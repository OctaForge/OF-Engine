
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "client_system.h"
#include "targeting.h"
#include "message_system.h"

using namespace MessageSystem;

#define MIN_CAMERA_MOVE_ITERS 8

VAR(cammovedist, 5, 10, 200); // Distance camera moves per iteration
VAR(camdist, 0, 50, 200); // How much higher than the player to set the camera

int saved_camdist;

void prepare_character_view() {
    player->pitch  = 0;
    camera1->pitch = 0;
    camera1->yaw   = camera1->yaw;

    saved_camdist = camdist;
    camdist = MIN_CAMERA_MOVE_ITERS * 3;
}

void stop_character_view() {
    camdist = saved_camdist;
}

FVARP(cameraheight, 0, 10, 50); // How much higher than the player to set the camera
FVAR(smoothcamera, 0, 0.2, 100.0); // Smoothing factor for the smooth camera. 0 means no smoothing
FVARP(cameraavoid, 0, 0.33, 1); // 1 means the camera is 100% away from the closest obstacle (and therefore on the player).

enum { FORCE_POS = 1<<0, FORCE_YAW = 1<<1, FORCE_PITCH = 1<<2, FORCE_ROLL = 1<<3 };

physent forced_camera;
int force_flags = 0;
float forced_camera_fov = -1;
int saved_thirdperson = -1;

void force_position(vec &pos) {
    force_flags |= FORCE_POS;
    forced_camera.o = pos;
    if (!thirdperson && saved_thirdperson == -1) {
        saved_thirdperson = thirdperson;
        thirdperson = 1;
    }
}

#define FORCE_PROP(name, flag) \
void force_##name(float name) { \
    force_flags |= flag; \
    forced_camera.name = name; \
    if (!thirdperson && saved_thirdperson == -1) { \
        saved_thirdperson = thirdperson; \
        thirdperson = 1; \
    } \
}
FORCE_PROP(yaw, FORCE_YAW)
FORCE_PROP(pitch, FORCE_PITCH)
FORCE_PROP(roll, FORCE_ROLL)

void force_fov(float fov) {
    forced_camera_fov = fov;
    if (!thirdperson && saved_thirdperson == -1) {
        saved_thirdperson = thirdperson;
        thirdperson = 1;
    }
}

void force_camera(vec &pos, float yaw, float pitch, float roll, float fov) {
    force_flags = 0;
    force_position(pos);
    force_yaw(yaw);
    force_pitch(pitch);
    force_roll(roll);
    force_fov(fov);
}

void position_camera(physent* camera1) {
    logger::log(logger::INFO, "position_camera\n");
    INDENT_LOG(logger::INFO);

    if (force_flags) {
        if (force_flags&FORCE_POS) {
            camera1->o = forced_camera.o; force_flags &= ~FORCE_POS;
        }
        if (force_flags&FORCE_YAW) {
            camera1->yaw = forced_camera.yaw; force_flags &= ~FORCE_YAW;
        }
        if (force_flags&FORCE_PITCH) {
            camera1->pitch = forced_camera.pitch; force_flags &= ~FORCE_PITCH;
        }
        if (force_flags&FORCE_ROLL) {
            camera1->roll = forced_camera.roll; force_flags &= ~FORCE_ROLL;
        }
        return; /* next time */
    }

    if (saved_thirdperson != -1) {
        thirdperson = saved_thirdperson;
        saved_thirdperson = -1;
    }

    float saved_camera_speed = camera1->maxspeed;
    camera1->maxspeed = 50;

    matrix3x3 orient;
    orient.identity();
    orient.rotate_around_y(camera1->roll*RAD);
    orient.rotate_around_x(camera1->pitch*-RAD);
    orient.rotate_around_z(camera1->yaw*-RAD);
    vec dir = vec(orient.b).neg();/*, side = vec(orient.a).neg(), up = orient.c;*/

    if(game::collidecamera()) {
        vec camera_origin = camera1->o;
        if (thirdperson) {
            vec up(0, 0, 1);
            movecamera(camera1, up, cameraheight, 1);
            // Find distance to obstacle
            movecamera(camera1, up, clamp(cameraheight
                - camera1->o.dist(camera_origin), 0.0f, 1.0f), 0.1f);
        }

        vec camera_origin2 = camera1->o;
        movecamera(camera1, dir, camdist, 1);
        // Find distance to obstacle
        movecamera(camera1, dir, clamp(camdist
            - camera1->o.dist(camera_origin2), 0.0f, 1.0f), 0.1f);

        if (smoothcamera) {
            float intended_dist = camera1->o.dist(camera_origin2)*(1.0f-cameraavoid);
            static float last_dist = 5;
            float ACTUAL_DISTANCE_FACTOR = clamp(1.0f - (curtime/1000.0f)/smoothcamera, 0.0f, 1.0f);
            float actual_dist = ACTUAL_DISTANCE_FACTOR*last_dist + (1-ACTUAL_DISTANCE_FACTOR)*intended_dist;

            // Start again, move to current distance
            camera1->o = camera_origin2;
            movecamera(camera1, dir, actual_dist, 1);
            movecamera(camera1, dir, clamp(actual_dist - camera1->o.dist(camera_origin2), 0.0f, 1.0f), 0.1f);
            last_dist = actual_dist;
        }
    } else {
        camera1->o.z += cameraheight;
        camera1->o.add(vec(dir).mul(camdist));
    }

    camera1->maxspeed = saved_camera_speed;

    static fpsent actual_camera; // Need fpsent for new normalization functions
    static vec last_playerpos;

    vec temp(actual_camera.o);
    temp.sub(camera1->o);

    actual_camera.normalize_yaw(camera1->yaw);
    actual_camera.normalize_pitch(camera1->pitch);

    float yawdelta = camera1->yaw - actual_camera.yaw;
    float pitchdelta = camera1->pitch - actual_camera.pitch;

    extern int mouselook;
    if (smoothcamera && !mouselook && temp.magnitude() < 50*player->radius && fabs(yawdelta) < 30.0f && fabs(pitchdelta) < 30.0f) {
        float ACTUAL_CAMERA_FACTOR = clamp(1.0f - (curtime/1000.0f)/smoothcamera, 0.0f, 1.0f);

        vec temp = player->o;
        temp.sub(last_playerpos);
        actual_camera.o.add(temp); // Prevent camera stutter

        actual_camera.o.mul(ACTUAL_CAMERA_FACTOR);
        temp = camera1->o;
        temp.mul(1-ACTUAL_CAMERA_FACTOR);
        actual_camera.o.add(temp);

        actual_camera.yaw = ACTUAL_CAMERA_FACTOR*actual_camera.yaw + (1-ACTUAL_CAMERA_FACTOR)*camera1->yaw;
        actual_camera.pitch = ACTUAL_CAMERA_FACTOR*actual_camera.pitch + (1-ACTUAL_CAMERA_FACTOR)*camera1->pitch;

        camera1->o = actual_camera.o;
        camera1->yaw = actual_camera.yaw;
        camera1->pitch = actual_camera.pitch;

//        camera1->o.z += player->aboveeye + player->eyeheight;
    } else {
        actual_camera.o = camera1->o;
        actual_camera.yaw = camera1->yaw;
        actual_camera.pitch = camera1->pitch;
    }

    last_playerpos = player->o;
}

// Input

VARF(mouselook, 0, 1, 1, {
    lua::push_external("cursor_reset"); lua_call(lua::L,  0, 0);
})

#define QUOT(arg) #arg

#define MOUSECLICK(num) \
void mouse##num##click() { \
    bool down = (addreleaseaction(newstring(QUOT(mouse##num##click))) != 0); \
    logger::log(logger::INFO, "mouse click: %i (down: %i)\n", num, down); \
\
    if (!(lua::L && ClientSystem::scenarioStarted())) \
        return; \
\
    TargetingControl::determineMouseTarget(true); \
    vec pos = TargetingControl::targetPosition; \
\
    CLogicEntity *tle = TargetingControl::targetLogicEntity; \
\
    int uid = -1; \
    if (tle && !tle->isNone()) uid = tle->getUniqueId(); \
\
    lua::push_external("cursor_get_position"); \
    lua_call(lua::L, 0, 2); \
\
    float x = lua_tonumber(lua::L, -2); \
    float y = lua_tonumber(lua::L, -1); \
    lua_pop(lua::L, 2); \
\
    assert(lua::push_external("input_click")); \
    lua_pushinteger(lua::L, num); \
    lua_pushboolean(lua::L, down); \
    lua_pushnumber (lua::L, pos.x); \
    lua_pushnumber (lua::L, pos.y); \
    lua_pushnumber (lua::L, pos.z); \
    if (tle && !tle->isNone()) { \
        lua_rawgeti(lua::L, LUA_REGISTRYINDEX, tle->lua_ref); \
    } else { \
        lua_pushnil(lua::L); \
    } \
    lua_pushnumber (lua::L, x); \
    lua_pushnumber (lua::L, y); \
    lua_call       (lua::L, 8, 0); \
} \
COMMAND(mouse##num##click, "");

MOUSECLICK(1)
MOUSECLICK(2)
MOUSECLICK(3)
#undef QUOT

bool k_turn_left, k_turn_right, k_look_up, k_look_down;

#define SCRIPT_DIR(name, v, p, d, s, os) \
ICOMMAND(name, "", (), { \
    if (ClientSystem::scenarioStarted()) \
    { \
        CLogicEntity *e = ClientSystem::playerLogicEntity; \
        lua_rawgeti (lua::L, LUA_REGISTRYINDEX, e->lua_ref); \
        lua_getfield(lua::L, -1, "clear_actions"); \
        lua_insert  (lua::L, -2); \
        lua_call    (lua::L, 1, 0); \
\
        s = (addreleaseaction(newstring(#name)) != 0); \
\
        lua::push_external("input_" #v); \
        lua_pushinteger(lua::L, s ? d : (os ? -(d) : 0)); \
        lua_pushboolean(lua::L, s); \
        lua_call(lua::L, 2, 0); \
    } \
});

SCRIPT_DIR(turn_left,  yaw, yawing, -1, k_turn_left,  k_turn_right);
SCRIPT_DIR(turn_right, yaw, yawing, +1, k_turn_right, k_turn_left);
SCRIPT_DIR(look_down, pitch, pitching, -1, k_look_down, k_look_up);
SCRIPT_DIR(look_up,   pitch, pitching, +1, k_look_up,   k_look_down);

// Old player movements
SCRIPT_DIR(backward, move, move, -1, player->k_down,  player->k_up);
SCRIPT_DIR(forward, move, move,  1, player->k_up,   player->k_down);
SCRIPT_DIR(left,   strafe, strafe,  1, player->k_left, player->k_right);
SCRIPT_DIR(right, strafe, strafe, -1, player->k_right, player->k_left);

ICOMMAND(jump, "", (), {
    if (ClientSystem::scenarioStarted())
    {
        CLogicEntity *e = ClientSystem::playerLogicEntity;
        lua_rawgeti (lua::L, LUA_REGISTRYINDEX, e->lua_ref);
        lua_getfield(lua::L, -1, "clear_actions");
        lua_insert  (lua::L, -2);
        lua_call    (lua::L, 1, 0);

        bool down = (addreleaseaction(newstring("jump")) != 0);

        lua::push_external("input_jump");
        lua_pushboolean(lua::L, down);
        lua_call(lua::L, 1, 0);
    }
});

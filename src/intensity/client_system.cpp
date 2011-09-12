
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "message_system.h"

#include "editing_system.h"
#include "client_engine_additions.h"
#include "targeting.h"

#include "client_system.h"
#include "of_world.h"

using namespace lua;

int            ClientSystem::playerNumber       = -1;
CLogicEntity  *ClientSystem::playerLogicEntity  = NULL;
bool           ClientSystem::loggedIn           = false;
bool           ClientSystem::editingAlone       = false;
int            ClientSystem::uniqueId           = -1;
types::string  ClientSystem::currScenarioCode   = "";

bool _scenarioStarted = false;
bool _mapCompletelyReceived = false;

namespace game
{
    extern int& minimapradius;
    extern int& minimaprightalign;
    extern int& forceminminimapzoom, &forcemaxminimapzoom;
    extern int& minimapsides;
    extern int& minminimapzoom, &maxminimapzoom;
    extern float& minimapxpos, &minimapypos, &minimaprotation;
}


void ClientSystem::connect(const char *host, int port)
{
    editingAlone = false;

    connectserv((char *)host, port, "");
}

void ClientSystem::login(int clientNumber)
{
    logger::log(logger::DEBUG, "ClientSystem::login()\r\n");

    playerNumber = clientNumber;

    MessageSystem::send_LoginRequest();
}

void ClientSystem::finishLogin(bool local)
{
    editingAlone = local;
    loggedIn = true;

    logger::log(logger::DEBUG, "Now logged in, with unique_ID: %d\r\n", uniqueId);
}

void ClientSystem::doDisconnect()
{
    disconnect();
}

void ClientSystem::onDisconnect()
{
    editingAlone = false;
    playerNumber = -1;
    loggedIn     = false;
    _scenarioStarted  = false;
    _mapCompletelyReceived = false;

    // it's also useful to stop all mapsounds and gamesounds (but only for client that disconnects!)
    stopsounds();

    // we also must get the lua system into clear state
    LogicSystem::clear(true);
}

bool ClientSystem::scenarioStarted()
{
    if (!_mapCompletelyReceived)
        logger::log(logger::INFO, "Map not completely received, so scenario not started\r\n");

    // If not already started, test if indeed started
    if (_mapCompletelyReceived && !_scenarioStarted)
    {
        if (engine.hashandle())
        {
            engine.getg("entity_store").t_getraw("has_scenario_started").call(0, 1);
            _scenarioStarted = engine.get<bool>(-1);
            engine.pop(2);
        }
    }

    return _mapCompletelyReceived && _scenarioStarted;
}

void ClientSystem::frameTrigger(int curtime)
{
    if (scenarioStarted())
    {
        float delta = float(curtime)/1000.0f;

        /* turn if mouse is at borders */
        float x, y;
        gui::getcursorpos(x, y);

        /* do not scroll with mouse */
        if (gui::hascursor(false)) x = y = 0.5;

        /* turning */
        fpsent *fp = (fpsent*)player;
        engine.getref(ClientSystem::playerLogicEntity->luaRef);
        float fs = engine.t_get<double>("facing_speed");

        if (fp->turn_move || fabs(x - 0.5) > 0.45)
        {
            player->yaw += fs * (
                fp->turn_move ? fp->turn_move : (x > 0.5 ? 1 : -1)
            ) * delta;
        }

        if (fp->look_updown_move || fabs(y - 0.5) > 0.45)
        {
            player->pitch += fs * (
                fp->look_updown_move ? fp->look_updown_move : (y > 0.5 ? -1 : 1)
            ) * delta;
        }

        engine.pop(1);

        /* normalize and limit the yaw and pitch values to appropriate ranges */
        extern void fixcamerarange();
        fixcamerarange();

        TargetingControl::determineMouseTarget();
        dobgload();
    }

    ClientSystem::cleanupHUD();
}

//
// HUD
//

struct queuedHUDRect
{
    float x1, y1, x2, y2;
    int color;
    float alpha;
};

vector<queuedHUDRect> queuedHUDRects;

void ClientSystem::addHUDRect(float x1, float y1, float x2, float y2, int color, float alpha)
{
    queuedHUDRect q;
    q.x1 = x1;
    q.y1 = y1;
    q.x2 = x2;
    q.y2 = y2;
    q.color = color;
    q.alpha = alpha;
    queuedHUDRects.add(q);
}

struct queuedHUDImage
{
    const char *tex;
    float centerX, centerY; //!< In relative coordinates (to each axis, the center of where to draw the HUD
//    float widthInX, heightInY; //!< In axis-relative coordinates, how big the HUD should be.
//                               //!< E.g. widthInX 0.5 means its width is half of the X dimension
    float width, height;
    int color;
    float alpha;

    queuedHUDImage()
    {
        tex = "";
        centerX = 0.5; centerY = 0.5;
//        widthInX = 0; heightInY = 0;
        width = 0.61803399; height = 0.61803399;
        color = 0xFFFFFF, alpha = 1.0;
    }
};

vector<queuedHUDImage> queuedHUDImages;

void ClientSystem::addHUDImage(const char *tex, float centerX, float centerY, float width, float height, int color, float alpha)
{
    queuedHUDImage q;
    q.tex = tex;
    q.centerX = centerX;
    q.centerY = centerY;
    q.width = width;
    q.height = height;
    q.color = color;
    q.alpha = alpha;
    queuedHUDImages.add(q);
}

struct queuedHUDText
{
    const char *text;
    float x, y, scale;
    int color;
};

vector<queuedHUDText> queuedHUDTexts;

void ClientSystem::addHUDText(const char *text, float x, float y, float scale, int color)
{
    queuedHUDText q;
    q.text = text;
    q.x = x;
    q.y = y;
    q.scale = scale;
    q.color = color;
    queuedHUDTexts.add(q);
}

void ClientSystem::drawHUD(int w, int h)
{
    if (gui::hascursor(false)) return; // Showing GUI - do not show HUD

    float wFactor = float(h)/max(w,h);
    float hFactor = float(w)/max(w,h);

    // Rects

    glPushMatrix();
    glScalef(w, h, 1);

    loopv(queuedHUDRects)
    {
        queuedHUDRect& q = queuedHUDRects[i];
        if (q.x2 < 0)
        {
            float x1 = q.x1, y1 = q.y1;
            q.x1 = x1 - wFactor*fabs(q.x2)/2;
            q.y1 = y1 - hFactor*fabs(q.y2)/2;
            q.x2 = x1 + wFactor*fabs(q.x2)/2;
            q.y2 = y1 + hFactor*fabs(q.y2)/2;
        }

        vec rgb(q.color>>16, (q.color>>8)&0xFF, q.color&0xFF);
        rgb.mul(1.0/256.0);

        glColor4f(rgb[0], rgb[1], rgb[2], q.alpha);

        glDisable(GL_TEXTURE_2D);
        notextureshader->set();
        glBegin(GL_TRIANGLE_STRIP);
        glVertex2f(q.x1, q.y1);
        glVertex2f(q.x2, q.y1);
        glVertex2f(q.x1, q.y2);
        glVertex2f(q.x2, q.y2);
        glEnd();
        glEnable(GL_TEXTURE_2D);
        defaultshader->set();    
    }

    glPopMatrix();

    // Images

    glPushMatrix();
    glScalef(w, h, 1);

    loopv(queuedHUDImages)
    {
        queuedHUDImage& q = queuedHUDImages[i];
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        float x1 = q.centerX - (wFactor*q.width/2);
        float y1 = q.centerY - (hFactor*q.height/2);
        float x2 = q.centerX + (wFactor*q.width/2);
        float y2 = q.centerY + (hFactor*q.height/2);
        vec rgb(q.color>>16, (q.color>>8)&0xFF, q.color&0xFF);
        rgb.mul(1.0/256.0);

        glColor4f(rgb[0], rgb[1], rgb[2], q.alpha);
        settexture(q.tex, 3);
        glBegin(GL_TRIANGLE_STRIP);
            glTexCoord2f(0.0f, 0.0f); glVertex2f(x1, y1);
            glTexCoord2f(1.0f, 0.0f); glVertex2f(x2, y1);
            glTexCoord2f(0.0f, 1.0f); glVertex2f(x1, y2);
            glTexCoord2f(1.0f, 1.0f); glVertex2f(x2, y2);
        glEnd();
    }

    glPopMatrix();

    // Texts

    loopv(queuedHUDTexts)
    {
        queuedHUDText& q = queuedHUDTexts[i];

        glPushMatrix();
        glScalef(q.scale, q.scale, 1);

        int b = q.color & 255;
        q.color = q.color >> 8;
        int g = q.color & 255;
        int r = q.color >> 8;

        draw_text(q.text, w*q.x/q.scale - text_width(q.text)/2, h*q.y/q.scale - FONTH/2, r, g, b);

        glPopMatrix();
    }
}

void ClientSystem::drawMinimap(int w, int h)
{
    if (gui::hascursor(false)) return; // Showing GUI - do not show HUD

    float x, y;
    vec dir, pos;

    glPushMatrix();
    glScalef(h / 1000.0f, h / 1000.0f, 1); // we don't want the screen width

    // if we want it aligned to right, we need to move stuff through screen .. if not, we just set the x position value
    if (game::minimaprightalign)
        x = (1000 * w) / h - game::minimapradius * 1000 - game::minimapxpos * 1000;
    else
        x = game::minimapxpos * 1000;

    y = game::minimapypos * 1000;
    glColor3f(1, 1, 1);

    glDisable(GL_BLEND);
    bindminimap();
    pos = vec(game::hudplayer()->o).sub(minimapcenter).mul(minimapscale).add(0.5f); // hudplayer, because we want minimap also when following someone.

    vecfromyawpitch(camera1->yaw, 0, 1, 0, dir);
    float scale = clamp(
        max(minimapradius.x, minimapradius.y) / 3,
        (game::forceminminimapzoom < 0) ?
            float(game::minminimapzoom)
          : float(game::forceminminimapzoom),
        (game::forcemaxminimapzoom < 0) ?
            float(game::maxminimapzoom)
          : float(game::forcemaxminimapzoom)
    );

    glBegin(GL_TRIANGLE_FAN);

    loopi(game::minimapsides) // create a triangle for every side, together it makes triangle when minimapsides is 3, square when it's 4 and "circle" for any other value.
    {
        // this part manages texture
        vec tc = vec(dir).rotate_around_z((i / float(game::minimapsides)) * 2 * M_PI);

        if (game::minimaprotation > 0) // rotate the minimap if we want to rotate it, if not, just skip this
            tc.rotate_around_z(game::minimaprotation * (M_PI / 180.0f));

        glTexCoord2f(pos.x + (tc.x * scale * minimapscale.x),
                     pos.y + (tc.y * scale * minimapscale.y));

        // this part actually creates the triangle which is the texture bind to
        vec v = vec(0, -1, 0).rotate_around_z((i / float(game::minimapsides)) * 2 * M_PI);

        if (game::minimaprotation > 0)
            v.rotate_around_z(game::minimaprotation * (M_PI / 180.0f));

        glVertex2f(x + 500 * game::minimapradius * (1.0f + v.x),
                   y + 500 * game::minimapradius * (1.0f + v.y));
    }

    glEnd();
    glEnable(GL_BLEND);

    glPopMatrix();
}

void ClientSystem::cleanupHUD()
{
    queuedHUDRects.setsize(0);
    queuedHUDImages.setsize(0);
    queuedHUDTexts.setsize(0);
}

void ClientSystem::finishLoadWorld()
{
    extern bool finish_load_world();
    finish_load_world();

    _mapCompletelyReceived = true; // We have the original map + static entities (still, scenarioStarted might want more stuff)

    EditingSystem::madeChanges = false; // Clean the slate

    ClientSystem::editingAlone = false; // Assume not in this mode

    gui::clearmainmenu(); // (see prepareForMap)
}

void ClientSystem::prepareForNewScenario(const types::string& sc)
{
    _mapCompletelyReceived = false; // We no longer have a map. This implies scenarioStarted will return false, thus
                                    // stopping sending of position updates, as well as rendering

    SETV(mainmenu, 1); // Keep showing GUI meanwhile (in particular, to show the message about a new map on the way

    // Clear the logic system, as it is no longer valid - were it running, we might try to process messages from
    // the new map being set up on the server, even though they are irrelevant to the existing engine, set up for
    // another map with its Classes etc.
    LogicSystem::clear();

    currScenarioCode = sc;
}

bool ClientSystem::isAdmin()
{
    bool isAdmin = false;
    if (!loggedIn) return isAdmin;
    if (!playerLogicEntity) return isAdmin;

    engine.getref(playerLogicEntity->luaRef);
    isAdmin = engine.t_get<bool>("can_edit");
    engine.pop(1);

    return isAdmin;
}


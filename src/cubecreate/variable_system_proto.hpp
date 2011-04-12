/*
 * variable_system_proto.hpp, version 1
 * Engine variable declarations
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2010 q66
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#ifndef _EV_NODEF

#define VCB(n, t, c) \
namespace var \
{ \
    inline void _varcb_##n(t curv) \
    { \
        c \
    } \
}

// engine/animmodel.h
VCB(preloadmodelshaders, int, preloadmodelshaders();)

// engine/blend.cpp
VCB(stoppaintblendmap, int, if(!curv) stoppaintblendmap();)

// engine/blob.cpp
#ifdef CLIENT
VCB(resetblobs, int, resetblobs();)
VCB(initsblobs, int, initblobs(BLOB_STATIC);)
VCB(initdblobs, int, initblobs(BLOB_DYNAMIC);)
#endif

// engine/client.cpp
void setrate(int rate);
void throttle();
VCB(setrate, int, setrate(curv);)
VCB(throttle, int, throttle();)

// engine/console.cpp
#ifdef CLIENT
extern vector<cline> conlines;
VCB(maxcon, int, while(conlines.length() > curv) delete[] conlines.pop().line;)

// engine/decal.cpp
VCB(initdecals, int, initdecals();)

// engine/depthfx.h
void cleanupdepthfx();
VCB(cleanupdepthfx, int, cleanupdepthfx();)

// engine/glare.cpp
void cleanupglare();
VCB(cleanupglare, int, cleanupglare();)

// engine/grass.cpp
extern bvec grasscolor;
VCB(grasscolour, int,
    int c = curv;
    if(!curv)
    {
        _EV_grasscolour->s(0xFFFFFF);
        c = 0xFFFFFF;
    }
    grasscolor = bvec((c>>16)&0xFF, (c>>8)&0xFF, c&0xFF);
)

// engine/lightmap.cpp
void setfullbrightlevel(int fullbrightlevel);
void cleanuplightmaps();
VCB(ambient, int,
    int c = curv;
    if(curv <= 255)
    {
        _EV_ambient->s(curv | (curv<<8) | (curv<<16));
        c = curv | (curv<<8) | (curv<<16);
    }
    ambientcolor = bvec((c>>16)&0xFF, (c>>8)&0xFF, c&0xFF);
)
VCB(skylight, int,
    int c = curv;
    if(curv <= 255)
    {
        _EV_skylight->s(curv | (curv<<8) | (curv<<16));
        c = curv | (curv<<8) | (curv<<16);
    }
    skylightcolor = bvec((c>>16)&0xFF, (c>>8)&0xFF, c&0xFF);
)
VCB(clearlightcache, int, clearlightcache();)
VCB(fullbright, int, if (lightmaptexs.length()) initlights();)
VCB(fullbrightlevel, int, setfullbrightlevel(curv);)
VCB(resetlights, int, cleanuplightmaps(); initlights(); allchanged();)

// engine/main.cpp
// TODO: remove those defines
#define SCR_MINW 320
#define SCR_MINH 200
#define SCR_MAXW 10000
#define SCR_MAXH 10000

void setfullscreen(bool enable);
void clockreset();
VCB(initwarningres, int, initwarning("screen resolution");)
VCB(initwarningdepth, int, initwarning("color depth");)
VCB(initwarningdbpre, int, initwarning("depth-buffer precision");)
VCB(initwarningsbpre, int, initwarning("stencil-buffer precision");)
VCB(initwarningaa, int, initwarning("anti-aliasing");)
VCB(initwarningvs, int, initwarning("vertical sync");)
VCB(initwarningshd, int, initwarning("shaders");)
VCB(initwarningshdpre, int, initwarning("shader quality");)
VCB(initwarningsnd, int, initwarning("sound configuration", INIT_RESET, CHANGE_SOUND);)
VCB(initwarningtexq, int, initwarning("texture quality", INIT_LOAD);)
VCB(initwarningtexf, int, initwarning("texture filtering", INIT_LOAD);)
VCB(fullscreen, int, setfullscreen(curv!=0);)
VCB(gamma, int,
    float f = curv/100.0f;
    if(SDL_SetGamma(f,f,f)==-1)
    {
        conoutf(CON_ERROR, "Could not set gamma (card/driver doesn't support it?)");
        conoutf(CON_ERROR, "sdl: %s", SDL_GetError());
    }
)
VCB(gamespeed, int, if(multiplayer()) _EV_gamespeed->s(100);)
VCB(paused, int, if(multiplayer()) _EV_paused->s(0);)
VCB(clockreset, int, clockreset();)

// engine/material.cpp
VCB(preloadwatershaders, int, preloadwatershaders();)
#endif
// engine/octaedit.cpp
extern selinfo sel;
extern int orient, gridsize;
extern ivec cor, lastcor;
extern ivec cur, lastcur;
extern int horient;
extern bool havesel;
// TODO: get rid of those
#define MAXBRUSH    64
#define MAXBRUSH2   32
VCB(dragging, int,
    if(!curv || cor[0]<0) return;
    lastcur = cur;
    lastcor = cor;
    sel.grid = gridsize;
    sel.orient = orient;
)
VCB(moving, int,
    if(!curv) return;
    vec v(cur.v); v.add(1);
    _EV_moving->s(pointinsel(sel, v));
    if(GETIV(moving)) havesel = false; // tell cursorupdate to create handle
)
VCB(gridpower, int,
    if(GETIV(dragging)) return;
    gridsize = 1<<curv;
    if(gridsize>=GETIV(mapsize)) gridsize = GETIV(mapsize)/2;
    cancelsel();
)
VCB(hmapedit, int, horient = sel.orient;)

// engine/physics.cpp
VCB(cleardynentcache, int, cleardynentcache();)

// engine/pvs.cpp
void lockpvs_(bool lock);
VCB(lockpvs, int, lockpvs_(curv!=0);)

#ifdef CLIENT
// engine/rendergl.cpp
extern int zoommillis, damageblendmillis;
extern bvec fogcolor;
extern bvec minimapcolor;
extern GLuint minimaptex;
void cleanupmotionblur();
VCB(zoom, int, if(curv) zoommillis = totalmillis;)
VCB(fogcolor, int, fogcolor = bvec((curv>>16)&0xFF, (curv>>8)&0xFF, curv&0xFF);)
VCB(minimapcolor, int, minimapcolor = bvec((curv>>16)&0xFF, (curv>>8)&0xFF, curv&0xFF);)
VCB(minimapdraw, int, if (minimaptex) drawminimap();)
VCB(cleanupmotionblur, int, if (!curv) cleanupmotionblur();)
VCB(damageblendmillis, int, if (!curv) damageblendmillis = 0;)

// engine/renderparticles.cpp
VCB(particleinit, int, particleinit();)
VCB(particleinitf, float, particleinit();)

// engine/rendersky.cpp
extern Texture *sky[6], *clouds[6], *stars[6], *sun[6];
extern Texture *cloudoverlay, *altcloudoverlay;
void loadsky(const char *basename, Texture *texs[6]);
Texture *loadskyoverlay(const char *basename);
extern bvec fogdomecolor;
VCB(loadstars, const char*, if (curv) loadsky(curv, stars);)
VCB(loadsky, const char*, if (curv) loadsky(curv, sky);)
VCB(loadsun, const char*, if (curv) loadsky(curv, sun);)
VCB(loadclouds, const char*, if (curv) loadsky(curv, clouds);)
VCB(skymillis, int, skymillis = 1;)
VCB(cloudoverlay, const char*, if (curv) cloudoverlay = loadskyoverlay(curv);)
VCB(altcloudoverlay, const char*, if (curv) altcloudoverlay = loadskyoverlay(curv);)
VCB(fogdomecolor, int, fogdomecolor = bvec((curv>>16)&0xFF, (curv>>8)&0xFF, curv&0xFF);)

// engine/renderva.cpp
VCB(loadcaustics, int, loadcaustics();)
#endif

// engine/server.cpp
void disconnectmaster();
VCB(disconnectmaster, const char*, disconnectmaster();)
VCB(serverport, int, if(!curv) _EV_serverport->s(server::serverport());)

// engine/shader.cpp
#ifdef CLIENT
void fixshaderdetail();
VCB(fixshaderdetail, int, fixshaderdetail();)

// engine/shadowmap.cpp
void cleanshadowmap();
void setshadowdir(int angle);
extern bvec shadowmapambientcolor;
VCB(cleanshadowmap, int, cleanshadowmap();)
VCB(shadowmapambient, int,
    int v = curv;
    if(v <= 255) v |= (v<<8) | (v<<16);
    shadowmapambientcolor = bvec((v>>16)&0xFF, (v>>8)&0xFF, v&0xFF);
    _EV_shadowmapambient->s(v);
)
VCB(shadowmapangle, int, setshadowdir(curv);)

// engine/sound.cpp
void stopchannels();
void setmusicvol(int musicvol);
VCB(soundvol, int, if(!curv) { stopchannels(); setmusicvol(0); })
VCB(musicvol, int, setmusicvol(GETIV(soundvol) ? curv : 0);)
VCB(mumble, int, if (curv) initmumble(); else closemumble();)
// TODO: remove
#define MIX_DEFAULT_FREQUENCY 22050

// engine/texture.cpp
// TODO: removeme
enum
{
    IMG_BMP = 0,
    IMG_TGA = 1,
    IMG_PNG = 2,
    NUMIMG
};
VCB(setuptexcompress, int, setuptexcompress();)
VCB(setupmaterials, int, setupmaterials();)

// engine/water.cpp
extern bvec watercolor, waterfallcolor, lavacolor;
VCB(preloadwaters, int, cleanreflections(); preloadwatershaders();)
VCB(watercolor, int,
    int c = curv;
    if(!c) c = 0x144650;
    watercolor = bvec((c>>16)&0xFF, (c>>8)&0xFF, c&0xFF);
    _EV_watercolour->s(c);
)
VCB(waterfallcolor, int, waterfallcolor = bvec((curv>>16)&0xFF, (curv>>8)&0xFF, curv&0xFF);)
VCB(lavacolor, int,
    int c = curv;
    if(!c) c = 0xFF4000;
    lavacolor = bvec((c>>16)&0xFF, (c>>8)&0xFF, c&0xFF);
    _EV_lavacolour->s(c);
)
VCB(cleanreflections, int, cleanreflections();)
#endif

// engine/world.cpp
extern int efocus, enthover;
extern bool initentdragging;
bool noentedit();
bool enttoggle(int id);
void entadd(int id);
VCB(entediting, int, if(!curv) { entcancel(); efocus = enthover = -1; })
VCB(entmoving, int,
    int c = curv;
    if(enthover < 0 || noentedit()) c = 0;
    else if(c == 1) c = enttoggle(enthover);
    else if(c == 2 && entgroup.find(enthover) < 0) entadd(enthover);
    if(c > 0) initentdragging = true;
    _EV_entmoving->s(c);
)

// fpsgame/scoreboard.cpp
#ifdef CLIENT
void scorebshow(bool on);
VCB(scoreboard, int, scorebshow(curv!=0);)
#endif

// others
VCB(allchanged, int, allchanged();)

namespace var
{
#endif
// end #ifndef _EV_NODEF

// engine/animmodel.h

DEFVAR(lightmodels)
DEFVAR(envmapmodels)
DEFVAR(glowmodels)
DEFVAR(bumpmodels)
DEFVAR(fullbrightmodels)

// engine/blend.cpp

DEFVAR(blendpaintmode)

DEFVAR(paintblendmapdelay)
DEFVAR(paintblendmapinterval)

// engine/blob.cpp

#ifdef CLIENT
DEFVAR(blobs) // globalname was showblobs
DEFVAR(blobintensity)
DEFVAR(blobheight)
DEFVAR(blobfadelow)
DEFVAR(blobfadehigh)
DEFVAR(blobmargin)
DEFVAR(dbgblob)
DEFVAR(blobstattris)
DEFVAR(blobdyntris)
#endif

// engine/client.cpp
DEFVAR(rate)
DEFVAR(throttle_interval)
DEFVAR(throttle_accel)
DEFVAR(throttle_decel)
DEFVAR(connectname)
DEFVAR(connectport)

#ifdef CLIENT
// engine/console.cpp
DEFVAR(maxcon)
DEFVAR(fullconsole)
DEFVAR(consize)
DEFVAR(miniconsize)
DEFVAR(miniconwidth)
DEFVAR(confade)
DEFVAR(miniconfade)
DEFVAR(fullconsize)
DEFVAR(confilter)
DEFVAR(fullconfilter)
DEFVAR(miniconfilter)
DEFVAR(maxhistory)

// engine/decal.cpp

DEFVAR(maxdecaltris)
DEFVAR(decalfade)
DEFVAR(dbgdec)
DEFVAR(decals) // globalname was showdecals
DEFVAR(maxdecaldistance)

// engine/depthfx.h
DEFVAR(depthfxfpscale)
DEFVAR(depthfxscale)
DEFVAR(depthfxblend)
DEFVAR(depthfxpartblend)
DEFVAR(depthfxmargin)
DEFVAR(depthfxbias)
DEFVAR(fpdepthfx)
DEFVAR(depthfxprecision)
DEFVAR(depthfxemuprecision)
DEFVAR(depthfxsize)
DEFVAR(depthfx)
DEFVAR(depthfxparts)
DEFVAR(depthfxrect)
DEFVAR(depthfxfilter)
DEFVAR(blurdepthfx)
DEFVAR(blurdepthfxsigma)
DEFVAR(depthfxscissor)
DEFVAR(debugdepthfx)

// engine/dynlight.cpp
DEFVAR(ffdynlights)
DEFVAR(maxdynlights)
DEFVAR(dynlightdist)

// engine/explosion.h

DEFVAR(explosion2d)

// engine/glare.cpp
DEFVAR(glaresize)
DEFVAR(glare)
DEFVAR(blurglare)
DEFVAR(blurglaresigma)
DEFVAR(debugglare)
DEFVAR(glarescale)

// engine/grass.cpp
DEFVAR(grass)
DEFVAR(dbggrass)
DEFVAR(grassdist)
DEFVAR(grasstaper)
DEFVAR(grassstep)
DEFVAR(grassheight)
DEFVAR(grassanimmillis)
DEFVAR(grassanimscale)
DEFVAR(grassscale)
DEFVAR(grasscolour)
DEFVAR(grassalpha)

// engine/lensflare.h

DEFVAR(flarelights)
DEFVAR(flarecutoff)
DEFVAR(flaresize)

// engine/lightmap.cpp
DEFVAR(lightprecision)
DEFVAR(lighterror)
DEFVAR(bumperror)
DEFVAR(lightlod)
DEFVAR(ambient)
DEFVAR(skylight)
DEFVAR(lmshadows) // global name was lmshadows_
DEFVAR(lmaa) // global name was lmaa_
DEFVAR(lightcompress)
DEFVAR(skytexturelight)
DEFVAR(blurlms)
DEFVAR(blurskylight)
DEFVAR(edgetolerance)
DEFVAR(adaptivesample)
DEFVAR(lightcachesize)
DEFVAR(lightthreads)
DEFVAR(patchnormals)
DEFVAR(fullbright)
DEFVAR(fullbrightlevel)
DEFVAR(convertlms)
DEFVAR(roundlightmaptex)
DEFVAR(batchlightmaps)

// engine/lightning.h

DEFVAR(lnjittermillis)
DEFVAR(lnjitterradius)
DEFVAR(lnjitterscale)
DEFVAR(lnscrollmillis)
DEFVAR(lnscrollscale)
DEFVAR(lnblendpower)

// engine/main.cpp
DEFVAR(scr_w)
DEFVAR(scr_h)
DEFVAR(colorbits)
DEFVAR(depthbits)
DEFVAR(stencilbits)
DEFVAR(fsaa)
DEFVAR(vsync)
DEFVAR(fullscreen)
DEFVAR(gamma)
DEFVAR(dbgmodes)
DEFVAR(iskeydown)
DEFVAR(iskeyup)
DEFVAR(ismousedown)
DEFVAR(ismouseup)
DEFVAR(gamespeed)
DEFVAR(paused)
DEFVAR(mainmenufps)
DEFVAR(maxfps)
DEFVAR(clockerror)
DEFVAR(clockfix)

// engine/material.cpp

DEFVAR(optmats)
DEFVAR(showmat)
DEFVAR(glassenv)
DEFVAR(waterfallenv)

// engine/menus.cpp

DEFVAR(menudistance)
DEFVAR(menuautoclose)
DEFVAR(applydialog)
DEFVAR(mainmenu)

// engine/movie.cpp

DEFVAR(dbgmovie)
DEFVAR(movieaccelblit)
DEFVAR(movieaccelyuv)
DEFVAR(movieaccel)
DEFVAR(moviesync)
DEFVAR(moview)
DEFVAR(movieh)
DEFVAR(moviefps)
DEFVAR(moviesound)
#endif

// engine/normal.cpp
DEFVAR(lerpangle)
DEFVAR(lerpsubdiv)
DEFVAR(lerpsubdivsize)

// engine/octa.cpp
DEFVAR(mipvis)
DEFVAR(minface)
DEFVAR(maxmerge)

// engine/octaedit.cpp
DEFVAR(dragging)
DEFVAR(moving)
DEFVAR(gridpower)
DEFVAR(passthroughsel)
DEFVAR(editing)
DEFVAR(selectcorners)
DEFVAR(hmapedit)
DEFVAR(gridlookup)
DEFVAR(passthroughcube)
DEFVAR(undomegs) // bounded by n megs
DEFVAR(nompedit)
DEFVAR(brushx)
DEFVAR(brushy)
DEFVAR(bypassheightmapcheck) // temp
DEFVAR(invalidcubeguard)
DEFVAR(selectionsurf)
DEFVAR(usevdelta)
DEFVAR(allfaces)
DEFVAR(texguiwidth)
DEFVAR(texguiheight)
DEFVAR(texguitime)
DEFVAR(texgui2d)

// engine/octarender.cpp

DEFVAR(printvbo)
DEFVAR(vbosize) // globalname was maxvbosize
DEFVAR(filltjoints)
DEFVAR(vacubemax)
DEFVAR(vacubesize)
DEFVAR(vacubemin)

// engine/physics.cpp

DEFVAR(dynentsize)
DEFVAR(maxroll)
DEFVAR(straferoll)
DEFVAR(floatspeed)
DEFVAR(physinterp)

// engine/pvs.cpp
DEFVAR(maxpvsblocker)
DEFVAR(pvsleafsize)
DEFVAR(pvsthreads)
DEFVAR(lockpvs)
DEFVAR(pvs) // globalname was usepvs
DEFVAR(waterpvs) // globalname was usewaterpvs

// engine/ragdoll.h

DEFVAR(ragdolltimestepmin)
DEFVAR(ragdolltimestepmax)
DEFVAR(ragdollrotfric)
DEFVAR(ragdollrotfricstop)
DEFVAR(ragdollconstrain)
DEFVAR(ragdollbodyfric)
DEFVAR(ragdollbodyfricscale)
DEFVAR(ragdollwaterfric)
DEFVAR(ragdollgroundfric)
DEFVAR(ragdollairfric)
DEFVAR(ragdollexpireoffset)
DEFVAR(ragdollwaterexpireoffset)
DEFVAR(ragdolleyesmooth)
DEFVAR(ragdolleyesmoothmillis)

// engine/rendergl.cpp

#ifdef CLIENT
DEFVAR(renderpath)
DEFVAR(ati_skybox_bug)
DEFVAR(ati_oq_bug)
DEFVAR(ati_minmax_bug)
DEFVAR(ati_dph_bug)
DEFVAR(ati_teximage_bug)
DEFVAR(ati_line_bug)
DEFVAR(ati_cubemap_bug)
DEFVAR(ati_ubo_bug)
DEFVAR(nvidia_scissor_bug)
DEFVAR(apple_glsldepth_bug)
DEFVAR(apple_ff_bug)
DEFVAR(apple_vp_bug)
DEFVAR(sdl_backingstore_bug)
DEFVAR(intel_quadric_bug)
DEFVAR(mesa_program_bug)
DEFVAR(avoidshaders)
DEFVAR(minimizetcusage)
DEFVAR(emulatefog)
DEFVAR(usevp2)
DEFVAR(usevp3)
DEFVAR(usetexrect)
DEFVAR(hasglsl)
DEFVAR(useubo)
DEFVAR(usebue)
DEFVAR(rtscissor)
DEFVAR(blurtile)
DEFVAR(rtsharefb)
DEFVAR(dbgexts)
DEFVAR(wireframe)
DEFVAR(zoominvel)
DEFVAR(zoomoutvel)
DEFVAR(zoomfov)
DEFVAR(fov)
DEFVAR(avatarzoomfov)
DEFVAR(avatarfov)
DEFVAR(avatardepth)
DEFVAR(zoom)
DEFVAR(zoomsens)
DEFVAR(zoomaccel)
DEFVAR(zoomautosens)
DEFVAR(sensitivity)
DEFVAR(sensitivityscale)
DEFVAR(invmouse)
DEFVAR(mouseaccel)
DEFVAR(thirdperson)
DEFVAR(thirdpersondistance)
DEFVAR(nearplane)
DEFVAR(reflectclip)
DEFVAR(reflectclipavatar)
DEFVAR(polygonoffsetfactor)
DEFVAR(polygonoffsetunits)
DEFVAR(depthoffset)
DEFVAR(fog)
DEFVAR(fogcolour)
DEFVAR(skyboxglare)
DEFVAR(reflectmms)
DEFVAR(refractsky)
DEFVAR(minimapheight)
DEFVAR(minimapcolour)
DEFVAR(minimapclip)
DEFVAR(minimapsize)
DEFVAR(motionblur)
DEFVAR(motionblurmillis)
DEFVAR(motionblurscale)
DEFVAR(damagecompass) // globalname was usedamagecompass
DEFVAR(damagecompassfade)
DEFVAR(damagecompasssize)
DEFVAR(damagecompassalpha)
DEFVAR(damagecompassmin)
DEFVAR(damagecompassmax)
DEFVAR(damagescreen)
DEFVAR(damagescreenfactor)
DEFVAR(damagescreenalpha)
DEFVAR(damagescreenfade)
DEFVAR(damagescreenmin)
DEFVAR(damagescreenmax)
DEFVAR(hidestats)
DEFVAR(hidehud)
DEFVAR(crosshairsize)
DEFVAR(cursorsize)
DEFVAR(crosshairfx)
DEFVAR(wallclock)
DEFVAR(wallclock24)
DEFVAR(wallclocksecs)
DEFVAR(showfps)
DEFVAR(showfpsrange)
DEFVAR(showeditstats)
DEFVAR(statrate)
DEFVAR(conscale)
#endif

// engine/rendermodel.cpp

DEFVAR(oqdynent)
DEFVAR(animationinterpolationtime)
DEFVAR(showboundingbox)
DEFVAR(modeltweaks) // INTENSITY: SkyManager: tweaks for models (like ambience, glow, so we can sync it with ambientlight
DEFVAR(tweakmodelspec)
DEFVAR(tweakmodelambient)
DEFVAR(tweakmodelglow)
DEFVAR(tweakmodelspecglare)
DEFVAR(tweakmodelglowglare)
DEFVAR(tweakmodelscale) // end INTENSITY
DEFVAR(maxmodelradiusdistance)
DEFVAR(animoverride)
DEFVAR(testanims)
DEFVAR(testpitch)

#ifdef CLIENT
// engine/renderparticles.cpp
DEFVAR(particlesize)
DEFVAR(emitmillis)
DEFVAR(dbgpseed)
DEFVAR(outlinemeters)
DEFVAR(maxparticles)
DEFVAR(fewparticles)
DEFVAR(particleglare)
DEFVAR(debugparticles)
DEFVAR(maxparticledistance)
DEFVAR(maxtrail)
DEFVAR(particletext)
DEFVAR(maxparticletextdistance)
DEFVAR(showparticles)
DEFVAR(cullparticles)
DEFVAR(replayparticles)
DEFVAR(seedparticles) // globalname was seedmillis
DEFVAR(dbgpcull)
DEFVAR(editpartsize)

// engine/rendersky.cpp
DEFVAR(starbox) // INTENSITY: SkyManager: various star and sun variables
DEFVAR(starboxtint)
DEFVAR(spinstars)
DEFVAR(yawstars) // end INTENSITY
DEFVAR(skybox)
DEFVAR(skyboxalpha) // INTENSITY: Less than one so it won't occlude and cause starbox to be culled.
DEFVAR(skyboxtint) // INTENSITY: was skyboxcolour
DEFVAR(spinsky)
DEFVAR(yawsky)
DEFVAR(sunbox)
DEFVAR(sunboxalpha)
DEFVAR(sunboxtint)
DEFVAR(spinsun)
DEFVAR(yawsun)
DEFVAR(cloudbox)
DEFVAR(cloudboxalpha) // INTENSITY: was 1
DEFVAR(cloudboxtint)
DEFVAR(spinclouds)
DEFVAR(yawclouds)
DEFVAR(cloudclip)
DEFVAR(cloudlayer)
DEFVAR(cloudscrollx)
DEFVAR(cloudscrolly)
DEFVAR(cloudscale)
DEFVAR(spincloudlayer)
DEFVAR(yawcloudlayer)
DEFVAR(cloudheight)
DEFVAR(cloudfade)
DEFVAR(cloudalpha)
DEFVAR(cloudsubdiv)
DEFVAR(cloudtint)
DEFVAR(altcloudlayer)
DEFVAR(altcloudscrollx)
DEFVAR(altcloudscrolly)
DEFVAR(altcloudscale)
DEFVAR(spinaltcloudlayer)
DEFVAR(yawaltcloudlayer)
DEFVAR(altcloudheight)
DEFVAR(altcloudfade)
DEFVAR(altcloudalpha)
DEFVAR(altcloudsubdiv)
DEFVAR(altcloudtint)
DEFVAR(fogdomeheight)
DEFVAR(fogdomemin)
DEFVAR(fogdomemax)
DEFVAR(fogdomecap)
DEFVAR(fogdomeclip)
DEFVAR(fogdomecolour)
DEFVAR(sparklyfix)
DEFVAR(showsky)
DEFVAR(clipsky)
DEFVAR(clampsky)
DEFVAR(fogdomeclouds)
DEFVAR(skytexture) // globalname was useskytexture

// engine/renderva.cpp

DEFVAR(oqfrags)
DEFVAR(oqwait)
DEFVAR(oqmm)
DEFVAR(outline)
DEFVAR(dtoutline)
DEFVAR(blendbrushcolor)
DEFVAR(oqdist)
DEFVAR(zpass)
DEFVAR(glowpass)
DEFVAR(envpass)
DEFVAR(batchgeom)
DEFVAR(causticscale)
DEFVAR(causticmillis)
DEFVAR(caustics)
DEFVAR(oqgeom)
DEFVAR(dbgffsm)
DEFVAR(dbgffdl)
DEFVAR(ffdlscissor)
#endif
// engine/serverbrowser.cpp

DEFVAR(searchlan)
DEFVAR(servpingrate)
DEFVAR(servpingdecay)
DEFVAR(maxservpings)

// engine/server.cpp
DEFVAR(updatemaster) // globalname was allowupdatemaster
DEFVAR(mastername)
DEFVAR(serveruprate)
DEFVAR(serverip)
DEFVAR(serverport) // not hex var

#ifdef CLIENT
// engine/shader.cpp
DEFVAR(reservevpparams)
DEFVAR(maxvpenvparams)
DEFVAR(maxvplocalparams)
DEFVAR(maxfpenvparams)
DEFVAR(maxfplocalparams)
DEFVAR(maxtexcoords)
DEFVAR(maxvsuniforms)
DEFVAR(maxfsuniforms)
DEFVAR(maxvaryings)
DEFVAR(dbgshader)
DEFVAR(dbgubo)
DEFVAR(shaders) // globalname was useshaders
DEFVAR(shaderprecision)
DEFVAR(reserveshadowmaptc)
DEFVAR(reservedynlighttc)
DEFVAR(minimizedynlighttcusage)
DEFVAR(defershaders)
DEFVAR(nativeshaders)
DEFVAR(shaderdetail)
DEFVAR(maxtmus)
DEFVAR(nolights)
DEFVAR(nowater)
DEFVAR(nomasks)

// engine/shadowmap.cpp
DEFVAR(shadowmap)
DEFVAR(shadowmapsize)
DEFVAR(shadowmapradius)
DEFVAR(shadowmapheight)
DEFVAR(ffshadowmapdist)
DEFVAR(shadowmapdist)
DEFVAR(fpshadowmap)
DEFVAR(shadowmapprecision)
DEFVAR(shadowmapambient)
DEFVAR(shadowmapintensity)
DEFVAR(blurshadowmap)
DEFVAR(blursmsigma)
DEFVAR(shadowmapcasters)
DEFVAR(shadowmapangle)
DEFVAR(shadowmapbias)
DEFVAR(shadowmappeelbias)
DEFVAR(smdepthpeel)
DEFVAR(smoothshadowmappeel)
DEFVAR(ffsmscissor)
DEFVAR(debugsm)
#endif
// engine/skelmodel.h

DEFVAR(gpuskel)
DEFVAR(matskel)
#ifdef CLIENT
// engine/sound.cpp
DEFVAR(soundvol)
DEFVAR(musicvol)
DEFVAR(soundchans)
DEFVAR(soundfreq)
DEFVAR(soundbufferlen)
DEFVAR(uwambient)
DEFVAR(stereo)
DEFVAR(maxsoundradius)
DEFVAR(maxsoundsatonce)
DEFVAR(dbgsound)
#if defined(WIN32) || defined(_POSIX_SHARED_MEMORY_OBJECTS)
DEFVAR(mumble)
#else
DEFVAR(mumble)
#endif

// engine/texture.cpp
DEFVAR(hwtexsize)
DEFVAR(hwcubetexsize)
DEFVAR(hwmaxaniso)
DEFVAR(maxtexsize)
DEFVAR(reducefilter)
DEFVAR(texreduce)
DEFVAR(texcompress)
DEFVAR(texcompressquality)
DEFVAR(trilinear)
DEFVAR(bilinear)
DEFVAR(aniso)
DEFVAR(hwmipmap)
DEFVAR(usenp2)
DEFVAR(usedds)
DEFVAR(dbgdds)
DEFVAR(autocompactvslots)
DEFVAR(envmapsize)
DEFVAR(envmapradius)
DEFVAR(aaenvmap)
DEFVAR(compresspng)
DEFVAR(compresstga)
DEFVAR(screenshotformat)
DEFVAR(screenshotdir)

// engine/water.cpp
DEFVAR(waterreflect)
DEFVAR(waterrefract)
DEFVAR(waterenvmap)
DEFVAR(waterfallrefract)
/* vertex water */
DEFVAR(watersubdiv)
DEFVAR(waterlod)
DEFVAR(vertwater)
DEFVAR(reflectdist)
DEFVAR(watercolour)
DEFVAR(waterfog)
DEFVAR(waterfallcolour)
DEFVAR(lavacolour)
DEFVAR(lavafog)
DEFVAR(waterspec)
DEFVAR(oqwater)
DEFVAR(waterfade)
DEFVAR(reflectsize)
DEFVAR(maxreflect)
DEFVAR(maskreflect)
DEFVAR(reflectscissor)
DEFVAR(reflectvfc)
DEFVAR(refractclear)
#endif

// engine/world.cpp
DEFVAR(mapversion)
DEFVAR(mapscale) // globalname was worldscale
DEFVAR(mapsize) // globalname was worldsize
DEFVAR(maptitle)
DEFVAR(octaentsize)
DEFVAR(entselradius)
DEFVAR(entediting)
DEFVAR(attachradius)
DEFVAR(entselsnap)
DEFVAR(entmovingshadow)
DEFVAR(showentradius)
DEFVAR(entitysurf)
DEFVAR(entmoving)
DEFVAR(entautoviewdist)
DEFVAR(entdrop)

// engine/worldio.cpp

DEFVAR(savebak)
DEFVAR(dbgvars)

#ifdef CLIENT
// engine/3dgui.cpp

DEFVAR(guiautotab)
DEFVAR(guiclicktab)
DEFVAR(guipushdist)
DEFVAR(guisens)
DEFVAR(guifollow) // globalname was useguifollow
DEFVAR(gui2d) // globalname was usegui2d
#endif

// fpsgame/client.cpp

DEFVAR(chat_sound)

// fpsgame/entities.cpp

DEFVAR(triggerstate)

// fpsgame/fps.cpp

// TODO: remove those minimap related (especially xpos/ypos, as that is *not* good since it is moved differently for all screen resolutions)
DEFVAR(useminimap) // do we want minimap? set from lua
DEFVAR(minminimapzoom)
DEFVAR(maxminimapzoom)
DEFVAR(forceminminimapzoom) // these are not stored in cfg or across maps and are made for map-specific forcing.
DEFVAR(forcemaxminimapzoom)
DEFVAR(minimapradius) // minimap size, relative to screen height (1.0 = full height), max is 10.0f (maybe someone will find usage?)
DEFVAR(minimapxpos) // minimap x position relative from right edge of screen (1.0 = one minimap size from right edge)
DEFVAR(minimapypos) // like above, but from top edge.
DEFVAR(minimaprotation) // rotation of minimap
DEFVAR(minimapsides) // number of minimap sides. No need to make it bigger than 1000, 1000 is really smooth circle at very big sizes.
DEFVAR(minimaprightalign) // do we want to align minimap right? if this is 1, then we do, if 0, then it's aligned to left.
DEFVAR(smoothmove)
DEFVAR(smoothdist)

#ifdef CLIENT
// fpsgame/scoreboard.cpp
DEFVAR(scoreboard2d)
DEFVAR(showpj) // Kripken
DEFVAR(showping)
DEFVAR(showspectators)
DEFVAR(scoreboard) // globalname was showscoreboard

// intensity/client_engine_additions.cpp

DEFVAR(cameraMoveDist) // Distance camera moves per iteration
DEFVAR(cam_dist) // How much higher than the player to set the camera
DEFVAR(cameraheight) // How much higher than the player to set the camera
DEFVAR(smoothcamera) // Smoothing factor for the smooth camera. 0 means no smoothing
DEFVAR(cameraavoid) // 1 means the camera is 100% away from the closest obstacle (and therefore on the player). 0 means it is on that obstacle. 0.5 means it is midway between them.
DEFVAR(entity_gui_title)
DEFVAR(num_entity_gui_fields)

// intensity/client_system.cpp

DEFVAR(can_edit)
// The asset ID of the last saved map. This is useful if we want to reload it (if it
// crashed the server, for example
DEFVAR(last_uploaded_map_asset)

// intensity/intensity_gui.cpp

DEFVAR(message_title)
DEFVAR(message_content)
DEFVAR(input_title)
DEFVAR(input_content)
DEFVAR(input_data)
#endif

// intensity/master.cpp

DEFVAR(entered_username) // Persisted - uses "-" instead of "@, to get around sauer issue
DEFVAR(true_username) // Has "@, can be sent to server to login
DEFVAR(entered_password)
DEFVAR(hashed_password)
DEFVAR(have_master)
DEFVAR(logged_into_master)
DEFVAR(error_message)

// intensity/script_engine_lua_embedding.h

DEFVAR(blood)
DEFVAR(ragdoll)

#ifdef SERVER
// intensity/server_system.cpp

DEFVAR(fog)
DEFVAR(thirdperson)
DEFVAR(gui2d)
DEFVAR(gamespeed)
DEFVAR(paused)
DEFVAR(shaderdetail)
DEFVAR(mainmenu)
DEFVAR(envmapradius)
DEFVAR(nolights)
DEFVAR(blobs)
DEFVAR(shadowmap)
DEFVAR(maxtmus)
DEFVAR(reservevpparams)
DEFVAR(maxvpenvparams)
DEFVAR(maxvplocalparams)
DEFVAR(maxfpenvparams)
DEFVAR(maxfplocalparams)
DEFVAR(maxvsuniforms)
DEFVAR(vertwater)
DEFVAR(reflectdist)
DEFVAR(waterrefract)
DEFVAR(waterreflect)
DEFVAR(waterfade)
DEFVAR(caustics)
DEFVAR(waterfallrefract)
DEFVAR(waterfog)
DEFVAR(lavafog)
DEFVAR(showmat)
DEFVAR(fullbright)
DEFVAR(menuautoclose)
DEFVAR(outline)
DEFVAR(oqfrags)
DEFVAR(renderpath)
DEFVAR(ati_oq_bug)
DEFVAR(lightprecision)
DEFVAR(lighterror)
DEFVAR(bumperror)
DEFVAR(lightlod)
DEFVAR(ambient)
DEFVAR(skylight)
DEFVAR(watercolour)
DEFVAR(waterfallcolour)
DEFVAR(lavacolour)
#endif

// intensity/targeting.cpp

DEFVAR(has_mouse_target)

#ifndef STANDALONE
// shared/stream.cpp

DEFVAR(dbggz)

// shared/zip.cpp

DEFVAR(dbgzip)

#ifndef _EV_NODEF
}
#endif

#endif

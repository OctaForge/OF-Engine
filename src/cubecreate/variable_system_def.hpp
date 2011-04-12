// engine/animmodel.h

VARFP(lightmodels, 0, 1, 1, preloadmodelshaders);
VARFP(envmapmodels, 0, 1, 1, preloadmodelshaders);
VARFP(glowmodels, 0, 1, 1, preloadmodelshaders);
VARFP(bumpmodels, 0, 1, 1, preloadmodelshaders);
VARP(fullbrightmodels, 0, 0, 200);

// engine/blend.cpp

VARF(blendpaintmode, 0, 0, 5, stoppaintblendmap);

VAR(paintblendmapdelay, 1, 500, 3000);
VAR(paintblendmapinterval, 1, 30, 3000);

// engine/blob.cpp

#ifdef CLIENT
VARP(blobs, 0, 1, 1); // globalname was showblobs
VARFP(blobintensity, 0, 60, 100, resetblobs);
VARFP(blobheight, 1, 32, 128, resetblobs);
VARFP(blobfadelow, 1, 8, 32, resetblobs);
VARFP(blobfadehigh, 1, 8, 32, resetblobs);
VARFP(blobmargin, 0, 1, 16, resetblobs);
VAR(dbgblob, 0, 0, 1);
VARFP(blobstattris, 128, 4096, 1<<16, initsblobs);
VARFP(blobdyntris, 128, 4096, 1<<16, initdblobs);
#endif

// engine/client.cpp
VARF(rate, 0, 0, 25000, setrate);
VARF(throttle_interval, 0, 5, 30, throttle);
VARF(throttle_accel, 0, 2, 32, throttle);
VARF(throttle_decel, 0, 2, 32, throttle);
SVAR(connectname, "");
VAR(connectport, 0, 0, 0xFFFF);

#ifdef CLIENT
// engine/console.cpp
VARFP(maxcon, 10, 200, 1000, maxcon);
VAR(fullconsole, 0, 0, 1);
VARP(consize, 0, 5, 100);
VARP(miniconsize, 0, 5, 100);
VARP(miniconwidth, 0, 40, 100);
VARP(confade, 0, 30, 60);
VARP(miniconfade, 0, 30, 60);
VARP(fullconsize, 0, 75, 100);
VARP(confilter, 0, 0x7FFFFFF, 0x7FFFFFF);
VARP(fullconfilter, 0, 0x7FFFFFF, 0x7FFFFFF);
VARP(miniconfilter, 0, 0, 0x7FFFFFF);
VAR(maxhistory, 0, 1000, 10000);

// engine/decal.cpp

VARFP(maxdecaltris, 1, 1024, 16384, initdecals);
VARP(decalfade, 1000, 10000, 60000);
VAR(dbgdec, 0, 0, 1);
VARP(decals, 0, 1, 1); // globalname was showdecals
VARP(maxdecaldistance, 1, 512, 10000);

// engine/depthfx.h
VARP(depthfxfpscale, 1, 1<<12, 1<<16);
VARP(depthfxscale, 1, 1<<6, 1<<8);
VARP(depthfxblend, 1, 16, 64);
VARP(depthfxpartblend, 1, 8, 64);
VAR(depthfxmargin, 0, 16, 64);
VAR(depthfxbias, 0, 1, 64);
VARFP(fpdepthfx, 0, 0, 1, cleanupdepthfx);
VARFP(depthfxprecision, 0, 0, 1, cleanupdepthfx);
VARP(depthfxemuprecision, 0, 1, 1);
VARFP(depthfxsize, 6, 7, 12, cleanupdepthfx);
VARP(depthfx, 0, 1, 1);
VARP(depthfxparts, 0, 1, 1);
VARFP(depthfxrect, 0, 0, 1, cleanupdepthfx);
VARFP(depthfxfilter, 0, 1, 1, cleanupdepthfx);
VARP(blurdepthfx, 0, 1, 7);
VARP(blurdepthfxsigma, 1, 50, 200);
VAR(depthfxscissor, 0, 2, 2);
VAR(debugdepthfx, 0, 0, 1);

// engine/dynlight.cpp
VARP(ffdynlights, 0, min(5, DYNLIGHTMASK), DYNLIGHTMASK);
VARP(maxdynlights, 0, min(3, MAXDYNLIGHTS), MAXDYNLIGHTS);
VARP(dynlightdist, 0, 1024, 10000);

// engine/explosion.h

VARP(explosion2d, 0, 0, 1);

// engine/glare.cpp
VARFP(glaresize, 6, 8, 10, cleanupglare);
VARP(glare, 0, 0, 1);
VARP(blurglare, 0, 4, 7);
VARP(blurglaresigma, 1, 50, 200);
VAR(debugglare, 0, 0, 1);
FVARP(glarescale, 0.0f, 1.0f, 8.0f);

// engine/grass.cpp
VARP(grass, 0, 0, 1);
VAR(dbggrass, 0, 0, 1);
VARP(grassdist, 0, 256, 10000);
FVARP(grasstaper, 0.0f, 0.2f, 1.0f);
FVARP(grassstep, 0.5f, 2.0f, 8.0f);
VARP(grassheight, 1, 4, 64);
VARR(grassanimmillis, 0, 3000, 60000);
FVARR(grassanimscale, 0.0f, 0.03f, 1.0f);
VARR(grassscale, 1, 2, 64);
VARFR(grasscolour, 0, 0xFFFFFF, 0xFFFFFF, grasscolour);
VARR(grassalpha, 0, 1, 1);

// engine/lensflare.h

VAR(flarelights, 0, 0, 1);
VARP(flarecutoff, 0, 1000, 10000);
VARP(flaresize, 20, 100, 500);

// engine/lightmap.cpp
VARR(lightprecision, 1, 32, 1024);
VARR(lighterror, 1, 8, 16);
VARR(bumperror, 1, 3, 16);
VARR(lightlod, 0, 0, 10);
VARFR(ambient, 1, 0x191919, 0xFFFFFF, ambient);
VARFR(skylight, 0, 0, 0xFFFFFF, skylight);
VAR(lmshadows, 0, 2, 2); // global name was lmshadows_
VAR(lmaa, 0, 3, 3); // global name was lmaa_
VAR(lightcompress, 0, 3, 6);
VARR(skytexturelight, 0, 1, 1);
VARR(blurlms, 0, 0, 2);
VARR(blurskylight, 0, 0, 2);
VAR(edgetolerance, 1, 4, 8);
VAR(adaptivesample, 0, 2, 2);
VARF(lightcachesize, 4, 6, 12, clearlightcache);
VARP(lightthreads, 1, 1, 16);
VAR(patchnormals, 0, 0, 1);
VARF(fullbright, 0, 0, 1, fullbright);
VARF(fullbrightlevel, 0, 128, 255, fullbrightlevel);
VARF(convertlms, 0, 1, 1, resetlights);
VARF(roundlightmaptex, 0, 4, 16, resetlights);
VARF(batchlightmaps, 0, 4, 256, resetlights);

// engine/lightning.h

VAR(lnjittermillis, 0, 100, 1000);
VAR(lnjitterradius, 0, 4, 100);
FVAR(lnjitterscale, 0.0f, 0.5f, 10.0f);
VAR(lnscrollmillis, 1, 300, 5000);
FVAR(lnscrollscale, 0.0f, 0.125f, 10.0f);
FVAR(lnblendpower, 0.0f, 0.25f, 1000.0f);

// engine/main.cpp
VARF(scr_w, SCR_MINW, -1, SCR_MAXW, initwarningres);
VARF(scr_h, SCR_MINH, -1, SCR_MAXH, initwarningres);
VARF(colorbits, 0, 0, 32, initwarningdepth);
VARF(depthbits, 0, 0, 32, initwarningdbpre);
VARF(stencilbits, 0, 0, 32, initwarningsbpre);
VARF(fsaa, -1, -1, 16, initwarningaa);
VARF(vsync, -1, -1, 1, initwarningvs);
VARF(fullscreen, 0, 0, 1, fullscreen);
VARFP(gamma, 30, 100, 300, gamma);
VAR(dbgmodes, 0, 0, 1);
VAR(iskeydown, 0, 0, 1);
VAR(iskeyup, 0, 0, 1);
VAR(ismousedown, 0, 0, 1);
VAR(ismouseup, 0, 0, 1);
VARF(gamespeed, 10, 100, 1000, gamespeed);
VARF(paused, 0, 0, 1, paused);
VAR(mainmenufps, 0, 60, 1000);
VARP(maxfps, 0, 100, 1000);
VARFP(clockerror, 990000, 1000000, 1010000, clockreset);
VARFP(clockfix, 0, 0, 1, clockreset);

// engine/material.cpp

VARF(optmats, 0, 1, 1, allchanged);
VARP(showmat, 0, 1, 1);
VARP(glassenv, 0, 1, 1);
VARFP(waterfallenv, 0, 1, 1, preloadwatershaders);

// engine/menus.cpp

VARP(menudistance, 16, 10, 256);
VARP(menuautoclose, 32, 120, 4096);
VARP(applydialog, 0, 1, 1);
VAR(mainmenu, 1, 1, 0);

// engine/movie.cpp

VAR(dbgmovie, 0, 0, 1);
VAR(movieaccelblit, 0, 0, 1);
VAR(movieaccelyuv, 0, 0, 1);
VARP(movieaccel, 0, 1, 1);
VARP(moviesync, 0, 0, 1);
VARP(moview, 0, 320, 10000);
VARP(movieh, 0, 240, 10000);
VARP(moviefps, 1, 24, 1000);
VARP(moviesound, 0, 1, 1);
#endif

// engine/normal.cpp
VARR(lerpangle, 0, 44, 180);
VARR(lerpsubdiv, 0, 2, 4);
VARR(lerpsubdivsize, 4, 4, 128);

// engine/octa.cpp
VAR(mipvis, 0, 0, 1);
VAR(minface, 0, 1, 1);
VAR(maxmerge, 0, 6, 12);

// engine/octaedit.cpp
VARF(dragging, 0, 0, 1, dragging);
VARF(moving, 0, 0, 1, moving);
VARF(gridpower, 0, 3, 12, gridpower);
VAR(passthroughsel, 0, 0, 1);
VAR(editing, 1, 0, 0);
VAR(selectcorners, 0, 0, 1);
VARF(hmapedit, 0, 0, 1, hmapedit);
VAR(gridlookup, 0, 0, 1);
VAR(passthroughcube, 0, 1, 1);
VARP(undomegs, 0, 5, 100); // bounded by n megs
VARP(nompedit, 0, 1, 1);
VAR(brushx, 0, MAXBRUSH2, MAXBRUSH);
VAR(brushy, 0, MAXBRUSH2, MAXBRUSH);
VARP(bypassheightmapcheck, 0, 0, 1); // temp
VAR(invalidcubeguard, 0, 1, 1);
VAR(selectionsurf, 0, 0, 1);
VAR(usevdelta, 1, 0, 0);
VAR(allfaces, 0, 0, 1);
VARP(texguiwidth, 1, 12, 1000);
VARP(texguiheight, 1, 8, 1000);
VARP(texguitime, 0, 25, 1000);
VAR(texgui2d, 0, 1, 1);

// engine/octarender.cpp

VAR(printvbo, 0, 0, 1);
VARF(vbosize, 0, 1<<14, 1<<16, allchanged); // globalname was maxvbosize
VARFP(filltjoints, 0, 1, 1, allchanged);
VARF(vacubemax, 64, 512, 256*256, allchanged);
VARF(vacubesize, 32, 128, 0x1000, allchanged);
VARF(vacubemin, 0, 128, 256*256, allchanged);

// engine/physics.cpp

VARF(dynentsize, 4, 7, 12, cleardynentcache);
VARP(maxroll, 0, 3, 20);
FVAR(straferoll, 0.0f, 0.033f, 90.0f);
VAR(floatspeed, 10, 100, 1000);
VAR(physinterp, 0, 1, 1);

// engine/pvs.cpp
VAR(maxpvsblocker, 1, 512, 1<<16);
VAR(pvsleafsize, 1, 64, 1024);
VARP(pvsthreads, 1, 1, 16);
VARF(lockpvs, 0, 0, 1, lockpvs);
VAR(pvs, 0, 1, 1); // globalname was usepvs
VAR(waterpvs, 0, 1, 1); // globalname was usewaterpvs

// engine/ragdoll.h

VAR(ragdolltimestepmin, 1, 5, 50);
VAR(ragdolltimestepmax, 1, 10, 50);
FVAR(ragdollrotfric, 0.0f, 0.85f, 1.0f);
FVAR(ragdollrotfricstop, 0.0f, 0.1f, 1.0f);
VAR(ragdollconstrain, 1, 5, 100);
FVAR(ragdollbodyfric, 0.0f, 0.95f, 1.0f);
FVAR(ragdollbodyfricscale, 0.0f, 2.0f, 10.0f);
FVAR(ragdollwaterfric, 0.0f, 0.85f, 1.0f);
FVAR(ragdollgroundfric, 0.0f, 0.8f, 1.0f);
FVAR(ragdollairfric, 0.0f, 0.996f, 1.0f);
VAR(ragdollexpireoffset, 0, 1500, 30000);
VAR(ragdollwaterexpireoffset, 0, 3000, 30000);
FVAR(ragdolleyesmooth, 0.0f, 0.5f, 1.0f);
VAR(ragdolleyesmoothmillis, 1, 250, 10000);

// engine/rendergl.cpp

#ifdef CLIENT
VAR(renderpath, 1, 0, 0);
VARP(ati_skybox_bug, 0, 0, 1);
VAR(ati_oq_bug, 0, 0, 1);
VAR(ati_minmax_bug, 0, 0, 1);
VAR(ati_dph_bug, 0, 0, 1);
VAR(ati_teximage_bug, 0, 0, 1);
VAR(ati_line_bug, 0, 0, 1);
VAR(ati_cubemap_bug, 0, 0, 1);
VAR(ati_ubo_bug, 0, 0, 1);
VAR(nvidia_scissor_bug, 0, 0, 1);
VAR(apple_glsldepth_bug, 0, 0, 1);
VAR(apple_ff_bug, 0, 0, 1);
VAR(apple_vp_bug, 0, 0, 1);
VAR(sdl_backingstore_bug, -1, 0, 1);
VAR(intel_quadric_bug, 0, 0, 1);
VAR(mesa_program_bug, 0, 0, 1);
VAR(avoidshaders, 1, 0, 0);
VAR(minimizetcusage, 1, 0, 0);
VAR(emulatefog, 1, 0, 0);
VAR(usevp2, 1, 0, 0);
VAR(usevp3, 1, 0, 0);
VAR(usetexrect, 1, 0, 0);
VAR(hasglsl, 1, 0, 0);
VAR(useubo, 1, 0, 0);
VAR(usebue, 1, 0, 0);
VAR(rtscissor, 0, 1, 1);
VAR(blurtile, 0, 1, 1);
VAR(rtsharefb, 0, 1, 1);
VAR(dbgexts, 0, 0, 1);
VAR(wireframe, 0, 0, 1);
VARP(zoominvel, 0, 250, 5000);
VARP(zoomoutvel, 0, 100, 5000);
VARP(zoomfov, 10, 35, 60);
VARP(fov, 10, 100, 150);
VAR(avatarzoomfov, 10, 25, 60);
VAR(avatarfov, 10, 65, 150);
FVAR(avatardepth, 0.0f, 0.5f, 1.0f);
VARF(zoom, -1, 0, 1, zoom);
FVARP(zoomsens, 1e-3f, 1.0f, 1000.0f);
FVARP(zoomaccel, 0.0f, 0.0f, 1000.0f);
VARP(zoomautosens, 0, 1, 1);
FVARP(sensitivity, 1e-3f, 3.0f, 1000.0f);
FVARP(sensitivityscale, 1e-3f, 1.0f, 1000.0f);
VARP(invmouse, 0, 0, 1);
FVARP(mouseaccel, 0.0f, 0.0f, 1000.0f);
VAR(thirdperson, 0, 0, 2);
FVAR(thirdpersondistance, 0.0f, 20.0f, 1000.0f);
FVAR(nearplane, 1e-3f, 0.54f, 1e3f);
VAR(reflectclip, 0, 6, 64);
VAR(reflectclipavatar, -64, 0, 64);
FVAR(polygonoffsetfactor, -1e4f, -3.0f, 1e4f);
FVAR(polygonoffsetunits, -1e4f, -3.0f, 1e4f);
FVAR(depthoffset, -1e4f, 0.01f, 1e4f);
VARR(fog, 16, 4000, 1000024);
VARFR(fogcolour, 0, 0x8099B3, 0xFFFFFF, fogcolor);
VARP(skyboxglare, 0, 1, 1);
VARP(reflectmms, 0, 1, 1);
VARR(refractsky, 0, 0, 1);
VARR(minimapheight, 0, 0, 2<<16);
VARFR(minimapcolour, 0, 0, 0xFFFFFF, minimapcolor);
VARR(minimapclip, 0, 0, 1);
VARFP(minimapsize, 7, 8, 10, minimapdraw);
VARFP(motionblur, 0, 0, 1, cleanupmotionblur);
VARP(motionblurmillis, 1, 5, 1000);
FVARP(motionblurscale, 0.0f, 0.5f, 1.0f);
VARP(damagecompass, 0, 1, 1); // globalname was usedamagecompass
VARP(damagecompassfade, 1, 1000, 10000);
VARP(damagecompasssize, 1, 30, 100);
VARP(damagecompassalpha, 1, 25, 100);
VARP(damagecompassmin, 1, 25, 1000);
VARP(damagecompassmax, 1, 200, 1000);
VARFP(damagescreen, 0, 1, 1, damageblendmillis);
VARP(damagescreenfactor, 1, 7, 100);
VARP(damagescreenalpha, 1, 45, 100);
VARP(damagescreenfade, 0, 125, 1000);
VARP(damagescreenmin, 1, 10, 1000);
VARP(damagescreenmax, 1, 100, 1000);
VAR(hidestats, 0, 0, 1);
VAR(hidehud, 0, 0, 1);
VARP(crosshairsize, 0, 15, 50);
VARP(cursorsize, 0, 30, 50);
VARP(crosshairfx, 0, 1, 1);
VARP(wallclock, 0, 0, 1);
VARP(wallclock24, 0, 0, 1);
VARP(wallclocksecs, 0, 0, 1);
VARP(showfps, 0, 1, 1);
VARP(showfpsrange, 0, 0, 1);
VAR(showeditstats, 0, 0, 1);
VAR(statrate, 1, 200, 1000);
FVARP(conscale, 1e-3f, 0.33f, 1e3f);
#endif

// engine/rendermodel.cpp

VARP(oqdynent, 0, 1, 1);
VARP(animationinterpolationtime, 0, 150, 1000);
VAR(showboundingbox, 0, 0, 2);
VAR(modeltweaks, 0, 0, 1); // INTENSITY: SkyManager: tweaks for models (like ambience, glow, so we can sync it with ambientlight
FVAR(tweakmodelspec, 0.0f, 1.0f, 100.0f);
FVAR(tweakmodelambient, 0.0f, 1.0f, 100.0f);
FVAR(tweakmodelglow, 0.0f, 1.0f, 100.0f);
FVAR(tweakmodelspecglare, 0.0f, 1.0f, 100.0f);
FVAR(tweakmodelglowglare, 0.0f, 1.0f, 100.0f);
FVARR(tweakmodelscale, 0.001f, 1.0f, 100.0f); // end INTENSITY
VARP(maxmodelradiusdistance, 10, 200, 1000);
VAR(animoverride, -1, 0, NUMANIMS-1);
VAR(testanims, 0, 0, 1);
VAR(testpitch, -90, 0, 90);

#ifdef CLIENT
// engine/renderparticles.cpp
VARP(particlesize, 20, 100, 500);
VARP(emitmillis, 1, 17, 1000);
VAR(dbgpseed, 0, 0, 1);
VARP(outlinemeters, 0, 0, 1);
VARFP(maxparticles, 10, 4000, 40000, particleinit);
VARFP(fewparticles, 10, 100, 40000, particleinit);
VARP(particleglare, 0, 2, 100);
VAR(debugparticles, 0, 0, 1);
VARP(maxparticledistance, 256, 1024, 4096);
VARP(maxtrail, 1, 500, 10000);
VARP(particletext, 0, 1, 1);
VARP(maxparticletextdistance, 0, 128, 10000);
VARP(showparticles, 0, 1, 1);
VAR(cullparticles, 0, 1, 1);
VAR(replayparticles, 0, 1, 1);
VAR(seedparticles, 0, 3000, 10000); // globalname was seedmillis
VAR(dbgpcull, 0, 0, 1);
FVARFP(editpartsize, 0.0f, 2.0f, 100.0f, particleinitf);

// engine/rendersky.cpp
SVARFR(starbox, "", loadstars); // INTENSITY: SkyManager: various star and sun variables
VARR(starboxtint, 0, 0xFFFFFF, 0xFFFFFF);
FVARR(spinstars, -720.0f, 0.0f, 720.0f);
VARR(yawstars, 0, 0, 360); // end INTENSITY
SVARFR(skybox, "", loadsky);
FVARR(skyboxalpha, 0.0f, 0.999f, 1.0f); // INTENSITY: Less than one so it won't occlude and cause starbox to be culled.
VAR(skyboxtint, 0, 0xFFFFFF, 0xFFFFFF); // INTENSITY: was skyboxcolour
FVARR(spinsky, -720.0f, 0.0f, 720.0f);
VARR(yawsky, 0, 0, 360);
SVARFR(sunbox, "", loadsun);
FVARR(sunboxalpha, 0.0f, 1.0f, 1.0f);
VARR(sunboxtint, 0, 0xFFFFFF, 0xFFFFFF);
FVAR(spinsun, -720.0f, 0.0f, 720.0f);
VARFR(yawsun, 0, 0, 360, skymillis);
SVARFR(cloudbox, "", loadclouds);
FVARR(cloudboxalpha, 0.0f, 0.999f, 1.0f); // INTENSITY: was 1
VARR(cloudboxtint, 0, 0xFFFFFF, 0xFFFFFF);
FVARR(spinclouds, -720.0f, 0.0f, 720.0f);
VARR(yawclouds, 0, 0, 360);
FVARR(cloudclip, 0.0f, 0.5f, 1.0f);
SVARFR(cloudlayer, "", cloudoverlay);
FVARR(cloudscrollx, -16.0f, 0.0f, 16.0f);
FVARR(cloudscrolly, -16.0f, 0.0f, 16.0f);
FVARR(cloudscale, 0.001f, 1.0f, 64.0f);
FVARR(spincloudlayer, -720.0f, 0.0f, 720.0f);
VARR(yawcloudlayer, 0, 0, 360);
FVARR(cloudheight, -1.0f, 0.2f, 1.0f);
FVARR(cloudfade, 0.0f, 0.2f, 1.0f);
FVARR(cloudalpha, 0.0f, 1.0f, 1.0f);
VARR(cloudsubdiv, 4, 16, 64);
VARR(cloudtint, 0, 0xFFFFFF, 0xFFFFFF);
SVARFR(altcloudlayer, "", altcloudoverlay);
FVARR(altcloudscrollx, -16.0f, 0.0f, 16.0f);
FVARR(altcloudscrolly, -16.0f, 0.0f, 16.0f);
FVARR(altcloudscale, 0.001f, 1.0f, 64.0f);
FVARR(spinaltcloudlayer, -720.0f, 0.0f, 720.0f);
VARR(yawaltcloudlayer, 0, 0, 360);
FVARR(altcloudheight, -1.0f, 0.1f, 1.0f);
FVARR(altcloudfade, 0.0f, 0.1f, 1.0f);
FVARR(altcloudalpha, 0.0f, 0.0f, 1.0f);
VARR(altcloudsubdiv, 4, 16, 64);
VARR(altcloudtint, 0, 0xFFFFFF, 0xFFFFFF);
FVARR(fogdomeheight, -1.0f, -0.5f, 1.0f);
FVARR(fogdomemin, 0.0f, 0.0f, 1.0f);
FVARR(fogdomemax, 0.0f, 0.0f, 1.0f);
VARR(fogdomecap, 0, 1, 1);
FVARR(fogdomeclip, 0.0f, 1.0f, 1.0f);
VARFR(fogdomecolour, 0, 0, 0xFFFFFF, fogdomecolor);
VARP(sparklyfix, 0, 0, 1);
VAR(showsky, 0, 1, 1);
VAR(clipsky, 0, 1, 1);
VAR(clampsky, 0, 1, 1);
VARR(fogdomeclouds, 0, 1, 1);
VARR(skytexture, 0, 1, 1); // globalname was useskytexture

// engine/renderva.cpp

VAR(oqfrags, 0, 8, 64);
VAR(oqwait, 0, 1, 1);
VAR(oqmm, 0, 4, 8);
VAR(outline, 0, 0, 0xFFFFFF);
VAR(dtoutline, 0, 1, 1);
VAR(blendbrushcolor, 0, 0x0000C0, 0xFFFFFF);
VAR(oqdist, 0, 256, 1024);
VAR(zpass, 0, 1, 1);
VAR(glowpass, 0, 1, 1);
VAR(envpass, 0, 1, 1);
VAR(batchgeom, 0, 1, 1);
VARR(causticscale, 0, 100, 10000);
VARR(causticmillis, 0, 75, 1000);
VARFP(caustics, 0, 1, 1, loadcaustics);
VAR(oqgeom, 0, 1, 1);
VAR(dbgffsm, 0, 0, 1);
VAR(dbgffdl, 0, 0, 1);
VAR(ffdlscissor, 0, 1, 1);
#endif
// engine/serverbrowser.cpp

VARP(searchlan, 0, 0, 1);
VARP(servpingrate, 1000, 5000, 60000);
VARP(servpingdecay, 1000, 15000, 60000);
VARP(maxservpings, 0, 10, 1000);

// engine/server.cpp
VAR(updatemaster, 0, 1, 1); // globalname was allowupdatemaster
SVARF(mastername, server::defaultmaster(), disconnectmaster);
VAR(serveruprate, 0, 0, INT_MAX);
SVAR(serverip, "");
VARFP(serverport, 0, server::serverport(), 0xFFFF, serverport); // not hex var

#ifdef CLIENT
// engine/shader.cpp
VAR(reservevpparams, 1, 16, 0);
VAR(maxvpenvparams, 1, 0, 0);
VAR(maxvplocalparams, 1, 0, 0);
VAR(maxfpenvparams, 1, 0, 0);
VAR(maxfplocalparams, 1, 0, 0);
VAR(maxtexcoords, 1, 0, 0);
VAR(maxvsuniforms, 1, 0, 0);
VAR(maxfsuniforms, 1, 0, 0);
VAR(maxvaryings, 1, 0, 0);
VAR(dbgshader, 0, 0, 2);
VAR(dbgubo, 0, 0, 1);
VARF(shaders, -1, -1, 1, initwarningshd); // globalname was useshaders
VARF(shaderprecision, 0, 0, 2, initwarningshdpre);
VAR(reserveshadowmaptc, 1, 0, 0);
VAR(reservedynlighttc, 1, 0, 0);
VAR(minimizedynlighttcusage, 1, 0, 0);
VAR(defershaders, 0, 1, 1);
VARF(nativeshaders, 0, 1, 1, fixshaderdetail);
VARFP(shaderdetail, 0, MAXSHADERDETAIL, MAXSHADERDETAIL, fixshaderdetail);
VAR(maxtmus, 1, 0, 0);
VAR(nolights, 1, 0, 0);
VAR(nowater, 1, 0, 0);
VAR(nomasks, 1, 0, 0);

// engine/shadowmap.cpp
VARP(shadowmap, 0, 0, 1);
VARFP(shadowmapsize, 7, 9, 11, cleanshadowmap);
VARP(shadowmapradius, 64, 96, 256);
VAR(shadowmapheight, 0, 32, 128);
VARP(ffshadowmapdist, 128, 1024, 4096);
VARP(shadowmapdist, 128, 256, 512);
VARFP(fpshadowmap, 0, 0, 1, cleanshadowmap);
VARFP(shadowmapprecision, 0, 0, 1, cleanshadowmap);
VARFR(shadowmapambient, 0, 0, 0xFFFFFF, shadowmapambient);
VARP(shadowmapintensity, 0, 40, 100);
VARP(blurshadowmap, 0, 1, 3);
VARP(blursmsigma, 1, 100, 200);
VAR(shadowmapcasters, 1, 0, 0);
VARFR(shadowmapangle, 0, 0, 360, shadowmapangle);
VARP(shadowmapbias, 0, 5, 1024);
VARP(shadowmappeelbias, 0, 20, 1024);
VAR(smdepthpeel, 0, 1, 1);
VAR(smoothshadowmappeel, 1, 0, 0);
VAR(ffsmscissor, 0, 1, 1);
VAR(debugsm, 0, 0, 1);
#endif
// engine/skelmodel.h

VARP(gpuskel, 0, 1, 1);
VARP(matskel, 0, 1, 1);
#ifdef CLIENT
// engine/sound.cpp
VARFP(soundvol, 0, 255, 255, soundvol);
VARFP(musicvol, 0, 128, 255, musicvol);
VARF(soundchans, 1, 32, 128, initwarningsnd);
VARF(soundfreq, 0, MIX_DEFAULT_FREQUENCY, 44100, initwarningsnd);
VARF(soundbufferlen, 128, 1024, 4096, initwarningsnd);
VARR(uwambient, 0, 0, 1);
VAR(stereo, 0, 1, 1);
VARP(maxsoundradius, 0, 340, 10000);
VARP(maxsoundsatonce, 0, 5, 100);
VAR(dbgsound, 0, 0, 1);
#if defined(WIN32) || defined(_POSIX_SHARED_MEMORY_OBJECTS)
VARFP(mumble, 0, 1, 1, mumble);
#else
VARFP(mumble, 0, 0, 1, mumble);
#endif

// engine/texture.cpp
VAR(hwtexsize, 1, 0, 0);
VAR(hwcubetexsize, 1, 0, 0);
VAR(hwmaxaniso, 1, 0, 0);
VARFP(maxtexsize, 0, 0, 1<<12, initwarningtexq);
VARFP(reducefilter, 0, 1, 1, initwarningtexq);
VARFP(texreduce, 0, 0, 12, initwarningtexq);
VARFP(texcompress, 0, 1<<10, 1<<12, initwarningtexq);
VARFP(texcompressquality, -1, -1, 1, setuptexcompress);
VARFP(trilinear, 0, 1, 1, initwarningtexf);
VARFP(bilinear, 0, 1, 1, initwarningtexf);
VARFP(aniso, 0, 0, 16, initwarningtexf);
VARFP(hwmipmap, 0, 0, 1, initwarningtexf);
VARFP(usenp2, 0, 0, 1, initwarningtexq);
VAR(usedds, 0, 1, 1);
VAR(dbgdds, 0, 0, 1);
VARP(autocompactvslots, 0, 256, 0x10000);
VARFP(envmapsize, 4, 7, 10, setupmaterials);
VAR(envmapradius, 0, 128, 10000);
VAR(aaenvmap, 0, 2, 4);
VARP(compresspng, 0, 9, 9);
VARP(compresstga, 0, 1, 1);
VARP(screenshotformat, 0, IMG_PNG, NUMIMG-1);
SVARP(screenshotdir, "");

// engine/water.cpp
VARFP(waterreflect, 0, 1, 1, preloadwaters);
VARFP(waterrefract, 0, 1, 1, preloadwaters);
VARFP(waterenvmap, 0, 1, 1, preloadwaters);
VARFP(waterfallrefract, 0, 0, 1, preloadwaters);
/* vertex water */
VARP(watersubdiv, 0, 2, 3);
VARP(waterlod, 0, 1, 3);
VARFP(vertwater, 0, 1, 1, allchanged);
VARP(reflectdist, 0, 2000, 10000);
VARFR(watercolour, 0, 0x144650, 0xFFFFFF, watercolor);
VARR(waterfog, 0, 150, 10000);
VARFR(waterfallcolour, 0, 0, 0xFFFFFF, waterfallcolor);
VARFR(lavacolour, 0, 0xFF4000, 0xFFFFFF, lavacolor);
VARR(lavafog, 0, 50, 10000);
VARR(waterspec, 0, 150, 1000);
VAR(oqwater, 0, 2, 2);
VARFP(waterfade, 0, 1, 1, preloadwaters);
VARFP(reflectsize, 6, 8, 10, cleanreflections);
VARP(maxreflect, 1, 1, 8);
VAR(maskreflect, 0, 2, 16);
VAR(reflectscissor, 0, 1, 1);
VAR(reflectvfc, 0, 1, 1);
VARR(refractclear, 0, 0, 1);
#endif

// engine/world.cpp
VARR(mapversion, 1, MAPVERSION, 0);
VARR(mapscale, 1, 0, 0); // globalname was worldscale
VARR(mapsize, 1, 0, 0); // globalname was worldsize
SVARR(maptitle, "Untitled Map by Unknown");
VAR(octaentsize, 0, 128, 1024);
VAR(entselradius, 0, 2, 10);
VARF(entediting, 0, 0, 1, entediting);
VAR(attachradius, 1, 100, 1000);
VAR(entselsnap, 0, 0, 1);
VAR(entmovingshadow, 0, 1, 1);
VAR(showentradius, 0, 1, 1);
VAR(entitysurf, 0, 0, 1);
VARF(entmoving, 0, 0, 2, entmoving);
VAR(entautoviewdist, 0, 25, 100);
VAR(entdrop, 0, 2, 3);

// engine/worldio.cpp

VARP(savebak, 0, 2, 2);
VAR(dbgvars, 0, 0, 1);

#ifdef CLIENT
// engine/3dgui.cpp

VARP(guiautotab, 6, 16, 40);
VARP(guiclicktab, 0, 1, 1);
VARP(guipushdist, 1, 4, 64);
FVARP(guisens, 1e-3f, 1.0f, 1e3f);
VARP(guifollow, 0, 1, 1); // globalname was useguifollow
VARP(gui2d, 0, 1, 1); // globalname was usegui2d
#endif

// fpsgame/client.cpp

SVARP(chat_sound, "olpc/FlavioGaete/Vla_G_Major");

// fpsgame/entities.cpp

VAR(triggerstate, -1, 0, 1);

// fpsgame/fps.cpp

// TODO: remove those minimap related (especially xpos/ypos, as that is *not* good since it is moved differently for all screen resolutions)
VAR(useminimap, 0, 0, 1); // do we want minimap? set from lua
VARP(minminimapzoom, 0, 384, 10000);
VARP(maxminimapzoom, 1, 1024, 10000);
VAR(forceminminimapzoom, -1, -1, 10000); // these are not stored in cfg or across maps and are made for map-specific forcing.
VAR(forcemaxminimapzoom, -1, -1, 10000);
FVAR(minimapradius, 0.0f, 0.3f, 10.0f); // minimap size, relative to screen height (1.0 = full height), max is 10.0f (maybe someone will find usage?)
FVAR(minimapxpos, -10000.0f, 0.1f, 10000.0f); // minimap x position relative from right edge of screen (1.0 = one minimap size from right edge)
FVAR(minimapypos, -10000.0f, 0.1f, 10000.0f); // like above, but from top edge.
FVAR(minimaprotation, 0.0f, 0.0f, 360.0f); // rotation of minimap
VAR(minimapsides, 3, 10, 1000); // number of minimap sides. No need to make it bigger than 1000, 1000 is really smooth circle at very big sizes.
VAR(minimaprightalign, 0, 1, 1); // do we want to align minimap right? if this is 1, then we do, if 0, then it's aligned to left.
VARP(smoothmove, 0, 75, 100);
VARP(smoothdist, 0, 32, 64);

#ifdef CLIENT
// fpsgame/scoreboard.cpp
VARP(scoreboard2d, 0, 1, 1);
VARP(showpj, 0, 1, 1); // Kripken
VARP(showping, 0, 1, 1);
VARP(showspectators, 0, 1, 1);
VARF(scoreboard, 0, 0, 1, scoreboard); // globalname was showscoreboard

// intensity/client_engine_additions.cpp

VAR(cameraMoveDist, 5, 10, 200); // Distance camera moves per iteration
VAR(cam_dist, 0, 50, 200); // How much higher than the player to set the camera
FVARP(cameraheight, 0.0f, 10.0f, 50.0f); // How much higher than the player to set the camera
FVAR(smoothcamera, 0.0f, 0.2f, 100.0f); // Smoothing factor for the smooth camera. 0 means no smoothing
FVARP(cameraavoid, 0.0f, 0.33f, 1.0f); // 1 means the camera is 100% away from the closest obstacle (and therefore on the player). 0 means it is on that obstacle. 0.5 means it is midway between them.
SVAR(entity_gui_title, "");
VAR(num_entity_gui_fields, 0, 0, 13);

// intensity/client_system.cpp

VAR(can_edit, 0, 0, 1);
// The asset ID of the last saved map. This is useful if we want to reload it (if it
// crashed the server, for example
SVARP(last_uploaded_map_asset, "");

// intensity/intensity_gui.cpp

SVAR(message_title, "");
SVAR(message_content, "");
SVAR(input_title, "");
SVAR(input_content, "");
SVAR(input_data, "");
#endif

// intensity/master.cpp

SVARP(entered_username, ""); // Persisted - uses "-" instead of "@, to get around sauer issue
SVAR(true_username, ""); // Has "@, can be sent to server to login
SVAR(entered_password, "");
SVARP(hashed_password, "");
VAR(have_master, 0, 1, 1);
VAR(logged_into_master, 0, 0, 1);
SVAR(error_message, "");

// intensity/scripting_system_lua_def.hpp

VARP(blood, 0, 1, 1);
VARP(ragdoll, 0, 1, 1);

#ifdef SERVER
// intensity/server_system.cpp

VARR(fog, 1, 2, 300000);
VAR(thirdperson, 0, 1, 2);
VAR(gui2d, 1, 1, 0);
VAR(gamespeed, 0, 100, 100);
VAR(paused, 0, 0, 1);
VAR(shaderdetail, 0, 1, 3);
VAR(mainmenu, 1, 0, 0);
VAR(envmapradius, 0, 128, 10000);
VAR(nolights, 1, 0, 0);
VAR(blobs, 0, 1, 1);
VAR(shadowmap, 0, 0, 1);
VAR(maxtmus, 1, 0, 0);
VAR(reservevpparams, 1, 16, 0);
VAR(maxvpenvparams, 1, 0, 0);
VAR(maxvplocalparams, 1, 0, 0);
VAR(maxfpenvparams, 1, 0, 0);
VAR(maxfplocalparams, 1, 0, 0);
VAR(maxvsuniforms, 1, 0, 0);
VAR(vertwater, 0, 1, 1);
VAR(reflectdist, 0, 2000, 10000);
VAR(waterrefract, 0, 1, 1);
VAR(waterreflect, 0, 1, 1);
VAR(waterfade, 0, 1, 1);
VAR(caustics, 0, 1, 1);
VAR(waterfallrefract, 0, 0, 1);
VAR(waterfog, 0, 150, 10000);
VAR(lavafog, 0, 50, 10000);
VAR(showmat, 0, 1, 1);
VAR(fullbright, 0, 0, 1);
VAR(menuautoclose, 32, 120, 4096);
VAR(outline, 0, 0, 0xFFFFFF);
VAR(oqfrags, 0, 8, 64);
VAR(renderpath, 1, R_FIXEDFUNCTION, 0);
VAR(ati_oq_bug, 0, 0, 1);
VAR(lightprecision, 1, 32, 1024);
VAR(lighterror, 1, 8, 16);
VAR(bumperror, 1, 3, 16);
VAR(lightlod, 0, 0, 10);
VAR(ambient, 1, 0x191919, 0xFFFFFF);
VAR(skylight, 0, 0, 0xFFFFFF);
VAR(watercolour, 0, 0x144650, 0xFFFFFF);
VAR(waterfallcolour, 0, 0, 0xFFFFFF);
VAR(lavacolour, 0, 0xFF4000, 0xFFFFFF);
#endif

// intensity/targeting.cpp

VAR(has_mouse_target, 0, 0, 1);

#ifndef STANDALONE
// shared/stream.cpp

VAR(dbggz, 0, 0, 1);

// shared/zip.cpp

VAR(dbgzip, 0, 0, 1);
#endif

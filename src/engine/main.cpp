// main.cpp: initialisation & main loop

#include "engine.h"

#include "system_manager.h" // INTENSITY
#include "client_system.h" // INTENSITY
#include "intensity_gui.h" // INTENSITY

void cleanup()
{
    recorder::stop();
    cleanupserver();
    SDL_ShowCursor(1);
    SDL_WM_GrabInput(SDL_GRAB_OFF);
    SDL_SetGamma(1, 1, 1);
    freeocta(worldroot);
    var::clear();
    extern void clear_console(); clear_console();
    extern void clear_mdls();    clear_mdls();
    extern void clear_sound();   clear_sound();
    SDL_Quit();
}

void force_quit(); // INTENSITY

void quit()                     // normal exit
{
    if (IntensityGUI::canQuit()) // INTENSITY
        force_quit(); // INTENSITY
}

void force_quit() // INTENSITY - change quit to force_quit
{
    extern void writeinitcfg();
    writeinitcfg();

    abortconnect();
    disconnect();
    localdisconnect();
    Utility::writecfg();
    cleanup();

    SystemManager::quit(); // INTENSITY
    var::flush(); // CubeCreate

    EXEC_PYTHON_FILE("intensity/quit.py"); // INTENSITY

    exit(EXIT_SUCCESS);
}

void fatal(const char *s, ...)    // failure exit
{
    static int errors = 0;
    errors++;

    if(errors <= 2) // print up to one extra recursive error
    {
        defvformatstring(msg,s,s);
        puts(msg);

        if(errors <= 1) // avoid recursion
        {
            if(SDL_WasInit(SDL_INIT_VIDEO))
            {
                SDL_ShowCursor(1);
                SDL_WM_GrabInput(SDL_GRAB_OFF);
                SDL_SetGamma(1, 1, 1);
            }
            #ifdef WIN32
                MessageBox(NULL, msg, "Cube 2: Sauerbraten fatal error", MB_OK|MB_SYSTEMMODAL);
            #endif
            SDL_Quit();
        }
    }

    exit(EXIT_FAILURE);
}

SDL_Surface *screen = NULL;

int curtime = 0, totalmillis = 1, lastmillis = 1, skymillis = 1; // INTENSITY: SkyManager: add skymillis, for syncing

dynent *player = NULL;

int initing = NOT_INITING;
static bool restoredinits = false;

bool initwarning(const char *desc, int level, int type)
{
    if(initing < level) 
    {
        addchange(desc, type);
        return true;
    }
    return false;
}

#define SCR_MINW 320
#define SCR_MINH 200
#define SCR_MAXW 10000
#define SCR_MAXH 10000
#define SCR_DEFAULTW 1024
#define SCR_DEFAULTH 768
void writeinitcfg()
{
    if(!restoredinits) return;
    JSONObject root;
    stream *f = openfile(path("init.json", true), "w");
    if(!f) return;

    root[L"fullscreen"] = new JSONValue((double)GETIV(fullscreen));
    root[L"scr_w"] = new JSONValue((double)GETIV(scr_w));
    root[L"scr_h"] = new JSONValue((double)GETIV(scr_h));
    root[L"colorbits"] = new JSONValue((double)GETIV(colorbits));
    root[L"depthbits"] = new JSONValue((double)GETIV(depthbits));
    root[L"stencilbits"] = new JSONValue((double)GETIV(stencilbits));
    root[L"fsaa"] = new JSONValue((double)GETIV(fsaa));
    root[L"vsync"] = new JSONValue((double)GETIV(vsync));
    root[L"shaders"] = new JSONValue((double)GETIV(shaders));
    root[L"shaderprecision"] = new JSONValue((double)GETIV(shaderprecision));
    root[L"soundchans"] = new JSONValue((double)GETIV(soundchans));
    root[L"soundfreq"] = new JSONValue((double)GETIV(soundfreq));
    root[L"soundbufferlen"] = new JSONValue((double)GETIV(soundbufferlen));

    JSONValue *value = new JSONValue(root);
    f->printf("%ls", value->Stringify().c_str());
    delete value;
    delete f;
}

bool execinitcfg(const char *cfgfile, bool msg)
{
    string s;
    copystring(s, cfgfile);
    char *buf = loadfile(path(s), NULL);
    if(!buf)
    {
        if(msg) conoutf(CON_ERROR, "could not read \"%s\"", s);
        return false;
    }
    // let's parse!
    JSONValue *value = JSON::Parse(buf);
    // we can delete buf now. It's all safely stored in JSONValue.
    delete[] buf;

    if (value == NULL)
    {
        if(msg) conoutf(CON_ERROR, "could not load \"%s\"", s);
        return false;
    }
    else
    {
        JSONObject root;
        if (value->IsObject() == false)
        {
            if(msg) conoutf(CON_ERROR, "could not load JSON root object.");
            return false;
        }
        else
        {
            root = value->AsObject();
            for (JSONObject::const_iterator iter = root.begin(); iter != root.end(); ++iter)
            {
                defformatstring(cmd)("%s = %i", fromwstring(iter->first).c_str(), (int)iter->second->AsNumber());
                lua::engine.exec(cmd);
            }
        }
    }
    delete value;
    return true;
}

static void getbackgroundres(int &w, int &h)
{
    float wk = 1, hk = 1;
    if(w < 1024) wk = 1024.0f/w;
    if(h < 768) hk = 768.0f/h;
    wk = hk = max(wk, hk);
    w = int(ceil(w*wk));
    h = int(ceil(h*hk));
}

string backgroundcaption = "";
Texture *backgroundmapshot = NULL;
string backgroundmapname = "";
char *backgroundmapinfo = NULL;

void restorebackground()
{
    if(renderedframe) return;
    renderbackground(backgroundcaption[0] ? backgroundcaption : NULL, backgroundmapshot, backgroundmapname[0] ? backgroundmapname : NULL, backgroundmapinfo, true);
}

void renderbackground(const char *caption, Texture *mapshot, const char *mapname, const char *mapinfo, bool restore, bool force)
{
    if(!inbetweenframes && !force) return;

    if (!GETIV(mainmenu)) // INTENSITY: Keep playing sounds over main menu
    stopsounds(); // stop sounds while loading
 
    int w = screen->w, h = screen->h;
    getbackgroundres(w, h);
    gettextres(w, h);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, w, h, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    defaultshader->set();
    glEnable(GL_TEXTURE_2D);

    static int lastupdate = -1, lastw = -1, lasth = -1;
    static float backgroundu = 0, backgroundv = 0, detailu = 0, detailv = 0;
    static int numdecals = 0;
    static struct decal { float x, y, size; int side; } decals[12];
    if((renderedframe && !GETIV(mainmenu) && lastupdate != lastmillis) || lastw != w || lasth != h)
    {
        lastupdate = lastmillis;
        lastw = w;
        lasth = h;

        backgroundu = rndscale(1);
        backgroundv = rndscale(1);
        detailu = rndscale(1);
        detailv = rndscale(1);
#if 0 // INTENSITY: No decals
        numdecals = sizeof(decals)/sizeof(decals[0]);
        numdecals = numdecals/3 + rnd((numdecals*2)/3 + 1);
        float maxsize = min(w, h)/16.0f;
        loopi(numdecals)
        {
            decal d = { rndscale(w), rndscale(h), maxsize/2 + rndscale(maxsize/2), rnd(2) };
            decals[i] = d;
        }
#endif
    }
    else if(lastupdate != lastmillis) lastupdate = lastmillis;

    loopi(restore ? 1 : 3)
    {
        glColor3f(1, 1, 1);
        settexture("data/textures/ui/background.png", 0);
        float bu = w*0.67f/256.0f + backgroundu, bv = h*0.67f/256.0f + backgroundv;
        glBegin(GL_TRIANGLE_STRIP);
        glTexCoord2f(0,  0);  glVertex2f(0, 0);
        glTexCoord2f(bu, 0);  glVertex2f(w, 0);
        glTexCoord2f(0,  bv); glVertex2f(0, h);
        glTexCoord2f(bu, bv); glVertex2f(w, h);
        glEnd();
#if 0 // INTENSITY: No background detail
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_BLEND);
        settexture("data/textures/ui/background_detail.png", 0);
        float du = w*0.8f/512.0f + detailu, dv = h*0.8f/512.0f + detailv;
        glBegin(GL_TRIANGLE_STRIP);
        glTexCoord2f(0,  0);  glVertex2f(0, 0);
        glTexCoord2f(du, 0);  glVertex2f(w, 0);
        glTexCoord2f(0,  dv); glVertex2f(0, h);
        glTexCoord2f(du, dv); glVertex2f(w, h);
        glEnd();
#endif
        settexture("data/textures/ui/background_decal.png", 3);
        glBegin(GL_QUADS);
        loopj(numdecals)
        {
            float hsz = decals[j].size, hx = clamp(decals[j].x, hsz, w-hsz), hy = clamp(decals[j].y, hsz, h-hsz), side = decals[j].side;
            glTexCoord2f(side,   0); glVertex2f(hx-hsz, hy-hsz);
            glTexCoord2f(1-side, 0); glVertex2f(hx+hsz, hy-hsz);
            glTexCoord2f(1-side, 1); glVertex2f(hx+hsz, hy+hsz);
            glTexCoord2f(side,   1); glVertex2f(hx-hsz, hy+hsz);
        }
        glEnd();
        float lh = 0.5f*min(w, h), lw = lh*2,
              lx = 0.5f*(w - lw), ly = 0.5f*(h*0.5f - lh);
        settexture((maxtexsize ? min(maxtexsize, hwtexsize) : hwtexsize) >= 1024 && (screen->w > 1280 || screen->h > 800) ? "data/textures/ui/logo.png" : "data/textures/ui/logo.png", 3); // INTENSITY: First was suffixed '_1024', but we use a single hi-res one
        glBegin(GL_TRIANGLE_STRIP);
        glTexCoord2f(0, 0); glVertex2f(lx,    ly);
        glTexCoord2f(1, 0); glVertex2f(lx+lw, ly);
        glTexCoord2f(0, 1); glVertex2f(lx,    ly+lh);
        glTexCoord2f(1, 1); glVertex2f(lx+lw, ly+lh);
        glEnd();

        if(caption)
        {
            int tw = text_width(caption);
            float tsz = 0.04f*min(w, h)/FONTH,
                  tx = 0.5f*(w - tw*tsz), ty = h - 0.075f*1.5f*min(w, h) - 1.25f*FONTH*tsz;
            glPushMatrix();
            glTranslatef(tx, ty, 0);
            glScalef(tsz, tsz, 1);
            draw_text(caption, 0, 0);
            glPopMatrix();
        }
        if(mapshot || mapname)
        {
            int infowidth = 12*FONTH;
            float sz = 0.35f*min(w, h), msz = (0.75f*min(w, h) - sz)/(infowidth + FONTH), x = 0.5f*(w-sz), y = ly+lh - sz/15;
            if(mapinfo)
            {
                int mw, mh;
                text_bounds(mapinfo, mw, mh, infowidth);
                x -= 0.5f*(mw*msz + FONTH*msz);
            }
            if(mapshot && mapshot!=notexture)
            {
                glBindTexture(GL_TEXTURE_2D, mapshot->id);
                glBegin(GL_TRIANGLE_STRIP);
                glTexCoord2f(0, 0); glVertex2f(x,    y);
                glTexCoord2f(1, 0); glVertex2f(x+sz, y);
                glTexCoord2f(0, 1); glVertex2f(x,    y+sz);
                glTexCoord2f(1, 1); glVertex2f(x+sz, y+sz);
                glEnd();
                glEnable(GL_BLEND); // INTENSITY
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); // INTENSITY
            }
            else
            {
                int qw, qh;
                text_bounds("?", qw, qh);
                float qsz = sz*0.5f/max(qw, qh);
                glPushMatrix();
                glTranslatef(x + 0.5f*(sz - qw*qsz), y + 0.5f*(sz - qh*qsz), 0);
                glScalef(qsz, qsz, 1);
                draw_text("?", 0, 0);
                glPopMatrix();
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            }        
            settexture("data/textures/ui/mapshot_frame.png", 3);
            glBegin(GL_TRIANGLE_STRIP);
            glTexCoord2f(0, 0); glVertex2f(x,    y);
            glTexCoord2f(1, 0); glVertex2f(x+sz, y);
            glTexCoord2f(0, 1); glVertex2f(x,    y+sz);
            glTexCoord2f(1, 1); glVertex2f(x+sz, y+sz);
            glEnd();
            if(mapname)
            {
                int tw = text_width(mapname);
                float tsz = sz/(8*FONTH),
                      tx = 0.9f*sz - tw*tsz, ty = 0.9f*sz - FONTH*tsz;
                if(tx < 0.1f*sz) { tsz = 0.1f*sz/tw; tx = 0.1f; }
                glPushMatrix();
                glTranslatef(x+tx, y+ty, 0);
                glScalef(tsz, tsz, 1);
                draw_text(mapname, 0, 0);
                glPopMatrix();
            }
            if(mapinfo)
            {
                glPushMatrix();
                glTranslatef(x+sz+FONTH*msz, y, 0);
                glScalef(msz, msz, 1);
                draw_text(mapinfo, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF, -1, infowidth);
                glPopMatrix();
            }
        }
        glDisable(GL_BLEND);
        if(!restore) swapbuffers();
    }
    glDisable(GL_TEXTURE_2D);

    if(!restore)
    {
        renderedframe = false;
        copystring(backgroundcaption, caption ? caption : "");
        backgroundmapshot = mapshot;
        copystring(backgroundmapname, mapname ? mapname : "");
        if(mapinfo != backgroundmapinfo)
        {
            DELETEA(backgroundmapinfo);
            if(mapinfo) backgroundmapinfo = newstring(mapinfo);
        }
    }
}

float loadprogress = 0;

void renderprogress(float bar, const char *text, GLuint tex, bool background)   // also used during loading
{
    if(!inbetweenframes || envmapping) return;

    clientkeepalive();      // make sure our connection doesn't time out while loading maps etc.
    
    renderbackground(NULL, backgroundmapshot, NULL, NULL, true, true); // INTENSITY

    #ifdef __APPLE__
    interceptkey(SDLK_UNKNOWN); // keep the event queue awake to avoid 'beachball' cursor
    #endif

    if(background || GETIV(sdl_backingstore_bug) > 0) restorebackground();

    int w = screen->w, h = screen->h;
    getbackgroundres(w, h);
    gettextres(w, h);

    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(0, w, h, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();

    glEnable(GL_TEXTURE_2D);
    defaultshader->set();
    glColor3f(1, 1, 1);

    float fh = 0.075f*min(w, h), fw = fh*10,
          fx = renderedframe ? w - fw - fh/4 : 0.5f*(w - fw), 
          fy = renderedframe ? fh/4 : h - fh*1.5f,
          fu1 = 0/512.0f, fu2 = 511/512.0f,
          fv1 = 0/64.0f, fv2 = 52/64.0f;

    glEnable(GL_BLEND); // INTENSITY: Moved to here, to cover loading_frame as well
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); // INTENSITY: ditto

    settexture("data/textures/ui/loading_frame.png", 3);
    glBegin(GL_TRIANGLE_STRIP);
    glTexCoord2f(fu1, fv1); glVertex2f(fx,    fy);
    glTexCoord2f(fu2, fv1); glVertex2f(fx+fw, fy);
    glTexCoord2f(fu1, fv2); glVertex2f(fx,    fy+fh);
    glTexCoord2f(fu2, fv2); glVertex2f(fx+fw, fy+fh);
    glEnd();

    float bw = fw*(511 - 2*17)/511.0f, bh = fh*20/52.0f,
          bx = fx + fw*17/511.0f, by = fy + fh*16/52.0f,
          bv1 = 0/32.0f, bv2 = 20/32.0f,
          su1 = 0/32.0f, su2 = 7/32.0f, sw = fw*7/511.0f,
          eu1 = 23/32.0f, eu2 = 30/32.0f, ew = fw*7/511.0f,
          mw = bw - sw - ew,
          ex = bx+sw + max(mw*bar, fw*7/511.0f);
    if(bar > 0)
    {
        settexture("data/textures/ui/loading_bar.png", 3);
        glBegin(GL_QUADS);
        glTexCoord2f(su1, bv1); glVertex2f(bx,    by);
        glTexCoord2f(su2, bv1); glVertex2f(bx+sw, by);
        glTexCoord2f(su2, bv2); glVertex2f(bx+sw, by+bh);
        glTexCoord2f(su1, bv2); glVertex2f(bx,    by+bh);

        glTexCoord2f(su2, bv1); glVertex2f(bx+sw, by);
        glTexCoord2f(eu1, bv1); glVertex2f(ex,    by);
        glTexCoord2f(eu1, bv2); glVertex2f(ex,    by+bh);
        glTexCoord2f(su2, bv2); glVertex2f(bx+sw, by+bh);

        glTexCoord2f(eu1, bv1); glVertex2f(ex,    by);
        glTexCoord2f(eu2, bv1); glVertex2f(ex+ew, by);
        glTexCoord2f(eu2, bv2); glVertex2f(ex+ew, by+bh);
        glTexCoord2f(eu1, bv2); glVertex2f(ex,    by+bh);
        glEnd();
    }
    else if (bar < 0) // INTENSITY: Show side-to-side progress for negative values (-0 to -infinity)
    {
        float width = 0.382; // 1-golden ratio 
        float start;
        bar = -bar;
        bar = fmod(bar, 1.0f);
        if (bar < 0.5)
            start = (bar*2)*(1-width);
        else
            start = 2*(1-bar)*(1-width);

        float bw = fw*(511 - 2*17)/511.0f, bh = fh*20/52.0f,
              bx = fx + fw*17/511.0f + mw*start, by = fy + fh*16/52.0f,
              bv1 = 0/32.0f, bv2 = 20/32.0f,
              su1 = 0/32.0f, su2 = 7/32.0f, sw = fw*7/511.0f,
              eu1 = 23/32.0f, eu2 = 30/32.0f, ew = fw*7/511.0f,
              mw = bw - sw - ew,
              ex = bx+sw + max(mw*width, fw*7/511.0f);

        settexture("data/textures/ui/loading_bar.png", 3);
        glBegin(GL_QUADS);
        glTexCoord2f(su1, bv1); glVertex2f(bx,    by);
        glTexCoord2f(su2, bv1); glVertex2f(bx+sw, by);
        glTexCoord2f(su2, bv2); glVertex2f(bx+sw, by+bh);
        glTexCoord2f(su1, bv2); glVertex2f(bx,    by+bh);

        glTexCoord2f(su2, bv1); glVertex2f(bx+sw, by);
        glTexCoord2f(eu1, bv1); glVertex2f(ex,    by);
        glTexCoord2f(eu1, bv2); glVertex2f(ex,    by+bh);
        glTexCoord2f(su2, bv2); glVertex2f(bx+sw, by+bh);

        glTexCoord2f(eu1, bv1); glVertex2f(ex,    by);
        glTexCoord2f(eu2, bv1); glVertex2f(ex+ew, by);
        glTexCoord2f(eu2, bv2); glVertex2f(ex+ew, by+bh);
        glTexCoord2f(eu1, bv2); glVertex2f(ex,    by+bh);
        glEnd();
    } // INTENSITY: End side-to-side progress


    if(text)
    {
        int tw = text_width(text);
        float tsz = bh*0.8f/FONTH;
        if(tw*tsz > mw) tsz = mw/tw;
        glPushMatrix();
        glTranslatef(bx+sw, by + (bh - FONTH*tsz)/2, 0);
        glScalef(tsz, tsz, 1);
        draw_text(text, 0, 0);
        glPopMatrix();
    }

    glDisable(GL_BLEND);

    if(tex)
    {
        glBindTexture(GL_TEXTURE_2D, tex);
        float sz = 0.35f*min(w, h), x = 0.5f*(w-sz), y = 0.5f*min(w, h) - sz/15;
        glBegin(GL_TRIANGLE_STRIP);
        glTexCoord2f(0, 0); glVertex2f(x,    y);
        glTexCoord2f(1, 0); glVertex2f(x+sz, y);
        glTexCoord2f(0, 1); glVertex2f(x,    y+sz);
        glTexCoord2f(1, 1); glVertex2f(x+sz, y+sz);
        glEnd();

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        settexture("data/textures/ui/mapshot_frame.png", 3);
        glBegin(GL_TRIANGLE_STRIP);
        glTexCoord2f(0, 0); glVertex2f(x,    y);
        glTexCoord2f(1, 0); glVertex2f(x+sz, y);
        glTexCoord2f(0, 1); glVertex2f(x,    y+sz);
        glTexCoord2f(1, 1); glVertex2f(x+sz, y+sz);
        glEnd();
        glDisable(GL_BLEND);
    }

    glDisable(GL_TEXTURE_2D);

    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    swapbuffers();
}

void keyrepeat(bool on)
{
    IntensityGUI::setKeyRepeat(
        on ? SDL_DEFAULT_REPEAT_DELAY : 0,
        SDL_DEFAULT_REPEAT_INTERVAL
    );
}

static bool grabinput = false, minimized = false;

void inputgrab(bool on)
{
#ifndef WIN32
    if(!(screen->flags & SDL_FULLSCREEN)) SDL_WM_GrabInput(SDL_GRAB_OFF);
    else
#endif
    SDL_WM_GrabInput(on ? SDL_GRAB_ON : SDL_GRAB_OFF);
    SDL_ShowCursor(on ? SDL_DISABLE : SDL_ENABLE);
}

void setfullscreen(bool enable)
{
    if(!screen) return;
#if defined(WIN32) || defined(__APPLE__)
    initwarning(enable ? "fullscreen" : "windowed");
#else
    if(enable == !(screen->flags&SDL_FULLSCREEN))
    {
        SDL_WM_ToggleFullScreen(screen);
        inputgrab(grabinput);
    }
#endif
}

void setScreenScriptValues() // INTENSITY: New function
{
    using namespace lua;
    if (engine.hashandle())
    {
        engine.getg("cc").t_getraw("global");
        engine.t_set("aspect_ratio", float(GETIV(scr_w))/float(GETIV(scr_h)));
        engine.t_set("scr_w", GETIV(scr_w));
        engine.t_set("scr_h", GETIV(scr_h));
        engine.t_set("fonth", FONTH);
        engine.t_set("cam_dist", GETIV(cam_dist));
        engine.t_set("cameraheight", GETFV(cameraheight));
        engine.pop(2);
    }
}

void screenres(int *w, int *h)
{
#if !defined(WIN32) && !defined(__APPLE__)
    if(initing >= INIT_RESET)
    {
#endif
        SETV(scr_w, clamp(*w, SCR_MINW, SCR_MAXW));
        SETV(scr_h, clamp(*h, SCR_MINH, SCR_MAXH));
#if defined(WIN32) || defined(__APPLE__)
        initwarning("screen resolution");
#else
        return;
    }
    SDL_Surface *surf = SDL_SetVideoMode(clamp(*w, SCR_MINW, SCR_MAXW), clamp(*h, SCR_MINH, SCR_MAXH), 0, SDL_OPENGL|(screen->flags&SDL_FULLSCREEN ? SDL_FULLSCREEN : SDL_RESIZABLE));
    if(!surf) return;
    screen = surf;
    SETV(scr_w, screen->w);
    SETV(scr_h, screen->h);
    glViewport(0, 0, GETIV(scr_w), GETIV(scr_h));

    setScreenScriptValues(); // INTENSITY
#endif
}

void resetgamma()
{
    float f = GETIV(gamma)/100.0f;
    if(f==1) return;
    SDL_SetGamma(1, 1, 1);
    SDL_SetGamma(f, f, f);
}

int desktopw = 0, desktoph = 0;

void setupscreen(int &usedcolorbits, int &useddepthbits, int &usedfsaa)
{
    int flags = SDL_RESIZABLE;
    #if defined(WIN32) || defined(__APPLE__)
    flags = 0;
    #endif
    if(GETIV(fullscreen)) flags = SDL_FULLSCREEN;
    SDL_Rect **modes = SDL_ListModes(NULL, SDL_OPENGL|flags);
    if(modes && modes!=(SDL_Rect **)-1)
    {
        int widest = -1, best = -1;
        for(int i = 0; modes[i]; i++)
        {
            if(GETIV(dbgmodes)) conoutf(CON_DEBUG, "mode[%d]: %d x %d", i, modes[i]->w, modes[i]->h);
            if(widest < 0 || modes[i]->w > modes[widest]->w || (modes[i]->w == modes[widest]->w && modes[i]->h > modes[widest]->h)) 
                widest = i; 
        }
        if(GETIV(scr_w) < 0 || GETIV(scr_h) < 0)
        {
            int w = GETIV(scr_w), h = GETIV(scr_h), ratiow = desktopw, ratioh = desktoph;
            if(w < 0 && h < 0) { w = SCR_DEFAULTW; h = SCR_DEFAULTH; }
            if(ratiow <= 0 || ratioh <= 0) { ratiow = modes[widest]->w; ratioh = modes[widest]->h; }
            for(int i = 0; modes[i]; i++) if(modes[i]->w*ratioh == modes[i]->h*ratiow)
            {
                if(w <= modes[i]->w && h <= modes[i]->h && (best < 0 || modes[i]->w < modes[best]->w))
                    best = i;
            }
        } 
        if(best < 0)
        {
            int w = GETIV(scr_w), h = GETIV(scr_h);
            if(w < 0 && h < 0) { w = SCR_DEFAULTW; h = SCR_DEFAULTH; }
            else if(w < 0) w = (h*SCR_DEFAULTW)/SCR_DEFAULTH;
            else if(h < 0) h = (w*SCR_DEFAULTH)/SCR_DEFAULTW;
            for(int i = 0; modes[i]; i++)
            {
                if(w <= modes[i]->w && h <= modes[i]->h && (best < 0 || modes[i]->w < modes[best]->w || (modes[i]->w == modes[best]->w && modes[i]->h < modes[best]->h)))
                    best = i;
            }
        }
        if(flags&SDL_FULLSCREEN)
        {
            if(best >= 0) { SETV(scr_w, modes[best]->w); SETV(scr_h, modes[best]->h); }
            else if(desktopw > 0 && desktoph > 0) { SETV(scr_w, desktopw); SETV(scr_h, desktoph); }
            else if(widest >= 0) { SETV(scr_w, modes[widest]->w); SETV(scr_h, modes[widest]->h); } 
        }
        else if(best < 0)
        { 
            SETV(scr_w, min(GETIV(scr_w) >= 0 ? GETIV(scr_w) : (GETIV(scr_h) >= 0 ? (GETIV(scr_h)*SCR_DEFAULTW)/SCR_DEFAULTH : SCR_DEFAULTW), (int)modes[widest]->w)); 
            SETV(scr_h, min(GETIV(scr_h) >= 0 ? GETIV(scr_h) : (GETIV(scr_w) >= 0 ? (GETIV(scr_w)*SCR_DEFAULTH)/SCR_DEFAULTW : SCR_DEFAULTH), (int)modes[widest]->h));
        }
        if(GETIV(dbgmodes)) conoutf(CON_DEBUG, "selected %d x %d", GETIV(scr_w), GETIV(scr_h));
    }
    if(GETIV(scr_w) < 0 && GETIV(scr_h) < 0) { SETV(scr_w, SCR_DEFAULTW); SETV(scr_h, SCR_DEFAULTH); }
    else if(GETIV(scr_w) < 0) SETV(scr_w, (GETIV(scr_h)*SCR_DEFAULTW)/SCR_DEFAULTH);
    else if(GETIV(scr_h) < 0) SETV(scr_h, (GETIV(scr_w)*SCR_DEFAULTH)/SCR_DEFAULTW);

    bool hasbpp = true;
    if(GETIV(colorbits))
        hasbpp = SDL_VideoModeOK(GETIV(scr_w), GETIV(scr_h), GETIV(colorbits), SDL_OPENGL|flags)==GETIV(colorbits);

    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
#if SDL_VERSION_ATLEAST(1, 2, 11)
    if(GETIV(vsync)>=0) SDL_GL_SetAttribute(SDL_GL_SWAP_CONTROL, GETIV(vsync));
#endif
    static int configs[] =
    {
        0x7, /* try everything */
        0x6, 0x5, 0x3, /* try disabling one at a time */
        0x4, 0x2, 0x1, /* try disabling two at a time */
        0 /* try disabling everything */
    };
    int config = 0;
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 0);
    if(!GETIV(depthbits)) SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
    if(!GETIV(fsaa))
    {
        SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 0);
        SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 0);
    }
    loopi(sizeof(configs)/sizeof(configs[0]))
    {
        config = configs[i];
        if(!GETIV(depthbits) && config&1) continue;
        if(!GETIV(stencilbits) && config&2) continue;
        if(GETIV(fsaa)<=0 && config&4) continue;
        if(GETIV(depthbits)) SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, config&1 ? GETIV(depthbits) : 16);
        if(GETIV(stencilbits))
        {
            hasstencil = config&2 ? GETIV(stencilbits) : 0;
            SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, hasstencil);
        }
        else hasstencil = 0;
        if(GETIV(fsaa)>0)
        {
            SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, config&4 ? 1 : 0);
            SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, config&4 ? GETIV(fsaa) : 0);
        }
        screen = SDL_SetVideoMode(GETIV(scr_w), GETIV(scr_h), hasbpp ? GETIV(colorbits) : 0, SDL_OPENGL|flags);
        if(screen) break;
    }
    if(!screen) fatal("Unable to create OpenGL screen: %s", SDL_GetError());
    else
    {
        if(!hasbpp) conoutf(CON_WARN, "%d bit color buffer not supported - disabling", GETIV(colorbits));
        if(GETIV(depthbits) && (config&1)==0) conoutf(CON_WARN, "%d bit z-buffer not supported - disabling", GETIV(depthbits));
        if(GETIV(stencilbits) && (config&2)==0) conoutf(CON_WARN, "Stencil buffer not supported - disabling");
        if(GETIV(fsaa)>0 && (config&4)==0) conoutf(CON_WARN, "%dx anti-aliasing not supported - disabling", GETIV(fsaa));
    }

    SETV(scr_w, screen->w);
    SETV(scr_h, screen->h);

    usedcolorbits = hasbpp ? GETIV(colorbits) : 0;
    useddepthbits = config&1 ? GETIV(depthbits) : 0;
    usedfsaa = config&4 ? GETIV(fsaa) : 0;
}

void resetgl()
{
    clearchanges(CHANGE_GFX);

    renderbackground("resetting OpenGL");

    extern void cleanupva();
    extern void cleanupparticles();
    extern void cleanupsky();
    extern void cleanupmodels();
    extern void cleanuptextures();
    extern void cleanuplightmaps();
    extern void cleanupblendmap();
    extern void cleanshadowmap();
    extern void cleanreflections();
    extern void cleanupglare();
    extern void cleanupdepthfx();
    extern void cleanupshaders();
    extern void cleanupgl();
    recorder::cleanup();
    cleanupva();
    cleanupparticles();
    cleanupsky();
    cleanupmodels();
    cleanuptextures();
    cleanuplightmaps();
    cleanupblendmap();
    cleanshadowmap();
    cleanreflections();
    cleanupglare();
    cleanupdepthfx();
    cleanupshaders();
    cleanupgl();
    
    SDL_SetVideoMode(0, 0, 0, 0);

    int usedcolorbits = 0, useddepthbits = 0, usedfsaa = 0;
    setupscreen(usedcolorbits, useddepthbits, usedfsaa);
    gl_init(GETIV(scr_w), GETIV(scr_h), usedcolorbits, useddepthbits, usedfsaa);

    extern void reloadfonts();
    extern void reloadtextures();
    extern void reloadshaders();
    inbetweenframes = false;
    if(!reloadtexture(*notexture) ||
       !reloadtexture("data/textures/ui/logo.png") ||
       !reloadtexture("data/textures/ui/logo_1024.png") || 
       !reloadtexture("data/textures/ui/background.png") ||
       !reloadtexture("data/textures/ui/background_detail.png") ||
       !reloadtexture("data/textures/ui/background_decal.png") ||
       !reloadtexture("data/textures/ui/mapshot_frame.png") ||
       !reloadtexture("data/textures/ui/loading_frame.png") ||
       !reloadtexture("data/textures/ui/loading_bar.png"))
        fatal("failed to reload core texture");
    reloadfonts();
    inbetweenframes = true;
    renderbackground("initializing...");
    resetgamma();
    reloadshaders();
    reloadtextures();
    initlights();
    allchanged(true);
}

static int ignoremouse = 5;

vector<SDL_Event> events;

void pushevent(const SDL_Event &e)
{
    events.add(e); 
}

bool interceptkey(int sym)
{
    static int lastintercept = SDLK_UNKNOWN;
    int len = lastintercept == sym ? events.length() : 0;
    SDL_Event event;
    while(SDL_PollEvent(&event)) switch(event.type)
    {
        case SDL_MOUSEMOTION: break;
        default: pushevent(event); break;
    }
    lastintercept = sym;
    if(sym != SDLK_UNKNOWN) for(int i = len; i < events.length(); i++)
    {
        if(events[i].type == SDL_KEYDOWN && events[i].key.keysym.sym == sym) { events.remove(i); return true; }
    }
    return false;
}

static void resetmousemotion()
{
#ifndef WIN32
    if(!(screen->flags&SDL_FULLSCREEN))
    {
        SDL_WarpMouse(screen->w / 2, screen->h / 2);
    }
#endif
}

static inline bool skipmousemotion(SDL_Event &event)
{
    if(event.type != SDL_MOUSEMOTION) return true;
#ifndef WIN32
    if(!(screen->flags&SDL_FULLSCREEN))
    {
        #ifdef __APPLE__
        if(event.motion.y == 0) return true;  // let mac users drag windows via the title bar
        #endif
        if(event.motion.x == screen->w / 2 && event.motion.y == screen->h / 2) return true;  // ignore any motion events generated SDL_WarpMouse
    }
#endif
    return false;
}

static void checkmousemotion(int &dx, int &dy)
{
    loopv(events)
    {
        SDL_Event &event = events[i];
        if(skipmousemotion(event)) 
        { 
            if(i > 0) events.remove(0, i); 
            return; 
        }
        dx += event.motion.xrel;
        dy += event.motion.yrel;
    }
    events.setsize(0);
    SDL_Event event;
    while(SDL_PollEvent(&event))
    {
        if(skipmousemotion(event))
        {
            events.add(event);
            return;
        }
        dx += event.motion.xrel;
        dy += event.motion.yrel;
    }
}

// INTENSITY - getter functions so we can embed it from script
// let them return booleans so it's more comfortable
bool getkeydown()
{
    return GETIV(iskeydown);
}

bool getkeyup()
{
    return GETIV(iskeyup);
}

bool getmousedown()
{
    return GETIV(ismousedown);
}

bool getmouseup()
{
    return GETIV(ismouseup);
}

void checkinput()
{
    SDL_Event event;
    int lasttype = 0, lastbut = 0;
    while(events.length() || SDL_PollEvent(&event))
    {
        if(events.length()) event = events.remove(0);

        switch(event.type)
        {
            case SDL_QUIT:
                quit();
                break;

            #if !defined(WIN32) && !defined(__APPLE__)
            case SDL_VIDEORESIZE:
                screenres(&event.resize.w, &event.resize.h);
                break;
            #endif

            case SDL_KEYDOWN:
            case SDL_KEYUP:
                #if 0 // INTENSITY start XXX security issue
                printf("SDL_KEY: %d, %d, %d\r\n", event.key.keysym.sym, event.key.state==SDL_PRESSED, event.key.keysym.unicode);
                #endif // INTENSITY end

                // INTENSITY - set the vars
                if (event.type == SDL_KEYDOWN)
                {
                    SETV(iskeydown, 1);
                    SETV(iskeyup, 0);
                }
                else
                {
                    SETV(iskeydown, 0);
                    SETV(iskeyup, 1);
                }

                keypress(event.key.keysym.sym, event.key.state==SDL_PRESSED, event.key.keysym.unicode);
                break;

            case SDL_ACTIVEEVENT:
                if(event.active.state & SDL_APPINPUTFOCUS)
                    inputgrab(grabinput = event.active.gain!=0);
                if(event.active.state & SDL_APPACTIVE)
                    minimized = !event.active.gain;
                break;

            case SDL_MOUSEMOTION:
                if(ignoremouse) { ignoremouse--; break; }
                if(grabinput && !skipmousemotion(event))
                {
                    int dx = event.motion.xrel, dy = event.motion.yrel;
                    checkmousemotion(dx, dy);
                    resetmousemotion();
                    if(!g3d_movecursor(dx, dy)) mousemove(dx, dy);
                }
                break;

            case SDL_MOUSEBUTTONDOWN:
            case SDL_MOUSEBUTTONUP:
                #if 0 // INTENSITY start XXX security issue
                float x, y;
                g3d_cursorpos(x, y);
                printf("SDL_MOUSEBUTTON: %d, %d (at %f,%f)\r\n", event.button.button, event.button.state, x, y);
                #endif // INTENSITY end

                // INTENSITY - set the vars
                if (event.type == SDL_MOUSEBUTTONDOWN)
                {
                    SETV(ismousedown, 1);
                    SETV(ismouseup, 0);
                }
                else
                {
                    SETV(ismousedown, 0);
                    SETV(ismouseup, 1);
                }

                if(lasttype==event.type && lastbut==event.button.button) break; // why?? get event twice without it
                keypress(-event.button.button, event.button.state!=0, 0);
                lasttype = event.type;
                lastbut = event.button.button;
                break;
        }
    }
}

void swapbuffers()
{
    recorder::capture();
    SDL_GL_SwapBuffers();
}
 
void limitfps(int &millis, int curmillis)
{
    int limit = GETIV(mainmenu) && GETIV(mainmenufps) ? (GETIV(maxfps) ? min(GETIV(maxfps), GETIV(mainmenufps)) : GETIV(mainmenufps)) : GETIV(maxfps);
    if(!limit) return;
    static int fpserror = 0;
    int delay = 1000/limit - (millis-curmillis);
    if(delay < 0) fpserror = 0;
    else
    {
        fpserror += 1000%limit;
        if(fpserror >= limit)
        {
            ++delay;
            fpserror -= limit;
        }
        if(delay > 0)
        {
            REFLECT_PYTHON( time ); // INTENSITY: Using Python sleep instead of SDL works better with Python console
            time.attr("sleep")(float(delay)/1000); // INTENSITY
//            SDL_Delay(delay); // INTENSITY
            millis += delay;
        }
    }
}

#if defined(WIN32) && !defined(_DEBUG) && !defined(__GNUC__)
void stackdumper(unsigned int type, EXCEPTION_POINTERS *ep)
{
    if(!ep) fatal("unknown type");
    EXCEPTION_RECORD *er = ep->ExceptionRecord;
    CONTEXT *context = ep->ContextRecord;
    string out, t;
    formatstring(out)("Cube 2: Sauerbraten Win32 Exception: 0x%x [0x%x]\n\n", er->ExceptionCode, er->ExceptionCode==EXCEPTION_ACCESS_VIOLATION ? er->ExceptionInformation[1] : -1);
    STACKFRAME sf = {{context->Eip, 0, AddrModeFlat}, {}, {context->Ebp, 0, AddrModeFlat}, {context->Esp, 0, AddrModeFlat}, 0};
    SymInitialize(GetCurrentProcess(), NULL, TRUE);

    while(::StackWalk(IMAGE_FILE_MACHINE_I386, GetCurrentProcess(), GetCurrentThread(), &sf, context, NULL, ::SymFunctionTableAccess, ::SymGetModuleBase, NULL))
    {
        struct { IMAGEHLP_SYMBOL sym; string n; } si = { { sizeof( IMAGEHLP_SYMBOL ), 0, 0, 0, sizeof(string) } };
        IMAGEHLP_LINE li = { sizeof( IMAGEHLP_LINE ) };
        DWORD off;
        if(SymGetSymFromAddr(GetCurrentProcess(), (DWORD)sf.AddrPC.Offset, &off, &si.sym) && SymGetLineFromAddr(GetCurrentProcess(), (DWORD)sf.AddrPC.Offset, &off, &li))
        {
            char *del = strrchr(li.FileName, '\\');
            formatstring(t)("%s - %s [%d]\n", si.sym.Name, del ? del + 1 : li.FileName, li.LineNumber);
            concatstring(out, t);
        }
    }
    fatal(out);
}
#endif

#define MAXFPSHISTORY 60

int fpspos = 0, fpshistory[MAXFPSHISTORY];

void resetfpshistory()
{
    loopi(MAXFPSHISTORY) fpshistory[i] = 1;
    fpspos = 0;
}

void updatefpshistory(int millis)
{
    fpshistory[fpspos++] = max(1, min(1000, millis));
    if(fpspos>=MAXFPSHISTORY) fpspos = 0;
}

void getfps(int &fps, int &bestdiff, int &worstdiff)
{
    int total = fpshistory[MAXFPSHISTORY-1], best = total, worst = total;
    loopi(MAXFPSHISTORY-1)
    {
        int millis = fpshistory[i];
        total += millis;
        if(millis < best) best = millis;
        if(millis > worst) worst = millis;
    }

    fps = (1000*MAXFPSHISTORY)/total;
    bestdiff = 1000/best-fps;
    worstdiff = fps-1000/worst;
}

void getfps_(int *raw)
{
    int fps, bestdiff, worstdiff;
    if(*raw) fps = 1000/fpshistory[(fpspos+MAXFPSHISTORY-1)%MAXFPSHISTORY];
    else getfps(fps, bestdiff, worstdiff);
    lua::engine.push(fps);
}

bool inbetweenframes = false, renderedframe = true;

static bool findarg(int argc, char **argv, const char *str)
{
    for(int i = 1; i<argc; i++) if(strstr(argv[i], str)==argv[i]) return true;
    return false;
}

int clockrealbase = 0, clockvirtbase = 0; // INTENSITY: Removed 'static'
void clockreset() { clockrealbase = SDL_GetTicks(); clockvirtbase = totalmillis; }

int sauer_main(int argc, char **argv) // INTENSITY: Renamed so we can access it elsewhere
{
    #ifdef WIN32
    //atexit((void (__cdecl *)(void))_CrtDumpMemoryLeaks);
    #ifndef _DEBUG
    #ifndef __GNUC__
//    __try { // INTENSITY: interferes with main_actionqueue stuff
    #endif
    #endif
    #endif

    int dedicated = 0;
    char *load = NULL, *initscript = NULL;

    #define initlog(s) Logging::log_noformat(Logging::INIT, s)

    initing = INIT_RESET;

    // initialize Lua early so everything is available at the beginning.
    initlog("lua");
    lua::engine.create();
    if (!lua::engine.hashandle()) fatal("cannot initialize lua script engine");

    for(int i = 1; i<argc; i++)
    {
        if(argv[i][0]=='-') switch(argv[i][1])
        {
            case 'q': printf("Using home directory: %s\n", &argv[i][2]); sethomedir(&argv[i][2]); break;
            case 'k': printf("Adding package directory: %s\n", &argv[i][2]); addpackagedir(&argv[i][2]); break;
            case 'r': execinitcfg(argv[i][2] ? &argv[i][2] : "init.json", false); restoredinits = true; break;
            case 'd': dedicated = atoi(&argv[i][2]); if(dedicated<=0) dedicated = 2; break;
            case 'w': SETV(scr_w, clamp(atoi(&argv[i][2]), SCR_MINW, SCR_MAXW)); if(!findarg(argc, argv, "-h")) SETV(scr_h, -1); break;
            case 'h': SETV(scr_h, clamp(atoi(&argv[i][2]), SCR_MINH, SCR_MAXH)); if(!findarg(argc, argv, "-w")) SETV(scr_w, -1); break;
            case 'z': SETV(depthbits, atoi(&argv[i][2])); break;
            case 'b': SETV(colorbits, atoi(&argv[i][2])); break;
            case 'a': SETV(fsaa, atoi(&argv[i][2])); break;
            case 'v': SETV(vsync, atoi(&argv[i][2])); break;
            case 't': SETV(fullscreen, atoi(&argv[i][2])); break;
            case 's': SETV(stencilbits, atoi(&argv[i][2])); break;
            case 'f': 
            {
                int n = atoi(&argv[i][2]);
                SETV(shaders, n > 0 ? 1 : 0);
                SETVN(shaderprecision, clamp(n >= 4 ? n - 4 : n - 1, 0, 2));
                break;
            }
            case 'l': 
            {
                char pkgdir[] = "data/"; 
                load = strstr(path(&argv[i][2]), path(pkgdir)); 
                if(load) load += sizeof(pkgdir)-1; 
                else load = &argv[i][2]; 
                break;
            }
            case 'x': initscript = &argv[i][2]; break;
            default: if(!serveroption(argv[i])) gameargs.add(argv[i]); break;
        }
        else gameargs.add(argv[i]);
    }
    initing = NOT_INITING;

    if(dedicated <= 1)
    {
        initlog("sdl");

        int par = 0;
        #ifdef _DEBUG
        par = SDL_INIT_NOPARACHUTE;
        #ifdef WIN32
        SetEnvironmentVariable("SDL_DEBUG", "1");
        #endif
        #endif

        if(SDL_Init(SDL_INIT_TIMER|SDL_INIT_VIDEO|SDL_INIT_AUDIO|par)<0) fatal("Unable to initialize SDL: %s", SDL_GetError());
    }

    initlog("net");
    if(enet_initialize()<0) fatal("Unable to initialise network module");
    atexit(enet_deinitialize);
    enet_time_set(0);

    initlog("game");
    game::parseoptions(gameargs);
    initserver(dedicated>0, dedicated>1);  // never returns if dedicated
    ASSERT(dedicated <= 1);
    game::initclient();

    initlog("video: mode");
    const SDL_VideoInfo *video = SDL_GetVideoInfo();
    if(video) 
    {
        desktopw = video->current_w;
        desktoph = video->current_h;
    }
    int usedcolorbits = 0, useddepthbits = 0, usedfsaa = 0;
    setupscreen(usedcolorbits, useddepthbits, usedfsaa);

    initlog("video: misc");
    SDL_WM_SetCaption("CubeCreate", NULL); // INTENSITY
    keyrepeat(false);
    SDL_ShowCursor(0);

    initlog("gl");
    gl_checkextensions();
    gl_init(GETIV(scr_w), GETIV(scr_h), usedcolorbits, useddepthbits, usedfsaa);
    notexture = textureload("data/textures/core/notexture.png");
    if(!notexture) fatal("could not find core textures");

    initlog("console");
    var::persistvars = false;
    if(!lua::engine.execf("data/cfg/font.lua"), false) fatal("cannot find font definitions");
    if(!setfont("default")) fatal("no default font specified");

    inbetweenframes = true;
    renderbackground("initializing...");

    initlog("gl: effects");
    loadshaders();
    particleinit();
    initdecals();

    initlog("world");
    camera1 = player = game::iterdynents(0);
    emptymap(0, true, NULL, false);

    initlog("sound");
    initsound();

    initlog("cfg");

    lua::engine.execf("data/cfg/keymap.lua");
    lua::engine.execf("data/cfg/sounds.lua");
    lua::engine.execf("data/cfg/menus.lua");
    lua::engine.execf("data/cfg/brush.lua");
    lua::engine.execf("mybrushes.lua");
    if(game::savedservers()) lua::engine.execf(game::savedservers(), false);
    
    var::persistvars = true;
    
    initing = INIT_LOAD;
    if(!Utility::config_exec_json(game::savedconfig(), false)) 
    {
        lua::engine.execf(game::defaultconfig());
        Utility::writecfg(game::restoreconfig());
    }
    lua::engine.execf("data/cfg/config.lua");
    lua::engine.execf(game::autoexec(), false);
    initing = NOT_INITING;

    var::persistvars = false;

    game::loadconfigs();

    var::persistvars = true;

    initlog("Intensity Engine System Initialization");
    SystemManager::init(); // INTENSITY

    if(load)
    {
        initlog("localconnect");
        //localconnect();
        game::changemap(load);
    }

    if(initscript) lua::engine.execf(initscript);

    initlog("mainloop");

    initmumble();
    resetfpshistory();

    inputgrab(grabinput = true);

    for(;;)
    {
        try
        {
            REFLECT_PYTHON( main_actionqueue ); // INTENSITY
            main_actionqueue.attr("execute_all")(); // INTENSITY
        } catch(boost::python::error_already_set const &)
        {
            printf("Error in Python main actionqueue\r\n");
            PyErr_Print();
            assert(0 && "Halting on Python error");
        }

        static int frames = 0;
        int millis = SDL_GetTicks() - clockrealbase;
        if(GETIV(clockfix)) millis = int(millis*(double(GETIV(clockerror))/1000000));
        millis += clockvirtbase;
        if(millis<totalmillis) millis = totalmillis;
        limitfps(millis, totalmillis);
        int elapsed = millis-totalmillis;
        if(multiplayer(false)) curtime = game::ispaused() ? 0 : elapsed;
        else
        {
            static int timeerr = 0;
            int scaledtime = elapsed*GETIV(gamespeed) + timeerr;
            curtime = scaledtime/100;
            timeerr = scaledtime%100;
            if(curtime>200) curtime = 200;
            if(GETIV(paused) || game::ispaused()) curtime = 0;
        }

        skymillis += curtime; // INTENSITY: SkyManager
        lastmillis += curtime;
        totalmillis = millis;

        Logging::log(Logging::INFO, "New frame: lastmillis: %d   curtime: %d\r\n", lastmillis, curtime); // INTENSITY

        checkinput();
        menuprocess();
        tryedit();

        if(lastmillis) game::updateworld();

        serverslice(false, 0);

        if(frames) updatefpshistory(elapsed);
        frames++;

        // miscellaneous general game effects
        recomputecamera();
        updateparticles();
        updatesounds();

        if(minimized) continue;

        inbetweenframes = false;
        if(GETIV(mainmenu)) gl_drawmainmenu(screen->w, screen->h);
        else
        {
            // INTENSITY: If we have all the data we need from the server to run the game, then we can actually draw
            if (ClientSystem::scenarioStarted())
            {
                static Benchmarker renderingBenchmarker;
                renderingBenchmarker.start();

                gl_drawframe(screen->w, screen->h);

                renderingBenchmarker.stop();
                SystemManager::showBenchmark("                                        Rendering", renderingBenchmarker);
            }
        }
        swapbuffers();
        renderedframe = inbetweenframes = true;

        SystemManager::frameTrigger(curtime); // INTENSITY
    }
    
    ASSERT(0);   
    return EXIT_FAILURE;

    #if defined(WIN32) && !defined(_DEBUG) && !defined(__GNUC__)
//    } __except(stackdumper(0, GetExceptionInformation()), EXCEPTION_CONTINUE_SEARCH) { return 0; } // INTENSITY: interferes with main_actionqueue stuff
    #endif
}

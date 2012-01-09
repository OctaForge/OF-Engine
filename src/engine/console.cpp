// console.cpp: the console buffer, its display, and command line control

#include "engine.h"

#include "client_engine_additions.h" // INTENSITY
#include "of_tools.h"

vector<cline> conlines;

int commandmillis = -1;
string commandbuf;
types::String commandaction, commandprompt;
int commandpos = -1;

VARFP(maxcon, 10, 200, 1000, { while(conlines.length() > maxcon) conlines.pop(); });

#define CONSTRLEN 512

void conline(int type, const types::String& sf)        // add a line to the console buffer
{
    cline cl;
    cl.line = conlines.length()>maxcon ? conlines.pop().line : types::String();   // constrain the buffer size
    cl.type = type;
    cl.outtime = totalmillis;                       // for how long to keep line on screen
    cl.line = sf;
    conlines.insert(0, cl);
}

void conoutfv(int type, const char *fmt, va_list args)
{
    types::String buf;
    buf.vformat(fmt, args);
    conline(type, buf);
    filtertext(&buf[0], buf.get_buf());
    logoutf("%s", buf.get_buf());
}

void conoutf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    conoutfv(CON_INFO, fmt, args);
    va_end(args); 
}

void conoutf(int type, const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    conoutfv(type, fmt, args);
    va_end(args);
}

VAR(fullconsole, 0, 0, 1);

int rendercommand(int x, int y, int w)
{
    if(commandmillis < 0) return 0;

    defformatstring(s)("%s %s", !commandprompt.is_empty() ? commandprompt.get_buf() : ">", commandbuf);
    int width, height;
    text_bounds(s, width, height, w);
    y -= height;
    draw_text(s, x, y, 0xFF, 0xFF, 0xFF, 0xFF, (commandpos>=0) ? (commandpos+1+(!commandprompt.is_empty() ? commandprompt.length() : 1)) : strlen(s), w);
    return height;
}

VARP(consize, 0, 5, 100);
VARP(miniconsize, 0, 5, 100);
VARP(miniconwidth, 0, 40, 100);
VARP(confade, 0, 30, 60);
VARP(miniconfade, 0, 30, 60);
VARP(fullconsize, 0, 75, 100);
HVARP(confilter, 0, 0x7FFFFFF, 0x7FFFFFF);
HVARP(fullconfilter, 0, 0x7FFFFFF, 0x7FFFFFF);
HVARP(miniconfilter, 0, 0, 0x7FFFFFF);

int conskip = 0, miniconskip = 0;

void setconskip(int &skip, int filter, int n)
{
    int offset = abs(n), dir = n < 0 ? -1 : 1;
    skip = clamp(skip, 0, conlines.length()-1);
    while(offset)
    {
        skip += dir;
        if(!conlines.inrange(skip))
        {
            skip = clamp(skip, 0, conlines.length()-1);
            return;
        }
        if(conlines[skip].type&filter) --offset;
    }
}

int drawconlines(int conskip, int confade, int conwidth, int conheight, int conoff, int filter, int y = 0, int dir = 1)
{
    int numl = conlines.length(), offset = min(conskip, numl);

    if(confade)
    {
        if(!conskip)
        {
            numl = 0;
            loopvrev(conlines) if(totalmillis-conlines[i].outtime < confade*1000) { numl = i+1; break; }
        }
        else offset--;
    }

    int totalheight = 0;
    loopi(numl) //determine visible height
    {
        // shuffle backwards to fill if necessary
        int idx = offset+i < numl ? offset+i : --offset;
        if(!(conlines[idx].type&filter)) continue;
        const types::String& line = conlines[idx].line;
        int width, height;
        text_bounds(line.get_buf(), width, height, conwidth);
        if(totalheight + height > conheight) { numl = i; if(offset == idx) ++offset; break; }
        totalheight += height;
    }
    if(dir > 0) y = conoff;
    loopi(numl)
    {
        int idx = offset + (dir > 0 ? numl-i-1 : i);
        if(!(conlines[idx].type&filter)) continue;
        const types::String& line = conlines[idx].line;
        int width, height;
        text_bounds(line.get_buf(), width, height, conwidth);
        if(dir <= 0) y -= height; 
        draw_text(line.get_buf(), conoff, y, 0xFF, 0xFF, 0xFF, 0xFF, -1, conwidth);
        if(dir > 0) y += height;
    }
    return y+conoff;
}

int renderconsole(int w, int h, int abovehud)                   // render buffer taking into account time & scrolling
{
    int conpad = fullconsole ? 0 : FONTH/4,
        conoff = fullconsole ? FONTH : FONTH/3,
        conheight = min(fullconsole ? ((h*fullconsize/100)/FONTH)*FONTH : FONTH*consize, h - 2*(conpad + conoff)),
        conwidth = w - 2*(conpad + conoff) - (fullconsole ? 0 : game::clipconsole(w, h));
    
    extern void consolebox(int x1, int y1, int x2, int y2);
    if(fullconsole) consolebox(conpad, conpad, conwidth+conpad+2*conoff, conheight+conpad+2*conoff);
    
    int y = drawconlines(conskip, fullconsole ? 0 : confade, conwidth, conheight, conpad+conoff, fullconsole ? fullconfilter : confilter);
    if(!fullconsole && (miniconsize && miniconwidth))
        drawconlines(miniconskip, miniconfade, (miniconwidth*(w - 2*(conpad + conoff)))/100, min(FONTH*miniconsize, abovehud - y), conpad+conoff, miniconfilter, abovehud, -1);
    return fullconsole ? conheight + 2*(conpad + conoff) : y;
}

// keymap is defined externally in keymap.cfg

hashtable<int, keym> keyms(128);

void keymap(int code, const char *key)
{
    if (!key) { conoutf(CON_ERROR, "no key given"); return; }
    if(var::overridevars) { conoutf(CON_ERROR, "cannot override keymap %s", key); return; }
    keym &km = keyms[code];
    km.code = code;
    km.name = key;
}

keym *keypressed = NULL;
types::String keyaction;

const char *getkeyname(int code)
{
    keym *km = keyms.access(code);
    return km ? km->name.get_buf() : NULL;
}

lua::Table searchbinds(const char *action, int type)
{
    int n = 1;
    lua::Table t = lapi::state.new_table();
    enumerate(keyms, keym, km,
    {
        if(km.actions[type] == action)
        {
            t[n] = km.name.get_buf();
            n++;
        }
    });
    return t;
}

keym *findbind(const char *key)
{
    enumerate(keyms, keym, km,
    {
        if(!strcasecmp(km.name.get_buf(), key)) return &km;
    });
    return NULL;
}   
    
types::String getbind(const char *key, int type)
{
    keym *km = findbind(key);
    return (km ? km->actions[type] : "");
}   

void bindkey(const char *key, const char *action, int state)
{
    if(var::overridevars) { conoutf(CON_ERROR, "cannot override %sbind \"%s\"", state == 1 ? "spec" : (state == 2 ? "edit" : ""), key); return; }
    keym *km = findbind(key);
    if(!km) { conoutf(CON_ERROR, "unknown key \"%s\"", key); return; }
    types::String& binding = km->actions[state];
    if(!keypressed || keyaction!=binding) binding.clear();
    // trim white-space to make searchbinds more reliable
    while(iscubespace(*action)) action++;
    binding = types::String(action);
}

void inputcommand(const char *init, const char *action = NULL, const char *prompt = NULL) // turns input to the command line on or off
{
    commandmillis = init ? totalmillis : -1;
    SDL_EnableUNICODE(commandmillis >= 0 ? 1 : 0);
    if(!editmode) keyrepeat(commandmillis >= 0);
    copystring(commandbuf, init ? init : "");
    commandpos = -1;
    commandaction.clear();
    commandprompt.clear();
    if(action && action[0]) commandaction = action;
    if(prompt && prompt[0]) commandprompt = prompt;
}

#if !defined(WIN32) && !defined(__APPLE__)
#include <X11/Xlib.h>
#include <SDL_syswm.h>
#endif

void pasteconsole()
{
#ifdef WIN32
    UINT fmt = CF_UNICODETEXT;
    if(!IsClipboardFormatAvailable(fmt)) 
    {
        fmt = CF_TEXT;
        if(!IsClipboardFormatAvailable(fmt)) return; 
    }
    if(!OpenClipboard(NULL)) return;
    HANDLE h = GetClipboardData(fmt);
    size_t commandlen = strlen(commandbuf);
    int cblen = int(GlobalSize(h)), decoded = 0;
    ushort *cb = (ushort *)GlobalLock(h);
    switch(fmt)
    {
        case CF_UNICODETEXT:
            decoded = min(int(sizeof(commandbuf)-1-commandlen), cblen/2);
            loopi(decoded) commandbuf[commandlen++] = uni2cube(cb[i]);
            break;
        case CF_TEXT:
            decoded = min(int(sizeof(commandbuf)-1-commandlen), cblen);
            memcpy(&commandbuf[commandlen], cb, decoded);
            break;
    }    
    commandbuf[commandlen + decoded] = '\0';
    GlobalUnlock(cb);
    CloseClipboard();
#elif defined(__APPLE__)
    extern char *mac_pasteconsole(int *cblen);
    int cblen = 0;
    uchar *cb = (uchar *)mac_pasteconsole(&cblen);
    if(!cb) return;
    size_t commandlen = strlen(commandbuf);
    int decoded = decodeutf8((uchar *)&commandbuf[commandlen], int(sizeof(commandbuf)-1-commandlen), cb, cblen);
    commandbuf[commandlen + decoded] = '\0';
    free(cb);
    #else
    SDL_SysWMinfo wminfo;
    SDL_VERSION(&wminfo.version); 
    wminfo.subsystem = SDL_SYSWM_X11;
    if(!SDL_GetWMInfo(&wminfo)) return;
    int cbsize;
    uchar *cb = (uchar *)XFetchBytes(wminfo.info.x11.display, &cbsize);
    if(!cb || !cbsize) return;
    size_t commandlen = strlen(commandbuf);
    for(uchar *cbline = cb, *cbend; commandlen + 1 < sizeof(commandbuf) && cbline < &cb[cbsize]; cbline = cbend + 1)
    {
        cbend = (uchar *)memchr(cbline, '\0', &cb[cbsize] - cbline);
        if(!cbend) cbend = &cb[cbsize];
        int cblen = int(cbend-cbline), commandmax = int(sizeof(commandbuf)-1-commandlen); 
        loopi(cblen) if((cbline[i]&0xC0) == 0x80) 
        { 
            commandlen += decodeutf8((uchar *)&commandbuf[commandlen], commandmax, cbline, cblen);
            goto nextline;
        }
        cblen = min(cblen, commandmax);
        loopi(cblen) commandbuf[commandlen++] = uni2cube(*cbline++);
    nextline:
        commandbuf[commandlen] = '\n';
        if(commandlen + 1 < sizeof(commandbuf) && cbend < &cb[cbsize]) ++commandlen;
        commandbuf[commandlen] = '\0';
    }
    XFree(cb);
#endif
}

struct hline
{
    types::String buf, action, prompt;

    hline() : buf(types::String()), action(types::String()), prompt(types::String()) {}
    ~hline() {}

    void restore()
    {
        copystring(commandbuf, buf.get_buf());
        if(commandpos >= (int)strlen(commandbuf)) commandpos = -1;
        if(!action.is_empty()) commandaction = action;
        if(!prompt.is_empty()) commandprompt = prompt;
    }

    bool shouldsave()
    {
        return commandbuf != buf ||
               (!commandaction.is_empty() ? action.is_empty() || commandaction != action : !action.is_empty()) ||
               (!commandprompt.is_empty() ? action.is_empty() || commandprompt != prompt : !prompt.is_empty());
    }
    
    void save()
    {
        buf = commandbuf;
        if(!commandaction.is_empty()) action = commandaction;
        if(!commandprompt.is_empty()) prompt = commandprompt;
    }

    void run()
    {
        if (!action.is_empty())
        {
            var::cvar *ev = var::get("commandbuf");
            if (!ev)
            {
                ev = var::regvar("commandbuf", new var::cvar("commandbuf", buf.get_buf()));
            }
            else ev->set(buf.get_buf(), false);
            types::Tuple<int, const char*> err = lapi::state.do_string(action);
            if (types::get<0>(err)) logger::log(logger::ERROR, "%s\n", types::get<1>(err));
        }
        else if (buf[0] == '/')
        {
            types::Tuple<int, const char*> err = lapi::state.do_string(buf.get_buf() + 1);
            if (types::get<0>(err)) logger::log(logger::ERROR, "%s\n", types::get<1>(err));
        }
        else game::toserver((char*)buf.get_buf());
    }
};
vector< types::Shared_Ptr<hline> > history;
int histpos = 0;

VARP(maxhistory, 0, 1000, 10000);

void history_(int n)
{
    static bool inhistory = false;
    if(!inhistory && history.inrange(n))
    {
        inhistory = true;
        history[history.length()-n-1]->run();
        inhistory = false;
    }
}

struct releaseaction
{
    keym *key;
    lua::Function action;
};
vector<releaseaction> releaseactions;

const char *addreleaseaction(const lua::Function& a)
{
    if(!keypressed) return NULL;
    releaseaction &ra = releaseactions.add();
    ra.key = keypressed;
    ra.action = a;
    return keypressed->name.get_buf();
}

const char *addreleaseaction(const char *s)
{
    if(!keypressed) return NULL;
    auto ret = lapi::state.load_string(s);
    if (types::get<0>(ret))
        logger::log(logger::DEBUG, "%s\n", types::get<1>(ret));

    return addreleaseaction(types::get<2>(ret));
}

void execbind(keym &k, bool isdown)
{
    loopv(releaseactions)
    {
        releaseaction &ra = releaseactions[i];
        if(ra.key==&k)
        {
            if(!isdown) ra.action();
            releaseactions.remove(i--);
        }
    }
    if (isdown)
    {
        int state = keym::ACTION_DEFAULT;
        if (!gui::mainmenu)
        {
            if(editmode) state = keym::ACTION_EDITING;
            else if(player->state==CS_SPECTATOR) state = keym::ACTION_SPECTATOR;
        }

        if (state == keym::ACTION_DEFAULT && !gui::mainmenu)
        {
            lua::Object o = lapi::state.get<lua::Function>(
                "LAPI", "Input", "get_local_bind"
            ).call<lua::Object>(k.name);

            if (o.type() == lua::TYPE_FUNCTION)
            {
                keypressed = &k;
                o.to<lua::Function>()();
                keypressed = NULL;
                k.pressed = isdown;
                return;
            }
        }
        types::String& action = k.actions[state][0] ? k.actions[state] : k.actions[keym::ACTION_DEFAULT];
        keyaction = action;
        keypressed = &k;
        types::Tuple<int, const char*> err = lapi::state.do_string(keyaction);
        if (types::get<0>(err)) logger::log(logger::ERROR, "%s\n", types::get<1>(err));
        keypressed = NULL;
        if (keyaction!=action) keyaction.clear();
    }
    k.pressed = isdown;
}

void consolekey(int code, bool isdown, int cooked)
{
    #ifdef __APPLE__
        #define MOD_KEYS (KMOD_LMETA|KMOD_RMETA) 
    #else
        #define MOD_KEYS (KMOD_LCTRL|KMOD_RCTRL)
    #endif

    if(isdown)
    {
        switch(code)
        {
            case SDLK_RETURN:
            case SDLK_KP_ENTER:
                break;

            case SDLK_HOME:
                if(strlen(commandbuf)) commandpos = 0;
                break;

            case SDLK_END:
                commandpos = -1;
                break;

            case SDLK_DELETE:
            {
                int len = (int)strlen(commandbuf);
                if(commandpos<0) break;
                memmove(&commandbuf[commandpos], &commandbuf[commandpos+1], len - commandpos);
                if(commandpos>=len-1) commandpos = -1;
                break;
            }

            case SDLK_BACKSPACE:
            {
                int len = (int)strlen(commandbuf), i = commandpos>=0 ? commandpos : len;
                if(i<1) break;
                memmove(&commandbuf[i-1], &commandbuf[i], len - i + 1);
                if(commandpos>0) commandpos--;
                else if(!commandpos && len<=1) commandpos = -1;
                break;
            }

            case SDLK_LEFT:
                if(commandpos>0) commandpos--;
                else if(commandpos<0) commandpos = (int)strlen(commandbuf)-1;
                break;

            case SDLK_RIGHT:
                if(commandpos>=0 && ++commandpos>=(int)strlen(commandbuf)) commandpos = -1;
                break;

            case SDLK_UP:
                if(histpos > history.length()) histpos = history.length();
                if(histpos > 0) history[--histpos]->restore(); 
                break;

            case SDLK_DOWN:
                if(histpos + 1 < history.length()) history[++histpos]->restore();
                break;

            case SDLK_v:
                if(SDL_GetModState()&MOD_KEYS) { pasteconsole(); return; }
                // fall through

            default:
                if(cooked)
                {
                    size_t len = (int)strlen(commandbuf);
                    if(len+1<sizeof(commandbuf))
                    {
                        if(commandpos<0) commandbuf[len] = cooked;
                        else
                        {
                            memmove(&commandbuf[commandpos+1], &commandbuf[commandpos], len - commandpos);
                            commandbuf[commandpos++] = cooked;
                        }
                        commandbuf[len+1] = '\0';
                    }
                }
                break;
        }
    }
    else
    {
        if(code==SDLK_RETURN || code==SDLK_KP_ENTER)
        {
            hline *h = NULL;
            if(commandbuf[0])
            {
                if(history.empty() || history.last()->shouldsave())
                {
                    if(maxhistory && history.length() >= maxhistory)
                    {
                        history.remove(0, history.length()-maxhistory+1);
                    }
                    history.add(new hline)->save();
                }
                h = history.last().get();
            }
            histpos = history.length();
            inputcommand(NULL);
            if (h) h->run();
        }
        else if(code==SDLK_ESCAPE)
        {
            histpos = history.length();
            inputcommand(NULL);
        }
    }
}

void keypress(int code, bool isdown, int cooked)
{
    keym *haskey = keyms.access(code);
    if(haskey && haskey->pressed) execbind(*haskey, isdown); // allow pressed keys to release
    else if(!gui::keypress(code, isdown, cooked)) // gui mouse button intercept
    {
        if(commandmillis >= 0) consolekey(code, isdown, cooked);
        else if(haskey) execbind(*haskey, isdown);
    }
    else if (isdown) GuiControl::menuKeyClickTrigger(); // INTENSITY
}

void clear_console()
{
    keyms.clear();
}

static inline bool sortbinds(keym *x, keym *y)
{
    return (x->name != y->name) < 0;
}

void writebinds(stream *f)
{
    static const char *cmds[3] = { "", "_spec", "_edit" };
    vector<keym *> binds;
    enumerate(keyms, keym, km, binds.add(&km));
    binds.sort(sortbinds);
    loopj(3)
    {
        loopv(binds)
        {
            keym &km = *binds[i];
            if(!km.actions[j].is_empty()) f->printf("input.bind%s(\"%s\", [[%s]])\n", cmds[j], km.name.get_buf(), km.actions[j].get_buf());
        }
    }
}

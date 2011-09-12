// console.cpp: the console buffer, its display, and command line control

#include "engine.h"

#include "client_engine_additions.h" // INTENSITY
#include "of_tools.h"

vector<cline> conlines;

int commandmillis = -1;
string commandbuf;
char *commandaction = NULL, *commandprompt = NULL;
int commandpos = -1;

VARFP(maxcon, 10, 200, 1000, { while(conlines.length() > maxcon) delete[] conlines.pop().line; });

#define CONSTRLEN 512

void conline(int type, const char *sf)        // add a line to the console buffer
{
    cline cl;
    cl.line = conlines.length()>maxcon ? conlines.pop().line : newstring("", CONSTRLEN-1);   // constrain the buffer size
    cl.type = type;
    cl.outtime = totalmillis;                       // for how long to keep line on screen
    conlines.insert(0, cl);
    copystring(cl.line, sf, CONSTRLEN);
}

void conoutfv(int type, const char *fmt, va_list args)
{
    types::string buf;
    buf.format(fmt, args);
    conline(type, buf.buf);
    filtertext(buf.buf, buf.buf);
    logoutf("%s", buf.buf);
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

    defformatstring(s)("%s %s", commandprompt ? commandprompt : ">", commandbuf);
    int width, height;
    text_bounds(s, width, height, w);
    y -= height;
    draw_text(s, x, y, 0xFF, 0xFF, 0xFF, 0xFF, (commandpos>=0) ? (commandpos+1+(commandprompt?strlen(commandprompt):1)) : strlen(s), w);
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
        char *line = conlines[idx].line;
        int width, height;
        text_bounds(line, width, height, conwidth);
        if(totalheight + height > conheight) { numl = i; if(offset == idx) ++offset; break; }
        totalheight += height;
    }
    if(dir > 0) y = conoff;
    loopi(numl)
    {
        int idx = offset + (dir > 0 ? numl-i-1 : i);
        if(!(conlines[idx].type&filter)) continue;
        char *line = conlines[idx].line;
        int width, height;
        text_bounds(line, width, height, conwidth);
        if(dir <= 0) y -= height; 
        draw_text(line, conoff, y, 0xFF, 0xFF, 0xFF, 0xFF, -1, conwidth);
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

void keymap(int *code, char *key)
{
    if(var::overridevars) { conoutf(CON_ERROR, "cannot override keymap %s", code); return; }
    keym &km = keyms[*code];
    km.code = *code;
    DELETEA(km.name);
    km.name = newstring(key);
}

keym *keypressed = NULL;
char *keyaction = NULL;

const char *getkeyname(int code)
{
    keym *km = keyms.access(code);
    return km ? km->name : NULL;
}

void searchbinds(char *action, int type)
{
    int n = 1;
    lua::engine.t_new();
    enumerate(keyms, keym, km,
    {
        if(!strcmp(km.actions[type], action))
        {
            lua::engine.t_set(n, km.name);
            n++;
        }
    });
}

keym *findbind(char *key)
{
    enumerate(keyms, keym, km,
    {
        if(!strcasecmp(km.name, key)) return &km;
    });
    return NULL;
}   
    
void getbind(char *key, int type)
{
    keym *km = findbind(key);
    lua::engine.push(km ? km->actions[type] : "");
}   

void bindkey(char *key, char *action, int state)
{
    if(var::overridevars) { conoutf(CON_ERROR, "cannot override %sbind \"%s\"", state == 1 ? "spec" : (state == 2 ? "edit" : ""), key); return; }
    keym *km = findbind(key);
    if(!km) { conoutf(CON_ERROR, "unknown key \"%s\"", key); return; }
    char *&binding = km->actions[state];
    if(!keypressed || keyaction!=binding) delete[] binding;
    // trim white-space to make searchbinds more reliable
    while(isspace(*action)) action++;
    int len = strlen(action);
    while(len>0 && isspace(action[len-1])) len--;
    binding = newstring(action, len);
}

void inputcommand(char *init, char *action = NULL, char *prompt = NULL) // turns input to the command line on or off
{
    commandmillis = init ? totalmillis : -1;
    SDL_EnableUNICODE(commandmillis >= 0 ? 1 : 0);
    if(!editmode) keyrepeat(commandmillis >= 0);
    copystring(commandbuf, init ? init : "");
    DELETEA(commandaction);
    DELETEA(commandprompt);
    commandpos = -1;
    if(action && action[0]) commandaction = newstring(action);
    if(prompt && prompt[0]) commandprompt = newstring(prompt);
}

#if !defined(WIN32) && !defined(__APPLE__)
#include <X11/Xlib.h>
#include <SDL_syswm.h>
#endif

void pasteconsole()
{
    #ifdef WIN32
    if(!IsClipboardFormatAvailable(CF_TEXT)) return; 
    if(!OpenClipboard(NULL)) return;
    char *cb = (char *)GlobalLock(GetClipboardData(CF_TEXT));
    concatstring(commandbuf, cb);
    GlobalUnlock(cb);
    CloseClipboard();
    #elif defined(__APPLE__)
    extern void mac_pasteconsole(char *commandbuf);

    mac_pasteconsole(commandbuf);
    #else
    SDL_SysWMinfo wminfo;
    SDL_VERSION(&wminfo.version); 
    wminfo.subsystem = SDL_SYSWM_X11;
    if(!SDL_GetWMInfo(&wminfo)) return;
    int cbsize;
    char *cb = XFetchBytes(wminfo.info.x11.display, &cbsize);
    if(!cb || !cbsize) return;
    size_t commandlen = strlen(commandbuf);
    for(char *cbline = cb, *cbend; commandlen + 1 < sizeof(commandbuf) && cbline < &cb[cbsize]; cbline = cbend + 1)
    {
        cbend = (char *)memchr(cbline, '\0', &cb[cbsize] - cbline);
        if(!cbend) cbend = &cb[cbsize];
        if(size_t(commandlen + cbend - cbline + 1) > sizeof(commandbuf)) cbend = cbline + sizeof(commandbuf) - commandlen - 1;
        memcpy(&commandbuf[commandlen], cbline, cbend - cbline);
        commandlen += cbend - cbline;
        commandbuf[commandlen] = '\n';
        if(commandlen + 1 < sizeof(commandbuf) && cbend < &cb[cbsize]) ++commandlen;
        commandbuf[commandlen] = '\0';
    }
    XFree(cb);
    #endif
}

struct hline
{
    char *buf, *action, *prompt;

    hline() : buf(NULL), action(NULL), prompt(NULL) {}
    ~hline()
    {
        DELETEA(buf);
        DELETEA(action);
        DELETEA(prompt);
    }

    void restore()
    {
        copystring(commandbuf, buf);
        if(commandpos >= (int)strlen(commandbuf)) commandpos = -1;
        DELETEA(commandaction);
        DELETEA(commandprompt);
        if(action) commandaction = newstring(action);
        if(prompt) commandprompt = newstring(prompt);
    }

    bool shouldsave()
    {
        return strcmp(commandbuf, buf) ||
               (commandaction ? !action || strcmp(commandaction, action) : action!=NULL) ||
               (commandprompt ? !prompt || strcmp(commandprompt, prompt) : prompt!=NULL);
    }
    
    void save()
    {
        buf = newstring(commandbuf);
        if(commandaction) action = newstring(commandaction);
        if(commandprompt) prompt = newstring(commandprompt);
    }

    void run()
    {
        if (action)
        {
            var::cvar *ev = var::get("commandbuf");
            if (!ev)
            {
                ev = var::regvar("commandbuf", new var::cvar("commandbuf", buf));
            }
            else ev->set(buf, false);
            lua::engine.exec(action);
        }
        else if (buf[0] == '/')
        {
            lua::engine.exec(buf + 1);
#if 0
            if  (buf[1] == '/')
                lua::engine.exec(buf + 2);
            else
            {
                if (strchr(buf, '='))
                {
                    lua::engine.exec(buf + 1);
                    return;
                }

                char *n   = NULL;
                char *str = newstring(buf + 1);
                char *tok = strtok(str, " ");
                char *cmd = new char[strlen(tok) + 2];
                strcpy(cmd, tok);
                strcat(cmd, "(");

                tok = strtok(NULL, " ");

                bool first = true;
                while (tok)
                {
                    if ((tok[0] == '\"' || tok[0] == '\'')
                     && (tok[strlen(tok) - 1] != '\"' && tok[strlen(tok) - 1] != '\''))
                    {
                        n = new char[strlen(cmd) + strlen(tok) + (first ? 1 : 3)];
                        strcpy(n, cmd);
                        if (!first) strcat(n, ", ");
                        strcat(n, tok);
                        delete[] cmd;
                        cmd = newstring(n);
                        delete[] n;

                        if ((tok = strtok(NULL, " ")))
                        {
                            n = new char[strlen(cmd) + 2);
                            strcpy(n, cmd);
                            strcat(n, " ");
                            delete[] cmd;
                            cmd = newstring(n);
                            delete[] n;
                        }

                        while (tok)
                        {
                            n = new char[strlen(cmd) + strlen(tok) + 1];
                            strcpy(n, cmd);
                            strcat(n, tok);
                            delete[] cmd;
                            cmd = newstring(n);
                            delete[] n;

                            if (tok[strlen(tok) - 1] == '\"' || tok[strlen(tok) - 1] == '\'')
                                break;
                            else
                            {
                                n = new char[strlen(cmd) + 2);
                                strcpy(n, cmd);
                                strcat(n, " ");
                                delete[] cmd;
                                cmd = newstring(n);
                                delete[] n;
                            }

                            tok = strtok(NULL, " ");
                        }

                        if (!tok) break;
                        if (!(tok = strtok(NULL, " "))) break;
                    }
                    else
                    {
                        n = new char[strlen(cmd) + strlen(tok) + (first ? 1 : 3)];
                        strcpy(n, cmd);
                        if (!first) strcat(n, ", ");
                        strcat(n, tok);
                        delete[] cmd;
                        cmd = newstring(n);
                        delete[] n;

                        tok = strtok(NULL, " ");
                    }
                    first = false;
                }

                char *command = new char[strlen(cmd) + 2];
                strcpy(command, cmd);
                strcat(command, ")");
                delete[] cmd;
                delete[] str;

                lua::engine.exec(command);
                delete[] command;
            }
#endif
        }
        else game::toserver(buf);
    }
};
vector<hline *> history;
int histpos = 0;

VARP(maxhistory, 0, 1000, 10000);

void history_(int *n)
{
    static bool inhistory = false;
    if(!inhistory && history.inrange(*n))
    {
        inhistory = true;
        history[history.length()-*n-1]->run();
        inhistory = false;
    }
}

struct releaseaction
{
    keym *key;
    int action;
};
vector<releaseaction> releaseactions;

const char *addreleaseaction(int a)
{
    if(!keypressed) return NULL;
    releaseaction &ra = releaseactions.add();
    ra.key = keypressed;
    ra.action = a;
    return keypressed->name;
}

const char *addreleaseaction(const char *s)
{
    if(!keypressed) return NULL;
    lua::engine.getg("loadstring").push(s).call(1, 1);
    return addreleaseaction(lua::engine.ref());
}

void execbind(keym &k, bool isdown)
{
    loopv(releaseactions)
    {
        releaseaction &ra = releaseactions[i];
        if(ra.key==&k)
        {
            if(!isdown) lua::engine.getref(ra.action).call(0, 0);
            lua::engine.unref(ra.action);
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
            lua::engine.getg("input").t_getraw("per_map_keys").t_getraw(k.name);
            if (lua::engine.is<void*>(-1))
            {
                keypressed = &k;
                lua::engine.call(0, 0);
                keypressed = NULL;

                k.pressed = isdown;
                lua::engine.pop(2);
                return;
            }
            lua::engine.pop(3);
        }
        char *&action = k.actions[state][0] ? k.actions[state] : k.actions[keym::ACTION_DEFAULT];
        keyaction = action;
        keypressed = &k;
        lua::engine.exec(keyaction);
        keypressed = NULL;
        if (keyaction!=action) delete[] keyaction;
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
                        loopi(history.length()-maxhistory+1) delete history[i];
                        history.remove(0, history.length()-maxhistory+1);
                    }
                    history.add(h = new hline)->save();
                }
                else h = history.last();
            }
            histpos = history.length();
            inputcommand(NULL);
            if(h) h->run();
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
    return strcmp(x->name, y->name) < 0;
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
            if(*km.actions[j]) f->printf("input.bind%s(\"%s\", [[%s]])\n", cmds[j], km.name, km.actions[j]);
        }
    }
}

// console.cpp: the console buffer, its display, and command line control

#include "engine.h"
#include "of_tools.h" // OF
#include "client_system.h"
#include "targeting.h"

struct cline { char *line; int type, outtime; };
vector<cline> conlines;

int commandmillis = -1;
string commandbuf;
char *commandaction = NULL, *commandprompt = NULL;
enum { CF_COMPLETE = 1<<0, CF_EXECUTE = 1<<1 };
int commandflags = 0, commandpos = -1;

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
    static char buf[CONSTRLEN];
    vformatstring(buf, fmt, args, sizeof(buf));
    conline(type, buf);
    logoutf("%s", buf);
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
ICOMMAND(toggleconsole, "", (), { fullconsole ^= 1; });

float rendercommand(float x, float y, float w)
{
    if(commandmillis < 0) return 0;

    defformatstring(s, "%s %s", commandprompt ? commandprompt : ">", commandbuf);
    float width, height;
    text_boundsf(s, width, height, w);
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

ICOMMAND(conskip, "i", (int *n), setconskip(conskip, fullconsole ? fullconfilter : confilter, *n));
ICOMMAND(miniconskip, "i", (int *n), setconskip(miniconskip, miniconfilter, *n));

ICOMMAND(clearconsole, "", (), { while(conlines.length()) delete[] conlines.pop().line; });

float drawconlines(int conskip, int confade, float conwidth, float conheight, float conoff, int filter, float y = 0, int dir = 1)
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
        float width, height;
        text_boundsf(line, width, height, conwidth);
        if(totalheight + height > conheight) { numl = i; if(offset == idx) ++offset; break; }
        totalheight += height;
    }
    if(dir > 0) y = conoff;
    loopi(numl)
    {
        int idx = offset + (dir > 0 ? numl-i-1 : i);
        if(!(conlines[idx].type&filter)) continue;
        char *line = conlines[idx].line;
        float width, height;
        text_boundsf(line, width, height, conwidth);
        if(dir <= 0) y -= height;
        draw_text(line, conoff, y, 0xFF, 0xFF, 0xFF, 0xFF, -1, conwidth);
        if(dir > 0) y += height;
    }
    return y+conoff;
}

float renderconsole(float w, float h, float abovehud)                   // render buffer taking into account time & scrolling
{
    float conpad = fullconsole ? 0 : FONTH/4,
          conoff = fullconsole ? FONTH : FONTH/3,
          conheight = min(fullconsole ? ((h*fullconsize/100)/FONTH)*FONTH : FONTH*consize, h - 2*(conpad + conoff)),
          conwidth = w - 2*(conpad + conoff) - (fullconsole ? 0 : game::clipconsole(w, h));

    //extern void consolebox(float x1, float y1, float x2, float y2);
    //if(fullconsole) consolebox(conpad, conpad, conwidth+conpad+2*conoff, conheight+conpad+2*conoff);

    float y = drawconlines(conskip, fullconsole ? 0 : confade, conwidth, conheight, conpad+conoff, fullconsole ? fullconfilter : confilter);
    if(!fullconsole && (miniconsize && miniconwidth))
        drawconlines(miniconskip, miniconfade, (miniconwidth*(w - 2*(conpad + conoff)))/100, min(float(FONTH*miniconsize), abovehud - y), conpad+conoff, miniconfilter, abovehud, -1);
    return fullconsole ? conheight + 2*(conpad + conoff) : y;
}

// keymap is defined externally in keymap.cfg

struct keym
{
    enum
    {
        ACTION_DEFAULT = 0,
        ACTION_SPECTATOR,
        ACTION_EDITING,
        NUMACTIONS
    };

    int code;
    char *name;
    char *actions[NUMACTIONS];
    bool pressed;

    keym() : code(-1), name(NULL), pressed(false) { loopi(NUMACTIONS) actions[i] = newstring(""); }
    ~keym() { DELETEA(name); loopi(NUMACTIONS) DELETEA(actions[i]); }
};

hashtable<int, keym> keyms(128);

void keymap(int *code, char *key)
{
    if(identflags&IDF_OVERRIDDEN) { conoutf(CON_ERROR, "cannot override keymap %d", *code); return; }
    keym &km = keyms[*code];
    km.code = *code;
    DELETEA(km.name);
    km.name = newstring(key);
}

COMMAND(keymap, "is");

keym *keypressed = NULL;
char *keyaction = NULL;

const char *getkeyname(int code)
{
    keym *km = keyms.access(code);
    return km ? km->name : NULL;
}

void searchbinds(char *action, int type)
{
    vector<char> names;
    enumerate(keyms, keym, km,
    {
        if(!strcmp(km.actions[type], action))
        {
            if(names.length()) names.add(' ');
            names.put(km.name, strlen(km.name));
        }
    });
    names.add('\0');
    result(names.getbuf());
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
    result(km ? km->actions[type] : "");
}

void bindkey(char *key, char *action, int state, const char *cmd)
{
    if(identflags&IDF_OVERRIDDEN) { conoutf(CON_ERROR, "cannot override %s \"%s\"", cmd, key); return; }
    keym *km = findbind(key);
    if(!km) { conoutf(CON_ERROR, "unknown key \"%s\"", key); return; }
    char *&binding = km->actions[state];
    if(!keypressed || keyaction!=binding) delete[] binding;
    // trim white-space to make searchbinds more reliable
    while(iscubespace(*action)) action++;
    int len = strlen(action);
    while(len>0 && iscubespace(action[len-1])) len--;
    binding = newstring(action, len);
}

ICOMMAND(bind,     "ss", (char *key, char *action), bindkey(key, action, keym::ACTION_DEFAULT, "bind"));
ICOMMAND(specbind, "ss", (char *key, char *action), bindkey(key, action, keym::ACTION_SPECTATOR, "specbind"));
ICOMMAND(editbind, "ss", (char *key, char *action), bindkey(key, action, keym::ACTION_EDITING, "editbind"));
ICOMMAND(getbind,     "s", (char *key), getbind(key, keym::ACTION_DEFAULT));
ICOMMAND(getspecbind, "s", (char *key), getbind(key, keym::ACTION_SPECTATOR));
ICOMMAND(geteditbind, "s", (char *key), getbind(key, keym::ACTION_EDITING));
ICOMMAND(searchbinds,     "s", (char *action), searchbinds(action, keym::ACTION_DEFAULT));
ICOMMAND(searchspecbinds, "s", (char *action), searchbinds(action, keym::ACTION_SPECTATOR));
ICOMMAND(searcheditbinds, "s", (char *action), searchbinds(action, keym::ACTION_EDITING));

void inputcommand(char *init, char *action = NULL, char *prompt = NULL, char *flags = NULL) // turns input to the command line on or off
{
    commandmillis = init ? totalmillis : -1;
    textinput(commandmillis >= 0, TI_CONSOLE);
    keyrepeat(commandmillis >= 0, KR_CONSOLE);
    copystring(commandbuf, init ? init : "");
    DELETEA(commandaction);
    DELETEA(commandprompt);
    commandpos = -1;
    if(action && action[0]) commandaction = newstring(action);
    if(prompt && prompt[0]) commandprompt = newstring(prompt);
    commandflags = 0;
    if(flags) while(*flags) switch(*flags++)
    {
        case 'c': commandflags |= CF_COMPLETE; break;
        case 'x': commandflags |= CF_EXECUTE; break;
        case 's': commandflags |= CF_COMPLETE|CF_EXECUTE; break;
    }
    else if(init) commandflags |= CF_COMPLETE|CF_EXECUTE;
}

ICOMMAND(saycommand, "C", (char *init), inputcommand(init));
COMMAND(inputcommand, "ssss");

void pasteconsole()
{
    if(!SDL_HasClipboardText()) return;
    char *cb = SDL_GetClipboardText();
    if(!cb) return;
    int cblen = strlen(cb);
    size_t commandlen = strlen(commandbuf);
    int decoded = decodeutf8((uchar *)&commandbuf[commandlen], int(sizeof(commandbuf)-1-commandlen), (const uchar *)cb, cblen);
    commandbuf[commandlen + decoded] = '\0';
    SDL_free(cb);
}

LUAICOMMAND(clipboard_has_text, {
    lua_pushboolean(L, SDL_HasClipboardText());
    return 1;
});

LUAICOMMAND(clipboard_get_text, {
    char *cb = SDL_GetClipboardText();
    if  (!cb) {
        lua_pushnil(L);
        lua_pushstring(L, SDL_GetError());
        return 2;
    }
    lua_pushstring(L, cb);
    SDL_free(cb);
    return 1;
})

LUAICOMMAND(clipboard_set_text, {
    if (!SDL_SetClipboardText(luaL_checkstring(L, 1))) {
        lua_pushboolean(L, true);
        return 1;
    }
    lua_pushboolean(L, false);
    lua_pushstring(L, SDL_GetError());
    return 2;
})

struct hline
{
    char *buf, *action, *prompt;
    int flags;

    hline() : buf(NULL), action(NULL), prompt(NULL), flags(0) {}
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
        commandflags = flags;
    }

    bool shouldsave()
    {
        return strcmp(commandbuf, buf) ||
               (commandaction ? !action || strcmp(commandaction, action) : action!=NULL) ||
               (commandprompt ? !prompt || strcmp(commandprompt, prompt) : prompt!=NULL) ||
               commandflags != flags;
    }

    void save()
    {
        buf = newstring(commandbuf);
        if(commandaction) action = newstring(commandaction);
        if(commandprompt) prompt = newstring(commandprompt);
        flags = commandflags;
    }

    void run()
    {
        if (flags&CF_EXECUTE && buf[0] == '/') {
            if (buf[1] == '/') {
                if (lua::load_string(buf + 2) || lua_pcall(lua::L, 0, 0, 0)) {
                    logger::log(logger::ERROR, "%s\n", lua_tostring(lua::L, -1));
                    lua_pop(lua::L, 1);
                }
            } else {
                execute(buf+1);
            }
        } else if (action) {
            alias("commandbuf", buf);
            execute(action);
        } else game::toserver(buf);
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

COMMANDN(history, history_, "i");

struct releaseaction
{
    keym *key;
    union
    {
        char *action;
        ident *id;
    };
    int numargs;
    tagval args[3];
};
vector<releaseaction> releaseactions;

const char *addreleaseaction(char *s)
{
    if(!keypressed) { delete[] s; return NULL; }
    releaseaction &ra = releaseactions.add();
    ra.key = keypressed;
    ra.action = s;
    ra.numargs = -1;
    return keypressed->name;
}

tagval *addreleaseaction(ident *id, int numargs)
{
    if(!keypressed || numargs > 3) return NULL;
    releaseaction &ra = releaseactions.add();
    ra.key = keypressed;
    ra.id = id;
    ra.numargs = numargs;
    return ra.args;
}

void onrelease(const char *s)
{
    addreleaseaction(newstring(s));
}

COMMAND(onrelease, "s");

void execbind(keym &k, bool isdown)
{
    loopv(releaseactions)
    {
        releaseaction &ra = releaseactions[i];
        if(ra.key==&k)
        {
            if(ra.numargs < 0)
            {
                if(!isdown) execute(ra.action);
                delete[] ra.action;
            }
            else execute(isdown ? NULL : ra.id, ra.args, ra.numargs);
            releaseactions.remove(i--);
        }
    }
    if(isdown)
    {
        int state = keym::ACTION_DEFAULT;
        if (!mainmenu)
        {
            if(editmode) state = keym::ACTION_EDITING;
            else if(player->state==CS_SPECTATOR) state = keym::ACTION_SPECTATOR;
        }

        char *&action = k.actions[state][0] ? k.actions[state] : k.actions[keym::ACTION_DEFAULT];
        keyaction = action;
        keypressed = &k;
        execute(keyaction);
        keypressed = NULL;
        if(keyaction!=action) delete[] keyaction;
    }
    k.pressed = isdown;
}

bool consoleinput(const char *str, int len)
{
    if(commandmillis < 0) return false;

    resetcomplete();
    int cmdlen = (int)strlen(commandbuf), cmdspace = int(sizeof(commandbuf)) - (cmdlen+1);
    len = min(len, cmdspace);
    if(commandpos<0)
    {
        memcpy(&commandbuf[cmdlen], str, len);
    }
    else
    {
        memmove(&commandbuf[commandpos+len], &commandbuf[commandpos], cmdlen - commandpos);
        memcpy(&commandbuf[commandpos], str, len);
        commandpos += len;
    }
    commandbuf[cmdlen + len] = '\0';

    return true;
}

bool consolekey(int code, bool isdown)
{
    if(commandmillis < 0) return false;

    #ifdef __APPLE__
        #define MOD_KEYS (KMOD_LGUI|KMOD_RGUI)
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

            case SDLK_TAB:
                if(commandflags&CF_COMPLETE)
                {
                    complete(commandbuf, sizeof(commandbuf), commandflags&CF_EXECUTE ? "/" : NULL);
                    if(commandpos>=0 && commandpos>=(int)strlen(commandbuf)) commandpos = -1;
                }
                break;

            case SDLK_v:
                if(SDL_GetModState()&MOD_KEYS) pasteconsole();
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

    return true;
}

void processtextinput(const char *str, int len)
{
    lua::push_external("input_text");
    lua_pushlstring(lua::L, str, len);
    lua_call(lua::L, 1, 1);
    bool b = lua_toboolean(lua::L, -1);
    lua_pop(lua::L, 1);
    if(!b) consoleinput(str, len);
}

void processkey(int code, bool isdown)
{
    keym *haskey = keyms.access(code);
    if(haskey && haskey->pressed) {
        execbind(*haskey, isdown); // allow pressed keys to release
    } else {
        lua::push_external("input_keypress");
        lua_pushinteger(lua::L, code);
        lua_pushboolean(lua::L, isdown);
        lua_call       (lua::L, 2, 1);
        bool b = lua_toboolean(lua::L, -1); lua_pop(lua::L, 1);

        if (!b) { // gui mouse button intercept
            if(!consolekey(code, isdown))
            {
                if(haskey) execbind(*haskey, isdown);
            }
        }
    }
}

void clear_console()
{
    keyms.clear();
}

void writebinds(stream *f)
{
    static const char * const cmds[3] = { "bind", "specbind", "editbind" };
    vector<keym *> binds;
    enumerate(keyms, keym, km, binds.add(&km));
    binds.sortname();
    loopj(3)
    {
        loopv(binds)
        {
            keym &km = *binds[i];
            if(*km.actions[j])
            {
                if(validateblock(km.actions[j])) f->printf("%s %s [%s]\n", cmds[j], escapestring(km.name), km.actions[j]);
                else f->printf("%s %s %s\n", cmds[j], escapestring(km.name), escapestring(km.actions[j]));
            }
        }
    }
}

// tab-completion of all idents and base maps

enum { FILES_DIR = 0, FILES_LIST };

struct fileskey
{
    int type;
    const char *dir, *ext;

    fileskey() {}
    fileskey(int type, const char *dir, const char *ext) : type(type), dir(dir), ext(ext) {}
};

struct filesval
{
    int type;
    char *dir, *ext;
    vector<char *> files;
    int millis;

    filesval(int type, const char *dir, const char *ext) : type(type), dir(newstring(dir)), ext(ext && ext[0] ? newstring(ext) : NULL), millis(-1) {}
    ~filesval() { DELETEA(dir); DELETEA(ext); files.deletearrays(); }

    void update()
    {
        if(type!=FILES_DIR || millis >= commandmillis) return;
        files.deletearrays();
        listfiles(dir, ext, files);
        files.sort();
        loopv(files) if(i && !strcmp(files[i], files[i-1])) delete[] files.remove(i--);
        millis = totalmillis;
    }
};

static inline bool htcmp(const fileskey &x, const fileskey &y)
{
    return x.type==y.type && !strcmp(x.dir, y.dir) && (x.ext == y.ext || (x.ext && y.ext && !strcmp(x.ext, y.ext)));
}

static inline uint hthash(const fileskey &k)
{
    return hthash(k.dir);
}

static hashtable<fileskey, filesval *> completefiles;
static hashtable<char *, filesval *> completions;

int completesize = 0;
char *lastcomplete = NULL;

void resetcomplete() { completesize = 0; }

void addcomplete(char *command, int type, char *dir, char *ext)
{
    if(identflags&IDF_OVERRIDDEN)
    {
        conoutf(CON_ERROR, "cannot override complete %s", command);
        return;
    }
    if(!dir[0])
    {
        filesval **hasfiles = completions.access(command);
        if(hasfiles) *hasfiles = NULL;
        return;
    }
    if(type==FILES_DIR)
    {
        int dirlen = (int)strlen(dir);
        while(dirlen > 0 && (dir[dirlen-1] == '/' || dir[dirlen-1] == '\\'))
            dir[--dirlen] = '\0';
        if(ext)
        {
            if(strchr(ext, '*')) ext[0] = '\0';
            if(!ext[0]) ext = NULL;
        }
    }
    fileskey key(type, dir, ext);
    filesval **val = completefiles.access(key);
    if(!val)
    {
        filesval *f = new filesval(type, dir, ext);
        if(type==FILES_LIST) explodelist(dir, f->files);
        val = &completefiles[fileskey(type, f->dir, f->ext)];
        *val = f;
    }
    filesval **hasfiles = completions.access(command);
    if(hasfiles) *hasfiles = *val;
    else completions[newstring(command)] = *val;
}

void addfilecomplete(char *command, char *dir, char *ext)
{
    addcomplete(command, FILES_DIR, dir, ext);
}

void addlistcomplete(char *command, char *list)
{
    addcomplete(command, FILES_LIST, list, NULL);
}

COMMANDN(complete, addfilecomplete, "sss");
COMMANDN(listcomplete, addlistcomplete, "ss");

void complete(char *s, int maxlen, const char *cmdprefix)
{
    int cmdlen = 0;
    if(cmdprefix)
    {
        cmdlen = strlen(cmdprefix);
        if(strncmp(s, cmdprefix, cmdlen)) prependstring(s, cmdprefix, maxlen);
    }
    if(!s[cmdlen]) return;
    if(!completesize) { completesize = (int)strlen(&s[cmdlen]); DELETEA(lastcomplete); }

    filesval *f = NULL;
    if(completesize)
    {
        char *end = strchr(&s[cmdlen], ' ');
        if(end) f = completions.find(stringslice(&s[cmdlen], int(end-&s[cmdlen])), NULL);
    }

    const char *nextcomplete = NULL;
    if(f) // complete using filenames
    {
        int commandsize = strchr(&s[cmdlen], ' ')+1-s;
        f->update();
        loopv(f->files)
        {
            if(strncmp(f->files[i], &s[commandsize], completesize+cmdlen-commandsize)==0 &&
               (!lastcomplete || strcmp(f->files[i], lastcomplete) > 0) && (!nextcomplete || strcmp(f->files[i], nextcomplete) < 0))
                nextcomplete = f->files[i];
        }
        cmdprefix = s;
        cmdlen = commandsize;
    }
    else // complete using command names
    {
        enumerate(idents, ident, id,
            if(strncmp(id.name, &s[cmdlen], completesize)==0 &&
               (!lastcomplete || strcmp(id.name, lastcomplete) > 0) && (!nextcomplete || strcmp(id.name, nextcomplete) < 0))
                nextcomplete = id.name;
        );
    }
    DELETEA(lastcomplete);
    if(nextcomplete)
    {
        cmdlen = min(cmdlen, maxlen-1);
        if(cmdlen) memmove(s, cmdprefix, cmdlen);
        copystring(&s[cmdlen], nextcomplete, maxlen-cmdlen);
        lastcomplete = newstring(nextcomplete);
    }
}

void writecompletions(stream *f)
{
    vector<char *> cmds;
    enumeratekt(completions, char *, k, filesval *, v, { if(v) cmds.add(k); });
    cmds.sort();
    loopv(cmds)
    {
        char *k = cmds[i];
        filesval *v = completions[k];
        if(v->type==FILES_LIST)
        {
            if(validateblock(v->dir)) f->printf("listcomplete %s [%s]\n", escapeid(k), v->dir);
            else f->printf("listcomplete %s %s\n", escapeid(k), escapestring(v->dir));
        }
        else f->printf("complete %s %s %s\n", escapeid(k), escapestring(v->dir), escapestring(v->ext ? v->ext : "*"));
    }
}

/* OF: input code */

VARP(freecursor, 0, 1, 2);
VARP(freeeditcursor, 0, 1, 2);

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
    if (tle) { \
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

ICOMMAND(crouch, "", (), {
    if (ClientSystem::scenarioStarted())
    {
        CLogicEntity *e = ClientSystem::playerLogicEntity;
        lua_rawgeti (lua::L, LUA_REGISTRYINDEX, e->lua_ref);
        lua_getfield(lua::L, -1, "clear_actions");
        lua_insert  (lua::L, -2);
        lua_call    (lua::L, 1, 0);

        bool down = (addreleaseaction(newstring("crouch")) != 0);

        lua::push_external("input_crouch");
        lua_pushboolean(lua::L, down);
        lua_call(lua::L, 1, 0);
    }
});

LUAICOMMAND(input_is_modifier_pressed, {
    int nargs = lua_gettop(L);
    int keys = 0;
    for (int i = 1; i <= nargs; ++i) {
        keys |= lua_tointeger(L, i);
    }
    lua_pushboolean(L, SDL_GetModState() & keys);
    return 1;
});

ICOMMAND(is_mod_pressed, "V", (tagval *args, int nargs), {
    int keys = 0;
    for (int i = 0; i < nargs; ++i) {
        keys |= args[i].getint();
    }
    intret((SDL_GetModState() & keys) != 0);
})

LUAICOMMAND(input_keyrepeat, {
    keyrepeat(lua_toboolean(L, 1), luaL_checkinteger(L, 2));
    return 0;
});

LUAICOMMAND(input_textinput, {
    textinput(lua_toboolean(L, 1), luaL_checkinteger(L, 2));
    return 0;
});

LUAICOMMAND(input_get_key_name, {
    lua_pushstring(L, getkeyname(luaL_checkinteger(L, 1)));
    return 1;
});

/*
 * of_lua_base.h, version 1
 * Base Lua API exports
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2011 q66
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

/* PROTOTYPES */

void keymap(int *code, char *key);
void registersound(char *name, int *vol);
void force_quit();
void quit();
void resetgl();
void getfps_(int *raw);
extern int conskip, miniconskip;
void setconskip(int &skip, int filter, int n);
extern vector<cline> conlines;
void bindkey(char *key, int action, int state);
void getbind(char *key, int type);
void inputcommand(char *init, char *action = NULL, char *prompt = NULL);
void history_(int *n);
void screenshot(char *filename);
void movie(char *name);
void glext(char *ext);
void loadcrosshair_(const char *name, int *i);
void resetsound();
void scorebshow(bool on);
bool addzip(const char *name, const char *mount = NULL, const char *strip = NULL);
bool removezip(const char *name);

extern string homedir;

extern int& fullconsole, &fullconfilter, &confilter, &miniconfilter;

#ifdef CLIENT
VARFN(scoreboard, showscoreboard, 0, 0, 1, scorebshow(showscoreboard!=0));
#endif

namespace lua_binds
{
    /* Logging Lua namespace */

    LUA_BIND_DEF(log, logger::log((logger::loglevel)e.get<int>(1), "%s\n", e.get<const char*>(2));)

    LUA_BIND_DEF(echo, conoutf("\f1%s", e.get<const char*>(1));)

    LUA_BIND_DEF(say, {
        int n = e.gettop();
        switch (n)
        {
            case 0: game::toserver((char*)""); break;
            case 1: game::toserver(e.get<char*>(1)); break;
            default:
            {
                char *s = e.get<char*>(1);
                for (int i = 2; i <= n; i++)
                {
                    const char *a = e.get<const char*>(i);
                    s = (char*)realloc(s, strlen(s) + strlen(a) + 1);
                    assert(s);
                    strcat(s, a);
                }
                game::toserver(s);
                delete s;
                break;
            }
        }
    })

    /* CAPI Lua namespace */

    // Core binds

    LUA_BIND_DEF(currtime, e.push(tools::currtime());)
    LUA_BIND_STD(getmillis, e.push, e.get<bool>(1) ? totalmillis : lastmillis)
    LUA_BIND_STD_CLIENT(keymap, keymap, e.get<int*>(1), e.get<char*>(2))
    LUA_BIND_STD_CLIENT(registersound, registersound, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD_CLIENT(resetsound, resetsound)
    LUA_BIND_STD_CLIENT(quit, quit)
    LUA_BIND_STD_CLIENT(force_quit, force_quit)
    LUA_BIND_STD_CLIENT(resetgl, resetgl)
    LUA_BIND_STD_CLIENT(glext, glext, e.get<char*>(1))
    LUA_BIND_STD_CLIENT(getfps, getfps_, e.get<int*>(1))
    LUA_BIND_STD_CLIENT(screenshot, screenshot, e.get<char*>(1))
    LUA_BIND_STD_CLIENT(movie, movie, e.get<char*>(1))
    LUA_BIND_CLIENT(showscores, {
        bool on = (addreleaseaction("CAPI.showscores()") != 0);
        showscoreboard = on ? 1 : 0;
        scorebshow(on);
    })
    LUA_BIND_STD(writecfg, tools::writecfg, e.get<const char*>(1))
    LUA_BIND_DEF(readfile, {
        const char *text = tools::sread(e.get<const char*>(1));
        if (!text)
        {
            e.push();
            return;
        }
        e.push(text);
        delete[] text;
    })
    LUA_BIND_STD(addzip, addzip,
                 e.get<const char*>(1),
                 e.get<const char*>(2)[0] ? e.get<const char*>(2) : NULL,
                 e.get<const char*>(3)[0] ? e.get<const char*>(3) : NULL)
    LUA_BIND_STD(removezip, removezip, e.get<const char*>(1))
    LUA_BIND_DEF(gethomedir, {
        char *hdir = newstring(homedir);
        if (!strcmp(hdir + strlen(hdir) - 1,   "/"))
                    hdir[  strlen(hdir) - 1] = '\0';

        e.push(hdir);
        delete[] hdir;
    })
    LUA_BIND_STD(getserverlogfile, e.push, SERVER_LOGFILE)
    

    // Bit math

    LUA_BIND_DEF(lsh, e.push(e.get<int>(1) << e.get<int>(2));)

    LUA_BIND_DEF(rsh, e.push(e.get<int>(1) >> e.get<int>(2));)

    LUA_BIND_DEF(bor, {
        int out = e.get<int>(1);
        int n   = e.gettop();
        for (int i = 2; i <= n; i++) out |= e.get<int>(i);
        e.push(out);
    })

    LUA_BIND_DEF(band, {
        int out = e.get<int>(1);
        int n   = e.gettop();
        for (int i = 2; i <= n; i++) out &= e.get<int>(i);
        e.push(out);
    })

    LUA_BIND_DEF(bnot, e.push(~e.get<int>(1));)

    // Engine vars

    LUA_BIND_DEF(resetvar, var::get(e.get<const char*>(1))->reset();)

    LUA_BIND_DEF(newvar, {
        const char *name = e.get<const char*>(1);
        switch (e.get<int>(2))
        {
            case var::VAR_I:
            {
                var::cvar *ev = var::get(name);
                if (!ev)
                {
                    ev = var::regvar(name, new var::cvar(name, e.get<int>(3), e.get<bool>(4)));
                }
                else ev->set(e.get<int>(3), false, false);
                break;
            }
            case var::VAR_F:
            {
                var::cvar *ev = var::get(name);
                if (!ev)
                {
                    ev = var::regvar(name, new var::cvar(name, e.get<float>(3), e.get<bool>(4)));
                }
                else ev->set(e.get<float>(3), false, false);
                break;
            }
            case var::VAR_S:
            {
                var::cvar *ev = var::get(name);
                if (!ev)
                {
                    ev = var::regvar(name, new var::cvar(name, e.get<const char*>(3), e.get<bool>(4)));
                }
                else ev->set(e.get<const char*>(3), false);
                break;
            }
            default: break;
        }
    })

    LUA_BIND_DEF(setvar, {
        var::cvar *ev = var::get(e.get<const char*>(1));
        if (!ev) return;
        if ((ev->flags&var::VAR_READONLY) != 0)
        {
            logger::log(logger::ERROR, "Variable %s is read-only.\n", ev->name);
            return;
        }
        switch (ev->type)
        {
            case var::VAR_I: ev->set(e.get<int>(2), true, true); break;
            case var::VAR_F: ev->set(e.get<float>(2), true, true); break;
            case var::VAR_S: ev->set(e.get<const char*>(2), true); break;
            default: break;
        }
    })

    LUA_BIND_DEF(getvar, {
        var::cvar *ev = var::get(e.get<const char*>(1));
        if (!ev)
        {
            e.push();
            return;
        }
        switch (ev->type)
        {
            case var::VAR_I:
            {
                /*if ((ev->flags&var::VAR_HEX) != 0)
                {
                    char buf[32];
                    snprintf(
                        buf, sizeof(buf),
                        "0x%.6X <%d, %d, %d>",
                        ev->curv.i,
                        (ev->curv.i>>16)&0xFF,
                        (ev->curv.i>>8)&0xFF,
                        ev->curv.i&0xFF
                    );
                    e.push(buf);
                }
                else e.push(ev->curv.i);*/
                e.push(ev->curv.i);
                break;
            }
            case var::VAR_F: e.push(ev->curv.f); break;
            case var::VAR_S: e.push(ev->curv.s); break;
            default: e.push(); break;
        }
    })

    LUA_BIND_STD(varexists, e.push, var::get(e.get<const char*>(1)) ? true : false)

    // Console

    LUA_BIND_STD_CLIENT(toggleconsole, SETV, fullconsole, fullconsole ^ 1)
    LUA_BIND_STD_CLIENT(conskip, setconskip, conskip, fullconsole ? fullconfilter : confilter, e.get<int>(1))
    LUA_BIND_STD_CLIENT(miniconskip, setconskip, miniconskip, miniconfilter, e.get<int>(1))
    LUA_BIND_CLIENT(clearconsole, while(conlines.length()) delete[] conlines.pop().line;)
    LUA_BIND_STD_CLIENT(bind, bindkey, e.get<char*>(1), e.ref_keep_stack(), e.get<int>(2))
    LUA_BIND_STD_CLIENT(getbind, getbind, e.get<char*>(1), e.get<int>(2))
    LUA_BIND_STD_CLIENT(prompt, inputcommand, e.get(1, (char*)""), e.get<char*>(2), e.get<char*>(3))
    LUA_BIND_STD_CLIENT(history, history_, e.get<int*>(1))
    LUA_BIND_STD_CLIENT(onrelease, addreleaseaction, e.ref_keep_stack())

    LUA_BIND_STD(get_totalmillis, e.push, totalmillis)
}

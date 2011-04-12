/*
 * luabind_base.hpp, version 1
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
void run_python(char *code);
void force_quit();
void quit();
void screenres(int *w, int *h);
void resetgl();
void getfps_(int *raw);
extern int conskip, miniconskip;
void setconskip(int &skip, int filter, int n);
extern vector<cline> conlines;
void bindkey(char *key, char *action, int state, const char *cmd);
void getbind(char *key, int type);
void searchbinds(char *action, int type);
void inputcommand(char *init, char *action = NULL, char *prompt = NULL);
void addfilecomplete(char *command, char *dir, char *ext);
void addlistcomplete(char *command, char *list);
void history_(int *n);
void onrelease(char *s);
void screenshot(char *filename);
void movie(char *name);
void glext(char *ext);
void loadcrosshair_(const char *name, int *i);
void tabify(const char *str, int *numtabs);
void resetsound();
void scorebshow(bool on);
bool addzip(const char *name, const char *mount = NULL, const char *strip = NULL);
bool removezip(const char *name);

namespace lua_binds
{
    /* Logging Lua namespace */

    LUA_BIND_DEF(log, Logging::log((Logging::Level)e.get<int>(1), "%s\n", e.get<const char*>(2));)

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

    LUA_BIND_DEF(currtime, e.push(Utility::SystemInfo::currTime());)
    LUA_BIND_STD(getmillis, e.push, e.get<bool>(1) ? totalmillis : lastmillis)
    LUA_BIND_STD_CLIENT(keymap, keymap, e.get<int*>(1), e.get<char*>(2))
    LUA_BIND_STD_CLIENT(registersound, registersound, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD_CLIENT(resetsound, resetsound)
    LUA_BIND_STD_CLIENT(quit, quit)
    LUA_BIND_STD_CLIENT(force_quit, force_quit)
    LUA_BIND_STD_CLIENT(screenres, screenres, e.get<int*>(1), e.get<int*>(2))
    LUA_BIND_STD_CLIENT(resetgl, resetgl)
    LUA_BIND_STD_CLIENT(glext, glext, e.get<char*>(1))
    LUA_BIND_STD_CLIENT(getfps, getfps_, e.get<int*>(1))
    LUA_BIND_STD_CLIENT(screenshot, screenshot, e.get<char*>(1))
    LUA_BIND_STD_CLIENT(movie, movie, e.get<char*>(1))
    LUA_BIND_STD_CLIENT(loadcrosshair, loadcrosshair_, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_CLIENT(showscores, {
        bool on = (addreleaseaction("CAPI.showscores()") != 0);
        SETV(scoreboard, on);
        scorebshow(on);
    })
    LUA_BIND_STD_CLIENT(tabify, tabify, e.get<char*>(1), e.get<int*>(2))
    LUA_BIND_STD(execcfg, Utility::config_exec_json, e.get<const char*>(1), e.get<bool>(2))
    LUA_BIND_STD(writecfg, Utility::writecfg, e.get<const char*>(1))
    LUA_BIND_STD(getcfg, e.push, Utility::Config::getString(e.get<const char*>(1), e.get<const char*>(2), "?").c_str())
    LUA_BIND_DEF(readfile, {
        try
        {
            REFLECT_PYTHON( read_file_safely );

            boost::python::object data = read_file_safely(e.get<const char*>(1));
            const char *text = boost::python::extract<const char*>(data);

            e.push(text);
        }
        catch(boost::python::error_already_set const &)
        {
            printf("Error in Python execution of embedded read_file_safely\r\n");
            PyErr_Print();
            assert(0 && "Halting on Python error");
        }
    })
    LUA_BIND_STD(addzip, addzip,
                 e.get<const char*>(1),
                 e.get<const char*>(2)[0] ? e.get<const char*>(2) : NULL,
                 e.get<const char*>(3)[0] ? e.get<const char*>(3) : NULL)
    LUA_BIND_STD(removezip, removezip, e.get<const char*>(1))
    

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

    LUA_BIND_DEF(resetvar, var::get(e.get<const char*>(1))->r();)

    LUA_BIND_DEF(newvar, {
        const char *name = e.get<const char*>(1);
        switch (e.get<int>(2))
        {
            case var::VAR_I:
            {
                var::cvar *ev = var::get(name);
                if (!ev)
                {
                    ev = var::reg(name, new var::cvar(name, e.get<int>(3), true));
                    ev->regliv();
                }
                else ev->s(e.get<int>(3), true, false, false);
                break;
            }
            case var::VAR_F:
            {
                var::cvar *ev = var::get(name);
                if (!ev)
                {
                    ev = var::reg(name, new var::cvar(name, e.get<float>(3), true));
                    ev->reglfv();
                }
                else ev->s(e.get<float>(3), true, false, false);
                break;
            }
            case var::VAR_S:
            {
                var::cvar *ev = var::get(name);
                if (!ev)
                {
                    ev = var::reg(name, new var::cvar(name, e.get<const char*>(3), true));
                    ev->reglsv();
                }
                else ev->s(e.get<const char*>(3), true, false, false);
                break;
            }
            default: break;
        }
    })

    LUA_BIND_DEF(svfl, {
        const char *name = e.get<const char*>(1);
        int type = e.get<int>(2);
        switch (type)
        {
            case var::VAR_I:
            {
                var::syncfl(name, e.get<int>(3));
                break;
            }
            case var::VAR_F:
            {
                var::syncfl(name, e.get<float>(3));
                break;
            }
            case var::VAR_S:
            {
                var::syncfl(name, e.get<const char*>(3));
                break;
            }
            default: break;
        }
    })

    LUA_BIND_DEF(ssls, {
        if (e.is<void>(1))
            run_python((char*)"intensity.components.server_runner.stop_server()");
        else
        {
            defformatstring(cmd)("intensity.components.server_runner.run_server('%s'%s)",
                                 e.get<const char*>(1),
                                 !GETIV(logged_into_master) ? ", False" : ""
                                );
            run_python((char*)cmd);
        }
    })

    // Console

    LUA_BIND_STD_CLIENT(toggleconsole, SETV, fullconsole, GETIV(fullconsole) ^ 1)
    LUA_BIND_STD_CLIENT(conskip, setconskip, conskip, GETIV(fullconsole) ? GETIV(fullconfilter) : GETIV(confilter), e.get<int>(1))
    LUA_BIND_STD_CLIENT(miniconskip, setconskip, miniconskip, GETIV(miniconfilter), e.get<int>(1))
    LUA_BIND_CLIENT(clearconsole, while(conlines.length()) delete[] conlines.pop().line;)
    LUA_BIND_STD_CLIENT(bind, bindkey, e.get<char*>(1), e.get<char*>(2), keym::ACTION_DEFAULT, "bind")
    LUA_BIND_STD_CLIENT(specbind, bindkey, e.get<char*>(1), e.get<char*>(2), keym::ACTION_SPECTATOR, "specbind")
    LUA_BIND_STD_CLIENT(editbind, bindkey, e.get<char*>(1), e.get<char*>(2), keym::ACTION_EDITING, "editbind")
    LUA_BIND_STD_CLIENT(getbind, getbind, e.get<char*>(1), keym::ACTION_DEFAULT)
    LUA_BIND_STD_CLIENT(getspecbind, getbind, e.get<char*>(1), keym::ACTION_SPECTATOR)
    LUA_BIND_STD_CLIENT(geteditbind, getbind, e.get<char*>(1), keym::ACTION_EDITING)
    LUA_BIND_STD_CLIENT(searchbinds, searchbinds, e.get<char*>(1), keym::ACTION_DEFAULT)
    LUA_BIND_STD_CLIENT(searchspecbinds, searchbinds, e.get<char*>(1), keym::ACTION_SPECTATOR)
    LUA_BIND_STD_CLIENT(searcheditbinds, searchbinds, e.get<char*>(1), keym::ACTION_EDITING)
    LUA_BIND_CLIENT(saycommand, {
        int n = e.gettop();
        switch (n)
        {
            case 0: inputcommand((char*)""); break;
            case 1: inputcommand(e.get<char*>(1)); break;
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
                inputcommand(s);
                delete s;
                break;
            }
        }
    })
    LUA_BIND_STD_CLIENT(inputcommand, inputcommand, e.get<char*>(1), e.get<char*>(2), e.get<char*>(3))
    LUA_BIND_STD_CLIENT(history, history_, e.get<int*>(1))
    LUA_BIND_STD_CLIENT(onrelease, onrelease, e.get<char*>(1))
    LUA_BIND_STD_CLIENT(complete, addfilecomplete, e.get<char*>(1), e.get<char*>(2), e.get<char*>(3))
    LUA_BIND_STD_CLIENT(listcomplete, addlistcomplete, e.get<char*>(1), e.get<char*>(2))

    LUA_BIND_CLIENT(setdeftpm, {
        // Only allow this to be done once
        if (!lua::engine["setdeftpm"])
        {
            lua::engine["setdeftpm"] = "set";
            SETV(thirdperson, e.get<int>(1));
        } else
            Logging::log(Logging::WARNING, "Can only set default thirdperson mode once per map\r\n");
    })
}

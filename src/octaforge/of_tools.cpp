/*
 * of_tools.cpp, version 1
 * Various utilities for OctaForge engine.
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

#include "cube.h"
#include "of_world.h"
#include "of_tools.h"
#include <sys/stat.h>
#include <ctype.h>

void writebinds(stream *f);
extern string homedir;
extern int clockrealbase;

namespace tools
{
    bool valanumeric(const char *str, const char *allow)
    {
        for (; *str; str++)
        {
            if (!isalnum(*str) && !strchr(allow, *str))
                return false;
        }
        return true;
    }

    bool valrpath(const char *path)
    {
        int level = -1;
        char  *p = newstring(path);
        char  *t = strtok(p, "/\\");
        while (t)
        {
            if (!strcmp(t, "..")) level--;
            else if (strcmp(t, ".") && strcmp(t, "")) level++;
            if (level < 0)
            {
                delete[] p;
                return false;
            }
            t = strtok(NULL, "/\\");
        }
        level--;
        delete[] p;
        return (level >= 0);
    }

    bool fnewer(const char *file, const char *otherfile)
    {
        struct stat buf, buf2;
        if (stat(file,      &buf )) return false;
        if (stat(otherfile, &buf2)) return true;
        if (buf.st_mtime > buf2.st_mtime) return true;
        return false;
    }

    bool fcopy(const char *src, const char *dest)
    {
        FILE *from, *to;
        char c;

        if (!(from = fopen(src,  "rb"))) return false;
        if (!(to   = fopen(dest, "wb")))
        {
            fclose(from);
            return false;
        }

        while (!feof(from))
        {
            c = fgetc(from);
            if (ferror(from))
            {
                fclose(from);
                fclose(to);
                return false;
            }
            if (!feof(from)) fputc(c, to);
            if (ferror(to))
            {
                fclose(from);
                fclose(to);
                return false;
            }
        }

        fclose(from);
        fclose(to);
        return true;
    }

    bool fdel(const char *file)
    {
#ifdef WIN32
        return (DeleteFile(file) != 0);
#else
        return (remove(file) == 0);
#endif
    }

    bool fempty(const char *file)
    {
        FILE *f = fopen(file, "w");
        if (!f) return false;
        fclose(f);
        return true;
    }

    static inline bool sortvars(var::cvar *x, var::cvar *y)
    {
        return strcmp(x->name, y->name) < 0;
    }

    void writecfg(const char *name)
    {
        stream *f = openutf8file(path(name && name[0] ? name : game::savedconfig(), true), "wb");
        if(!f) return;

        f->printf("-- automatically written on exit, DO NOT MODIFY\n");
        f->printf("-- delete this file to have %s overwrite these settings\n", game::defaultconfig());
        f->printf("-- modify settings in game, or put settings in %s to override anything\n\n", game::autoexec());
        f->printf("-- configuration file version\n");
        f->printf("if OF_CFG_VERSION ~= %i then return nil end\n\n", OF_CFG_VERSION);
        f->printf("-- engine variables\n");

        for (var::vartable::cit it = var::vars->begin(); it != var::vars->end(); ++it)
        {
            var::cvar *v = it->second;
            /* do not write aliases here! */
            if ((v->flags&var::VAR_ALIAS)   != 0) continue;
            if ((v->flags&var::VAR_PERSIST) != 0) switch(v->type)
            {
                case var::VAR_I: f->printf("%s = %d\n", v->name, v->curv.i); break;
                case var::VAR_F: f->printf("%s = %f\n", v->name, v->curv.f); break;
                case var::VAR_S:
                {
                    if (!v->curv.s) continue;
                    f->printf("%s = \"", v->name);
                    for (size_t sz = 0; sz < strlen(v->curv.s); sz++)
                    {
                        switch (v->curv.s[sz])
                        {
                            case '\n': f->write("^n", 2); break;
                            case '\t': f->write("^t", 2); break;
                            case '\f': f->write("^f", 2); break;
                            case '"': f->write("^\"", 2); break;
                            default: f->putchar(v->curv.s[sz]); break;
                        }
                    }
                    f->printf("\"\n");
                    break;
                }
            }
        }
        f->printf("\n");
        f->printf("-- binds\n");
        writebinds(f);
        f->printf("\n");

        f->printf("-- aliases\n");
        f->printf("local was_persisting = engine.persist_vars(true)\n");
        for (var::vartable::cit it = var::vars->begin(); it != var::vars->end(); ++it)
        {
            var::cvar *v = it->second;
            if ((v->flags&var::VAR_ALIAS) != 0 && (v->flags&var::VAR_PERSIST) != 0) switch (v->type)
            {
                case var::VAR_I: f->printf("engine.new_var(\"%s\", engine.VAR_I, %d)\n", v->name, v->curv.i); break;
                case var::VAR_F: f->printf("engine.new_var(\"%s\", engine.VAR_F, %f)\n", v->name, v->curv.f); break;
                case var::VAR_S:
                {
                    if (strstr(v->name, "new_entity_gui_field") || !v->curv.s) continue;
                    f->printf("engine.new_var(\"%s\", engine.VAR_S, \"", v->name);
                    for (size_t sz = 0; sz < strlen(v->curv.s); sz++)
                    {
                        switch (v->curv.s[sz])
                        {
                            case '\n': f->write("^n", 2); break;
                            case '\t': f->write("^t", 2); break;
                            case '\f': f->write("^f", 2); break;
                            case '"': f->write("^\"", 2); break;
                            default: f->putchar(v->curv.s[sz]); break;
                        }
                    }
                    f->printf("\")\n");
                    break;
                }
            }
        }
        f->printf("engine.persist_vars(was_persisting)\n");
        f->printf("\nOF_CFG_VERSION_PASSED = true\n");
        delete f;
    }

    bool execcfg(const char *cfgfile, bool ignore_ret)
    {
        string s;
        copystring(s, cfgfile);
        char *buf = loadfile(path(s), NULL);
        if(!buf) return false;
        auto err = lapi::state.do_string(buf, lua::ERROR_TRACEBACK);
        if (types::get<0>(err))
            logger::log(logger::ERROR, "%s\n", types::get<1>(err));

        bool ret = true;
        if (!ignore_ret)
        {
            ret = lapi::state["OF_CFG_VERSION_PASSED"].to<bool>();
            if (!ret)
            {
                conoutf(
                    "Your OctaForge config file was too old to run with "
                    "your current client. Initializing a default set."
                );
            }
            lapi::state["OF_CFG_VERSION_PASSED"] = lua::nil;
        }

        delete[] buf;
        return ret;
    }

    int currtime()
    {
#ifdef SERVER
        return enet_time_get();
#else /* CLIENT */
        return SDL_GetTicks() - clockrealbase;
#endif
    }

} /* end namespace tools */

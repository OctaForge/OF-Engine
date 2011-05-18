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
#include <sys/stat.h>

void writebinds(stream *f);
extern string homedir;
extern int clockrealbase;

namespace tools
{
    bool valanumeric(const char *str, const char *allow)
    {
        register unsigned int i, n;
        bool skip = false;
        for (i = 0; i < strlen(str); i++)
        {
            if (str[i] <= 47
            || (str[i] >= 58 && str[i] <= 64)
            || (str[i] >= 91 && str[i] <= 96)
            ||  str[i] >= 123
            ) {
                if (allow)
                {
                    for (n = 0; n < strlen(allow); n++) if (str[i] == allow[n])
                    {
                        skip = true;
                        break;
                    }
                    if (skip)
                    {
                        skip = false;
                        continue;
                    }
                }
                logger::log(
                    logger::WARNING,
                    "Alphanumeric validation of string \"%s\" failed (using alphanumeric + %s)",
                    str,
                    allow ? allow : "nothing"
                );
                return false;
            }
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

    bool mkpath(const char *path)
    {
        char  buf[4096];
        char buff[4096];
        char  *p = newstring(path);
        char  *t = strtok(p, "/\\");   
        while (t)
        {
            if (t[0] == '.')
                t = strtok(NULL, "/\\");

            if (strlen(buf) > 0)
            {
                snprintf(buff, sizeof(buff), "%s%c%s", buf, PATHDIV, t);
                if (!createdir(buff))
                {
                    delete[] p;
                    return false;
                }
                snprintf(buf, sizeof(buf), "%s", buff);
            }
            else if (!createdir(t))
            {
                delete[] p;
                return false;
            }
            else snprintf(buf, sizeof(buf), "%s", t);

            t  = strtok(NULL, "/\\");
        }
        delete[] p;
        return true;
    }

    char *sread(const char *fname)
    {
        if (!fname
          || strstr(fname, "..")
          || strchr(fname, '~')
          || fname[0] == '/'
        ) return NULL;
        /* TODO: more checks */

        char buf[512], buff[512];
        char *loaded = NULL;

        if (strlen(fname) >= 2 && fname[0] == '.' && fname[1] == '/')
        {
            char *path = world::get_mapfile_path(fname + 2);
            snprintf(buf, sizeof(buf), "%s", path);
            delete[] path;
        }
        else snprintf(
            buf, sizeof(buf),
            "%s%cdata%c%s",
            homedir, PATHDIV,
            PATHDIV, fname
        );

        loaded = loadfile(buf, NULL);
        if (!loaded)
        {
            snprintf(buff, sizeof(buff), "data%c%s", PATHDIV, fname);
            loaded = loadfile(buff, NULL);
        }
        if (!loaded)
        {
            logger::log(logger::ERROR, "Could not load file %s (%s, %s)", fname, buf, buff);
            return NULL;
        }
        return loaded;
    }

    static int sortvars(var::cvar **x, var::cvar **y)
    {
        return strcmp((*x)->name, (*y)->name);
    }

    void writecfg(const char *name)
    {
        stream *f = openfile(path(name && name[0] ? name : game::savedconfig(), true), "w");
        if(!f) return;

        f->printf("-- automatically written on exit, DO NOT MODIFY\n");
        f->printf("-- delete this file to have %s overwrite these settings\n", game::defaultconfig());
        f->printf("-- modify settings in game, or put settings in %s to override anything\n\n", game::autoexec());
        f->printf("-- engine variables\n");
        vector<var::cvar*> varv;

        enumerate(*var::vars, var::cvar*, v, varv.add(v));
        varv.sort(sortvars);
        loopv(varv)
        {
            var::cvar *v = varv[i];
            if ((v->flags&var::VAR_PERSIST) != 0) switch(v->type)
            {
                case var::VAR_I: f->printf("%s = %d\n", v->name, v->curv.i); break;
                case var::VAR_F: f->printf("%s = %f\n", v->name, v->curv.f); break;
                case var::VAR_S:
                {
                    f->printf("%s = \"", v->name);
                    const char *s = v->curv.s;
                    for (; *s; s++) switch(*s)
                    {
                        case '\n': f->write("^n", 2); break;
                        case '\t': f->write("^t", 2); break;
                        case '\f': f->write("^f", 2); break;
                        case '"': f->write("^\"", 2); break;
                        default: f->putchar(*s); break;
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
        loopv(varv)
        {
            var::cvar *v = varv[i];
            if ((v->flags&var::VAR_ALIAS) != 0 && (v->flags&var::VAR_PERSIST) != 0 && (v->flags&var::VAR_OVERRIDEN) == 0) switch (v->type)
            {
                case var::VAR_I: f->printf("engine.newvar(\"%s\", engine.VAR_I, %d)\n", v->name, v->curv.i); break;
                case var::VAR_F: f->printf("engine.newvar(\"%s\", engine.VAR_F, %f)\n", v->name, v->curv.f); break;
                case var::VAR_S:
                {
                    if (strstr(v->name, "new_entity_gui_field")) continue;
                    f->printf("engine.newvar(\"%s\", engine.VAR_S, \"", v->name);
                    const char *s = v->curv.s;
                    for(; *s; s++) switch(*s)
                    {
                        case '\n': f->write("^n", 2); break;
                        case '\t': f->write("^t", 2); break;
                        case '\f': f->write("^f", 2); break;
                        case '"': f->write("^\"", 2); break;
                        default: f->putchar(*s); break;
                    }
                    f->printf("\")\n");
                    break;
                }
            }
        }
        f->printf("\n");
        delete f;
    }

    bool execcfg(const char *cfgfile)
    {
        string s;
        copystring(s, cfgfile);
        char *buf = loadfile(path(s), NULL);
        if(!buf) return false;
        lua::engine.exec(buf);
        delete[] buf;
        return true;
    }

    char *vstrcat(char *str, const char *format, ...)
    {
        if (!str) str = new char[1];
        if (!str) return NULL;

        va_list args;
        char buf[64];

        size_t oslen = 0;
        size_t aslen = 0;

        va_start(args, format);
        while (*format != '\0')
        {
            oslen = strlen(str);
            switch (*format)
            {
                case 's':
                {
                    char *s = va_arg(args, char*);
                    aslen = strlen(s);

                    char *ns = new char[oslen + aslen + 1];
                    memcpy(ns, str, oslen + 1);
                    delete[] str;

                    memcpy(ns + strlen(ns), s, aslen + 1);
                    str = ns;
                    break;
                }
                case 'i':
                case 'd':
                {
                    snprintf(buf, sizeof(buf), "%i", va_arg(args, int));
                    aslen = strlen(buf);

                    char *ns = new char[oslen + aslen + 1];
                    memcpy(ns, str, oslen + 1);
                    delete[] str;
    
                    memcpy(ns + strlen(ns), buf, aslen + 1);
                    str = ns;
                    break;
                }
                case 'f':
                {
                    snprintf(buf, sizeof(buf), "%f", va_arg(args, double));
                    aslen = strlen(buf);

                    char *ns = new char[oslen + aslen + 1];
                    memcpy(ns, str, oslen + 1);
                    delete[] str;
    
                    memcpy(ns + strlen(ns), buf, aslen + 1);
                    str = ns;
                    break;
                }
                default: continue;
            }
            if (!str) return NULL;
            format++;
        }
        va_end(args);
        return str;
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

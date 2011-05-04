/*
 * of_tools.c, version 1
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
#include "of_tools.h"
#include "of_world.h"
#include <sys/stat.h>

void writebinds(stream *f);
extern string homedir;

bool of_tools_validate_alphanumeric(const char *str, const char *allow)
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
            Logging::log(
                Logging::WARNING,
                "Alphanumeric validation of string \"%s\" failed (using alphanumeric + %s)",
                str,
                allow ? allow : "nothing"
            );
            return false;
        }
    }
    return true;
}

bool of_tools_validate_relpath(const char *path)
{
    int level = -1;
    char  *p = strdup(path);
    char  *t = strtok(p, "/\\");
    while (t)
    {
        if (!strcmp(t, "..")) level--;
        else if (strcmp(t, ".") && strcmp(t, "")) level++;
        if (level < 0)
        {
            OF_FREE(p);
            return false;
        }
        t = strtok(NULL, "/\\");
    }
    level--;
    OF_FREE(p);
    return (level >= 0);
}

bool of_tools_is_file_newer_than(const char *file, const char *otherfile)
{
    struct stat buf, buf2;
    if (stat(file,      &buf )) return false;
    if (stat(otherfile, &buf2)) return true;
    if (buf.st_mtime > buf2.st_mtime) return true;
    return false;
}

bool of_tools_file_copy(const char *src, const char *dest)
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

bool of_tools_createpath(const char *path)
{
    char  buf[4096];
    char  *p = strdup(path);
    char  *t = strtok(p, "/\\");   
    while (t)
    {
        if (t[0] == '.')
            t = strtok(NULL, "/\\");

        if (strlen(buf) > 0)
        {
            snprintf (buf, sizeof(buf), "%s%c%s", buf, PATHDIV, t);
            if (!createdir(buf))
            {
                OF_FREE(p);
                return false;
            }
        }
        else if (!createdir(t))
        {
            OF_FREE(p);
            return false;
        }
        else snprintf(buf, sizeof(buf), "%s", t);

        t  = strtok(NULL, "/\\");
    }
    OF_FREE(p);
    return true;
}

char *of_tools_loadfile_safe(const char *fname)
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
        char *path = of_world_get_mapfile_path(fname + 2);
        snprintf(buf, sizeof(buf), "%s", path);
        OF_FREE(path);
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
        Logging::log(Logging::ERROR, "Could not load file %s (%s, %s)", fname, buf, buff);
        return NULL;
    }
    return loaded;
}

static int sortvars(var::cvar **x, var::cvar **y)
{
    return strcmp((*x)->gn(), (*y)->gn());
}

void of_tools_writecfg(const char *name)
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
        if (v->ispersistent()) switch(v->gt())
        {
            case var::VAR_I: f->printf("%s = %d\n", v->gn(), v->gi()); break;
            case var::VAR_F: f->printf("%s = %f\n", v->gn(), v->gf()); break;
            case var::VAR_S:
            {
                f->printf("%s = \"", v->gn());
                const char *s = v->gs();
                for(; *s; s++) switch(*s)
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
        if (v->isalias() && v->ispersistent() && !v->isoverriden()) switch (v->gt())
        {
            case var::VAR_I: f->printf("engine.newvar(\"%s\", engine_variables.VAR_I, %d)\n", v->gn(), v->gi()); break;
            case var::VAR_F: f->printf("engine.newvar(\"%s\", engine_variables.VAR_F, %f)\n", v->gn(), v->gf()); break;
            case var::VAR_S:
            {
                if (strstr(v->gn(), "new_entity_gui_field")) continue;
                f->printf("engine.newvar(\"%s\", engine.VAR_S, \"", v->gn());
                const char *s = v->gs();
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

bool of_tools_execcfg(const char *cfgfile)
{
    string s;
    copystring(s, cfgfile);
    char *buf = loadfile(path(s), NULL);
    if(!buf) return false;
    lua::engine.exec(buf);
    delete[] buf;
    return true;
}

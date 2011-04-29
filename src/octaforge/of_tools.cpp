/*
 * of_tools.c, version 1
 * Various utilities for OctaForge engine
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
            p = NULL; free(p);
            return false;
        }
        t = strtok(NULL, "/\\");
    }
    level--;
    p = NULL; free(p);
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

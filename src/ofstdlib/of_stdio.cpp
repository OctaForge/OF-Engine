/*
 * File: of_stdio.cpp
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Standard I/O extensions - implementation.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifdef WIN32
#include <cstdio>
#include <cstdarg>

int _vasprintf(char **strp, const char *fmt, va_list ap)
{
    char *buf;
    int   ret;

    ret = _vscprintf(fmt, ap) + 1;

    if (!(buf = (char*)malloc(ret)))
        return -1;

    *strp = buf;

    if ((ret = vsprintf(buf, fmt, ap)) < 0)
        return -1;

    return ret;
}

int _asprintf(char **strp, const char *fmt, ...)
{
    va_list ap;
    int    ret;

    va_start(ap, fmt);
    ret = vasprintf(strp, fmt, ap);
    va_end(ap);

    return ret;
}
#endif

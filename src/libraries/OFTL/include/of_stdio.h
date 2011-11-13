/* File: of_stdio.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Standard I/O extensions for Windows.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_STDIO_H
#define OF_STDIO_H

#ifdef WIN32

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

/* Function: _vasprintf
 * See vasprintf. Windows-specific implementation. Defined as <vasprintf>
 * by macro to get around redefinition issue on MinGW/Cygwin.
 */
inline int _vasprintf(char **strp, const char *fmt, va_list ap)
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

/* Function: _asprintf
 * See <_vasprintf>.
 */
inline int _asprintf(char **strp, const char *fmt, ...)
{
    va_list ap;
    int    ret;

    va_start(ap, fmt);
    ret = _vasprintf(strp, fmt, ap);
    va_end(ap);

    return ret;
}

/* Define: vasprintf
 * Alias for <_vasprintf> to get around redefinition issues.
 */
#define vasprintf _vasprintf

/* Define: asprintf
 * Alias for <_asprintf> to get around redefinition issues.
 */
#define asprintf _asprintf

#endif

#endif

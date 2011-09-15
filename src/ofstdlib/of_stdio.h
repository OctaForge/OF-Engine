/*
 * File: of_stdio.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Standard I/O extensions - headers.
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

/*
 * Function: _vasprintf
 * See vasprintf. Windows-specific implementation.
 * Defined as <vasprintf> by macro to get around
 * redefinition issue on MinGW/Cygwin.
 */
int _vasprintf(char **strp, const char *fmt, va_list ap);

/*
 * Function: _asprintf
 * See <_vasprintf>.
 */
int _asprintf(char **strp, const char *fmt, ...);

/*
 * Define: vasprintf
 * Alias for <_vasprintf> to get around redefinition issues.
 */
#define vasprintf _vasprintf

/*
 * Define: asprintf
 * Alias for <_asprintf> to get around redefinition issues.
 */
#define asprintf _asprintf

#endif

#endif

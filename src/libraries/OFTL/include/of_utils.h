/* File: of_utils.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Various generic stuff (like typedefs).
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *  Bits taken from the Cube 2 source code (zlib).
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_UTILS_H
#define OF_UTILS_H

#include <string.h>

#ifdef NULL
#undef NULL
#endif

/* Define: NULL
 * Set to 0.
 */
#define NULL 0

/* Typedef: uint
 * Defined as unsigned int.
 */
typedef unsigned int uint;

/* Typedef: ushort
 * Defined as unsigned short.
 */
typedef unsigned short ushort;

/* Typedef: ulong
 * Defined as unsigned long.
 */
typedef unsigned long ulong;

/* Typedef: uchar
 * Defined as unsigned char.
 */
typedef unsigned char uchar;

#endif

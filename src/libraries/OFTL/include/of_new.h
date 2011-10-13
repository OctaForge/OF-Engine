/* File: of_new.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Overloads for the new and delete operators.
 *  Included by of_utils.h. Defining OF_NO_NEW
 *  before including this makes it not define
 *  the new / delete operators.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_NEW_H
#define OF_NEW_H

#include "of_utils.h"

#ifndef OF_NO_NEW
#include <stdlib.h>

/* Operator: new
 * Allocates storage space.
 */
inline void *operator new(size_t size) 
{ 
    void  *p = malloc(size);
    if   (!p)  abort();
    return p;
}

/* Operator: new[]
 * Allocates storage space for array.
 */
inline void *operator new[](size_t size) 
{
    void  *p = malloc(size);
    if   (!p)  abort();
    return p;
}

/* Operator: delete
 * Deallocates storage space.
 */
inline void operator delete(void *p) { free(p); }

/* Operator: delete[]
 * Deallocates storage space of array.
 */
inline void operator delete[](void *p) { free(p); } 

inline void *operator new  (size_t, void *p)  { return p; }
inline void *operator new[](size_t, void *p)  { return p; }
inline void operator delete  (void *, void *) {}
inline void operator delete[](void *, void *) {}

#endif

/* Define: DELETEA
 * Behaves like <delete[]>, but NULLs the pointer after
 * deleting.
 *
 * See also <DELETEP>.
 */
#define DELETEA(p) \
{ \
    delete[] p; \
    p = NULL; \
}

/* Define: DELETEP
 * Behaves like <delete>, but NULLs the pointer after
 * deleting.
 *
 * See also <DELETEA>.
 */
#define DELETEP(p) \
{ \
    delete p; \
    p = NULL; \
}

#endif

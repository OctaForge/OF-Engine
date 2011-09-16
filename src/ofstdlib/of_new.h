/*
 * File: of_new.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Overloads for the new and delete operators.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_NEW_H
#define OF_NEW_H

#include <cstdlib>

#include "of_utils.h"

/*
 * Operator: new
 * Allocates storage space.
 */
inline void *operator new(size_t size) 
{ 
    void  *p = malloc(size);
    if   (!p)  abort();
    return p;
}

/*
 * Operator: new[]
 * Allocates storage space for array.
 */
inline void *operator new[](size_t size) 
{
    void  *p = malloc(size);
    if   (!p)  abort();
    return p;
}

/*
 * Operator: delete
 * Deallocates storage space.
 */
inline void operator delete(void *p)
{
    free(p);
    p = NULL;
}

/*
 * Operator: delete[]
 * Deallocates storage space of array.
 */
inline void operator delete[](void *p)
{
    free(p);
    p = NULL;
} 

inline void *operator new  (size_t, void *p)  { return p; }
inline void *operator new[](size_t, void *p)  { return p; }
inline void operator delete  (void *, void *) {}
inline void operator delete[](void *, void *) {}

/*
 * Define: DELETEA
 * Behaves like <delete[]>, but it checks if the given
 * pointer is NULL. If it's not, standard <delete[]>
 * gets called and the pointer gets NULLed.
 *
 * See also <DELETEP>.
 */
#define DELETEA(p) \
if (p) \
{ \
    delete[] p; \
    p = NULL; \
}

/*
 * Define: DELETEP
 * Behaves like <delete>, but it checks if the given
 * pointer is NULL. If it's not, standard <delete>
 * gets called and the pointer gets NULLed.
 *
 * See also <DELETEA>.
 */
#define DELETEP(p) \
if (p) \
{ \
    delete p; \
    p = NULL; \
}

#endif

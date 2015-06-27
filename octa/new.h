/* Default new/delete operator overloads for OctaSTD. Also has an impl file.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_NEW_H
#define OCTA_NEW_H

#ifndef OCTA_ALLOW_CXXSTD
#include "octa/types.h"

inline void *operator new     (octa::Size, void *p) { return p; }
inline void *operator new   [](octa::Size, void *p) { return p; }
inline void  operator delete  (void *, void *)  {}
inline void  operator delete[](void *, void *)  {}
#else
#include <new>
#endif

#endif
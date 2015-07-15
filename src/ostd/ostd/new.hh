/* Default new/delete operator overloads for OctaSTD. Also has an impl file.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OSTD_NEW_HH
#define OSTD_NEW_HH

#ifndef OSTD_ALLOW_CXXSTD
#include "ostd/types.hh"

inline void *operator new     (ostd::Size, void *p) { return p; }
inline void *operator new   [](ostd::Size, void *p) { return p; }
inline void  operator delete  (void *, void *)  {}
inline void  operator delete[](void *, void *)  {}
#else
#include <new>
#endif

#endif
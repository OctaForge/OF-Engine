/* Default new/delete operator overloads for OctaSTD. Also has a header file.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#include <stdlib.h>

#include "ostd/types.hh"

void *operator new(ostd::Size size) {
    void  *p = malloc(size);
    if   (!p) abort();
    return p;
}

void *operator new[](ostd::Size size) {
    void  *p = malloc(size);
    if   (!p) abort();
    return p;
}

void operator delete(void *p) noexcept {
    free(p);
}

void operator delete[](void *p) noexcept {
    free(p);
}
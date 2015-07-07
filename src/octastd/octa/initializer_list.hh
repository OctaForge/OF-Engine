/* Initializer list support for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_INITIALIZER_LIST_HH
#define OCTA_INITIALIZER_LIST_HH

#include <stddef.h>

#include "octa/range.hh"

#ifndef OCTA_ALLOW_CXXSTD
/* must be in std namespace otherwise the compiler won't know about it */
namespace std {

template<typename T>
class initializer_list {
    const T *p_buf;
    octa::Size p_len;

    constexpr initializer_list(const T *v, octa::Size n): p_buf(v), p_len(n) {}
public:
    constexpr initializer_list(): p_buf(nullptr), p_len(0) {}

    constexpr octa::Size size() const { return p_len; }

    constexpr const T *begin() const { return p_buf; }
    constexpr const T *end() const { return p_buf + p_len; }
};

}
#else
#include <initializer_list>
#endif

namespace octa {

template<typename T> using InitializerList = std::initializer_list<T>;

template<typename T>
PointerRange<const T> iter(std::initializer_list<T> init) {
    return PointerRange<const T>(init.begin(), init.end());
}

template<typename T>
PointerRange<const T> citer(std::initializer_list<T> init) {
    return PointerRange<const T>(init.begin(), init.end());
}

}

#endif
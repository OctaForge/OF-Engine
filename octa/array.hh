/* Static array implementation for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_ARRAY_HH
#define OCTA_ARRAY_HH

#include <stddef.h>

#include "octa/algorithm.hh"
#include "octa/range.hh"
#include "octa/string.hh"

namespace octa {

template<typename T, octa::Size N>
struct Array {
    using Size = octa::Size;
    using Difference = octa::Ptrdiff;
    using Value = T;
    using Reference = T &;
    using ConstReference = const T &;
    using Pointer = T *;
    using ConstPointer = const T *;
    using Range = octa::PointerRange<T>;
    using ConstRange = octa::PointerRange<const T>;

    T &operator[](Size i) { return p_buf[i]; }
    const T &operator[](Size i) const { return p_buf[i]; }

    T &at(Size i) { return p_buf[i]; }
    const T &at(Size i) const { return p_buf[i]; }

    T &front() { return p_buf[0]; }
    const T &front() const { return p_buf[0]; }

    T &back() { return p_buf[(N > 0) ? (N - 1) : 0]; }
    const T &back() const { return p_buf[(N > 0) ? (N - 1) : 0]; }

    Size size() const { return N; }
    Size max_size() const { return Size(~0) / sizeof(T); }

    bool empty() const { return N == 0; }

    bool in_range(Size idx) { return idx < N; }
    bool in_range(int idx) { return idx >= 0 && Size(idx) < N; }
    bool in_range(ConstPointer ptr) {
        return ptr >= &p_buf[0] && ptr < &p_buf[N];
    }

    Pointer data() { return p_buf; }
    ConstPointer data() const { return p_buf; }

    Range iter() {
        return Range(p_buf, p_buf + N);
    }
    ConstRange iter() const {
        return ConstRange(p_buf, p_buf + N);
    }
    ConstRange citer() const {
        return ConstRange(p_buf, p_buf + N);
    }

    void swap(Array &v) {
        octa::swap_ranges(iter(), v.iter());
    }

    T p_buf[(N > 0) ? N : 1];
};

} /* namespace octa */

#endif
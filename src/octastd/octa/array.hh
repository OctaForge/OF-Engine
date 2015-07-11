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
#include "octa/internal/tuple.hh"

namespace octa {

template<typename T, Size N>
struct Array {
    using Size = octa::Size;
    using Difference = Ptrdiff;
    using Value = T;
    using Reference = T &;
    using ConstReference = const T &;
    using Pointer = T *;
    using ConstPointer = const T *;
    using Range = PointerRange<T>;
    using ConstRange = PointerRange<const T>;

    T &operator[](Size i) { return p_buf[i]; }
    const T &operator[](Size i) const { return p_buf[i]; }

    T *at(Size i) {
        if (!in_range(i)) return nullptr;
        return &p_buf[i];
    }
    const T *at(Size i) const {
        if (!in_range(i)) return nullptr;
        return &p_buf[i];
    }

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

template<typename T, Size N>
struct TupleSize<Array<T, N>>: IntegralConstant<Size, N> {};

template<Size I, typename T, Size N>
struct TupleElementBase<I, Array<T, N>> {
    using Type = T;
};

template<Size I, typename T, Size N>
TupleElement<I, Array<T, N>> &get(Array<T, N> &a) {
    return a[I];
}

template<Size I, typename T, Size N>
const TupleElement<I, Array<T, N>> &get(const Array<T, N> &a) {
    return a[I];
}

template<Size I, typename T, Size N>
TupleElement<I, Array<T, N>> &&get(Array<T, N> &&a) {
    return a[I];
}

template<typename T, Size N>
inline bool operator==(const Array<T, N> &x, const Array<T, N> &y) {
    return equal(x.iter(), y.iter());
}

template<typename T, Size N>
inline bool operator!=(const Array<T, N> &x, const Array<T, N> &y) {
    return !(x == y);
}

template<typename T, Size N>
inline bool operator<(const Array<T, N> &x, const Array<T, N> &y) {
    return lexicographical_compare(x.iter(), y.iter());
}

template<typename T, Size N>
inline bool operator>(const Array<T, N> &x, const Array<T, N> &y) {
    return (y < x);
}

template<typename T, Size N>
inline bool operator<=(const Array<T, N> &x, const Array<T, N> &y) {
    return !(y < x);
}

template<typename T, Size N>
inline bool operator>=(const Array<T, N> &x, const Array<T, N> &y) {
    return !(x < y);
}

} /* namespace octa */

#endif
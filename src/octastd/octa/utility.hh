/* Utilities for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_UTILITY_HH
#define OCTA_UTILITY_HH

#include <stddef.h>

#include "octa/type_traits.hh"

namespace octa {

/* move */

template<typename T>
static inline constexpr RemoveReference<T> &&move(T &&v) {
    return static_cast<RemoveReference<T> &&>(v);
}

/* forward */

template<typename T>
static inline constexpr T &&forward(RemoveReference<T> &v) {
    return static_cast<T &&>(v);
}

template<typename T>
static inline constexpr T &&forward(RemoveReference<T> &&v) {
    return static_cast<T &&>(v);
}

/* exchange */

template<typename T, typename U = T>
T exchange(T &v, U &&nv) {
    T old = move(v);
    v = forward<U>(nv);
    return old;
}

/* declval */

template<typename T> AddRvalueReference<T> declval();

/* swap */

namespace detail {
    template<typename T>
    struct SwapTest {
        template<typename U, void (U::*)(U &)> struct Test {};
        template<typename U> static char test(Test<U, &U::swap> *);
        template<typename U> static  int test(...);
        static constexpr bool value = (sizeof(test<T>(0)) == sizeof(char));
    };

    template<typename T> inline void swap(T &a, T &b, EnableIf<
        detail::SwapTest<T>::value, bool
    > = true) {
        a.swap(b);
    }

    template<typename T> inline void swap(T &a, T &b, EnableIf<
        !detail::SwapTest<T>::value, bool
    > = true) {
        T c(move(a));
        a = move(b);
        b = move(c);
    }
}

template<typename T> void swap(T &a, T &b) {
   detail::swap(a, b);
}

template<typename T, Size N> void swap(T (&a)[N], T (&b)[N]) {
    for (Size i = 0; i < N; ++i) {
        octa::swap(a[i], b[i]);
    }
}

/* pair */

template<typename T, typename U>
struct Pair {
    T first;
    U second;

    Pair() = default;
    ~Pair() = default;

    Pair(const Pair &) = default;
    Pair(Pair &&) = default;

    Pair(const T &x, const U &y): first(x), second(y) {}

    template<typename TT, typename UU>
    Pair(TT &&x, UU &&y):
        first(forward<TT>(x)), second(forward<UU>(y)) {}

    template<typename TT, typename UU>
    Pair(const Pair<TT, UU> &v): first(v.first), second(v.second) {}

    template<typename TT, typename UU>
    Pair(Pair<TT, UU> &&v):
        first(move(v.first)), second(move(v.second)) {}

    Pair &operator=(const Pair &v) {
        first = v.first;
        second = v.second;
        return *this;
    }

    template<typename TT, typename UU>
    Pair &operator=(const Pair<TT, UU> &v) {
        first = v.first;
        second = v.second;
        return *this;
    }

    Pair &operator=(Pair &&v) {
        first = move(v.first);
        second = move(v.second);
        return *this;
    }

    template<typename TT, typename UU>
    Pair &operator=(Pair<TT, UU> &&v) {
        first = forward<TT>(v.first);
        second = forward<UU>(v.second);
        return *this;
    }

    void swap(Pair &v) {
        swap(first, v.first);
        swap(second, v.second);
    }
};

template<typename T> struct ReferenceWrapper;

namespace detail {
    template<typename T>
    struct MakePairRetBase {
        using Type = T;
    };

    template<typename T>
    struct MakePairRetBase<ReferenceWrapper<T>> {
        using Type = T &;
    };

    template<typename T>
    struct MakePairRet {
        using Type = typename detail::MakePairRetBase<Decay<T>>::Type;
    };
} /* namespace detail */

template<typename T, typename U>
Pair<typename detail::MakePairRet<T>::Type,
     typename detail::MakePairRet<U>::Type
 > make_pair(T &&a, U &&b) {
    return Pair<typename detail::MakePairRet<T>::Type,
                typename detail::MakePairRet<U>::Type
    >(forward<T>(a), forward<U>(b));;
}

namespace detail {
    template<typename T, typename U,
        bool = IsSame<RemoveCv<T>, RemoveCv<U>>::value,
        bool = IsEmpty<T>::value,
        bool = IsEmpty<U>::value
    > struct CompressedPairSwitch;

    /* neither empty */
    template<typename T, typename U, bool Same>
    struct CompressedPairSwitch<T, U, Same, false, false> { enum { value = 0 }; };

    /* first empty */
    template<typename T, typename U, bool Same>
    struct CompressedPairSwitch<T, U, Same, true, false> { enum { value = 1 }; };

    /* second empty */
    template<typename T, typename U, bool Same>
    struct CompressedPairSwitch<T, U, Same, false, true> { enum { value = 2 }; };

    /* both empty, not the same */
    template<typename T, typename U>
    struct CompressedPairSwitch<T, U, false, true, true> { enum { value = 3 }; };

    /* both empty and same */
    template<typename T, typename U>
    struct CompressedPairSwitch<T, U, true, true, true> { enum { value = 1 }; };

    template<typename T, typename U, Size = CompressedPairSwitch<T, U>::value>
    struct CompressedPairBase;

    template<typename T, typename U>
    struct CompressedPairBase<T, U, 0> {
        T p_first;
        U p_second;

        template<typename TT, typename UU>
        CompressedPairBase(TT &&a, UU &&b): p_first(forward<TT>(a)),
                                            p_second(forward<UU>(b)) {}

        T &first() { return p_first; }
        const T &first() const { return p_first; }

        U &second() { return p_second; }
        const U &second() const { return p_second; }

        void swap(CompressedPairBase &v) {
            octa::swap(p_first, v.p_first);
            octa::swap(p_second, v.p_second);
        }
    };

    template<typename T, typename U>
    struct CompressedPairBase<T, U, 1>: T {
        U p_second;

        template<typename TT, typename UU>
        CompressedPairBase(TT &&a, UU &&b): T(forward<TT>(a)),
                                            p_second(forward<UU>(b)) {}

        T &first() { return *this; }
        const T &first() const { return *this; }

        U &second() { return p_second; }
        const U &second() const { return p_second; }

        void swap(CompressedPairBase &v) {
            octa::swap(p_second, v.p_second);
        }
    };

    template<typename T, typename U>
    struct CompressedPairBase<T, U, 2>: U {
        T p_first;

        template<typename TT, typename UU>
        CompressedPairBase(TT &&a, UU &&b): U(forward<UU>(b)),
                                            p_first(forward<TT>(a)) {}

        T &first() { return p_first; }
        const T &first() const { return p_first; }

        U &second() { return *this; }
        const U &second() const { return *this; }

        void swap(CompressedPairBase &v) {
            octa::swap(p_first, v.p_first);
        }
    };

    template<typename T, typename U>
    struct CompressedPairBase<T, U, 3>: T, U {
        template<typename TT, typename UU>
        CompressedPairBase(TT &&a, UU &&b): T(forward<TT>(a)),
                                            U(forward<UU>(b)) {}

        T &first() { return *this; }
        const T &first() const { return *this; }

        U &second() { return *this; }
        const U &second() const { return *this; }

        void swap(CompressedPairBase &) {}
    };

    template<typename T, typename U>
    struct CompressedPair: CompressedPairBase<T, U> {
        using Base = CompressedPairBase<T, U>;

        template<typename TT, typename UU>
        CompressedPair(TT &&a, UU &&b): Base(forward<TT>(a),
                                             forward<UU>(b)) {}

        T &first() { return Base::first(); }
        const T &first() const { return Base::first(); }

        U &second() { return Base::second(); }
        const U &second() const { return Base::second(); }

        void swap(CompressedPair &v) {
            Base::swap(v);
        }
    };
} /* namespace detail */

} /* namespace octa */

#endif
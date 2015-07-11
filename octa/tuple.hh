/* Tuples or OctaSTD. Partially taken from the libc++ project.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_TUPLE_HH
#define OCTA_TUPLE_HH

#include "octa/internal/tuple.hh"

#include "octa/types.hh"
#include "octa/type_traits.hh"
#include "octa/memory.hh"
#include "octa/utility.hh"

namespace octa {

/* tuple size */

template<typename ...T> struct TupleSize<Tuple<T...>>:
    IntegralConstant<Size, sizeof...(T)> {};

/* tuple element */

template<Size I, typename ...T>
struct TupleElementBase<I, Tuple<T...>> {
    using Type = typename TupleElementBase<I, detail::TupleTypes<T...>>::Type;
};

/* tuple leaf */

namespace detail {
    template<Size I, typename H, bool = IsEmpty<H>::value>
    struct TupleLeaf {
        constexpr TupleLeaf(): p_value() {
            static_assert(!IsReference<H>::value,
                "attempt to default construct a reference element in a tuple");
        }

        template<typename A>
        TupleLeaf(IntegralConstant<int, 0>, const A &): p_value() {
            static_assert(!IsReference<H>::value,
                "attempt to default construct a reference element in a tuple");
        }
        template<typename A>
        TupleLeaf(IntegralConstant<int, 1>, const A &a): p_value(allocator_arg, a) {
            static_assert(!IsReference<H>::value,
                "attempt to default construct a reference element in a tuple");
        }
        template<typename A>
        TupleLeaf(IntegralConstant<int, 2>, const A &a): p_value(a) {
            static_assert(!IsReference<H>::value,
                "attempt to default construct a reference element in a tuple");
        }

        template<typename T,
                 typename = EnableIf<And<Not<IsSame<Decay<T>, TupleLeaf>>,
                                         IsConstructible<H, T>>::value>>
        explicit TupleLeaf(T &&t): p_value(forward<T>(t)) {
            static_assert(!IsReference<H>::value ||
                          (IsLvalueReference<H>::value &&
                           (IsLvalueReference<T>::value ||
                            IsSame<RemoveReference<T>,
                                   ReferenceWrapper<RemoveReference<H>>
                            >::value)) ||
                           (IsRvalueReference<H>::value &&
                            !IsLvalueReference<T>::value),
            "attempt to construct a reference element in a tuple with an rvalue");
        }

        template<typename T, typename A>
        explicit TupleLeaf(IntegralConstant<int, 0>, const A &, T &&t):
                           p_value(forward<T>(t)) {
            static_assert(!IsLvalueReference<H>::value ||
                          (IsLvalueReference<H>::value &&
                           (IsLvalueReference<T>::value ||
                            IsSame<RemoveReference<T>,
                                   ReferenceWrapper<RemoveReference<H>>
                            >::value)),
            "attempt to construct a reference element in a tuple with an rvalue");
        }

        template<typename T, typename A>
        explicit TupleLeaf(IntegralConstant<int, 1>, const A &a, T &&t):
                           p_value(allocator_arg, a, forward<T>(t)) {
            static_assert(!IsLvalueReference<H>::value ||
                          (IsLvalueReference<H>::value &&
                           (IsLvalueReference<T>::value ||
                            IsSame<RemoveReference<T>,
                                   ReferenceWrapper<RemoveReference<H>>
                            >::value)),
            "attempt to construct a reference element in a tuple with an rvalue");
        }

        template<typename T, typename A>
        explicit TupleLeaf(IntegralConstant<int, 2>, const A &a, T &&t):
                           p_value(forward<T>(t), a) {
            static_assert(!IsLvalueReference<H>::value ||
                          (IsLvalueReference<H>::value &&
                           (IsLvalueReference<T>::value ||
                            IsSame<RemoveReference<T>,
                                   ReferenceWrapper<RemoveReference<H>>
                            >::value)),
            "attempt to construct a reference element in a tuple with an rvalue");
        }

        TupleLeaf(const TupleLeaf &) = default;
        TupleLeaf(TupleLeaf &&) = default;

        template<typename T>
        TupleLeaf &operator=(T &&t) {
            p_value = forward<T>(t);
            return *this;
        }

        void swap(TupleLeaf &t) {
            swap_adl(get(), t.get());
        }

        H &get() { return p_value; }
        const H &get() const { return p_value; }

    private:
        TupleLeaf &operator=(const TupleLeaf &);
        H p_value;
    };

    template<Size I, typename H>
    struct TupleLeaf<I, H, true>: private H {
        constexpr TupleLeaf() {}

        template<typename A>
        TupleLeaf(IntegralConstant<int, 0>, const A &) {}

        template<typename A>
        TupleLeaf(IntegralConstant<int, 1>, const A &a):
            H(allocator_arg, a) {}

        template<typename A>
        TupleLeaf(IntegralConstant<int, 2>, const A &a): H(a) {}

        template<typename T,
                 typename = EnableIf<And<
                     Not<IsSame<Decay<T>, TupleLeaf>>,
                     IsConstructible<H, T>
                 >::value>
        > explicit TupleLeaf(T &&t): H(forward<T>(t)) {}

        template<typename T, typename A>
        explicit TupleLeaf(IntegralConstant<int, 0>, const A &, T &&t):
            H(forward<T>(t)) {}

        template<typename T, typename A>
        explicit TupleLeaf(IntegralConstant<int, 1>, const A &a, T &&t):
            H(allocator_arg, a, forward<T>(t)) {}

        template<typename T, typename A>
        explicit TupleLeaf(IntegralConstant<int, 2>, const A &a, T &&t):
            H(forward<T>(t), a) {}

        TupleLeaf(const TupleLeaf &) = default;
        TupleLeaf(TupleLeaf &&) = default;

        template<typename T>
        TupleLeaf &operator=(T &&t) {
            H::operator=(forward<T>(t));
            return *this;
        }

        void swap(TupleLeaf &t) {
            swap_adl(get(), t.get());
        }

        H &get() { return (H &)*this; }
        const H &get() const { return (const H &)*this; }

    private:
        TupleLeaf &operator=(const TupleLeaf &);
    };
} /* namespace detail */

/* internal utils */

namespace detail {
    template<typename ...A>
    inline void tuple_swallow(A &&...) {}

    template<bool ...A>
    struct TupleAll: IsSame<TupleAll<A...>, TupleAll<(A, true)...>> {};

    template<typename T>
    struct TupleAllDefaultConstructible;

    template<typename ...A>
    struct TupleAllDefaultConstructible<TupleTypes<A...>>:
        TupleAll<IsDefaultConstructible<A>::value...> {};
}

/* tuple implementation */

namespace detail {
    template<typename, typename ...> struct TupleBase;

    template<Size ...I, typename ...A>
    struct TupleBase<TupleIndices<I...>, A...>: TupleLeaf<I, A>... {
        constexpr TupleBase() {}

        template<Size ...Ia, typename ...Aa,
                 Size ...Ib, typename ...Ab, typename ...T>
        explicit TupleBase(TupleIndices<Ia...>, TupleTypes<Aa...>,
                           TupleIndices<Ib...>, TupleTypes<Ab...>,
                           T &&...t):
            TupleLeaf<Ia, Aa>(forward<T>(t))...,
            TupleLeaf<Ib, Ab>()... {}

        template<typename Alloc, Size ...Ia, typename ...Aa,
                 Size ...Ib, typename ...Ab, typename ...T>
        explicit TupleBase(AllocatorArg, const Alloc &a,
                           TupleIndices<Ia...>, TupleTypes<Aa...>,
                           TupleIndices<Ib...>, TupleTypes<Ab...>,
                           T &&...t):
            TupleLeaf<Ia, Aa>(UsesAllocatorConstructor<Aa, Alloc, T>(), a,
                forward<T>(t))...,
            TupleLeaf<Ib, Ab>(UsesAllocatorConstructor<Ab, Alloc>(), a)...
        {}

        template<typename T, typename = EnableIf<
            TupleConstructible<T, Tuple<A...>>::value
        >> TupleBase(T &&t): TupleLeaf<I, A>(forward<
            TupleElement<I, MakeTupleTypes<T>>
        >(get<I>(t)))... {}

        template<typename Alloc, typename T, typename = EnableIf<
            TupleConvertible<T, Tuple<A...>>::value
        >> TupleBase(AllocatorArg, const Alloc &a, T &&t):
            TupleLeaf<I, A>(UsesAllocatorConstructor<
                A, Alloc, TupleElement<I, MakeTupleTypes<T>>
            >(), a, forward<TupleElement<I, MakeTupleTypes<T>>>(get<I>(t)))...
        {}

        template<typename T>
        EnableIf<TupleAssignable<T, Tuple<A...>>::value, TupleBase &>
        operator=(T &&t) {
            tuple_swallow(TupleLeaf<I, A>::operator=(forward<
                TupleElement<I, MakeTupleTypes<T>>
            >(get<I>(t)))...);
            return *this;
        }

        TupleBase(const TupleBase &) = default;
        TupleBase(TupleBase &&) = default;

        TupleBase &operator=(const TupleBase &t) {
            tuple_swallow(TupleLeaf<I, A>::operator=(((const TupleLeaf<I,
                A> &)t).get())...);
            return *this;
        }

        TupleBase &operator=(TupleBase &&t) {
            tuple_swallow(TupleLeaf<I, A>::operator=(forward<A>
                (((const TupleLeaf<I, A> &)t).get()))...);
            return *this;
        }

        void swap(TupleBase &t) {
            tuple_swallow(TupleLeaf<I, A>::swap((TupleLeaf<I, A> &)t)...);
        }
    };
} /* namespace detail */

template<typename ...A>
class Tuple {
    using Base = detail::TupleBase<detail::MakeTupleIndices<sizeof...(A)>, A...>;
    Base p_base;

    template<Size I, typename ...T>
    friend TupleElement<I, Tuple<T...>> &get(Tuple<T...> &);

    template<Size I, typename ...T>
    friend const TupleElement<I, Tuple<T...>> &get(const Tuple<T...> &);

    template<Size I, typename ...T>
    friend TupleElement<I, Tuple<T...>> &&get(Tuple<T...> &&);

public:
    template<bool D = true, typename = EnableIf<
        detail::TupleAll<(D && IsDefaultConstructible<A>::value)...>::value
    >> Tuple() {}

    explicit Tuple(const A &...t):
        p_base(detail::MakeTupleIndices<sizeof...(A)>(),
               detail::MakeTupleTypes<Tuple, sizeof...(A)>(),
               detail::MakeTupleIndices<0>(),
               detail::MakeTupleTypes<Tuple, 0>(), t...) {}

    template<typename Alloc>
    Tuple(AllocatorArg, const Alloc &a, const A &...t):
        p_base(allocator_arg, a,
            detail::MakeTupleIndices<sizeof...(A)>(),
            detail::MakeTupleTypes<Tuple, sizeof...(A)>(),
            detail::MakeTupleIndices<0>(),
            detail::MakeTupleTypes<Tuple, 0>(), t...) {}

    template<typename ...T, EnableIf<
        (sizeof...(T) <= sizeof...(A)) &&
        detail::TupleConvertible<
            Tuple<T...>,
            detail::MakeTupleTypes<Tuple,
                (sizeof...(T) < sizeof...(A)) ? sizeof...(T)
                                              : sizeof...(A)
            >
        >::value &&
        detail::TupleAllDefaultConstructible<
            detail::MakeTupleTypes<Tuple, sizeof...(A),
                (sizeof...(T) < sizeof...(A)) ? sizeof...(T)
                                              : sizeof...(A)
            >
        >::value, bool
    > = true>
    Tuple(T &&...t):
        p_base(detail::MakeTupleIndices<sizeof...(T)>(),
               detail::MakeTupleTypes<Tuple, sizeof...(T)>(),
               detail::MakeTupleIndices<sizeof...(A), sizeof...(T)>(),
               detail::MakeTupleTypes<Tuple, sizeof...(A), sizeof...(T)>(),
               forward<T>(t)...) {}

    template<typename ...T, EnableIf<
        (sizeof...(T) <= sizeof...(A)) &&
        detail::TupleConstructible<
            Tuple<T...>,
            detail::MakeTupleTypes<Tuple,
                (sizeof...(T) < sizeof...(A)) ? sizeof...(T)
                                              : sizeof...(A)
            >
        >::value &&
        !detail::TupleConvertible<
            Tuple<T...>,
            detail::MakeTupleTypes<Tuple,
                (sizeof...(T) < sizeof...(A)) ? sizeof...(T)
                                              : sizeof...(A)
            >
        >::value &&
        detail::TupleAllDefaultConstructible<
            detail::MakeTupleTypes<Tuple, sizeof...(A),
                (sizeof...(T) < sizeof...(A)) ? sizeof...(T)
                                              : sizeof...(A)
            >
        >::value, bool
    > = true>
    Tuple(T &&...t):
        p_base(detail::MakeTupleIndices<sizeof...(T)>(),
               detail::MakeTupleTypes<Tuple, sizeof...(T)>(),
               detail::MakeTupleIndices<sizeof...(A), sizeof...(T)>(),
               detail::MakeTupleTypes<Tuple, sizeof...(A), sizeof...(T)>(),
               forward<T>(t)...) {}

    template<typename Alloc, typename ...T, typename = EnableIf<
        (sizeof...(T) <= sizeof...(A)) &&
        detail::TupleConvertible<
            Tuple<T...>,
            detail::MakeTupleTypes<Tuple,
                (sizeof...(T) < sizeof...(A)) ? sizeof...(T)
                                              : sizeof...(A)
            >
        >::value &&
        detail::TupleAllDefaultConstructible<
            detail::MakeTupleTypes<Tuple, sizeof...(A),
                (sizeof...(T) < sizeof...(A)) ? sizeof...(T)
                                              : sizeof...(A)
            >
        >::value
    >> Tuple(AllocatorArg, const Alloc &a, T &&...t):
        p_base(allocator_arg, a, detail::MakeTupleIndices<sizeof...(T)>(),
               detail::MakeTupleTypes<Tuple, sizeof...(T)>(),
               detail::MakeTupleIndices<sizeof...(A), sizeof...(T)>(),
               detail::MakeTupleTypes<Tuple, sizeof...(A), sizeof...(T)>(),
               forward<T>(t)...) {}

    template<typename T, EnableIf<
        detail::TupleConvertible<T, Tuple>::value, bool
    > = true> Tuple(T &&t): p_base(forward<T>(t)) {}

    template<typename T, EnableIf<
        detail::TupleConstructible<T, Tuple>::value &&
        !detail::TupleConvertible<T, Tuple>::value, bool
    > = true> Tuple(T &&t): p_base(forward<T>(t)) {}

    template<typename Alloc, typename T, typename = EnableIf<
        detail::TupleConvertible<T, Tuple>::value
    >> Tuple(AllocatorArg, const Alloc &a, T &&t):
        p_base(allocator_arg, a, forward<T>(t)) {}

    template<typename T, typename = EnableIf<
        detail::TupleAssignable<T, Tuple>::value
    >> Tuple &operator=(T &&t) {
        p_base.operator=(forward<T>(t));
        return *this;
    }

    void swap(Tuple &t) {
        p_base.swap(t.p_base);
    }
};

template<> class Tuple<> {
public:
    constexpr Tuple() {}
    template<typename A> Tuple(AllocatorArg, const A &) {}
    template<typename A> Tuple(AllocatorArg, const A &, const Tuple &) {}
    void swap(Tuple &) {}
};

/* get */

template<Size I, typename ...A>
inline TupleElement<I, Tuple<A...>> &get(Tuple<A...> &t) {
    using Type = TupleElement<I, Tuple<A...>>;
    return ((detail::TupleLeaf<I, Type> &)t.p_base).get();
}

template<Size I, typename ...A>
inline const TupleElement<I, Tuple<A...>> &get(const Tuple<A...> &t) {
    using Type = TupleElement<I, Tuple<A...>>;
    return ((const detail::TupleLeaf<I, Type> &)t.p_base).get();
}

template<Size I, typename ...A>
inline TupleElement<I, Tuple<A...>> &&get(Tuple<A...> &&t) {
    using Type = TupleElement<I, Tuple<A...>>;
    return ((detail::TupleLeaf<I, Type> &&)t.p_base).get();
}

/* tie */

template<typename ...T>
inline Tuple<T &...> tie(T &...t) {
    return Tuple<T &...>(t...);
}

/* ignore */

namespace detail {
    struct Ignore {
        template<typename T>
        const Ignore &operator=(T &&) const { return *this; }
    };
}

static const detail::Ignore ignore = detail::Ignore();

/* make tuple */

namespace detail {
    template<typename T>
    struct MakeTupleReturnType {
        using Type = T;
    };

    template<typename T>
    struct MakeTupleReturnType<ReferenceWrapper<T>> {
        using Type = T &;
    };

    template<typename T>
    struct MakeTupleReturn {
        using Type = typename MakeTupleReturnType<Decay<T>>::Type;
    };
}

template<typename ...T>
inline Tuple<typename detail::MakeTupleReturn<T>::Type...>
make_tuple(T &&...t) {
    return Tuple<typename detail::MakeTupleReturn<T>::Type...>(forward<T>(t)...);
}

/* forward as tuple */

template<typename ...T>
inline Tuple<T &&...> forward_as_tuple(T &&...t) {
    return Tuple<T &&...>(forward<T>(t)...);
}

/* tuple relops */

namespace detail {
    template<Size I>
    struct TupleEqual {
        template<typename T, typename U>
        bool operator()(const T &x, const U &y) {
            return TupleEqual<I - 1>()(x, y) && (get<I>(x) == get<I>(y));
        }
    };

    template<>
    struct TupleEqual<0> {
        template<typename T, typename U>
        bool operator()(const T &, const U &) {
            return true;
        }
    };
}

template<typename ...T, typename ...U>
inline bool operator==(const Tuple<T...> &x, const Tuple<U...> &y) {
    return detail::TupleEqual<sizeof...(T)>(x, y);
}

template<typename ...T, typename ...U>
inline bool operator!=(const Tuple<T...> &x, const Tuple<U...> &y) {
    return !(x == y);
}

namespace detail {
    template<Size I>
    struct TupleLess {
        template<typename T, typename U>
        bool operator()(const T &x, const U &y) {
            Size J = TupleSize<T>::value - I;
            if (get<J>(x) < get<J>(y)) return true;
            if (get<J>(y) < get<J>(x)) return false;
            return TupleLess<I - 1>()(x, y);
        }
    };

    template<>
    struct TupleLess<0> {
        template<typename T, typename U>
        bool operator()(const T &, const U &) {
            return true;
        }
    };
}

template<typename ...T, typename ...U>
inline bool operator<(const Tuple<T...> &x, const Tuple<U...> &y) {
    return detail::TupleLess<sizeof...(T)>(x, y);
}

template<typename ...T, typename ...U>
inline bool operator>(const Tuple<T...> &x, const Tuple<U...> &y) {
    return y < x;
}

template<typename ...T, typename ...U>
inline bool operator<=(const Tuple<T...> &x, const Tuple<U...> &y) {
    return !(y < x);
}

template<typename ...T, typename ...U>
inline bool operator>=(const Tuple<T...> &x, const Tuple<U...> &y) {
    return !(x < y);
}

/* uses alloc */

template<typename ...T, typename A>
struct UsesAllocator<Tuple<T...>, A>: True {};

} /* namespace octa */

#endif
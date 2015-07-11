/* Some tuple internals for inclusion from various headers. Partially
 * taken from the libc++ project.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_INTERNAL_TUPLE_HH
#define OCTA_INTERNAL_TUPLE_HH

#include "octa/types.hh"
#include "octa/type_traits.hh"

namespace octa {

template<typename ...A> class Tuple;
template<typename T, typename U> struct Pair;
template<typename T, Size I> struct Array;

/* tuple size */

template<typename T> struct TupleSize;

template<typename T> struct TupleSize<const T>: public TupleSize<T> {};
template<typename T> struct TupleSize<volatile T>: public TupleSize<T> {};
template<typename T> struct TupleSize<const volatile T>: public TupleSize<T> {};

/* tuple element */

template<Size I, typename T> struct TupleElementBase;
template<Size I, typename T>
struct TupleElementBase<I, const T> {
    using Type = AddConst<typename TupleElementBase<I, T>::Type>;
};
template<Size I, typename T>
struct TupleElementBase<I, volatile T> {
    using Type = AddVolatile<typename TupleElementBase<I, T>::Type>;
};
template<Size I, typename T>
struct TupleElementBase<I, const volatile T> {
    using Type = AddCv<typename TupleElementBase<I, T>::Type>;
};

template<Size I, typename T>
using TupleElement = typename TupleElementBase<I, T>::Type;

/* is tuple-like */

template<typename T> struct IsTupleLike: False {};
template<typename T> struct IsTupleLike<const T>: IsTupleLike<T> {};
template<typename T> struct IsTupleLike<volatile T>: IsTupleLike<T> {};
template<typename T> struct IsTupleLike<const volatile T>: IsTupleLike<T> {};

/* tuple specializations */

template<typename ...A> struct IsTupleLike<Tuple<A...>>: True {};

template<Size I, typename ...A>
TupleElement<I, Tuple<A...>> &get(Tuple<A...> &);

template<Size I, typename ...A>
const TupleElement<I, Tuple<A...>> &get(const Tuple<A...> &);

template<Size I, typename ...A>
TupleElement<I, Tuple<A...>> &&get(Tuple<A...> &&);

/* pair specializations */

template<typename T, typename U> struct IsTupleLike<Pair<T, U>>: True {};

template<Size I, typename T, typename U>
TupleElement<I, Pair<T, U>> &get(Pair<T, U> &);

template<Size I, typename T, typename U>
const TupleElement<I, Pair<T, U>> &get(const Pair<T, U> &);

template<Size I, typename T, typename U>
TupleElement<I, Pair<T, U>> &&get(Pair<T, U> &&);

/* array specializations */

template<typename T, Size I> struct IsTupleLike<Array<T, I>>: True {};

template<Size I, typename T, Size S>
T &get(Array<T, S> &);

template<Size I, typename T, Size S>
const T &get(const Array<T, S> &);

template<Size I, typename T, Size S>
T &&get(Array<T, S> &&);

/* make tuple indices */

namespace detail {
    template<Size ...> struct TupleIndices {};

    template<Size S, typename T, Size E> struct MakeTupleIndicesBase;

    template<Size S, Size ...I, Size E>
    struct MakeTupleIndicesBase<S, TupleIndices<I...>, E> {
        using Type = typename MakeTupleIndicesBase<S + 1,
            TupleIndices<I..., S>, E>::Type;
    };

    template<Size E, Size ...I>
    struct MakeTupleIndicesBase<E, TupleIndices<I...>, E> {
        using Type = TupleIndices<I...>;
    };

    template<Size E, Size S>
    struct MakeTupleIndicesImpl {
        static_assert(S <= E, "MakeTupleIndices input error");
        using Type = typename MakeTupleIndicesBase<S, TupleIndices<>, E>::Type;
    };

    template<Size E, Size S = 0>
    using MakeTupleIndices = typename MakeTupleIndicesImpl<E, S>::Type;
}

/* tuple types */

namespace detail {
    template<typename ...T> struct TupleTypes {};
}

template<Size I> struct TupleElementBase<I, detail::TupleTypes<>> {
public:
    static_assert(I == 0, "TupleElement index out of range");
    static_assert(I != 0, "TupleElement index out of range");
};

template<typename H, typename ...T>
struct TupleElementBase<0, detail::TupleTypes<H, T...>> {
public:
    using Type = H;
};

template<Size I, typename H, typename ...T>
struct TupleElementBase<I, detail::TupleTypes<H, T...>> {
public:
    using Type = typename TupleElementBase<I - 1,
        detail::TupleTypes<T...>>::Type;
};

template<typename ...T> struct TupleSize<detail::TupleTypes<T...>>:
    IntegralConstant<Size, sizeof...(T)> {};

template<typename ...T> struct IsTupleLike<detail::TupleTypes<T...>>: True {};

/* make tuple types */

namespace detail {
    template<typename TT, typename T, Size S, Size E>
    struct MakeTupleTypesBase;

    template<typename ...TS, typename T, Size S, Size E>
    struct MakeTupleTypesBase<TupleTypes<TS...>, T, S, E> {
        using TR = RemoveReference<T>;
        using Type = typename MakeTupleTypesBase<TupleTypes<TS...,
            Conditional<IsLvalueReference<T>::value,
                TupleElement<S, TR> &,
                TupleElement<S, TR>>>, T, S + 1, E>::Type;
    };

    template<typename ...TS, typename T, Size E>
    struct MakeTupleTypesBase<TupleTypes<TS...>, T, E, E> {
        using Type = TupleTypes<TS...>;
    };

    template<typename T, Size E, Size S>
    struct MakeTupleTypesImpl {
        static_assert(S <= E, "MakeTupleTypes input error");
        using Type = typename MakeTupleTypesBase<TupleTypes<>, T, S, E>::Type;
    };

    template<typename T, Size E = TupleSize<RemoveReference<T>>::value, Size S = 0>
    using MakeTupleTypes = typename MakeTupleTypesImpl<T, E, S>::Type;
}

/* tuple convertible */

namespace detail {
    template<typename, typename>
    struct TupleConvertibleBase: False {};

    template<typename T, typename ...TT, typename U, typename ...UU>
    struct TupleConvertibleBase<TupleTypes<T, TT...>, TupleTypes<U, UU...>>:
        IntegralConstant<bool, IsConvertible<T, U>::value &&
                               TupleConvertibleBase<TupleTypes<TT...>,
                                                    TupleTypes<UU...>>::value> {};

    template<>
    struct TupleConvertibleBase<TupleTypes<>, TupleTypes<>>: True {};

    template<bool, typename, typename>
    struct TupleConvertibleApply: False {};

    template<typename T, typename U>
    struct TupleConvertibleApply<true, T, U>: TupleConvertibleBase<
        MakeTupleTypes<T>, MakeTupleTypes<U>
    > {};

    template<typename T, typename U, bool = IsTupleLike<RemoveReference<T>>::value,
                                     bool = IsTupleLike<U>::value>
    struct TupleConvertible: False {};

    template<typename T, typename U>
    struct TupleConvertible<T, U, true, true>: TupleConvertibleApply<
        TupleSize<RemoveReference<T>>::value == TupleSize<U>::value, T, U
    > {};
}

/* tuple constructible */

namespace detail {
    template<typename, typename>
    struct TupleConstructibleBase: False {};

    template<typename T, typename ...TT, typename U, typename ...UU>
    struct TupleConstructibleBase<TupleTypes<T, TT...>, TupleTypes<U, UU...>>:
        IntegralConstant<bool, IsConstructible<U, T>::value &&
                               TupleConstructibleBase<TupleTypes<TT...>,
                                                      TupleTypes<UU...>>::value> {};

    template<>
    struct TupleConstructibleBase<TupleTypes<>, TupleTypes<>>: True {};

    template<bool, typename, typename>
    struct TupleConstructibleApply: False {};

    template<typename T, typename U>
    struct TupleConstructibleApply<true, T, U>: TupleConstructibleBase<
        MakeTupleTypes<T>, MakeTupleTypes<U>
    > {};

    template<typename T, typename U, bool = IsTupleLike<RemoveReference<T>>::value,
                                     bool = IsTupleLike<U>::value>
    struct TupleConstructible: False {};

    template<typename T, typename U>
    struct TupleConstructible<T, U, true, true>: TupleConstructibleApply<
        TupleSize<RemoveReference<T>>::value == TupleSize<U>::value, T, U
    > {};
}

/* tuple assignable */

namespace detail {
    template<typename, typename>
    struct TupleAssignableBase: False {};

    template<typename T, typename ...TT, typename U, typename ...UU>
    struct TupleAssignableBase<TupleTypes<T, TT...>, TupleTypes<U, UU...>>:
        IntegralConstant<bool, IsAssignable<U &, T>::value &&
                               TupleAssignableBase<TupleTypes<TT...>,
                                                   TupleTypes<UU...>>::value> {};

    template<>
    struct TupleAssignableBase<TupleTypes<>, TupleTypes<>>: True {};

    template<bool, typename, typename>
    struct TupleAssignableApply: False {};

    template<typename T, typename U>
    struct TupleAssignableApply<true, T, U>: TupleAssignableBase<
        MakeTupleTypes<T>, MakeTupleTypes<U>
    > {};

    template<typename T, typename U, bool = IsTupleLike<RemoveReference<T>>::value,
                                     bool = IsTupleLike<U>::value>
    struct TupleAssignable: False {};

    template<typename T, typename U>
    struct TupleAssignable<T, U, true, true>: TupleAssignableApply<
        TupleSize<RemoveReference<T>>::value == TupleSize<U>::value, T, U
    > {};
}

} /* namespace octa */

#endif
/* Type traits for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_TYPE_TRAITS_HH
#define OCTA_TYPE_TRAITS_HH

#include <stddef.h>

#include "octa/types.hh"

namespace octa {
/* forward declarations */

namespace detail {
    template<typename> struct RemoveCvBase;
    template<typename> struct AddLr;
    template<typename> struct AddRr;
    template<typename> struct AddConstBase;
    template<typename> struct RemoveReferenceBase;
    template<typename> struct RemoveAllExtentsBase;

    template<typename ...> struct CommonTypeBase;
}

template<typename> struct IsReference;
template<typename> struct IsTriviallyDefaultConstructible;

template<typename T>
using RemoveCv = typename detail::RemoveCvBase<T>::Type;

template<typename T>
using AddLvalueReference = typename detail::AddLr<T>::Type;

template<typename T>
using AddRvalueReference = typename detail::AddRr<T>::Type;

template<typename T>
using AddConst = typename detail::AddConstBase<T>::Type;

template<typename T>
using RemoveReference = typename detail::RemoveReferenceBase<T>::Type;

template<typename T>
using RemoveAllExtents = typename detail::RemoveAllExtentsBase<T>::Type;

namespace detail {
    template<typename T> AddRvalueReference<T> declval_in();
}

/* integral constant */

template<typename T, T val>
struct IntegralConstant {
    static constexpr T value = val;

    using Value = T;
    using Type = IntegralConstant<T, val>;

    constexpr operator Value() const { return value; }
    constexpr Value operator()() const { return value; }
};

using True = IntegralConstant<bool, true>;
using False = IntegralConstant<bool, false>;

template<typename T, T val> constexpr T IntegralConstant<T, val>::value;

/* and */

namespace detail {
    template<bool B, typename ...A> struct AndBase;

    template<typename ...A>
    struct AndBase<false, A...>: False {};

    template<>
    struct AndBase<true>: True {};

    template<typename T>
    struct AndBase<true, T>: IntegralConstant<bool, T::Type::value> {};

    template<typename T, typename ...A>
    struct AndBase<true, T, A...>: AndBase<T::Type::value, A...> {};
}

template<typename T, typename ...A>
struct And: detail::AndBase<T::Type::value, A...> {};

/* or */

namespace detail {
    template<bool B, typename ...A> struct OrBase;

    template<>
    struct OrBase<false>: False {};

    template<typename T, typename ...A>
    struct OrBase<false, T, A...>: OrBase<T::Type::value, A...> {};

    template<typename ...A>
    struct OrBase<true, A...>: True {};
}

template<typename T, typename ...A>
struct Or: detail::OrBase<T::Type::value, A...> {};

/* not */

template<typename T>
struct Not: IntegralConstant<bool, !T::Type::value> {};

/* is void */

namespace detail {
    template<typename T> struct IsVoidBase      : False {};
    template<          > struct IsVoidBase<void>:  True {};
}

    template<typename T>
    struct IsVoid: detail::IsVoidBase<RemoveCv<T>> {};

/* is null pointer */

namespace detail {
    template<typename> struct IsNullPointerBase         : False {};
    template<        > struct IsNullPointerBase<Nullptr>:  True {};
}

template<typename T> struct IsNullPointer:
    detail::IsNullPointerBase<RemoveCv<T>> {};

/* is integer */

namespace detail {
    template<typename T> struct IsIntegralBase: False {};

    template<> struct IsIntegralBase<bool  >: True {};
    template<> struct IsIntegralBase<char  >: True {};
    template<> struct IsIntegralBase<short >: True {};
    template<> struct IsIntegralBase<int   >: True {};
    template<> struct IsIntegralBase<long  >: True {};

    template<> struct IsIntegralBase<sbyte >: True {};
    template<> struct IsIntegralBase<byte  >: True {};
    template<> struct IsIntegralBase<ushort>: True {};
    template<> struct IsIntegralBase<uint  >: True {};
    template<> struct IsIntegralBase<ulong >: True {};
    template<> struct IsIntegralBase<llong >: True {};
    template<> struct IsIntegralBase<ullong>: True {};

    template<> struct IsIntegralBase<Char16>: True {};
    template<> struct IsIntegralBase<Char32>: True {};
    template<> struct IsIntegralBase<Wchar >: True {};
}

template<typename T>
struct IsIntegral: detail::IsIntegralBase<RemoveCv<T>> {};

/* is floating point */

namespace detail {
    template<typename T> struct IsFloatingPointBase: False {};

    template<> struct IsFloatingPointBase<float >: True {};
    template<> struct IsFloatingPointBase<double>: True {};

    template<> struct IsFloatingPointBase<ldouble>: True {};
}

template<typename T>
struct IsFloatingPoint: detail::IsFloatingPointBase<RemoveCv<T>> {};

/* is array */

template<typename          > struct IsArray      : False {};
template<typename T        > struct IsArray<T[] >:  True {};
template<typename T, Size N> struct IsArray<T[N]>:  True {};

/* is pointer */

namespace detail {
    template<typename  > struct IsPointerBase     : False {};
    template<typename T> struct IsPointerBase<T *>:  True {};
}

template<typename T>
struct IsPointer: detail::IsPointerBase<RemoveCv<T>> {};

/* is lvalue reference */

template<typename  > struct IsLvalueReference     : False {};
template<typename T> struct IsLvalueReference<T &>:  True {};

/* is rvalue reference */

template<typename  > struct IsRvalueReference      : False {};
template<typename T> struct IsRvalueReference<T &&>:  True {};

/* is enum */

template<typename T> struct IsEnum: IntegralConstant<bool, __is_enum(T)> {};

/* is union */

template<typename T> struct IsUnion: IntegralConstant<bool, __is_union(T)> {};

/* is class */

template<typename T> struct IsClass: IntegralConstant<bool, __is_class(T)> {};

/* is function */

namespace detail {
    struct FunctionTestDummy {};

    template<typename T> char function_test(T *);
    template<typename T> char function_test(FunctionTestDummy);
    template<typename T> int  function_test(...);

    template<typename T> T                 &function_source(int);
    template<typename T> FunctionTestDummy  function_source(...);

    template<typename T, bool = IsClass<T>::value ||
                                IsUnion<T>::value ||
                                IsVoid<T>::value ||
                                IsReference<T>::value ||
                                IsNullPointer<T>::value
    > struct IsFunctionBase: IntegralConstant<bool,
        sizeof(function_test<T>(function_source<T>(0))) == 1
    > {};

    template<typename T> struct IsFunctionBase<T, true>: False {};
} /* namespace detail */

template<typename T> struct IsFunction: detail::IsFunctionBase<T> {};

/* is arithmetic */

template<typename T> struct IsArithmetic: IntegralConstant<bool,
    (IsIntegral<T>::value || IsFloatingPoint<T>::value)
> {};

/* is fundamental */

template<typename T> struct IsFundamental: IntegralConstant<bool,
    (IsArithmetic<T>::value || IsVoid<T>::value || IsNullPointer<T>::value)
> {};

/* is compound */

template<typename T> struct IsCompound: IntegralConstant<bool,
    !IsFundamental<T>::value
> {};

/* is pointer to member */

namespace detail {
    template<typename>
    struct IsMemberPointerBase: False {};

    template<typename T, typename U>
    struct IsMemberPointerBase<T U::*>: True {};
}

template<typename T>
struct IsMemberPointer: detail::IsMemberPointerBase<RemoveCv<T>> {};

/* is pointer to member object */

namespace detail {
    template<typename>
    struct IsMemberObjectPointerBase: False {};

    template<typename T, typename U>
    struct IsMemberObjectPointerBase<T U::*>: IntegralConstant<bool,
        !IsFunction<T>::value
    > {};
}

template<typename T> struct IsMemberObjectPointer:
    detail::IsMemberObjectPointerBase<RemoveCv<T>> {};

/* is pointer to member function */

namespace detail {
    template<typename>
    struct IsMemberFunctionPointerBase: False {};

    template<typename T, typename U>
    struct IsMemberFunctionPointerBase<T U::*>: IntegralConstant<bool,
        IsFunction<T>::value
    > {};
}

template<typename T> struct IsMemberFunctionPointer:
    detail::IsMemberFunctionPointerBase<RemoveCv<T>> {};

/* is reference */

template<typename T> struct IsReference: IntegralConstant<bool,
    (IsLvalueReference<T>::value || IsRvalueReference<T>::value)
> {};

/* is object */

template<typename T> struct IsObject: IntegralConstant<bool,
    (!IsFunction<T>::value && !IsVoid<T>::value && !IsReference<T>::value)
> {};

/* is scalar */

template<typename T> struct IsScalar: IntegralConstant<bool,
    (IsMemberPointer<T>::value || IsPointer<T>::value || IsEnum<T>::value
  || IsNullPointer  <T>::value || IsArithmetic<T>::value)
> {};

/* is abstract */

template<typename T>
struct IsAbstract: IntegralConstant<bool, __is_abstract(T)> {};

/* is const */

template<typename  > struct IsConst         : False {};
template<typename T> struct IsConst<const T>:  True {};

/* is volatile */

template<typename  > struct IsVolatile            : False {};
template<typename T> struct IsVolatile<volatile T>:  True {};

/* is empty */

template<typename T>
struct IsEmpty: IntegralConstant<bool, __is_empty(T)> {};

/* is POD */

template<typename T> struct IsPod: IntegralConstant<bool, __is_pod(T)> {};

/* is polymorphic */

template<typename T>
struct IsPolymorphic: IntegralConstant<bool, __is_polymorphic(T)> {};

/* is signed */

namespace detail {
    template<typename T>
    struct IsSignedBase: IntegralConstant<bool, T(-1) < T(0)> {};
}

template<typename T, bool = IsArithmetic<T>::value>
struct IsSigned: False {};

template<typename T>
struct IsSigned<T, true>: detail::IsSignedBase<T> {};

/* is unsigned */

namespace detail {
    template<typename T>
    struct IsUnsignedBase: IntegralConstant<bool, T(0) < T(-1)> {};
}

template<typename T, bool = IsArithmetic<T>::value>
struct IsUnsigned: False {};

template<typename T>
struct IsUnsigned<T, true>: detail::IsUnsignedBase<T> {};

/* is standard layout */

template<typename T>
struct IsStandardLayout: IntegralConstant<bool, __is_standard_layout(T)> {};

/* is literal type */

template<typename T>
struct IsLiteralType: IntegralConstant<bool, __is_literal_type(T)> {};

/* is trivially copyable */

template<typename T>
struct IsTriviallyCopyable: IntegralConstant<bool,
    IsScalar<RemoveAllExtents<T>>::value
> {};

/* is trivial */

template<typename T>
struct IsTrivial: IntegralConstant<bool, __is_trivial(T)> {};

/* has virtual destructor */

template<typename T>
struct HasVirtualDestructor: IntegralConstant<bool,
    __has_virtual_destructor(T)
> {};

/* is constructible */

namespace detail {
#define OCTA_MOVE(v) static_cast<RemoveReference<decltype(v)> &&>(v)

    template<typename, typename T> struct Select2nd { using Type = T; };
    struct Any { Any(...); };

    template<typename T, typename ...A> typename Select2nd<
        decltype(OCTA_MOVE(T(declval_in<A>()...))), True
    >::Type is_ctible_test(T &&, A &&...);

#undef OCTA_MOVE

    template<typename ...A> False is_ctible_test(Any, A &&...);

    template<bool, typename T, typename ...A>
    struct CtibleCore: CommonTypeBase<
        decltype(is_ctible_test(declval_in<T>(), declval_in<A>()...))
    >::Type {};

    /* function types are not constructible */
    template<typename R, typename ...A1, typename ...A2>
    struct CtibleCore<false, R(A1...), A2...>: False {};

    /* scalars are default constructible, refs are not */
    template<typename T>
    struct CtibleCore<true, T>: IsScalar<T> {};

    /* scalars and references are constructible from one arg if
     * implicitly convertible to scalar or reference */
    template<typename T>
    struct CtibleRef {
        static True  test(T);
        static False test(...);
    };

    template<typename T, typename U>
    struct CtibleCore<true, T, U>: CommonTypeBase<
        decltype(CtibleRef<T>::test(declval_in<U>()))
    >::Type {};

    /* scalars and references are not constructible from multiple args */
    template<typename T, typename U, typename ...A>
    struct CtibleCore<true, T, U, A...>: False {};

    /* treat scalars and refs separately */
    template<bool, typename T, typename ...A>
    struct CtibleVoidCheck: CtibleCore<
        (IsScalar<T>::value || IsReference<T>::value), T, A...
    > {};

    /* if any of T or A is void, IsConstructible should be false */
    template<typename T, typename ...A>
    struct CtibleVoidCheck<true, T, A...>: False {};

    template<typename ...A> struct CtibleContainsVoid;

    template<> struct CtibleContainsVoid<>: False {};

    template<typename T, typename ...A>
    struct CtibleContainsVoid<T, A...> {
        static constexpr bool value = IsVoid<T>::value
           || CtibleContainsVoid<A...>::value;
    };

    /* entry point */
    template<typename T, typename ...A>
    struct Ctible: CtibleVoidCheck<
        CtibleContainsVoid<T, A...>::value || IsAbstract<T>::value,
        T, A...
    > {};

    /* array types are default constructible if their element type is */
    template<typename T, Size N>
    struct CtibleCore<false, T[N]>: Ctible<RemoveAllExtents<T>> {};

    /* otherwise array types are not constructible by this syntax */
    template<typename T, Size N, typename ...A>
    struct CtibleCore<false, T[N], A...>: False {};

    /* incomplete array types are not constructible */
    template<typename T, typename ...A>
    struct CtibleCore<false, T[], A...>: False {};
} /* namespace detail */

template<typename T, typename ...A>
struct IsConstructible: detail::Ctible<T, A...> {};

/* is default constructible */

template<typename T> struct IsDefaultConstructible: IsConstructible<T> {};

/* is copy constructible */

template<typename T> struct IsCopyConstructible: IsConstructible<T,
    AddLvalueReference<AddConst<T>>
> {};

/* is move constructible */

template<typename T> struct IsMoveConstructible: IsConstructible<T,
    AddRvalueReference<T>
> {};

/* is assignable */

namespace detail {
    template<typename T, typename U> typename detail::Select2nd<
        decltype((declval_in<T>() = declval_in<U>())), True
    >::Type assign_test(T &&, U &&);

    template<typename T> False assign_test(Any, T &&);

    template<typename T, typename U, bool = IsVoid<T>::value ||
                                            IsVoid<U>::value
    > struct IsAssignableBase: CommonTypeBase<
        decltype(assign_test(declval_in<T>(), declval_in<U>()))
    >::Type {};

    template<typename T, typename U>
    struct IsAssignableBase<T, U, true>: False {};
} /* namespace detail */

template<typename T, typename U>
struct IsAssignable: detail::IsAssignableBase<T, U> {};

/* is copy assignable */

template<typename T> struct IsCopyAssignable: IsAssignable<
    AddLvalueReference<T>,
    AddLvalueReference<AddConst<T>>
> {};

/* is move assignable */

template<typename T> struct IsMoveAssignable: IsAssignable<
    AddLvalueReference<T>,
    const AddRvalueReference<T>
> {};

/* is destructible */

namespace detail {
    template<typename> struct IsDtibleApply { using Type = int; };

    template<typename T> struct IsDestructorWellformed {
        template<typename TT> static char test(typename IsDtibleApply<
            decltype(detail::declval_in<TT &>().~TT())
        >::Type);

        template<typename TT> static int test(...);

        static constexpr bool value = (sizeof(test<T>(12)) == sizeof(char));
    };

    template<typename, bool> struct DtibleImpl;

    template<typename T>
    struct DtibleImpl<T, false>: IntegralConstant<bool,
        IsDestructorWellformed<RemoveAllExtents<T>>::value
    > {};

    template<typename T>
    struct DtibleImpl<T, true>: True {};

    template<typename T, bool> struct DtibleFalse;

    template<typename T> struct DtibleFalse<T, false>
        : DtibleImpl<T, IsReference<T>::value> {};

    template<typename T> struct DtibleFalse<T, true>: False {};
} /* namespace detail */

template<typename T>
struct IsDestructible: detail::DtibleFalse<T, IsFunction<T>::value> {};

template<typename T> struct IsDestructible<T[]>: False {};
template<           > struct IsDestructible<void>: False {};

/* is trivially constructible */

template<typename T, typename ...A>
struct IsTriviallyConstructible: False {};

template<typename T>
struct IsTriviallyConstructible<T>: IntegralConstant<bool,
    __has_trivial_constructor(T)
> {};

template<typename T>
struct IsTriviallyConstructible<T, T &>: IntegralConstant<bool,
    __has_trivial_copy(T)
> {};

template<typename T>
struct IsTriviallyConstructible<T, const T &>: IntegralConstant<bool,
    __has_trivial_copy(T)
> {};

template<typename T>
struct IsTriviallyConstructible<T, T &&>: IntegralConstant<bool,
    __has_trivial_copy(T)
> {};

/* is trivially default constructible */

template<typename T>
struct IsTriviallyDefaultConstructible: IsTriviallyConstructible<T> {};

/* is trivially copy constructible */

template<typename T>
struct IsTriviallyCopyConstructible: IsTriviallyConstructible<T,
    AddLvalueReference<const T>
> {};

/* is trivially move constructible */

template<typename T>
struct IsTriviallyMoveConstructible: IsTriviallyConstructible<T,
    AddRvalueReference<T>
> {};

/* is trivially assignable */

template<typename T, typename ...A>
struct IsTriviallyAssignable: False {};

template<typename T>
struct IsTriviallyAssignable<T>: IntegralConstant<bool,
    __has_trivial_assign(T)
> {};

template<typename T>
struct IsTriviallyAssignable<T, T &>: IntegralConstant<bool,
    __has_trivial_copy(T)
> {};

template<typename T>
struct IsTriviallyAssignable<T, const T &>: IntegralConstant<bool,
    __has_trivial_copy(T)
> {};

template<typename T>
struct IsTriviallyAssignable<T, T &&>: IntegralConstant<bool,
    __has_trivial_copy(T)
> {};

/* is trivially copy assignable */

template<typename T>
struct IsTriviallyCopyAssignable: IsTriviallyAssignable<T,
    AddLvalueReference<const T>
> {};

/* is trivially move assignable */

template<typename T>
struct IsTriviallyMoveAssignable: IsTriviallyAssignable<T,
    AddRvalueReference<T>
> {};

/* is trivially destructible */

template<typename T>
struct IsTriviallyDestructible: IntegralConstant<bool,
    __has_trivial_destructor(T)
> {};

/* is base of */

template<typename B, typename D>
struct IsBaseOf: IntegralConstant<bool, __is_base_of(B, D)> {};

/* is convertible */

namespace detail {
    template<typename F, typename T, bool = IsVoid<F>::value
        || IsFunction<T>::value || IsArray<T>::value
    > struct IsConvertibleBase {
        using Type = typename IsVoid<T>::Type;
    };

    template<typename F, typename T>
    struct IsConvertibleBase<F, T, false> {
        template<typename TT> static void test_f(TT);

        template<typename FF, typename TT,
            typename = decltype(test_f<TT>(declval_in<FF>()))
        > static True test(int);

        template<typename, typename> static False test(...);

        using Type = decltype(test<F, T>(0));
    };
}

template<typename F, typename T>
struct IsConvertible: detail::IsConvertibleBase<F, T>::Type {};

/* type equality */

template<typename, typename> struct IsSame      : False {};
template<typename T        > struct IsSame<T, T>:  True {};

/* extent */

template<typename T, uint I = 0>
struct Extent: IntegralConstant<Size, 0> {};

template<typename T>
struct Extent<T[], 0>: IntegralConstant<Size, 0> {};

template<typename T, uint I>
struct Extent<T[], I>: IntegralConstant<Size, Extent<T, I - 1>::value> {};

template<typename T, Size N>
struct Extent<T[N], 0>: IntegralConstant<Size, N> {};

template<typename T, Size N, uint I>
struct Extent<T[N], I>: IntegralConstant<Size, Extent<T, I - 1>::value> {};

/* rank */

template<typename T> struct Rank: IntegralConstant<Size, 0> {};

template<typename T>
struct Rank<T[]>: IntegralConstant<Size, Rank<T>::value + 1> {};

template<typename T, Size N>
struct Rank<T[N]>: IntegralConstant<Size, Rank<T>::value + 1> {};

/* remove const, volatile, cv */

namespace detail {
    template<typename T>
    struct RemoveConstBase          { using Type = T; };
    template<typename T>
    struct RemoveConstBase<const T> { using Type = T; };

    template<typename T>
    struct RemoveVolatileBase             { using Type = T; };
    template<typename T>
    struct RemoveVolatileBase<volatile T> { using Type = T; };
}

template<typename T>
using RemoveConst = typename detail::RemoveConstBase<T>::Type;
template<typename T>
using RemoveVolatile = typename detail::RemoveVolatileBase<T>::Type;

namespace detail {
    template<typename T>
    struct RemoveCvBase {
        using Type = RemoveVolatile<RemoveConst<T>>;
    };
}

/* add const, volatile, cv */

namespace detail {
    template<typename T, bool = IsReference<T>::value
         || IsFunction<T>::value || IsConst<T>::value>
    struct AddConstCore { using Type = T; };

    template<typename T> struct AddConstCore<T, false> {
        using Type = const T;
    };

    template<typename T> struct AddConstBase {
        using Type = typename AddConstCore<T>::Type;
    };

    template<typename T, bool = IsReference<T>::value
         || IsFunction<T>::value || IsVolatile<T>::value>
    struct AddVolatileCore { using Type = T; };

    template<typename T> struct AddVolatileCore<T, false> {
        using Type = volatile T;
    };

    template<typename T> struct AddVolatileBase {
        using Type = typename AddVolatileCore<T>::Type;
    };
}

template<typename T>
using AddVolatile = typename detail::AddVolatileBase<T>::Type;

namespace detail {
    template<typename T>
    struct AddCvBase {
        using Type = AddConst<AddVolatile<T>>;
    };
}

template<typename T>
using AddCv = typename detail::AddCvBase<T>::Type;

/* remove reference */

namespace detail {
    template<typename T>
    struct RemoveReferenceBase       { using Type = T; };
    template<typename T>
    struct RemoveReferenceBase<T &>  { using Type = T; };
    template<typename T>
    struct RemoveReferenceBase<T &&> { using Type = T; };
}

/* remove pointer */

namespace detail {
    template<typename T>
    struct RemovePointerBase                     { using Type = T; };
    template<typename T>
    struct RemovePointerBase<T *               > { using Type = T; };
    template<typename T>
    struct RemovePointerBase<T * const         > { using Type = T; };
    template<typename T>
    struct RemovePointerBase<T * volatile      > { using Type = T; };
    template<typename T>
    struct RemovePointerBase<T * const volatile> { using Type = T; };
}

template<typename T>
using RemovePointer = typename detail::RemovePointerBase<T>::Type;

/* add pointer */

namespace detail {
    template<typename T> struct AddPointerBase {
        using Type = RemoveReference<T> *;
    };
}

template<typename T>
using AddPointer = typename detail::AddPointerBase<T>::Type;

/* add lvalue reference */

namespace detail {
    template<typename T> struct AddLr      { using Type = T &; };
    template<typename T> struct AddLr<T &> { using Type = T &; };
    template<> struct AddLr<void> {
        using Type = void;
    };
    template<> struct AddLr<const void> {
        using Type = const void;
    };
    template<> struct AddLr<volatile void> {
        using Type = volatile void;
    };
    template<> struct AddLr<const volatile void> {
        using Type = const volatile void;
    };
}

/* add rvalue reference */

namespace detail {
    template<typename T> struct AddRr { using Type = T &&; };
    template<> struct AddRr<void> {
        using Type = void;
    };
    template<> struct AddRr<const void> {
        using Type = const void;
    };
    template<> struct AddRr<volatile void> {
        using Type = volatile void;
    };
    template<> struct AddRr<const volatile void> {
        using Type = const volatile void;
    };
}

/* remove extent */

namespace detail {
    template<typename T>
    struct RemoveExtentBase       { using Type = T; };
    template<typename T>
    struct RemoveExtentBase<T[ ]> { using Type = T; };
    template<typename T, Size N>
    struct RemoveExtentBase<T[N]> { using Type = T; };
}

template<typename T>
using RemoveExtent = typename detail::RemoveExtentBase<T>::Type;

/* remove all extents */

namespace detail {
    template<typename T> struct RemoveAllExtentsBase { using Type = T; };

    template<typename T> struct RemoveAllExtentsBase<T[]> {
        using Type = RemoveAllExtentsBase<T>;
    };

    template<typename T, Size N> struct RemoveAllExtentsBase<T[N]> {
        using Type = RemoveAllExtentsBase<T>;
    };
}

/* make (un)signed
 *
 * this is bad, but i don't see any better way
 * shamelessly copied from graphitemaster @ neothyne
 */

namespace detail {
    template<typename T, typename U> struct TypeList {
        using First = T;
        using Rest = U;
    };

    /* not a type */
    struct TlNat {
        TlNat() = delete;
        TlNat(const TlNat &) = delete;
        TlNat &operator=(const TlNat &) = delete;
        ~TlNat() = delete;
    };

    using Stypes = TypeList<sbyte,
                   TypeList<short,
                   TypeList<int,
                   TypeList<long,
                   TypeList<llong, TlNat>>>>>;

    using Utypes = TypeList<byte,
                   TypeList<ushort,
                   TypeList<uint,
                   TypeList<ulong,
                   TypeList<ullong, TlNat>>>>>;

    template<typename T, Size N, bool = (N <= sizeof(typename T::First))>
    struct TypeFindFirst;

    template<typename T, typename U, Size N>
    struct TypeFindFirst<TypeList<T, U>, N, true> {
        using Type = T;
    };

    template<typename T, typename U, Size N>
    struct TypeFindFirst<TypeList<T, U>, N, false> {
        using Type = typename TypeFindFirst<U, N>::Type;
    };

    template<typename T, typename U,
        bool = IsConst<RemoveReference<T>>::value,
        bool = IsVolatile<RemoveReference<T>>::value
    > struct ApplyCv {
        using Type = U;
    };

    template<typename T, typename U>
    struct ApplyCv<T, U, true, false> { /* const */
        using Type = const U;
    };

    template<typename T, typename U>
    struct ApplyCv<T, U, false, true> { /* volatile */
        using Type = volatile U;
    };

    template<typename T, typename U>
    struct ApplyCv<T, U, true, true> { /* const volatile */
        using Type = const volatile U;
    };

    template<typename T, typename U>
    struct ApplyCv<T &, U, true, false> { /* const */
        using Type = const U &;
    };

    template<typename T, typename U>
    struct ApplyCv<T &, U, false, true> { /* volatile */
        using Type = volatile U &;
    };

    template<typename T, typename U>
    struct ApplyCv<T &, U, true, true> { /* const volatile */
        using Type = const volatile U &;
    };

    template<typename T, bool = IsIntegral<T>::value ||
                                IsEnum<T>::value>
    struct MakeSignedCore {};

    template<typename T, bool = IsIntegral<T>::value ||
                                IsEnum<T>::value>
    struct MakeUnsignedCore {};

    template<typename T>
    struct MakeSignedCore<T, true> {
        using Type = typename TypeFindFirst<Stypes, sizeof(T)>::Type;
    };

    template<typename T>
    struct MakeUnsignedCore<T, true> {
        using Type = typename TypeFindFirst<Utypes, sizeof(T)>::Type;
    };

    template<> struct MakeSignedCore<bool  , true> {};
    template<> struct MakeSignedCore<short , true> { using Type = short; };
    template<> struct MakeSignedCore<int   , true> { using Type = int; };
    template<> struct MakeSignedCore<long  , true> { using Type = long; };

    template<> struct MakeSignedCore<sbyte , true> { using Type = sbyte; };
    template<> struct MakeSignedCore<byte  , true> { using Type = sbyte; };
    template<> struct MakeSignedCore<ushort, true> { using Type = short; };
    template<> struct MakeSignedCore<uint  , true> { using Type = int;   };
    template<> struct MakeSignedCore<ulong , true> { using Type = long;  };
    template<> struct MakeSignedCore<llong , true> { using Type = llong; };
    template<> struct MakeSignedCore<ullong, true> { using Type = llong; };

    template<> struct MakeUnsignedCore<bool  , true> {};
    template<> struct MakeUnsignedCore<short , true> { using Type = ushort; };
    template<> struct MakeUnsignedCore<int   , true> { using Type = uint;   };
    template<> struct MakeUnsignedCore<long  , true> { using Type = ulong;  };

    template<> struct MakeUnsignedCore<sbyte , true> { using Type = byte;   };
    template<> struct MakeUnsignedCore<byte  , true> { using Type = byte;   };
    template<> struct MakeUnsignedCore<ushort, true> { using Type = ushort; };
    template<> struct MakeUnsignedCore<uint  , true> { using Type = uint;   };
    template<> struct MakeUnsignedCore<ulong , true> { using Type = ulong;  };
    template<> struct MakeUnsignedCore<llong , true> { using Type = ullong; };
    template<> struct MakeUnsignedCore<ullong, true> { using Type = ullong; };

    template<typename T> struct MakeSignedBase {
        using Type = typename ApplyCv<T,
            typename MakeSignedCore<RemoveCv<T>>::Type
        >::Type;
    };

    template<typename T> struct MakeUnsignedBase {
        using Type = typename ApplyCv<T,
            typename MakeUnsignedCore<RemoveCv<T>>::Type
        >::Type;
    };
} /* namespace detail */

template<typename T>
using MakeSigned = typename detail::MakeSignedBase<T>::Type;
template<typename T>
using MakeUnsigned = typename detail::MakeUnsignedBase<T>::Type;

/* conditional */

namespace detail {
    template<bool _cond, typename T, typename U>
    struct ConditionalBase {
        using Type = T;
    };

    template<typename T, typename U>
    struct ConditionalBase<false, T, U> {
        using Type = U;
    };
}

template<bool _cond, typename T, typename U>
using Conditional = typename detail::ConditionalBase<_cond, T, U>::Type;

/* result of call at compile time */

namespace detail {
#define OCTA_FWD(T, _v) static_cast<T &&>(_v)
    template<typename F, typename ...A>
    inline auto rof_invoke(F &&f, A &&...args) ->
      decltype(OCTA_FWD(F, f)(OCTA_FWD(A, args)...)) {
        return OCTA_FWD(F, f)(OCTA_FWD(A, args)...);
    }
    template<typename B, typename T, typename D>
    inline auto rof_invoke(T B::*pmd, D &&ref) ->
      decltype(OCTA_FWD(D, ref).*pmd) {
        return OCTA_FWD(D, ref).*pmd;
    }
    template<typename PMD, typename P>
    inline auto rof_invoke(PMD &&pmd, P &&ptr) ->
      decltype((*OCTA_FWD(P, ptr)).*OCTA_FWD(PMD, pmd)) {
        return (*OCTA_FWD(P, ptr)).*OCTA_FWD(PMD, pmd);
    }
    template<typename B, typename T, typename D, typename ...A>
    inline auto rof_invoke(T B::*pmf, D &&ref, A &&...args) ->
      decltype((OCTA_FWD(D, ref).*pmf)(OCTA_FWD(A, args)...)) {
        return (OCTA_FWD(D, ref).*pmf)(OCTA_FWD(A, args)...);
    }
    template<typename PMF, typename P, typename ...A>
    inline auto rof_invoke(PMF &&pmf, P &&ptr, A &&...args) ->
      decltype(((*OCTA_FWD(P, ptr)).*OCTA_FWD(PMF, pmf))
          (OCTA_FWD(A, args)...)) {
        return ((*OCTA_FWD(P, ptr)).*OCTA_FWD(PMF, pmf))
          (OCTA_FWD(A, args)...);
    }
#undef OCTA_FWD

    template<typename, typename = void>
    struct ResultOfCore {};
    template<typename F, typename ...A>
    struct ResultOfCore<F(A...), decltype(void(rof_invoke(
    detail::declval_in<F>(), detail::declval_in<A>()...)))> {
        using type = decltype(rof_invoke(detail::declval_in<F>(),
            detail::declval_in<A>()...));
    };

    template<typename T> struct ResultOfBase: ResultOfCore<T> {};
} /* namespace detail */

template<typename T>
using ResultOf = typename detail::ResultOfBase<T>::Type;

/* enable if */

namespace detail {
    template<bool B, typename T = void> struct EnableIfBase {};

    template<typename T> struct EnableIfBase<true, T> { using Type = T; };
}

template<bool B, typename T = void>
using EnableIf = typename detail::EnableIfBase<B, T>::Type;

/* decay */

namespace detail {
    template<typename T>
    struct DecayBase {
    private:
        using U = RemoveReference<T>;
    public:
        using Type = Conditional<IsArray<U>::value,
            RemoveExtent<U> *,
            Conditional<IsFunction<U>::value,
                AddPointer<U>, RemoveCv<U>>
        >;
    };
}

template<typename T>
using Decay = typename detail::DecayBase<T>::Type;

/* common type */

namespace detail {
    template<typename ...T> struct CommonTypeBase;

    template<typename T> struct CommonTypeBase<T> {
        using Type = Decay<T>;
    };

    template<typename T, typename U> struct CommonTypeBase<T, U> {
        using Type = Decay<decltype(true ? detail::declval_in<T>()
            : detail::declval_in<U>())>;
    };

    template<typename T, typename U, typename ...V>
    struct CommonTypeBase<T, U, V...> {
        using Type = typename CommonTypeBase<
            typename CommonTypeBase<T, U>::Type, V...
        >::Type;
    };
}

template<typename T, typename U, typename ...V>
using CommonType = typename detail::CommonTypeBase<T, U, V...>::Type;

/* aligned storage */

namespace detail {
    template<Size N> struct AlignedTest {
        union Type {
            byte data[N];
            MaxAlign align;
        };
    };

    template<Size N, Size A> struct AlignedStorageBase {
        struct Type {
            alignas(A) byte data[N];
        };
    };
}

template<Size N, Size A
    = alignof(typename detail::AlignedTest<N>::Type)
> using AlignedStorage = typename detail::AlignedStorageBase<N, A>::Type;

/* aligned union */

namespace detail {
    template<Size ...N> struct AlignMax;

    template<Size N> struct AlignMax<N> {
        static constexpr Size value = N;
    };

    template<Size N1, Size N2> struct AlignMax<N1, N2> {
        static constexpr Size value = (N1 > N2) ? N1 : N2;
    };

    template<Size N1, Size N2, Size ...N>
    struct AlignMax<N1, N2, N...> {
        static constexpr Size value
            = AlignMax<AlignMax<N1, N2>::value, N...>::value;
    };

    template<Size N, typename ...T> struct AlignedUnionBase {
        static constexpr Size alignment_value
            = AlignMax<alignof(T)...>::value;

        struct type {
            alignas(alignment_value) byte data[AlignMax<N,
                sizeof(T)...>::value];
        };
    };
} /* namespace detail */

template<Size N, typename ...T>
using AlignedUnion = typename detail::AlignedUnionBase<N, T...>::Type;

/* underlying type */

namespace detail {
    /* gotta wrap, in a struct otherwise clang ICEs... */
    template<typename T> struct UnderlyingTypeBase {
        using Type = __underlying_type(T);
    };
}

template<typename T>
using UnderlyingType = typename detail::UnderlyingTypeBase<T>::Type;

} /* namespace octa */

#endif
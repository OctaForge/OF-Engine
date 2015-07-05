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
using RemoveCv = typename octa::detail::RemoveCvBase<T>::Type;

template<typename T>
using AddLvalueReference = typename octa::detail::AddLr<T>::Type;

template<typename T>
using AddRvalueReference = typename octa::detail::AddRr<T>::Type;

template<typename T>
using AddConst = typename octa::detail::AddConstBase<T>::Type;

template<typename T>
using RemoveReference = typename octa::detail::RemoveReferenceBase<T>::Type;

template<typename T>
using RemoveAllExtents = typename octa::detail::RemoveAllExtentsBase<T>::Type;

namespace detail {
    template<typename T> octa::AddRvalueReference<T> declval_in();
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

/* is void */

namespace detail {
    template<typename T> struct IsVoidBase      : False {};
    template<          > struct IsVoidBase<void>:  True {};
}

    template<typename T>
    struct IsVoid: octa::detail::IsVoidBase<RemoveCv<T>> {};

/* is null pointer */

namespace detail {
    template<typename> struct IsNullPointerBase               : False {};
    template<        > struct IsNullPointerBase<octa::Nullptr>:  True {};
}

template<typename T> struct IsNullPointer:
    octa::detail::IsNullPointerBase<RemoveCv<T>> {};

/* is integer */

namespace detail {
    template<typename T> struct IsIntegralBase: False {};

    template<> struct IsIntegralBase<bool  >: True {};
    template<> struct IsIntegralBase<char  >: True {};
    template<> struct IsIntegralBase<short >: True {};
    template<> struct IsIntegralBase<int   >: True {};
    template<> struct IsIntegralBase<long  >: True {};

    template<> struct IsIntegralBase<octa::sbyte >: True {};
    template<> struct IsIntegralBase<octa::byte  >: True {};
    template<> struct IsIntegralBase<octa::ushort>: True {};
    template<> struct IsIntegralBase<octa::uint  >: True {};
    template<> struct IsIntegralBase<octa::ulong >: True {};
    template<> struct IsIntegralBase<octa::llong >: True {};
    template<> struct IsIntegralBase<octa::ullong>: True {};

    template<> struct IsIntegralBase<octa::Char16>: True {};
    template<> struct IsIntegralBase<octa::Char32>: True {};
    template<> struct IsIntegralBase<octa::Wchar >: True {};
}

template<typename T>
struct IsIntegral: octa::detail::IsIntegralBase<RemoveCv<T>> {};

/* is floating point */

namespace detail {
    template<typename T> struct IsFloatingPointBase: False {};

    template<> struct IsFloatingPointBase<float >: True {};
    template<> struct IsFloatingPointBase<double>: True {};

    template<> struct IsFloatingPointBase<octa::ldouble>: True {};
}

template<typename T>
struct IsFloatingPoint: octa::detail::IsFloatingPointBase<RemoveCv<T>> {};

/* is array */

template<typename                > struct IsArray      : False {};
template<typename T              > struct IsArray<T[] >:  True {};
template<typename T, octa::Size N> struct IsArray<T[N]>:  True {};

/* is pointer */

namespace detail {
    template<typename  > struct IsPointerBase     : False {};
    template<typename T> struct IsPointerBase<T *>:  True {};
}

template<typename T>
struct IsPointer: octa::detail::IsPointerBase<RemoveCv<T>> {};

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

    template<typename T, bool = octa::IsClass<T>::value ||
                                octa::IsUnion<T>::value ||
                                octa::IsVoid<T>::value ||
                                octa::IsReference<T>::value ||
                                octa::IsNullPointer<T>::value
    > struct IsFunctionBase: IntegralConstant<bool,
        sizeof(function_test<T>(function_source<T>(0))) == 1
    > {};

    template<typename T> struct IsFunctionBase<T, true>: False {};
} /* namespace detail */

template<typename T> struct IsFunction: octa::detail::IsFunctionBase<T> {};

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
struct IsMemberPointer: octa::detail::IsMemberPointerBase<RemoveCv<T>> {};

/* is pointer to member object */

namespace detail {
    template<typename>
    struct IsMemberObjectPointerBase: False {};

    template<typename T, typename U>
    struct IsMemberObjectPointerBase<T U::*>: IntegralConstant<bool,
        !octa::IsFunction<T>::value
    > {};
}

template<typename T> struct IsMemberObjectPointer:
    octa::detail::IsMemberObjectPointerBase<RemoveCv<T>> {};

/* is pointer to member function */

namespace detail {
    template<typename>
    struct IsMemberFunctionPointerBase: False {};

    template<typename T, typename U>
    struct IsMemberFunctionPointerBase<T U::*>: IntegralConstant<bool,
        octa::IsFunction<T>::value
    > {};
}

template<typename T> struct IsMemberFunctionPointer:
    octa::detail::IsMemberFunctionPointerBase<RemoveCv<T>> {};

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

template<typename T, bool = octa::IsArithmetic<T>::value>
struct IsSigned: False {};

template<typename T>
struct IsSigned<T, true>: octa::detail::IsSignedBase<T> {};

/* is unsigned */

namespace detail {
    template<typename T>
    struct IsUnsignedBase: IntegralConstant<bool, T(0) < T(-1)> {};
}

template<typename T, bool = octa::IsArithmetic<T>::value>
struct IsUnsigned: False {};

template<typename T>
struct IsUnsigned<T, true>: octa::detail::IsUnsignedBase<T> {};

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
#define OCTA_MOVE(v) static_cast<octa::RemoveReference<decltype(v)> &&>(v)

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
    struct CtibleCore<true, T>: octa::IsScalar<T> {};

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
        (octa::IsScalar<T>::value || octa::IsReference<T>::value), T, A...
    > {};

    /* if any of T or A is void, IsConstructible should be false */
    template<typename T, typename ...A>
    struct CtibleVoidCheck<true, T, A...>: False {};

    template<typename ...A> struct CtibleContainsVoid;

    template<> struct CtibleContainsVoid<>: False {};

    template<typename T, typename ...A>
    struct CtibleContainsVoid<T, A...> {
        static constexpr bool value = octa::IsVoid<T>::value
           || CtibleContainsVoid<A...>::value;
    };

    /* entry point */
    template<typename T, typename ...A>
    struct Ctible: CtibleVoidCheck<
        CtibleContainsVoid<T, A...>::value || octa::IsAbstract<T>::value,
        T, A...
    > {};

    /* array types are default constructible if their element type is */
    template<typename T, octa::Size N>
    struct CtibleCore<false, T[N]>: Ctible<octa::RemoveAllExtents<T>> {};

    /* otherwise array types are not constructible by this syntax */
    template<typename T, octa::Size N, typename ...A>
    struct CtibleCore<false, T[N], A...>: False {};

    /* incomplete array types are not constructible */
    template<typename T, typename ...A>
    struct CtibleCore<false, T[], A...>: False {};
} /* namespace detail */

template<typename T, typename ...A>
struct IsConstructible: octa::detail::Ctible<T, A...> {};

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
    template<typename T, typename U> typename octa::detail::Select2nd<
        decltype((declval_in<T>() = declval_in<U>())), True
    >::Type assign_test(T &&, U &&);

    template<typename T> False assign_test(Any, T &&);

    template<typename T, typename U, bool = octa::IsVoid<T>::value ||
                                              octa::IsVoid<U>::value
    > struct IsAssignableBase: CommonTypeBase<
        decltype(assign_test(declval_in<T>(), declval_in<U>()))
    >::Type {};

    template<typename T, typename U>
    struct IsAssignableBase<T, U, true>: False {};
} /* namespace detail */

template<typename T, typename U>
struct IsAssignable: octa::detail::IsAssignableBase<T, U> {};

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
            decltype(octa::detail::declval_in<TT &>().~TT())
        >::Type);

        template<typename TT> static int test(...);

        static constexpr bool value = (sizeof(test<T>(12)) == sizeof(char));
    };

    template<typename, bool> struct DtibleImpl;

    template<typename T>
    struct DtibleImpl<T, false>: octa::IntegralConstant<bool,
        IsDestructorWellformed<octa::RemoveAllExtents<T>>::value
    > {};

    template<typename T>
    struct DtibleImpl<T, true>: True {};

    template<typename T, bool> struct DtibleFalse;

    template<typename T> struct DtibleFalse<T, false>
        : DtibleImpl<T, octa::IsReference<T>::value> {};

    template<typename T> struct DtibleFalse<T, true>: False {};
} /* namespace detail */

template<typename T>
struct IsDestructible: octa::detail::DtibleFalse<T, IsFunction<T>::value> {};

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
    template<typename F, typename T, bool = octa::IsVoid<F>::value
        || octa::IsFunction<T>::value || octa::IsArray<T>::value
    > struct IsConvertibleBase {
        using Type = typename octa::IsVoid<T>::Type;
    };

    template<typename F, typename T>
    struct IsConvertibleBase<F, T, false> {
        template<typename TT> static void test_f(TT);

        template<typename FF, typename TT,
            typename = decltype(test_f<TT>(declval_in<FF>()))
        > static octa::True test(int);

        template<typename, typename> static octa::False test(...);

        using Type = decltype(test<F, T>(0));
    };
}

template<typename F, typename T>
struct IsConvertible: octa::detail::IsConvertibleBase<F, T>::Type {};

/* type equality */

template<typename, typename> struct IsSame      : False {};
template<typename T        > struct IsSame<T, T>:  True {};

/* extent */

template<typename T, octa::uint I = 0>
struct Extent: IntegralConstant<octa::Size, 0> {};

template<typename T>
struct Extent<T[], 0>: IntegralConstant<octa::Size, 0> {};

template<typename T, octa::uint I>
struct Extent<T[], I>: IntegralConstant<octa::Size, Extent<T, I - 1>::value> {};

template<typename T, octa::Size N>
struct Extent<T[N], 0>: IntegralConstant<octa::Size, N> {};

template<typename T, octa::Size N, octa::uint I>
struct Extent<T[N], I>: IntegralConstant<octa::Size, Extent<T, I - 1>::value> {};

/* rank */

template<typename T> struct Rank: IntegralConstant<octa::Size, 0> {};

template<typename T>
struct Rank<T[]>: IntegralConstant<octa::Size, Rank<T>::value + 1> {};

template<typename T, octa::Size N>
struct Rank<T[N]>: IntegralConstant<octa::Size, Rank<T>::value + 1> {};

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
using RemoveConst = typename octa::detail::RemoveConstBase<T>::Type;
template<typename T>
using RemoveVolatile = typename octa::detail::RemoveVolatileBase<T>::Type;

namespace detail {
    template<typename T>
    struct RemoveCvBase {
        using Type = octa::RemoveVolatile<octa::RemoveConst<T>>;
    };
}

/* add const, volatile, cv */

namespace detail {
    template<typename T, bool = octa::IsReference<T>::value
         || octa::IsFunction<T>::value || octa::IsConst<T>::value>
    struct AddConstCore { using Type = T; };

    template<typename T> struct AddConstCore<T, false> {
        using Type = const T;
    };

    template<typename T> struct AddConstBase {
        using Type = typename AddConstCore<T>::Type;
    };

    template<typename T, bool = octa::IsReference<T>::value
         || octa::IsFunction<T>::value || octa::IsVolatile<T>::value>
    struct AddVolatileCore { using Type = T; };

    template<typename T> struct AddVolatileCore<T, false> {
        using Type = volatile T;
    };

    template<typename T> struct AddVolatileBase {
        using Type = typename AddVolatileCore<T>::Type;
    };
}

template<typename T>
using AddVolatile = typename octa::detail::AddVolatileBase<T>::Type;

namespace detail {
    template<typename T>
    struct AddCvBase {
        using Type = octa::AddConst<octa::AddVolatile<T>>;
    };
}

template<typename T>
using AddCv = typename octa::detail::AddCvBase<T>::Type;

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
using RemovePointer = typename octa::detail::RemovePointerBase<T>::Type;

/* add pointer */

namespace detail {
    template<typename T> struct AddPointerBase {
        using Type = octa::RemoveReference<T> *;
    };
}

template<typename T>
using AddPointer = typename octa::detail::AddPointerBase<T>::Type;

/* add lvalue reference */

namespace detail {
    template<typename T> struct AddLr       { using Type = T &; };
    template<typename T> struct AddLr<T  &> { using Type = T &; };
    template<typename T> struct AddLr<T &&> { using Type = T &; };
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
    template<typename T> struct AddRr       { using Type = T &&; };
    template<typename T> struct AddRr<T  &> { using Type = T &&; };
    template<typename T> struct AddRr<T &&> { using Type = T &&; };
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
    template<typename T, octa::Size N>
    struct RemoveExtentBase<T[N]> { using Type = T; };
}

template<typename T>
using RemoveExtent = typename octa::detail::RemoveExtentBase<T>::Type;

/* remove all extents */

namespace detail {
    template<typename T> struct RemoveAllExtentsBase { using Type = T; };

    template<typename T> struct RemoveAllExtentsBase<T[]> {
        using Type = RemoveAllExtentsBase<T>;
    };

    template<typename T, octa::Size N> struct RemoveAllExtentsBase<T[N]> {
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

    using Stypes = TypeList<octa::sbyte,
                   TypeList<short,
                   TypeList<int,
                   TypeList<long,
                   TypeList<octa::llong, TlNat>>>>>;

    using Utypes = TypeList<octa::byte,
                   TypeList<octa::ushort,
                   TypeList<octa::uint,
                   TypeList<octa::ulong,
                   TypeList<octa::ullong, TlNat>>>>>;

    template<typename T, octa::Size N, bool = (N <= sizeof(typename T::First))>
    struct TypeFindFirst;

    template<typename T, typename U, octa::Size N>
    struct TypeFindFirst<TypeList<T, U>, N, true> {
        using Type = T;
    };

    template<typename T, typename U, octa::Size N>
    struct TypeFindFirst<TypeList<T, U>, N, false> {
        using Type = typename TypeFindFirst<U, N>::Type;
    };

    template<typename T, typename U,
        bool = octa::IsConst<octa::RemoveReference<T>>::value,
        bool = octa::IsVolatile<octa::RemoveReference<T>>::value
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

    template<typename T, bool = octa::IsIntegral<T>::value ||
                                 octa::IsEnum<T>::value>
    struct MakeSigned {};

    template<typename T, bool = octa::IsIntegral<T>::value ||
                                 octa::IsEnum<T>::value>
    struct MakeUnsigned {};

    template<typename T>
    struct MakeSigned<T, true> {
        using Type = typename TypeFindFirst<Stypes, sizeof(T)>::Type;
    };

    template<typename T>
    struct MakeUnsigned<T, true> {
        using Type = typename TypeFindFirst<Utypes, sizeof(T)>::Type;
    };

    template<> struct MakeSigned<bool  , true> {};
    template<> struct MakeSigned<short , true> { using Type = short; };
    template<> struct MakeSigned<int   , true> { using Type = int; };
    template<> struct MakeSigned<long  , true> { using Type = long; };

    template<> struct MakeSigned<octa::sbyte , true> { using Type = octa::sbyte; };
    template<> struct MakeSigned<octa::byte  , true> { using Type = octa::sbyte; };
    template<> struct MakeSigned<octa::ushort, true> { using Type = short;       };
    template<> struct MakeSigned<octa::uint  , true> { using Type = int;         };
    template<> struct MakeSigned<octa::ulong , true> { using Type = long;        };
    template<> struct MakeSigned<octa::llong , true> { using Type = octa::llong; };
    template<> struct MakeSigned<octa::ullong, true> { using Type = octa::llong; };

    template<> struct MakeUnsigned<bool  , true> {};
    template<> struct MakeUnsigned<short , true> { using Type = octa::ushort; };
    template<> struct MakeUnsigned<int   , true> { using Type = octa::uint; };
    template<> struct MakeUnsigned<long  , true> { using Type = octa::ulong; };

    template<> struct MakeUnsigned<octa::sbyte , true> { using Type = octa::byte;   };
    template<> struct MakeUnsigned<octa::byte  , true> { using Type = octa::byte;   };
    template<> struct MakeUnsigned<octa::ushort, true> { using Type = octa::ushort; };
    template<> struct MakeUnsigned<octa::uint  , true> { using Type = octa::uint;   };
    template<> struct MakeUnsigned<octa::ulong , true> { using Type = octa::ulong;  };
    template<> struct MakeUnsigned<octa::llong , true> { using Type = octa::ullong; };
    template<> struct MakeUnsigned<octa::ullong, true> { using Type = octa::ullong; };

    template<typename T> struct MakeSignedBase {
        using Type = typename ApplyCv<T,
            typename MakeSigned<octa::RemoveCv<T>>::Type
        >::Type;
    };

    template<typename T> struct MakeUnsignedBase {
        using Type = typename ApplyCv<T,
            typename MakeUnsigned<octa::RemoveCv<T>>::Type
        >::Type;
    };
} /* namespace detail */

template<typename T>
using MakeSigned = typename octa::detail::MakeSignedBase<T>::Type;
template<typename T>
using MakeUnsigned = typename octa::detail::MakeUnsignedBase<T>::Type;

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
using Conditional = typename octa::detail::ConditionalBase<_cond, T, U>::Type;

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
    octa::detail::declval_in<F>(), octa::detail::declval_in<A>()...)))> {
        using type = decltype(rof_invoke(octa::detail::declval_in<F>(),
            octa::detail::declval_in<A>()...));
    };

    template<typename T> struct ResultOfBase: ResultOfCore<T> {};
} /* namespace detail */

template<typename T>
using ResultOf = typename octa::detail::ResultOfBase<T>::Type;

/* enable if */

namespace detail {
    template<bool B, typename T = void> struct EnableIfBase {};

    template<typename T> struct EnableIfBase<true, T> { using Type = T; };
}

template<bool B, typename T = void>
using EnableIf = typename octa::detail::EnableIfBase<B, T>::Type;

/* decay */

namespace detail {
    template<typename T>
    struct DecayBase {
    private:
        using U = octa::RemoveReference<T>;
    public:
        using Type = octa::Conditional<octa::IsArray<U>::value,
            octa::RemoveExtent<U> *,
            octa::Conditional<octa::IsFunction<U>::value,
                octa::AddPointer<U>, octa::RemoveCv<U>>
        >;
    };
}

template<typename T>
using Decay = typename octa::detail::DecayBase<T>::Type;

/* common type */

namespace detail {
    template<typename ...T> struct CommonTypeBase;

    template<typename T> struct CommonTypeBase<T> {
        using Type = Decay<T>;
    };

    template<typename T, typename U> struct CommonTypeBase<T, U> {
        using Type = Decay<decltype(true ? octa::detail::declval_in<T>()
            : octa::detail::declval_in<U>())>;
    };

    template<typename T, typename U, typename ...V>
    struct CommonTypeBase<T, U, V...> {
        using Type = typename CommonTypeBase<
            typename CommonTypeBase<T, U>::Type, V...
        >::Type;
    };
}

template<typename T, typename U, typename ...V>
using CommonType = typename octa::detail::CommonTypeBase<T, U, V...>::Type;

/* aligned storage */

namespace detail {
    template<octa::Size N> struct AlignedTest {
        union Type {
            octa::byte data[N];
            octa::MaxAlign align;
        };
    };

    template<octa::Size N, octa::Size A> struct AlignedStorageBase {
        struct Type {
            alignas(A) octa::byte data[N];
        };
    };
}

template<octa::Size N, octa::Size A
    = alignof(typename octa::detail::AlignedTest<N>::Type)
> using AlignedStorage = typename octa::detail::AlignedStorageBase<N, A>::Type;

/* aligned union */

namespace detail {
    template<octa::Size ...N> struct AlignMax;

    template<octa::Size N> struct AlignMax<N> {
        static constexpr octa::Size value = N;
    };

    template<octa::Size N1, octa::Size N2> struct AlignMax<N1, N2> {
        static constexpr octa::Size value = (N1 > N2) ? N1 : N2;
    };

    template<octa::Size N1, octa::Size N2, octa::Size ...N>
    struct AlignMax<N1, N2, N...> {
        static constexpr octa::Size value
            = AlignMax<AlignMax<N1, N2>::value, N...>::value;
    };

    template<octa::Size N, typename ...T> struct AlignedUnionBase {
        static constexpr octa::Size alignment_value
            = AlignMax<alignof(T)...>::value;

        struct type {
            alignas(alignment_value) octa::byte data[AlignMax<N,
                sizeof(T)...>::value];
        };
    };
} /* namespace detail */

template<octa::Size N, typename ...T>
using AlignedUnion = typename octa::detail::AlignedUnionBase<N, T...>::Type;

/* underlying type */

namespace detail {
    /* gotta wrap, in a struct otherwise clang ICEs... */
    template<typename T> struct UnderlyingTypeBase {
        using Type = __underlying_type(T);
    };
}

template<typename T>
using UnderlyingType = typename octa::detail::UnderlyingTypeBase<T>::Type;
} /* namespace octa */

#endif
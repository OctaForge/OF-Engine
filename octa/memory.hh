/* Memory utilities for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_MEMORY_HH
#define OCTA_MEMORY_HH

#include <stddef.h>

#include "octa/new.hh"
#include "octa/utility.hh"
#include "octa/type_traits.hh"

namespace octa {
/* address of */

template<typename T> constexpr T *address_of(T &v) {
    return reinterpret_cast<T *>(&const_cast<char &>
        (reinterpret_cast<const volatile char &>(v)));
}

/* pointer traits */

namespace detail {
    template<typename T>
    struct HasElement {
        template<typename U> static int test(...);
        template<typename U> static char test(typename U::Element * = 0);

        static constexpr bool value = (sizeof(test<T>(0)) == 1);
    };

    template<typename T, bool = HasElement<T>::value>
    struct PointerElementBase;

    template<typename T> struct PointerElementBase<T, true> {
        using Type = typename T::Element;
    };

    template<template<typename, typename...> class T, typename U, typename ...A>
    struct PointerElementBase<T<U, A...>, true> {
        using Type = typename T<U, A...>::Element;
    };

    template<template<typename, typename...> class T, typename U, typename ...A>
    struct PointerElementBase<T<U, A...>, false> {
        using Type = U;
    };

    template<typename T>
    struct PointerElementType {
        using Type = typename PointerElementBase<T>::Type;
    };

    template<typename T>
    struct PointerElementType<T *> {
        using Type = T;
    };

    template<typename T>
    struct HasDifference {
        template<typename U> static int test(...);
        template<typename U> static char test(typename U::Difference * = 0);

        static constexpr bool value = (sizeof(test<T>(0)) == 1);
    };

    template<typename T, bool = HasDifference<T>::value>
    struct PointerDifferenceBase {
        using Type = Ptrdiff;
    };

    template<typename T> struct PointerDifferenceBase<T, true> {
        using Type = typename T::Difference;
    };

    template<typename T>
    struct PointerDifferenceType {
        using Type = typename PointerDifferenceBase<T>::Type;
    };

    template<typename T>
    struct PointerDifferenceType<T *> {
        using Type = Ptrdiff;
    };

    template<typename T, typename U>
    struct HasRebind {
        template<typename V> static int test(...);
        template<typename V> static char test(
            typename V::template Rebind<U> * = 0);

        static constexpr bool value = (sizeof(test<T>(0)) == 1);
    };

    template<typename T, typename U, bool = HasRebind<T, U>::value>
    struct PointerRebindBase {
        using Type = typename T::template Rebind<U>;
    };

    template<template<typename, typename...> class T, typename U,
        typename ...A, typename V
    >
    struct PointerRebindBase<T<U, A...>, V, true> {
        using Type = typename T<U, A...>::template Rebind<V>;
    };

    template<template<typename, typename...> class T, typename U,
        typename ...A, typename V
    >
    struct PointerRebindBase<T<U, A...>, V, false> {
        using Type = T<V, A...>;
    };

    template<typename T, typename U>
    struct PointerRebindType {
        using type = typename PointerRebindBase<T, U>::Type;
    };

    template<typename T, typename U>
    struct PointerRebindType<T *, U> {
        using type = U *;
    };

    template<typename T>
    struct PointerPointer {
        using Type = T;
    };

    template<typename T>
    struct PointerPointer<T *> {
        using Type = T *;
    };
} /*namespace detail */

template<typename T>
using Pointer = typename detail::PointerPointer<T>::Type;

template<typename T>
using PointerElement = typename detail::PointerElementType<T>::Type;

template<typename T>
using PointerDifference = typename detail::PointerDifferenceType<T>::Type;

template<typename T, typename U>
using PointerRebind = typename detail::PointerRebindType<T, U>::Type;

/* pointer to */

namespace detail {
    struct PointerToNat {};

    template<typename T>
    struct PointerTo {
        static T pointer_to(Conditional<IsVoid<PointerElement<T>>::value,
            PointerToNat, PointerElement<T>
        > &r) {
            return T::pointer_to(r);
        }
    };

    template<typename T>
    struct PointerTo<T *> {
        static T pointer_to(Conditional<IsVoid<T>::value,
            PointerToNat, T
        > &r) {
            return address_of(r);
        }
    };
}

template<typename T>
static T pointer_to(Conditional<IsVoid<PointerElement<T>>::value,
    detail::PointerToNat, PointerElement<T>
> &r) {
    return detail::PointerTo<T>::pointer_to(r);
}

/* default deleter */

template<typename T>
struct DefaultDelete {
    constexpr DefaultDelete() = default;

    template<typename U> DefaultDelete(const DefaultDelete<U> &) {};

    void operator()(T *p) const {
        delete p;
    }
};

template<typename T>
struct DefaultDelete<T[]> {
    constexpr DefaultDelete() = default;

    template<typename U> DefaultDelete(const DefaultDelete<U[]> &) {};

    void operator()(T *p) const {
        delete[] p;
    }
    template<typename U> void operator()(U *) const = delete;
};

/* box */

namespace detail {
    template<typename T>
    static int ptr_test(...);
    template<typename T>
    static char ptr_test(typename T::Pointer * = 0);

    template<typename T> struct HasPtr: IntegralConstant<bool,
        (sizeof(ptr_test<T>(0)) == 1)
    > {};

    template<typename T, typename D, bool = HasPtr<D>::value>
    struct PointerBase {
        using Type = typename D::Pointer;
    };

    template<typename T, typename D> struct PointerBase<T, D, false> {
        using Type = T *;
    };

    template<typename T, typename D> struct PointerType {
        using Type = typename PointerBase<T, RemoveReference<D>>::Type;
    };
} /* namespace detail */

template<typename T, typename D = DefaultDelete<T>>
struct Box {
    using Element = T;
    using Deleter = D;
    using Pointer = typename detail::PointerType<T, D>::Type;

private:
    struct Nat { int x; };

    using Dref = RemoveReference<D> &;
    using Dcref = const RemoveReference<D> &;

public:
    constexpr Box(): p_stor(nullptr, D()) {
        static_assert(!IsPointer<D>::value,
            "Box constructed with null fptr deleter");
    }
    constexpr Box(Nullptr): p_stor(nullptr, D()) {
        static_assert(!IsPointer<D>::value,
            "Box constructed with null fptr deleter");
    }

    explicit Box(Pointer p): p_stor(p, D()) {
        static_assert(!IsPointer<D>::value,
            "Box constructed with null fptr deleter");
    }

    Box(Pointer p, Conditional<IsReference<D>::value,
        D, AddLvalueReference<const D>
    > d): p_stor(p, d) {}

    Box(Pointer p, RemoveReference<D> &&d):
    p_stor(p, move(d)) {
        static_assert(!IsReference<D>::value,
            "rvalue deleter cannot be a ref");
    }

    Box(Box &&u): p_stor(u.release(), forward<D>(u.get_deleter())) {}

    template<typename TT, typename DD>
    Box(Box<TT, DD> &&u, EnableIf<!IsArray<TT>::value
        && IsConvertible<typename Box<TT, DD>::Pointer, Pointer>::value
        && IsConvertible<DD, D>::value
        && (!IsReference<D>::value || IsSame<D, DD>::value)
    > = Nat()): p_stor(u.release(), forward<DD>(u.get_deleter())) {}

    Box &operator=(Box &&u) {
        reset(u.release());
        p_stor.second() = forward<D>(u.get_deleter());
        return *this;
    }

    template<typename TT, typename DD>
    EnableIf<!IsArray<TT>::value
        && IsConvertible<typename Box<TT, DD>::Pointer, Pointer>::value
        && IsAssignable<D &, DD &&>::value,
        Box &
    > operator=(Box<TT, DD> &&u) {
        reset(u.release());
        p_stor.second() = forward<DD>(u.get_deleter());
        return *this;
    }

    Box &operator=(Nullptr) {
        reset();
        return *this;
    }

    ~Box() { reset(); }

    AddLvalueReference<T> operator*() const { return *p_stor.first(); }
    Pointer operator->() const { return p_stor.first(); }

    explicit operator bool() const {
        return p_stor.first() != nullptr;
    }

    Pointer get() const { return p_stor.first(); }

    Dref  get_deleter()       { return p_stor.second(); }
    Dcref get_deleter() const { return p_stor.second(); }

    Pointer release() {
        Pointer p = p_stor.first();
        p_stor.first() = nullptr;
        return p;
    }

    void reset(Pointer p = nullptr) {
        Pointer tmp = p_stor.first();
        p_stor.first() = p;
        if (tmp) p_stor.second()(tmp);
    }

    void swap(Box &u) {
        p_stor.swap(u.p_stor);
    }

private:
    detail::CompressedPair<T *, D> p_stor;
};

namespace detail {
    template<typename T, typename U, bool = IsSame<
        RemoveCv<PointerElement<T>>,
        RemoveCv<PointerElement<U>>
    >::value> struct SameOrLessCvQualifiedBase: IsConvertible<T, U> {};

    template<typename T, typename U>
    struct SameOrLessCvQualifiedBase<T, U, false>: False {};

    template<typename T, typename U, bool = IsPointer<T>::value
        || IsSame<T, U>::value || detail::HasElement<T>::value
    > struct SameOrLessCvQualified: SameOrLessCvQualifiedBase<T, U> {};

    template<typename T, typename U>
    struct SameOrLessCvQualified<T, U, false>: False {};
} /* namespace detail */

template<typename T, typename D>
struct Box<T[], D> {
    using Element = T;
    using Deleter = D;
    using Pointer = typename detail::PointerType<T, D>::Type;

private:
    struct Nat { int x; };

    using Dref = RemoveReference<D> &;
    using Dcref = const RemoveReference<D> &;

public:
    constexpr Box(): p_stor(nullptr, D()) {
        static_assert(!IsPointer<D>::value,
            "Box constructed with null fptr deleter");
    }
    constexpr Box(Nullptr): p_stor(nullptr, D()) {
        static_assert(!IsPointer<D>::value,
            "Box constructed with null fptr deleter");
    }

    template<typename U> explicit Box(U p, EnableIf<
        detail::SameOrLessCvQualified<U, Pointer>::value, Nat
    > = Nat()): p_stor(p, D()) {
        static_assert(!IsPointer<D>::value,
            "Box constructed with null fptr deleter");
    }

    template<typename U> Box(U p, Conditional<
        IsReference<D>::value,
        D, AddLvalueReference<const D>
    > d, EnableIf<detail::SameOrLessCvQualified<U, Pointer>::value,
    Nat> = Nat()): p_stor(p, d) {}

    Box(Nullptr, Conditional<IsReference<D>::value,
        D, AddLvalueReference<const D>
    > d): p_stor(nullptr, d) {}

    template<typename U> Box(U p, RemoveReference<D> &&d,
    EnableIf<
        detail::SameOrLessCvQualified<U, Pointer>::value, Nat
    > = Nat()): p_stor(p, move(d)) {
        static_assert(!IsReference<D>::value,
            "rvalue deleter cannot be a ref");
    }

    Box(Nullptr, RemoveReference<D> &&d):
    p_stor(nullptr, move(d)) {
        static_assert(!IsReference<D>::value,
            "rvalue deleter cannot be a ref");
    }

    Box(Box &&u): p_stor(u.release(), forward<D>(u.get_deleter())) {}

    template<typename TT, typename DD>
    Box(Box<TT, DD> &&u, EnableIf<IsArray<TT>::value
        && detail::SameOrLessCvQualified<typename Box<TT, DD>::Pointer,
                                         Pointer>::value
        && IsConvertible<DD, D>::value
        && (!IsReference<D>::value ||
             IsSame<D, DD>::value)> = Nat()
    ): p_stor(u.release(), forward<DD>(u.get_deleter())) {}

    Box &operator=(Box &&u) {
        reset(u.release());
        p_stor.second() = forward<D>(u.get_deleter());
        return *this;
    }

    template<typename TT, typename DD>
    EnableIf<IsArray<TT>::value
        && detail::SameOrLessCvQualified<typename Box<TT, DD>::Pointer,
                                         Pointer>::value
        && IsAssignable<D &, DD &&>::value,
        Box &
    > operator=(Box<TT, DD> &&u) {
        reset(u.release());
        p_stor.second() = forward<DD>(u.get_deleter());
        return *this;
    }

    Box &operator=(Nullptr) {
        reset();
        return *this;
    }

    ~Box() { reset(); }

    AddLvalueReference<T> operator[](Size idx) const {
        return p_stor.first()[idx];
    }

    explicit operator bool() const {
        return p_stor.first() != nullptr;
    }

    Pointer get() const { return p_stor.first(); }

    Dref  get_deleter()       { return p_stor.second(); }
    Dcref get_deleter() const { return p_stor.second(); }

    Pointer release() {
        Pointer p = p_stor.first();
        p_stor.first() = nullptr;
        return p;
    }

    template<typename U> EnableIf<
        detail::SameOrLessCvQualified<U, Pointer>::value, void
    > reset(U p) {
        Pointer tmp = p_stor.first();
        p_stor.first() = p;
        if (tmp) p_stor.second()(tmp);
    }

    void reset(Nullptr) {
        Pointer tmp = p_stor.first();
        p_stor.first() = nullptr;
        if (tmp) p_stor.second()(tmp);
    }

    void reset() {
        reset(nullptr);
    }

    void swap(Box &u) {
        p_stor.swap(u.p_stor);
    }

private:
    detail::CompressedPair<T *, D> p_stor;
};

namespace detail {
    template<typename T> struct BoxIf {
        using BoxType = Box<T>;
    };

    template<typename T> struct BoxIf<T[]> {
        using BoxUnknownSize = Box<T[]>;
    };

    template<typename T, Size N> struct BoxIf<T[N]> {
        using BoxKnownSize = void;
    };
}

template<typename T, typename ...A>
typename detail::BoxIf<T>::BoxType make_box(A &&...args) {
    return Box<T>(new T(forward<A>(args)...));
}

template<typename T>
typename detail::BoxIf<T>::BoxUnknownSize make_box(Size n) {
    return Box<T>(new RemoveExtent<T>[n]());
}

template<typename T, typename ...A>
typename detail::BoxIf<T>::BoxKnownSize make_box(A &&...args) = delete;

/* allocator */

template<typename> struct Allocator;

template<> struct Allocator<void> {
    using Value = void;
    using Pointer = void *;
    using ConstPointer = const void *;

    template<typename U> using Rebind = Allocator<U>;
};

template<> struct Allocator<const void> {
    using Value = const void;
    using Pointer = const void *;
    using ConstPointer = const void *;

    template<typename U> using Rebind = Allocator<U>;
};

template<typename T> struct Allocator {
    using Size = octa::Size;
    using Difference = Ptrdiff;
    using Value = T;
    using Reference = T &;
    using ConstReference = const T &;
    using Pointer = T *;
    using ConstPointer = const T *;

    template<typename U> using Rebind = Allocator<U>;

    Allocator() {}
    template<typename U> Allocator(const Allocator<U> &) {}

    Pointer address(Reference v) const {
        return address_of(v);
    };
    ConstPointer address(ConstReference v) const {
        return address_of(v);
    };

    Size max_size() const { return Size(~0) / sizeof(T); }

    Pointer allocate(Size n, Allocator<void>::ConstPointer = nullptr) {
        return (Pointer) ::new byte[n * sizeof(T)];
    }

    void deallocate(Pointer p, Size) { ::delete[] (byte *) p; }

    template<typename U, typename ...A>
    void construct(U *p, A &&...args) {
        ::new((void *)p) U(forward<A>(args)...);
    }

    void destroy(Pointer p) { p->~T(); }
};

template<typename T> struct Allocator<const T> {
    using Size = octa::Size;
    using Difference = Ptrdiff;
    using Value = const T;
    using Reference = const T &;
    using ConstReference = const T &;
    using Pointer = const T *;
    using ConstPointer = const T *;

    template<typename U> using Rebind = Allocator<U>;

    Allocator() {}
    template<typename U> Allocator(const Allocator<U> &) {}

    ConstPointer address(ConstReference v) const {
        return address_of(v);
    };

    Size max_size() const { return Size(~0) / sizeof(T); }

    Pointer allocate(Size n, Allocator<void>::ConstPointer = nullptr) {
        return (Pointer) ::new byte[n * sizeof(T)];
    }

    void deallocate(Pointer p, Size) { ::delete[] (byte *) p; }

    template<typename U, typename ...A>
    void construct(U *p, A &&...args) {
        ::new((void *)p) U(forward<A>(args)...);
    }

    void destroy(Pointer p) { p->~T(); }
};

template<typename T, typename U>
bool operator==(const Allocator<T> &, const Allocator<U> &) {
    return true;
}

template<typename T, typename U>
bool operator!=(const Allocator<T> &, const Allocator<U> &) {
    return false;
}

/* allocator traits - modeled after libc++ */

namespace detail {
    template<typename T>
    struct ConstPtrTest {
        template<typename U> static char test(
            typename U::ConstPointer * = 0);
        template<typename U> static  int test(...);
        static constexpr bool value = (sizeof(test<T>(0)) == 1);
    };

    template<typename T, typename P, typename A,
        bool = ConstPtrTest<A>::value>
    struct ConstPointer {
        using Type = typename A::ConstPointer;
    };

    template<typename T, typename P, typename A>
    struct ConstPointer<T, P, A, false> {
        using Type = PointerRebind<P, const T>;
    };

    template<typename T>
    struct VoidPtrTest {
        template<typename U> static char test(
            typename U::VoidPointer * = 0);
        template<typename U> static  int test(...);
        static constexpr bool value = (sizeof(test<T>(0)) == 1);
    };

    template<typename P, typename A, bool = VoidPtrTest<A>::value>
    struct VoidPointer {
        using Type = typename A::VoidPointer;
    };

    template<typename P, typename A>
    struct VoidPointer<P, A, false> {
        using Type = PointerRebind<P, void>;
    };

    template<typename T>
    struct ConstVoidPtrTest {
        template<typename U> static char test(
            typename U::ConstVoidPointer * = 0);
        template<typename U> static  int test(...);
        static constexpr bool value = (sizeof(test<T>(0)) == 1);
    };

    template<typename P, typename A, bool = ConstVoidPtrTest<A>::value>
    struct ConstVoidPointer {
        using Type = typename A::ConstVoidPointer;
    };

    template<typename P, typename A>
    struct ConstVoidPointer<P, A, false> {
        using Type = PointerRebind<P, const void>;
    };

    template<typename T>
    struct SizeTest {
        template<typename U> static char test(typename U::Size * = 0);
        template<typename U> static  int test(...);
        static constexpr bool value = (sizeof(test<T>(0)) == 1);
    };

    template<typename A, typename D, bool = SizeTest<A>::value>
    struct SizeBase {
        using Type = MakeUnsigned<D>;
    };

    template<typename A, typename D>
    struct SizeBase<A, D, true> {
        using Type = typename A::Size;
    };
} /* namespace detail */

/* allocator type traits */

template<typename A>
using AllocatorType = A;

template<typename A>
using AllocatorValue = typename AllocatorType<A>::Value;

template<typename A>
using AllocatorPointer = typename detail::PointerType<
    AllocatorValue<A>, AllocatorType<A>
>::Type;

template<typename A>
using AllocatorConstPointer = typename detail::ConstPointer<
    AllocatorValue<A>, AllocatorPointer<A>, AllocatorType<A>
>::Type;

template<typename A>
using AllocatorVoidPointer = typename detail::VoidPointer<
    AllocatorPointer<A>, AllocatorType<A>
>::Type;

template<typename A>
using AllocatorConstVoidPointer = typename detail::ConstVoidPointer<
    AllocatorPointer<A>, AllocatorType<A>
>::Type;

/* allocator difference */

namespace detail {
    template<typename T>
    struct DiffTest {
        template<typename U> static char test(typename U::Difference * = 0);
        template<typename U> static  int test(...);
        static constexpr bool value = (sizeof(test<T>(0)) == 1);
    };

    template<typename A, typename P, bool = DiffTest<A>::value>
    struct AllocDifference {
        using Type = PointerDifference<P>;
    };

    template<typename A, typename P>
    struct AllocDifference<A, P, true> {
        using Type = typename A::Difference;
    };
}

template<typename A>
using AllocatorDifference = typename detail::AllocDifference<
    A, AllocatorPointer<A>
>::Type;

/* allocator size */

template<typename A>
using AllocatorSize = typename detail::SizeBase<
    A, AllocatorDifference<A>
>::Type;

/* allocator rebind */

namespace detail {
    template<typename T, typename U, bool = detail::HasRebind<T, U>::value>
    struct AllocTraitsRebindType {
        using Type = typename T::template Rebind<U>;
    };

    template<template<typename, typename...> class A, typename T,
        typename ...Args, typename U
    >
    struct AllocTraitsRebindType<A<T, Args...>, U, true> {
        using Type = typename A<T, Args...>::template Rebind<U>;
    };

    template<template<typename, typename...> class A, typename T,
        typename ...Args, typename U
    >
    struct AllocTraitsRebindType<A<T, Args...>, U, false> {
        using Type = A<U, Args...>;
    };
} /* namespace detail */

template<typename A, typename T>
using AllocatorRebind = typename detail::AllocTraitsRebindType<
    AllocatorType<A>, T
>::Type;

/* allocator propagate on container copy assignment */

namespace detail {
    template<typename T>
    struct PropagateOnContainerCopyAssignmentTest {
        template<typename U> static char test(
            typename U::PropagateOnContainerCopyAssignment * = 0);
        template<typename U> static  int test(...);
        static constexpr bool value = (sizeof(test<T>(0)) == 1);
    };

    template<typename A, bool = PropagateOnContainerCopyAssignmentTest<
        A
    >::value> struct PropagateOnContainerCopyAssignmentBase {
        using Type = False;
    };

    template<typename A>
    struct PropagateOnContainerCopyAssignmentBase<A, true> {
        using Type = typename A::PropagateOnContainerCopyAssignment;
    };
} /* namespace detail */

template<typename A>
using AllocatorPropagateOnContainerCopyAssignment
    = typename detail::PropagateOnContainerCopyAssignmentBase<A>::Type;

/* allocator propagate on container move assignment */

namespace detail {
    template<typename T>
    struct PropagateOnContainerMoveAssignmentTest {
        template<typename U> static char test(
            typename U::PropagateOnContainerMoveAssignment * = 0);
        template<typename U> static  int test(...);
        static constexpr bool value = (sizeof(test<T>(0)) == 1);
    };

    template<typename A, bool = PropagateOnContainerMoveAssignmentTest<
        A
    >::value> struct PropagateOnContainerMoveAssignmentBase {
        using Type = False;
    };

    template<typename A>
    struct PropagateOnContainerMoveAssignmentBase<A, true> {
        using Type = typename A::PropagateOnContainerMoveAssignment;
    };
} /* namespace detail */

template<typename A>
using AllocatorPropagateOnContainerMoveAssignment
    = typename detail::PropagateOnContainerMoveAssignmentBase<A>::Type;

/* allocator propagate on container swap */

namespace detail {
    template<typename T>
    struct PropagateOnContainerSwapTest {
        template<typename U> static char test(
            typename U::PropagateOnContainerSwap * = 0);
        template<typename U> static  int test(...);
        static constexpr bool value = (sizeof(test<T>(0)) == 1);
    };

    template<typename A, bool = PropagateOnContainerSwapTest<A>::value>
    struct PropagateOnContainerSwapBase {
        using Type = False;
    };

    template<typename A>
    struct PropagateOnContainerSwapBase<A, true> {
        using Type = typename A::PropagateOnContainerSwap;
    };
} /* namespace detail */

template<typename A>
using AllocatorPropagateOnContainerSwap
    = typename detail::PropagateOnContainerSwapBase<A>::Type;

/* allocator is always equal */

namespace detail {
    template<typename T>
    struct IsAlwaysEqualTest {
        template<typename U> static char test(typename U::IsAlwaysEqual * = 0);
        template<typename U> static  int test(...);
        static constexpr bool value = (sizeof(test<T>(0)) == 1);
    };

    template<typename A, bool = IsAlwaysEqualTest<A>::value>
    struct IsAlwaysEqualBase {
        using Type = typename IsEmpty<A>::Type;
    };

    template<typename A>
    struct IsAlwaysEqualBase<A, true> {
        using Type = typename A::IsAlwaysEqual;
    };
} /* namespace detail */

template<typename A>
using AllocatorIsAlwaysEqual = typename detail::IsAlwaysEqualBase<A>::Type;

/* allocator allocate */

template<typename A>
inline AllocatorPointer<A>
allocator_allocate(A &a, AllocatorSize<A> n) {
    return a.allocate(n);
}

namespace detail {
    template<typename A, typename S, typename CVP>
    auto allocate_hint_test(A &&a, S &&sz, CVP &&p)
        -> decltype(a.allocate(sz, p), True());

    template<typename A, typename S, typename CVP>
    auto allocate_hint_test(const A &, S &&, CVP &&)
        -> False;

    template<typename A, typename S, typename CVP>
    struct AllocateHintTest: IntegralConstant<bool,
        IsSame<decltype(allocate_hint_test(declval<A>(),
                                           declval<S>(),
                                           declval<CVP>())), True
        >::value
    > {};

    template<typename A>
    inline AllocatorPointer<A> allocate(A &a, AllocatorSize<A> n,
                                         AllocatorConstVoidPointer<A> h,
                                         True) {
        return a.allocate(n, h);
    }

    template<typename A>
    inline AllocatorPointer<A> allocate(A &a, AllocatorSize<A> n,
                                         AllocatorConstVoidPointer<A>,
                                         False) {
        return a.allocate(n);
    }
} /* namespace detail */

template<typename A>
inline AllocatorPointer<A>
allocator_allocate(A &a, AllocatorSize<A> n,
                   AllocatorConstVoidPointer<A> h) {
    return detail::allocate(a, n, h,
        detail::AllocateHintTest<
            A, AllocatorSize<A>, AllocatorConstVoidPointer<A>
        >());
}

/* allocator deallocate */

template<typename A>
inline void allocator_deallocate(A &a, AllocatorPointer<A> p,
                                 AllocatorSize<A> n) {
    a.deallocate(p, n);
}

/* allocator construct */

namespace detail {
    template<typename A, typename T, typename ...Args>
    auto construct_test(A &&a, T *p, Args &&...args)
        -> decltype(a.construct(p, forward<Args>(args)...),
            True());

    template<typename A, typename T, typename ...Args>
    auto construct_test(const A &, T *, Args &&...)
        -> False;

    template<typename A, typename T, typename ...Args>
    struct ConstructTest: IntegralConstant<bool,
        IsSame< decltype(construct_test(declval<A>(),
                                       declval<T>(),
                                       declval<Args>()...)), True
        >::value
    > {};

    template<typename A, typename T, typename ...Args>
    inline void construct(True, A &a, T *p, Args &&...args) {
        a.construct(p, forward<Args>(args)...);
    }

    template<typename A, typename T, typename ...Args>
    inline void construct(False, A &, T *p, Args &&...args) {
        ::new ((void *)p) T(forward<Args>(args)...);
    }
} /* namespace detail */

template<typename A, typename T, typename ...Args>
inline void allocator_construct(A &a, T *p, Args &&...args) {
    detail::construct(detail::ConstructTest<A, T *, Args...>(), a, p,
        forward<Args>(args)...);
}

/* allocator destroy */

namespace detail {
    template<typename A, typename P>
    auto destroy_test(A &&a, P &&p) -> decltype(a.destroy(p), True());

    template<typename A, typename P>
    auto destroy_test(const A &, P &&) -> False;

    template<typename A, typename P>
    struct DestroyTest: IntegralConstant<bool,
        IsSame<decltype(destroy_test(declval<A>(), declval<P>())), True
        >::value
    > {};

    template<typename A, typename T>
    inline void destroy(True, A &a, T *p) {
        a.destroy(p);
    }

    template<typename A, typename T>
    inline void destroy(False, A &, T *p) {
        p->~T();
    }
} /* namespace detail */

template<typename A, typename T>
inline void allocator_destroy(A &a, T *p) {
    detail::destroy(detail::DestroyTest<A, T *>(), a, p);
}

/* allocator max size */

namespace detail {
    template<typename A>
    auto alloc_max_size_test(A &&a) -> decltype(a.max_size(), True());

    template<typename A>
    auto alloc_max_size_test(const A &) -> False;

    template<typename A>
    struct AllocMaxSizeTest: IntegralConstant<bool,
        IsSame<decltype(alloc_max_size_test(declval<A &>())), True
        >::value
    > {};

    template<typename A>
    inline AllocatorSize<A> alloc_max_size(True, const A &a) {
        return a.max_size();
    }

    template<typename A>
    inline AllocatorSize<A> alloc_max_size(False, const A &) {
        return AllocatorSize<A>(~0);
    }
} /* namespace detail */

template<typename A>
inline AllocatorSize<A> allocator_max_size(const A &a) {
    return detail::alloc_max_size(detail::AllocMaxSizeTest<const A>(), a);
}

/* allocator container copy */

namespace detail {
    template<typename A>
    auto alloc_copy_test(A &&a) -> decltype(a.container_copy(), True());

    template<typename A>
    auto alloc_copy_test(const A &) -> False;

    template<typename A>
    struct AllocCopyTest: IntegralConstant<bool,
        IsSame<decltype(alloc_copy_test(declval<A &>())), True
        >::value
    > {};

    template<typename A>
    inline AllocatorType<A> alloc_container_copy(True, const A &a) {
        return a.container_copy();
    }

    template<typename A>
    inline AllocatorType<A> alloc_container_copy(False, const A &a) {
        return a;
    }
} /* namespace detail */

template<typename A>
inline AllocatorType<A> allocator_container_copy(const A &a) {
    return detail::alloc_container_copy(detail::AllocCopyTest<
        const A
    >(), a);
}

/* allocator arg */

struct AllocatorArg {};

constexpr AllocatorArg allocator_arg = AllocatorArg();

/* uses allocator */

namespace detail {
    template<typename T> struct HasAllocatorType {
        template<typename U> static char test(typename U::Allocator *);
        template<typename U> static  int test(...);
        static constexpr bool value = (sizeof(test<T>(0)) == 1);
    };

    template<typename T, typename A, bool = HasAllocatorType<T>::value>
    struct UsesAllocatorBase: IntegralConstant<bool,
        IsConvertible<A, typename T::Allocator>::value
    > {};

    template<typename T, typename A>
    struct UsesAllocatorBase<T, A, false>: False {};
}

template<typename T, typename A>
struct UsesAllocator: detail::UsesAllocatorBase<T, A> {};

/* uses allocator ctor */

namespace detail {
    template<typename T, typename A, typename ...Args>
    struct UsesAllocCtor {
        static constexpr bool ua = UsesAllocator<T, A>::value;
        static constexpr bool ic = IsConstructible<
            T, AllocatorArg, A, Args...
        >::value;
        static constexpr int value = ua ? (2 - ic) : 0;
    };
}

template<typename T, typename A, typename ...Args>
struct UsesAllocatorConstructor: IntegralConstant<int,
    detail::UsesAllocCtor<T, A, Args...>::value
> {};

} /* namespace octa */

#endif
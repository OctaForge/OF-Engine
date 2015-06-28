/* Self-expanding dynamic array implementation for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_VECTOR_H
#define OCTA_VECTOR_H

#include <string.h>
#include <stddef.h>

#include "octa/type_traits.hh"
#include "octa/utility.hh"
#include "octa/range.hh"
#include "octa/algorithm.hh"
#include "octa/initializer_list.hh"
#include "octa/memory.hh"

namespace octa {

namespace detail {
} /* namespace detail */

template<typename T, typename A = octa::Allocator<T>>
class Vector {
    using VecPair = octa::detail::CompressedPair<octa::AllocatorPointer<A>, A>;

    octa::Size p_len, p_cap;
    VecPair p_buf;

    void insert_base(octa::Size idx, octa::Size n) {
        if (p_len + n > p_cap) reserve(p_len + n);
        p_len += n;
        for (octa::Size i = p_len - 1; i > idx + n - 1; --i) {
            p_buf.first()[i] = octa::move(p_buf.first()[i - n]);
        }
    }

    template<typename R>
    void ctor_from_range(R &range, octa::EnableIf<
        octa::IsFiniteRandomAccessRange<R>::value, bool
    > = true) {
        octa::RangeSize<R> l = range.size();
        reserve(l);
        p_len = l;
        if (octa::IsPod<T>() && octa::IsSame<T, octa::RangeValue<R>>()) {
            memcpy(p_buf.first(), &range.front(), range.size());
            return;
        }
        for (octa::Size i = 0; !range.empty(); range.pop_front()) {
            octa::allocator_construct(p_buf.second(),
                &p_buf.first()[i], range.front());
            ++i;
        }
    }

    template<typename R>
    void ctor_from_range(R &range, EnableIf<
        !octa::IsFiniteRandomAccessRange<R>::value, bool
    > = true) {
        octa::Size i = 0;
        for (; !range.empty(); range.pop_front()) {
            reserve(i + 1);
            octa::allocator_construct(p_buf.second(),
                &p_buf.first()[i], range.front());
            ++i;
            p_len = i;
        }
    }

    void copy_contents(const Vector &v) {
        if (octa::IsPod<T>()) {
            memcpy(p_buf.first(), v.p_buf.first(), p_len * sizeof(T));
        } else {
            Pointer cur = p_buf.first(), last = p_buf.first() + p_len;
            Pointer vbuf = v.p_buf.first();
            while (cur != last) {
                octa::allocator_construct(p_buf.second(),
                   cur++, *vbuf++);
            }
        }
    }

public:
    using Size = octa::Size;
    using Difference = octa::Ptrdiff;
    using Value = T;
    using Reference = T &;
    using ConstReference = const T &;
    using Pointer = octa::AllocatorPointer<A>;
    using ConstPointer = octa::AllocatorConstPointer<A>;
    using Range = octa::PointerRange<T>;
    using ConstRange = octa::PointerRange<const T>;
    using Allocator = A;

    Vector(const A &a = A()): p_len(0), p_cap(0), p_buf(nullptr, a) {}

    explicit Vector(Size n, const T &val = T(),
    const A &al = A()): Vector(al) {
        p_buf.first() = octa::allocator_allocate(p_buf.second(), n);
        p_len = p_cap = n;
        Pointer cur = p_buf.first(), last = p_buf.first() + n;
        while (cur != last)
            octa::allocator_construct(p_buf.second(), cur++, val);
    }

    Vector(const Vector &v): p_len(0), p_cap(0), p_buf(nullptr,
    octa::allocator_container_copy(v.p_buf.second())) {
        reserve(v.p_cap);
        p_len = v.p_len;
        copy_contents(v);
    }

    Vector(const Vector &v, const A &a): p_len(0), p_cap(0), p_buf(nullptr, a) {
        reserve(v.p_cap);
        p_len = v.p_len;
        copy_contents(v);
    }

    Vector(Vector &&v): p_len(v.p_len), p_cap(v.p_cap), p_buf(v.p_buf.first(),
    octa::move(v.p_buf.second())) {
        v.p_buf.first() = nullptr;
        v.p_len = v.p_cap = 0;
    }

    Vector(Vector &&v, const A &a): p_buf(nullptr, a) {
        if (a != v.p_buf.second()) {
            reserve(v.p_cap);
            p_len = v.p_len;
            if (octa::IsPod<T>()) {
                memcpy(p_buf.first(), v.p_buf.first(), p_len * sizeof(T));
            } else {
                Pointer cur = p_buf.first(), last = p_buf.first() + p_len;
                Pointer vbuf = v.p_buf.first();
                while (cur != last) {
                    octa::allocator_construct(p_buf.second(), cur++,
                        octa::move(*vbuf++));
                }
            }
            return;
        }
        p_buf.first() = v.p_buf.first();
        p_len = v.p_len;
        p_cap = v.p_cap;
        v.p_buf.first() = nullptr;
        v.p_len = v.p_cap = 0;
    }

    Vector(const Value *buf, Size n, const A &a = A()): Vector(a) {
        reserve(n);
        if (octa::IsPod<T>()) {
            memcpy(p_buf.first(), buf, n * sizeof(T));
        } else {
            for (Size i = 0; i < n; ++i)
                octa::allocator_construct(p_buf.second(),
                    &p_buf.first()[i], buf[i]);
        }
        p_len = n;
    }

    Vector(InitializerList<T> v, const A &a = A()):
        Vector(v.begin(), v.size(), a) {}

    template<typename R> Vector(R range, const A &a = A(),
        octa::EnableIf<
            octa::IsInputRange<R>::value &&
            octa::IsConvertible<RangeReference<R>, Value>::value,
            bool
        > = true
    ): Vector(a) {
        ctor_from_range(range);
    }

    ~Vector() {
        clear();
        octa::allocator_deallocate(p_buf.second(), p_buf.first(), p_cap);
    }

    void clear() {
        if (p_len > 0 && !octa::IsPod<T>()) {
            Pointer cur = p_buf.first(), last = p_buf.first() + p_len;
            while (cur != last)
                octa::allocator_destroy(p_buf.second(), cur++);
        }
        p_len = 0;
    }

    Vector &operator=(const Vector &v) {
        if (this == &v) return *this;
        clear();
        if (octa::AllocatorPropagateOnContainerCopyAssignment<A>::value) {
            if (p_buf.second() != v.p_buf.second()) {
                octa::allocator_deallocate(p_buf.second(), p_buf.first(), p_cap);
                p_cap = 0;
            }
            p_buf.second() = v.p_buf.second();
        }
        reserve(v.p_cap);
        p_len = v.p_len;
        copy_contents(v);
        return *this;
    }

    Vector &operator=(Vector &&v) {
        clear();
        octa::allocator_deallocate(p_buf.second(), p_buf.first(), p_cap);
        if (octa::AllocatorPropagateOnContainerMoveAssignment<A>::value)
            p_buf.second() = v.p_buf.second();
        p_len = v.p_len;
        p_cap = v.p_cap;
        p_buf.~VecPair();
        new (&p_buf) VecPair(v.disown(), octa::move(v.p_buf.second()));
        return *this;
    }

    Vector &operator=(InitializerList<T> il) {
        clear();
        Size ilen = il.end() - il.begin();
        reserve(ilen);
        if (octa::IsPod<T>()) {
            memcpy(p_buf.first(), il.begin(), ilen);
        } else {
            Pointer tbuf = p_buf.first(), ibuf = il.begin(),
                last = il.end();
            while (ibuf != last) {
                octa::allocator_construct(p_buf.second(),
                    tbuf++, *ibuf++);
            }
        }
        p_len = ilen;
        return *this;
    }

    template<typename R>
    octa::EnableIf<
        octa::IsInputRange<R>::value &&
        octa::IsConvertible<RangeReference<R>, Value>::value,
        Vector &
    > operator=(R range) {
        clear();
        ctor_from_range(range);
        return *this;
    }

    void resize(Size n, const T &v = T()) {
        Size l = p_len;
        reserve(n);
        p_len = n;
        if (octa::IsPod<T>()) {
            for (Size i = l; i < p_len; ++i) {
                p_buf.first()[i] = T(v);
            }
        } else {
            Pointer first = p_buf.first() + l;
            Pointer last  = p_buf.first() + p_len;
            while (first != last)
                octa::allocator_construct(p_buf.second(), first++, v);
        }
    }

    void reserve(Size n) {
        if (n <= p_cap) return;
        Size oc = p_cap;
        if (!oc) {
            p_cap = octa::max(n, Size(8));
        } else {
            while (p_cap < n) p_cap *= 2;
        }
        Pointer tmp = octa::allocator_allocate(p_buf.second(), p_cap);
        if (oc > 0) {
            if (octa::IsPod<T>()) {
                memcpy(tmp, p_buf.first(), p_len * sizeof(T));
            } else {
                Pointer cur = p_buf.first(), tcur = tmp,
                    last = tmp + p_len;
                while (tcur != last) {
                    octa::allocator_construct(p_buf.second(), tcur++,
                        octa::move(*cur));
                    octa::allocator_destroy(p_buf.second(), cur);
                    ++cur;
                }
            }
            octa::allocator_deallocate(p_buf.second(), p_buf.first(), oc);
        }
        p_buf.first() = tmp;
    }

    T &operator[](Size i) { return p_buf.first()[i]; }
    const T &operator[](Size i) const { return p_buf.first()[i]; }

    T &at(Size i) { return p_buf.first()[i]; }
    const T &at(Size i) const { return p_buf.first()[i]; }

    T &push(const T &v) {
        if (p_len == p_cap) reserve(p_len + 1);
        octa::allocator_construct(p_buf.second(),
            &p_buf.first()[p_len], v);
        return p_buf.first()[p_len++];
    }

    T &push() {
        if (p_len == p_cap) reserve(p_len + 1);
        octa::allocator_construct(p_buf.second(), &p_buf.first()[p_len]);
        return p_buf.first()[p_len++];
    }

    template<typename ...U>
    T &emplace_back(U &&...args) {
        if (p_len == p_cap) reserve(p_len + 1);
        octa::allocator_construct(p_buf.second(), &p_buf.first()[p_len],
            octa::forward<U>(args)...);
        return p_buf.first()[p_len++];
    }

    void pop() {
        if (!octa::IsPod<T>()) {
            octa::allocator_destroy(p_buf.second(),
                &p_buf.first()[--p_len]);
        } else {
            --p_len;
        }
    }

    T &front() { return p_buf.first()[0]; }
    const T &front() const { return p_buf.first()[0]; }

    T &back() { return p_buf.first()[p_len - 1]; }
    const T &back() const { return p_buf.first()[p_len - 1]; }

    Value *data() { return (Value *)p_buf.first(); }
    const Value *data() const { return (const Value *)p_buf.first(); }

    Size size() const { return p_len; }
    Size capacity() const { return p_cap; }

    Size max_size() const { return Size(~0) / sizeof(T); }

    bool empty() const { return (p_len == 0); }

    bool in_range(Size idx) { return idx < p_len; }
    bool in_range(int idx) { return idx >= 0 && Size(idx) < p_len; }
    bool in_range(const Value *ptr) {
        return ptr >= p_buf.first() && ptr < &p_buf.first()[p_len];
    }

    Value *disown() {
        Pointer r = p_buf.first();
        p_buf.first() = nullptr;
        p_len = p_cap = 0;
        return (Value *)r;
    }

    Range insert(Size idx, T &&v) {
        insert_base(idx, 1);
        p_buf.first()[idx] = octa::move(v);
        return Range(&p_buf.first()[idx], &p_buf.first()[p_len]);
    }

    Range insert(Size idx, const T &v) {
        insert_base(idx, 1);
        p_buf.first()[idx] = v;
        return Range(&p_buf.first()[idx], &p_buf.first()[p_len]);
    }

    Range insert(Size idx, Size n, const T &v) {
        insert_base(idx, n);
        for (Size i = 0; i < n; ++i) {
            p_buf.first()[idx + i] = v;
        }
        return Range(&p_buf.first()[idx], &p_buf.first()[p_len]);
    }

    template<typename U>
    Range insert_range(Size idx, U range) {
        Size l = range.size();
        insert_base(idx, l);
        for (Size i = 0; i < l; ++i) {
            p_buf.first()[idx + i] = range.front();
            range.pop_front();
        }
        return Range(&p_buf.first()[idx], &p_buf.first()[p_len]);
    }

    Range insert(Size idx, InitializerList<T> il) {
        return insert_range(idx, octa::iter(il));
    }

    Range iter() {
        return Range(p_buf.first(), p_buf.first() + p_len);
    }
    ConstRange iter() const {
        return ConstRange(p_buf.first(), p_buf.first() + p_len);
    }
    ConstRange citer() const {
        return ConstRange(p_buf.first(), p_buf.first() + p_len);
    }

    void swap(Vector &v) {
        octa::swap(p_len, v.p_len);
        octa::swap(p_cap, v.p_cap);
        octa::swap(p_buf.first(), v.p_buf.first());
        if (octa::AllocatorPropagateOnContainerSwap<A>::value)
            octa::swap(p_buf.second(), v.p_buf.second());
    }

    A get_allocator() const {
        return p_buf.second();
    }
};

} /* namespace octa */

#endif
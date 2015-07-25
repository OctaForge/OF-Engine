/* Self-expanding dynamic array implementation for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OSTD_VECTOR_HH
#define OSTD_VECTOR_HH

#include <string.h>
#include <stddef.h>

#include "ostd/type_traits.hh"
#include "ostd/utility.hh"
#include "ostd/range.hh"
#include "ostd/algorithm.hh"
#include "ostd/initializer_list.hh"
#include "ostd/memory.hh"

namespace ostd {

template<typename T, typename A = Allocator<T>>
class Vector {
    using VecPair = detail::CompressedPair<AllocatorPointer<A>, A>;

    ostd::Size p_len, p_cap;
    VecPair p_buf;

    void insert_base(Size idx, Size n) {
        if (p_len + n > p_cap) reserve(p_len + n);
        p_len += n;
        for (Size i = p_len - 1; i > idx + n - 1; --i) {
            p_buf.first()[i] = move(p_buf.first()[i - n]);
        }
    }

    template<typename R>
    void ctor_from_range(R &range, EnableIf<
        IsFiniteRandomAccessRange<R>::value &&
        IsPod<T>::value &&
        IsSame<T, RemoveCv<RangeValue<R>>>::value, bool
    > = true) {
        RangeSize<R> l = range.size();
        reserve(l);
        p_len = l;
        range.copy(p_buf.first(), l);
    }

    template<typename R>
    void ctor_from_range(R &range, EnableIf<
        !IsFiniteRandomAccessRange<R>::value ||
        !IsPod<T>::value ||
        !IsSame<T, RemoveCv<RangeValue<R>>>::value, bool
    > = true) {
        Size i = 0;
        for (; !range.empty(); range.pop_front()) {
            reserve(i + 1);
            allocator_construct(p_buf.second(), &p_buf.first()[i],
                range.front());
            ++i;
            p_len = i;
        }
    }

    void copy_contents(const Vector &v) {
        if (IsPod<T>()) {
            memcpy(p_buf.first(), v.p_buf.first(), p_len * sizeof(T));
        } else {
            Pointer cur = p_buf.first(), last = p_buf.first() + p_len;
            Pointer vbuf = v.p_buf.first();
            while (cur != last) {
                allocator_construct(p_buf.second(), cur++, *vbuf++);
            }
        }
    }

public:
    using Size = ostd::Size;
    using Difference = Ptrdiff;
    using Value = T;
    using Reference = T &;
    using ConstReference = const T &;
    using Pointer = AllocatorPointer<A>;
    using ConstPointer = AllocatorConstPointer<A>;
    using Range = PointerRange<T>;
    using ConstRange = PointerRange<const T>;
    using Allocator = A;

    Vector(const A &a = A()): p_len(0), p_cap(0), p_buf(nullptr, a) {}

    explicit Vector(Size n, const T &val = T(),
    const A &al = A()): Vector(al) {
        if (!n) return;
        p_buf.first() = allocator_allocate(p_buf.second(), n);
        p_len = p_cap = n;
        Pointer cur = p_buf.first(), last = p_buf.first() + n;
        while (cur != last)
            allocator_construct(p_buf.second(), cur++, val);
    }

    Vector(const Vector &v): p_len(0), p_cap(0), p_buf(nullptr,
    allocator_container_copy(v.p_buf.second())) {
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
    move(v.p_buf.second())) {
        v.p_buf.first() = nullptr;
        v.p_len = v.p_cap = 0;
    }

    Vector(Vector &&v, const A &a): p_len(0), p_cap(0), p_buf(nullptr, a) {
        if (a != v.p_buf.second()) {
            reserve(v.p_cap);
            p_len = v.p_len;
            if (IsPod<T>()) {
                memcpy(p_buf.first(), v.p_buf.first(), p_len * sizeof(T));
            } else {
                Pointer cur = p_buf.first(), last = p_buf.first() + p_len;
                Pointer vbuf = v.p_buf.first();
                while (cur != last) {
                    allocator_construct(p_buf.second(), cur++, move(*vbuf++));
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

    Vector(ConstRange r, const A &a = A()): Vector(a) {
        reserve(r.size());
        if (IsPod<T>()) {
            memcpy(p_buf.first(), &r[0], r.size() * sizeof(T));
        } else {
            for (Size i = 0; i < r.size(); ++i)
                allocator_construct(p_buf.second(), &p_buf.first()[i], r[i]);
        }
        p_len = r.size();
    }

    Vector(InitializerList<T> v, const A &a = A()):
        Vector(ConstRange(v.begin(), v.size()), a) {}

    template<typename R, typename = EnableIf<
        IsInputRange<R>::value &&
        IsConvertible<RangeReference<R>, Value>::value
    >> Vector(R range, const A &a = A()): Vector(a) {
        ctor_from_range(range);
    }

    ~Vector() {
        clear();
        allocator_deallocate(p_buf.second(), p_buf.first(), p_cap);
    }

    void clear() {
        if (p_len > 0 && !IsPod<T>()) {
            Pointer cur = p_buf.first(), last = p_buf.first() + p_len;
            while (cur != last)
                allocator_destroy(p_buf.second(), cur++);
        }
        p_len = 0;
    }

    Vector &operator=(const Vector &v) {
        if (this == &v) return *this;
        clear();
        if (AllocatorPropagateOnContainerCopyAssignment<A>::value) {
            if (p_buf.second() != v.p_buf.second() && p_cap) {
                allocator_deallocate(p_buf.second(), p_buf.first(), p_cap);
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
        if (p_buf.first())
            allocator_deallocate(p_buf.second(), p_buf.first(), p_cap);
        if (AllocatorPropagateOnContainerMoveAssignment<A>::value)
            p_buf.second() = v.p_buf.second();
        p_len = v.p_len;
        p_cap = v.p_cap;
        p_buf.~VecPair();
        new (&p_buf) VecPair(v.disown(), move(v.p_buf.second()));
        return *this;
    }

    Vector &operator=(InitializerList<T> il) {
        clear();
        Size ilen = il.end() - il.begin();
        reserve(ilen);
        if (IsPod<T>()) {
            memcpy(p_buf.first(), il.begin(), ilen);
        } else {
            Pointer tbuf = p_buf.first(), ibuf = il.begin(),
                last = il.end();
            while (ibuf != last) {
                allocator_construct(p_buf.second(),
                    tbuf++, *ibuf++);
            }
        }
        p_len = ilen;
        return *this;
    }

    template<typename R, typename = EnableIf<
        IsInputRange<R>::value &&
        IsConvertible<RangeReference<R>, Value>::value
    >> Vector &operator=(R range) {
        clear();
        ctor_from_range(range);
        return *this;
    }

    void resize(Size n, const T &v = T()) {
        if (!n) {
            clear();
            return;
        }
        Size l = p_len;
        reserve(n);
        p_len = n;
        if (IsPod<T>()) {
            for (Size i = l; i < p_len; ++i) {
                p_buf.first()[i] = T(v);
            }
        } else {
            Pointer first = p_buf.first() + l;
            Pointer last  = p_buf.first() + p_len;
            while (first != last)
                allocator_construct(p_buf.second(), first++, v);
        }
    }

    void reserve(Size n) {
        if (n <= p_cap) return;
        Size oc = p_cap;
        if (!oc) {
            p_cap = max(n, Size(8));
        } else {
            while (p_cap < n) p_cap *= 2;
        }
        Pointer tmp = allocator_allocate(p_buf.second(), p_cap);
        if (oc > 0) {
            if (IsPod<T>()) {
                memcpy(tmp, p_buf.first(), p_len * sizeof(T));
            } else {
                Pointer cur = p_buf.first(), tcur = tmp,
                    last = tmp + p_len;
                while (tcur != last) {
                    allocator_construct(p_buf.second(), tcur++, move(*cur));
                    allocator_destroy(p_buf.second(), cur);
                    ++cur;
                }
            }
            allocator_deallocate(p_buf.second(), p_buf.first(), oc);
        }
        p_buf.first() = tmp;
    }

    T &operator[](Size i) { return p_buf.first()[i]; }
    const T &operator[](Size i) const { return p_buf.first()[i]; }

    T *at(Size i) {
        if (!in_range(i)) return nullptr;
        return &p_buf.first()[i];
    }
    const T *at(Size i) const {
        if (!in_range(i)) return nullptr;
        return &p_buf.first()[i];
    }

    T &push(const T &v) {
        if (p_len == p_cap) reserve(p_len + 1);
        allocator_construct(p_buf.second(), &p_buf.first()[p_len], v);
        return p_buf.first()[p_len++];
    }

    T &push(T &&v) {
        if (p_len == p_cap) reserve(p_len + 1);
        allocator_construct(p_buf.second(), &p_buf.first()[p_len], move(v));
        return p_buf.first()[p_len++];
    }

    T &push() {
        if (p_len == p_cap) reserve(p_len + 1);
        allocator_construct(p_buf.second(), &p_buf.first()[p_len]);
        return p_buf.first()[p_len++];
    }

    template<typename ...U>
    T &emplace_back(U &&...args) {
        if (p_len == p_cap) reserve(p_len + 1);
        allocator_construct(p_buf.second(), &p_buf.first()[p_len],
            forward<U>(args)...);
        return p_buf.first()[p_len++];
    }

    void pop() {
        if (!IsPod<T>()) {
            allocator_destroy(p_buf.second(), &p_buf.first()[--p_len]);
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
        p_buf.first()[idx] = move(v);
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
        return insert_range(idx, ostd::iter(il));
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

    Range iter_cap() {
        return Range(p_buf.first(), p_buf.first() + p_cap);
    }

    void swap(Vector &v) {
        detail::swap_adl(p_len, v.p_len);
        detail::swap_adl(p_cap, v.p_cap);
        detail::swap_adl(p_buf.first(), v.p_buf.first());
        if (AllocatorPropagateOnContainerSwap<A>::value)
            detail::swap_adl(p_buf.second(), v.p_buf.second());
    }

    A get_allocator() const {
        return p_buf.second();
    }
};

template<typename T, typename A>
inline bool operator==(const Vector<T, A> &x, const Vector<T, A> &y) {
    return equal(x.iter(), y.iter());
}

template<typename T, typename A>
inline bool operator!=(const Vector<T, A> &x, const Vector<T, A> &y) {
    return !(x == y);
}

template<typename T, typename A>
inline bool operator<(const Vector<T, A> &x, const Vector<T, A> &y) {
    using Range = typename Vector<T, A>::Range;
    Range range1 = x.iter(), range2 = y.iter();
    while (!range1.empty() && !range2.empty()) {
        if (range1.front() < range2.front()) return true;
        if (range2.front() < range1.front()) return false;
        range1.pop_front();
        range2.pop_front();
    }
    return (range1.empty() && !range2.empty());
}

template<typename T, typename A>
inline bool operator>(const Vector<T, A> &x, const Vector<T, A> &y) {
    return (y < x);
}

template<typename T, typename A>
inline bool operator<=(const Vector<T, A> &x, const Vector<T, A> &y) {
    return !(y < x);
}

template<typename T, typename A>
inline bool operator>=(const Vector<T, A> &x, const Vector<T, A> &y) {
    return !(x < y);
}

} /* namespace ostd */

#endif
/* String for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OSTD_STRING_HH
#define OSTD_STRING_HH

#include <stdio.h>
#include <stddef.h>

#include "ostd/utility.hh"
#include "ostd/range.hh"
#include "ostd/vector.hh"

namespace ostd {
static constexpr Size npos = -1;

template<typename T, typename A = Allocator<T>> class StringBase;

template<typename T>
struct StringRangeBase: InputRange<
    StringRangeBase<T>, FiniteRandomAccessRangeTag, T
> {
    StringRangeBase() = delete;
    StringRangeBase(T *beg, T *end): p_beg(beg), p_end(end) {}
    StringRangeBase(T *beg, Size n): p_beg(beg), p_end(beg + n) {}
    /* TODO: traits for utf-16/utf-32 string lengths, for now assume char */
    StringRangeBase(T *beg): p_beg(beg), p_end(beg + strlen(beg)) {}

    template<typename A>
    StringRangeBase(const StringBase<T, A> &s): p_beg(s.data()),
        p_end(s.data() + s.size()) {}

    template<typename U, typename = EnableIf<
        IsConvertible<U *, T *>::value
    >> StringRangeBase(const StringRangeBase<U> &v):
        p_beg(&v[0]), p_end(&v[v.size()]) {}

    StringRangeBase &operator=(const StringRangeBase &v) {
        p_beg = v.p_beg; p_end = v.p_end; return *this;
    }

    template<typename A>
    StringRangeBase &operator=(const StringBase<T, A> &s) {
        p_beg = s.data(); p_end = s.data() + s.size(); return *this;
    }
    /* TODO: traits for utf-16/utf-32 string lengths, for now assume char */
    StringRangeBase &operator=(T *s) {
        p_beg = s; p_end = s + strlen(s); return *this;
    }

    bool empty() const { return p_beg == p_end; }

    bool pop_front() {
        if (p_beg == p_end) return false;
        ++p_beg;
        return true;
    }
    bool push_front() { --p_beg; return true; }

    Size pop_front_n(Size n) {
        Size olen = p_end - p_beg;
        p_beg += n;
        if (p_beg > p_end) {
            p_beg = p_end;
            return olen;
        }
        return n;
    }

    Size push_front_n(Size n) { p_beg -= n; return true; }

    T &front() const { return *p_beg; }

    bool equals_front(const StringRangeBase &range) const {
        return p_beg == range.p_beg;
    }

    Ptrdiff distance_front(const StringRangeBase &range) const {
        return range.p_beg - p_beg;
    }

    bool pop_back() {
        if (p_end == p_beg) return false;
        --p_end;
        return true;
    }
    bool push_back() { ++p_end; return true; }

    Size pop_back_n(Size n) {
        Size olen = p_end - p_beg;
        p_end -= n;
        if (p_end < p_beg) {
            p_end = p_beg;
            return olen;
        }
        return n;
    }

    Size push_back_n(Size n) { p_end += n; return true; }

    T &back() const { return *(p_end - 1); }

    bool equals_back(const StringRangeBase &range) const {
        return p_end == range.p_end;
    }

    Ptrdiff distance_back(const StringRangeBase &range) const {
        return range.p_end - p_end;
    }

    Size size() const { return p_end - p_beg; }

    StringRangeBase slice(Size start, Size end) const {
        return StringRangeBase(p_beg + start, p_beg + end);
    }

    T &operator[](Size i) const { return p_beg[i]; }

    bool put(T v) {
        if (empty()) return false;
        *(p_beg++) = v;
        return true;
    }

    /* non-range methods */
    T *data() { return p_beg; }
    const T *data() const { return p_beg; }

    Size to_hash() const {
        const T *d = data();
        Size h = 5381, len = size();
        for (Size i = 0; i < len; ++i)
            h = ((h << 5) + h) ^ d[i];
        return h;
    }

private:
    T *p_beg, *p_end;
};

template<typename T, typename A>
class StringBase {
    using StrPair = detail::CompressedPair<AllocatorPointer<A>, A>;

    ostd::Size p_len, p_cap;
    StrPair p_buf;

    template<typename R>
    void ctor_from_range(R &range, EnableIf<
        IsFiniteRandomAccessRange<R>::value &&
        IsSame<T, RemoveCv<RangeValue<R>>>::value, bool
    > = true) {
        if (range.empty()) return;
        RangeSize<R> l = range.size();
        reserve(l);
        p_len = l;
        range.copy(p_buf.first(), l);
        p_buf.first()[l] = '\0';
    }

    template<typename R>
    void ctor_from_range(R &range, EnableIf<
        !IsFiniteRandomAccessRange<R>::value ||
        !IsSame<T, RemoveCv<RangeValue<R>>>::value, bool
    > = true) {
        if (range.empty()) return;
        Size i = 0;
        for (; !range.empty(); range.pop_front()) {
            reserve(i + 1);
            allocator_construct(p_buf.second(), &p_buf.first()[i],
                range.front());
            ++i;
            p_len = i;
        }
        p_buf.first()[p_len] = '\0';
    }

public:
    using Size = ostd::Size;
    using Difference = Ptrdiff;
    using Value = T;
    using Reference = T &;
    using ConstReference = const T &;
    using Pointer = AllocatorPointer<A>;
    using ConstPointer = AllocatorConstPointer<A>;
    using Range = StringRangeBase<T>;
    using ConstRange = StringRangeBase<const T>;
    using Allocator = A;

    StringBase(const A &a = A()): p_len(0), p_cap(0),
        p_buf((Pointer)&p_len, a) {}

    explicit StringBase(Size n, T val = T(), const A &al = A()):
    StringBase(al) {
        if (!n) return;
        p_buf.first() = allocator_allocate(p_buf.second(), n + 1);
        p_len = p_cap = n;
        Pointer cur = p_buf.first(), last = p_buf.first() + n;
        while (cur != last) *cur++ = val;
        *cur = '\0';
    }

    StringBase(const StringBase &s): p_len(0), p_cap(0),
    p_buf((Pointer)&p_len, allocator_container_copy(s.p_buf.second())) {
        if (!s.p_len) return;
        reserve(s.p_len);
        p_len = s.p_len;
        memcpy(p_buf.first(), s.p_buf.first(), (p_len + 1) * sizeof(T));
    }
    StringBase(const StringBase &s, const A &a): p_len(0), p_cap(0),
    p_buf((Pointer)&p_len, a) {
        if (!s.p_len) return;
        reserve(s.p_len);
        p_len = s.p_len;
        memcpy(p_buf.first(), s.p_buf.first(), (p_len + 1) * sizeof(T));
    }
    StringBase(StringBase &&s): p_len(s.p_len), p_cap(s.p_cap),
    p_buf(s.p_buf.first(), move(s.p_buf.second())) {
        s.p_len = s.p_cap = 0;
        s.p_buf.first() = (Pointer)&s.p_len;
    }
    StringBase(StringBase &&s, const A &a): p_len(0), p_cap(0),
    p_buf((Pointer)&p_len, a) {
        if (!s.p_len) return;
        if (a != s.p_buf.second()) {
            reserve(s.p_cap);
            p_len = s.p_len;
            memcpy(p_buf.first(), s.p_buf.first(), (p_len + 1) * sizeof(T));
            return;
        }
        p_buf.first() = s.p_buf.first();
        p_len = s.p_len;
        p_cap = s.p_cap;
        s.p_len = s.p_cap = 0;
        s.p_buf.first() = &s.p_cap;
    }

    StringBase(const StringBase &s, Size pos, Size len = npos,
    const A &a = A()): StringBase(a) {
        Size end = (len == npos) ? s.size() : (pos + len);
        Size nch = (end - pos);
        reserve(nch);
        memcpy(p_buf.first(), s.p_buf.first() + pos, nch);
        p_len += nch;
        p_buf.first()[p_len] = '\0';
    }

    /* TODO: traits for utf-16/utf-32 string lengths, for now assume char */
    StringBase(const Value *v, const A &a = A()): StringBase(a) {
        Size len = strlen(v);
        if (!len) return;
        reserve(len);
        memcpy(p_buf.first(), v, len + 1);
        p_len = len;
    }

    StringBase(const Value *v, Size n, const A &a = A()): StringBase(a) {
        if (!n) return;
        reserve(n);
        memcpy(p_buf.first(), v, n);
        p_buf.first()[n] = '\0';
    }

    template<typename R, typename = EnableIf<
        IsInputRange<R>::value &&
        IsConvertible<RangeReference<R>, Value>::value
    >> StringBase(R range, const A &a = A()): StringBase(a) {
        ctor_from_range(range);
    }

    void clear() {
        p_len = 0;
        *p_buf.first() = '\0';
    }

    StringBase &operator=(const StringBase &v) {
        if (this == &v) return *this;
        clear();
        if (AllocatorPropagateOnContainerCopyAssignment<A>::value) {
            if ((p_buf.second() != v.p_buf.second()) && p_cap) {
                allocator_deallocate(p_buf.second(), p_buf.first(), p_cap);
                p_cap = 0;
                p_buf.first() = &p_len;
            }
            p_buf.second() = v.p_buf.second();
        }
        reserve(v.p_cap);
        p_len = v.p_len;
        if (p_len) {
            memcpy(p_buf.first(), v.p_buf.first(), p_len);
            p_buf.first()[p_len] = '\0';
        } else p_buf.first() = &p_len;
        return *this;
    }
    StringBase &operator=(StringBase &&v) {
        clear();
        if (p_cap) allocator_deallocate(p_buf.second(), p_buf.first(), p_cap);
        if (AllocatorPropagateOnContainerMoveAssignment<A>::value)
            p_buf.second() = v.p_buf.second();
        p_len = v.p_len;
        p_cap = v.p_cap;
        p_buf.~StrPair();
        new (&p_buf) StrPair(v.disown(), move(v.p_buf.second()));
        if (!p_cap) p_buf.first() = &p_len;
        return *this;
    }
    StringBase &operator=(const Value *v) {
        Size len = strlen(v);
        reserve(len);
        if (len) memcpy(p_buf.first(), v, len);
        p_buf.first()[len] = '\0';
        return *this;
    }
    template<typename R, typename = EnableIf<
        IsInputRange<R>::value &&
        IsConvertible<RangeReference<R>, Value>::value
    >> StringBase &operator=(const R &r) {
        clear();
        ctor_from_range(r);
        return *this;
    }

    void resize(Size n, T v = T()) {
        if (!n) {
            clear();
            return;
        }
        Size l = p_len;
        reserve(n);
        p_len = n;
        for (Size i = l; i < p_len; ++i) {
            p_buf.first()[i] = T(v);
        }
        p_buf.first()[l] = '\0';
    }

    void reserve(Size n) {
        if (n <= p_cap) return;
        Size oc = p_cap;
        if (!oc) {
            p_cap = max(n, Size(8));
        } else {
            while (p_cap < n) p_cap *= 2;
        }
        Pointer tmp = allocator_allocate(p_buf.second(), p_cap + 1);
        if (oc > 0) {
            memcpy(tmp, p_buf.first(), (p_len + 1) * sizeof(T));
            allocator_deallocate(p_buf.second(), p_buf.first(), oc + 1);
        }
        tmp[p_len] = '\0';
        p_buf.first() = tmp;
    }

    T &operator[](Size i) { return p_buf[i]; }
    const T &operator[](Size i) const { return p_buf[i]; }

    T &at(Size i) { return p_buf[i]; }
    const T &at(Size i) const { return p_buf[i]; }

    T &front() { return p_buf[0]; }
    const T &front() const { return p_buf[0]; };

    T &back() { return p_buf[size() - 1]; }
    const T &back() const { return p_buf[size() - 1]; }

    Value *data() { return p_buf.first(); }
    const Value *data() const { return p_buf.first(); }

    Size size() const {
        return p_len;
    }

    Size capacity() const {
        return p_cap;
    }

    Size length() const {
        /* TODO: unicode */
        return size();
    }

    bool empty() const { return (size() == 0); }

    void push(T v) {
        reserve(p_len + 1);
        p_buf.first()[p_len++] = v;
        p_buf.first()[p_len] = '\0';
    }

    StringBase &append(const StringBase &s) {
        reserve(p_len + s.p_len);
        if (!s.p_len) return *this;
        memcpy(p_buf.first() + p_len, s.p_buf.first(), s.p_len);
        p_len += s.p_len;
        p_buf.first()[p_len] = '\0';
        return *this;
    }

    StringBase &append(const StringBase &s, Size idx, Size len) {
        if (!s.p_len) return;
        Size end = (len == npos) ? s.size() : (idx + len);
        Size nch = (end - idx);
        if (!nch) return;
        reserve(p_len + nch);
        memcpy(p_buf.first() + p_len, s.p_buf.first() + idx, nch);
        p_len += nch;
        p_buf.first()[p_len] = '\0';
        return *this;
    }

    StringBase &append(const Value *s) {
        Size len = strlen(s);
        reserve(p_len + len);
        if (!len) return *this;
        memcpy(p_buf.first() + p_len, s, len);
        p_len += len;
        p_buf.first()[p_len] = '\0';
        return *this;
    }

    StringBase &append(Size n, T c) {
        if (!n) return;
        reserve(p_len + n);
        for (Size i = 0; i < n; ++n) p_buf.first()[p_len + i] = c;
        p_len += n;
        p_buf.first()[p_len] = '\0';
        return *this;
    }

    template<typename R>
    StringBase &append_range(R range) {
        Size nadd = 0;
        for (; !range.empty(); range.pop_front()) {
            reserve(p_len + nadd + 1);
            p_buf.first()[p_len + nadd++] = range.front(); 
        }
        p_len += nadd;
        p_buf.first()[p_len] = '\0';
        return *this;
    }

    StringBase &operator+=(const StringBase &s) {
        return append(s);
    }
    StringBase &operator+=(const Value *s) {
        return append(s);
    }
    StringBase &operator+=(T c) {
        reserve(p_len + 1);
        p_buf.first()[p_len++] = c;
        p_buf.first()[p_len] = '\0';
        return *this;
    }

    int compare(const StringBase &s) const {
        return strcmp(p_buf.first(), s.data());
    }

    int compare(const Value *p) const {
        return strcmp(p_buf.first(), p);
    }

    Range iter() {
        return Range(p_buf.first(), size());
    }
    ConstRange iter() const {
        return ConstRange(p_buf.first(), size());
    }
    ConstRange citer() const {
        return ConstRange(p_buf.dfirst(), size());
    }

    Range iter_cap() {
        return Range(p_buf.first(), capacity());
    }

    void swap(StringBase &v) {
        detail::swap_adl(p_len, v.p_len);
        detail::swap_adl(p_cap, v.p_cap);
        detail::swap_adl(p_buf.first(), v.p_buf.first());
        if (AllocatorPropagateOnContainerSwap<A>::value)
            detail::swap_adl(p_buf.second(), v.p_buf.second());
    }

    Size to_hash() const {
        return iter().to_hash();
    }

    A get_allocator() const {
        return p_buf.second();
    }
};

using String = StringBase<char>;
using StringRange = StringRangeBase<char>;
using ConstStringRange = StringRangeBase<const char>;

template<typename A> using AnyString = StringBase<char, A>;

template<typename T, typename A>
inline bool operator==(const StringBase<T, A> &lhs,
                       const StringBase<T, A> &rhs) {
    return !lhs.compare(rhs);
}
template<typename T, typename A>
inline bool operator==(const StringBase<T, A> &lhs, const char *rhs) {
    return !lhs.compare(rhs);
}
template<typename T, typename A>
inline bool operator==(const char *lhs, const StringBase<T, A> &rhs) {
    return !rhs.compare(lhs);
}

template<typename T, typename A>
inline bool operator!=(const StringBase<T, A> &lhs,
                       const StringBase<T, A> &rhs) {
    return !(lhs == rhs);
}
template<typename T, typename A>
inline bool operator!=(const StringBase<T, A> &lhs, const char *rhs) {
    return !(lhs == rhs);
}
template<typename T, typename A>
inline bool operator!=(const char *lhs,  const StringBase<T, A> &rhs) {
    return !(rhs == lhs);
}

template<typename T, typename A>
inline bool operator<(const StringBase<T, A> &lhs,
                      const StringBase<T, A> &rhs) {
    return lhs.compare(rhs) < 0;
}
template<typename T, typename A>
inline bool operator<(const StringBase<T, A> &lhs, const char *rhs) {
    return lhs.compare(rhs) < 0;
}
template<typename T, typename A>
inline bool operator<(const char *lhs, const StringBase<T, A> &rhs) {
    return rhs.compare(lhs) > 0;
}

template<typename T, typename A>
inline bool operator>(const StringBase<T, A> &lhs,
                      const StringBase<T, A> &rhs) {
    return rhs < lhs;
}
template<typename T, typename A>
inline bool operator>(const StringBase<T, A> &lhs, const char *rhs) {
    return rhs < lhs;
}
template<typename T, typename A>
inline bool operator>(const char *lhs, const StringBase<T, A> &rhs) {
    return rhs < lhs;
}

template<typename T, typename A>
inline bool operator<=(const StringBase<T, A> &lhs,
                       const StringBase<T, A> &rhs) {
    return !(rhs < lhs);
}
template<typename T, typename A>
inline bool operator<=(const StringBase<T, A> &lhs, const char *rhs) {
    return !(rhs < lhs);
}
template<typename T, typename A>
inline bool operator<=(const char *lhs, const StringBase<T, A> &rhs) {
    return !(rhs < lhs);
}

template<typename T, typename A>
inline bool operator>=(const StringBase<T, A> &lhs,
                       const StringBase<T, A> &rhs) {
    return !(lhs < rhs);
}
template<typename T, typename A>
inline bool operator>=(const StringBase<T, A> &lhs, const char *rhs) {
    return !(lhs < rhs);
}
template<typename T, typename A>
inline bool operator>=(const char *lhs, const StringBase<T, A> &rhs) {
    return !(lhs < rhs);
}

template<typename A, typename T, typename F, typename S = const char *>
AnyString<A> concat(AllocatorArg, const A &alloc, const T &v, const S &sep,
                    F func) {
    AnyString<A> ret(alloc);
    auto range = ostd::iter(v);
    if (range.empty()) return ret;
    for (;;) {
        ret += func(range.front());
        range.pop_front();
        if (range.empty()) break;
        ret += sep;
    }
    return ret;
}

template<typename A, typename T, typename S = const char *>
AnyString<A> concat(AllocatorArg, const A &alloc, const T &v,
                    const S &sep = " ") {
    AnyString<A> ret(alloc);
    auto range = ostd::iter(v);
    if (range.empty()) return ret;
    for (;;) {
        ret += range.front();
        range.pop_front();
        if (range.empty()) break;
        ret += sep;
    }
    return ret;
}

template<typename T, typename F, typename S = const char *>
String concat(const T &v, const S &sep, F func) {
    return concat(allocator_arg, typename String::Allocator(), v, sep, func);
}

template<typename T, typename S = const char *>
String concat(const T &v, const S &sep = " ") {
    return concat(allocator_arg, typename String::Allocator(), v, sep);
}

template<typename A, typename T, typename F, typename S = const char *>
AnyString<A> concat(AllocatorArg, const A &alloc,
                    std::initializer_list<T> v, const S &sep, F func) {
    return concat(allocator_arg, alloc, ostd::iter(v), sep, func);
}

template<typename A, typename T, typename S = const char *>
AnyString<A> concat(AllocatorArg, const A &alloc,
                    std::initializer_list<T> v, const S &sep = " ") {
    return concat(allocator_arg, alloc, ostd::iter(v), sep);
}

template<typename T, typename F, typename S = const char *>
String concat(std::initializer_list<T> v, const S &sep, F func) {
    return concat(ostd::iter(v), sep, func);
}

template<typename T, typename S = const char *>
String concat(std::initializer_list<T> v, const S &sep = " ") {
    return concat(ostd::iter(v), sep);
}

namespace detail {
    template<typename T>
    auto test_tostring(int) ->
        decltype(IsSame<decltype(declval<T>().to_string()), String>());
    template<typename>
    False test_tostring(...);

    template<typename T>
    using ToStringTest = decltype(test_tostring<T>(0));

    template<typename T>
    True test_iterable(decltype(ostd::iter(declval<T>())) *);
    template<typename> static False test_iterable(...);

    template<typename T>
    using IterableTest = decltype(test_iterable<T>(0));
}

template<typename T, typename = void>
struct ToString;

template<typename T>
struct ToString<T, EnableIf<detail::IterableTest<T>::value>> {
    using Argument = RemoveCv<RemoveReference<T>>;
    using Result = String;

    String operator()(const T &v) const {
        String ret("{");
        ret += concat(ostd::iter(v), ", ", ToString<
            RemoveConst<RemoveReference<
                RangeReference<decltype(ostd::iter(v))>
            >>
        >());
        ret += "}";
        return ret;
    }
};

template<typename T>
struct ToString<T, EnableIf<detail::ToStringTest<T>::value>> {
    using Argument = RemoveCv<RemoveReference<T>>;
    using Result = String;

    String operator()(const T &v) const {
        return v.to_string();
    }
};

namespace detail {
    template<typename T>
    void str_printf(String &s, const char *fmt, T v) {
        char buf[256];
        int n = snprintf(buf, sizeof(buf), fmt, v);
        s.clear();
        s.reserve(n);
        if (n >= (int)sizeof(buf))
            snprintf(s.data(), n + 1, fmt, v);
        else if (n > 0)
            memcpy(s.data(), buf, n + 1);
        else {
            s.clear();
        }
        *((Size *)&s) = n;
    }
}

template<> struct ToString<bool> {
    using Argument = bool;
    using Result = String;
    String operator()(bool b) {
        return b ? "true" : "false";
    }
};

template<> struct ToString<char> {
    using Argument = char;
    using Result = String;
    String operator()(char c) {
        String ret;
        ret.push(c);
        return ret;
    }
};

#define OSTD_TOSTR_NUM(T, fmt) \
template<> struct ToString<T> { \
    using Argument = T; \
    using Result = String; \
    String operator()(T v) { \
        String ret; \
        detail::str_printf(ret, fmt, v); \
        return ret; \
    } \
};

OSTD_TOSTR_NUM(sbyte, "%d")
OSTD_TOSTR_NUM(int, "%d")
OSTD_TOSTR_NUM(int &, "%d")
OSTD_TOSTR_NUM(long, "%ld")
OSTD_TOSTR_NUM(float, "%f")
OSTD_TOSTR_NUM(double, "%f")

OSTD_TOSTR_NUM(byte, "%u")
OSTD_TOSTR_NUM(uint, "%u")
OSTD_TOSTR_NUM(ulong, "%lu")
OSTD_TOSTR_NUM(llong, "%lld")
OSTD_TOSTR_NUM(ullong, "%llu")
OSTD_TOSTR_NUM(ldouble, "%Lf")

#undef OSTD_TOSTR_NUM

template<typename T> struct ToString<T *> {
    using Argument = T *;
    using Result = String;
    String operator()(Argument v) {
        String ret;
        detail::str_printf(ret, "%p", v);
        return ret;
    }
};

template<> struct ToString<const char *> {
    using Argument = const char *;
    using Result = String;
    String operator()(const char *s) {
        return String(s);
    }
};

template<> struct ToString<char *> {
    using Argument = char *;
    using Result = String;
    String operator()(char *s) {
        return String(s);
    }
};

template<> struct ToString<String> {
    using Argument = String;
    using Result = String;
    String operator()(const Argument &s) {
        return s;
    }
};

template<> struct ToString<StringRange> {
    using Argument = StringRange;
    using Result = String;
    String operator()(const Argument &s) {
        return String(s);
    }
};

template<typename T, typename U> struct ToString<Pair<T, U>> {
    using Argument = Pair<T, U>;
    using Result = String;
    String operator()(const Argument &v) {
        String ret("{");
        ret += ToString<RemoveReference<RemoveCv<T>>>()(v.first);
        ret += ", ";
        ret += ToString<RemoveReference<RemoveCv<U>>>()(v.second);
        ret += "}";
        return ret;
    }
};

template<typename T>
typename ToString<T>::Result to_string(const T &v) {
    return ToString<RemoveReference<RemoveCv<T>>>()(v);
}

template<typename T>
String to_string(std::initializer_list<T> init) {
    return to_string(iter(init));
}

} /* namespace ostd */

#endif
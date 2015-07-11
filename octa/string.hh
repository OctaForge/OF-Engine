/* String for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_STRING_HH
#define OCTA_STRING_HH

#include <stdio.h>
#include <stddef.h>

#include "octa/utility.hh"
#include "octa/range.hh"
#include "octa/vector.hh"

namespace octa {
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
    Vector<T, A> p_buf;

    void terminate() {
        if (p_buf.empty() || (p_buf.back() != '\0')) p_buf.push('\0');
    }

public:
    using Size = octa::Size;
    using Difference = Ptrdiff;
    using Value = T;
    using Reference = T &;
    using ConstReference = const T &;
    using Pointer = AllocatorPointer<A>;
    using ConstPointer = AllocatorConstPointer<A>;
    using Range = StringRangeBase<T>;
    using ConstRange = StringRangeBase<const T>;
    using Allocator = A;

    StringBase(const A &a = A()): p_buf(1, '\0', a) {}

    StringBase(Size n, const T &val = T(), const A &al = A()):
        p_buf(n + 1, val, al) {}

    StringBase(const StringBase &s): p_buf(s.p_buf) {}
    StringBase(const StringBase &s, const A &a):
        p_buf(s.p_buf, a) {}
    StringBase(StringBase &&s): p_buf(move(s.p_buf)) {}
    StringBase(StringBase &&s, const A &a):
        p_buf(move(s.p_buf), a) {}

    StringBase(const StringBase &s, Size pos, Size len = npos,
    const A &a = A()):
        p_buf(s.p_buf.iter().slice(pos,
            (len == npos) ? s.p_buf.size() : (pos + len)), a) {
        terminate();
    }

    /* TODO: traits for utf-16/utf-32 string lengths, for now assume char */
    StringBase(const Value *v, const A &a = A()):
        p_buf(ConstRange(v, strlen(v) + 1), a) {}

    StringBase(const Value *v, Size n, const A &a = A()):
        p_buf(ConstRange(v, n), a) {}

    template<typename R, typename = EnableIf<
        IsInputRange<R>::value &&
        IsConvertible<RangeReference<R>, Value>::value
    >> StringBase(R range, const A &a = A()): p_buf(range, a) {
        terminate();
    }

    void clear() { p_buf.clear(); }

    StringBase &operator=(const StringBase &v) {
        p_buf.operator=(v);
        return *this;
    }
    StringBase &operator=(StringBase &&v) {
        p_buf.operator=(move(v));
        return *this;
    }
    StringBase &operator=(const Value *v) {
        p_buf = ConstRange(v, strlen(v) + 1);
        return *this;
    }
    template<typename R, typename = EnableIf<
        IsInputRange<R>::value &&
        IsConvertible<RangeReference<R>, Value>::value
    >> StringBase &operator=(const R &r) {
        p_buf = r;
        terminate();
        return *this;
    }

    void resize(Size n, T v = T()) {
        p_buf.pop();
        p_buf.resize(n, v);
        terminate();
    }

    void reserve(Size n) {
        p_buf.reserve(n + 1);
    }

    T &operator[](Size i) { return p_buf[i]; }
    const T &operator[](Size i) const { return p_buf[i]; }

    T &at(Size i) { return p_buf[i]; }
    const T &at(Size i) const { return p_buf[i]; }

    T &front() { return p_buf[0]; }
    const T &front() const { return p_buf[0]; };

    T &back() { return p_buf[size() - 1]; }
    const T &back() const { return p_buf[size() - 1]; }

    Value *data() { return p_buf.data(); }
    const Value *data() const { return p_buf.data(); }

    Size size() const {
        return p_buf.size() - 1;
    }

    Size capacity() const {
        return p_buf.capacity() - 1;
    }

    Size length() const {
        /* TODO: unicode */
        return size();
    }

    bool empty() const { return (size() == 0); }

    void push(T v) {
        p_buf.back() = v;
        p_buf.push('\0');
    }

    StringBase &append(const StringBase &s) {
        p_buf.pop();
        p_buf.insert_range(p_buf.size(), s.p_buf.iter());
        return *this;
    }

    StringBase &append(const StringBase &s, Size idx, Size len) {
        p_buf.pop();
        p_buf.insert_range(p_buf.size(), Range(&s[idx],
            (len == npos) ? (s.size() - idx) : len));
        terminate();
        return *this;
    }

    StringBase &append(const Value *s) {
        p_buf.pop();
        p_buf.insert_range(p_buf.size(), ConstRange(s,
            strlen(s) + 1));
        return *this;
    }

    StringBase &append(Size n, T c) {
        p_buf.pop();
        for (Size i = 0; i < n; ++i) p_buf.push(c);
        p_buf.push('\0');
        return *this;
    }

    template<typename R>
    StringBase &append_range(R range) {
        p_buf.pop();
        p_buf.insert_range(p_buf.size(), range);
        terminate();
        return *this;
    }

    StringBase &operator+=(const StringBase &s) {
        return append(s);
    }
    StringBase &operator+=(const Value *s) {
        return append(s);
    }
    StringBase &operator+=(T c) {
        p_buf.pop();
        p_buf.push(c);
        p_buf.push('\0');
        return *this;
    }

    int compare(const StringBase &s) const {
        return strcmp(p_buf.data(), s.data());
    }

    int compare(const Value *p) const {
        return strcmp(p_buf.data(), p);
    }

    Range iter() {
        return Range(p_buf.data(), size());
    }
    ConstRange iter() const {
        return ConstRange(p_buf.data(), size());
    }
    ConstRange citer() const {
        return ConstRange(p_buf.data(), size());
    }

    Range iter_cap() {
        return Range(p_buf.data(), capacity());
    }

    void swap(StringBase &v) {
        p_buf.swap(v.p_buf);
    }

    Size to_hash() const {
        return iter().to_hash();
    }

    A get_allocator() const {
        return p_buf.get_allocator();
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

template<typename T, typename F, typename S = const char *,
         typename A = typename String::Allocator>
AnyString<A> concat(const T &v, const S &sep, F func) {
    AnyString<A> ret;
    auto range = octa::iter(v);
    if (range.empty()) return ret;
    for (;;) {
        ret += func(range.front());
        range.pop_front();
        if (range.empty()) break;
        ret += sep;
    }
    return ret;
}

template<typename T, typename S = const char *,
         typename A = typename String::Allocator>
AnyString<A> concat(const T &v, const S &sep = " ") {
    AnyString<A> ret;
    auto range = octa::iter(v);
    if (range.empty()) return ret;
    for (;;) {
        ret += range.front();
        range.pop_front();
        if (range.empty()) break;
        ret += sep;
    }
    return ret;
}

template<typename T, typename F, typename S = const char *,
         typename A = typename String::Allocator>
AnyString<A> concat(std::initializer_list<T> v, const S &sep, F func) {
    return concat(octa::iter(v), sep, func);
}

template<typename T, typename S = const char *,
         typename A = typename String::Allocator>
AnyString<A> concat(std::initializer_list<T> v, const S &sep = " ") {
    return concat(octa::iter(v), sep);
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
    True test_iterable(decltype(octa::iter(declval<T>())) *);
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
        ret += concat(octa::iter(v), ", ", ToString<
            RemoveConst<RemoveReference<
                RangeReference<decltype(octa::iter(v))>
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
    void str_printf(Vector<char> *s, const char *fmt, T v) {
        char buf[256];
        int n = snprintf(buf, sizeof(buf), fmt, v);
        s->clear();
        s->reserve(n + 1);
        if (n >= (int)sizeof(buf))
            snprintf(s->data(), n + 1, fmt, v);
        else if (n > 0)
            memcpy(s->data(), buf, n + 1);
        else {
            n = 0;
            *(s->data()) = '\0';
        }
        *((Size *)s) = n + 1;
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

#define OCTA_TOSTR_NUM(T, fmt) \
template<> struct ToString<T> { \
    using Argument = T; \
    using Result = String; \
    String operator()(T v) { \
        String ret; \
        detail::str_printf((Vector<char> *)&ret, fmt, v); \
        return ret; \
    } \
};

OCTA_TOSTR_NUM(sbyte, "%d")
OCTA_TOSTR_NUM(int, "%d")
OCTA_TOSTR_NUM(int &, "%d")
OCTA_TOSTR_NUM(long, "%ld")
OCTA_TOSTR_NUM(float, "%f")
OCTA_TOSTR_NUM(double, "%f")

OCTA_TOSTR_NUM(byte, "%u")
OCTA_TOSTR_NUM(uint, "%u")
OCTA_TOSTR_NUM(ulong, "%lu")
OCTA_TOSTR_NUM(llong, "%lld")
OCTA_TOSTR_NUM(ullong, "%llu")
OCTA_TOSTR_NUM(ldouble, "%Lf")

#undef OCTA_TOSTR_NUM

template<typename T> struct ToString<T *> {
    using Argument = T *;
    using Result = String;
    String operator()(Argument v) {
        String ret;
        detail::str_printf((Vector<char> *)&ret, "%p", v);
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

} /* namespace octa */

#endif
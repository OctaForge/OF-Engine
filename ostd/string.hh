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
#include "ostd/functional.hh"
#include "ostd/type_traits.hh"

namespace ostd {
static constexpr Size npos = -1;

template<typename T, typename A = Allocator<T>> class StringBase;

template<typename T>
struct CharRangeBase: InputRange<
    CharRangeBase<T>, ContiguousRangeTag, T
> {
private:
    struct Nat {};

public:
    CharRangeBase(): p_beg(nullptr), p_end(nullptr) {};

    template<typename U>
    CharRangeBase(T *beg, U end, EnableIf<
        (IsPointer<U>::value || IsNullPointer<U>::value) &&
        IsConvertible<U, T *>::value, Nat
    > = Nat()): p_beg(beg), p_end(end) {}

    CharRangeBase(T *beg, Size n): p_beg(beg), p_end(beg + n) {}

    /* TODO: traits for utf-16/utf-32 string lengths, for now assume char */
    template<typename U>
    CharRangeBase(U beg, EnableIf<
        IsConvertible<U, T *>::value && !IsArray<U>::value, Nat
    > = Nat()): p_beg(beg), p_end((T *)beg + (beg ? strlen(beg) : 0)) {}

    CharRangeBase(Nullptr): p_beg(nullptr), p_end(nullptr) {}

    template<typename U, Size N>
    CharRangeBase(U (&beg)[N], EnableIf<
        IsConvertible<U *, T *>::value, Nat
    > = Nat()): p_beg(beg),
        p_end(beg + N - (beg[N - 1] == '\0')) {}

    template<typename U, typename A>
    CharRangeBase(const StringBase<U, A> &s, EnableIf<
        IsConvertible<U *, T *>::value, Nat
    > = Nat()): p_beg(s.data()),
        p_end(s.data() + s.size()) {}

    template<typename U, typename = EnableIf<
        IsConvertible<U *, T *>::value
    >> CharRangeBase(const CharRangeBase<U> &v):
        p_beg(&v[0]), p_end(&v[v.size()]) {}

    CharRangeBase &operator=(const CharRangeBase &v) {
        p_beg = v.p_beg; p_end = v.p_end; return *this;
    }

    template<typename A>
    CharRangeBase &operator=(const StringBase<T, A> &s) {
        p_beg = s.data(); p_end = s.data() + s.size(); return *this;
    }
    /* TODO: traits for utf-16/utf-32 string lengths, for now assume char */
    CharRangeBase &operator=(T *s) {
        p_beg = s; p_end = s + (s ? strlen(s) : 0); return *this;
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

    bool equals_front(const CharRangeBase &range) const {
        return p_beg == range.p_beg;
    }

    Ptrdiff distance_front(const CharRangeBase &range) const {
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

    bool equals_back(const CharRangeBase &range) const {
        return p_end == range.p_end;
    }

    Ptrdiff distance_back(const CharRangeBase &range) const {
        return range.p_end - p_end;
    }

    Size size() const { return p_end - p_beg; }

    CharRangeBase slice(Size start, Size end) const {
        return CharRangeBase(p_beg + start, p_beg + end);
    }

    T &operator[](Size i) const { return p_beg[i]; }

    bool put(T v) {
        if (empty()) return false;
        *(p_beg++) = v;
        return true;
    }

    T *data() { return p_beg; }
    const T *data() const { return p_beg; }

    Size to_hash() const {
        return detail::mem_hash(data(), size());
    }

    /* non-range */
    int compare(CharRangeBase<const T> s) const {
        int ret = memcmp(data(), s.data(), ostd::min(size(), s.size()));
        return ret ? ret : (size() - s.size());
    }

private:
    T *p_beg, *p_end;
};

using CharRange = CharRangeBase<char>;
using ConstCharRange = CharRangeBase<const char>;

inline bool operator==(ConstCharRange lhs, ConstCharRange rhs) {
    return !lhs.compare(rhs);
}

inline bool operator!=(ConstCharRange lhs, ConstCharRange rhs) {
    return lhs.compare(rhs);
}

inline bool operator<(ConstCharRange lhs, ConstCharRange rhs) {
    return lhs.compare(rhs) < 0;
}

inline bool operator>(ConstCharRange lhs, ConstCharRange rhs) {
    return lhs.compare(rhs) > 0;
}

inline bool operator<=(ConstCharRange lhs, ConstCharRange rhs) {
    return lhs.compare(rhs) <= 0;
}

inline bool operator>=(ConstCharRange lhs, ConstCharRange rhs) {
    return lhs.compare(rhs) >= 0;
}

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
    using Range = CharRangeBase<T>;
    using ConstRange = CharRangeBase<const T>;
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
    StringBase(ConstRange v, const A &a = A()): StringBase(a) {
        if (!v.size()) return;
        reserve(v.size());
        memcpy(p_buf.first(), &v[0], v.size());
        p_buf.first()[v.size()] = '\0';
        p_len = v.size();
    }

    template<typename U>
    StringBase(U v, const EnableIf<
        IsConvertible<U, const Value *>::value && !IsArray<U>::value, A
    > &a = A()): StringBase(ConstRange(v), a) {}

    template<typename U, Size N>
    StringBase(U (&v)[N], const EnableIf<
        IsConvertible<U *, const Value *>::value, A
    > &a = A()): StringBase(ConstRange(v), a) {}

    template<typename R, typename = EnableIf<
        IsInputRange<R>::value &&
        IsConvertible<RangeReference<R>, Value>::value
    >> StringBase(R range, const A &a = A()): StringBase(a) {
        ctor_from_range(range);
    }

    ~StringBase() {
        if (!p_cap) return;
        allocator_deallocate(p_buf.second(), p_buf.first(), p_cap + 1);
    }

    void clear() {
        if (!p_len) return;
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
                p_buf.first() = (Pointer)&p_len;
            }
            p_buf.second() = v.p_buf.second();
        }
        reserve(v.p_cap);
        p_len = v.p_len;
        if (p_len) {
            memcpy(p_buf.first(), v.p_buf.first(), p_len);
            p_buf.first()[p_len] = '\0';
        } else p_buf.first() = (Pointer)&p_len;
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
        if (!p_cap) p_buf.first() = (Pointer)&p_len;
        return *this;
    }

    StringBase &operator=(ConstRange v) {
        reserve(v.size());
        if (v.size()) memcpy(p_buf.first(), &v[0], v.size());
        p_buf.first()[v.size()] = '\0';
        p_len = v.size();
        return *this;
    }

    template<typename U>
    EnableIf<
        IsConvertible<U, const Value *>::value && !IsArray<U>::value,
        StringBase &
    > operator=(U v) {
        return operator=(ConstRange(v));
    }

    template<typename U, Size N>
    EnableIf<
        IsConvertible<U *, const Value *>::value, StringBase &
    > operator=(U (&v)[N]) {
        return operator=(ConstRange(v));
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

    T &operator[](Size i) { return p_buf.first()[i]; }
    const T &operator[](Size i) const { return p_buf.first()[i]; }

    T &at(Size i) { return p_buf.first()[i]; }
    const T &at(Size i) const { return p_buf.first()[i]; }

    T &front() { return p_buf.first()[0]; }
    const T &front() const { return p_buf.first()[0]; };

    T &back() { return p_buf.first()[size() - 1]; }
    const T &back() const { return p_buf.first()[size() - 1]; }

    Value *data() { return p_buf.first(); }
    const Value *data() const { return p_buf.first(); }

    Size size() const {
        return p_len;
    }

    Size capacity() const {
        return p_cap;
    }

    void advance(Size s) { p_len += s; }

    Size length() const {
        /* TODO: unicode */
        return size();
    }

    bool empty() const { return (size() == 0); }

    Value *disown() {
        Pointer r = p_buf.first();
        p_buf.first() = nullptr;
        p_len = p_cap = 0;
        return (Value *)r;
    }

    void push(T v) {
        reserve(p_len + 1);
        p_buf.first()[p_len++] = v;
        p_buf.first()[p_len] = '\0';
    }

    StringBase &append(ConstRange r) {
        if (!r.size()) return *this;
        reserve(p_len + r.size());
        memcpy(p_buf.first() + p_len, &r[0], r.size());
        p_len += r.size();
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

    template<typename R, typename = EnableIf<
        IsInputRange<R>::value &&
        IsConvertible<RangeReference<R>, Value>::value &&
        !IsConvertible<R, ConstRange>::value
    >> StringBase &append(R range) {
        Size nadd = 0;
        for (; !range.empty(); range.pop_front()) {
            reserve(p_len + nadd + 1);
            p_buf.first()[p_len + nadd++] = range.front(); 
        }
        p_len += nadd;
        p_buf.first()[p_len] = '\0';
        return *this;
    }

    StringBase &operator+=(ConstRange r) {
        return append(r);
    }
    StringBase &operator+=(T c) {
        reserve(p_len + 1);
        p_buf.first()[p_len++] = c;
        p_buf.first()[p_len] = '\0';
        return *this;
    }
    template<typename R>
    StringBase &operator+=(const R &v) {
        return append(v);
    }

    int compare(ConstRange r) const {
        return iter().compare(r);
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

/* string literals */

inline namespace literals { inline namespace string_literals {
    inline String operator "" _s(const char *str, Size len) {
        return String(ConstCharRange(str, len));
    }

    inline ConstCharRange operator "" _S(const char *str, Size len) {
        return ConstCharRange(str, len);
    }
} }

namespace detail {
    template<typename T, bool = IsConvertible<T, ConstCharRange>::value,
                         bool = IsConvertible<T, char>::value>
    struct ConcatPut;

    template<typename T, bool B>
    struct ConcatPut<T, true, B> {
        template<typename R>
        static bool put(R &sink, ConstCharRange v) {
            return v.size() && (sink.put_n(&v[0], v.size()) == v.size());
        }
    };

    template<typename T>
    struct ConcatPut<T, false, true> {
        template<typename R>
        static bool put(R &sink, char v) {
            return sink.put(v);
        }
    };
}

template<typename R, typename T, typename F>
bool concat(R &&sink, const T &v, ConstCharRange sep, F func) {
    auto range = ostd::iter(v);
    if (range.empty()) return true;
    for (;;) {
        if (!detail::ConcatPut<
            decltype(func(range.front()))
        >::put(sink, func(range.front())))
            return false;
        range.pop_front();
        if (range.empty()) break;
        sink.put_n(&sep[0], sep.size());
    }
    return true;
}

template<typename R, typename T>
bool concat(R &&sink, const T &v, ConstCharRange sep = " ") {
    auto range = ostd::iter(v);
    if (range.empty()) return true;
    for (;;) {
        ConstCharRange ret = range.front();
        if (!ret.size() || (sink.put_n(&ret[0], ret.size()) != ret.size()))
            return false;
        range.pop_front();
        if (range.empty()) break;
        sink.put_n(&sep[0], sep.size());
    }
    return true;
}

template<typename R, typename T, typename F>
bool concat(R &&sink, std::initializer_list<T> v, ConstCharRange sep, F func) {
    return concat(sink, ostd::iter(v), sep, func);
}

template<typename R, typename T>
bool concat(R &&sink, std::initializer_list<T> v, ConstCharRange sep = " ") {
    return concat(sink, ostd::iter(v), sep);
}

namespace detail {
    template<typename R>
    struct TostrRange: OutputRange<TostrRange<R>, char> {
        TostrRange() = delete;
        TostrRange(R &out): p_out(out), p_written(0) {}
        bool put(char v) {
            bool ret = p_out.put(v);
            p_written += ret;
            return ret;
        }
        Size put_n(const char *v, Size n) {
            Size ret = p_out.put_n(v, n);
            p_written += ret;
            return ret;
        }
        Size put_string(ConstCharRange r) {
            return put_n(&r[0], r.size());
        }
        Size get_written() const { return p_written; }
    private:
        R &p_out;
        Size p_written;
    };

    template<typename T, typename R>
    auto test_stringify(int) ->
        decltype(IsSame<decltype(declval<T>().stringify()), String>());

    template<typename T, typename R>
    static True test_stringify(decltype(declval<const T &>().to_string
        (declval<R &>())) *);

    template<typename, typename>
    False test_stringify(...);

    template<typename T, typename R>
    using StringifyTest = decltype(test_stringify<T, R>(0));

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
        auto x = appender<String>();
        if (concat(x, ostd::iter(v), ", ", ToString<
            RemoveConst<RemoveReference<
                RangeReference<decltype(ostd::iter(v))>
            >>
        >())) ret += x.get();
        ret += "}";
        return ret;
    }
};

template<typename T>
struct ToString<T, EnableIf<
    detail::StringifyTest<T, detail::TostrRange<AppenderRange<String>>>::value
>> {
    using Argument = RemoveCv<RemoveReference<T>>;
    using Result = String;

    String operator()(const T &v) const {
        auto app = appender<String>();
        detail::TostrRange<AppenderRange<String>> sink(app);
        if (!v.to_string(sink)) return String();
        return move(app.get());
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

template<> struct ToString<CharRange> {
    using Argument = CharRange;
    using Result = String;
    String operator()(const Argument &s) {
        return String(s);
    }
};

template<> struct ToString<ConstCharRange> {
    using Argument = ConstCharRange;
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
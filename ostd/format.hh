/* Format strings for OctaSTD. Inspired by D's std.format module.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OSTD_FORMAT_HH
#define OSTD_FORMAT_HH

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <assert.h>

#include "ostd/algorithm.hh"
#include "ostd/string.hh"
#include "ostd/utility.hh"
#include "ostd/internal/tuple.hh"

namespace ostd {

enum FormatFlags {
    FMT_FLAG_DASH  = 1 << 0,
    FMT_FLAG_ZERO  = 1 << 1,
    FMT_FLAG_SPACE = 1 << 2,
    FMT_FLAG_PLUS  = 1 << 3,
    FMT_FLAG_HASH  = 1 << 4
};

namespace detail {
    inline int parse_fmt_flags(ConstCharRange &fmt, int ret) {
        while (!fmt.empty()) {
            switch (fmt.front()) {
            case '-': ret |= FMT_FLAG_DASH; fmt.pop_front(); break;
            case '+': ret |= FMT_FLAG_PLUS; fmt.pop_front(); break;
            case '#': ret |= FMT_FLAG_HASH; fmt.pop_front(); break;
            case '0': ret |= FMT_FLAG_ZERO; fmt.pop_front(); break;
            case ' ': ret |= FMT_FLAG_SPACE; fmt.pop_front(); break;
            default: goto retflags;
            }
        }
    retflags:
        return ret;
    }

    inline Size read_digits(ConstCharRange &fmt, char *buf) {
        Size ret = 0;
        for (; !fmt.empty() && isdigit(fmt.front()); ++ret) {
            *buf++ = fmt.front();
            fmt.pop_front();
        }
        *buf = '\0';
        return ret;
    }

    /* 0 .. not allowed
     * 1 .. floating point
     * 2 .. character
     * 3 .. binary
     * 4 .. octal
     * 5 .. decimal
     * 6 .. hexadecimal
     * 7 .. string
     * 8 .. custom object
     */
    static constexpr const byte fmt_specs[] = {
        /* uppercase spec set */
        1, 3, 8, 8, /* A B C D */
        1, 1, 1, 8, /* E F G H */
        8, 8, 8, 8, /* I J K L */
        8, 8, 8, 8, /* M N O P */
        8, 8, 8, 8, /* Q R S T */
        8, 8, 8, 6, /* U V W X */
        8, 8,       /* Y Z */

        /* ascii filler */
        0, 0, 0, 0, 0, 0,

        /* lowercase spec set */
        1, 3, 2, 5, /* a b c d */
        1, 1, 1, 8, /* e f g h */
        8, 8, 8, 8, /* i j k l */
        8, 8, 4, 8, /* m n o p */
        8, 8, 7, 8, /* q r s t */
        8, 8, 8, 6, /* u v w x */
        8, 8,       /* y z */

        /* ascii filler */
        0, 0, 0, 0, 0
    };

    static constexpr const int fmt_bases[] = {
        0, 0, 0, 2, 8, 10, 16, 0
    };

    static constexpr const char fmt_digits[2][16] = {
        {
            '0', '1', '2', '3', '4', '5', '6', '7',
            '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
        },
        {
            '0', '1', '2', '3', '4', '5', '6', '7',
            '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'
        }
    };

    static constexpr const char *fmt_intpfx[2][4] = {
        { "0B", "0", "", "0X" },
        { "0b", "0", "", "0x" }
    };

    /* retrieve width/precision */
    template<typename T>
    bool convert_arg_param(const T &val, int &param, EnableIf<
        IsIntegral<T>::value, bool
    > = true) {
        param = int(val);
        return true;
    }

    template<typename T>
    bool convert_arg_param(const T &, int &, EnableIf<
        !IsIntegral<T>::value, bool
    > = true) {
        assert(false && "invalid argument for width/precision");
        return false;
    }

    template<typename T>
    bool get_arg_param(Size idx, int &param, const T &val) {
        if (idx) {
            assert(false && "not enough format args");
            return false;
        }
        return convert_arg_param(val, param);
    }
    template<typename T, typename ...A>
    bool get_arg_param(Size idx, int &param, const T &val,
                      const A &...args) {
        if (idx) return get_arg_param(idx - 1, param, args...);
        return convert_arg_param(val, param);
    }
}

struct FormatSpec {
    FormatSpec(): p_nested_escape(false), p_fmt() {}
    FormatSpec(ConstCharRange fmt, bool escape = false):
        p_nested_escape(escape), p_fmt(fmt) {}

    template<typename R>
    bool read_until_spec(R &writer, Size *wret) {
        Size written = 0;
        if (wret) *wret = 0;
        if (p_fmt.empty()) return false;
        while (!p_fmt.empty()) {
            if (p_fmt.front() == '%') {
                p_fmt.pop_front();
                if (p_fmt.front() == '%') goto plain;
                bool r = read_spec();
                if (wret) *wret = written;
                return r;
            }
        plain:
            ++written;
            writer.put(p_fmt.front());
            p_fmt.pop_front();
        }
        if (wret) *wret = written;
        return false;
    }

    template<typename R>
    Size write_spaces(R &writer, Size n, bool left, char c = ' ') const {
        if (left == bool(p_flags & FMT_FLAG_DASH)) return 0;
        int r = p_width - int(n);
        for (int w = p_width - int(n); --w >= 0; writer.put(c));
        if (r < 0) return 0;
        return r;
    }

    ConstCharRange rest() const {
        return p_fmt;
    }

    template<typename R>
    Size build_spec(R &&out, ConstCharRange spec) {
        Size ret = out.put('%');
        if (p_flags & FMT_FLAG_DASH ) ret += out.put('-');
        if (p_flags & FMT_FLAG_ZERO ) ret += out.put('0');
        if (p_flags & FMT_FLAG_SPACE) ret += out.put(' ');
        if (p_flags & FMT_FLAG_PLUS ) ret += out.put('+');
        if (p_flags & FMT_FLAG_HASH ) ret += out.put('#');
        ret += out.put_n("*.*", 3);
        ret += out.put_n(&spec[0], spec.size());
        return ret;
    }

    int width() const { return p_width; }
    int precision() const { return p_precision; }

    bool has_width() const { return p_has_width; }
    bool has_precision() const { return p_has_precision; }

    bool arg_width() const { return p_arg_width; }
    bool arg_precision() const { return p_arg_precision; }

    template<typename ...A>
    bool set_width(Size idx, const A &...args) {
        return detail::get_arg_param(idx, p_width, args...);
    }

    template<typename ...A>
    bool set_precision(Size idx, const A &...args) {
        return detail::get_arg_param(idx, p_precision, args...);
    }

    int flags() const { return p_flags; }

    char spec() const { return p_spec; }

    byte index() const { return p_index; }

    ConstCharRange nested() const { return p_nested; }
    ConstCharRange nested_sep() const { return p_nested_sep; }

    bool is_nested() const { return p_is_nested; }
    bool nested_escape() const { return p_nested_escape; }

protected:
    ConstCharRange p_nested;
    ConstCharRange p_nested_sep;

    int p_flags = 0;

    int p_width = 0;
    int p_precision = 0;

    bool p_has_width = false;
    bool p_has_precision = false;

    bool p_arg_width = false;
    bool p_arg_precision = false;

    char p_spec = '\0';

    byte p_index = 0;

    bool p_is_nested = false;
    bool p_nested_escape = false;

    bool read_until_dummy() {
        while (!p_fmt.empty()) {
            if (p_fmt.front() == '%') {
                p_fmt.pop_front();
                if (p_fmt.front() == '%') goto plain;
                return read_spec();
            }
        plain:
            p_fmt.pop_front();
        }
        return false;
    }

    bool read_spec_range() {
        int sflags = p_flags;
        p_nested_escape = !(sflags & FMT_FLAG_DASH);
        p_fmt.pop_front();
        ConstCharRange begin_inner(p_fmt);
        if (!read_until_dummy()) {
            p_is_nested = false;
            return false;
        }
        /* skip to the last spec in case multiple specs are present */
        ConstCharRange curfmt(p_fmt);
        while (read_until_dummy()) {
            curfmt = p_fmt;
        }
        p_fmt = curfmt;
        p_flags = sflags;
        /* find delimiter or ending */
        ConstCharRange begin_delim(p_fmt);
        ConstCharRange p = find(begin_delim, '%');
        for (; !p.empty(); p = find(p, '%')) {
            p.pop_front();
            /* escape, skip */
            if (p.front() == '%') {
                p.pop_front();
                continue;
            }
            /* found end, in that case delimiter is after spec */
            if (p.front() == ')') {
                p_nested = begin_inner.slice(0, &begin_delim[0] - &begin_inner[0]);
                p_nested_sep = begin_delim.slice(0, &p[0] - &begin_delim[0] - 1);
                p.pop_front();
                p_fmt = p;
                p_is_nested = true;
                return true;
            }
            /* found actual delimiter start... */
            if (p.front() == '|') {
                p_nested = begin_inner.slice(0, &p[0] - &begin_inner[0] - 1);
                p.pop_front();
                p_nested_sep = p;
                for (p = find(p, '%'); !p.empty(); p = find(p, '%')) {
                    p.pop_front();
                    if (p.front() == ')') {
                        p_nested_sep = p_nested_sep.slice(0, &p[0] - &p_nested_sep[0] - 1);
                        p.pop_front();
                        p_fmt = p;
                        p_is_nested = true;
                        return true;
                    }
                }
                p_is_nested = false;
                return false;
            }
        }
        p_is_nested = false;
        return false;
    }

    bool read_spec() {
        Size ndig = detail::read_digits(p_fmt, p_buf);

        bool havepos = false;
        p_index = 0;
        /* parse index */
        if (p_fmt.front() == '$') {
            if (ndig <= 0) return false; /* no pos given */
            int idx = atoi(p_buf);
            if (idx <= 0 || idx > 255) return false; /* bad index */
            p_index = byte(idx);
            p_fmt.pop_front();
            havepos = true;
        }

        /* parse flags */
        p_flags = 0;
        Size skipd = 0;
        if (havepos || !ndig) {
            p_flags = detail::parse_fmt_flags(p_fmt, 0);
        } else {
            for (Size i = 0; i < ndig; ++i) {
                if (p_buf[i] != '0') break;
                ++skipd;
            }
            if (skipd) p_flags = FMT_FLAG_ZERO;
            if (skipd == ndig)
                p_flags = detail::parse_fmt_flags(p_fmt, p_flags);
        }

        /* range/array formatting */
        if ((p_fmt.front() == '(') && (havepos || !(ndig - skipd))) {
            return read_spec_range();
        }

        /* parse width */
        p_width = 0;
        p_has_width = false;
        p_arg_width = false;
        if (!havepos && ndig && (ndig - skipd)) {
            p_width = atoi(p_buf + skipd);
            p_has_width = true;
        } else if (detail::read_digits(p_fmt, p_buf)) {
            p_width = atoi(p_buf);
            p_has_width = true;
        } else if (p_fmt.front() == '*') {
            p_arg_width = p_has_width = true;
            p_fmt.pop_front();
        }

        /* parse precision */
        p_precision = 0;
        p_has_precision = false;
        p_arg_precision = false;
        if (p_fmt.front() != '.') goto fmtchar;
        p_fmt.pop_front();

        if (detail::read_digits(p_fmt, p_buf)) {
            p_precision = atoi(p_buf);
            p_has_precision = true;
        } else if (p_fmt.front() == '*') {
            p_arg_precision = p_has_precision = true;
            p_fmt.pop_front();
        } else return false;

    fmtchar:
        p_spec = p_fmt.front();
        p_fmt.pop_front();
        /* make sure we're testing on a signed byte - our mapping only
         * tests values up to 127 */
        sbyte sp = p_spec;
        return (sp >= 65) && (detail::fmt_specs[sp - 65] != 0);
    }

    ConstCharRange p_fmt;
    char p_buf[32];
};

/* for custom container formatting */

template<typename T, typename R, typename = EnableIf<
    IsSame<decltype(declval<const T &>()
        .to_format(declval<R &>(), declval<const FormatSpec &>())), bool
    >::value
>> inline bool to_format(const T &v, R &writer, const FormatSpec &fs) {
    return v.to_format(writer, fs);
}

namespace detail {
    template<typename R, typename T>
    inline Ptrdiff write_u(R &writer, const FormatSpec *fl, bool neg, T val) {
        char buf[20];
        Ptrdiff r = 0;
        Size n = 0;

        char spec = fl->spec();
        if (spec == 's') spec = 'd';
        byte specn = detail::fmt_specs[spec - 65];
        if (specn <= 2 || specn > 7) {
            assert(false && "cannot format integers with the given spec");
            return -1;
        }

        int base = detail::fmt_bases[specn];
        if (!val) buf[n++] = '0';
        for (; val; val /= base)
            buf[n++] = detail::fmt_digits[spec >= 'a'][val % base];
        r = n;

        int flags = fl->flags();
        bool lsgn = flags & FMT_FLAG_PLUS;
        bool lsp  = flags & FMT_FLAG_SPACE;
        bool zero = flags & FMT_FLAG_ZERO;
        bool sign = neg + lsgn + lsp;
        r += sign;

        const char *pfx = nullptr;
        int pfxlen = 0;
        if (flags & FMT_FLAG_HASH && spec != 'd') {
            pfx = detail::fmt_intpfx[spec >= 'a'][specn - 3];
            pfxlen = !!pfx[1] + 1;
            r += pfxlen;
        }

        if (!zero)
            r += fl->write_spaces(writer, n + pfxlen + sign, true, ' ');
        if (sign) writer.put(neg ? '-' : *((" \0+") + lsgn * 2));
        writer.put_n(pfx, pfxlen);
        if (zero)
            r += fl->write_spaces(writer, n + pfxlen + sign, true, '0');

        for (int i = int(n - 1); i >= 0; --i) {
            writer.put(buf[i]);
        }
        r += fl->write_spaces(writer, n + sign + pfxlen, false);
        return r;
    }

    template<typename R, typename ...A>
    static Ptrdiff format_impl(R &writer, Size &fmtn, bool escape,
                               ConstCharRange fmt, const A &...args);

    template<typename T, typename = RangeOf<T>>
    static True test_fmt_range(int);
    template<typename>
    static False test_fmt_range(...);

    template<typename T>
    using FmtRangeTest = decltype(test_fmt_range<T>(0));

    template<Size I>
    struct FmtTupleUnpacker {
        template<typename R, typename T, typename ...A>
        static inline Ptrdiff unpack(R &writer, Size &fmtn, bool esc,
                                     ConstCharRange fmt, const T &item,
                                     const A &...args) {
            return FmtTupleUnpacker<I - 1>::unpack(writer, fmtn, esc, fmt,
                item, get<I - 1>(item), args...);
        }
    };

    template<>
    struct FmtTupleUnpacker<0> {
        template<typename R, typename T, typename ...A>
        static inline Ptrdiff unpack(R &writer, Size &fmtn, bool esc,
                                     ConstCharRange fmt, const T &,
                                     const A &...args) {
            return format_impl(writer, fmtn, esc, fmt, args...);
        }
    };

    template<typename R, typename T>
    inline Ptrdiff format_ritem(R &writer, Size &fmtn, bool esc, bool,
                                ConstCharRange fmt, const T &item,
                                EnableIf<!IsTupleLike<T>::value, bool>
                                    = true) {
        return format_impl(writer, fmtn, esc, fmt, item);
    }

    template<typename R, typename T>
    inline Ptrdiff format_ritem(R &writer, Size &fmtn, bool esc,
                                bool expandval, ConstCharRange fmt,
                                const T &item,
                                EnableIf<IsTupleLike<T>::value, bool>
                                    = true) {
        if (expandval) {
            return FmtTupleUnpacker<TupleSize<T>::value>::unpack(writer,
                fmtn, esc, fmt, item);
        }
        return format_impl(writer, fmtn, esc, fmt, item);
    }

    template<typename R, typename T>
    inline Ptrdiff write_range(R &writer, const FormatSpec *fl,
                               bool escape, bool expandval,
                               ConstCharRange sep,
                               const T &val,
                               EnableIf<FmtRangeTest<T>::value, bool>
                                   = true) {
        auto range = ostd::iter(val);
        if (range.empty()) return 0;
        Ptrdiff ret = 0;
        Size fmtn = 0;
        /* test first item */
        Ptrdiff fret = format_ritem(writer, fmtn, escape, expandval,
            fl->rest(), range.front());
        if (fret < 0) return fret;
        ret += fret;
        range.pop_front();
        /* write the rest (if any) */
        for (; !range.empty(); range.pop_front()) {
            auto v = writer.put_n(&sep[0], sep.size());
            if (v != sep.size())
                return -1;
            ret += sep.size();
            fret = format_ritem(writer, fmtn, escape, expandval,
                fl->rest(), range.front());
            if (fret < 0) return fret;
            ret += fret;
        }
        return ret;
    }

    template<typename R, typename T>
    inline Ptrdiff write_range(R &, const FormatSpec *, bool, bool,
                               ConstCharRange, const T &,
                               EnableIf<!FmtRangeTest<T>::value, bool>
                                   = true) {
        assert(false && "invalid value for ranged format");
        return -1;
    }

    template<typename T>
    static True test_fmt_tostr(decltype(ostd::to_string(declval<T>())) *);
    template<typename> static False test_fmt_tostr(...);

    template<typename T>
    using FmtTostrTest = decltype(test_fmt_tostr<T>(0));

    /* non-printable escapes up to 0x20 (space) */
    static constexpr const char *fmt_escapes[] = {
        "\\0"  , "\\x01", "\\x02", "\\x03", "\\x04", "\\x05",
        "\\x06", "\\a"  , "\\b"  , "\\t"  , "\\n"  , "\\v"  ,
        "\\f"  , "\\r"  , "\\x0E", "\\x0F", "\\x10", "\\x11",
        "\\x12", "\\x13", "\\x14", "\\x15", "\\x16", "\\x17",
        "\\x18", "\\x19", "\\x1A", "\\x1B", "\\x1C", "\\x1D",
        "\\x1E", "\\x1F",
        /* we want to escape double quotes... */
        nullptr, nullptr, "\\\"", nullptr, nullptr, nullptr,
        nullptr, "\\\'"
    };

    inline const char *escape_fmt_char(char v, char quote) {
        if ((v >= 0 && v < 0x20) || (v == quote)) {
            return fmt_escapes[Size(v)];
        } else if (v == 0x7F) {
            return "\\x7F";
        }
        return nullptr;
    }

    inline String escape_fmt_str(ConstCharRange val) {
        String ret;
        ret.push('"');
        while (!val.empty()) {
            const char *esc = escape_fmt_char(val.front(), '"');
            if (esc)
                ret.append(esc);
            else
                ret.push(val.front());
            val.pop_front();
        }
        ret.push('"');
        return ret;
    }

    template<typename T, typename R>
    static True test_tofmt(decltype(to_format(declval<const T &>(),
                                              declval<R &>(),
                                              declval<const FormatSpec &>())) *);

    template<typename, typename>
    static False test_tofmt(...);

    template<typename T, typename R>
    using FmtTofmtTest = decltype(test_tofmt<T, R>(0));

    struct WriteSpec: FormatSpec {
        WriteSpec(): FormatSpec() {}
        WriteSpec(ConstCharRange fmt, bool esc): FormatSpec(fmt, esc) {}

        /* string base writer */
        template<typename R>
        Ptrdiff write_str(R &writer, bool escape, ConstCharRange val) {
            if (escape) {
                return write_str(writer, false, escape_fmt_str(val));
            }
            Size n = val.size();
            if (this->precision()) n = this->precision();
            Ptrdiff r = n;
            r += this->write_spaces(writer, n, true);
            writer.put_n(&val[0], n);
            r += this->write_spaces(writer, n, false);
            return r;
        }

        /* any string value */
        template<typename R, typename T>
        Ptrdiff write(R &writer, bool escape, const T &val, EnableIf<
            IsConstructible<ConstCharRange, const T &>::value, bool
        > = true) {
            if (this->spec() != 's') {
                assert(false && "cannot print strings with the given spec");
                return -1;
            }
            return write_str(writer, escape, val);
        }

        /* character */
        template<typename R>
        Ptrdiff write(R &writer, bool escape, char val) {
            if (this->spec() != 's' && this->spec() != 'c') {
                assert(false && "cannot print chars with the given spec");
                return -1;
            }
            if (escape) {
                const char *esc = escape_fmt_char(val, '\'');
                if (esc) {
                    char buf[6];
                    buf[0] = '\'';
                    Size elen = strlen(esc);
                    memcpy(buf + 1, esc, elen);
                    buf[elen + 1] = '\'';
                    return write(writer, false, (const char *)buf, elen + 2);
                }
            }
            Ptrdiff r = 1 + escape * 2;
            r += this->write_spaces(writer, 1 + escape * 2, true);
            if (escape) {
                writer.put('\'');
                writer.put(val);
                writer.put('\'');
            } else writer.put(val);
            r += this->write_spaces(writer, 1 + escape * 2, false);
            return r;
        }

        /* bool */
        template<typename R>
        Ptrdiff write(R &writer, bool, bool val) {
            if (this->spec() == 's')
                return write(writer, ("false\0true") + (6 * val));
            else
                return write(writer, int(val));
        }

        /* signed integers */
        template<typename R, typename T>
        Ptrdiff write(R &writer, bool, T val, EnableIf<
            IsIntegral<T>::value && IsSigned<T>::value, bool
        > = true) {
            using UT = MakeUnsigned<T>;
            return detail::write_u(writer, this, val < 0,
                (val < 0) ? (UT)(-val) : (UT)(val));
        }

        /* unsigned integers */
        template<typename R, typename T>
        Ptrdiff write(R &writer, bool, T val, EnableIf<
            IsIntegral<T>::value && IsUnsigned<T>::value, bool
        > = true) {
            return detail::write_u(writer, this, false, val);
        }

        template<typename R, typename T,
            bool Long = IsSame<T, ldouble>::value
        > Ptrdiff write(R &writer, bool, T val, EnableIf<
            IsFloatingPoint<T>::value, bool
        > = true) {
            char buf[16], rbuf[128];
            char fmtspec[Long + 1];

            fmtspec[Long] = this->spec();
            byte specn = detail::fmt_specs[this->spec() - 65];
            if (specn != 1 && specn != 7) {
                assert(false && "cannot format floats with the given spec");
                return -1;
            }
            if (specn == 7) fmtspec[Long] = 'g';
            if (Long) fmtspec[0] = 'L';

            buf[this->build_spec(iter(buf), fmtspec)] = '\0';
            Ptrdiff ret = snprintf(rbuf, sizeof(rbuf), buf,
                this->width(),
                this->has_precision() ? this->precision() : 6, val);

            char *dbuf = nullptr;
            if (Size(ret) >= sizeof(rbuf)) {
                /* this should typically never happen */
                dbuf = (char *)malloc(ret + 1);
                ret = snprintf(dbuf, ret + 1, buf, this->width(),
                    this->has_precision() ? this->precision() : 6, val);
                writer.put_n(dbuf, ret);
                free(dbuf);
            } else writer.put_n(rbuf, ret);
            return ret;
        }

        /* pointer value */
        template<typename R, typename T>
        Ptrdiff write(R &writer, bool, T *val, EnableIf<
            !IsConstructible<ConstCharRange, T *>::value, bool
        > = true) {
            if (this->p_spec == 's') {
                this->p_spec = 'x';
                this->p_flags |= FMT_FLAG_HASH;
            }
            return write(writer, false, Size(val));
        }

        /* generic value */
        template<typename R, typename T>
        Ptrdiff write(R &writer, bool, const T &val, EnableIf<
            !IsArithmetic<T>::value &&
            !IsConstructible<ConstCharRange, const T &>::value &&
            FmtTostrTest<T>::value &&
            !FmtTofmtTest<T, TostrRange<R>>::value, bool
        > = true) {
            if (this->spec() != 's') {
                assert(false && "custom objects need '%s' format");
                return -1;
            }
            return write(writer, false, ostd::to_string(val));
        }

        /* custom format case */
        template<typename R, typename T>
        Ptrdiff write(R &writer, bool, const T &val,
            EnableIf<FmtTofmtTest<T, TostrRange<R>>::value, bool
        > = true) {
            TostrRange<R> sink(writer);
            if (!to_format(val, sink, *this)) return -1;
            return sink.get_written();
        }

        /* generic failure case */
        template<typename R, typename T>
        Ptrdiff write(R &, bool, const T &, EnableIf<
            !IsArithmetic<T>::value &&
            !IsConstructible<ConstCharRange, const T &>::value &&
            !FmtTostrTest<T>::value &&
            !FmtTofmtTest<T, TostrRange<R>>::value, bool
        > = true) {
            assert(false && "value cannot be formatted");
            return -1;
        }

        /* actual writer */
        template<typename R, typename T>
        Ptrdiff write_arg(R &writer, Size idx, const T &val) {
            if (idx) {
                assert(false && "not enough format args");
                return -1;
            }
            return write(writer, this->p_nested_escape, val);
        }

        template<typename R, typename T, typename ...A>
        Ptrdiff write_arg(R &writer, Size idx, const T &val,
                          const A &...args) {
            if (idx) return write_arg(writer, idx - 1, args...);
            return write(writer, this->p_nested_escape, val);
        }

        /* range writer */
        template<typename R, typename T>
        Ptrdiff write_range(R &writer, Size idx, bool expandval,
                            ConstCharRange sep, const T &val) {
            if (idx) {
                assert(false && "not enough format args");
                return -1;
            }
            return detail::write_range(writer, this, this->p_nested_escape,
                expandval, sep, val);
        }

        template<typename R, typename T, typename ...A>
        Ptrdiff write_range(R &writer, Size idx, bool expandval,
                            ConstCharRange sep, const T &val,
                            const A &...args) {
            if (idx) {
                return write_range(writer, idx - 1, expandval, sep, args...);
            }
            return detail::write_range(writer, this,
                this->p_nested_escape, expandval, sep, val);
        }
    };

    template<typename R, typename ...A>
    inline Ptrdiff format_impl(R &writer, Size &fmtn, bool escape,
                               ConstCharRange fmt, const A &...args) {
        Size argidx = 1, retn = 0, twr = 0;
        Ptrdiff written = 0;
        detail::WriteSpec spec(fmt, escape);
        while (spec.read_until_spec(writer, &twr)) {
            written += twr;
            Size argpos = spec.index();
            if (spec.is_nested()) {
                if (!argpos) argpos = argidx++;
                /* FIXME: figure out a better way */
                detail::WriteSpec nspec(spec.nested(), spec.nested_escape());
                Ptrdiff sw = nspec.write_range(writer, argpos - 1,
                    (spec.flags() & FMT_FLAG_HASH),
                    spec.nested_sep(), args...);
                if (sw < 0) return sw;
                written += sw;
                continue;
            }
            if (!argpos) {
                argpos = argidx++;
                if (spec.arg_width()) {
                    if (!spec.set_width(argpos - 1, args...))
                        return -1;
                    argpos = argidx++;
                }
                if (spec.arg_precision()) {
                    if (!spec.set_precision(argpos - 1, args...))
                        return -1;
                    argpos = argidx++;
                }
            } else {
                bool argprec = spec.arg_precision();
                if (argprec) {
                    if (argpos <= 1) {
                        assert(false && "argument precision not given");
                        return -1;
                    }
                    if (!spec.set_precision(argpos - 2, args...))
                        return -1;
                }
                if (spec.arg_width()) {
                    if (argpos <= (Size(argprec) + 1)) {
                        assert(false && "argument width not given");
                        return -1;
                    }
                    if (!spec.set_width(argpos - 2 - argprec, args...))
                        return -1;
                }
            }
            Ptrdiff sw = spec.write_arg(writer, argpos - 1, args...);
            if (sw < 0) return sw;
            written += sw;
        }
        written += twr;
        fmtn = retn;
        return written;
    }

    template<typename R, typename ...A>
    inline Ptrdiff format_impl(R &writer, Size &fmtn, bool,
                               ConstCharRange fmt) {
        Size written = 0;
        detail::WriteSpec spec(fmt, false);
        if (spec.read_until_spec(writer, &written)) return -1;
        fmtn = 0;
        return written;
    }
} /* namespace detail */

template<typename R, typename ...A>
inline Ptrdiff format(R &&writer, Size &fmtn, ConstCharRange fmt,
                      const A &...args) {
    return detail::format_impl(writer, fmtn, false, fmt, args...);
}

template<typename R, typename ...A>
Ptrdiff format(R &&writer, ConstCharRange fmt, const A &...args) {
    Size fmtn = 0;
    return format(writer, fmtn, fmt, args...);
}

} /* namespace ostd */

#endif
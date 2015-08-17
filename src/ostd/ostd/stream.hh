/* Generic stream implementation for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OSTD_STREAM_HH
#define OSTD_STREAM_HH

#include <sys/types.h>

#include "ostd/platform.hh"
#include "ostd/types.hh"
#include "ostd/range.hh"
#include "ostd/type_traits.hh"
#include "ostd/string.hh"
#include "ostd/utility.hh"
#include "ostd/format.hh"

namespace ostd {

#ifndef OSTD_PLATFORM_WIN32
using StreamOffset = off_t;
#else
using StreamOffset = __int64;
#endif

enum class StreamSeek {
    cur = SEEK_CUR,
    end = SEEK_END,
    set = SEEK_SET
};

template<typename T = char, bool = IsPod<T>::value>
struct StreamRange;

namespace detail {
    template<Size N>
    struct FormatOutRange: OutputRange<FormatOutRange<N>, char> {
        FormatOutRange(char *buf): buf(buf), idx(0) {}
        FormatOutRange(const FormatOutRange &r): buf(r.buf), idx(r.idx) {}
        char *buf;
        Size idx;
        bool put(char v) {
            if (idx < N) {
                buf[idx++] = v;
                return true;
            }
            return false;
        }
    };

    struct UnsafeWritefRange: OutputRange<UnsafeWritefRange, char> {
        UnsafeWritefRange(char *p): p_ptr(p) {}
        bool put(char c) {
            *p_ptr++ = c;
            return true;
        }
        char *p_ptr;
    };
}

struct Stream {
private:
    struct StNat {};

    bool write_impl(ConstCharRange s) {
        return write_bytes(s.data(), s.size()) == s.size();
    }

    template<typename T>
    inline bool write_impl(const T &v, EnableIf<
        !IsConstructible<ConstCharRange, const T &>::value, StNat
    > = StNat()) {
        return write(ostd::to_string(v));
    }

public:
    using Offset = StreamOffset;

    virtual ~Stream() {}

    virtual void close() = 0;

    virtual bool end() const = 0;

    virtual Offset size() {
        Offset p = tell();
        if ((p < 0) || !seek(0, StreamSeek::end)) return -1;
        Offset e = tell();
        return ((p == e) || seek(p, StreamSeek::set)) ? e : -1;
    }

    virtual bool seek(Offset, StreamSeek = StreamSeek::set) {
        return false;
    }

    virtual Offset tell() const { return -1; }

    virtual bool flush() { return true; }

    virtual Size read_bytes(void *, Size) { return 0; }
    virtual Size write_bytes(const void *, Size) { return 0; }

    virtual int getchar() {
        byte c;
        return (read_bytes(&c, 1) == 1) ? c : -1;
    }

    virtual bool putchar(int c) {
        byte wc = byte(c);
        return write_bytes(&wc, 1) == 1;
    }

    template<typename T>
    bool write(const T &v) {
        return write_impl(v);
    }

    template<typename T, typename ...A>
    bool write(const T &v, const A &...args) {
        return write(v) && write(args...);
    }

    template<typename T>
    bool writeln(const T &v) {
        return write(v) && putchar('\n');
    }

    template<typename T, typename ...A>
    bool writeln(const T &v, const A &...args) {
        return write(v) && write(args...) && putchar('\n');
    }

    template<typename ...A>
    bool writef(ConstCharRange fmt, const A &...args) {
        char buf[512];
        Ptrdiff need = format(detail::FormatOutRange<sizeof(buf)>(buf),
            fmt, args...);
        if (need < 0)
            return false;
        else if (Size(need) < sizeof(buf))
            return write_bytes(buf, need) == Size(need);
        Vector<char> s;
        s.reserve(need);
        format(detail::UnsafeWritefRange(s.data()), fmt, args...);
        return write_bytes(s.data(), need) == Size(need);
    }

    template<typename ...A>
    bool writefln(ConstCharRange fmt, const A &...args) {
        return writef(fmt, args...) && putchar('\n');
    }

    template<typename T = char>
    StreamRange<T> iter();

    template<typename T> Size put(const T *v, Size count) {
        return write_bytes(v, count * sizeof(T)) / sizeof(T);
    }

    template<typename T> bool put(T v) {
        return write_bytes(&v, sizeof(T)) == sizeof(T);
    }

    template<typename T> Size get(T *v, Size count) {
        return read_bytes(v, count * sizeof(T)) / sizeof(T);
    }

    template<typename T> bool get(T &v) {
        return read_bytes(&v, sizeof(T)) == sizeof(T);
    }

    template<typename T> T get() {
        T r;
        return get(r) ? r : T();
    }
};

template<typename T>
struct StreamRange<T, true>: InputRange<
    StreamRange<T>, InputRangeTag, T, T, Size, StreamOffset
> {
    StreamRange() = delete;
    StreamRange(Stream &s): p_stream(&s), p_size(s.size()) {}
    StreamRange(const StreamRange &r): p_stream(r.p_stream), p_size(r.p_size) {}

    bool empty() const {
        return (p_size - p_stream->tell()) < StreamOffset(sizeof(T));
    }

    bool pop_front() {
        if (empty()) return false;
        T val;
        return !!p_stream->read_bytes(&val, sizeof(T));
    }

    T front() const {
        T val;
        p_stream->seek(-p_stream->read_bytes(&val, sizeof(T)), StreamSeek::cur);
        return val;
    }

    bool equals_front(const StreamRange &s) const {
        return p_stream->tell() == s.p_stream->tell();
    }

    bool put(T val) {
        Size v = p_stream->write_bytes(&val, sizeof(T));
        p_size += v;
        return (v == sizeof(T));
    }

    Size put_n(const T *p, Size n) {
        return p_stream->put(p, n);
    }

    Size copy(RemoveCv<T> *p, Size n = -1) {
        if (n == Size(-1)) {
            n = p_stream->size() / sizeof(T);
        }
        return p_stream->get(p, n);
    }

private:
    Stream *p_stream;
    StreamOffset p_size;
};

template<typename T>
inline StreamRange<T> Stream::iter() {
    return StreamRange<T>(*this);
}

}

#endif
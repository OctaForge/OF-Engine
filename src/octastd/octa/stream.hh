/* Generic stream implementation for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_STREAM_HH
#define OCTA_STREAM_HH

#include <sys/types.h>

#include "octa/platform.hh"
#include "octa/types.hh"
#include "octa/range.hh"
#include "octa/type_traits.hh"
#include "octa/string.hh"
#include "octa/utility.hh"
#include "octa/format.hh"

namespace octa {

#ifndef OCTA_PLATFORM_WIN32
using StreamOffset = off_t;
#else
using StreamOffset = __int64;
#endif

enum class StreamSeek {
    cur = SEEK_CUR,
    end = SEEK_END,
    set = SEEK_SET
};

template<typename T = char, bool = octa::IsPod<T>::value>
struct StreamRange;

namespace detail {
    template<octa::Size N>
    struct FormatOutRange: octa::OutputRange<FormatOutRange<N>, char> {
        FormatOutRange(char *buf): buf(buf), idx(0) {}
        FormatOutRange(const FormatOutRange &r): buf(r.buf), idx(r.idx) {}
        char *buf;
        octa::Size idx;
        bool put(char v) {
            if (idx < N) {
                buf[idx++] = v;
                return true;
            }
            return false;
        }
    };
}

struct Stream {
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

    virtual octa::Size read_bytes(void *, octa::Size) { return 0; }
    virtual octa::Size write_bytes(const void *, octa::Size) { return 0; }

    virtual int getchar() {
        octa::byte c;
        return (read_bytes(&c, 1) == 1) ? c : -1;
    }

    virtual bool putchar(int c) {
        octa::byte wc = octa::byte(c);
        return write_bytes(&wc, 1) == 1;
    }

    virtual bool write(const char *s) {
        octa::Size len = strlen(s);
        return write_bytes(s, len) == len;
    }

    virtual bool write(const octa::String &s) {
        return write_bytes(s.data(), s.size()) == s.size();
    }

    template<typename T> bool write(const T &v) {
        return write(octa::to_string(v));
    }

    template<typename T, typename ...A>
    bool write(const T &v, const A &...args) {
        return write(v) && write(args...);
    }

    virtual bool writeln(const octa::String &s) {
        return write(s) && putchar('\n');
    }

    virtual bool writeln(const char *s) {
        return write(s) && putchar('\n');
    }

    template<typename T> bool writeln(const T &v) {
        return write(v) && putchar('\n');
    }

    template<typename T, typename ...A>
    bool writeln(const T &v, const A &...args) {
        return write(v) && write(args...) && putchar('\n');
    }

    template<typename ...A>
    bool writef(const char *fmt, const A &...args) {
        char buf[512];
        octa::Size need = octa::format(octa::detail::FormatOutRange<
            sizeof(buf)>(buf), fmt, args...);
        if (need < sizeof(buf))
            return write_bytes(buf, need) == need;
        octa::String s;
        s.reserve(need);
        s[need] = '\0';
        octa::format(s.iter(), fmt, args...);
        return write_bytes(s.data(), need) == need;
    }

    template<typename ...A>
    bool writef(const octa::String &fmt, const A &...args) {
        return writef(fmt.data(), args...);
    }

    template<typename ...A>
    bool writefln(const char *fmt, const A &...args) {
        return writef(fmt, args...) && putchar('\n');
    }

    template<typename ...A>
    bool writefln(const octa::String &fmt, const A &...args) {
        return writefln(fmt.data(), args...);
    }

    template<typename T = char>
    StreamRange<T> iter();

    template<typename T> octa::Size put(const T *v, octa::Size count) {
        return write_bytes(v, count * sizeof(T)) / sizeof(T);
    }

    template<typename T> bool put(T v) {
        return write_bytes(&v, sizeof(T)) == sizeof(T);
    }

    template<typename T> octa::Size get(T *v, octa::Size count) {
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
    StreamRange<T>, octa::InputRangeTag, T, T, octa::Size, StreamOffset
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
        octa::Size v = p_stream->write_bytes(&val, sizeof(T));
        p_size += v;
        return (v == sizeof(T));
    }

    octa::Size put_n(const T *p, octa::Size n) {
        return p_stream->put(p, n);
    }

    octa::Size copy(octa::RemoveCv<T> *p, octa::Size n = -1) {
        if (n == octa::Size(-1)) {
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
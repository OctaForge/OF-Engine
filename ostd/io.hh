/* Standard I/O implementation for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OSTD_IO_HH
#define OSTD_IO_HH

#include <stdio.h>

#include "ostd/platform.hh"
#include "ostd/string.hh"
#include "ostd/stream.hh"
#include "ostd/format.hh"

namespace ostd {

enum class StreamMode {
    read, write, append,
    update = 1 << 2
};

namespace detail {
    static const char *filemodes[] = {
        "rb", "wb", "ab", nullptr, "rb+", "wb+", "ab+"
    };
}

struct FileStream: Stream {
    FileStream(): p_f(), p_owned(false) {}
    FileStream(const FileStream &) = delete;
    FileStream(FileStream &&s): p_f(s.p_f), p_owned(s.p_owned) {
        s.p_f = nullptr;
        s.p_owned = false;
    }

    FileStream(const char *path, StreamMode mode): p_f() {
        open(path, mode);
    }

    template<typename A>
    FileStream(const AnyString<A> &path, StreamMode mode): p_f() {
        open(path, mode);
    }

    FileStream(FILE *f): p_f(f), p_owned(false) {}

    ~FileStream() { close(); }

    FileStream &operator=(const FileStream &) = delete;
    FileStream &operator=(FileStream &&s) {
        close();
        swap(s);
        return *this;
    }

    bool open(const char *path, StreamMode mode) {
        if (p_f) return false;
        p_f = fopen(path, detail::filemodes[Size(mode)]);
        p_owned = true;
        return is_open();
    }

    template<typename A>
    bool open(const AnyString<A> &path, StreamMode mode) {
        return open(path.data(), mode);
    }

    bool open(FILE *f) {
        if (p_f) return false;
        p_f = f;
        p_owned = false;
        return is_open();
    }

    bool is_open() const { return p_f != nullptr; }
    bool is_owned() const { return p_owned; }

    void close() {
        if (p_f && p_owned) fclose(p_f);
        p_f = nullptr;
        p_owned = false;
    }

    bool end() const {
        return feof(p_f) != 0;
    }

    bool seek(StreamOffset pos, StreamSeek whence = StreamSeek::set) {
#ifndef OSTD_PLATFORM_WIN32
        return fseeko(p_f, pos, int(whence)) >= 0;
#else
        return _fseeki64(p_f, pos, int(whence)) >= 0;
#endif
    }

    StreamOffset tell() const {
#ifndef OSTD_PLATFORM_WIN32
        return ftello(p_f);
#else
        return _ftelli64(p_f);
#endif
    }

    bool flush() { return !fflush(p_f); }

    Size read_bytes(void *buf, Size count) {
        return fread(buf, 1, count, p_f);
    }

    Size write_bytes(const void *buf, Size count) {
        return fwrite(buf, 1, count, p_f);
    }

    int getchar() {
        return fgetc(p_f);
    }

    bool putchar(int c) {
        return  fputc(c, p_f) != EOF;
    }

    bool write(const char *s) {
        return fputs(s, p_f) != EOF;
    }

    void swap(FileStream &s) {
        ostd::swap(p_f, s.p_f);
        ostd::swap(p_owned, s.p_owned);
    }

    FILE *get_file() { return p_f; }

private:
    FILE *p_f;
    bool p_owned;
};

static FileStream in(::stdin);
static FileStream out(::stdout);
static FileStream err(::stderr);

/* no need to call anything from FileStream, prefer simple calls... */

inline void write(const char *s) {
    fputs(s, ::stdout);
}

template<typename A>
inline void write(const AnyString<A> &s) {
    fwrite(s.data(), 1, s.size(), ::stdout);
}

template<typename T>
inline void write(const T &v) {
    write(ostd::to_string(v));
}

template<typename T, typename ...A>
inline void write(const T &v, const A &...args) {
    write(v);
    write(args...);
}

inline void writeln(const char *s) {
    write(s);
    putc('\n', ::stdout);
}

template<typename A>
inline void writeln(const AnyString<A> &s) {
    write(s);
    putc('\n', ::stdout);
}

template<typename T>
inline void writeln(const T &v) {
    writeln(ostd::to_string(v));
}

template<typename T, typename ...A>
inline void writeln(const T &v, const A &...args) {
    write(v);
    write(args...);
    putc('\n', ::stdout);
}

namespace detail {
    struct UnsafeWritefRange: OutputRange<UnsafeWritefRange, char> {
        UnsafeWritefRange(char *p): p_ptr(p) {}
        bool put(char c) {
            *p_ptr++ = c;
            return true;
        }
        char *p_ptr;
    };
}

template<typename ...A>
inline void writef(const char *fmt, const A &...args) {
    char buf[512];
    Ptrdiff need = format(detail::FormatOutRange<sizeof(buf)>(buf),
        fmt, args...);
    if (need < 0) return;
    else if (Size(need) < sizeof(buf)) {
        fwrite(buf, 1, need, ::stdout);
        return;
    }
    Vector<char> s;
    s.reserve(need);
    format(detail::UnsafeWritefRange(s.data()), fmt, args...);
    fwrite(s.data(), 1, need, ::stdout);
}

template<typename AL, typename ...A>
inline void writef(const AnyString<AL> &fmt,
                          const A &...args) {
    writef(fmt.data(), args...);
}

template<typename ...A>
inline void writefln(const char *fmt, const A &...args) {
    writef(fmt, args...);
    putc('\n', ::stdout);
}

template<typename AL, typename ...A>
inline void writefln(const AnyString<AL> &fmt,
                            const A &...args) {
    writef(fmt, args...);
    putc('\n', ::stdout);
}

} /* namespace ostd */

#endif
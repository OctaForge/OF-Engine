/* Generic stream implementation for OctaSTD.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OCTA_STREAM_H
#define OCTA_STREAM_H

#include <stdio.h>
#include <sys/types.h>

#include "octa/types.h"
#include "octa/range.h"
#include "octa/string.h"
#include "octa/type_traits.h"

namespace octa {

/* off_t is POSIX - will also work on windows with mingw/clang, but FIXME */
using StreamOffset = off_t;

enum class StreamSeek {
    cur = SEEK_CUR,
    end = SEEK_END,
    set = SEEK_SET
};

template<typename T = char, bool = octa::IsPod<T>::value>
struct StreamRange;

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

    virtual octa::Size read(void *, octa::Size) { return 0; }
    virtual octa::Size write(const void *, octa::Size) { return 0; }

    template<typename T = char>
    StreamRange<T> iter();
};

template<typename T>
struct StreamRange<T, true>: InputRange<
    StreamRange<T>, octa::InputRangeTag, T, T, octa::Size, StreamOffset
> {
    StreamRange(): p_stream(), p_size(0) {}
    StreamRange(Stream &s): p_stream(&s), p_size(s.size()) {}
    StreamRange(const StreamRange &r): p_stream(r.p_stream), p_size(r.p_size) {}

    bool empty() const {
        return p_stream->tell() == p_size;
    }

    bool pop_front() {
        if (empty()) return false;
        T val;
        return !!p_stream->read(&val, sizeof(T));
    }

    T front() const {
        T val;
        p_stream->seek(-p_stream->read(&val, sizeof(T)), StreamSeek::cur);
        return val;
    }

    virtual bool equals_front(const StreamRange &s) const {
        return p_stream->tell() == s.p_stream->tell();
    }

    void put(T val) {
        p_size += p_stream->write(&val, sizeof(T));
    }

private:
    Stream *p_stream;
    StreamOffset p_size;
};

template<typename T>
inline StreamRange<T> Stream::iter() {
    return StreamRange<T>(*this);
}

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
    FileStream(): p_f() {}
    FileStream(const FileStream &s) = delete;

    FileStream(const octa::String &path, StreamMode mode): p_f() {
        open(path, mode);
    }

    ~FileStream() { close(); }

    bool open(const octa::String &path, StreamMode mode) {
        if (p_f) return false;
        p_f = fopen(path.data(), octa::detail::filemodes[octa::Size(mode)]);
        return p_f != nullptr;
    }

    void close() {
        if (p_f) fclose(p_f);
        p_f = nullptr;
    }

    bool end() const {
        return feof(p_f) != 0;
    }

    bool seek(StreamOffset pos, StreamSeek whence = StreamSeek::set) {
        return fseeko(p_f, pos, int(whence)) >= 0;
    }

    StreamOffset tell() const {
        return ftello(p_f);
    }

    bool flush() { return !fflush(p_f); }

    octa::Size read(void *buf, octa::Size count) {
        return fread(buf, 1, count, p_f);
    }

    octa::Size write(const void *buf, octa::Size count) {
        return fwrite(buf, 1, count, p_f);
    }

private:
    FILE *p_f;
};

}

#endif
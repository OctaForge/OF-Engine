/* Filesystem API for OctaSTD. Currently POSIX only.
 *
 * This file is part of OctaSTD. See COPYING.md for futher information.
 */

#ifndef OSTD_FILESYSTEM_HH
#define OSTD_FILESYSTEM_HH

#include "ostd/platform.hh"

#ifdef OSTD_PLATFORM_WIN32
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#else
#include <dirent.h>
#include <sys/stat.h>
#endif

#include "ostd/types.hh"
#include "ostd/range.hh"
#include "ostd/vector.hh"
#include "ostd/string.hh"
#include "ostd/array.hh"
#include "ostd/algorithm.hh"

namespace ostd {

enum class FileType {
    unknown, regular, fifo, character, directory, block, symlink, socket
};

struct FileInfo;

#ifdef OSTD_PLATFORM_WIN32
static constexpr char PATH_SEPARATOR = '\\';
#else
static constexpr char PATH_SEPARATOR = '/';
#endif

#ifdef OSTD_PLATFORM_WIN32
namespace detail {
    inline time_t filetime_to_time_t(const FILETIME &ft) {
        ULARGE_INTEGER ul;
        ul.LowPart  = ft.dwLowDateTime;
        ul.HighPart = ft.dwHighDateTime;
        return (time_t)((ul.QuadPart / 10000000ULL) - 11644473600ULL);
    }
}
#endif

inline void path_normalize(CharRange) {
    /* TODO */
}

struct FileInfo {
    FileInfo() {}

    FileInfo(const FileInfo &i):
        p_slash(i.p_slash), p_dot(i.p_dot), p_type(i.p_type),
        p_path(i.p_path), p_atime(i.p_atime), p_mtime(i.p_mtime),
        p_ctime(i.p_ctime) {}

    FileInfo(FileInfo &&i):
        p_slash(i.p_slash), p_dot(i.p_dot), p_type(i.p_type),
        p_path(move(i.p_path)), p_atime(i.p_atime), p_mtime(i.p_mtime),
        p_ctime(i.p_ctime) {
        i.p_slash = i.p_dot = npos;
        i.p_type = FileType::unknown;
        i.p_atime = i.p_ctime = i.p_mtime = 0;
    }

    FileInfo(ConstCharRange path) {
        init_from_str(path);
    }

    FileInfo &operator=(const FileInfo &i) {
        p_slash = i.p_slash;
        p_dot = i.p_dot;
        p_type = i.p_type;
        p_path = i.p_path;
        p_atime = i.p_atime;
        p_mtime = i.p_mtime;
        p_ctime = i.p_ctime;
        return *this;
    }

    FileInfo &operator=(FileInfo &&i) {
        swap(i);
        return *this;
    }

    ConstCharRange path() const { return p_path.iter(); }

    ConstCharRange filename() const {
        return path().slice((p_slash == npos) ? 0 : (p_slash + 1),
                            p_path.size());
    }

    ConstCharRange stem() const {
        return path().slice((p_slash == npos) ? 0 : (p_slash + 1),
                            (p_dot == npos) ? p_path.size() : p_dot);
    }

    ConstCharRange extension() const {
        return (p_dot == npos) ? ConstCharRange()
                               : path().slice(p_dot, p_path.size());
    }

    FileType type() const { return p_type; }

    void normalize() {
        path_normalize(p_path.iter());
        init_from_str(p_path.iter());
    }

    time_t atime() const { return p_atime; }
    time_t mtime() const { return p_mtime; }
    time_t ctime() const { return p_ctime; }

    void swap(FileInfo &i) {
        detail::swap_adl(i.p_slash, p_slash);
        detail::swap_adl(i.p_dot, p_dot);
        detail::swap_adl(i.p_type, p_type);
        detail::swap_adl(i.p_path, p_path);
        detail::swap_adl(i.p_atime, p_atime);
        detail::swap_adl(i.p_mtime, p_mtime);
        detail::swap_adl(i.p_ctime, p_ctime);
    }

private:
    void init_from_str(ConstCharRange path) {
#ifdef OSTD_PLATFORM_WIN32
        WIN32_FILE_ATTRIBUTE_DATA attr;
        if (!GetFileAttributesEx(path, GetFileExInfoStandard, &attr) ||
            attr.dwFileAttributes == INVALID_FILE_ATTRIBUTES)
#else
        struct stat st;
        if (stat(String(path).data(), &st) < 0)
#endif
        {
            p_slash = p_dot = npos;
            p_type = FileType::unknown;
            p_path.clear();
            p_atime = p_mtime = p_ctime = 0;
            return;
        }
        p_path = path;
        ConstCharRange r = p_path.iter();

        ConstCharRange found = find_last(r, PATH_SEPARATOR);
        if (found.empty())
            p_slash = npos;
        else
            p_slash = r.distance_front(found);

        found = find(filename(), '.');
        if (found.empty())
            p_dot = npos;
        else
            p_dot = r.distance_front(found);

#ifdef OSTD_PLATFORM_WIN32
        if (attr.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
            p_type = FileType::directory;
        else if (attr.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT)
            p_type = FileType::symlink;
        else if (attr.dwFileAttributes & (FILE_ATTRIBUTE_ARCHIVE |
                                          FILE_ATTRIBUTE_COMPRESSED |
                                          FILE_ATTRIBUTE_COMPRESSED |
                                          FILE_ATTRIBUTE_HIDDEN |
                                          FILE_ATTRIBUTE_NORMAL |
                                          FILE_ATTRIBUTE_SPARSE_FILE |
                                          FILE_ATTRIBUTE_TEMPORARY))
            p_type = FileType::regular;
        else
            p_type = FileType::unknown;

        p_atime = detail::filetime_to_time_t(attr.ftLastAccessTime);
        p_mtime = detail::filetime_to_time_t(attr.ftLastWriteTime);
        p_ctime = detail::filetime_to_time_t(attr.ftCreationTime);
#else
        if (S_ISREG(st.st_mode))
            p_type = FileType::regular;
        else if (S_ISDIR(st.st_mode))
            p_type = FileType::directory;
        else if (S_ISCHR(st.st_mode))
            p_type = FileType::character;
        else if (S_ISBLK(st.st_mode))
            p_type = FileType::block;
        else if (S_ISFIFO(st.st_mode))
            p_type = FileType::fifo;
        else if (S_ISLNK(st.st_mode))
            p_type = FileType::symlink;
        else if (S_ISSOCK(st.st_mode))
            p_type = FileType::socket;
        else
            p_type = FileType::unknown;

        p_atime = st.st_atime;
        p_mtime = st.st_mtime;
        p_ctime = st.st_ctime;
#endif
    }

    Size p_slash = npos, p_dot = npos;
    FileType p_type = FileType::unknown;
    String p_path;

    time_t p_atime = 0, p_mtime = 0, p_ctime = 0;
};

struct DirectoryRange;

#ifndef OSTD_PLATFORM_WIN32
struct DirectoryStream {
    friend struct DirectoryRange;

    DirectoryStream(): p_d(), p_de(), p_dev(), p_path() {}
    DirectoryStream(const DirectoryStream &) = delete;
    DirectoryStream(DirectoryStream &&s): p_d(s.p_d), p_de(s.p_de),
                                          p_dev(s.p_dev),
                                          p_path(move(s.p_path)) {
        s.p_d = nullptr;
        s.p_de = nullptr;
        memset(&s.p_dev, 0, sizeof(s.p_dev));
    }

    DirectoryStream(ConstCharRange path): p_d() {
        open(path);
    }

    ~DirectoryStream() { close(); }

    DirectoryStream &operator=(const DirectoryStream &) = delete;
    DirectoryStream &operator=(DirectoryStream &&s) {
        close();
        swap(s);
        return *this;
    }

    bool open(ConstCharRange path) {
        if (p_d || (path.size() > FILENAME_MAX)) return false;
        char buf[FILENAME_MAX + 1];
        memcpy(buf, &path[0], path.size());
        buf[path.size()] = '\0';
        p_d = opendir(buf);
        if (!pop_front() || !skip_dots()) {
            close();
            return false;
        }
        p_path = path;
        return true;
    }

    bool is_open() const { return p_d != nullptr; }

    void close() {
        if (p_d) closedir(p_d);
        p_d = nullptr;
        p_de = nullptr;
    }

    long size() const {
        if (!p_d) return -1;
        DIR *td = opendir(p_path.data());
        if (!td) return -1;
        long ret = 0;
        struct dirent rdv;
        struct dirent *rd;
        while (pop_front(td, &rdv, &rd))
            ret += strcmp(rd->d_name, ".") && strcmp(rd->d_name, "..");
        closedir(td);
        return ret;
    }

    bool rewind() {
        if (!p_d) return false;
        rewinddir(p_d);
        if (!pop_front() || !skip_dots()) {
            close();
            return false;
        }
        return true;
    }

    bool empty() const {
        return !p_de;
    }

    FileInfo read() {
        if (!pop_front())
            return FileInfo();
        return front();
    }

    void swap(DirectoryStream &s) {
        detail::swap_adl(p_d, s.p_d);
        detail::swap_adl(p_de, s.p_de);
        detail::swap_adl(p_path, s.p_path);
    }

    DirectoryRange iter();

private:
    static bool pop_front(DIR *d, struct dirent *dev, struct dirent **de) {
        if (!d) return false;
        if (readdir_r(d, dev, de))
            return false;
        return !!*de;
    }

    bool pop_front() {
        return pop_front(p_d, &p_dev, &p_de);
    }

    bool skip_dots() {
        while (p_de && (!strcmp(p_de->d_name, ".") ||
                        !strcmp(p_de->d_name, "..")))
            if (readdir_r(p_d, &p_dev, &p_de))
                return false;
        return !!p_de;
    }

    FileInfo front() const {
        if (!p_de)
            return FileInfo();
        String ap = p_path;
        ap += PATH_SEPARATOR;
        ap += (const char *)p_de->d_name;
        return FileInfo(ap);
    }

    DIR *p_d;
    struct dirent *p_de;
    struct dirent  p_dev;
    String p_path;
};

#else /* OSTD_PLATFORM_WIN32 */

struct DirectoryStream {
    friend struct DirectoryRange;

    DirectoryStream(): p_handle(INVALID_HANDLE_VALUE), p_data(), p_path() {}
    DirectoryStream(const DirectoryStream &) = delete;
    DirectoryStream(DirectoryStream &&s): p_handle(s.p_handle),
                                          p_data(s.p_data),
                                          p_path(move(s.p_path)) {
        s.p_handle = INVALID_HANDLE_VALUE;
        memset(&s.p_data, 0, sizeof(s.p_data));
    }

    DirectoryStream(ConstCharRange path): p_d() {
        open(path);
    }

    ~DirectoryStream() { close(); }

    DirectoryStream &operator=(const DirectoryStream &) = delete;
    DirectoryStream &operator=(DirectoryStream &&s) {
        close();
        swap(s);
        return *this;
    }

    bool open(ConstCharRange path) {
        if (p_handle || (path.size() >= 1024)) return false;
        char buf[1024];
        memcpy(buf, &path[0], path.size());
        buf[path.size()] = '\0';
        p_handle = FindFirstFile(buf, &p_data);
        if (p_handle == INVALID_HANDLE_VALUE)
            return false;
        while (!strcmp(p_data.cFileName, ".") ||
               !strcmp(p_data.cFileName, ".."))
            if (!FindNextFile(p_handle, &p_data)) {
                FindClose(p_handle);
                p_handle = INVALID_HANDLE_VALUE;
                p_data.cFileName[0] = '\0';
                return false;
            }
        p_path = path;
        return true;
    }

    bool is_open() const { return p_handle != INVALID_HANDLE_VALUE; }

    void close() {
        if (p_handle != INVALID_HANDLE_VALUE)
            FindClose(p_handle);
        p_handle = INVALID_HANDLE_VALUE;
        p_data.cFileName[0] = '\0';
    }

    long size() const {
        if (p_handle == INVALID_HANDLE_VALUE)
            return -1;
        WIN32_FIND_DATA wfd;
        HANDLE *td = FindFirstFile(p_path.data(), &wfd);
        if (td == INVALID_HANDLE_VALUE)
            return -1;
        while (!strcmp(wfd.cFileName, ".") && !strcmp(wfd.cFileName, ".."))
            if (!FindNextFile(td, &wfd)) {
                FindClose(td);
                return 0;
            }
        long ret = 1;
        while (FindNextFile(td, &wfd))
            ++ret;
        FindClose(td);
        return ret;
    }

    bool rewind() {
        if (p_handle != INVALID_HANDLE_VALUE)
            FindClose(p_handle);
        p_handle = FindFirstFile(p_path.data(), &p_data);
        if (p_handle == INVALID_HANDLE_VALUE) {
            p_data.cFileName[0] = '\0';
            return false;
        }
        while (!strcmp(p_data.cFileName, ".") ||
               !strcmp(p_data.cFileName, ".."))
            if (!FindNextFile(p_handle, &p_data)) {
                FindClose(p_handle);
                p_handle = INVALID_HANDLE_VALUE;
                p_data.cFileName[0] = '\0';
                return false;
            }
        return true;
    }

    bool empty() const {
        return p_data.cFileName[0] == '\0';
    }

    FileInfo read() {
        if (!pop_front())
            return FileInfo();
        return front();
    }

    void swap(DirectoryStream &s) {
        detail::swap_adl(p_d, s.p_d);
        detail::swap_adl(p_de, s.p_de);
        detail::swap_adl(p_path, s.p_path);
    }

    DirectoryRange iter();

private:
    bool pop_front() {
        if (!is_open())
            return false;
        if (!FindNextFile(p_handle, &p_data)) {
            p_data.cFileName[0] = '\0';
            return false;
        }
        return true;
    }

    FileInfo front() const {
        if (empty())
            return FileInfo();
        String ap = p_path;
        ap += PATH_SEPARATOR;
        ap += (const char *)p_data.cFileName;
        return FileInfo(ap);
    }

    HANDLE *p_handle;
    WIN32_FIND_DATA p_data;
    String p_path;
};
#endif /* OSTD_PLATFORM_WIN32 */

struct DirectoryRange: InputRange<
    DirectoryRange, InputRangeTag, FileInfo, FileInfo, Size, long
> {
    DirectoryRange() = delete;
    DirectoryRange(DirectoryStream &s): p_stream(&s) {}
    DirectoryRange(const DirectoryRange &r): p_stream(r.p_stream) {}

    DirectoryRange &operator=(const DirectoryRange &r) {
        p_stream = r.p_stream;
        return *this;
    }

    bool empty() const {
        return p_stream->empty();
    }

    bool pop_front() {
        return p_stream->pop_front();
    }

    FileInfo front() const {
        return p_stream->front();
    }

    bool equals_front(const DirectoryRange &s) const {
        return p_stream == s.p_stream;
    }

private:
    DirectoryStream *p_stream;
};

inline DirectoryRange DirectoryStream::iter() {
    return DirectoryRange(*this);
}

namespace detail {
    template<Size I> struct PathJoin {
        template<typename T, typename ...A>
        static void join(String &s, const T &a, const A &...b) {
            s += a;
            s += PATH_SEPARATOR;
            PathJoin<I - 1>::join(s, b...);
        }
    };

    template<> struct PathJoin<1> {
        template<typename T>
        static void join(String &s, const T &a) {
            s += a;
        }
    };
}

template<typename ...A>
inline FileInfo path_join(const A &...args) {
    String path;
    detail::PathJoin<sizeof...(A)>::join(path, args...);
    path_normalize(path.iter());
    return FileInfo(path);
}

inline bool directory_change(ConstCharRange path) {
    char buf[1024];
    if (path.size() >= 1024)
        return false;
    memcpy(buf, path.data(), path.size());
    buf[path.size()] = '\0';
#ifndef OSTD_PLATFORM_WIN32
    return !chdir(buf);
#else
    return !_chdir(buf);
#endif
}

} /* namespace ostd */

#endif
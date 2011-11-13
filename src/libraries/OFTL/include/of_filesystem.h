/* File: of_filesystem.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  OF Filesystem access, common header file.
 *  The Filesystem module has implementation files for
 *  Windows and POSIX.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_FILESYSTEM_H
#define OF_FILESYSTEM_H

#include "of_utils.h"
#include "of_string.h"
#include "of_list.h"
#include "of_vector.h"

#include <time.h>

/* Package: filesystem
 * A namespace containing filesystem access utilities.
 */
namespace filesystem
{
    /* Enum: File_Type
     * This enumeration represents the file types
     * defined by the module.
     *
     * Types:
     *  FILE_UNKNOWN - unknown file type.
     *  FILE_FIFO - named pipe (FIFO) type (POSIX only).
     *  FILE_CHR - character device type (POSIX only).
     *  FILE_DIR - directory type.
     *  FILE_BLK - block device type (POSIX only).
     *  FILE_REG - regular file type.
     *  FILE_LNK - symbolic link type.
     *  FILE_SOCK - UNIX domain socket type (POSIX only).
     *  FILE_WHT - whiteout file type (POSIX only).
     */
    enum File_Type
    {
        FILE_UNKNOWN = 0,
        FILE_FIFO,
        FILE_CHR,
        FILE_DIR,
        FILE_BLK,
        FILE_REG,
        FILE_LNK,
        FILE_SOCK,
        FILE_WHT
    };

    struct File_Info;
    struct File_Iterator;
    struct File_Iterator_Base;

    /* Typedef: File_Vector
     * Defined as types:: <Vector> < <File_Info> >. Returned by <list>.
     */
    typedef types::Vector<File_Info> File_Vector;

    /* Function: separator
     * Returns a path separator character for the platform
     * (as simple char). On POSIX, it's /, on Windows,
     * it's \.
     */
    const char separator();

    /* Function: list
     * Returns a <File_Vector> containing complete contents
     * of the directory given by the argument.
     *
     * Basically performs
     * (start code)
     *     File_Vector ret;
     *     for (File_Iterator it = path.begin(); it != path.end(); ++it)
     *         ret.push_back(*it);
     *     return ret;
     * (end)
     *
     * As this has to make a vector and push everything, it's less efficient
     * than just iterating over a directory, so do this only when really
     * required.
     */
    inline File_Vector list(const File_Info& path);

    /* Function: normalize_path
     * Normalizes a path string given by the argument. As the argument
     * is a reference, it simply writes into the passed string. It
     * has no return value.
     */
    void normalize_path(types::String& str);

    /* Function: join_path
     * Joins a set of const char*'s into a path and returns a
     * <File_Info> of the path. Example:
     *
     * (start code)
     *      // f will be foo/bar/baz/bah.txt on POSIX
     *      // and foo\bar\baz\bah.txt on Windows.
     *     File_Info f = filesystem::join_path(
     *         "foo", "bar", "baz", "bah.txt"
     *     );
     * (end)
     */
    inline File_Info join_path(const char *first, ...);

    /* Struct: File_Info
     * This structure represents a state of a file or directory.
     * Directories define iterators. All types are parseable
     * into whole path, stem (filename minus extension),
     * filename and extension.
     *
     * You can get their type (see <filesystem.File_Type>), last access
     * time (atime), last modification time (mtime) and
     * creation time (ctime).
     */
    struct File_Info
    {
        /* Typedef: it
         * A directory iterator typedef.
         */
        typedef File_Iterator it;

        /* Constructor: File_Info
         * Empty constructor. Initializes the type as
         * unknown, path as empty string and times
         * to 0.
         */
        File_Info():
            p_slash(types::String::npos), p_dot(types::String::npos),
            p_type(FILE_UNKNOWN), p_path(types::String()),
            p_atime(0), p_mtime(0), p_ctime(0) {}

        /* Constructor: File_Info
         * Constructs a File_Info from another instance of one.
         * Basically a copy.
         */
        File_Info(const File_Info& info):
            p_slash(info.p_slash), p_dot  (info.p_dot  ),
            p_type (info.p_type ), p_path (info.p_path ),
            p_atime(info.p_atime), p_mtime(info.p_mtime),
            p_ctime(info.p_ctime) {}

        /* Constructor: File_Info
         * Constructs a File_Info from a path string (const char*).
         */
        File_Info(const char *path)
        {
            init_from_str(path);
        }

        /* Constructor: File_Info
         * Same as above, but the string type is <String_Base> <char>.
         */
        File_Info(const types::String& path)
        {
            init_from_str(path.get_buf());
        }

        /* Function: begin
         * Directory specific. If called for a file, returns an
         * empty <File_Iterator>. Otherwise, returns an iterator
         * to the first file / directory in the directory.
         */
        File_Iterator begin() const;

        /* Function: end
         * Returns an empty <File_Iterator>. Used for comparison,
         * as incrementing an iterator to the last item in a
         * directory results in empty iterator.
         */
        File_Iterator end() const;

        /* Function: path
         * Returns the whole path (i.e. foo/bar/baz.txt).
         */
        types::String path() const { return p_path; }

        /* Function: stem
         * Returns a "stem", that is a filename
         * without an extension (i.e. when the
         * path is foo/bar/baz.txt, this
         * returns just baz).
         */
        types::String stem() const
        {
            types::String f = filename();

            if (p_dot != types::String::npos)
                return f.substr(0, f.find("."));

            return filename();
        }

        /* Function: filename
         * Returns a filename (i.e. for path foo/bar/baz.txt,
         * this returns baz.txt).
         */
        types::String filename() const
        {
            if (p_slash != types::String::npos)
                return p_path.substr(
                    p_slash + 1, p_path.length() - p_slash - 1
                );
            else
                return p_path;
        }

        /* Function: extension
         * Returns the extension part of the filename (i.e.
         * for path foo/bar/baz.txt, this returns .txt
         * including the dot).
         */
        types::String extension() const
        {
            if (p_dot != types::String::npos)
                return p_path.substr(
                    p_dot, p_path.length() - p_dot
                );
            else
                return types::String();
        }

        /* Function: type
         * Returns the <filesystem.File_Type> of the file or directory
         * assigned to this instance.
         */
        File_Type type() const { return p_type; }

        /* Function: normalize
         * Normalizes the path, that is, gets rid of redundant . and ..,
         * on POSIX it converts backslashes to forward slashes and on
         * Windows it does the opposite.
         */
        void normalize()
        {
            normalize_path(p_path);
            init_from_str (p_path.get_buf());
        }

        /* Function: atime
         * Returns the file / directory last access time as time_t.
         */
        time_t atime() const { return p_atime; }

        /* Function: atime
         * Returns the file / directory last modification time as time_t.
         */
        time_t mtime() const { return p_mtime; }

        /* Function: atime
         * Returns the file / directory creation time as time_t.
         */
        time_t ctime() const { return p_ctime; }

    private:

        void init_from_str(const char *path);

        size_t p_slash;
        size_t p_dot;

        File_Type     p_type;
        types::String p_path;

        time_t p_atime;
        time_t p_mtime;
        time_t p_ctime;
    };

    /* Struct: File_Iterator
     * A "file iterator". Used to iterate directory contents.
     * An instance of this will is returned by the "begin"
     * and "end" methods of <File_Info>.
     *
     * Example that prints names of all files in the current
     * working directory:
     *
     * (start code)
     *     File_Info cwd(".");
     *     for (File_Iterator it = cwd.begin(); it != cwd.end(); ++it)
     *         printf("%s\n", it->filename().get_buf());
     * (end)
     *
     * This is also used by the list function, which inserts all the
     * data from the iteration into a vector.
     *
     * This is a forward iterator type with all properties that are
     * specific to it. Difference type is ptrdiff_t, value type is
     * <File_Info>, reference type is const <File_Info> &, pointer
     * type is const <File_Info>*.
     *
     * A slight difference from other iterators is that both prefix
     * and postfix versions of the ++ operator have the exact same
     * effect.
     */
    struct File_Iterator
    {
        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: val_t */
        typedef File_Info val_t;
        /* Typedef: ref_t */
        typedef const File_Info& ref_t;
        /* Typedef: ptr_t */
        typedef const File_Info* ptr_t;

        /* Constructor: File_Iterator
         * Constructs an empty file iterator, used
         * as an ending iterator.
         */
        File_Iterator();

        /* Constructor: File_Iterator
         * Constructs an iterator from a path given
         * by the argument. The path specifies the
         * directory to iterate.
         *
         * If it's a file or invalid path, it has
         * the same effect as creating an empty
         * iterator.
         */
        File_Iterator(const types::String& path);

        /* Constructor: File_Iterator
         * Constructs an iterator from another one.
         */
        File_Iterator(const File_Iterator& it);

        /* Destructor: File_Iterator
         * Destroys the iterator.
         */
        ~File_Iterator();

        /* Operator: *
         * Dereferencing the iterator returns a <ref_t>.
         */
        ref_t operator*() const;

        /* Operator: ->
         * Pointer-like iterator access.
         */
        ptr_t operator->() const;

        /* Operator: ++
         * Moves to the next item in the directory. Prefix version.
         */
        File_Iterator& operator++();

        /* Operator: ++
         * See above. Postfix version, but it has the same effect.
         */
        File_Iterator& operator++(int) { return operator++(); }

        /* Operator: == */
        bool operator==(const File_Iterator& b);
        /* Operator: != */
        bool operator!=(const File_Iterator& b);

    private:

        File_Iterator_Base *p_base;
    };

    inline File_Vector list(const File_Info& path)
    {
        File_Vector ret;

        for (File_Iterator it = path.begin(); it != path.end(); ++it)
            ret.push_back(*it);

        return ret;
    }

    inline File_Info join_path(const char *first, ...)
    {
        va_list  ap;
        va_start(ap, first);

        char *str = (char*)first;

        types::String path;
        do
        {
            path += str;
            if ((str  = va_arg(ap, char*)))
                path += separator();
        } while (str);

        va_end(ap);

        normalize_path  (path);
        return File_Info(path);
    }
} /* end namespace filesystem */

#endif

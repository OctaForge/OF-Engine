/* File: of_filesystem_win32.cpp
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  OF Filesystem access, Win32 implementation.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#undef WIN32_LEAN_AND_MEAN

#include "of_filesystem.h"

namespace filesystem
{
    time_t filetime_to_time_t(const FILETIME& ft);

    /* The iterator base. Used to provide implementation
     * specific things hidden away from the interface
     * while allowing to keep it the same for all
     * platforms.
     */
    struct File_Iterator_Base
    {
        /* empty ctor for end iterators */
        File_Iterator_Base()
        {
            p_path   = types::String();
            p_handle = INVALID_HANDLE_VALUE;
            p_curr   = File_Info();
        }
    
        /* ctor from a string */
        File_Iterator_Base(const types::String& path)
        {
            p_path  = path;

            types::String p = p_path;
            p              += "\\*.*";

            p_handle = FindFirstFile(p.get_buf(), &p_data);

            if (p_handle == INVALID_HANDLE_VALUE)
            {
                p_curr = File_Info();
                return;
            }

            while ((!strcmp(p_data.cFileName, ".") ||
                    !strcmp(p_data.cFileName, "..")
            )) if (!FindNextFile(p_handle, &p_data))
            {
                FindClose(p_handle);
                p_handle = INVALID_HANDLE_VALUE;
                p_curr   = File_Info();
                return;
            }

            p      = path;
            p     += '\\';
            p     += p_data.cFileName;
            p_curr = File_Info(p);
        }

        /* ctor from another iterator base (pointer) */
        File_Iterator_Base(File_Iterator_Base *it):
            p_path(it->p_path), p_handle(it->p_handle),
            p_data(it->p_data), p_curr(it->p_curr) {}

        /* dtor */
        ~File_Iterator_Base()
        {
            if (p_handle != INVALID_HANDLE_VALUE)
                FindClose(p_handle);
        }

        /* moves on to the next dir */
        void incr()
        {
            if (p_handle == INVALID_HANDLE_VALUE) return;
            if (!FindNextFile(p_handle, &p_data))
                p_curr = File_Info();
            else
            {
                types::String p = p_path;
                p              += '\\';
                p              += p_data.cFileName;
                p_curr          = File_Info(p);
            }
        }

        /* privates: the path, current dir handle,
         * current dir data, current file info.
         */
        types::String   p_path;
        HANDLE          p_handle;
        WIN32_FIND_DATA p_data;
        File_Info       p_curr;
    };

    /* IMPLEMENTATION DETAILS: File_Info
     * Platform specific implementations of File_Info methods.
     */

    /* initializes the File_Info from a single string */
    void File_Info::init_from_str(const char *path)
    {
        WIN32_FILE_ATTRIBUTE_DATA attr;

        if (!GetFileAttributesEx(path, GetFileExInfoStandard, &attr) ||
             attr.dwFileAttributes == INVALID_FILE_ATTRIBUTES)
        {
            p_slash = p_dot = types::String::npos;
            p_type  = FILE_UNKNOWN;
            p_path  = types::String();
            return;
        }

        p_path = path;

        p_slash = p_path.rfind("\\");
        p_dot   = p_path.find(
            ".", p_slash == types::String::npos ? 0 : p_slash
        );

        if (attr.dwFileAttributes&FILE_ATTRIBUTE_DIRECTORY)
            p_type = FILE_DIR;
        else if (attr.dwFileAttributes&FILE_ATTRIBUTE_REPARSE_POINT)
            p_type = FILE_LNK;
        else if (attr.dwFileAttributes&(
            FILE_ATTRIBUTE_ARCHIVE |
            FILE_ATTRIBUTE_COMPRESSED |
            FILE_ATTRIBUTE_COMPRESSED |
            FILE_ATTRIBUTE_HIDDEN |
            FILE_ATTRIBUTE_NORMAL |
            FILE_ATTRIBUTE_SPARSE_FILE |
            FILE_ATTRIBUTE_TEMPORARY
        ))
            p_type = FILE_REG;
        else
            p_type = FILE_UNKNOWN;

        p_atime = filetime_to_time_t(attr.ftLastAccessTime);
        p_mtime = filetime_to_time_t(attr.ftLastWriteTime);
        p_ctime = filetime_to_time_t(attr.ftCreationTime);
    }

    /* begin iterator */
    File_Iterator File_Info::begin() const
    { return File_Iterator(p_path); }

    /* end iterator */
    File_Iterator File_Info::end() const
    { return File_Iterator(); }

    /* IMPLEMENTATION DETAILS: File_Iterator
     * Platform specific implementations of File_Iterator methods.
     */

    File_Iterator::File_Iterator(): p_base(new File_Iterator_Base()) {}

    File_Iterator::File_Iterator(const types::String& path):
        p_base(new File_Iterator_Base(path)) {}

    File_Iterator::File_Iterator(const File_Iterator& it):
        p_base(new File_Iterator_Base(it.p_base)) {}

    File_Iterator::~File_Iterator() { delete p_base; }

    File_Iterator::ref_t File_Iterator::operator *() const
    { return p_base->p_curr; }

    File_Iterator::ptr_t File_Iterator::operator->() const
    { return &p_base->p_curr; }

    File_Iterator& File_Iterator::operator++()
    {
        p_base->incr();
        return *this;
    }

    /* comparators */

    bool File_Iterator::operator==(const File_Iterator& b)
    { return p_base->p_curr.type() == b.p_base->p_curr.type(); }

    bool File_Iterator::operator!=(const File_Iterator& b)
    { return p_base->p_curr.type() != b.p_base->p_curr.type(); }

    /* GLOBAL PUBLIC FUNCTIONS */

    const char separator() { return '\\'; }

    /* PRIVATE FUNCTIONS
     * Contains derelativizer, normalizer and conversion
     * utility from FILETIME to time_t. */

    void derelativize_path(types::String& str)
    {
        if (str.find("\\..\\") == types::String::npos)
            return;

        size_t pos = str.find("\\..\\");
        if    (pos == types::String::npos || pos == 0)
            return;

        size_t i = str.rfind("\\", 0, pos - 1);
        if    (i == types::String::npos)
            return;

        str.erase(i + 1, pos - i + 3);
        derelativize_path(str);
    }

    void normalize_path(types::String& str)
    {
        for (types::String::it c = str.begin(); c != str.end(); ++c)
            if (*c == '/') *c = '\\';

        size_t pos = str.find("\\.\\");
        while (pos != types::String::npos)
        {
            str.erase(pos, 2);
            pos = str.find("\\.\\");
        }

        derelativize_path(str);
    }

    time_t filetime_to_time_t(const FILETIME& ft)
    {
        ULARGE_INTEGER ul;
        ul.LowPart  = ft.dwLowDateTime;
        ul.HighPart = ft.dwHighDateTime;
        return (time_t)((ul.QuadPart / 10000000ULL) - 11644473600ULL);
    }
} /* end namespace filesystem */

/* File: of_filesystem_posix.cpp
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  OF Filesystem access, POSIX implementation.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#include <dirent.h>
#include <sys/stat.h>

#include "of_filesystem.h"

namespace filesystem
{
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
            p_path = types::String();
            p_dir  = NULL;
            p_de   = NULL;
            p_curr = File_Info();
        }

        /* ctor from a string */
        File_Iterator_Base(const types::String& path):
            p_path(path), p_dir(opendir(path.get_buf()))
        {
            if (!p_dir)
            {
                p_de   = NULL;
                p_curr = File_Info();
                return;
            }

            p_de = readdir(p_dir);
            while (p_de &&
                (!strcmp(p_de->d_name,  ".") ||
                 !strcmp(p_de->d_name, ".."))
            ) p_de = readdir(p_dir);

            if (!p_de)
            {
                closedir(p_dir);
                p_dir  = NULL;
                p_curr = File_Info();
                return;
            }

            types::String p = path;
            p              += '/';
            p              += p_de->d_name;
            p_curr          = File_Info(p);
        }

        /* ctor from another iterator base (pointer) */
        File_Iterator_Base(File_Iterator_Base *it):
            p_path(it->p_path), p_dir(it->p_dir),
            p_de(it->p_de), p_curr(it->p_curr) {}

        /* dtor */
        ~File_Iterator_Base() { if (p_dir) closedir(p_dir); }

        /* moves on to the next dir */
        void incr()
        {
            if (!p_dir) return;
            if (!(p_de = readdir(p_dir)))
                p_curr = File_Info();
            else
            {
                types::String p = p_path;
                p              += '/';
                p              += p_de->d_name;
                p_curr          = File_Info(p);
            }
        }

        /* privates: the path, current DIR,
         * current entry, current file info.
         */
        types::String  p_path;
        DIR           *p_dir;
        struct dirent *p_de;
        File_Info      p_curr;
    };

    /* IMPLEMENTATION DETAILS: File_Info
     * Platform specific implementations of File_Info methods.
     */

    /* initializes the File_Info from a single string */
    void File_Info::init_from_str(const char *path)
    {
        struct stat info;

        if (stat(path, &info))
        {
            p_slash = p_dot = types::String::npos;
            p_type  = FILE_UNKNOWN;
            p_path  = types::String();
            return;
        }

        p_path = path;

        p_slash = p_path.rfind("/");
        p_dot   = p_path.find(
            ".", p_slash == types::String::npos ? 0 : p_slash
        );

        if (S_ISREG(info.st_mode))
            p_type = FILE_REG;
        else if (S_ISDIR(info.st_mode))
            p_type = FILE_DIR;
        else if (S_ISCHR(info.st_mode))
            p_type = FILE_CHR;
        else if (S_ISBLK(info.st_mode))
            p_type = FILE_BLK;
        else if (S_ISFIFO(info.st_mode))
            p_type = FILE_FIFO;
        else if (S_ISLNK(info.st_mode))
            p_type = FILE_LNK;
        else if (S_ISSOCK(info.st_mode))
            p_type = FILE_SOCK;
        else
            p_type = FILE_UNKNOWN;

        p_atime = info.st_atime;
        p_mtime = info.st_mtime;
        p_ctime = info.st_ctime;
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

    const char separator() { return '/'; }

    /* PRIVATE FUNCTIONS
     * Contains derelativizer and normalizer. */

    void derelativize_path(types::String& str)
    {
        if (str.find("/../") == types::String::npos)
            return;

        size_t pos = str.find("/../");
        if    (pos == types::String::npos || pos == 0)
            return;

        size_t i = str.rfind("/", 0, pos - 1);
        if    (i == types::String::npos)
            return;

        str.erase(i + 1, pos - i + 3);
        derelativize_path(str);
    }

    void normalize_path(types::String& str)
    {
        for (types::String::it c = str.begin(); c != str.end(); ++c)
            if (*c == '\\') *c = '/';

        size_t pos = str.find("/./");
        while (pos != types::String::npos)
        {
            str.erase(pos, 2);
            pos = str.find("/./");
        }

        derelativize_path(str);
    }
} /* end namespace filesystem */

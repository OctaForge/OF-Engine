/* File: of_string.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  String class header.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_STRING_H
#define OF_STRING_H

#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include "of_utils.h"
#include "of_stdio.h"
#include "of_iterator.h"

/* Package: types
 * A namespace containing various container types.
 */
namespace types
{
    /* Variable: string_base
     * A base struct for string class. The string then
     * specializes for T == char.
     */
    template<typename T> struct string_base {};

    /* Class: string_base
     * A char specialization for string_base class.
     * It's later typedef'd, so it's just "string".
     *
     * This provides a RAII string container that
     * internally uses char*, but automatically manages
     * the memory and provides some other neat features
     * as well, like easy formatting.
     *
     * Use this when working with char* is too complicated.
     */
    template<> struct string_base<char>
    {
        /* Constant: npos
         * This is a constant of the largest value size_t
         * type can have. It's used mostly as "not found"
         * return value.
         */
        static const size_t npos = ~0;

        /* Typedef: it
         * Iterator typedef, a char*.
         */
        typedef char* it;

        /* Typedef: cit
         * Const iterator typedef, a const char*.
         */
        typedef const char* cit;

        /* Typedef: rit
         * Reverse iterator typedef, a <reverse> < <it> >.
         */
        typedef iterators::reverse<it> rit;

        /* Typedef: vrit
         * Const reverse iterator typedef, a <reverse> < <cit> >.
         */
        typedef iterators::reverse<cit> crit;

        /* Constructor: string_base
         * A constructor that creates the string from const char
         * pointer. It simply calls the assignment overload.
         */
        string_base(const char *str = ""):
            buf(NULL), s_length(0), s_capacity(0)
        {
            *this = str;
        }

        /* Constructor: string_base
         * A constructor that creates the string from another
         * string. It simply calls the assignment overload.
         */
        string_base(const string_base& str):
            buf(NULL), s_length(0), s_capacity(0)
        {
            *this = str;
        }

        /* Destructor: string_base
         * Deletes the buffer.
         */
        ~string_base()
        {
            delete[] buf;
        }

        /* Operator: =
         * Assignment operator overriden to assign current
         * contents from a given string. Self-assignment
         * is ignored.
         *
         * If the current capacity is big enough, new buffer
         * won't be allocated and instead, existing one will
         * be used.
         */
        string_base& operator=(const string_base& str)
        {
            if (this != &str)
            {
                if (str.length() <= s_capacity && s_capacity > 0)
                {
                    s_length = str.length();
                    memcpy(buf, str.buf, s_length + 1);
                    return *this;
                }

                delete[] buf;
                buf = NULL;
                
                s_length   = str.length  ();
                s_capacity = str.capacity();

                buf = new char[s_capacity + 1];
                memcpy(buf, str.buf, s_length + 1);
            }

            return *this;
        }

        /* Operator: =
         * Assignment operator overriden to assign current
         * contents from a given const char pointer.
         * Self-assignment is ignored.
         *
         * If the current capacity is big enough, new buffer
         * won't be allocated and instead, existing one will
         * be used.
         */
        string_base& operator=(const char *str)
        {
            if (strlen(str) <= s_capacity && s_capacity > 0)
            {
                    s_length = strlen(str);
                    memcpy(buf, str, s_length + 1);
                    return *this;
            }

            delete[] buf;
            buf = NULL;
            
            s_length   = strlen(str);
            s_capacity = s_length;

            buf = new char  [s_capacity + 1];
            memcpy(buf, str, s_length   + 1);

            return *this;
        }

        /* Operator: =
         * Assignment operator overriden to assign current
         * contents from a given character. Self-assignment
         * is ignored.
         *
         * If the current capacity is big enough, new buffer
         * won't be allocated and instead, existing one will
         * be used.
         */
        string_base& operator=(char c)
        {
            if (s_capacity >= 1)
            {
                buf[0] = c;
                buf[1] = '\0';
                s_length = 1;
                return *this;
            }

            delete[] buf;
            buf = NULL;

            buf = new char[2];
            buf[0] = c;
            buf[1] = '\0';

            s_length   = 1;
            s_capacity = 1;

            return *this;
        }

        /* Function: begin
         * Returns a pointer to the buffer.
         */
        it begin() { return buf; }

        /* Function: begin
         * Returns a const pointer to the buffer.
         */
        cit begin() const { return buf; }

        /* Function: rbegin
         * Returns a <reverse> iterator to <end>.
         */
        rit rbegin() { return rit(end()); }

        /* Function: rbegin
         * Returns a const <reverse> iterator to <end>.
         */
        crit rbegin() const { return crit(end()); }

        /* Function: end
         * Returns a pointer to the string end ('\0').
         */
        it end() { return buf + s_length; }

        /* Function: end
         * Returns a const pointer to the string end ('\0').
         */
        cit end() const { return buf + s_length; }

        /* Function: rend
         * Returns a <reverse> iterator to <begin>.
         */
        rit rend() { return rit(begin()); }

        /* Function: rend
         * Returns a const <reverse> iterator to <begin>.
         */
        crit rend() const { return crit(begin()); }

        /* Function: get_buf
         * Returns the internal buffer as const char pointer.
         */
        const char *get_buf() const { return buf; }

        /* Function: resize
         * Resizes the string to be of the given capacity. If the new
         * capacity is smaller than the current length, the string will
         * be truncated.
         */
        void resize(size_t new_len)
        {
            if (new_len == s_capacity) return;

            char *new_buf = new char[new_len + 1];
            if   (new_len > s_capacity || s_length <= new_len)
            {
                memcpy(new_buf, buf, s_length + 1);
                s_capacity = new_len;
            }
            else
            {
                memcpy(new_buf, buf, new_len);
                new_buf[new_len] = '\0';
                s_length   = new_len;
                s_capacity = s_length;
            }
            delete[]  buf;
            buf = new_buf;
        }

        /* Function: clear
         * Deletes the string buffer and sets the
         * length and the capacity to 0.
         */
        void clear()
        {
            delete[] buf;
            buf        = NULL;
            s_length   = 0;
            s_capacity = 0;
        }

        /* Function: length
         * Returns the string length.
         */
        size_t length() const { return s_length; }

        /* Function: capacity
         * Returns the string capacity.
         */
        size_t capacity() const { return s_capacity; }

        /* Function: is_empty
         * Returns true if the string is empty, false otherwise.
         */
        bool is_empty() const { return (s_length == 0); }

        /* Operator: []
         * Returns a reference to the character on the given index.
         * Used for assignment.
         */
        char& operator[](size_t idx) { return buf[idx]; }

        /* Operator: []
         * Returns a const reference to the character on the given
         * index. Used for reading.
         */
        const char& operator[](size_t idx) const { return buf[idx]; }

        /* Function: at
         * Returns a reference to the character on the given index.
         * Used for assignment.
         */
        char& at(size_t idx) { return buf[idx]; }

        /* Function: at
         * Returns a const reference to the character on the given
         * index. Used for reading.
         */
        const char& at(size_t idx) const { return buf[idx]; }

        /* Function: append
         * Appends a given string to the current one.
         */
        string_base& append(const string_base& str)
        {
            if (this != &str)
            {
                if (str.length() == 0) return *this;
                append(str.buf, str.length());
            }

            return *this;
        }

        /* Function: append
         * Appends a given string (const char*) to the current one.
         */
        string_base& append(const char *str)
        {
            if (!str) return *this;

            size_t len   = strlen(str);
            if (len != 0) append(str, len);

            return *this;
        }

        /* Function: append
         * Appends a given character to the string.
         */
        string_base& append(char c)
        {
            char tmp[2] = { c, '\0' };
            append(tmp, 1);

            return *this;
        }

        /* Operator: +=
         * Appends a given string to the current one.
         */
        string_base& operator+=(const string_base& str) { return append(str); }

        /* Operator: +=
         * Appends a given string (const char*) to the current one.
         */
        string_base& operator+=(const char *str) { return append(str); }

        /* Operator: +=
         * Appends a given character to the string.
         */
        string_base& operator+=(char c) { return append(c); }

        /* Function: substr
         * Returns a substring of the string based on the given
         * arguments. It will be a new instance with its own
         * buffer.
         *
         * First argument specifies the index to start the
         * substring on, second argument specifies the length
         * of the substring.
         */
        string_base substr(size_t idx, size_t len) const
        {
            if (idx >= s_length || (idx + len) > s_length)
                return string_base();

            char  *sub_buf = new char [len + 1];
            memcpy(sub_buf, &buf[idx], len);
            sub_buf[len] = '\0';

            string_base ret(sub_buf);
            delete[]   sub_buf;

            return ret;
        }

        /* Function: find
         * Given a string, this returns the position of the first
         * occurence of the given string in the string. You can
         * also provide an optional second argument specifying
         * the index to start searching on.
         */
        size_t find(const string_base& str, size_t pos = 0)
        {
            return find(str.buf, str.length(), pos);
        }

        /* Function: find
         * Given a const char*, this returns the position of the first
         * occurence of the given string in the string. You can
         * also provide an optional second argument specifying
         * the index to start searching on.
         */
        size_t find(const char *str, size_t pos = 0)
        {
            return find(str, strlen(str), pos);
        }

        /* Function: find
         * This is used internally by the two find functions above.
         * All arguments are mandatory here and you need to provide
         * the length of the substring to search for.
         */
        size_t find(const char *str, size_t len, size_t pos)
        {
            /* performance improvement - check if
             * we CAN find the substring
             */
            if (!strstr(buf, str)) return npos;

            /* begin searching from position */
            char  *tmp = &buf[pos];
            for (; tmp[0]; pos++)
            {
                /* this loop will check if the string we search
                 * for is equal with the beginning of the offset
                 * tmp pointer, if not, breaks out and moves on
                 */
                for (size_t i = 0; i < len; i++)
                {
                    if (str[i] != tmp[i]) break;
                    /* if everything is fine, return the position */
                    if (i == (len - 1) && str[i] == tmp[i])
                        return pos;
                }

                /* if it was not equal, let's offset by
                 * one more char and loop it again
                 */
                tmp = &buf[pos + 1];
            }

            /* on unsuccessful find, return npos constant */
            return npos;
        }

        /* Function: rfind
         * See <find>. The difference is that it returns the
         * position of the last occurence instead of first.
         *
         * The position argument has the same meaning as
         * previously.
         */
        size_t rfind(const string_base& str, size_t pos = 0)
        {
            return rfind(str.buf, str.length(), pos);
        }

        /* Function: rfind
         * See <find>. The difference is that it returns the
         * position of the last occurence instead of first.
         *
         * The position argument has the same meaning as
         * previously.
         */
        size_t rfind(const char *str, size_t pos = 0)
        {
            return rfind(str, strlen(str), pos);
        }

        /* Function: find
         * This is used internally by the two rfind functions
         * above. It uses <find> to locate the last occurence.
         */
        size_t rfind(const char *str, size_t len, size_t pos)
        {
            size_t res = 0, ret = npos;

            for (;;)
            {
                res = find(str, len, res);
                if (res == npos) break;
                ret = res;
            }
            return ret;
        }

        /* Function: format
         * Formats the string using a given format string (as
         * const char*) and a va_list of arguments.
         *
         * The format string is the same as with printf family.
         */
        string_base& format(const char *fmt, va_list ap)
        {
            char *new_buf = NULL;

            s_length   = vasprintf(&new_buf, fmt, ap);
            s_capacity = s_length;

            delete[] buf;
            buf = new_buf;

            return *this;
        }

        /* Function: format
         * Formats the string using a given format string (as
         * const string&) and a va_list of arguments.
         *
         * The format string is the same as with printf family.
         */
        string_base& format(const string_base& fmt, va_list ap)
        {
            return format(fmt.buf, ap);
        }

        /* Function: format
         * Formats the string using a given format string (as
         * const char*) and a list of arguments.
         *
         * The format string is the same as with printf family.
         */
        string_base& format(const char *fmt, ...)
        {
            va_list ap;

            va_start(ap, fmt);
            format  (fmt, ap);
            va_end  (ap);

            return *this;
        }

        /* Function: format
         * Formats the string using a given format string (as
         * const string&) and a list of arguments.
         *
         * The format string is the same as with printf family.
         */
        string_base& format(const string_base& fmt, ...)
        {
            va_list ap;

            va_start(ap, fmt);
            format  (fmt, ap);
            va_end  (ap);

            return *this;
        }

    private:

        void append(const char *str, size_t len)
        {
            /* in that case, we can just append without copying */
            size_t left = s_capacity - s_length;
            if    (left > 0 && left >= len)
            {
                buf += s_length;
                for (; *str;  str++)
                    *buf++ = *str;
                *buf++ = '\0';

                s_length += len;
                buf -= (s_length + 1);
                
                return;
            }

            /* save old buf */
            char  *old_buf = buf;

            /* this will be the new length */
            size_t new_len = s_length + len;

            buf = new char[new_len + 1];

            /* copy both old buf contents
             * and new string into new buffer,
             * copy new string with offset.
             */
            memcpy(buf, old_buf, s_length);
            memcpy(buf + s_length, str, len);

            /* important: null termination */
            buf[new_len] = '\0';

            delete[] old_buf;

            /* length now equals capacity */
            s_length   = new_len;
            s_capacity = s_length;
        }

        char *buf;

        size_t s_length;
        size_t s_capacity;
    };

    /* Typedef: string
     * Defined as string_base<char>.
     */
    typedef string_base<char> string;

    /* Operator: ==
     * See strcmp. Global, not part of the class.
     */
    inline bool operator==(const string& a, const string& b)
    {
        return (strcmp(a.get_buf(), b.get_buf()) == 0);
    }

    /* Operator: < */
    inline bool operator<(const string& a, const string& b)
    {
        return (strcmp(a.get_buf(), b.get_buf()) < 0);
    }

    /* Operator: > */
    inline bool operator>(const string& a, const string& b)
    {
        return (strcmp(a.get_buf(), b.get_buf()) > 0);
    }

    /* Operator: != */
    inline bool operator!=(const string& a, const string& b)
    {
        return !(a == b);
    }

    /* Operator: <= */
    inline bool operator<=(const string& a, const string& b)
    {
        return (b == a || b < a);
    }

    /* Operator: >= */
    inline bool operator>=(const string& a, const string& b)
    {
        return (b == a || b > a);
    }
} /* end namespace types */

#endif

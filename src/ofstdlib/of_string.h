/*
 * File: of_string.h
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

#include <cstdio>
#include <cstring>
#include <cstdarg>

#include "of_utils.h"
#include "of_stdio.h"

/*
 * Package: types
 * This namespace features some types used in OctaForge.
 * This part exactly defines string.
 */
namespace types
{
    /*
     * Variable: string_base
     * A base struct for string class. The string then
     * specializes for T == char.
     */
    template<typename T> struct string_base {};

    /*
     * Class: string_base
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
        /*
         * Constant: npos
         * This is a constant of the largest value size_t
         * type can have. It's used mostly as "not found"
         * return value.
         */
        static const size_t npos = ~0;

        /*
         * Constructor: string_base
         * A constructor that creates the string from const char
         * pointer. It simply calls the assignment overload.
         */
        string_base(const char *str = ""):
            buf(NULL), length(0), capacity(0)
        {
            *this = str;
        }

        /*
         * Constructor: string_base
         * A constructor that creates the string from another
         * string. It simply calls the assignment overload.
         */
        string_base(const string_base& str):
            buf(NULL), length(0), capacity(0)
        {
            *this = str;
        }

        /*
         * Destructor: string_base
         * Deletest the buffer.
         */
        ~string_base()
        {
            if (buf) delete[] buf;
        }

        /*
         * Operator: =
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
                if (str.length <= capacity && capacity > 0)
                {
                    length = str.length;
                    memcpy(buf, str.buf, length + 1);
                    return *this;
                }

                delete[] buf;
                buf = NULL;
                
                length   = str.length;
                capacity = str.capacity;

                buf = new char[capacity + 1];
                memcpy(buf, str.buf, length + 1);
            }

            return *this;
        }

        /*
         * Operator: =
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
            if (strlen(str) <= capacity && capacity > 0)
            {
                    length = strlen(str);
                    memcpy(buf, str, length + 1);
                    return *this;
            }

            delete[] buf;
            buf = NULL;
            
            length   = strlen(str);
            capacity = length;

            buf = new char[capacity + 1];
            memcpy(buf, str, length + 1);

            return *this;
        }

        /*
         * Operator: =
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
            if (capacity >= 1)
            {
                buf[0] = c;
                buf[1] = '\0';
                length = 1;
                return *this;
            }

            delete[] buf;
            buf = NULL;

            buf = new char[2];
            buf[0] = c;
            buf[1] = '\0';

            length   = 1;
            capacity = 1;

            return *this;
        }

        /*
         * Function: first
         * Returns a pointer to the buffer.
         */
        char *first() { return buf; }

        /*
         * Function: first
         * Returns a const pointer to the buffer.
         */
        const char *first() const { return buf; }

        /*
         * Function: last
         * Returns a pointer to the buffer offset by its length.
         */
        char *last() { return buf + length; }

        /*
         * Function: last
         * Returns a const pointer to the buffer offset by its length.
         */
        const char *last() const { return buf + length; }

        /*
         * Function: end
         * Returns a pointer to the buffer offset by its capacity.
         */
        char *end() { return buf + capacity; }

        /*
         * Function: end
         * Returns a const pointer to the buffer offset by its capacity.
         */
        const char *end() const { return buf + capacity; }

        /*
         * Function: resize
         * Resizes the string to be of the given capacity. If the new
         * capacity is smaller than the current length, the string will
         * be truncated.
         */
        void resize(size_t new_len)
        {
            if (new_len == capacity) return;

            char *new_buf = new char[new_len + 1];
            if   (new_len > capacity || length <= new_len)
            {
                memcpy(new_buf, buf, length + 1);
                capacity = new_len;
            }
            else
            {
                memcpy(new_buf, buf, new_len);
                new_buf[new_len] = '\0';
                length   = new_len;
                capacity = length;
            }
            delete[]  buf;
            buf = new_buf;
        }

        /*
         * Function: clear
         * Deletes the string buffer and sets the
         * length and the capacity to 0.
         */
        void clear()
        {
            delete[] buf;
            buf      = NULL;
            length   = 0;
            capacity = 0;
        }

        /*
         * Function: is_empty
         * Returns true if the string is empty, false otherwise.
         */
        bool is_empty() { return (length == 0); }

        /*
         * Operator: []
         * Returns a reference to the character on the given index.
         * Used for assignment.
         */
        char& operator[](size_t idx) { return buf[idx]; }

        /*
         * Operator: []
         * Returns a const reference to the character on the given
         * index. Used for reading.
         */
        const char& operator[](size_t idx) const { return buf[idx]; }

        /*
         * Function: at
         * Returns a reference to the character on the given index.
         * Used for assignment.
         */
        char& at(size_t idx) { return buf[idx]; }

        /*
         * Function: at
         * Returns a const reference to the character on the given
         * index. Used for reading.
         */
        const char& at(size_t idx) const { return buf[idx]; }

        /*
         * Function: append
         * Appends a given string to the current one.
         */
        string_base& append(const string_base& str)
        {
            if (this != &str)
            {
                if (str.length == 0) return *this;
                append(str.buf, str.length);
            }

            return *this;
        }

        /*
         * Function: append
         * Appends a given string (const char*) to the current one.
         */
        string_base& append(const char *str)
        {
            if (!str) return *this;

            size_t len   = strlen(str);
            if (len != 0) append(str, len);

            return *this;
        }

        /*
         * Function: append
         * Appends a given character to the string.
         */
        string_base& append(char c)
        {
            char tmp[2] = { c, '\0' };
            append(tmp, 1);

            return *this;
        }

        /*
         * Operator: +=
         * Appends a given string to the current one.
         */
        string_base& operator+=(const string_base& str) { return append(str); }

        /*
         * Operator: +=
         * Appends a given string (const char*) to the current one.
         */
        string_base& operator+=(const char *str) { return append(str); }

        /*
         * Operator: +=
         * Appends a given character to the string.
         */
        string_base& operator+=(char c) { return append(c); }

        /*
         * Function: substr
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
            if (idx >= length || (idx + len) > length)
                return string_base();

            char  *sub_buf = new char [len + 1];
            memcpy(sub_buf, &buf[idx], len);
            sub_buf[len] = '\0';

            string_base ret(sub_buf);
            delete[]   sub_buf;

            return ret;
        }

        /*
         * Function: find
         * Given a string, this returns the position of the first
         * occurence of the given string in the string. You can
         * also provide an optional second argument specifying
         * the index to start searching on.
         */
        size_t find(const string_base& str, size_t pos = 0)
        {
            return find(str.buf, str.length, pos);
        }

        /*
         * Function: find
         * Given a const char*, this returns the position of the first
         * occurence of the given string in the string. You can
         * also provide an optional second argument specifying
         * the index to start searching on.
         */
        size_t find(const char *str, size_t pos = 0)
        {
            return find(str, strlen(str), pos);
        }

        /*
         * Function: find
         * This is used internally by the two find functions above.
         * All arguments are mandatory here and you need to provide
         * the length of the substring to search for.
         */
        size_t find(const char *str, size_t len, size_t pos)
        {
            /*
             * performance improvement - check if
             * we CAN find the substring
             */
            if (!strstr(buf, str)) return npos;

            /* begin searching from position */
            char  *tmp = &buf[pos];
            for (; tmp[0]; pos++)
            {
                /*
                 * this loop will check if the string we search
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

                /*
                 * if it was not equal, let's offset by
                 * one more char and loop it again
                 */
                tmp = &buf[pos + 1];
            }

            /* on unsuccessful find, return npos constant */
            return npos;
        }

        /*
         * Function: rfind
         * See <find>. The difference is that it returns the
         * position of the last occurence instead of first.
         *
         * The position argument has the same meaning as
         * previously.
         */
        size_t rfind(const string_base& str, size_t pos = 0)
        {
            return rfind(str.buf, str.length, pos);
        }

        /*
         * Function: rfind
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

        /*
         * Function: find
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

        /*
         * Function: format
         * Formats the string using a given format string (as
         * const char*) and a va_list of arguments.
         *
         * The format string is the same as with printf family.
         */
        string_base& format(const char *fmt, va_list ap)
        {
            char *new_buf = NULL;

            length   = vasprintf(&new_buf, fmt, ap);
            capacity = length;

            delete[] buf;
            buf = new_buf;

            return *this;
        }

        /*
         * Function: format
         * Formats the string using a given format string (as
         * const string&) and a va_list of arguments.
         *
         * The format string is the same as with printf family.
         */
        string_base& format(const string_base& fmt, va_list ap)
        {
            return format(fmt.buf, ap);
        }

        /*
         * Function: format
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

        /*
         * Function: format
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

        /*
         * Function: append
         * Given a const char* and the length of the given string,
         * it appends the string to the buffer. If the capacity is
         * fine to hold the appended part, no reallocation is made.
         *
         * This is for internal use only.
         */
        void append(const char *str, size_t len)
        {
            /* in that case, we can just append without copying */
            size_t left = capacity - length;
            if    (left > 0 && left >= len)
            {
                buf += length;
                for (; *str;  str++)
                    *buf++ = *str;
                *buf++ = '\0';

                length += len;
                buf -= (length + 1);
                
                return;
            }

            /* save old buf */
            char  *old_buf = buf;

            /* this will be the new length */
            size_t new_len = length + len;

            buf = new char[new_len + 1];

            /*
             * copy both old buf contents
             * and new string into new buffer,
             * copy new string with offset.
             */
            memcpy(buf, old_buf, length);
            memcpy(buf + length, str, len);

            /* important: null termination */
            buf[new_len] = '\0';

            delete[] old_buf;

            /* length now equals capacity */
            length   = new_len;
            capacity = length;
        }

        /*
         * Variable: buf
         * A buffer the string is stored in. It is
         * managed, so you don't have to care about
         * its memory.
         */
        char *buf;

        /*
         * Variable: length
         * Stores the actual length of the string
         * (that is, the amount of characters before
         * the terminating '\0'), not the <capacity>
         * of <buf>.
         */
        size_t length;

        /*
         * Variable: capacity
         * Stores the <buf>'s capacity. That is not
         * always the length of the string, though
         * often it is. For length, see <length>.
         */
        size_t capacity;
    };

    typedef string_base<char> string;

    /*
     * Operator: ==
     * See strcmp.
     */
    inline bool operator==(const string& a, const string& b)
    {
        return (strcmp(a.buf, b.buf) == 0);
    }

    /*
     * Operator: <
     * See strcmp.
     */
    inline bool operator<(const string& a, const string& b)
    {
        return (strcmp(a.buf, b.buf) < 0);
    }

    /*
     * Operator: >
     * See strcmp.
     */
    inline bool operator>(const string& a, const string& b)
    {
        return (strcmp(a.buf, b.buf) > 0);
    }

    /*
     * Operator: !=
     * See strcmp.
     */
    inline bool operator!=(const string& a, const string& b)
    {
        return !(a == b);
    }

    /*
     * Operator: <=
     * See strcmp.
     */
    inline bool operator<=(const string& a, const string& b)
    {
        return (b == a || b < a);
    }

    /*
     * Operator: >=
     * See strcmp.
     */
    inline bool operator>=(const string& a, const string& b)
    {
        return (b == a || b > a);
    }
} /* end namespace types */

#endif

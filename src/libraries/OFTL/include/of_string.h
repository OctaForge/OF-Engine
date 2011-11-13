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
    /* Variable: String_Base
     * A base struct for string class. The string then specializes
     * for T == char.
     */
    template<typename T> struct String_Base {};

    /* Struct: String_Base
     * A char specialization for String_Base class. It's later typedef'd,
     * so it's just "string".
     *
     * This provides a RAII string container that internally uses char*, but
     * automatically manages the memory and provides some other neat features
     * as well, like easy formatting.
     *
     * Use this when working with char* is too complicated.
     */
    template<> struct String_Base<char>
    {
        /* Constant: npos
         * This is a constant of the largest value size_t type can have.
         * It's used mostly as "not found" return value.
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
         * Reverse iterator typedef, a <Reverse> < <it> >.
         */
        typedef iterators::Reverse_Iterator<it> rit;

        /* Typedef: vrit
         * Const reverse iterator typedef, a <Reverse> < <cit> >.
         */
        typedef iterators::Reverse_Iterator<cit> crit;

        /* Constructor: String_Base
         * A constructor that creates the string from const char pointer.
         * It simply calls the assignment overload.
         */
        String_Base(const char *str = ""):
            p_buf(NULL), p_length(0), p_capacity(0)
        {
            *this = str;
        }

        /* Constructor: String_Base
         * A constructor that creates the string from another string.
         * It simply calls the assignment overload.
         */
        String_Base(const String_Base& str):
            p_buf(NULL), p_length(0), p_capacity(0)
        {
            *this = str;
        }

        /* Destructor: String_Base
         * Deletes the buffer.
         */
        ~String_Base()
        {
            delete[] p_buf;
        }

        /* Operator: =
         * Assignment operator overriden to assign current contents from a
         * given string. Self-assignment is ignored.
         *
         * If the current capacity is big enough, new buffer won't be
         * allocated and instead, existing one will be used.
         */
        String_Base& operator=(const String_Base& str)
        {
            if (this != &str)
            {
                if (str.length() <= p_capacity && p_capacity > 0)
                {
                    p_length = str.length();
                    memcpy(p_buf, str.p_buf, p_length + 1);
                    return *this;
                }

                delete[] p_buf;
                p_buf = NULL;
                
                p_length   = str.length  ();
                p_capacity = str.capacity();

                p_buf = new char[p_capacity + 1];
                memcpy(p_buf, str.p_buf, p_length + 1);
            }

            return *this;
        }

        /* Operator: =
         * Assignment operator overriden to assign current contents from a
         * given const char pointer.
         *
         * If the current capacity is big enough, new buffer won't be allocated
         * and instead, existing one will be used.
         */
        String_Base& operator=(const char *str)
        {
            if (!str)
            {
                if (p_capacity > 0)
                {
                    delete[] p_buf;
                    p_buf = NULL;

                    p_length   = 0;
                    p_capacity = 0;
                }
                return *this;
            }

            if (strlen(str) <= p_capacity && p_capacity > 0)
            {
                    p_length = strlen(str);
                    memcpy(p_buf, str, p_length + 1);
                    return *this;
            }

            delete[] p_buf;
            p_buf = NULL;
            
            p_length   = strlen(str);
            p_capacity = p_length;

            p_buf = new char  [p_capacity + 1];
            memcpy(p_buf, str, p_length   + 1);

            return *this;
        }

        /* Operator: =
         * Assignment operator overriden to assign current contents from a
         * given character. Self-assignment is ignored.
         *
         * If the current capacity is big enough, new buffer won't be allocated
         * and instead, existing one will be used.
         */
        String_Base& operator=(char c)
        {
            if (p_capacity >= 1)
            {
                p_buf[0] = c;
                p_buf[1] = '\0';
                p_length = 1;
                return *this;
            }

            delete[] p_buf;
            p_buf = NULL;

            p_buf = new char[2];
            p_buf[0] = c;
            p_buf[1] = '\0';

            p_length   = 1;
            p_capacity = 1;

            return *this;
        }

        /* Function: begin
         * Returns a pointer to the buffer.
         */
        it begin() { return p_buf; }

        /* Function: begin
         * Returns a const pointer to the buffer.
         */
        cit begin() const { return p_buf; }

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
        it end() { return p_buf + p_length; }

        /* Function: end
         * Returns a const pointer to the string end ('\0').
         */
        cit end() const { return p_buf + p_length; }

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
        const char *get_buf() const { return p_buf; }

        /* Function: resize
         * Resizes the string to be of the given capacity. If the new capacity
         * is smaller than the current length, the string will be truncated.
         */
        void resize(size_t new_len)
        {
            if (new_len == p_capacity) return;

            char *new_buf = new char[new_len + 1];
            if   (new_len > p_capacity || p_length <= new_len)
            {
                memcpy(new_buf, p_buf, p_length + 1);
                p_capacity = new_len;
            }
            else
            {
                memcpy(new_buf, p_buf, new_len);
                new_buf[new_len] = '\0';
                p_length   = new_len;
                p_capacity = p_length;
            }
            delete[]  p_buf;
            p_buf = new_buf;
        }

        /* Function: clear
         * Deletes the string buffer and sets the length and the capacity to 0.
         */
        void clear()
        {
            delete[] p_buf;
            p_buf      = NULL;
            p_length   = 0;
            p_capacity = 0;
        }

        /* Function: length
         * Returns the string length.
         */
        size_t length() const { return p_length; }

        /* Function: capacity
         * Returns the string capacity.
         */
        size_t capacity() const { return p_capacity; }

        /* Function: is_empty
         * Returns true if the string is empty, false otherwise.
         */
        bool is_empty() const { return (p_length == 0); }

        /* Operator: []
         * Returns a reference to the character on the given index. Used for
         * assignment.
         */
        char& operator[](size_t idx) { return p_buf[idx]; }

        /* Operator: []
         * Returns a const reference to the character on the given index. Used
         * for reading.
         */
        const char& operator[](size_t idx) const { return p_buf[idx]; }

        /* Function: at
         * Returns a reference to the character on the given index. Used for
         * assignment.
         */
        char& at(size_t idx) { return p_buf[idx]; }

        /* Function: at
         * Returns a const reference to the character on the given index. Used
         * for reading.
         */
        const char& at(size_t idx) const { return p_buf[idx]; }

        /* Function: append
         * Appends a given string to the current one.
         */
        String_Base& append(const String_Base& str)
        {
            if (this != &str)
            {
                if (str.length() == 0) return *this;
                p_append(str.p_buf, str.length());
            }

            return *this;
        }

        /* Function: append
         * Appends a given string (const char*) to the current one.
         */
        String_Base& append(const char *str)
        {
            if (!str) return *this;

            size_t len   = strlen(str);
            if (len != 0) p_append(str, len);

            return *this;
        }

        /* Function: append
         * Appends a given character to the string.
         */
        String_Base& append(char c)
        {
            char tmp[2] = { c, '\0' };
            p_append(tmp, 1);

            return *this;
        }

        /* Operator: +=
         * Appends a given string to the current one.
         */
        String_Base& operator+=(const String_Base& str) { return append(str); }

        /* Operator: +=
         * Appends a given string (const char*) to the current one.
         */
        String_Base& operator+=(const char *str) { return append(str); }

        /* Operator: +=
         * Appends a given character to the string.
         */
        String_Base& operator+=(char c) { return append(c); }

        /* Function: substr
         * Returns a substring of the string based on the given arguments. It
         * will be a new instance with its own buffer.
         *
         * First argument specifies the index to start the substring on,
         * second argument specifies the length of the substring.
         */
        String_Base substr(size_t idx, size_t len) const
        {
            if (idx >= p_length || (idx + len) > p_length)
                return String_Base();

            char  *sub_buf = new char   [len + 1];
            memcpy(sub_buf, &p_buf[idx], len);
            sub_buf[len] = '\0';

            String_Base ret(sub_buf);
            delete[]   sub_buf;

            return ret;
        }

        /* Function: find
         * Given a string, this returns the position of the first occurence of
         * the given string in the string. You can also provide optional
         * arguments specifying where to start and end searching.
         */
        size_t find(const String_Base& str,
            size_t beg = 0,
            size_t end = npos
        ) const
        {
            return find(str.p_buf, str.length(), beg, end);
        }

        /* Function: find
         * Given a const char*, this returns the position of the first
         * occurence of the given string in the string. You can also provide
         * optional arguments specifying where to start and end searching.
         */
        size_t find(const char *str,
            size_t beg = 0,
            size_t end = npos
        ) const
        {
            return find(str, strlen(str), beg, end);
        }

        /* Function: find
         * This is used internally by the two find functions above. All the
         * arguments are mandatory here and you need to provide the length of
         * the substring to search for.
         */
        size_t find(const char *str,
            size_t len,
            size_t beg,
            size_t end
        ) const
        {
            /* performance improvement - check if
             * we CAN find the substring
             */
            if (!strstr(p_buf, str)) return npos;

            /* begin searching from position */
            char  *tmp = &p_buf[beg];
            for (; tmp[0]   && (beg <= end); ++beg)
            {
                /* this loop will check if the string we search
                 * for is equal with the beginning of the offset
                 * tmp pointer, if not, breaks out and moves on
                 */
                for (size_t i = 0; i < len; ++i)
                {
                    if (str[i] != tmp[i]) break;
                    /* if everything is fine, return the position */
                    if (i == (len - 1) && str[i] == tmp[i])
                        return beg;
                }

                /* if it was not equal, let's offset by
                 * one more char and loop it again
                 */
                tmp = &p_buf[beg + 1];
            }

            /* on unsuccessful find, return npos constant */
            return npos;
        }

        /* Function: rfind
         * See <find>. The difference is that it returns the position of the
         * last occurence instead of first.
         *
         * The position argument has the same meaning as previously.
         */
        size_t rfind(const String_Base& str,
            size_t beg = 0,
            size_t end = npos
        ) const
        {
            return rfind(str.p_buf, str.length(), beg, end);
        }

        /* Function: rfind
         * See <find>. The difference is that it returns the position of the
         * last occurence instead of first.
         *
         * The position argument has the same meaning as previously.
         */
        size_t rfind(const char *str,
            size_t beg = 0,
            size_t end = npos
        ) const
        {
            return rfind(str, strlen(str), beg, end);
        }

        /* Function: find
         * This is used internally by the two rfind functions above. It uses
         * <find> to locate the last occurence.
         */
        size_t rfind(const char *str,
            size_t len,
            size_t beg,
            size_t end
        ) const
        {
            size_t res = beg - 1, ret = npos;

            for (;;)
            {
                res = find(str, len, res + 1, end);
                if (res == npos) break;
                ret = res;
            }
            return ret;
        }

        /* Function: erase
         * Erases a part of the string, moving the rest of it back
         * by the erased part. The erased part is here specified
         * by the position of the first character to erase and
         * the length of the erased part.
         */
        String_Base& erase(size_t pos = 0, size_t len = npos)
        {
            if (pos == 0 && len == npos)
            {
                p_length = 0;
                p_buf[0] = '\0';
                return *this;
            }

            for (size_t i = (pos + len); i < p_length; ++i)
                p_buf[i - len] = p_buf[i];

            p_length -= len;
            p_buf[p_length] = '\0';

            return *this;
        }

        /* Function: erase
         * This erases a single character specified by an iterator.
         */
        it erase(it position)
        {
            if (position < p_buf || position >= (p_buf + p_length))
                return end();

            size_t pos = (position - p_buf);
            erase(pos, 1);

            it p = (p_buf + pos);

            if (p >= (p_buf + p_length))
                return end();

            return p;
        }

        /* Function: erase
         * This erases a part of the string specified by two iterators,
         * the first one specifying the first character to erase and
         * the second one specifying the last character to erase.
         */
        it erase(it first, it last)
        {
            if (first <   p_buf) first = p_buf;
            if (first >= (p_buf + p_length) || last < p_buf)
                return end();
            if (last >= (p_buf + p_length))
                last  = (p_buf + p_length - 1);

            size_t pos = (first - p_buf);
            size_t len = (last  - p_buf);

            erase(pos, len - pos + 1);

            it p = (p_buf + pos);

            if (p >= (p_buf + p_length))
                return end();

            return p;
        }

        /* Function: format
         * Formats the string using a given format string (as const char*)
         * and a va_list of arguments.
         *
         * The format string is the same as with printf family.
         */
        String_Base& format(const char *fmt, va_list ap)
        {
            char *new_buf = NULL;

            p_length   = vasprintf(&new_buf, fmt, ap);
            p_capacity = p_length;

            delete[] p_buf;
            p_buf = new_buf;

            return *this;
        }

        /* Function: format
         * Formats the string using a given format string (as const string&)
         * and a va_list of arguments.
         *
         * The format string is the same as with printf family.
         */
        String_Base& format(const String_Base& fmt, va_list ap)
        {
            return format(fmt.p_buf, ap);
        }

        /* Function: format
         * Formats the string using a given format string (as const char*)
         * and a list of arguments.
         *
         * The format string is the same as with printf family.
         */
        String_Base& format(const char *fmt, ...)
        {
            va_list ap;

            va_start(ap, fmt);
            format  (fmt, ap);
            va_end  (ap);

            return *this;
        }

        /* Function: format
         * Formats the string using a given format string (as const string&)
         * and a list of arguments.
         *
         * The format string is the same as with printf family.
         */
        String_Base& format(const String_Base& fmt, ...)
        {
            va_list ap;

            va_start(ap, fmt);
            format  (fmt, ap);
            va_end  (ap);

            return *this;
        }

        /* Operator: == */
        friend bool operator==(const String_Base& a, const String_Base& b)
        { return (strcmp(a.p_buf, b.p_buf) == 0); }

        /* Operator: != */
        friend bool operator!=(const String_Base& a, const String_Base& b)
        { return (strcmp(a.p_buf, b.p_buf) != 0); }

        /* Operator: < */
        friend bool operator<(const String_Base& a, const String_Base& b)
        { return (strcmp(a.p_buf, b.p_buf) < 0); }

        /* Operator: > */
        friend bool operator>(const String_Base& a, const String_Base& b)
        { return (strcmp(a.p_buf, b.p_buf) > 0); }

        /* Operator: <= */
        friend bool operator<=(const String_Base& a, const String_Base& b)
        { return (strcmp(a.p_buf, b.p_buf) <= 0); }

        /* Operator: >= */
        friend bool operator>=(const String_Base& a, const String_Base& b)
        { return (strcmp(a.p_buf, b.p_buf) >= 0); }

    private:

        void p_append(const char *str, size_t len)
        {
            /* in that case, we can just append without copying */
            size_t left = p_capacity - p_length;
            if    (left > 0 && left >= len)
            {
                p_buf += p_length;
                for (; *str;    str++)
                    *p_buf++ = *str;
                *p_buf++ = '\0';

                p_length += len;
                p_buf -= (p_length + 1);
                
                return;
            }

            /* save old buf */
            char  *old_buf = p_buf;

            /* this will be the new length */
            size_t new_len = p_length + len;

            p_buf = new char[new_len + 1];

            /* copy both old buf contents
             * and new string into new buffer,
             * copy new string with offset.
             */
            memcpy(p_buf,  old_buf, p_length);
            memcpy(p_buf + p_length, str, len);

            /* important: null termination */
            p_buf[new_len] = '\0';

            delete[] old_buf;

            /* length now equals capacity */
            p_length   = new_len;
            p_capacity = p_length;
        }

        char *p_buf;

        size_t p_length;
        size_t p_capacity;
    };

    /* Typedef: String
     * Defined as String_Base<char>.
     */
    typedef String_Base<char> String;
} /* end namespace types */

#endif

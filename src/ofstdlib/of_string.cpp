/*
 * File: of_string.cpp
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  String class implementation.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#include "of_string.h"

namespace types
{
    /* const char* constructor */
    string::string(const char *str) : buf(NULL), length(0), capacity(0)
    {
        *this = str;
    }

    /* string constructor */
    string::string(const string& str) : buf(NULL), length(0), capacity(0)
    {
        *this = str;
    }

    /* destructor */
    string::~string()
    {
        if (buf) delete[] buf;
    }

    /* clear */
    void string::clear()
    {
        delete[] buf;
        buf      = NULL;
        length   = 0;
        capacity = 0;
    }

    /* empty checker */
    bool string::is_empty()
    {
        return (!buf || length == 0);
    }

    /* string assignment */
    const string& string::operator=(const string& str)
    {
        if (this != &str)
        {
            delete[] buf;
            buf = NULL;
            
            length   = str.length;
            capacity = str.capacity;

            buf = new char[capacity + 1];
            memcpy(buf, str.buf, length + 1);
        }

        return *this;
    }

    /* const char* assignment */
    const string& string::operator=(const char *str)
    {
        delete[] buf;
        buf = NULL;
        
        length   = strlen(str);
        capacity = length;

        buf = new char[capacity + 1];
        memcpy(buf, str, length + 1);

        return *this;
    }

    /* string appender */
    const string& string::operator+=(const string& str)
    {
        if (this != &str)
        {
            if (str.length == 0) return *this;
            _append(str.buf, str.length);
        }

        return *this;
    }

    /* const char* appender */
    const string& string::operator+=(const char *str)
    {
        if (!str) return *this;

        size_t len   = strlen(str);
        if (len != 0) _append(str, len);

        return *this;
    }

    /* char appender */
    const string& string::operator+=(char c)
    {
        char tmp[2] = { c, '\0' };
        _append(tmp, 1);

        return *this;
    }

    /* idx getters */
    char  string::operator[](size_t idx) const { return buf[idx]; }
    char& string::operator[](size_t idx)       { return buf[idx]; }
    char  string::at(size_t idx) const         { return buf[idx]; }

    /* slicing */
    string string::substr(size_t idx, size_t len) const
    {
        if (idx >= length || (idx + len) > length)
            return string();

        char  *sub_buf = new char [len + 1];
        memcpy(sub_buf, &buf[idx], len);
        sub_buf[len] = '\0';

        string ret(sub_buf);
        delete[]   sub_buf;

        return ret;
    }

    /* find string */
    size_t string::find(const string& str, size_t pos)
    {
        return find(str.buf, str.length, pos);
    }

    /* find const char* */
    size_t string::find(const char *str, size_t pos)
    {
        return find(str, strlen(str), pos);
    }

    /* find const char* with given size */
    size_t string::find(const char *str, size_t len, size_t pos)
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

    /* find last string */
    size_t string::rfind(const string& str, size_t pos)
    {
        return rfind(str.buf, str.length, pos);
    }

    /* find last const char* */
    size_t string::rfind(const char *str, size_t pos)
    {
        return rfind(str, strlen(str), pos);
    }

    /* find last const char* with given size */
    size_t string::rfind(const char *str, size_t len, size_t pos)
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

    /* format with const char* and va_list */
    const string& string::format(const char *fmt, va_list ap)
    {
        char *new_buf = NULL;

        length   = vasprintf(&new_buf, fmt, ap);
        capacity = length;

        delete[] buf;
        buf = new_buf;

        return *this;
    }

    /* format with string and va_list */
    const string& string::format(const string& fmt, va_list ap)
    {
        return format(fmt.buf, ap);
    }

    /* format with const char* and varargs */
    const string& string::format(const char *fmt, ...)
    {
        va_list ap;

        va_start(ap, fmt);
        format  (fmt, ap);
        va_end  (ap);

        return *this;
    }

    /* format with string and varargs */
    const string& string::format(const string& fmt, ...)
    {
        va_list ap;

        va_start(ap, fmt);
        format  (fmt, ap);
        va_end  (ap);

        return *this;
    }

    /* iterators and const iterators */
    char       *string::first()       { return buf; }
    const char *string::first() const { return buf; }
    char       *string::last()        { return buf + length; }
    const char *string::last() const  { return buf + length; }

    /* internal appender */
    void string::_append(const char *str, size_t len)
    {
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
} /* end namespace types */

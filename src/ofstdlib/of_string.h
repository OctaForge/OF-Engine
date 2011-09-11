/*
 * File: of_string.cpp
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

#include "of_utils.h"

/*
 * Package: types
 * This namespace features some types used in OctaForge.
 * This part exactly defines strings.
 */
namespace types
{
    /*
     * Class: string
     * A string type. It's a structure that holds a data
     * buffer. The buffer is automatically freed on struct
     * destructor, so you don't have to care about it (unless
     * you have a heap-allocated pointer to the class). Also
     * features multiple methods for string manipulation.
     */
    struct string
    {
        /*
         * Constant: npos
         * This is a constant representing the largest possible
         * value for size_t type. It's used as a return value in
         * <find> in case of invalid search for example.
         */
        static const size_t npos = ~0;

        /*
         * Constructor: string
         * A constructor variant that initializes the string from
         * a C char pointer (allocated, a literal, or whatever else).
         * 
         * Parameters:
         *  str - the char pointer. The constructor will actually
         *  copy the data.
         */
        string(const char *str = "");

        /*
         * Constructor: string
         * A constructor variant that initializes the string from
         * another string. Same as for char pointer, it'll copy
         * the data.
         */
        string(const string& str);

        /*
         * Destructor: string
         * Called on class destruction. Frees the data buffer.
         * The buffer won't get freed if it was freed already
         * (for example, using <clear>).
         */
        ~string();

        /*
         * Function: clear
         * Clears the data buffer and frees it.
         */
        void clear();

        /*
         * Function: is_empty
         * Returns true if the string is empty (length
         * set to 0 or freed buffer).
         */
        bool is_empty();

        /*
         * Operator: =
         * Overloaded assignment operator for string
         * argument. Please note that it'll copy the
         * data, so the new string will differ from
         * the old one. Self-assignment results in
         * no action.
         */
        const string& operator=(const string& str);

        /*
         * Operator: =
         * Overloaded assignment operator for char
         * pointer argument.
         */
        const string& operator=(const char *str);

        /*
         * Operator: +=
         * Appends a string to the existing one.
         * Internally calls <_append>.
         */
        const string& operator+=(const string& str);

        /*
         * Operator: +=
         * Appends a char pointer to the string.
         * Internally calls <_append>.
         */
        const string& operator+=(const char *str);

        /*
         * Operator: +=
         * Appends a character to the string.
         * Internally calls <_append>.
         */
        const string& operator+=(char c);

        /*
         * Operator: []
         * Returns a character on given index.
         */
        char operator[](size_t idx) const;

        /*
         * Operator: []
         * Version used for assignment of a character to the given index.
         */
        char& operator[](size_t idx);

        /*
         * Function: at
         * Returns a character on given index.
         */
        char at(size_t idx) const;

        /*
         * Operator: ()
         * Used for slicing. First argument is the index the sliced
         * result begins on, second argument is the length of the
         * resulting slice. Returns the slice as a new string.
         */
        string operator()(size_t idx, size_t len);

        /*
         * Function: find
         * Finds a given substring inside the string. Second optional
         * argument specifies the first index to start searching on.
         */
        size_t find(const string& str, size_t pos = 0);

        /*
         * Function: find
         * Finds a given substring (char pointer version) inside the string.
         * Second optional argument specifies the first index to start
         * searching on.
         */
        size_t find(const char *str, size_t pos = 0);

        /*
         * Function: find
         * Like above, except that there are no optional arguments. Second
         * argument specifies the length of the given substring, third
         * argument specifies the first index to start searching on.
         */
        size_t find(const char *str, size_t len, size_t pos);

        /*
         * Function: format
         * Formats the string buffer according to the first
         * argument (specifying the format) and va_list.
         * Used by all other format functions.
         * 
         * This one automatically allocates required buffer
         * space.
         */
        const string& format(const char *fmt, va_list ap);

        /*
         * Function: format
         * Version of above for string format argument,
         * not const char*.
         */
        const string& format(const string& fmt, va_list ap);

        /*
         * Function: format
         * Version of format using varargs instead of va_list
         * and const char* for format.
         */
        const string& format(const char *fmt, ...);

        /*
         * Function: format
         * Version of format using varargs instead of va_list
         * and string for format.
         */
        const string& format(const string& fmt, ...);

        /*
         * Function: first
         * Returns the buffer pointer without offset.
         */
        char *first();

        /*
         * Function: first
         * Returns the buffer const pointer without offset.
         */
        const char *first() const;

        /*
         * Function: first
         * Returns the buffer pointer offset to the last index.
         */
        char *last();

        /*
         * Function: first
         * Returns the buffer const pointer offset to the last index.
         */
        const char *last() const;

        /*
         * Function: _append
         * Internal function that appends a given char pointer to
         * the string. Second argument specifies the length of the
         * char pointer to append.
         */
        void _append(const char *str, size_t len);

        /*
         * Property: buf
         * This serves as the storage buffer for the string data.
         * Allocated with the new operator, deleted in the destructor
         * (or <clear> or somewhere else internally).
         */
        char *buf;

        /*
         * Property: length
         * Stores the string length as size_t. It usually equals to
         * <capacity>, but doesn't have to.
         */
        size_t length;

        /*
         * Property: capacity
         * Stores the capacity (aka number of allocated bytes for the
         * buffer). Usually equals to <length>, but can be bigger.
         */
        size_t capacity;
    };

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

/* File: of_functional.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  OFTL functor library.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_FUNCTIONAL_H
#define OF_FUNCTIONAL_H

#include <string.h>

#include "of_traits.h"

/* Package: functional
 * OF functors. The comparison functors are always defined for generic
 * comparable POD and non-POD types and strings.
 */
namespace functional
{
    /* EQUAL FUNCTOR - internal implementation */

    template<bool T> struct F_Eq_POD
    {
        template<typename U, typename V> static bool f(U a, V b)
        { return (a == b); }

        static bool f(const char *a, const char *b)
        { return !strcmp(a, b); }
    };

    template<> struct F_Eq_POD<true>
    {
        template<typename T, typename U>
        static bool f(const T& a, const U& b)
        { return (a == b); }
    };

    /* NOT EQUAL FUNCTOR - internal implementation */

    template<bool T> struct F_Neq_POD
    {
        template<typename U, typename V> static bool f(U a, V b)
        { return (a != b); }

        static bool f(const char *a, const char *b)
        { return strcmp(a, b); }
    };

    template<> struct F_Neq_POD<true>
    {
        template<typename T, typename U>
        static bool f(const T& a, const U& b)
        { return (a != b); }
    };

    /* GREATER THAN FUNCTOR - internal implementation */

    template<bool T> struct F_Greater_POD
    {
        template<typename U, typename V> static bool f(U a, V b)
        { return (a > b); }

        static bool f(const char *a, const char *b)
        { return (strcmp(a, b) > 0); }
    };

    template<> struct F_Greater_POD<true>
    {
        template<typename T, typename U>
        static bool f(const T& a, const U& b)
        { return (a > b); }
    };

    /* LESS THAN FUNCTOR - internal implementation */

    template<bool T> struct F_Less_POD
    {
        template<typename U, typename V> static bool f(U a, V b)
        { return (a < b); }

        static bool f(const char *a, const char *b)
        { return (strcmp(a, b) < 0); }
    };

    template<> struct F_Less_POD<true>
    {
        template<typename T, typename U>
        static bool f(const T& a, const U& b)
        { return (a < b); }
    };

    /* GREATER THAN OR EQUAL FUNCTOR - internal implementation */

    template<bool T> struct F_Greater_Eq_POD
    {
        template<typename U, typename V> static bool f(U a, V b)
        { return (a >= b); }

        static bool f(const char *a, const char *b)
        { return (strcmp(a, b) >= 0); }
    };

    template<> struct F_Greater_Eq_POD<true>
    {
        template<typename T, typename U>
        static bool f(const T& a, const U& b)
        { return (a >= b); }
    };

    /* LESS THAN OR EQUAL FUNCTOR - internal implementation */

    template<bool T> struct F_Less_Eq_POD
    {
        template<typename U, typename V> static bool f(U a, V b)
        { return (a <= b); }

        static bool f(const char *a, const char *b)
        { return (strcmp(a, b) <= 0); }
    };

    template<> struct F_Less_Eq_POD<true>
    {
        template<typename T, typename U>
        static bool f(const T& a, const U& b)
        { return (a <= b); }
    };

    /* Struct: Unary_Function
     * Base object struct for unary functor, that is one that
     * takes just one argument and has one result. Unused currently.
     */
    template<typename T, typename U>
    struct Unary_Function
    {
        /* Typedef: arg */
        typedef T arg;
        /* Tyoedef: ret */
        typedef U ret;
    };

    /* Struct: Binary_Function
     * Base object struct for binary functor, that is one that
     * takes two arguments and has one result. Used by multiple
     * functors. Arguments can be of different types, too.
     */
    template<typename T, typename U, typename V>
    struct Binary_Function
    {
        /* Typedef: arg1 */
        typedef T arg1;
        /* Typedef: arg2 */
        typedef U arg2;
        /* Typedef: ret */
        typedef V ret;
    };

    /* Struct: Equal
     * A functor returning true if two given arguments are equal.
     */
    template<typename T, typename U>
    struct Equal: Binary_Function<T, U, bool>
    {
        bool operator()(const T& a, const U& b) const
        {
            return F_Eq_POD<
                !traits::Is_POD<T>::value &&
                !traits::Is_POD<U>::value
            >::f(a, b);
        }
    };

    /* Struct: Not_Equal
     * A functor returning true if two given arguments are not equal.
     */
    template<typename T, typename U>
    struct Not_Equal: Binary_Function<T, U, bool>
    {
        bool operator()(const T& a, const U& b) const
        {
            return F_Neq_POD<
                !traits::Is_POD<T>::value &&
                !traits::Is_POD<U>::value
            >::f(a, b);
        }
    };

    /* Struct: Greater
     * A functor returning true if the left value is greater
     * than the right one.
     */
    template<typename T, typename U>
    struct Greater: Binary_Function<T, U, bool>
    {
        bool operator()(const T& a, const U& b) const
        {
            return F_Greater_POD<
                !traits::Is_POD<T>::value &&
                !traits::Is_POD<U>::value
            >::f(a, b);
        }
    };

    /* Struct: Less
     * A functor returning true if the left value is less
     * than the right one.
     */
    template<typename T, typename U>
    struct Less: Binary_Function<T, U, bool>
    {
        bool operator()(const T& a, const U& b) const
        {
            return F_Less_POD<
                !traits::Is_POD<T>::value &&
                !traits::Is_POD<U>::value
            >::f(a, b);
        }
    };

    /* Struct: Greater_Equal
     * A functor returning true if the left value is greater
     * or equal than the right one.
     */
    template<typename T, typename U>
    struct Greater_Equal: Binary_Function<T, U, bool>
    {
        bool operator()(const T& a, const U& b) const
        {
            return F_Greater_Eq_POD<
                !traits::Is_POD<T>::value &&
                !traits::Is_POD<U>::value
            >::f(a, b);
        }
    };

    /* Struct: Less_Equal
     * A functor returning true if the left value is less
     * or equal than the right one.
     */
    template<typename T, typename U>
    struct Less_Equal: Binary_Function<T, U, bool>
    {
        bool operator()(const T& a, const U& b) const
        {
            return F_Less_Eq_POD<
                !traits::Is_POD<T>::value &&
                !traits::Is_POD<U>::value
            >::f(a, b);
        }
    };
} /* end namespace functional */

#endif

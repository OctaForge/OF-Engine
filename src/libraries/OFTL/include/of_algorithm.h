/*
 * File: of_algorithm.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  OFTL algorithm library.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 *  Used libstdc++ and http://www.boost.org/doc/libs/1_44_0/libs/type_traits/
 *  doc/html/boost_typetraits/examples/iter.html as reference.
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_ALGORITHM_H
#define OF_ALGORITHM_H

#include "of_iterator.h"
#include "of_traits.h"

/*
 * Package: algorithm
 * Various algorithms for OFTL.
 */
namespace algorithm
{
    /*
     * Function: max
     * Returns the largest of
     * the given values.
     */
    template<typename T>
    inline T max(T a, T b)
    {
        if (a < b) return b;
        return a;
    }

    /*
     * Function: max
     * Returns the smallest of
     * the given values.
     */
    template<typename T>
    inline T min(T a, T b)
    {
        if (b < a) return b;
        return a;
    }

    /*
     * Function: clamp
     * Clamps a given value a into the
     * bounds of b(minimum) and c(maximum)
     */
    template<typename T>
    inline T clamp(T a, T b, T c)
    {
        return max(b, min(a, c));
    }

    template<typename T> inline void swap(T& a, T& b)
    {
        T t = a;
        a   = b;
        b   = t;
    }

    template<bool T> struct i_swap
    {
        template<typename U, typename V> static void iter_swap(U a, V b)
        {
            typedef typename iterators::traits<U>::val_t val_t;
            val_t t = *a;
            *a      = *b;
            *b      = t;
        }
    };

    template<> struct i_swap<true>
    {
        template<typename U, typename V> static void iter_swap(U a, V b)
        {
            swap(*a, *b);
        }
    };

    template<typename T, typename U> inline void iter_swap(T a, U b)
    {
        typedef typename iterators::traits<T>::val_t val_t1;
        typedef typename iterators::traits<U>::val_t val_t2;
        typedef typename iterators::traits<T>::ref_t ref_t1;
        typedef typename iterators::traits<U>::ref_t ref_t2;
        i_swap<
            traits::are_equal<val_t1, val_t2> ::value &&
            traits::are_equal<ref_t1, val_t1&>::value &&
            traits::are_equal<ref_t2, val_t2&>::value
        >::iter_swap(a, b);
    }

    /*
     * Function: compare
     * Generic compare function that returns 1
     * when a is bigger than b, 0 when they're
     * equal and -1 when b is bigger than a.
     *
     * Used mainly in sets / maps to compare keys.
     */
    template<typename T> inline int compare(T a, T b)
    {
        return ((a > b) ? 1 : ((a < b) ? -1 : 0));
    }

    /*
     * Function: compare
     * Specialization for strings.
     */
    template<> inline int compare(const char *a, const char *b)
    {
        return strcmp(a, b);
    }

    /*
     * Function: quicksort_cmp
     * Default comparison function for <sort>.
     */
    template<typename T>
    inline bool sort_cmp(T a, T b)
    {
        return (a <= b);
    }
} /* end namespace iterators */

#endif

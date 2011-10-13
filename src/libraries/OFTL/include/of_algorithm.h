/* File: of_algorithm.h
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

/* Package: algorithm
 * Various algorithms for OFTL.
 */
namespace algorithm
{
    /* Function: max
     * Returns the largest of
     * the given values.
     */
    template<typename T>
    inline T max(T a, T b)
    {
        if (a < b) return b;
        return a;
    }

    /* Function: max
     * Returns the smallest of
     * the given values.
     */
    template<typename T>
    inline T min(T a, T b)
    {
        if (b < a) return b;
        return a;
    }

    /* Function: clamp
     * Clamps a given value a into the
     * bounds of b(minimum) and c(maximum)
     */
    template<typename T>
    inline T clamp(T a, T b, T c)
    {
        return max(b, min(a, c));
    }

    /* Function: swap
     * Assigns the content of a to b and
     * the content of b to a.
     */
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

    /* Function: iter_swap
     * Assigns the content of *a to *b and
     * the content of *b to *a.
     *
     * Internally does some more checking
     * for proxying iterators.
     */
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

    /* Function: compare
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

    /* Function: compare
     * Specialization for strings.
     */
    template<> inline int compare(const char *a, const char *b)
    {
        return strcmp(a, b);
    }

    /* Function: quicksort_cmp
     * Default comparison function for <sort> and <insertion_sort>.
     * Using this on compatible value type (one that can be compared
     * with <) results in sort from the lowest to the highest value.
     *
     * For other ordering or incompatible value types, define your
     * own and pass it to the respective sort function.
     */
    template<typename T>
    inline bool sort_cmp(const T& a, const T& b)
    {
        return (a < b);
    }

    /* Function: insertion_sort
     * Performs an insertion sort on the range given by "first"
     * and "last", with comparator function defined by "cmp".
     * See below for version that doesn't need "cmp".
     *
     * For big ranges, it's a better idea to use <sort>.
     */
    template<typename T, typename U>
    inline void insertion_sort(T first, T last, U cmp)
    {
        for (T i = (first + 1); i < last; ++i)
        {
            typename iterators::traits<T>::val_t tmp = *i;
            T j = i;

            for (; j > first && cmp(tmp, *(j - 1)); --j)
                  *j = *(j - 1);

            *j = tmp;
        }
    }

    /* Function: insertion_sort
     * An overload that doesn't require a comparator
     * function and simply uses <sort_cmp> instead.
     */
    template<typename T>
    inline void insertion_sort(T first, T last)
    {
        insertion_sort(first, last, sort_cmp<
            typename iterators::traits<T>::val_t
        >);
    }

    /* Function: sort
     * Sorts a range given by "first" and "last", with
     * comparator function defined by "cmp". See below
     * for version that doesn't need "cmp".
     *
     * Internally, this is a hybrid sorting algorithm,
     * which first uses quicksort with a pivot of median
     * of three if the range is big and when the chunk
     * is 10 elements long or fewer, it performs an
     * <insertion_sort> which is more efficient in
     * such cases. You can use this for any general
     * sorting then, because it should be efficient
     * for both small and big ranges.
     */
    template<typename T, typename U>
    void sort(T first, T last, U cmp)
    {
        while ((last - first) > 10)
        {
            T pivot(first + ((last - first) / 2));

            if (cmp(*first, *pivot) && cmp(*(last - 1), *first))
            {
                pivot = first;
            }
            else if (cmp(*(last - 1), *pivot) && cmp(*first, *(last - 1)))
            {
                pivot = last - 1;
            }

            typename iterators::traits<T>::val_t p(*pivot);
            iter_swap(pivot, last - 1);

            T s = first;
            for (T it = first; it != (last - 1); ++it)
            {
                if (cmp(*it, p))
                {
                    iter_swap(s, it);
                    ++s;
                }
            }
            iter_swap(last - 1, s);
            pivot = s;

            sort(first,     pivot, cmp);
            sort(pivot + 1, last,  cmp);
        }
        insertion_sort(first, last, cmp);
    }

    /* Function: sort
     * An overload that doesn't require a comparator
     * function and simply uses <sort_cmp> instead.
     */
    template<typename T>
    void sort(T first, T last)
    {
        sort(first, last, sort_cmp<
            typename iterators::traits<T>::val_t
        >);
    }
} /* end namespace algorithm */

#endif

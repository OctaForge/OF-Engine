/*
 * File: of_pair.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Pair class header.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_PAIR_H
#define OF_PAIR_H

/*
 * Package: types
 * A namespace containing various container types.
 */
namespace types
{
    /*
     * Class: pair
     * This is a pair struct which encapsulates two members.
     * The members are passed by const ref in the constructor.
     */
    template<typename T, typename U> struct pair
    {
        /*
         * Constructor: pair
         * Default empty ctor.
         */
        pair(): first(T()), second(U()) {}

        /*
         * Constructor: pair
         * A constructor accepting arguments of
         * types T and U. Passing is done by const
         * ref.
         */
        pair(const T& a, const U& b): first(a), second(b) {}

        /*
         * Constructor: pair
         * A constructor accepting another pair,
         * again by const reference.
         */
        pair(const pair<T, U>& p): first(p.first), second(p.second) {}

        /*
         * Operator: =
         * A copy constructor.
         */
        pair& operator=(const pair& p)
        {
            if (&p == this) return *this;

            first  = p.first;
            second = p.second;

            return *this;
        }

        /*
         * Variable: first
         * The "T" member which you can access / set.
         */
        T first;

        /*
         * Variable: second
         * The "U" member which you can access / set.
         */
        U second;
    };
} /* end namespace types */

/*
 * Package: algorithm
 * The pair header overloads algorithm compare
 * function for pair types.
 */
namespace algorithm
{
    /*
     * Function: compare
     * Comparison for cases where both arguments are <pair> <T, U>.
     */
    template<typename T, typename U>
    inline int compare(const types::pair<T, U>& a, const types::pair<T, U>& b)
    {
        return compare(a.first, b.first);
    }

    /*
     * Function: compare
     * Comparison for cases where first argument is T and
     * second argument is <pair> <T, U>.
     */
    template<typename T, typename U>
    inline int compare(const T& a, const types::pair<T, U>& b)
    {
        return compare(a, b.first);
    }
} /* end namespace algorithm */

#endif

/* File: of_pair.h
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

#include "of_functional.h"

/* Package: types
 * A namespace containing various container types.
 */
namespace types
{
    /* Struct: Pair
     * This is a pair struct which encapsulates two members. The members are
     * passed by const ref in the constructor.
     */
    template<typename T, typename U> struct Pair
    {
        /* Constructor: Pair
         * Default empty ctor.
         */
        Pair(): first(T()), second(U()) {}

        /* Constructor: Pair
         * A constructor accepting arguments of types T and U. Passing is
         * done by const ref.
         */
        Pair(const T& a, const U& b): first(a), second(b) {}

        /* Constructor: Pair
         * A constructor accepting another Pair, again by const reference.
         */
        Pair(const Pair<T, U>& p): first(p.first), second(p.second) {}

        /* Operator: =
         * A copy constructor.
         */
        Pair& operator=(const Pair& p)
        {
            if (&p == this) return *this;

            first  = p.first;
            second = p.second;

            return *this;
        }

        /* Variable: first
         * The "T" member which you can access / set.
         */
        T first;

        /* Variable: second
         * The "U" member which you can access / set.
         */
        U second;

        /* Operator: == */
        friend bool operator==(const Pair& a, const Pair& b)
        { return functional::Equal<T, T>()(a.first, b.first); }

        /* Operator: == */
        friend bool operator==(const T& a, const Pair& b)
        { return functional::Equal<T, T>()(a, b.first); }

        /* Operator: != */
        friend bool operator!=(const Pair& a, const Pair& b)
        { return functional::Not_Equal<T, T>()(a.first, b.first); }

        /* Operator: != */
        friend bool operator!=(const T& a, const Pair& b)
        { return functional::Not_Equal<T, T>()(a, b.first); }

        /* Operator: < */
        friend bool operator<(const Pair& a, const Pair& b)
        { return functional::Less<T, T>()(a.first, b.first); }

        /* Operator: < */
        friend bool operator<(const T& a, const Pair& b)
        { return functional::Less<T, T>()(a, b.first); }

        /* Operator: <= */
        friend bool operator<=(const Pair& a, const Pair& b)
        { return functional::Less_Equal<T, T>()(a.first, b.first); }

        /* Operator: <= */
        friend bool operator<=(const T& a, const Pair& b)
        { return functional::Less_Equal<T, T>()(a, b.first); }

        /* Operator: > */
        friend bool operator>(const Pair& a, const Pair& b)
        { return functional::Greater<T, T>()(a.first, b.first); }

        /* Operator: > */
        friend bool operator>(const T& a, const Pair& b)
        { return functional::Greater<T, T>()(a, b.first); }

        /* Operator: >= */
        friend bool operator>=(const Pair& a, const Pair& b)
        { return functional::Greater_Equal<T, T>()(a.first, b.first); }

        /* Operator: >= */
        friend bool operator>=(const T& a, const Pair& b)
        { return functional::Greater_Equal<T, T>()(a, b.first); }
    };
} /* end namespace types */

#endif

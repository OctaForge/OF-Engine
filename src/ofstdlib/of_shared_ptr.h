/*
 * File: of_shared_ptr.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  shared_ptr class header.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 *  Inspired by implementation from ecaprice library
 *  (http://github.com/graphitemaster/ecaprice)
 *  by Dale "graphitemaster" Weiler.
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_SHARED_PTR_H
#define OF_SHARED_PTR_H

#include <cstdlib>

#include "of_utils.h"

/*
 * Package: types
 * This namespace features some types used in OctaForge.
 * This part exactly defines shared_ptr.
 */
namespace types
{
    /*
     * Class: shared_ptr
     * A shared pointer. Basically a reference counted container.
     * Useful for i.e. storing pointers in various container types
     * like vectors and hashtables without risking leaks.
     */
    template<typename T> struct shared_ptr
    {
        /*
         * Constructor: shared_ptr
         * Initializes empty shared_ptr.
         */
        shared_ptr();

        /*
         * Constructor: shared_ptr
         * Initializes shared_ptr from shared_ptr. Inherits
         * its pointer and reference count.
         */
        shared_ptr(const shared_ptr<T>& p);

        /*
         * Constructor: shared_ptr
         * Initializes shared_ptr from a pointer. Initializes
         * the reference count as result of <nil>.
         */
        shared_ptr(T *p);

        /*
         * Destructor: shared_ptr
         * Decrements the <counter>.
         */
        ~shared_ptr();

        /*
         * Operator: ->
         * Overload of this operator so you can manipulate
         * with the container simillarily to standard pointer.
         */
        T *operator->();

        /*
         * Operator: *
         * Overload of this operator so you can manipulate
         * with the container simillarily to standard pointer.
         */
        T& operator*();

        /*
         * Operator: ->
         * Overload of this operator so you can manipulate
         * with the container simillarily to standard pointer.
         * Const version.
         */
        const T *operator->() const;

        /*
         * Operator: *
         * Overload of this operator so you can manipulate
         * with the container simillarily to standard pointer.
         * Const version.
         */
        const T& operator*() const;

        /*
         * Operator: ==,!=,<,<=,>,>=
         * Overloads for comparison operators.
         */
        bool operator==(const shared_ptr<T>& p) const;
        bool operator!=(const shared_ptr<T>& p) const;
        bool operator< (const shared_ptr<T>& p) const;
        bool operator<=(const shared_ptr<T>& p) const;
        bool operator> (const shared_ptr<T>& p) const;
        bool operator>=(const shared_ptr<T>& p) const;

        /*
         * Function: get_count
         * Returns the reference count as size_t.
         */
        size_t get_count();

        /*
         * Function: increment
         * Increments the counter.
         */
        void increment();

        /*
         * Function: decrement
         * Decrements the counter.
         */
        void decrement();

        /*
         * Function: nil
         * Nil for the reference counter. It's static,
         * so it can live on for inherited shared_ptrs.
         */
        static size_t *nil();

        /*
         * Variable: ptr
         * The pointer.
         */
        T *ptr;

        /*
         * Variable: count
         * The reference count stored as pointer to size_t.
         */
        size_t *count;
    };
} /* end namespace types */

#endif

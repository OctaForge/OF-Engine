/* File: of_shared_ptr.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Shared_ptr class header.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 *  Originally inspired by implementation from ecaprice library
 *  (http://github.com/graphitemaster/ecaprice) by Dale "graphitemaster"
 *  Weiler, currently completely custom implementation.
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_SHARED_PTR_H
#define OF_SHARED_PTR_H

#include "of_utils.h"

/* Package: types
 * A namespace containing various container types.
 */
namespace types
{
    /* Struct: Shared_Ptr
     * A shared pointer. Basically a reference counted container. Useful for
     * i.e. storing pointers in various container types like vectors and
     * hashtables without risking leaks.
     */
    template<typename T> struct Shared_Ptr
    {
        /* Constructor: Shared_Ptr
         * Initializes empty Shared_Ptr.
         */
        Shared_Ptr(): p_ptr(NULL), p_count(NULL)
        {
            p_count = new p_counter;
        }

        /* Constructor: Shared_Ptr
         * Initializes Shared_Ptr from Shared_Ptr. Increments the counter.
         */
        Shared_Ptr(const Shared_Ptr<T>& p): p_ptr(p.p_ptr), p_count(p.p_count)
        {
            ++p_count->count;
        }

        /* Constructor: Shared_Ptr
         * Initializes Shared_Ptr from a pointer.
         */
        Shared_Ptr(T *p): p_ptr(p), p_count(NULL)
        {
            p_count = new p_counter;
        }

        /* Destructor: Shared_Ptr
         * Decrements the counter. If it reaches 0, both pointer and
         * counter will be freed.
         */
        ~Shared_Ptr()
        {
            if (p_count && --(p_count->count) == 0)
            {
                delete p_ptr;
                delete p_count;
            }
        }

        /* Operator: =
         * Assigns the Shared_Ptr from another one. Inherits its reference
         * count and increments it by one.
         */
        Shared_Ptr<T>& operator=(const Shared_Ptr<T>& p)
        {
            if (&p != this)
            {
                if (p_count && --(p_count->count) == 0)
                {
                    delete p_ptr;
                    delete p_count;
                }
                p_ptr   = p.p_ptr;
                p_count = p.p_count;
                ++(p_count->count);
            }
            return *this;
        }

        /* Function: get
         * Returns the raw pointer.
         */
        T *get() { return p_ptr; }

        /* Function: get
         * Returns a const version of the raw pointer.
         */
        const T *get() const { return p_ptr; }

        /* Operator: ->
         * Overload of this operator so you can manipulate with the container
         * simillarily to a standard pointer.
         */
        T *operator->() { return p_ptr; }

        /* Operator: *
         * Overload of this operator so you can manipulate with the container
         * simillarily to a standard pointer.
         */
        T& operator*() { return *p_ptr; }

        /* Operator: ->
         * Overload of this operator so you can manipulate with the container
         * simillarily to a standard pointer. Const version.
         */
        const T *operator->() const { return p_ptr; }

        /* Operator: *
         * Overload of this operator so you can manipulate with the container
         * simillarily to a standard pointer. Const version.
         */
        const T& operator*() const { return *p_ptr; }

        /* Operator: == */
        bool operator==(const Shared_Ptr<T>& p) const
        { return p_ptr == p.p_ptr; }

        /* Operator: != */
        bool operator!=(const Shared_Ptr<T>& p) const
        { return p_ptr != p.p_ptr; }

        /* Operator: < */
        bool operator< (const Shared_Ptr<T>& p) const
        { return p_ptr <  p.p_ptr; }

        /* Operator: <= */
        bool operator<=(const Shared_Ptr<T>& p) const
        { return p_ptr <= p.p_ptr; }

        /* Operator: > */
        bool operator> (const Shared_Ptr<T>& p) const
        { return p_ptr >  p.p_ptr; }

        /* Operator: >= */
        bool operator>=(const Shared_Ptr<T>& p) const
        { return p_ptr >= p.p_ptr; }

    protected:

        struct p_counter
        {
            p_counter(): count(1) {};
            size_t count;
        };

        T         *p_ptr;
        p_counter *p_count;
    };
} /* end namespace types */

#endif

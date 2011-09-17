/*
 * File: of_shared_ptr.cpp
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

#include "of_shared_ptr.h"

namespace types
{
    /* empty constructor */
    template<typename T>
    shared_ptr<T>::shared_ptr(): ptr(NULL), count(nil())
    {
        increment();
    }

    /* shared_ptr constructor */
    template<typename T>
    shared_ptr<T>::shared_ptr(const shared_ptr<T>& p):
        ptr(p.ptr), count(p.count)
    {
        increment();
    }

    /* pointer constructor */
    template<typename T>
    shared_ptr<T>::shared_ptr(T *p): ptr(p), count(new size_t(1)) {}

    /* destructor */
    template<typename T>
    shared_ptr<T>::~shared_ptr()
    {
        decrement();
    }

    /* overloads for manipulating pointer-ish */
    template<typename T> T *shared_ptr<T>::operator->() { return  ptr; }
    template<typename T> T& shared_ptr<T>::operator* () { return *ptr; }

    /* const overloads for getting */
    template<typename T>
    const T *shared_ptr<T>::operator->() const { return  ptr; }
    template<typename T>
    const T& shared_ptr<T>::operator* () const { return *ptr; }

    /* comparison operators */
    template<typename T>
    bool shared_ptr<T>::operator==(const shared_ptr<T>& p) const
    {
        return ptr == p.ptr;
    }
    template<typename T>
    bool shared_ptr<T>::operator!=(const shared_ptr<T>& p) const
    {
        return ptr != p.ptr;
    }
    template<typename T>
    bool shared_ptr<T>::operator< (const shared_ptr<T>& p) const
    {
        return ptr < p.ptr;
    }
    template<typename T>
    bool shared_ptr<T>::operator<=(const shared_ptr<T>& p) const
    {
        return ptr <= p.ptr;
    }
    template<typename T>
    bool shared_ptr<T>::operator> (const shared_ptr<T>& p) const
    {
        return ptr >  p.ptr;
    }
    template<typename T>
    bool shared_ptr<T>::operator>=(const shared_ptr<T>& p) const
    {
        return ptr >= p.ptr;
    }

    /* count getter */
    template<typename T> size_t shared_ptr<T>::get_count()
    {
        return *count;
    }

    /* incrementer */
    template<typename T> void shared_ptr<T>::increment()
    {
        ++(*count);
    }

    /* decrementer */
    template<typename T> void shared_ptr<T>::decrement()
    {
        if (--(*count) == 0)
        {
            delete ptr;
            delete count;
        }
    }

    /* static nil */
    template<typename T> size_t *shared_ptr<T>::nil()
    {
        static size_t nc = 1;
        return &nc;
    }
} /* end namespace types */

/*
 * File: of_iterator.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Basic iterator types.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_ITERATOR_H
#define OF_ITERATOR_H

#include <stddef.h>

/*
 * Package: iterators
 * This namespace provides various iterator types
 * like reverse iterator and iterator traits.
 */
namespace iterators
{
    /*
     * Struct: traits
     * Default iterator traits. Every iterator should have
     * 4 typedefs, diff_t, which is a size type (for i.e.
     * offset between iterators). That one is usually
     * ptrdiff_t.
     *
     * Then val_t has to be defined, which specifies a
     * value type for the iterator. Then, ptr_t specifies
     * pointer type (mostly pointer to value type) and
     * ref_t specifies reference type.
     */
    template<typename T> struct traits
    {
        /* Typedef: diff_t */
        typedef typename T::diff_t diff_t;
        /* Typedef: val_t */
        typedef typename T::val_t  val_t;
        /* Typedef: ptr_t */
        typedef typename T::ptr_t  ptr_t;
        /* Typedef: ref_t */
        typedef typename T::ref_t  ref_t;
    };

    /*
     * Struct: traits
     * Special structure for pointer types. Difference type is
     * ptrdiff_t, value type is T, pointer type T* and reference
     * type T&.
     */
    template<typename T> struct traits<T*>
    {
        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: val_t */
        typedef T  val_t;
        /* Typedef: ptr_t */
        typedef T* ptr_t;
        /* Typedef: ref_t */
        typedef T& ref_t;
    };

    /*
     * Struct: traits
     * Special structure for const pointer types. Difference
     * type is ptrdiff_t, value type is T, pointer type
     * const T* and reference type const T&.
     */
    template<typename T> struct traits<const T*>
    {
        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: ptr_t */
        typedef const T*  ptr_t;
        /* Typedef: ref_t */
        typedef const T&  ref_t;
        /* Typedef: val_t */
        typedef T val_t;
    };

    /*
     * Struct: traits
     * This one is for void pointers, as there can't be a
     * "void" value type. Difference type is ptrdiff_t,
     * value type unsigned char, pointer type void*
     * and reference type unsigned char&.
     */
    template<> struct traits<void*>
    {
        /* Typedef: diff_t */
        typedef ptrdiff_t    diff_t;
        /* Typedef: val_t */
        typedef unsigned char val_t;
        /* Typedef: ptr_t */
        typedef void*  ptr_t;
        /* Typedef: ref_t */
        typedef val_t& ref_t;
    };

    /*
     * Struct: traits
     * This one is for const void pointers. Difference
     * type is ptrdiff_t, value type unsigned char,
     * pointer type const void* and reference type
     * const unsigned char&.
     */
    template<> struct traits<const void*>
    {
        /* Typedef: diff_t */
        typedef ptrdiff_t    diff_t;
        /* Typedef: val_t */
        typedef unsigned char val_t;
        /* Typedef: ptr_t */
        typedef const void*  ptr_t;
        /* Typedef: ref_t */
        typedef const val_t& ref_t;
    };

    /*
     * Struct: reverse
     * A reverse iterator. Given any iterator type (random
     * access or bidirectional), it returns a reverse one
     * for the type. Incrementing then means going back,
     * first value will be in fact last value and so on.
     *
     * Reverse iterators are usually returned by "rbegin"
     * and "rend" methods of container types.
     */
    template<typename T> struct reverse
    {
        /* Typedef: diff_t */
        typedef typename traits<T>::diff_t diff_t;
        /* Typedef: ptr_t */
        typedef typename traits<T>::ptr_t ptr_t;
        /* Typedef: ref_t */
        typedef typename traits<T>::ref_t ref_t;
        /* Typedef: val_t */
        typedef typename traits<T>::val_t val_t;

        /*
         * Constructor: reverse
         * An empty constructor.
         */
        reverse(): it_base(T()) {}

        /*
         * Constructor: reverse
         * Constructs a reverse iterator from given iterator.
         */
        reverse(T it): it_base(it ) {}

        /*
         * Constructor: reverse
         * Constructs a reverse iterator from a reverse iterator of
         * any type.
         */
        template<typename U>
        reverse(const reverse<U>& it): it_base(it.base()) {}

        /*
         * Function: equals
         * Returns true if given reverse iterator equals the current
         * one (that is, if their bases are the same).
         */
        template<typename U>
        bool equals(const reverse<U>& it) const
        { return (it.base() == it_base); }

        /*
         * Function: base
         * Returns the standard iterator held by the
         * reverse iterator. It isn't a reference, so
         * you can safely modify the returned iterator
         * without worrying about the reverse one.
         */
        T base() const { return it_base; }

        /*
         * Operator: *
         * Overloaded dereference operator. Returns what
         * a standard iterator it holds returns when
         * dereferencing.
         */
        ref_t operator*() const
        {
            T tmp(it_base);
            return *--tmp;
        }

        /*
         * Operator: +
         * Useful for random access iterators to
         * perform offsets. Basically returns
         * reverse iterator to "base - N".
         */
        reverse operator+(diff_t n) const
        {
            return reverse(it_base - n);
        }

        /*
         * Operator: ++
         * The prefix version of the ++ operator.
         * Decrements the base iterator.
         */
        reverse& operator++()
        {
            --it_base;
            return *this;
        }

        /*
         * Operator: ++
         * The postfix version of the ++ operator.
         * Creates a new reverse iterator from
         * this one, decrements the current one
         * and returns the new one.
         */
        reverse operator++(int)
        {
            reverse tmp(*this);
            --it_base;
            return tmp;
        }

        /*
         * Operator: +=
         * Decrements the base iterator by N.
         */
        reverse& operator+=(diff_t n)
        {
            it_base -= n;
            return *this;
        }

        /*
         * Operator: -
         * See above. Performs the opposite action.
         */
        reverse operator-(diff_t n) const
        {
            return reverse(it_base + n);
        }

        /*
         * Operator: --
         * See above. Performs the opposite action.
         * Prefix version.
         */
        reverse& operator--()
        {
            ++it_base;
            return *this;
        }

        /*
         * Operator: --
         * See above. Performs the opposite action.
         * Postfix version.
         */
        reverse operator--(int)
        {
            reverse tmp(*this);
            ++it_base;
            return tmp;
        }

        /*
         * Operator: -=
         * See above. Performs the opposite action.
         */
        reverse& operator-=(size_t n)
        {
            it_base += n;
            return *this;
        }

        /*
         * Operator: ->
         * Defined for pointer-based base iterators in
         * order to access elements in a pointer-ish way.
         */
        ptr_t operator->() const
        {
            return &(operator*());
        }

        /*
         * Operator: []
         * Defined for pointer/array-based base iterators
         * in order to access elements in an array-ish way.
         */
        ref_t operator[](size_t n) const
        {
            return *(*it_base + n);
        }

    protected:

        /*
         * Variable: it_base
         * The base iterator. Protected access.
         */
        T it_base;
    };

    /*
     * Operator: ==
     * Defines == comparison behavior for reverse iterators.
     * Global operator, not part of the class. Can be used
     * for any two reverse iterators, even of different types.
     */
    template<typename T, typename U>
    inline bool operator==(const reverse<T>& a, const reverse<U>& b)
    { return a.equals(b); }

    /* Operator: != */
    template<typename T, typename U>
    inline bool operator!=(const reverse<T>& a, const reverse<U>& b)
    { return !a.equals(b); }
} /* end namespace iterators */

#endif

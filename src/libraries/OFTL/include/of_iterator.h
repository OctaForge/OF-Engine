/* File: of_iterator.h
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

/* Package: iterators
 * This namespace provides various iterator types
 * like reverse iterator and iterator traits.
 */
namespace iterators
{
    /* Struct: Traits
     * Default iterator traits. Every iterator should have 4 typedefs,
     * diff_t, which is a size type (for i.e. offset between iterators).
     * That one is usually ptrdiff_t.
     *
     * Then val_t has to be defined, which specifies a value type for the
     * iterator. Then, ptr_t specifies pointer type (mostly pointer to
     * the value type) and ref_t specifies reference type.
     */
    template<typename T> struct Traits
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

    /* Struct: Traits
     * Special structure for pointer types. Difference type is ptrdiff_t,
     * value type is T, pointer type T* and reference type T&.
     */
    template<typename T> struct Traits<T*>
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

    /* Struct: Traits
     * Special structure for const pointer types. Difference type is
     * ptrdiff_t, value type is T, pointer type const T* and reference
     * type const T&.
     */
    template<typename T> struct Traits<const T*>
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

    /* Struct: Traits
     * This one is for void pointers, as there can't be a "void" value type.
     * Difference type is ptrdiff_t, value type unsigned char, pointer type
     * void* and reference type unsigned char&.
     */
    template<> struct Traits<void*>
    {
        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: val_t */
        typedef unsigned char val_t;
        /* Typedef: ptr_t */
        typedef void*  ptr_t;
        /* Typedef: ref_t */
        typedef val_t& ref_t;
    };

    /* Struct: Traits
     * This one is for const void pointers. Difference type is ptrdiff_t,
     * value type unsigned char, pointer type const void* and reference
     * type const unsigned char&.
     */
    template<> struct Traits<const void*>
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

    /* Struct: Reverse_Iterator
     * A reverse iterator. Given any iterator type (random access or
     * bidirectional), it returns a reverse one for the type. Incrementing
     * then means going back, first value will be in fact last value and
     * so on.
     *
     * Reverse_Iterator iterators are usually returned by "rbegin" and "rend" methods
     * of container types.
     */
    template<typename T> struct Reverse_Iterator
    {
        /* Typedef: diff_t */
        typedef typename Traits<T>::diff_t diff_t;
        /* Typedef: ptr_t */
        typedef typename Traits<T>::ptr_t ptr_t;
        /* Typedef: ref_t */
        typedef typename Traits<T>::ref_t ref_t;
        /* Typedef: val_t */
        typedef typename Traits<T>::val_t val_t;

        /* Constructor: Reverse_Iterator
         * An empty constructor.
         */
        Reverse_Iterator(): p_base(T()) {}

        /* Constructor: Reverse_Iterator
         * Constructs a reverse iterator from given iterator.
         */
        Reverse_Iterator(T it): p_base(it) {}

        /* Constructor: Reverse_Iterator
         * Constructs a reverse iterator from a reverse iterator of any type.
         */
        template<typename U>
        Reverse_Iterator(const Reverse_Iterator<U>& it): p_base(it.base()) {}

        /* Function: base
         * Returns the standard iterator held by the reverse iterator. It
         * isn't a reference, so you can safely modify the returned iterator
         * without worrying about the reverse one.
         */
        T base() const { return p_base; }

        /* Operator: *
         * Overloaded dereference operator. Returns what a standard iterator
         * it holds returns when dereferencing.
         */
        ref_t operator*() const
        {
            T tmp(p_base);
            return *--tmp;
        }

        /* Operator: +
         * Useful for random access iterators to perform offsets. Basically
         * returns reverse iterator to "base - N".
         */
        Reverse_Iterator operator+(diff_t n) const
        {
            return Reverse_Iterator(p_base - n);
        }

        /* Operator: ++
         * The prefix version of the ++ operator. Decrements the base
         * iterator.
         */
        Reverse_Iterator& operator++()
        {
            --p_base;
            return *this;
        }

        /* Operator: ++
         * The postfix version of the ++ operator. Creates a new reverse
         * iterator from this one, decrements the current one and returns
         * the new one.
         */
        Reverse_Iterator operator++(int)
        {
            Reverse_Iterator tmp(*this);
            --p_base;
            return tmp;
        }

        /* Operator: +=
         * Decrements the base iterator by N.
         */
        Reverse_Iterator& operator+=(diff_t n)
        {
            p_base -= n;
            return *this;
        }

        /* Operator: -
         * See above. Performs the opposite action.
         */
        Reverse_Iterator operator-(diff_t n) const
        {
            return Reverse_Iterator(p_base + n);
        }

        /* Operator: --
         * See above. Performs the opposite action.
         * Prefix version.
         */
        Reverse_Iterator& operator--()
        {
            ++p_base;
            return *this;
        }

        /* Operator: --
         * See above. Performs the opposite action.
         * Postfix version.
         */
        Reverse_Iterator operator--(int)
        {
            Reverse_Iterator tmp(*this);
            ++p_base;
            return tmp;
        }

        /* Operator: -=
         * See above. Performs the opposite action.
         */
        Reverse_Iterator& operator-=(size_t n)
        {
            p_base += n;
            return *this;
        }

        /* Operator: ->
         * Defined for pointer-based base iterators in order to access
         * elements in a pointer-ish way.
         */
        ptr_t operator->() const
        {
            return &(operator*());
        }

        /* Operator: []
         * Defined for pointer/array-based base iterators in order to access
         * elements in an array-ish way.
         */
        ref_t operator[](size_t n) const
        {
            return *(*p_base + n);
        }

        /* Operator: == */
        template<typename U>
        friend bool operator==(
            const Reverse_Iterator& a, const Reverse_Iterator<U>& b
        ) { return a.base() == b.base(); }

        /* Operator: != */
        template<typename U>
        friend bool operator!=(
            const Reverse_Iterator& a, const Reverse_Iterator<U>& b
        ) { return a.base() != b.base(); }

    protected:

        T p_base;
    };
} /* end namespace iterators */

#endif

/* File: of_vector.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Vector class header.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *  Partially inspired by the Cube 2 Vector implementation (zlib).
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_VECTOR_H
#define OF_VECTOR_H

#include "of_traits.h"
#include "of_utils.h"
#include "of_new.h"
#include "of_iterator.h"
#include "of_algorithm.h"

/* Package: types
 * A namespace containing various container types.
 */
namespace types
{
    /* Struct: Vector
     * Vector is a container that holds a list of elements simillarily to an
     * array, but it's generic, can be easily manipulated (resized, appended
     * etc.) and its memory is managed automatically.
     */
    template<typename T> struct Vector
    {
        /* Variable: MIN_SIZE
         * The minimal amount of elements to reserve space for when creating
         * the buffer.
         */
        enum { MIN_SIZE = 8 };

        /* Typedef: it
         * Iterator typedef, a T*.
         */
        typedef T* it;

        /* Typedef: cit
         * Const iterator typedef, a const T*.
         */
        typedef const T* cit;

        /* Typedef: rit
         * Reverse iterator typedef, a <Reverse> < <it> >.
         */
        typedef iterators::Reverse_Iterator<it> rit;

        /* Typedef: vrit
         * Const reverse iterator typedef, a <Reverse> < <cit> >.
         */
        typedef iterators::Reverse_Iterator<cit> crit;

        /* Constructor: Vector
         * Constructs an empty vector.
         */
        Vector(): p_buf(NULL), p_length(0), p_capacity(0) {}

        /* Constructor: Vector
         * Constructs a vector from another vector.
         */
        Vector(const Vector& v): p_buf(NULL), p_length(0), p_capacity(0)
        {
            *this = v;
        }

        /* Constructor: Vector
         * Constructs a vector of a given size. Optional element given by
         * the second argument will be repeated in it.
         */
        Vector(size_t sz, const T& v = T()): Vector()
        {
            p_buf = new uchar[sz * sizeof(T)];
            p_length = p_capacity = sz;

            T *last = p_buf + sz;

            while   (p_buf != last)
                new (p_buf++) T(v);

            p_buf -= sz;
        }

        /* Destructor: Vector
         * Calls <clear>.
         */
        ~Vector() { clear(); }

        /* Operator: =
         * Assignment operator for the vector. It makes this vector take
         * parameters of the given vector.
         *
         * Buffer is not simply assigned, instead, a new one is allocated and
         * the elements are inserted inside it.
         *
         * This makes heavy use of copy constructors.
         */
        Vector& operator=(const Vector& v)
        {
            if (this == &v) return *this;

            if (p_capacity >= v.capacity())
            {
                if (!traits::Is_POD<T>::value)
                {
                    T *last = p_buf + p_length;

                    while (p_buf != last)
                         (*p_buf++).~T();

                    p_buf -= p_length;
                }
                p_length = v.length();
            }
            else
            {
                clear();

                p_length   = v.length  ();
                p_capacity = v.capacity();

                p_buf = (T*) new uchar[p_capacity * sizeof(T)];
            }

            if (traits::Is_POD<T>::value)
                memcpy(p_buf, v.p_buf, p_length * sizeof(T));
            else
            {
                T *last =   p_buf + p_length;
                T *vbuf = v.p_buf;

                while   (p_buf != last)
                    new (p_buf++) T(*vbuf++);

                p_buf -= p_length;
            }

            return *this;
        }

        /* Function: begin
         * Returns a pointer to the buffer.
         */
        it begin() { return p_buf; }

        /* Function: begin
         * Returns a const pointer to the buffer.
         */
        cit begin() const { return p_buf; }

        /* Function: rbegin
         * Returns a <reverse> iterator to <end>.
         */
        rit rbegin() { return rit(end()); }

        /* Function: rbegin
         * Returns a const <reverse> iterator to <end>.
         */
        crit rbegin() const { return crit(end()); }

        /* Function: end
         * Returns a pointer to the element after the last one.
         */
        it end() { return p_buf + p_length; }

        /* Function: end
         * Returns a const pointer to the element after the last one.
         */
        cit end() const { return p_buf + p_length; }

        /* Function: rend
         * Returns a <reverse> iterator to <begin>.
         */
        rit rend() { return rit(begin()); }

        /* Function: rend
         * Returns a const <reverse> iterator to <begin>.
         */
        crit rend() const { return crit(begin()); }

        /* Function: get_buf
         * Returns the internal buffer.
         */
        T *get_buf() { return p_buf; }

        /* Function: get_buf
         * Returns the internal buffer as const.
         */
        const T *get_buf() const { return p_buf; }

        /* Function: resize
         * Resizes the vector to be of given size. If the capacity is too
         * small for that, it calls <reserve> with the size first.
         *
         * Second optional argument provides data that can be copied into
         * each field that was initialized this time (happens when the
         * given size is greater than the old size).
         */
        void resize(size_t sz, const T& v = T())
        {
            size_t len = p_length;

            reserve   (sz);
            p_length = sz;

            if (traits::Is_POD<T>::value)
            {
                for (size_t i = len; i < p_length; i++)
                    p_buf[i] = T(v);
            }
            else
            {
                T *first = p_buf + len;
                T *last  = p_buf + p_length;

                while   (first != last)
                    new (first++) T(v);
            }
        }

        /* Function: length
         * Returns the current vector length.
         */
        size_t length() const { return p_length; }

        /* Function: capacity
         * Returns the current vector capacity.
         */
        size_t capacity() const { return p_capacity; }

        /* Function: is_empty
         * Returns true if the vector is empty, false otherwise.
         */
        bool is_empty() const { return (p_length == 0); }

        /* Function: reserve
         * Reserves the size given by the argument. If that is smaller
         * (or equal) than current capacity, this will do nothing.
         * If it's bigger, the buffer will be reallocated.
         */
        void reserve(size_t sz)
        {
            size_t old_cap = p_capacity;

            if (!p_capacity)
                 p_capacity = algorithm::max((size_t)MIN_SIZE, sz);
            else while (p_capacity < sz)
                        p_capacity *= 2;

            if (p_capacity <= old_cap) return;

            T *tmp = (T*) new uchar[p_capacity * sizeof(T)];
            if (old_cap > 0)
            {
                if (traits::Is_POD<T>::value)
                    memcpy(tmp, p_buf, p_length * sizeof(T));
                else
                {
                    T *curr = p_buf;
                    T *last = tmp + p_length;

                    while (tmp != last)
                    {
                        new (tmp++) T(*curr);

                        (*curr).~T();
                          curr++;
                    }

                    tmp -= p_length;
                }
                delete[] (uchar*)p_buf;
            }
            p_buf = tmp;
        }

        /* Operator: []
         * Returns a reference to the field on the given index.
         * Used for assignment.
         */
        T& operator[](size_t idx) { return p_buf[idx]; }

        /* Operator: []
         * Returns a const reference to the field on the given
         * index. Used for reading.
         */
        const T& operator[](size_t idx) const { return p_buf[idx]; }

        /* Function: at
         * Returns a reference to the field on the given index.
         * Used for assignment.
         */
        T& at(size_t idx) { return p_buf[idx]; }

        /* Function: at
         * Returns a const reference to the field on the given
         * index. Used for reading.
         */
        const T& at(size_t idx) const { return p_buf[idx]; }

        /* Function: push_back
         * Appends a given value to the end of the vector. If the current
         * capacity is not big enough to hold the future contents, it'll be
         * resized.
         *
         * This returns a reference to the newly added element.
         */
        T& push_back(const T& data = T())
        {
            if(p_length >= p_capacity)
                reserve   (p_capacity + 1);

            new  (&p_buf[p_length]) T(data);
            return p_buf[p_length++];
        }

        /* Function: pop_back
         * Pops a last value out of the vector.
         */
        void pop_back()
        {
            if (!traits::Is_POD<T>::value)
                p_buf[--p_length].~T();
            else
                p_length--;
        }

        /* Function: clear
         * Clears the vector contents. Deletes the buffer and sets the length
         * and capacity to 0.
         *
         * As the buffer is initialized as uchar*, it also calls a destructor
         * for each value inside the buffer.
         */
        void clear()
        {
            if (p_capacity > 0)
            {
                if (!traits::Is_POD<T>::value)
                {
                    T *last = p_buf + p_length;

                    while (p_buf != last)
                         (*p_buf++).~T();

                    p_buf -= p_length;
                }
                delete[] (uchar*)p_buf;

                p_length = p_capacity = 0;
            }
        }

    private:

        T     *p_buf;
        size_t p_length;
        size_t p_capacity;
    };
} /* end namespace types */

#endif

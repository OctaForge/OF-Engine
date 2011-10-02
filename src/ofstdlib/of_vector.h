/*
 * File: of_vector.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Vector class header.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *  Partially inspired by the Cube 2 vector implementation (zlib).
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_VECTOR_H
#define OF_VECTOR_H

#include "of_traits.h"
#include "of_utils.h"

/*
 * Package: types
 * This namespace features some types used in OctaForge.
 * This part exactly defines vector.
 */
namespace types
{
    /*
     * Class: vector
     * Vector is a container that holds a list of elements simillarily
     * to an array, but it's generic, can be easily manipulated (resized,
     * appended etc.) and its memory is managed automatically.
     */
    template<typename T> struct vector
    {
        /*
         * Variable: MIN_SIZE
         * The minimal amount of elements to reserve
         * space for when creating the buffer.
         */
        static const size_t MIN_SIZE = 8;

        /*
         * Constructor: vector
         * Constructs an empty vector.
         */
        vector(): buf(NULL), c_length(0), c_capacity(0) {}

        /*
         * Constructor: vector
         * Constructs a vector from another vector.
         */
        vector(const vector& v): buf(NULL), c_length(0), c_capacity(0)
        {
            *this = v;
        }

        /*
         * Constructor: vector
         * Constructs a vector of a given size. Optional element
         * given by the second argument will be repeated in it.
         */
        vector(size_t sz, const T& v = T()): vector()
        {
            buf = new uchar[sz * sizeof(T)];
            c_length = c_capacity = sz;

            T *last = buf + sz;

            while   (buf != last)
                new (buf++) T(v);

            buf -= sz;
        }

        /*
         * Destructor: vector
         * Calls <clear>.
         */
        ~vector() { clear(); }

        /*
         * Operator: =
         * Assignment operator for the vector. It makes this
         * vector take parameters of the given vector.
         *
         * Buffer is not simply assigned, instead, a new one
         * is allocated and the elements are inserted inside it.
         *
         * This makes heavy use of copy constructors.
         */
        vector& operator=(const vector& v)
        {
            if (this == &v) return *this;
        
            delete[] (uchar*)buf;

            c_length   = v.length  ();
            c_capacity = v.capacity();

            buf = (T*) new uchar[c_capacity * sizeof(T)];

            if (traits::is_pod<T>::value)
                memcpy(buf, v.buf, c_length * sizeof(T));
            else
            {
                T *last = buf + c_length;
                T *vbuf = v.buf;

                while   (buf != last)
                    new (buf++) T(*vbuf++);

                buf -= c_length;
            }

            return *this;
        }

        /*
         * Function: first
         * Returns a pointer to the buffer.
         */
        T *first() { return buf; }

        /*
         * Function: first
         * Returns a const pointer to the buffer.
         */
        const T *first() const { return buf; }

        /*
         * Function: last
         * Returns a pointer to the last buffer element.
         */
        T *last() { return buf + c_length - 1; }

        /*
         * Function: last
         * Returns a const pointer to the last buffer element.
         */
        const T *last() const { return buf + c_length - 1; }

        /*
         * Function: get_buf
         * Returns the internal buffer.
         */
        T *get_buf() { return buf; }

        /*
         * Function: get_buf
         * Returns the internal buffer as const.
         */
        const T *get_buf() const { return buf; }

        /*
         * Function: resize
         * Resizes the vector to be of given size. If the capacity
         * is too small for that, it calls <reserve> with the size
         * first.
         *
         * Second optional argument provides data that can be copied
         * into each field that was initialized this time (happens
         * when the given size is greater than the old size).
         */
        void resize(size_t sz, const T& v = T())
        {
            size_t len = c_length;

            reserve   (sz);
            c_length = sz;

            if (traits::is_pod<T>::value)
            {
                for (size_t i = len; i < c_length; i++)
                    buf[i] = T(v);
            }
            else
            {
                T *first = buf + len;
                T *last  = buf + c_length;

                while   (first != last)
                    new (first++) T(v);
            }
        }

        /*
         * Function: length
         * Returns the current vector length.
         */
        size_t length() const { return c_length; }

        /*
         * Function: capacity
         * Returns the current vector capacity.
         */
        size_t capacity() const { return c_capacity; }

        /*
         * Function: is_empty
         * Returns true if the vector is empty, false otherwise.
         */
        bool is_empty() const { return (c_length == 0); }

        /*
         * Function: reserve
         * Reserves the size given by the argument. If that is
         * smaller(or equal) than current capacity, this will
         * do nothing. If it's bigger, the buffer will be
         * reallocated.
         */
        void reserve(size_t sz)
        {
            size_t old_cap = c_capacity;

            if (!c_capacity)
                 c_capacity = max(MIN_SIZE, sz);
            else while (c_capacity < sz)
                        c_capacity *= 2;

            if (c_capacity <= old_cap) return;

            T *tmp = (T*) new uchar[c_capacity * sizeof(T)];
            if (old_cap > 0)
            {
                if (traits::is_pod<T>::value)
                    memcpy(tmp, buf, c_length * sizeof(T));
                else
                {
                    T *curr = buf;
                    T *last = tmp + c_length;

                    while (tmp != last)
                    {
                        new (tmp++) T(*curr);

                        (*curr).~T();
                          curr++;
                    }

                    tmp -= c_length;
                }
                delete[] (uchar*)buf;
            }
            buf = tmp;
        }

        /*
         * Operator: []
         * Returns a reference to the field on the given index.
         * Used for assignment.
         */
        T& operator[](size_t idx) { return buf[idx]; }

        /*
         * Operator: []
         * Returns a const reference to the field on the given
         * index. Used for reading.
         */
        const T& operator[](size_t idx) const { return buf[idx]; }

        /*
         * Function: at
         * Returns a reference to the field on the given index.
         * Used for assignment.
         */
        T& at(size_t idx) { return buf[idx]; }

        /*
         * Function: at
         * Returns a const reference to the field on the given
         * index. Used for reading.
         */
        const T& at(size_t idx) const { return buf[idx]; }

        /*
         * Function: push_back
         * Appends a given value to the end of the vector.
         * If the current capacity is not big enough to hold
         * the future contents, it'll be resized.
         *
         * This returns a reference to the newly added element.
         */
        T& push_back(const T& data = T())
        {
            if(c_length >= c_capacity)
                reserve   (c_capacity + 1);

            new  (&buf[c_length]) T(data);
            return buf[c_length++];
        }

        /*
         * Function: pop_back
         * Pops a last value out of the vector
         * and returns a reference to it.
         */
        T& pop_back() { return buf[--c_length]; }

        /*
         * Function: sort
         * Sorts the vector using the quicksort algorithm (see
         * the function in of_utils). The first argument is a
         * function as specified by the quicksort implementation,
         * second argument is the index to start sorting on, third
         * argument is the amount of items to sort.
         *
         * Only the first argument is mandatory.
         */
        template<typename U>
        void sort(U f, size_t idx = 0, size_t len = 0)
        {
            quicksort(&buf[idx], (!len) ? (c_length - idx - 1) : len, f);
        }

        /*
         * Function: clear
         * Clears the vector contents. Deletes the buffer
         * and sets the length and capacity to 0.
         *
         * As the buffer is initialized as uchar*, it also
         * calls a destructor for each value inside the buffer.
         */
        void clear()
        {
            if (c_capacity > 0)
            {
                if (!traits::is_pod<T>::value)
                {
                    T *last = buf + c_length;

                    while (buf != last)
                         (*buf++).~T();

                    buf -= c_length;
                }
                delete[] (uchar*)buf;

                c_length = c_capacity = 0;
            }
        }

    private:

        /*
         * Variable: buf
         * This stores the contents. Its size can be
         * retrieved using <capacity>.
         *
         * Allocated as uchar*, so ctors / dtors are
         * managed manually.
         *
         * Private level of access.
         */
        T *buf;

        /*
         * Variable: c_length
         * Stores the current vector length ("how many
         * items are stored in it").
         *
         * Private level of access.
         */
        size_t c_length;

        /*
         * Variable: c_capacity
         * Stores the current vector capacity ("how many
         * items can be stored in it").
         *
         * Private level of access.
         */
        size_t c_capacity;
    };
} /* end namespace types */

#endif

/*
 * File: of_vector.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  vector class header.
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
        vector(): buf(NULL), length(0), capacity(0) {}

        /*
         * Constructor: vector
         * Constructs a vector from another vector.
         */
        vector(const vector& v): buf(NULL), length(0), capacity(0)
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
            uchar *tmp = new uchar[sz * sizeof(T)];
            length = capacity = sz;

            for (size_t i = 0; i < sz; sz++)
                tmp[i] = v;

            buf = (T*)tmp;
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
         */
        vector& operator=(const vector& v)
        {
            if (*this == v) return *this;
        
            delete[] (uchar*)buf;

            length   = v.length;
            capacity = v.capacity;

            uchar *tmp = new uchar[capacity * sizeof(T)];
            memcpy(tmp, v.buf, length * sizeof(T));

            buf = (T*)tmp;

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
         * Returns a pointer to the buffer offset by its length.
         */
        T *last() { return buf + length; }

        /*
         * Function: last
         * Returns a const pointer to the buffer offset by its length.
         */
        const T *last() const { return buf + length; }

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
        void resize(size_t sz, T c = T())
        {
            size_t len = length;

            reserve (sz);
            length = sz;

            for (;  len < length; len++)
                buf[len] = c;
        }

        /*
         * Function: is_empty
         * Returns true if the vector is empty, false otherwise.
         */
        bool is_empty() { return (length == 0); }

        /*
         * Function: reserve
         * Reserves the size given by the argument. If that is
         * smaller(or equal) than current capacity, this will
         * do nothing. If it's bigger, the buffer will be
         * reallocated.
         */
        void reserve(size_t sz)
        {
            size_t old_cap = capacity;

            if (!capacity)
                 capacity = max(MIN_SIZE, sz);
            else
                while (capacity < sz)
                       capacity *= 2;

            if (capacity <= old_cap) return;

            uchar *tmp = new uchar[capacity * sizeof(T)];
            if (old_cap > 0)
            {
                memcpy(tmp, buf, old_cap * sizeof(T));
                delete[] (uchar*)buf;
            }
            buf = (T*)tmp;
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
         * Function: push
         * Appends a given value to the end of the vector.
         * If the current capacity is not big enough to hold
         * the future contents, it'll be resized.
         *
         * This returns a reference to the newly added element.
         */
        T& push(const T& data = T())
        {
            if(length >= capacity)
                reserve (capacity + 1);

            new  (&buf[length]) T(data);
            return buf[length++];
        }

        /*
         * Function: pop
         * Pops a last value out of the vector
         * and returns a reference to it.
         */
        T& pop() { return buf[--length]; }

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
        void sort(U f, size_t idx = 0, size_t len = -1)
        {
            quicksort(&buf[idx], (len < 0) ? (length - idx) : len, f);
        }

        /*
         * Function: clear
         * Clears the vector contents. Deletes the buffer
         * and sets the length and capacity to 0.
         */
        void clear()
        {
            if (capacity > 0)
            {
                delete[] (uchar*)buf;
                length = capacity = 0;
            }
        }

        /*
         * Variable: buf
         * This stores the contents. Its size can be
         * retrieved using <capacity>.
         */
        T *buf;

        /*
         * Variable: length
         * Stores the current vector length ("how many
         * items are stored in it").
         */
        size_t length;

        /*
         * Variable: capacity
         * Stores the current vector capacity ("how many
         * items can be stored in it").
         */
        size_t capacity;
    };
} /* end namespace types */

#endif

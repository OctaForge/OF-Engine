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
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_VECTOR_H
#define OF_VECTOR_H

#include "of_utils.h"
#include "of_algorithm.h"

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
            buf = new T[sz];
            length = capacity = sz;

            for (size_t sz = 0; sz < length; sz++)
                buf[sz] = v;
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
        
            delete[] buf;

            length   = v.length;
            capacity = v.capacity;

            buf = new T[capacity];

            for (size_t sz = 0; sz < length; sz++)
                buf[sz] = v.buf[sz];

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

            for (size_t i = len; i < length; sz++)
                buf[i] = c;
        }

        /*
         * Function: is_empty
         * Returns true if the vector is empty, false otherwise.
         */
        bool is_empty() { return (length == 0); }

        /*
         * Function: reserve
         * Reserves the size given by the argument. If that is
         * smaller than current capacity, this will do nothing.
         * If it's bigger, the buffer will be reallocated.
         */
        void reserve(size_t sz)
        {
            if (!buf)
            {
                length   = 0;
                capacity = 0;
            }

            if (sz <= capacity)
                return;

            T *tmp = new T[sz];

            algorithm::copy(buf, buf + length, tmp);
            capacity = sz;

            delete[] buf;
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
         * Function: push
         * Appends a given value to the end of the vector.
         * If the current capacity is not big enough to hold
         * the future contents, it is resized by 5.
         */
        void push(const T& data)
        {
            if (length >= capacity)
                reserve(capacity + 5);

            buf[length++] = data;
        }

        /*
         * Function: pop
         * Pops a last value out of the vector
         * and returns a reference to it.
         */
        T& pop() { return buf[--length]; }

        /*
         * Function: clear
         * Clears the vector contents. Deletes the buffer
         * and sets the length and capacity to 0.
         */
        void clear()
        {
            if (capacity > 0)
            {
                delete[] buf;
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

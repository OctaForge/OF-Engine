/*
 * File: of_list.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  List class header.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_LIST_H
#define OF_LIST_H

#include "of_utils.h"

/*
 * Package: types
 * This namespace features some types used in OctaForge.
 * This part exactly defines list.
 */
namespace types
{
    /*
     * Class: list
     * A "list" class. It represents a doubly linked list with
     * links to first and last node, so you can insert and delete
     * from both the beginning and the end. That means you can
     * use this as a double-ended queue (deque).
     *
     * Also stores <length> and you can iterate it from all
     * directions.
     *
     * (start code)
     *     typedef types::list<int> lst;
     *
     *     lst foo;
     *     foo.push_back(5);
     *     foo.push_back(10);
     *
     *     foo.push_front(15);
     *     foo.push_front(20);
     *
     *     // prints 20 15 5 10
     *     for (const lst::node *n = foo.first(); n; n = n->next())
     *         printf("%i\n", **n);
     *
     *     // prints 10 5 15 20
     *     for (const lst::node *n = foo.last(); n; n = n->prev())
     *         printf("%i\n", n->get());
     *
     *     foo.pop_back ();
     *     foo.pop_front();
     *
     *     foo->clear();
     * (end)
     */
    template<typename T> struct list
    {
        /*
         * Variable: node
         * The list node class. Provides iteration facilities
         * (methods prev, next returning pointer to either
         * previous or next node, also const versions)
         * and getters (dereference operator and a get
         * method, both also with const versions).
         */
        struct node
        {
            node(): n_prev(NULL), n_next(NULL) {}

            node(const T& data, node *prev, node *next):
                data(data), n_prev(prev), n_next(next) {}

                  node *prev()       { return n_prev; }
            const node *prev() const { return n_prev; }

                  node *next()       { return n_next; }
            const node *next() const { return n_next; }

                  T& operator*()       { return data; }
            const T& operator*() const { return data; }

                  T& get()       { return data; }
            const T& get() const { return data; }

        protected:

            T data;

            node *n_prev;
            node *n_next;

            friend struct list;
        };

        /*
         * Constructor: list
         * An empty list constructor.
         */
        list(): n_first(NULL), n_last(NULL), c_length(0) {}

        /*
         * Destructor: list
         * Calls <pop_back> until the length is 0.
         */
        ~list()
        {
            while (c_length > 0) pop_back();
        }

        /*
         * Function: first
         * Returns a pointer to the first node.
         */
        node *first() { return n_first; }

        /*
         * Function: first
         * Returns a const pointer to the first node.
         */
        const node *first() const { return n_first; }

        /*
         * Function: last
         * Returns a pointer to the last node.
         */
        node *last() { return n_last; }

        /*
         * Function: last
         * Returns a const pointer to the last node.
         */
        const node *last() const { return n_last; }

        /*
         * Function: length
         * Returns the current list length.
         */
        size_t length() const { return c_length; }

        /*
         * Function: is_empty
         * Returns true if the list contains no nodes,
         * and false otherwise.
         */
        bool is_empty() const { return (c_length == 0); }

        /*
         * Function: push_back
         * Pushes the given data to the end of the list.
         * Returns a reference to the data.
         */
        T& push_back(const T& data)
        {
            node *n = new node(data, n_last, NULL);

            if (!n_last) n_first = n;
            else n_last-> n_next = n;

            n_last = n;
            c_length++;
        }

        /*
         * Function: push_front
         * Pushes the given data to the beginning of the list.
         * Returns a reference to the data.
         */
        T& push_front(const T& data)
        {
            node *n = new node(data, NULL, n_first);

            if (!n_first) n_last = n;
            else n_first->n_prev = n;

            n_first = n;
            c_length++;
        }

        /*
         * Function: pop_back
         * Pops out the node at the end. Returns a reference
         * to the data, deletes the node (so it doesn't leak).
         */
        T& pop_back()
        {
            node *n =    n_last;
            n_last  = n->n_prev;

            if (!n_last) n_first = NULL;
            else n_last-> n_next = NULL;

            T& ret = n->data;
            delete n;
            c_length--;

            return ret;
        }

        /*
         * Function: pop_front
         * Pops out the node at the beginning. Returns a reference
         * to the data, deletes the node (so it doesn't leak).
         */
        T& pop_front()
        {
            node *n =   n_first;
            n_first = n->n_next;

            if (!n_first) n_last = NULL;
            else n_first->n_prev = NULL;

            T& ret = n->data;
            delete n;
            c_length--;

            return ret;
        }

        /*
         * Function: clear
         * Calls <pop_back> until the length is 0.
         */
        void clear()
        {
            while (c_length > 0) pop_back();
        }

    protected:

        /*
         * Variable: n_first
         * A pointer to the first node of the list.
         *
         * Protected level of access.
         */
        node *n_first;

        /*
         * Variable: n_first
         * A pointer to the last node of the list.
         *
         * Protected level of access.
         */
        node *n_last;

        /*
         * Variable: c_length
         * Stores the list length (the number of nodes).
         *
         * Protected level of access.
         */
        size_t c_length;
    };
} /* end namespace types */

#endif

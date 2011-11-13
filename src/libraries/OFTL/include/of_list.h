/* File: of_list.h
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
#include "of_iterator.h"

/* Package: types
 * A namespace containing various container types.
 */
namespace types
{
    template<typename T> struct List_Node
    {
        List_Node(): p_prev(NULL), p_next(NULL) {}
        List_Node(const T& data, List_Node *prev, List_Node *next):
            p_data(data), p_prev(prev), p_next(next) {}

    private:

        T p_data;

        List_Node *p_prev;
        List_Node *p_next;

        template<typename U> friend struct List_Iterator;
        template<typename U> friend struct List_Const_Iterator;
        template<typename U> friend struct List;
    };

    /* Struct: List_Iterator
     * An iterator for the linked list. It's a bidirectional iterator,
     * you can only go two directions and without offsets.
     */
    template<typename T> struct List_Iterator
    {
        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: val_t */
        typedef T val_t;
        /* Typedef: ptr_t */
        typedef T* ptr_t;
        /* Typedef: ref_t */
        typedef T& ref_t;

        /* Constructor: List_Iterator
         * Constructs an empty iterator.
         */
        List_Iterator(): p_nd(NULL) {}

        /* Constructor: List_Iterator
         * Constructs an iterator from a given <List_Node>.
         */
        List_Iterator(List_Node<T> *nd): p_nd(nd) {}

        /* Constructor: List_Iterator
         * Constructs an iterator from another iterator.
         */
        List_Iterator(const List_Iterator& it): p_nd(it.p_nd) {}

        /* Operator: *
         * Dereferencing list iterator returns
         * the current node data.
         */
        ref_t operator*() const { return p_nd->p_data; }

        /* Operator: ->
         * Pointer-like iterator access.
         */
        ptr_t operator->() const { return &p_nd->p_data; }

        /* Operator: ++
         * Moves on to the next node, prefix version.
         */
        List_Iterator& operator++()
        {
            p_nd = p_nd->p_next;
            return *this;
        }

        /* Operator: ++
         * Moves on to the next node and returns an iterator to the current
         * node (before incrementing). Postfix version.
         */
        List_Iterator operator++(int)
        {
            List_Iterator tmp = *this;
            p_nd = p_nd->p_next;
            return tmp;
        }

        /* Operator: --
         * Prefix version, see <++>.
         */
        List_Iterator& operator--()
        {
            p_nd = p_nd->p_prev;
            return *this;
        }

        /* Operator: --
         * Postfix version, see <++>.
         */
        List_Iterator operator--(int)
        {
            List_Iterator tmp = *this;
            p_nd = p_nd->p_prev;
            return tmp;
        }

        /* Operator: == */
        template<typename U>
        friend bool operator==(
            const List_Iterator& a, const List_Iterator<U>& b
        )
        { return a.p_nd == b.p_nd; }

        /* Operator: != */
        template<typename U>
        friend bool operator!=(
            const List_Iterator& a, const List_Iterator<U>& b
        )
        { return a.p_nd != b.p_nd; }

    protected:

        List_Node<T> *p_nd;

        template<typename U> friend struct List_Iterator;
        template<typename U> friend struct List_Const_Iterator;
    };

    /* Struct: List_Const_Iterator
     * Const version of <List_Iterator>. Inherits from <List_Iterator>.
     * Besides its own typedefs, it provides a constructor allowing to
     * create it from standard <List_Iterator> and overloads for * and
     * -> operators.
     */
    template<typename T> struct List_Const_Iterator: List_Iterator<T>
    {
        typedef List_Iterator<T> base;

        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: ptr_t */
        typedef const T* ptr_t;
        /* Typedef: ref_t */
        typedef const T& ref_t;
        /* Typedef: val_t */
        typedef T val_t;

        /* Constructor: List_Const_Iterator
         * Constructs a list const iterator from <base>.
         */
        List_Const_Iterator(const base& it) { base::p_nd = it.p_nd; }

        /* Operator: *
         * Dereferencing list iterator returns
         * the current node data.
         */
        ref_t operator*() const { return base::p_nd->p_data; }

        /* Operator: ->
         * Pointer-like iterator access.
         */
        ptr_t operator->() const { return &base::p_nd->p_data; }
    };

    /* Struct: List
     * A "list" class. It represents a doubly linked list with links to first
     * and last node, so you can insert and delete from both the beginning and
     * the end. That means you can use this as a double-ended queue (deque).
     *
     * Also stores <length> and you can iterate it from all directions.
     *
     * (start code)
     *     typedef types::List<int> lst;
     *
     *     lst foo;
     *     foo.push_back(5);
     *     foo.push_back(10);
     *
     *     foo.push_front(15);
     *     foo.push_front(20);
     *
     *     // prints 20 15 5 10
     *     for (lst::cit it = foo.begin(); it != foo.end(); ++it)
     *         printf("%i\n", *n);
     *
     *     // prints 10 5 15 20
     *     for (lst::crit it = foo.rbegin(); it != foo.rend(); ++it)
     *         printf("%i\n", *n);
     *
     *     foo.pop_back ();
     *     foo.pop_front();
     *
     *     foo.clear();
     * (end)
     */
    template<typename T> struct List
    {
        typedef List_Node<T> node;

        /* Typedef: it
         * An iterator typedef for standard, non-const iterator.
         */
        typedef List_Iterator<T> it;

        /* Typedef: cit
         * An iterator typedef for const iterator.
         */
        typedef List_Const_Iterator<T> cit;

        /* Typedef: rit
         * Reverse iterator typedef, a <Reverse> < <it> >.
         */
        typedef iterators::Reverse_Iterator<it> rit;

        /* Typedef: crit
         * Const reverse iterator typedef, a <Reverse> < <cit> >.
         */
        typedef iterators::Reverse_Iterator<cit> crit;

        /* Constructor: list
         * An empty list constructor.
         */
        List(): p_first(NULL), p_last(new node), p_length(0) {}

        /* Destructor: list
         * Calls <pop_back> until the length is 0.
         */
        ~List()
        {
            while (p_length > 0) pop_back();
            delete p_last;
        }

        /* Function: begin
         * Returns an iterator to the first node.
         */
        it begin() { return it(p_first); }

        /* Function: begin
         * Returns a const iterator to the first node.
         */
        cit begin() const { return cit(p_first); }

        /* Function: rbegin
         * Returns a <reverse> iterator to <end>.
         */
        rit rbegin() { return rit(end()); }

        /* Function: rbegin
         * Returns a const <reverse> iterator to <end>.
         */
        crit rbegin() const { return crit(end()); }

        /* Function: end
         * Returns an iterator to the last node.
         */
        it end() { return it(p_last); }

        /* Function: end
         * Returns a const iterator to the last node.
         */
        cit end() const { return cit(p_last); }

        /* Function: rend
         * Returns a <reverse> iterator to <begin>.
         */
        rit rend() { return rit(begin()); }

        /* Function: rend
         * Returns a const <reverse> iterator to <begin>.
         */
        crit rend() const { return crit(begin()); }

        /* Function: length
         * Returns the current list length.
         */
        size_t length() const { return p_length; }

        /* Function: is_empty
         * Returns true if the list contains no nodes,
         * and false otherwise.
         */
        bool is_empty() const { return (p_length == 0); }

        /* Function: push_back
         * Pushes the given data to the end of the list. Returns a
         * reference to the data.
         */
        T& push_back(const T& data)
        {
            node *n = new node(data, p_last->p_prev, p_last);

            if (!p_last->p_prev) p_first = n;
            else p_last->p_prev->p_next  = n;

            p_last->p_prev = n;
            ++p_length;

            return n->p_data;
        }

        /* Function: push_front
         * Pushes the given data to the beginning of the list. Returns
         * a reference to the data.
         */
        T& push_front(const T& data)
        {
            node *n = new node(data, NULL, p_first);

            if (!p_first) p_last->p_prev = n;
            else p_first->p_prev = n;

            p_first = n;
            ++p_length;

            return n->p_data;
        }

        /* Function: pop_back
         * Pops out the node at the end.
         */
        void pop_back()
        {
            node *n = p_last->p_prev;
            if  (!n) return;

            p_last->p_prev = n->p_prev;

            if (p_last->p_prev)
                p_last->p_prev->p_next = n->p_next;

            if (p_length == 1)
                p_first = NULL;

            if (p_last->p_prev && !p_last->p_prev->p_prev)
            {
                p_first = p_last->p_prev;
                p_first ->p_prev = NULL;
            }

            delete n;
            --p_length;
        }

        /* Function: pop_front
         * Pops out the node at the beginning.
         */
        void pop_front()
        {
            node *n = p_first;
            if  (!n) return;

            if (p_length == 1)
                p_first = NULL;
            else
            {
                p_first = n->p_next;
                p_first->p_prev = NULL;
            }

            delete n;
            --p_length;
        }

        /* Function: clear
         * Calls <pop_back> until the length is 0.
         */
        void clear()
        {
            while (p_length > 0) pop_back();
        }

    protected:

        node *p_first;
        node *p_last;

        size_t p_length;
    };
} /* end namespace types */

#endif

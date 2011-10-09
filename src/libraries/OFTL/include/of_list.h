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
#include "of_iterator.h"

/*
 * Package: types
 * A namespace containing various container types.
 */
namespace types
{
    /*
     * Struct: list_node
     * The list node class. Holds the data and the links (prev, next).
     */
    template<typename T> struct list_node
    {
        /*
         * Constructor: list_node
         * An empty constructor.
         */
        list_node(): prev(NULL), next(NULL) {}

        /*
         * Constructor: list_node
         * Constructs a list node from data and prev, next nodes.
         */
        list_node(const T& data, list_node *prev, list_node *next):
            data(data), prev(prev), next(next) {}

    private:
        /*
         * Variable: data
         * Private access.
         */
        T data;

        /*
         * Variable: prev
         * Private access.
         */
        list_node *prev;

        /*
         * Variable: next
         * Private access.
         */
        list_node *next;

        /*
         * Property: list_iterator
         * <list_iterator> is a friend of this class.
         */
        template<typename U> friend struct list_iterator;

        /*
         * Property: list_const_iterator
         * <list_const_iterator> is a friend of this class.
         */
        template<typename U> friend struct list_const_iterator;

        /*
         * Property: list
         * <list> is a friend of this class.
         */
        template<typename U> friend struct list;
    };

    /*
     * Struct: list_iterator
     * An iterator for the linked list. It's a bidirectional
     * iterator, you can only go two directions and without
     * offsets.
     */
    template<typename T> struct list_iterator
    {
        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: val_t */
        typedef T val_t;
        /* Typedef: ptr_t */
        typedef T* ptr_t;
        /* Typedef: ref_t */
        typedef T& ref_t;

        /*
         * Constructor: list_iterator
         * Constructs an empty iterator.
         */
        list_iterator(): nd(NULL) {}

        /*
         * Constructor: list_iterator
         * Constructs an iterator from a given <list_node>.
         */
        list_iterator(list_node<T> *nd): nd(nd) {}

        /*
         * Constructor: list_iterator
         * Constructs an iterator from another iterator.
         */
        list_iterator(const list_iterator& it): nd(it.nd) {}

        /*
         * Function: equals
         * Returns true if given list iterator equals this one
         * (that is, if their nodes equal).
         */
        bool equals(const list_iterator& it) const { return (it.nd == nd); }

        /*
         * Operator: *
         * Dereferencing list iterator returns
         * the current node data.
         */
        ref_t operator*() const { return nd->data; }

        /*
         * Operator: ->
         * Pointer-like iterator access.
         */
        ptr_t operator->() const { return &nd->data; }

        /*
         * Operator: ++
         * Moves on to the next node, prefix version.
         */
        list_iterator& operator++()
        {
            nd = nd->next;
            return *this;
        }

        /*
         * Operator: ++
         * Moves on to the next node and returns
         * an iterator to the current node (before
         * incrementing). Postfix version.
         */
        list_iterator& operator++(int)
        {
            list_iterator tmp = *this;
            nd = nd->next;
            return tmp;
        }

        /*
         * Operator: --
         * Prefix version, see <++>.
         */
        list_iterator& operator--()
        {
            nd = nd->prev;
            return *this;
        }

        /*
         * Operator: --
         * Postfix version, see <++>.
         */
        list_iterator& operator--(int)
        {
            list_iterator tmp = *this;
            nd = nd->prev;
            return tmp;
        }

    protected:

        /*
         * Variable: nd
         * The current list node the iterator
         * is at. Protected level of access.
         */
        list_node<T> *nd;

        /* Property: friend list_iterator */
        template<typename U> friend struct list_iterator;

        /* Property: friend list_const_iterator */
        template<typename U> friend struct list_const_iterator;
    };

    /*
     * Struct: list_const_iterator
     * Const version of <list_iterator>. Inherits from
     * <list_iterator>. Besides its own typedefs, it provides
     * a constructor allowing to create it from standard
     * <list_iterator>, an "equals" function for comparison
     * with another const iterator and overloads for * and
     * -> operators.
     */
    template<typename T> struct list_const_iterator: list_iterator<T>
    {
        /* Typedef: base */
        typedef list_iterator<T> base;

        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: ptr_t */
        typedef const T* ptr_t;
        /* Typedef: ref_t */
        typedef const T& ref_t;
        /* Typedef: val_t */
        typedef T val_t;

        /*
         * Constructor: list_const_iterator
         * Constructs a list const iterator from <base>.
         */
        list_const_iterator(const base& it) { base::nd = it.nd; }

        /*
         * Function: equals
         * Returns true if given const list iterator equals the
         * current one (that is, if their nodes equal).
         */
        bool equals(const list_const_iterator& it) const
        { return (it.nd == base::nd); }

        /*
         * Operator: *
         * Dereferencing list iterator returns
         * the current node data.
         */
        ref_t operator*() const { return base::nd->data; }

        /*
         * Operator: ->
         * Pointer-like iterator access.
         */
        ptr_t operator->() const { return &base::nd->data; }
    };

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
     *     for (lst::cit it = foo.begin(); it != foo.end(); ++it)
     *         printf("%i\n", **n);
     *
     *     // prints 10 5 15 20
     *     for (lst::crit it = foo.rbegin(); it != foo.rend(); ++it)
     *         printf("%i\n", n->get());
     *
     *     foo.pop_back ();
     *     foo.pop_front();
     *
     *     foo.clear();
     * (end)
     */
    template<typename T> struct list
    {
        /* Typedef: node */
        typedef list_node<T> node;

        /*
         * Typedef: it
         * An iterator typedef for standard, non-const iterator.
         */
        typedef list_iterator<T> it;

        /*
         * Typedef: cit
         * An iterator typedef for const iterator.
         */
        typedef list_const_iterator<T> cit;

        /*
         * Typedef: rit
         * Reverse iterator typedef, a <reverse> < <it> >.
         */
        typedef iterators::reverse<it> rit;

        /*
         * Typedef: crit
         * Const reverse iterator typedef, a <reverse> < <cit> >.
         */
        typedef iterators::reverse<cit> crit;

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
         * Function: begin
         * Returns an iterator to the first node.
         */
        it begin() { return it(n_first); }

        /*
         * Function: begin
         * Returns a const iterator to the first node.
         */
        cit begin() const { return cit(n_first); }

        /*
         * Function: rbegin
         * Returns a <reverse> iterator to <end>.
         */
        rit rbegin() { return rit(end()); }

        /*
         * Function: rbegin
         * Returns a const <reverse> iterator to <end>.
         */
        crit rbegin() const { return crit(end()); }

        /*
         * Function: end
         * Returns an iterator to the last node.
         */
        it end() { return it(n_last); }

        /*
         * Function: end
         * Returns a const iterator to the last node.
         */
        cit end() const { return cit(n_last); }

        /*
         * Function: rend
         * Returns a <reverse> iterator to <begin>.
         */
        rit rend() { return rit(begin()); }

        /*
         * Function: rend
         * Returns a const <reverse> iterator to <begin>.
         */
        crit rend() const { return crit(begin()); }

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
            else n_last->   next = n;

            n_last = n;
            c_length++;

            return n->data;
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
            else n_first->  prev = n;

            n_first = n;
            c_length++;

            return n->data;
        }

        /*
         * Function: pop_back
         * Pops out the node at the end.
         */
        void pop_back()
        {
            node *n =    n_last;
            n_last  = n->prev;

            if (!n_last) n_first = NULL;
            else n_last->   next = NULL;

            delete n;
            c_length--;
        }

        /*
         * Function: pop_front
         * Pops out the node at the beginning.
         */
        void pop_front()
        {
            node *n =   n_first;
            n_first = n->next;

            if (!n_first) n_last = NULL;
            else n_first->  prev = NULL;

            delete n;
            c_length--;
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

    /*
     * Operator: ==
     * Defines == comparison behavior for list iterators.
     * Global operator, not part of the class. Can be used
     * for any two list iterators, even of different types.
     */
    template<typename T, typename U>
    inline bool operator==(
        const list_iterator<T>& a, const list_iterator<U>& b
    )
    { return a.equals(b); }

    /* Operator: != */
    template<typename T, typename U>
    inline bool operator!=(
        const list_iterator<T>& a, const list_iterator<U>& b
    )
    { return !a.equals(b); }

    /* Operator: == */
    template<typename T, typename U>
    inline bool operator==(
        const list_const_iterator<T>& a, const list_const_iterator<U>& b
    )
    { return a.equals(b); }

    /* Operator: != */
    template<typename T, typename U>
    inline bool operator!=(
        const list_const_iterator<T>& a, const list_const_iterator<U>& b
    )
    { return !a.equals(b); }

    /* Operator: == */
    template<typename T, typename U>
    inline bool operator==(
        const list_iterator<T>& a, const list_const_iterator<U>& b
    )
    { return a.equals(b); }

    /* Operator: != */
    template<typename T, typename U>
    inline bool operator!=(
        const list_iterator<T>& a, const list_const_iterator<U>& b
    )
    { return !a.equals(b); }

    /* Operator: == */
    template<typename T, typename U>
    inline bool operator==(
        const list_const_iterator<T>& a, const list_iterator<U>& b
    )
    { return a.equals(b); }

    /* Operator: != */
    template<typename T, typename U>
    inline bool operator!=(
        const list_const_iterator<T>& a, const list_iterator<U>& b
    )
    { return !a.equals(b); }
} /* end namespace types */

#endif

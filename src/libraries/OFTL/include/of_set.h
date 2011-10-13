/* File: of_set.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Set class header.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_SET_H
#define OF_SET_H

#include "of_utils.h"
#include "of_algorithm.h"
#include "of_iterator.h"

/* Package: types
 * A namespace containing various container types.
 */
namespace types
{
    /* Struct: set_node
     * A node structure for the tree. Has two constructors,
     * one of them takes no arguments (level 0, left and right
     * nodes as "this") and the other takes data, a node
     * the left and right links will point at (initializes
     * with level 1 and thus it'll be a leaf node) and a parent
     * node (see below).
     *
     * The "parent" link is used on iteration to "go back".
     * Default constructor initializes it to "this", the other
     * one has it passed.
     *
     * Protected members are the data, current node level and
     * the left and right links and the parent link. Besides
     * that, the structure has friends set to <map>, <set>,
     * <set_iterator> and <set_const_iterator>.
     */
    template<typename T> struct set_node
    {
        /* Constructor: set_node
         * A default constructor. The level is set to 0 and all
         * links to "this".
         */
        set_node():
            level(0), parent(this), left(this), right(this) {}

        /* Constructor: set_node
         * Passes data, parent node and left/right nodes (the same).
         * The <level> member is initialized to 1 (the node begins
         * life as leaf node).
         */
        set_node(const T& data, set_node *nd, set_node *parent):
            data(data), level(1), parent(parent), left(nd), right(nd) {}

    protected:

        T data;
        size_t level;

        set_node *parent;
        set_node *left;
        set_node *right;

        template<typename U> friend struct set_iterator;
        template<typename U> friend struct set_const_iterator;
        template<typename U> friend struct set;

        template<typename U, typename V> friend struct map;
    };

    /* Struct: set_iterator
     * An iterator for set (and map). It's a bidirectional
     * iterator, you can only go two directions and without
     * offsets.
     */
    template<typename T> struct set_iterator
    {
        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: val_t */
        typedef T val_t;
        /* Typedef: ptr_t */
        typedef T* ptr_t;
        /* Typedef: ref_t */
        typedef T& ref_t;

        /* Constructor: set_iterator
         * Constructs an empty iterator.
         */
        set_iterator(): nd(NULL) {}

        /* Constructor: set_iterator
         * Constructs an iterator from <set_node>.
         */
        set_iterator(set_node<T> *nd): nd(nd) {}

        /* Constructor: set_iterator
         * Constructs an iterator from another iterator.
         */
        set_iterator(const set_iterator& it): nd(it.nd) {}

        /* Function: equals
         * Returns true if given set iterator equals this one
         * (that is, if their nodes equal).
         */
        bool equals(const set_iterator& it) const { return (it.nd == nd); }

        /* Operator: *
         * Dereferencing set iterator returns
         * the current node data.
         */
        ref_t operator*() const { return nd->data; }

        /* Operator: ->
         * Pointer-like iterator access.
         */
        ptr_t operator->() const { return &nd->data; }

        /* Operator: ++
         * Moves on to the next node, prefix version.
         */
        set_iterator& operator++()
        {
            if (nd->right->level != 0)
            {
                nd = nd->right;
                while (nd->left->level != 0)
                    nd = nd->left;
            }
            else
            {
                set_node<T> *n = nd->parent;
                while (nd == n->right)
                {
                    nd = n;
                    n = n->parent;
                }
                if (nd->right != n)
                    nd = n;
            }
            return *this;
        }

        /* Operator: ++
         * Moves on to the next node and returns
         * an iterator to the current node (before
         * incrementing). Postfix version.
         */
        set_iterator& operator++(int)
        {
            set_iterator tmp = *this;
            operator++();
            return tmp;
        }

        /* Operator: --
         * Prefix version, see <++>.
         */
        set_iterator& operator--()
        {
            if (nd->left->level != 0)
            {
                nd = nd->left;
                while (nd->right->level != 0)
                    nd = nd->right;
            }
            else
            {
                set_node<T> *n = nd->parent;
                while (nd->level != 0 && nd == n->left)
                {
                    nd = n;
                    n = n->parent;
                }
                if (nd->left != n)
                    nd = n;
            }
            return *this;
        }

        /* Operator: --
         * Postfix version, see <++>.
         */
        set_iterator& operator--(int)
        {
            set_iterator tmp = *this;
            operator--();
            return tmp;
        }

    protected:

        set_node<T> *nd;

        template<typename U> friend struct set_iterator;
        template<typename U> friend struct set_const_iterator;
    };

    /* Struct: set_const_iterator
     * Const version of <set_iterator>. Inherits from
     * <set_iterator>. Besides its own typedefs, it provides
     * a constructor allowing to create it from standard
     * <set_iterator>, an "equals" function for comparison
     * with another const iterator and overloads for * and
     * -> operators.
     */
    template<typename T> struct set_const_iterator: set_iterator<T>
    {
        /* Typedef: base */
        typedef set_iterator<T> base;

        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: ptr_t */
        typedef const T* ptr_t;
        /* Typedef: ref_t */
        typedef const T& ref_t;
        /* Typedef: val_t */
        typedef T val_t;

        /* Constructor: set_const_iterator
         * Constructs a set const iterator from <base>.
         */
        set_const_iterator(const base& it) { base::nd = it.nd; }

        /* Function: equals
         * Returns true if given const set iterator equals the
         * current one (that is, if their nodes equal).
         */
        bool equals(const set_const_iterator& it) const
        { return (it.nd == base::nd); }

        /* Operator: *
         * Dereferencing set iterator returns
         * the current node data.
         */
        ref_t operator*() const { return base::nd->data; }

        /* Operator: ->
         * Pointer-like iterator access.
         */
        ptr_t operator->() const { return &base::nd->data; }
    };

    /* Class: set
     * An efficient associative container implementation
     * using AA tree (an enhancement to red-black tree,
     * see <http://en.wikipedia.org/wiki/AA_tree>).
     *
     * It can be used for efficient key-value associations
     * that are ordered, while remaining very efficient in
     * insertion and search.
     *
     * Anything can be used as either key or value, ranging
     * from POD types through objects to pointers.
     *
     * You should, however, never store a pointer inside the
     * container unless you manage it elsewhere to prevent
     * memory leaks (you can however store it in reference
     * counted container, <shared_ptr>).
     *
     * This structure represents a "set", where a key value
     * is the same as data value. It serves as a base for
     * actual map, where key and data are different. It
     * simply inherites and makes use of <pair>.
     *
     * (start code)
     *     typedef types::set<int> myset;
     *     myset test;
     *     // these two ways are equivalent in function, the
     *     // second one is better if the element doesn't exist.
     *     test[5] = 5;
     *     test.insert(5);
     * 
     *     // searching
     *     printf("%i\n", test[5]);
     *     // this will not fail - it'll insert an empty value,
     *     // so it'll print just 0 (default value for an int)
     *     printf("%i\n", test[10]);
     *
     *     // iteration
     *     for (myset::cit it = test.begin(); it != test.end(); ++it)
     *         printf("%i\n", *it);
     *
     *     // reverse iteration
     *     for (myset::crit it = test.rbegin(); it != test.rend(); ++it)
     *         printf("%i\n", *it);
     *
     *     // erasing, will delete the node
     *     test.erase(5);
     *
     *     // same as erase, but will return the node instead
     *     // of deletion, letting the user to manage it
     *     myset::node *n = test.pop(10);
     *
     *     // retrieving the tree length
     *     printf("%i\n", test.length());
     *
     *     // will clear the node - also done
     *     // automatically in the destructor
     *     test.clear();
     * (end)
     */
    template<typename T> struct set
    {
        /* Typedef: node
         * Typedefs <set_node> <T> so it can
         * be used as "node".
         */
        typedef set_node<T> node;

        /* Typedef: it
         * An iterator typedef for standard, non-const iterator.
         */
        typedef set_iterator<T> it;

        /* Typedef: cit
         * An iterator typedef for const iterator.
         */
        typedef set_const_iterator<T> cit;

        /* Typedef: rit
         * Reverse iterator typedef, a <reverse> < <it> >.
         */
        typedef iterators::reverse<it> rit;

        /* Typedef: crit
         * Const reverse iterator typedef, a <reverse> < <cit> >.
         */
        typedef iterators::reverse<cit> crit;

        /* Constructor: set
         * Creates a new set with root <node> where root
         * is the same as nil (will change when something
         * gets inserted).
         */
        set(): root(new node), nil(NULL), c_length(0)
        {
            nil = root;
        }

        /* Destructor: set
         * Deletes a root node, all its sub-nodes and
         * a nil node. Done to not leak memory.
         */
        ~set()
        {
            destroy_node(root);
            delete nil;
        }

        /* Function: length
         * Returns the tree length (the amount of nodes
         * with actual data).
         */
        size_t length() const { return c_length; }

        /* Function: is_empty
         * Returns true if the set contains no nodes
         * (except root / nil) and false otherwise.
         */
        bool is_empty() const { return (c_length == 0); }

        /* Function: begin
         * Returns an iterator to the first node.
         */
        it begin()
        {
            node  *nd = root;
            while (nd != nil)
            {
                if (nd->left == nil) break;
                    nd = nd->left;
            }

            return it(nd);
        }

        /* Function: begin
         * Returns a const iterator to the first node.
         */
        cit begin() const
        {
            node  *nd = root;
            while (nd != nil)
            {
                if (nd->left == nil) break;
                    nd = nd->left;
            }

            return cit(nd);
        }

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
        it end()
        {
            node  *nd = root;
            while (nd != nil)
                nd = nd->right;

            return it(nd);
        }

        /* Function: end
         * Returns a const iterator to the last node.
         */
        cit end() const
        {
            node  *nd = root;
            while (nd != nil)
                nd = nd->right;

            return cit(nd);
        }

        /* Function: rend
         * Returns a <reverse> iterator to <begin>.
         */
        rit rend() { return rit(begin()); }

        /* Function: rend
         * Returns a const <reverse> iterator to <begin>.
         */
        crit rend() const { return crit(begin()); }

        /* Function: insert
         * Inserts a new node into the tree with data
         * member given by the arguments.
         *
         * You can also use the <[]> operator with assignment,
         * both ways are equivalent in function, this is however
         * better on non-existent keys because it doesn't have to
         * insert first and then assign, instead it creates with
         * the given data directly.
         */
        T& insert(const T& data)
        {
            return insert(root, data)->data;
        }

        /* Function: clear
         * Destroys the root node, all its sub-nodes and the nil
         * node, and re-initializes the tree with length 0.
         */
        void clear()
        {
            destroy_node(root);
            delete nil;

            root     = new node;
            nil      = root;
            c_length = 0;
        }

        /* Function: erase
         * Erases a node with a given key from the tree. Unlike
         * <pop>, it also deletes the node (and returns nothing).
         */
        void erase(const T& key) { delete erase(root, key); }

        /* Function: find
         * Returns an iterator to a node that belongs to a given key.
         * There is also a const version that returns a const
         * iterator (non-modifiable).
         */
        it find(const T& key) { return it(find(root, key)); }

        /* Function: find
         * Const version of <find>. The result cannot be modified.
         */
        cit find(const T& key) const { return cit(find(root, key)); }

        /* Operator: []
         * See <find>. This one is not const, so you can assign
         * the value. If you assign a non-existant key, it'll
         * get created first, because this has to return the
         * data, not a node (see <insert>).
         *
         * (start code)
         *     tree[value] = value;
         * (end)
         *
         * There is also a const version used for reading.
         */
        T& operator[](const T& key) { return find(root, key, true)->data; }

        /* Operator: []
         * Const version of <[]>. Used for reading only, because it
         * returns a const reference which is non-modifiable.
         *
         * (start code)
         *     printf("%s\n", tree[key]);
         * (end)
         */
        const T& operator[](const T& key) const { return find(key)->data; }

    protected:

        void destroy_node(node *nd)
        {
            if (nd == nil) return;
            destroy_node(nd->left);
            destroy_node(nd->right);
            delete nd;
        }

        /* Function: skew
         * See <http://en.wikipedia.org/wiki/AA_tree>.
         * The given argument is a reference to a node
         * (it modifies the node from inside).
         *
         * See also <split>, <insert> and <erase>.
         * This method has protected level of access.
         */
        void skew(node *&nd)
        {
            if (nd->level && nd->level == nd->left->level)
            {
                node *n   = nd->left;
                n->parent = nd->parent;

                nd->left = n->right;
                nd->left->parent = nd;

                n->right = nd;
                n->right->parent = n;

                nd = n;
            }
        }

        /* Function: split
         * See <http://en.wikipedia.org/wiki/AA_tree>.
         * The given argument is a reference to a node
         * (it modifies the node from inside).
         *
         * See also <skew>, <insert> and <erase>.
         * This method has protected level of access.
         */
        void split(node *&nd)
        {
            if (nd->level && nd->level == nd->right->right->level)
            {
                node *n   = nd->right;
                n->parent = nd->parent;

                nd->right = n->left;
                nd->right->parent = nd;

                n->left = nd;
                n->left->parent = n;

                nd = n;
                nd->level++;
            }
        }

        /* Function: insert
         * See <http://en.wikipedia.org/wiki/AA_tree>.
         * The first given argument is a reference to
         * a node (it modifies the node from inside).
         * The other argument is a const reference to
         * the value we're inserting.
         *
         * Returns the newly inserted node.
         *
         * See also <skew>, <split> and <erase>.
         * This method has protected level of access.
         */
        template<typename U>
        node *insert(node *&nd, const U& data, node *prev = NULL)
        {
            if (nd == nil)
            {
                if (!prev) prev = root;
                nd = new node(data, nil, prev);
                c_length++;
                return nd;
            }

            node *ret = NULL;

            int cmp = algorithm::compare(data, nd->data);
            if (cmp)
            {
                ret = insert(((cmp > 0)
                    ? nd->right
                    : nd->left
                ), data, nd);
                if (!ret) return NULL;
            }

            skew (nd);
            split(nd);

            return ret;
        }

        /* Function: erase
         * See <http://en.wikipedia.org/wiki/AA_tree>.
         * The first given argument is a reference to
         * a node (it modifies the node from inside).
         * The other argument is the key belonging
         * to the node we're erasing.
         *
         * Returns the erased node for later processing.
         *
         * See also <skew>, <split> and <insert>.
         * This method has protected level of access.
         */
        template<typename U>
        node *erase(node *&nd, const U& key)
        {
            if (nd == nil) return NULL;

            int cmp = algorithm::compare(key, nd->data);
            if (cmp == 0)
            {
                if (nd->left != nil && nd->right != nil)
                {
                    node  *heir = nd->left;
                    while (heir->right != nil)
                           heir = heir->right;

                    nd->data = heir->data;

                    return erase(nd->left, nd->data);
                }
                else
                {
                    node *ret = nd;
                    node *par = nd->parent;
                    nd = ((nd->left == nil)
                        ? nd->right
                        : nd->left
                    );
                    nd->parent = par;

                    c_length--;

                    return ret;
                }
            }
            else return erase(((cmp < 0)
                ? nd->left
                : nd->right
            ), key);

            return NULL;
        }

        /* Function: find
         * Returns a node the key given by the second argument
         * belongs to. The first argument is a root node, usually.
         *
         * Used by <[]> and the interface <find> (the one that
         * doesn't take a root node argument).
         *
         * This method has protected level of access.
         */
        node *find(node *nd, const T& key, bool do_insert = false)
        {
            if (nd == nil)
            {
                if (do_insert)
                    return insert(root, T());
                else
                    return nil;
            }

            int cmp = algorithm::compare(key, nd->data);
            if (cmp)
                return find(((cmp < 0)
                    ? nd->left
                    : nd->right
                ), key, do_insert);

            return nd;
        }

        node *root;
        node *nil;

    private:

        size_t c_length;
    };

    /* Operator: ==
     * Defines == comparison behavior for set iterators.
     * Global operator, not part of the class. Can be used
     * for any two set iterators, even of different types.
     */
    template<typename T, typename U>
    inline bool operator==(
        const set_iterator<T>& a, const set_iterator<U>& b
    )
    { return a.equals(b); }

    /* Operator: != */
    template<typename T, typename U>
    inline bool operator!=(
        const set_iterator<T>& a, const set_iterator<U>& b
    )
    { return !a.equals(b); }

    /* Operator: == */
    template<typename T, typename U>
    inline bool operator==(
        const set_const_iterator<T>& a, const set_const_iterator<U>& b
    )
    { return a.equals(b); }

    /* Operator: != */
    template<typename T, typename U>
    inline bool operator!=(
        const set_const_iterator<T>& a, const set_const_iterator<U>& b
    )
    { return !a.equals(b); }

    /* Operator: == */
    template<typename T, typename U>
    inline bool operator==(
        const set_iterator<T>& a, const set_const_iterator<U>& b
    )
    { return a.equals(b); }

    /* Operator: != */
    template<typename T, typename U>
    inline bool operator!=(
        const set_iterator<T>& a, const set_const_iterator<U>& b
    )
    { return !a.equals(b); }

    /* Operator: == */
    template<typename T, typename U>
    inline bool operator==(
        const set_const_iterator<T>& a, const set_iterator<U>& b
    )
    { return a.equals(b); }

    /* Operator: != */
    template<typename T, typename U>
    inline bool operator!=(
        const set_const_iterator<T>& a, const set_iterator<U>& b
    )
    { return !a.equals(b); }
} /* end namespace types */

#endif

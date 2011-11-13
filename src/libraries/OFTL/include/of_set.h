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
    template<typename T> struct Set_Node
    {
        Set_Node():
            p_level(0), p_parent(this), p_left(this), p_right(this) {}

        Set_Node(const T& data, Set_Node *nd, Set_Node *parent):
            p_data(data), p_level(1),
            p_parent(parent), p_left(nd), p_right(nd) {}

    protected:

        T p_data;
        size_t p_level;

        Set_Node *p_parent;
        Set_Node *p_left;
        Set_Node *p_right;

        template<typename U> friend struct Set_Iterator;
        template<typename U> friend struct Set_Const_Iterator;
        template<typename U> friend struct Set;

        template<typename U, typename V> friend struct Map;
    };

    /* Struct: Set_Iterator
     * An iterator for set (and map). It's a bidirectional iterator, you can
     * only go two directions and without offsets.
     */
    template<typename T> struct Set_Iterator
    {
        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: val_t */
        typedef T val_t;
        /* Typedef: ptr_t */
        typedef T* ptr_t;
        /* Typedef: ref_t */
        typedef T& ref_t;

        /* Constructor: Set_Iterator
         * Constructs an empty iterator.
         */
        Set_Iterator(): p_nd(NULL) {}

        /* Constructor: Set_Iterator
         * Constructs an iterator from <Set_Node>.
         */
        Set_Iterator(Set_Node<T> *nd): p_nd(nd) {}

        /* Constructor: Set_Iterator
         * Constructs an iterator from another iterator.
         */
        Set_Iterator(const Set_Iterator& it): p_nd(it.p_nd) {}

        /* Operator: *
         * Dereferencing set iterator returns the current node data.
         */
        ref_t operator*() const { return p_nd->p_data; }

        /* Operator: ->
         * Pointer-like iterator access.
         */
        ptr_t operator->() const { return &p_nd->p_data; }

        /* Operator: ++
         * Moves on to the next node, prefix version.
         */
        Set_Iterator& operator++()
        {
            if (p_nd->p_right->p_level != 0)
            {
                p_nd = p_nd->p_right;
                while (p_nd->p_left->p_level != 0)
                       p_nd = p_nd->p_left;
            }
            else
            {
                Set_Node<T> *n = p_nd->p_parent;
                while (p_nd == n->p_right)
                {
                    p_nd = n;
                    n = n->p_parent;
                }
                if (p_nd->p_right != n)
                    p_nd = n;
            }
            return *this;
        }

        /* Operator: ++
         * Moves on to the next node and returns an iterator to the
         * current node (before incrementing). Postfix version.
         */
        Set_Iterator operator++(int)
        {
            Set_Iterator tmp = *this;
            operator++();
            return tmp;
        }

        /* Operator: --
         * Prefix version, see <++>.
         */
        Set_Iterator& operator--()
        {
            if (p_nd->p_left->p_level != 0)
            {
                p_nd = p_nd->p_left;
                while (p_nd->p_right->p_level != 0)
                       p_nd = p_nd->p_right;
            }
            else
            {
                Set_Node<T> *n = p_nd->p_parent;
                while (p_nd->p_level != 0 && p_nd == n->p_left)
                {
                    p_nd = n;
                    n = n->p_parent;
                }
                if (p_nd->p_left != n)
                    p_nd = n;
            }
            return *this;
        }

        /* Operator: --
         * Postfix version, see <++>.
         */
        Set_Iterator operator--(int)
        {
            Set_Iterator tmp = *this;
            operator--();
            return tmp;
        }

        /* Operator: == */
        template<typename U>
        friend bool operator==(
            const Set_Iterator& a, const Set_Iterator<U>& b
        )
        { return a.p_nd == b.p_nd; }

        /* Operator: != */
        template<typename U>
        friend bool operator!=(
            const Set_Iterator& a, const Set_Iterator<U>& b
        )
        { return a.p_nd != b.p_nd; }

    protected:

        Set_Node<T> *p_nd;

        template<typename U> friend struct Set_Iterator;
        template<typename U> friend struct Set_Const_Iterator;
    };

    /* Struct: Set_Const_Iterator
     * Const version of <Set_Iterator>. Inherits from <Set_Iterator>.
     * Besides its own typedefs, it provides a constructor allowing
     * to create it from a standard <Set_Iterator> and overloads for
     * the * and -> operators.
     */
    template<typename T> struct Set_Const_Iterator: Set_Iterator<T>
    {
        typedef Set_Iterator<T> base;

        /* Typedef: diff_t */
        typedef ptrdiff_t diff_t;
        /* Typedef: ptr_t */
        typedef const T* ptr_t;
        /* Typedef: ref_t */
        typedef const T& ref_t;
        /* Typedef: val_t */
        typedef T val_t;

        /* Constructor: Set_Const_Iterator
         * Constructs a set const iterator from <Set_Iterator>.
         */
        Set_Const_Iterator(const base& it) { base::p_nd = it.p_nd; }

        /* Operator: *
         * Dereferencing set iterator returns the current node data.
         */
        ref_t operator*() const { return base::p_nd->p_data; }

        /* Operator: ->
         * Pointer-like iterator access.
         */
        ptr_t operator->() const { return &base::p_nd->p_data; }
    };

    /* Struct: set
     * An efficient associative container implementation using AA
     * tree (an enhancement to the red-black tree algorithm, see
     * <http://en.wikipedia.org/wiki/AA_tree>).
     *
     * It can be used for efficient key-value associations that are ordered,
     * while remaining very efficient in insertion and search.
     *
     * Anything can be used as either key or value, ranging from POD types
     * through objects to pointers.
     *
     * You should, however, never store a pointer inside the container unless
     * you manage it elsewhere to prevent memory leaks (you can however store
     * it in reference counted container, <shared_ptr>).
     *
     * This structure represents a "set", where a key value is the same as
     * data value. It serves as a base for actual map, where key and data are
     * different. It simply inherits and makes use of <pair>.
     * 
     * If you need unordered storage with forward iterators only, you can use
     * <hashset>, which is implemented using a hash table. It has better
     * insertion / lookup time complexity, but also less features and
     * fewer types can be used as keys.
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
     *     // this will not fail - it'll insert a value, so it'll print 10.
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
     *     // retrieving the tree length
     *     printf("%i\n", test.length());
     *
     *     // will clear the node - also done
     *     // automatically in the destructor
     *     test.clear();
     * (end)
     */
    template<typename T> struct Set
    {
        typedef Set_Node<T> node;

        /* Typedef: it
         * An iterator typedef for standard, non-const iterator.
         */
        typedef Set_Iterator<T> it;

        /* Typedef: cit
         * An iterator typedef for const iterator.
         */
        typedef Set_Const_Iterator<T> cit;

        /* Typedef: rit
         * Reverse iterator typedef, a <Reverse> < <it> >.
         */
        typedef iterators::Reverse_Iterator<it> rit;

        /* Typedef: crit
         * Const reverse iterator typedef, a <Reverse> < <cit> >.
         */
        typedef iterators::Reverse_Iterator<cit> crit;

        /* Constructor: set
         * Creates a new set with root node where root is the same as nil
         * (will change when something gets inserted).
         */
        Set(): p_root(new node), p_nil(NULL), p_length(0)
        {
            p_nil = p_root;
        }

        /* Destructor: set
         * Deletes a root node, all its sub-nodes and a nil node. Done to not
         * leak memory.
         */
        ~Set()
        {
            p_destroy_node(p_root);
            delete p_nil;
        }

        /* Function: length
         * Returns the tree length (the amount of nodes with actual data).
         */
        size_t length() const { return p_length; }

        /* Function: is_empty
         * Returns true if the set contains no nodes (except root / nil)
         * and false otherwise.
         */
        bool is_empty() const { return (p_length == 0); }

        /* Function: begin
         * Returns an iterator to the first node.
         */
        it begin()
        {
            node  *nd = p_root;
            while (nd != p_nil)
            {
                if (nd->p_left == p_nil) break;
                    nd = nd->p_left;
            }

            return it(nd);
        }

        /* Function: begin
         * Returns a const iterator to the first node.
         */
        cit begin() const
        {
            node  *nd = p_root;
            while (nd != p_nil)
            {
                if (nd->p_left == p_nil) break;
                    nd = nd->p_left;
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
            node  *nd = p_root;
            while (nd != p_nil)
                nd = nd->p_right;

            return it(nd);
        }

        /* Function: end
         * Returns a const iterator to the last node.
         */
        cit end() const
        {
            node  *nd = p_root;
            while (nd != p_nil)
                nd = nd->p_right;

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
         * Inserts a new node into the tree with data member given by the
         * arguments.
         */
        T& insert(const T& data)
        {
            return p_insert(p_root, data)->p_data;
        }

        /* Function: clear
         * Destroys the root node, all its sub-nodes and the nil node, and
         * re-initializes the tree with length 0.
         */
        void clear()
        {
            p_destroy_node(p_root);
            delete p_nil;

            p_root     = new node;
            p_nil      = p_root;
            p_length = 0;
        }

        /* Function: erase
         * Erases a node with a given key from the tree.
         */
        void erase(const T& key) { delete p_erase(p_root, key); }

        /* Function: find
         * Returns an iterator to a node that belongs to a given key. There is
         * also a const version that returns a const iterator (non-modifiable).
         */
        it find(const T& key) { return it(p_find(p_root, key)); }

        /* Function: find
         * Const version of <find>. The result cannot be modified.
         */
        cit find(const T& key) const { return cit(p_find(p_root, key)); }

    protected:

        void p_destroy_node(node *nd)
        {
            if (nd == p_nil) return;
            p_destroy_node(nd->p_left);
            p_destroy_node(nd->p_right);
            delete nd;
        }

        void p_skew(node *&nd)
        {
            if (nd->p_level && nd->p_level == nd->p_left->p_level)
            {
                node *n     = nd->p_left;
                n->p_parent = nd->p_parent;

                nd->p_left = n->p_right;
                nd->p_left->p_parent = nd;

                n->p_right = nd;
                n->p_right->p_parent = n;

                nd = n;
            }
        }

        void p_split(node *&nd)
        {
            if (nd->p_level && nd->p_level == nd->p_right->p_right->p_level)
            {
                node *n     = nd->p_right;
                n->p_parent = nd->p_parent;

                nd->p_right = n->p_left;
                nd->p_right->p_parent = nd;

                n->p_left = nd;
                n->p_left->p_parent = n;

                nd = n;
                nd->p_level++;
            }
        }

        template<typename U>
        node *p_insert(node *&nd, const U& data, node *prev = NULL)
        {
            if (nd == p_nil)
            {
                if (!prev) prev = p_root;
                nd = new node(data, p_nil, prev);
                p_length++;
                return nd;
            }

            node *ret = NULL;

            if (!functional::Equal<U, U>()(data, nd->p_data))
            {
                ret = p_insert(((functional::Greater<U, U>()(data, nd->p_data))
                    ? nd->p_right
                    : nd->p_left
                ), data, nd);
                if (!ret) return NULL;
            }

            p_skew (nd);
            p_split(nd);

            return ret;
        }

        template<typename U>
        node *p_erase(node *&nd, const U& key)
        {
            if (nd == p_nil) return NULL;

            if (functional::Equal<U, T>()(key, nd->p_data))
            {
                if (nd->p_left != p_nil && nd->p_right != p_nil)
                {
                    node  *heir = nd->p_left;
                    while (heir->p_right != p_nil)
                           heir = heir->p_right;

                    nd->p_data = heir->p_data;

                    return p_erase(nd->p_left, nd->p_data);
                }
                else
                {
                    node *ret = nd;
                    node *par = nd->p_parent;
                    nd = ((nd->p_left == p_nil)
                        ? nd->p_right
                        : nd->p_left
                    );
                    nd->p_parent = par;

                    p_length--;

                    return ret;
                }
            }
            else return p_erase(((functional::Less<U, T>()(key, nd->p_data))
                ? nd->p_left
                : nd->p_right
            ), key);

            return NULL;
        }

        node *p_find(node *nd, const T& key, bool do_insert = false)
        {
            if (nd == p_nil)
            {
                if (do_insert)
                    return insert(p_root, T());
                else
                    return p_nil;
            }

            if (!functional::Equal<T, T>()(key, nd->p_data))
                return p_find(((functional::Less<T, T>()(key, nd->p_data))
                    ? nd->p_left
                    : nd->p_right
                ), key, do_insert);

            return nd;
        }

        node *p_root;
        node *p_nil;

    private:

        size_t p_length;
    };
} /* end namespace types */

#endif

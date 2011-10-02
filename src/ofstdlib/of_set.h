/*
 * File: of_set.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  set class header.
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
#include "of_tree_node.h"

/*
 * Package: types
 * This namespace features some types used in OctaForge.
 * This part exactly defines set.
 */
namespace types
{
    /*
     * Class: set
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
     *     for (myset::node *n = test.first(); n; n = test.next())
     *         printf("%i\n", n->get());
     *
     *     // reverse iteration
     *     for (myset::node *n = test.last(); n; n = test.prev())
     *         printf("%i\n", **n);
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
        /*
         * Typedef: node
         * Typedefs <tree_node> <T> so it can
         * be used as "node".
         */
        typedef tree_node<T> node;

        /*
         * Constructor: set
         * Creates a new set with root <node> where root
         * is the same as nil (will change when something
         * gets inserted).
         */
        set(): root(new node), nil(NULL), c_length(0)
        {
            nil = root;
        }

        /*
         * Destructor: set
         * Deletes a root node, all its sub-nodes and
         * a nil node. Done to not leak memory.
         */
        ~set()
        {
            destroy_node(root);
            delete nil;
        }

        /*
         * Function: length
         * Returns the tree length (the amount of nodes
         * with actual data).
         */
        size_t length() const { return c_length; }

        /*
         * Function: is_empty
         * Returns true if the set contains no nodes
         * (except root / nil) and false otherwise.
         */
        bool is_empty() const { return (c_length == 0); }

        /*
         * Function: first
         * Returns a pointer to the first node in the
         * tree. Useful for iteration. It basically
         * returns the return value of <fill_stack>.
         *
         * As this fills the stack, it's then possible
         * to nicely iterate the tree without recursion
         * (see the example in the tree definition).
         *
         * See also <last>, <next>, <prev>.
         */
        node *first() { return fill_stack(); }

        /*
         * Function: last
         * See <first>. Also fills the stack, but
         * reversed, so it can be used for reverse
         * iteration.
         *
         * See also <first>, <next>, <prev>.
         */
        node *last() { return fill_stack(true); }

        /*
         * Function: next
         * Basically returns the value of <iter_stack>.
         * Moves onto a next value on the stack and
         * returns it. May return NULL which indicates
         * the end of the tree.
         *
         * See also <first>, <last>, <prev>.
         */
        node *next() { return iter_stack(); }

        /*
         * Function: prev
         * See <next>. Meant to be used with <last>,
         * where <next> is meant to be used with
         * <first>. Iterates the stack in the same
         * way as <next>, but reversed, so it can
         * be used for reverse iteration.
         */
        node *prev() { return iter_stack(true); }

        /*
         * Function: first
         * Const version of <first>.
         */
        const node *first() const { return first(); }

        /*
         * Function: last
         * Const version of <last>.
         */
        const node *last() const { return last(); }

        /*
         * Function: next
         * Const version of <next>.
         */
        const node *next() const { return next(); }

        /*
         * Function: prev
         * Const version of <prev>.
         */
        const node *prev() const { return prev(); }

        /*
         * Function: insert
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

        /*
         * Function: clear
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

        /*
         * Function: erase
         * Erases a node with a given key from the tree. Unlike
         * <pop>, it also deletes the node (and returns nothing).
         */
        void erase(const T& key) { delete erase(root, key); }

        /*
         * Function: pop
         * Simillar to <erase>, but the node doesn't get deleted,
         * instead this returns the node for the user to manage.
         */
        node *pop(const T& key) { return erase(root, key); }

        /*
         * Function: find
         * Returns a node that belongs to a given key. Because it's an
         * actual node, you can modify its data. There is also a const
         * version that returns a const node pointer (non-modifiable).
         */
        node *find(const T& key) { return find(root, key); }

        /*
         * Function: find
         * Const version of <find>. The result cannot be modified.
         */
        const node *find(const T& key) const { return find(root, key); }

        /*
         * Operator: []
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

        /*
         * Operator: []
         * Const version of <[]>. Used for reading only, because it
         * returns a const reference which is non-modifiable.
         *
         * (start code)
         *     printf("%s\n", tree[key]);
         * (end)
         */
        const T& operator[](const T& key) const { return find(key)->data; }

        /*
         * Function: destroy_node
         * Destroys a node given by the argument. This function is
         * recursive, which means it'll call itself for left and
         * right nodes of the given node (and for left and right
         * of those, and so on).
         *
         * Called in <clear> and in the destructor (to destroy the
         * root node and all its sub-nodes).
         *
         * It does nothing when the given node is <nil>.
         */
        void destroy_node(node *nd)
        {
            if (nd == nil) return;
            destroy_node(nd->left);
            destroy_node(nd->right);
            delete nd;
        }

    protected:

        /*
         * Function: skew
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
                node *n = nd->left;

                nd->left = n->right;
                n->right = nd;

                nd = n;
            }
        }

        /*
         * Function: split
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
                node *n = nd->right;

                nd->right = n->left;
                n->left   = nd;

                nd = n;
                nd->level++;
            }
        }

        /*
         * Function: insert
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
        node *insert(node *&nd, const U& data)
        {
            if (nd == nil)
            {
                nd = new node(data, nil);
                c_length++;
                return nd;
            }

            node *ret = NULL;

            int cmp = compare(data, nd->data);
            if (cmp)
            {
                ret = insert(((cmp > 0)
                    ? nd->right
                    : nd->left
                ), data);
                if (!ret) return NULL;
            }

            skew (nd);
            split(nd);

            return ret;
        }

        /*
         * Function: erase
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

            int cmp = compare(key, nd->data);
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
                    nd = ((nd->left == nil)
                        ? nd->right
                        : nd->left
                    );

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

        /*
         * Function: find
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
                    return NULL;
            }

            int cmp = compare(key, nd->data);
            if (cmp)
                return find(((cmp < 0)
                    ? nd->left
                    : nd->right
                ), key, do_insert);

            return nd;
        }

        /*
         * Function: fill_stack
         * Fills an internal node stack with either elements
         * going from the root to the left or if reversed
         * (specified by the argument, defaults to false),
         * the elements going from the root to the right.
         *
         * That is later used when we iterating the tree,
         * as it's important to have the nodes we can't
         * use to get back to the root node stored in
         * a flat structure.
         *
         * For example, if we're iterating from the smallest
         * to the biggest, we need to save the range of smallest
         * nodes until the root onto the stack, loop that then,
         * and when the stack is empty, go to the right as usual.
         *
         * For reverse iteration, we save the range from the root
         * to the biggest, then go through it and then loop the
         * rest again.
         *
         * Can also return NULL if there is nothing in the tree.
         *
         * See <iter_stack>, <first>, <last>, <next>, <prev>.
         * This method has protected level of access.
         */
        node *fill_stack(bool reverse = false)
        {
            node_stack.clear();

            node  *nd = root;
            while (nd != nil)
            {
                node_stack.push(nd);
                nd = reverse
                    ? nd->right
                    : nd->left;
            }
            return ((!node_stack.is_empty())
                ? node_stack.top()
                : NULL
            );
        }

        /*
         * Function: iter_stack
         * Returns a next node (if the argument is unspecified
         * or false, the one with greater key, otherwise the
         * one with lesser key). Makes use of the stack to
         * properly manage the nodes.
         *
         * Can also return NULL when there is no next node to
         * go to.
         *
         * See also <fill_stack>.
         * This method has protected level of access.
         */
        node *iter_stack(bool reverse = false)
        {
            if (node_stack.is_empty()) return NULL;

            node *nd = node_stack.top();
            node_stack.pop();

            nd = reverse
                ? nd->left
                : nd->right;

            while (nd != nil)
            {
                node_stack.push(nd);
                nd = reverse
                    ? nd->right
                    : nd->left;
            }
            return ((!node_stack.is_empty())
                ? node_stack.top()
                : NULL
            );
        }

        /*
         * Variable: root
         * Stores the root node (the one in the middle).
         *
         * This member has protected level of access.
         */
        node *root;

        /*
         * Variable: nil
         * The nil node (the one that always has level 0 and
         * is present in the endings of all nodes that are
         * not further linked).
         *
         * This member has protected level of access.
         */
        node *nil;

    private:

        /*
         * Variable: c_length
         * Stores the current tree length (the amount of
         * nodes that contain some data and are accessible).
         *
         * This member has private level of access. If you
         * want to access it elsewhere, use <length>, which
         * doesn't actually allow you to modify it.
         */
        size_t c_length;

        /*
         * Variable: node_stack
         * A stack of nodes used for the iteration (see
         * <fill_stack> and <iter_stack>).
         *
         * This member has private level of access.
         */
        stack<node*> node_stack;
    };
} /* end namespace types */

#endif

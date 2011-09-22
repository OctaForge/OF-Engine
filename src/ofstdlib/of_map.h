/*
 * File: of_map.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  map class header.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_MAP_H
#define OF_MAP_H

#include <cstring>

#include "of_utils.h"

/*
 * Package: types
 * This namespace features some types used in OctaForge.
 * This part exactly defines map.
 */
namespace types
{
    /*
     * Function: map_cmp
     * A template function used for key comparisons
     * in <map>. This is the default version which
     * is generic.
     *
     * The function takes two arguments, a and b.
     * It returns an int value. The value is 0 if
     * a and b are equal, 1 if a is greater than
     * b and -1 when b is greater than a.
     *
     * You can here specify specialized function
     * for some different type that is more specific
     * (though you shouldn't need to, instead define
     * appropriate comparison operators inside your
     * class).
     */
    template<typename T> inline int map_cmp(T a, T b)
    {
        return ((a > b) ? 1 : ((a < b) ? -1 : 0));
    }

    /*
     * Function: map_cmp
     * Specialization of <map_cmp> for char*'s. This
     * uses strcmp instead of direct comparisons, as
     * you can't compare char pointers like that.
     */
    template<> inline int map_cmp(const char *a, const char *b)
    {
        return strcmp(a, b);
    }

    /*
     * Class: map
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
     * (start code)
     *     typedef types::map<const char*, int> mymap;
     *     mymap test;
     *     // these two ways are equivalent.
     *     test["foo"] = 5;
     *     test.insert("bar", 10);
     * 
     *     // searching
     *     printf("%i\n", test["bar"]);
     *     // this will not fail - it'll insert an empty value,
     *     // so it'll print just 0 (default value for an int)
     *     printf("%i\n", test["baz"]);
     *
     *     // iteration
     *     for (mymap::node *n = test.first(); n; n = test.next())
     *         printf("%s - %i\n", n->key, n->data);
     *
     *     // reverse iteration
     *     for (mymap::node *n = test.last(); n; n = test.prev())
     *         printf("%s - %i\n", n->key, n->data);
     *
     *     // erasing, will delete the node
     *     test.erase("baz");
     *
     *     // same as erase, but will return the node instead
     *     // of deletion, letting the user to manage it
     *     mymap::node *n = test.pop("bar");
     *
     *     // retrieving the tree length
     *     printf("%i\n", test.length);
     *
     *     // will clear the node - also done
     *     // automatically in the destructor
     *     test.clear();
     * (end)
     */
    template<typename T, typename U> struct map
    {
        /*
         * Variable: node
         * The tree node. Contains key and data members.
         * Has two constructors, one takes no arguments
         * and creates a node that is of level 0 and both
         * left and right nodes are itself (here used as
         * <nil>).
         *
         * See the AA tree wikipedia linked in the class
         * definition for more information.
         */
        struct node
        {
            node():
                level(0), left(this), right(this) {}

            node(const T& key, const U& data, node *nd):
                level(1), left(nd), right(nd), key(key), data(data) {}

            size_t level;

            node *left;
            node *right;

            T key;
            U data;
        };

        /*
         * Constructor: map
         * Creates a new map with root <node> where root
         * is the same as nil (will change when something
         * gets inserted).
         */
        map(): length(0), root(new node), nil(NULL)
        {
            nil = root;
        }

        /*
         * Destructor: map
         * Deletes a root node, all its sub-nodes and
         * a nil node. Done to not leak memory.
         */
        ~map()
        {
            destroy_node(root);
            delete nil;
        }

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
         * Inserts a new node into the tree with key and
         * data members given by the arguments.
         *
         * You can also use the <[]> operator with assignment,
         * both ways are equivalent.
         */
        U& insert(const T& key, const U& data)
        {
            return insert(root, key, data)->data;
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

            root   = new node;
            nil    = root;
            length = 0;
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
         * data, not a node.
         *
         * (start code)
         *     tree[key] = value;
         * (end)
         *
         * There is also a const version used for reading.
         */
        U& operator[](const T& key) { return find(root, key, true)->data; }

        /*
         * Operator: []
         * Const version of <[]>. Used for reading only, because it
         * returns a const reference which is non-modifiable.
         *
         * (start code)
         *     printf("%s\n", tree[key]);
         * (end)
         */
        const U& operator[](const T& key) const { return find(key)->data; }

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

        /*
         * Function: skew
         * See <http://en.wikipedia.org/wiki/AA_tree>.
         * The given argument is a reference to a node
         * (it modifies the node from inside).
         *
         * See also <split>, <insert> and <erase>.
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
         * Other arguments are const references to
         * key and value we're inserting.
         *
         * Returns the newly inserted node.
         *
         * See also <skew>, <split> and <erase>.
         */
        node *insert(node *&nd, const T& key, const U& data)
        {
            if (nd == nil)
            {
                nd = new node(key, data, nil);
                length++;
                return nd;
            }

            node *ret = NULL;

            int cmp = map_cmp(key, nd->key);
            if (cmp)
            {
                ret = insert(((cmp > 0)
                    ? nd->right
                    : nd->left
                ), key, data);
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
         */
        node *erase(node *&nd, const T& key)
        {
            if (nd == nil) return NULL;

            int cmp = map_cmp(key, nd->key);
            if (cmp == 0)
            {
                if (nd->left != nil && nd->right != nil)
                {
                    node  *heir = nd->left;
                    while (heir->right != nil)
                           heir = heir->right;

                    nd->key  = heir->key;
                    nd->data = heir->data;

                    return erase(nd->left, nd->key);
                }
                else
                {
                    node *ret = nd;
                    nd = ((nd->left == nil)
                        ? nd->right
                        : nd->left
                    );

                    length--;

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
         */
        node *find(node *nd, const T& key, bool do_insert = false)
        {
            if (nd == nil)
            {
                if (do_insert)
                    return insert(root, key, U());
                else
                    return NULL;
            }

            int cmp = map_cmp(key, nd->key);
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
         * Variable: length
         * Stores the current tree length (the amount of
         * nodes that contain some data and are accessible).
         */
        size_t length;

        /*
         * Variable: root
         * Stores the root node (the one in the middle).
         */
        node *root;

        /*
         * Variable: nil
         * The nil node (the one that always has level 0 and
         * is present in the endings of all nodes that are
         * not further linked).
         */
        node *nil;

        /*
         * Variable: node_stack
         * A stack of nodes used for the iteration (see
         * <fill_stack> and <iter_stack>).
         */
        stack<node*> node_stack;
    };
} /* end namespace types */

#endif

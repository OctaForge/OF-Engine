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

#include "of_utils.h"
#include "of_tree_node.h"
#include "of_set.h"

/*
 * Package: types
 * This namespace features some types used in OctaForge.
 * This part exactly defines map.
 */
namespace types
{
    /*
     * Class: map
     * See <set>. This is the same thing, but it makes
     * use of <pair> to create a key-value associative
     * container, not key-key (value-value). The interface
     * is designed in that way you don't actually access
     * or modify pairs much, only when iterating.
     *
     * (start code)
     *     typedef types::map<const char*, int> mymap;
     *     mymap test;
     *     // these two ways are equivalent in function, the
     *     // second one is better if the element doesn't exist.
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
     *         printf("%s - %i\n", (**n).first, (**n).second);
     *
     *     // reverse iteration
     *     for (mymap::node *n = test.last(); n; n = test.prev())
     *         printf("%s - %i\n", n->get().first, n->get().second);
     *
     *     // erasing, will delete the node
     *     test.erase("baz");
     *
     *     // same as erase, but will return the node instead
     *     // of deletion, letting the user to manage it
     *     mymap::node *n = test.pop("bar");
     *
     *     // retrieving the tree length
     *     printf("%i\n", test.length());
     *
     *     // will clear the node - also done
     *     // automatically in the destructor
     *     test.clear();
     * (end)
     */
    template<typename T, typename U> struct map: set<pair<T, U> >
    {
        /*
         * Typedef: base
         * Typedefs <set> <<pair> <T, U>> so it can be used
         * as "base", for accessing parent (<set>) methods etc.
         */
        typedef set<pair<T, U> > base;

        /*
         * Typedef: node
         * Typedefs <tree_node> <<pair> <T, U>> so it can be used
         * as "node".
         */
        typedef tree_node<pair<T, U> > node;

        /*
         * Function: insert
         * Inserts a new node into the tree with key and
         * data members given by the arguments.
         *
         * You can also use the <[]> operator with assignment,
         * both ways are equivalent in function, this is however
         * better on non-existent keys because it doesn't have to
         * insert first and then assign, instead it creates with
         * the given data directly.
         */
        U& insert(const T& key, const U& data)
        {
            return base::insert(
                base::root, pair<T, U>(key, data)
            )->data.second;
        }

        /*
         * Function: insert
         * A variant of insert that accepts a <pair> of key and
         * data instead of key and data separately.
         */
        const U& insert(const pair<T, U>& data)
        {
            return base::insert(base::root, data)->data.second;
        }

        /*
         * Function: erase
         * Erases a node with a given key from the tree. Unlike
         * <pop>, it also deletes the node (and returns nothing).
         */
        void erase(const T& key) { delete base::erase(base::root, key); }

        /*
         * Function: pop
         * Simillar to <erase>, but the node doesn't get deleted,
         * instead this returns the node for the user to manage.
         */
        node *pop(const T& key) { return base::erase(base::root, key); }

        /*
         * Function: find
         * Returns a node that belongs to a given key. Because it's an
         * actual node, you can modify its data. There is also a const
         * version that returns a const node pointer (non-modifiable).
         */
        node *find(const T& key) { return find(base::root, key); }

        /*
         * Function: find
         * Const version of <find>. The result cannot be modified.
         */
        const node *find(const T& key) const { return find(base::root, key); }

        /*
         * Operator: []
         * See <find>. This one is not const, so you can assign
         * the value. If you assign a non-existant key, it'll
         * get created first, because this has to return the
         * data, not a node (see <insert>).
         *
         * (start code)
         *     tree[key] = value;
         * (end)
         *
         * There is also a const version used for reading.
         */
        U& operator[](const T& key)
        {
            return find(base::root, key, true)->data.second;
        }

        /*
         * Operator: []
         * Const version of <[]>. Used for reading only, because it
         * returns a const reference which is non-modifiable.
         *
         * (start code)
         *     printf("%s\n", tree[key]);
         * (end)
         */
        const U& operator[](const T& key) const
        {
            return find(key)->data.second;
        }

    protected:

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
            if (nd == base::nil)
            {
                if (do_insert)
                    return base::insert(base::root, pair<T, U>(key, U()));
                else
                    return NULL;
            }

            int cmp = compare(key, nd->data.first);
            if (cmp)
                return find(((cmp < 0)
                    ? nd->left
                    : nd->right
                ), key, do_insert);

            return nd;
        }
    };
} /* end namespace types */

#endif

/*
 * File: of_tree_node.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Tree node class header.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_TREE_NODE_H
#define OF_TREE_NODE_H

/*
 * Package: types
 * This namespace features some types used in OctaForge.
 * This part exactly defines tree node.
 */
namespace types
{
    /*
     * Class: tree_node
     * Represents a generic node for trees of various kinds,
     * like red black trees and AA trees.
     *
     * In ofstdlib, used by the <set> and <map> containers,
     * which are friends of this struct (so they can access
     * protected members).
     */
    template<typename T> struct tree_node
    {
        /*
         * Constructor: tree_node
         * Empty constructor. Initializes the level to 0
         * and left and right nodes to itself.
         */
        tree_node(): level(0), left(this), right(this) {}

        /*
         * Constructor: tree_node
         * Initializes the node as leaf node, that is a
         * node with given data, level 1 and left and right
         * nodes being the same.
         */
        tree_node(const T& data, tree_node *nd):
            data(data), level(1), left(nd), right(nd) {}

        /*
         * Operator: *
         * Overloaded non-const dereference operator
         * returning <data>.
         */
        T& operator*() { return data; }

        /*
         * Operator: *
         * Overloaded const dereference operator
         * returning <data>.
         */
        const T& operator*() const { return data; }

        /*
         * Function: get
         * Returns a non-const T reference (data).
         */
        T& get() { return data; }

        /*
         * Function: get
         * Returns a const T reference (data).
         */
        const T& get() const { return data; }

    protected:
        /*
         * Variable: data
         * The node data. Protected level of access.
         */
        T data;

        /*
         * Variable: level
         * The node level. Protected level of access.
         */
        size_t level;

        /*
         * Variable: left
         * The left node link. Protected level of access.
         */
        tree_node *left;

        /*
         * Variable: right
         * The right node link. Protected level of access.
         */
        tree_node *right;

        /*
         * Property: set
         * This specifies the set container is a friend
         * class of this one, and thus can access its
         * protected data.
         */
        template<typename U> friend struct set;

        /*
         * Property: map
         * This specifies the map container is a friend
         * class of this one, and thus can access its
         * protected data.
         */
        template<typename U, typename V> friend struct map;
    };
} /* end namespace types */

#endif

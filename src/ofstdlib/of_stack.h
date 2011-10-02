/*
 * File: of_stack.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  Stack class header.
 *
 * About: Author
 *  Daniel "q66" Kolesa <quaker66@gmail.com>
 *
 * About: License
 *  This file is licensed under MIT. See COPYING.txt for more information.
 */

#ifndef OF_STACK_H
#define OF_STACK_H

#include "of_utils.h"

/*
 * Package: types
 * This namespace features some types used in OctaForge.
 * This part exactly defines stack.
 */
namespace types
{
    /*
     * Class: stack
     * A "stack" class. Internally it's a singly linked list
     * of nodes. Every node has data of type specified by the
     * template argument.
     *
     * As any stack, it has a top node, pushing onto the stack
     * results in new top node with data of the last pushed item,
     * popping results in removal of current top node (that means,
     * previous node will be top again).
     * 
     * It also stores <length>.
     */
    template<typename T> struct stack
    {
        /*
         * Constructor: stack
         * Initializes the stack.
         */
        stack(): top_node(NULL), c_length(0) {}

        /*
         * Destructor: stack
         * Calls <pop_back> until the length is 0. That makes
         * sure all the nodes are deleted (and thus memory
         * is not leaked).
         */
        ~stack()
        {
            while (c_length > 0) pop_back();
        }

        /*
         * Function: length
         * Returns the current stack length.
         */
        size_t length() const { return c_length; }

        /*
         * Function: is_empty
         * Returns true if the stack contains no nodes,
         * and false otherwise.
         */
        bool is_empty() const { return (c_length == 0); }

        /*
         * Function: top
         * Returns the data of the top node.
         */
        T& top() { return top_node->data; }

        /*
         * Function: top
         * Returns the data of the top node, const version.
         */
        const T& top() const { return top_node->data; }

        /*
         * Function: push_back
         * Creates a new top node with the data specified
         * by the argument.
         */
        void push_back(const T& data)
        {
            node *tmp = new node(data, top_node);
            top_node  = tmp;

            c_length++;
        }

        /*
         * Function: pop_back
         * Pops out the top node. The node gets deleted so
         * the memory is not leaked. Return value is the
         * data of the deleted node.
         */
        T& pop_back()
        {
            node *popped = top_node;
            top_node     = popped->below;

            T& ret = popped->data;
            delete   popped;

            c_length--;
            return ret;
        }

        /*
         * Function: clear
         * Calls <pop_back> until the stack is empty.
         */
        void clear()
        {
            while (c_length > 0) pop_back();
        }

    protected:

        /*
         * Variable: node
         * A node for the stack. As this works as a singly
         * linked list, it contains a pointer to the node below,
         * besides data.
         *
         * Protected level of access.
         */
        struct node
        {
            node(const T& data, node *below = NULL):
                below(below), data(data) {}

            node *below;
            T data;
        };

        /*
         * Variable: top_node
         * The top node of the stack (represented as <stack_node>).
         *
         * Protected level of access.
         */
        node *top_node;

        /*
         * Variable: c_length
         * Stores the stack length (the number of nodes).
         *
         * Protected level of access.
         */
        size_t c_length;
    };
} /* end namespace types */

#endif

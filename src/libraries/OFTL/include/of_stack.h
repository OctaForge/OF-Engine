/* File: of_stack.h
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

/* Package: types
 * A namespace containing various container types.
 */
namespace types
{
    /* Struct: Stack
     * A "stack" class. Internally it's a singly linked list of nodes.
     * Every node has data of type specified by the template argument.
     *
     * As any stack, it has a top node, pushing onto the stack results
     * in a new top node with data of the last pushed item, popping results
     * in removal of the current top node (that means, previous node will be
     * top again).
     * 
     * It also stores <length>.
     */
    template<typename T> struct Stack
    {
        /* Constructor: Stack
         * Initializes the Stack.
         */
        Stack(): p_top_node(NULL), p_length(0) {}

        /* Destructor: Stack
         * Calls <pop_back> until the length is 0. That makes sure all the
         * nodes are deleted (and thus memory is not leaked).
         */
        ~Stack()
        {
            while (p_length > 0) pop_back();
        }

        /* Function: length
         * Returns the current Stack length.
         */
        size_t length() const { return p_length; }

        /* Function: is_empty
         * Returns true if the Stack contains no nodes, and false otherwise.
         */
        bool is_empty() const { return (p_length == 0); }

        /* Function: top
         * Returns the data of the top node.
         */
        T& top() { return p_top_node->data; }

        /* Function: top
         * Returns the data of the top node, const version.
         */
        const T& top() const { return p_top_node->data; }

        /* Function: push_back
         * Creates a new top node with the data specified by the argument.
         */
        void push_back(const T& data)
        {
            p_node *tmp = new p_node(data, p_top_node);
            p_top_node  = tmp;

            p_length++;
        }

        /* Function: pop_back
         * Pops out the top node.
         */
        void pop_back()
        {
            p_node *popped = p_top_node;
            p_top_node     = popped->below;

            delete popped;
            p_length--;
        }

        /* Function: clear
         * Calls <pop_back> until the Stack is empty.
         */
        void clear()
        {
            while (p_length > 0) pop_back();
        }

    protected:

        struct p_node
        {
            p_node(const T& data, p_node *below = NULL):
                below(below), data(data) {}

            p_node *below;
            T       data;
        };

        p_node *p_top_node;
        size_t  p_length;
    };
} /* end namespace types */

#endif

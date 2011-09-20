/*
 * File: of_stack.h
 *
 * About: Version
 *  This is version 1 of the file.
 *
 * About: Purpose
 *  stack class header.
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
        stack(): top_node(NULL), length(0) {}

        /*
         * Destructor: stack
         * Calls <pop> until the length is 0. That makes
         * sure all the nodes are deleted (and thus memory
         * is not leaked).
         */
        ~stack()
        {
            while (length > 0) pop();
        }

        /*
         * Function: is_empty
         * Returns true if the stack contains no nodes,
         * and false otherwise.
         */
        bool is_empty() { return (length == 0); }

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
         * Function: push
         * Creates a new top node with the data specified
         * by the argument.
         */
        void push(const T& data)
        {
            stack_node *tmp = new stack_node(data, top_node);
            top_node  = tmp;

            length++;
        }

        /*
         * Function: pop
         * Pops out the top node. The node gets deleted so
         * the memory is not leaked.
         */
        void pop()
        {
            stack_node *popped = top_node;
            top_node  = popped->below;
            delete      popped;

            length--;
        }

        /*
         * Function: clear
         * Calls <pop> until the stack is empty.
         */
        void clear()
        {
            while (length > 0) pop();
        }

        /*
         * Variable: stack_node
         * A node for the stack. Since this works as a singly
         * linked list, it contains a pointer to the node below,
         * besides data.
         */
        struct stack_node
        {
            stack_node(const T& data, stack_node *below = NULL):
                below(below), data(data) {}

            stack_node *below;
            T data;
        };

        /*
         * Variable: top_node
         * The top node of the stack (represented as <stack_node>).
         */
        stack_node *top_node;

        /*
         * Variable: length
         * Stores the stack length (number of nodes).
         */
        size_t length;
    };
} /* end namespace types */

#endif

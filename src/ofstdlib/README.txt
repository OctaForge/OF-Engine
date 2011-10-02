ofstdlib - OctaForge standard library

is a set of various generic features for the C++ programming language,
simillar in function to the C++ standard library, but with simpler,
more transparent implementation, designed to work well with the
"C with classes" style of writing with usage of the C standard
library.

The final goal however is to create a library that is independent on
OctaForge and can be used just about everywhere, but for now is pretty
much limited to OctaForge's needs.

The API is designed from ground up and NOT compatible with the C++
standard library.

It's part of OctaForge and thus is licensed under the MIT license.

Currently contains:
    of_string.h - simple string class with basic operations including
                  slicing, finding and true string formatting, printf
                  style.

    of_new.h - features overloaded new, new[], delete and delete[]
               operators using malloc/free and also DELETEA and
               DELETEP macros for NULL-deleting arrays and pointers.

    of_utils.h - unified definition for NULL (0), some unsigned typedefs,
                 min, max, clamping, swapping, comparing, sorting..

    of_stdio.(cpp,h) - stdio extensions for now for Windows. Features
                       the vasprintf and asprintf functions required
                       by string for formatting.

    of_shared_ptr.h - reference-counted pointer container for use
                      with vectors, hashtables etc. to prevent leaks.

    of_stack.h - a stack container, which is internally a singly linked
                 list. It provides a top node and all other nodes are
                 linked to it ("stacked"). You can get the top node,
                 push data (that'll create new top node) and pop
                 (that'll destroy the current top node and bring
                 back the previous one, which was linked below
                 the top node).

    of_pair.h - a pair container used to implement maps using sets.
                Also useful elsewhere.

    of_tree_node.h - a generic tree node for use in various tree containers
                     like red black trees and AA trees.

    of_set.h - an efficient implemention of generic associative
               container using an AA tree (enhancement to red-black
               tree). Here used to implement a set (an associative
               container where key and value are the same).

    of_map.h - a variant of set that has unique keys and values, thus
               representing an associative array.

    of_list.h - an implementation of doubly linked list with links to
                the first and the last node. Allows insertions and
                deletions from both the beginning and the end.

    of_vector.h - an efficient implementation of generic vector
                  container (simillar to array, but easily manipulable).

    of_traits.h - basic type traits (integral type, floating point type,
                                     pointer type, POD type checking).


Author: Daniel "q66" Kolesa <quaker66@gmail.com>

OFTL - OctaForge Template Library

is a set of various generic features for the C++ programming language,
simillar in function to the C++ standard library, but with simpler,
more transparent implementation, designed to work well with the
"C with classes" style of writing with usage of the C standard
library.

The API is designed from ground up and NOT compatible with the C++
standard library, albeit freely inspired.

It's released under MIT license and created for needs of the OctaForge
project (http://octaforge.org), however is not limited to it and is
meant to be independent.

Currently included:
    - fast and efficient RAII managed strings.
    - generic doubly linked list implementation.
    - AA tree implementation, which provides two containers:
        - set, which is a tree where key and value are the same.
        - map, where key and value are different.
    - pair class, mainly for map.
    - stack implemented using singly linked list.
    - fast and generic dynamic array (vector).
    - shared pointer (reference-counted) class.
    - type traits for checking for integral, floating point,
      pointer and POD types, and equality.
    - unified iterator interface
    - algorithm library
    - unified definition for the new and delete operators.
    - stdio extensions (asprintf/vasprintf for Windows).
    - utilities (unified NULL constant definition, typedefs like
      unsigned int -> uint..).

Author: Daniel "q66" Kolesa <quaker66@gmail.com>

USAGE:
    Simply include the header you want and specify the include path
    when compiling (i.e. -I../include). On Windows, you'll have to
    compile of_stdio.cpp into your application if you want strings
    working.

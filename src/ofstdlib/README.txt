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
    of_string - simple non-templated string class, with basic operations
                including slicing, finding and true string formatting,
                printf style. It's const correct, fast and standard
                conformant.

Author: Daniel "q66" Kolesa <quaker66@gmail.com>

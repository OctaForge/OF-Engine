# octastd

OctaSTD is a collection of C++ utilities to aid the upcoming OctaForge C++
API. It provides containers (dynamic arrays etc) as well as other utilities.

Documentation for OctaSTD can be found at https://wiki.octaforge.org/docs/octastd.

It utilizes C++11. It also implements equivalents of certain C++14 library
features that are possible to implement with the C++11 language. It does not
go beyond C++11 level when it comes to core language features.

## Supported compilers

Compiler | Version
-------- | -------
gcc/g++  | 4.8+
clang    | 3.3+

Other C++11 compliant compilers might work as well. OctaSTD does not utilize
compiler specific extensions except certain builtin type traits - to implement
traits that are not normally possible to implement without compiler support.

OctaSTD does not provide fallbacks for those traits. The compiler is expected
to support these builtins. So far the 2 above-mentioned compilers support them
(MSVC++ supports most of these as well).

MSVC++ is currently unsupported. It is likely that it will never be supported,
as it seems that MS will start supporting Clang in Visual Studio; however,
if that does not happen and the MS C++ compiler gains the required features,
support will be added.

## Supported operating systems

Currently supported OSes in OctaSTD are Linux, FreeBSD and OS X. Other
systems that implement POSIX API will also work (if they don't, bug reports
are welcome).

Windows is supported at least with the MinGW (gcc) and Clang compilers. MS
Visual Studio is currently unsupported.
Compiling OctaForge
********************

Officially supported platforms for OctaForge (those which include/will include
binaries) are currently Linux, FreeBSD, Windows and OS X (experimental).

It should work without problems also on Solaris and other UNIX-like or UNIX
systems.

For different platforms, compilation instructions might differ a bit, so
separate OSes will be explained separately.

For all OSes
============

1. **In all cases, you need to get source code.**
   You can use either release tarball or Git source versioning system to get
   source code.
   (Git will get you most recent source)

   There are two locations where you can grab a copy of the repository:

   https://git.octaforge.org/engine/octaforge.git
   https://github.com/OctaForge/OF-Engine

   You can use an arbitrary Git client, Windows users will likely find
   a GUI client such as TortoiseGit more convenient than the command line
   client.

Unix-like systems (including Linux, the BSDs and Mac OS X)
==========================================================

On these OSes, compilation should be really trivial. Instructions assume Linux
with .deb packaging system, with little modifications it should work everywhere.

Currently this includes OS X. At some point, OS X will get its own instructions.

Supported compilers are GCC (at least 4.2), Clang and possibly others.

1. Open terminal window and get some dependencies to build.

   1. build-essential - on Debian, metapackage installing GNU compiler set and
      a few other things. Basically basic things you need to build sources.
   2. SDL2 dev package, SDL2_image dev package, SDL2_mixer dev package
   3. Zlib dev libraries and headers
   4. LuaJIT 2.0 or higher

   For Linux with apt-get:
   
```
   sudo apt-get install build-essential zlib1g-dev libluajit-dev libsdl2-dev
   libsdl2-mixer-dev libsdl2-image-dev
```

   For FreeBSD (compiler and zlib are included by default):

```
   sudo pkg install sdl20 sdl2_mixer sdl2_image luajit pkgconf gmake
```

   For other operating systems, it should be similar.

   For OS X you can get the official frameworks for the SDL libraries and
   install LuaJIT from Homebrew (or from source). You will need pkg-config
   if you wish to use systemwide LuaJIT.

   If you have a custom build of LuaJIT (static), you can put the lib as
   libluajit.a into src/platform_{linux,freebsd,osx,solaris}/lib and the
   header files into src/platform_*/include and then set LUAJIT_LOCAL in
   the feature section of the Makefile to 1 or pass it to make.

2. Open a terminal, build OF:

```
$ cd $HOME/OctaForge_source/src
$ make install
```

   If you have a multicore processor, you can use `-jNUMCORES+1` as make argument.
   On some systems (like FreeBSD), you'll have to use `gmake` instead of `make`.
   Add `VERBOSE=1` at the end of the make command for verbose builds.

3. You're done, you should have binaries in `OFROOT/bin_unix`.

Windows
=======

On Windows, fetch the repository <https://github.com/OctaForge/OF-Windows> and
place the `platform_windows` directory into `src` and contents of `bin_win32/64`
to `bin_win32/64`.

Then just proceed with the compilation.

OF supports both Win32 and Win64 binaries. The variant is deduced from the
target compiler.

*Visual Studio project will be added soon.*

So the steps are:

1. Install latest MinGW distribution whichever way you want. You need just the
   core (C/C++ support). You can install it wherever you want, but make sure to
   change steps of this guide accordingly after that. Note that you need
   MinGW64 to build 64-bit binaries.

2. Append this into your `PATH` environment variable (modify path if needed):

```
;C:\mingw\bin
```

3. Open a command line (press Windows + R, then type `cmd` and press [Enter]), go to `OFROOT\src`, type:

```
$ mingw32-make install
```

   If you have a multicore processor, you can use `-jNUMCORES+1` as make argument.
   Add `VERBOSE=1` at the end of the make command for verbose builds.

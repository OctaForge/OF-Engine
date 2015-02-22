Compiling OctaForge
********************

Officially supported platforms for OctaForge (those which include/will include
binaries) are currently Linux, FreeBSD, Windows and OS X (experimental).

It should work without problems also on Solaris and other UNIX-like or UNIX
systems.

For different platforms, compilation instructions might differ a bit, so
separate OSes will be explained separately.

Keep in mind that nightly prebuilt snapshots for Linux and Windows are
provided on

https://ftp.octaforge.org/snapshots/

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

On Windows, fetch the repository with dependencies and place the `platform_windows`
directory into `src` and contents of `bin_win32/64` to `bin_win32/64`.

There are two locations where you can grab a copy of the repository:

https://git.octaforge.org/build/libs_win.git
https://github.com/OctaForge/OF-Windows

Then you have 3 options:

1. Use MinGW or TDM-gcc to build.

   In that case the procedure is similar to Unix-like systems. You need to
   have a command line with PATH set properly so that it can find the MinGW
   (or TDM-GCC) binaries. Then, you just simply do:

   ```
      mingw32-make install
   ```

   This also gives you a separate server executable in addition to the client
   and you can build the master server with it, by using the `master` target.

   You can also speed up compilation by using the `-jN` argument for multiple
   threads. Please refer to the appropriate documentation.

   This option is suitable for developers and advanced users who are used to
   using a command line environment.

2. Use a code::blocks project file.

   A code::blocks project file is provided in `src/vcpp/octaforge.cbp`. You
   need the MinGW compiler for code::blocks installed. Then you can simply
   build OctaForge, nothing else should be necessary.

   This option will only give you a client executable. You can launch a
   dedicated server using the `-d2` option for the client. That is completely
   functionally identical to using a separate server executable. The actual
   server executable is most suitable for headless systems (which Windows
   isn't) - for example remote servers with ssh only access.

   Both 32-bit and 64-bit executables are supported.

3. Use a Visual Studio project file.

   In that case you should be using `src/vcpp/octaforge.sln`. Just like above,
   it only builds a client (in either 32-bit or 64-bit version, debug, release
   or profile), just like the code::blocks project file. Use `-d2` to launch
   a dedicated server, if needed.

   Unlike the two options above, this builds OctaForge using Microsoft's
   C++ compiler, against Microsoft runtime, which is the preferable option
   if you're packaging the engine.

You can also cross-compile OctaForge for Windows from a Linux, FreeBSD or
some other Unix-like system using MinGW.

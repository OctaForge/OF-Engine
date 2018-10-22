OctaForge
=========

**THIS REPOSITORY IS ARCHIVED AND DEPRECATED.**
**Development continues on https://git.octaforge.org.**

For installation, read **INSTALL.md**.

Running depends on the platform.

On Unix-like systems (OS X only when compiled with the provided Makefile), run
it using `bin_unix/client_YOUROS_YOURARCH` from either the root directory or
`bin_unix`.

On OS X, you can use the way above and you can also run it from within the
Xcode project (development builds) or you can run the generated app bundle
after deploying (the .dmg file also contains gamedata and is ready to ship).

On Windows, execute `bin_winYOURARCH\client_win_YOURARCH.exe` either from
the root directory or from the directory with the binary.

Samee goes for server, just change "client" to "server". Using the -d2 option
to client binary you can get the same dedicated server too (-d1 will start a
listenserver).

In case of problems, delete contents of your OF home directory
(`$HOME/.octaforge` on Unix-like operating systems,
`Documents\My Games\OctaForge` on Windows)

The variable "game" influences what gamescript will be run. In local sessions
it's used directly, but when connecting to a server is involved, the server
will send the gamescript name to the client (on the server the same variable
is used to specify it; modify server-init.cfg appropriately).

Example:

    /game drawing.basic

This results in media/scripts/gamescripts/drawing/basic.oct being run.

There is just one map, "test", bundled by default. Use `/newmap` to create a
new map, just like in Tesseract.

If a problem persists, report it into our
issue tracker: <https://github.com/OctaForge/OF-Engine/issues>

<http://octaforge.org/>

2013-11-23 - 0.3.0 beta 11

    * Removed obsolete GUI code, simplified, optimized the rest
    * GUI: reduce expanding hbox/vbox mode to two passes
    * Procedural API: cube, texture, material lookups
    * Tweaked fonts
    * 8-directional movement animations (running, crouching, jumping etc.)
    * New contributor: fleeky
    * New player model by fleeky
    * Build system fixes and simplifications
    * Changed license: University of Illinois/NCSA Open Source License
    * Added in some textures by nobiax
    * Redesign the player_class system
    * Tweaked player values
    * playerfpsshadow variable for making player shadow visible in first person
    * New map: test (by fleeky)
    * Texture groups via the texgroup command (for categorization)
    * New texture loading system - works dynamically while mapping, is based
      on a texture pack system (texpackload, texpackunload, texpackreload)
    * New command: texcull, to remove unused slots
    * New command: writemediacfg, to write used textures (and optionally
      preload lines for models and sounds) into media.cfg - executed
      automatically on map start, and the cfg is also written in savemap
    * Akin to texpackload, matpackload loads .mat files with material defs
      (materialreset has been expanded to allow fine-grained clearing)
    * Fixed the replace/replacesel commands
    * Upstream: decal and particle improvements
    * Extended newent: extra arguments to it specify default values of
      the new entity's attributes (specific for each entity type)

2013-10-14 - 0.2.9 beta 10

    * Adjustable procedural atmosphere/sky
    * New scripting library: games
    * Initial code for the OF demo game, "octacraft", with basic block
      placement and deletion
    * Lots of UI fixes
    * Improved spawn stage control in game manager
    * A new, generic, reusable health/damage system
    * Faster API calls: almost all of the core API was transformed to use
      FFI function pointers (and all performance sensitive functions)
    * A new capi patching module
    * Reworked UI texture handling
    * Redesigned/rewritten procedural editing API with high level safe
      functions and a fast and powerful low level part
    * Vectors in geom.lua now use floats

2013-09-16 - 0.2.8 beta 9

    * UI changes:
      * Much improved text editors (better clamping, autoscroll,
        customizable colors, documentation and other things)
      * Improved states (use "default" state when none available)
      * Support for 5 mouse buttons in clicking
      * New event: holding (when a clicked widget is being held)
      * Improved API for menus and tooltips (not as hardcoded)
      * Better scrollers and scrollbars
      * Everything now respects independent projections
      * Better and more efficient menu positioning
      * Initial theme and default GUIs:
        * Main menu
        * Entity editing (right click or F1 with entity selection)
        * "New entity" window (F1)
        * Texture selection window (F2)
        * Changes window
      * Theme includes more things:
        * Checkboxes, radioboxes
        * Window styles (borderless, regular, movable etc.)
      * Variant properties
      * A "false" variant (disables)
      * Improved clamping: clamp_h and clamp_v for horizontal/vertical clamp
      * New event: "released" (when a widget is released from a click)
      * New widget: Text_Filler (fills in terms of font units)
      * Removed world margin (not needed anymore)
      * Improved colors on widgets: can be now specified in several ways
        (hex ARGB, hex RGB + alpha, hex RGB, RGB fields, RGBA fields)
      * New modes for H_Box and V_Box:
        * Expand - makes clamping items take as much space as they can
        * Homogenous - gives all items an equal amount of space
      * New widget: State (an equivalent of a "switch" construct or pattern
        matching in terms of GUI)
      * Revamped handling of floating widgets and movable windows
      * And a lot more (fixes everywhere)
    * Changed naming on constructors and initializers (__ctor, __init etc.)

2013-08-26 - 0.2.7 beta 8

    * UI changes:
      * Font selection on labels and editors
      * New widgets: Triangle, Circle, Console
      * Optional dynamic min_w and min_h for widgets
      * Large console and edit stats are now handled with the UI
      * Separate projection for each window/UI world object (independent
        scaling)
      * Rewritten editors:
        * They now implement the same interface as Scrollers, allowing for
          scrollbars
        * Horizontal and vertical autoscroll as you type
        * Unbounded (no maxx/maxy)
        * Proper clipping
      * Better value handling on sliders/editors/fields
      * Faster text calls (via function pointers)
    * Upstream sync:
      * Oculus Rift support on Linux
      * nogi material
    * New vector library, geom.lua, for now supporting vec2, vec3 and vec4
      with a lot more functions than the previous one
    * Luacy: support for 64bit signed and unsigned integers

2013-08-05 - 0.2.6 beta 7

    * Savemap command
    * Faster bindings - allow C-Lua functions to be bound via C function
      pointers and then called using the FFI for better performance
    * Core Lua library organization changes
    * UI improvements:
      * New widget: Line
      * New feature: universal dropdown menus and submenus and a Menu_Button
        widget
      * New feature: variants (to create differently styled global versions
        of widgets)
      * New feature: global state children initializers
      * New feature: containers (allows you to specify a custom widget that'll
        act as a children container for another widget)
      * New feature: widget visibility
      * Started UI theming
      * Optimized grid and box widgets
      * Cleanups and fixes
    * New menu background and logo, tweaked font settings
    * Tesseract: accurate per triangle mapmodel collisions including collision
      meshes
    * Updated and renamed configuration files
    * Windows: make the server a GUI application so that it doesn't spawn
      a cmd window everytime you run a map
    * Updated local server runner that uses fork/exec on un*x and CreateProcess
      on Windows instead of popen
    * Tesseract: OpenGL 4 core support
    * Used mapmodel preloading
    * Server build now includes rendermodel for correct serverside physics

2013-07-22 - 0.2.5 beta 6

    * More module cleanups - no extra globals except SERVER remain now
    * Cubescript optimizations
    * Scalable font rendering using signed distance fields (including fragment
      shader outlines and possibility for all kinds of font effects)
    * Resolution changes in fullscreen no longer result in display mode
      change (instead the engine stretches to native resolution)
    * Deduplicated and cleaned up message passing code
    * Introduction of the Luacy compiler for Lua scripts, featuring:
      * bitwise operators (&, |, ^^, ~, <<, >>, >>>)
      * If expression (if cond then expr1 else expr2)
      * Continue statement for loops
      * Short lambda expressions (|arglist| retexpr or |arglist| do block end)
      * Enumerations ({: contents :}), members auto-increment like an enum
        (they start with 1), you can reference previously defined enum members
        directly
      * New inequality syntax (!= instead of ~=, the old form remains for
        compatibility)
      * Debug statement for clean performant debug logging (debug then stat,
        debug do block end)
      * Binary literals (including underscore support for readability)
      * Syntactic sugar for table member locals (local foo, bar in baz instead
        of local foo, bar = baz.foo, baz.bar)
      * Compound assignment statements (foo += bar instead of foo = foo + bar,
        supports all bitwise and arithmetic operators plus the concat operator)
    * A gradient widget for the UI
    * An outline widget for the UI (with adjustable thickness, including a
      simple line)
    * A revamped text input system for the UI, no longer requiring text editor
      handlers
    * Keyfield widget for potential keybind UI
    * Separate slot and vslot viewer widgets
    * Lots of fixes and cleanups

2013-07-08 - 0.2.4 beta 5

    * Removed some serverside code regarding particles and sounds - use state
      variables and draw directly on the client instead
    * Removed the old "effects" module for particles
    * Separated module extensions - math, string and table stuff is no longer
      injected into their respective core modules
    * Lua API to register particle renderers and create various effects
    * Lua API to register decal renderers and spawn decals
    * Particles and decals now store color channels separately rather than
      in a single int so that it's possible to go out of the standard range
      of 1 byte
    * New C++ API for Lua string pinning
    * Cleaned up mapmodel system
    * New Lua API for dynlights
    * Mapsounds are managed from Lua side
    * Improved model attachment system that works for mapmodels, characters
      and any other model type
    * Low level entity system cleanups
    * Expanded the number of user definable animations from 128 to 512
    * Separated animation and animation flags from Lua perspective
    * The animation state variable is now an array of strings so that
      you don't have to know the integer ids and so that you don't have
      to use bitwise operations for secondary anims
    * High level particle effect and decal module in the core library
    * Removed the original particle effect entity type and instead introduced
      a new system where each particle effect has its own unique entity,
      those can be created from Lua
    * Removed all predefined particle effect types - you can define them
      on your own
    * Logging is now contained within its own module, no globals
    * GUI is now moved to the core namespace
    * The Lua state is now destroyed after you close the map and re-created,
      so you can start another map without restarting the engine
    * Mapscripts are now sandboxed so that they can't access unsafe APIs,
      they have their own module system
    * You can no longer create new global variables the standard way (without
      using rawset) - store your vars as locals and expose via modules
    * Cleaned up preprocessing loader so that the input without preprocessing
      is valid Lua code
    * The core C API is now a module as well, initially stored in
      package.preload
    * Various other cleanups and reorganizations - refer to git commits
      for more information

2013-06-17 - 0.2.3 beta 4

    * Changes in default texture scaling - textures now render at quarter
      of their size (where it fit once before, it fits four times now)
    * Default texture scaling adjustable with a map var
    * Correct behavior of model bounding boxes when adjusting pitch/roll
    * The sauer attr system is not limited to 5 attributes anymore
    * Scripted vectors now use native __new constructors
    * OF no longer needs luajit with 5.2 features (proxy objects are used to
      work around the lack of __len on tables)
    * Pitch and roll for obstacles
    * Particles now support 24bit colors instead of just 16bit
    * Functional newent for manual use
    * From tesseract: triplanar texturing and decal shaders, cubescript
      optimizations and other improvements
    * Reorganized namespaces - they're always explicit now
    * Modules don't use globals anymore - instead you require() them where
      you need them
    * Removed _V (use the var module)
    * The _C interface to core API is now read only (via userdata - can never
      be modified from scripts)
    * Removed the CLIENT variable, check for client via "not SERVER"
    * Removed the library module - you can use require() with any library
      right away to include modules
    * More improvements in the editing HUD
    * Removed the 10/ library - some of the scripts are replaced in extra/
      using new APIs, some are not replaced yet
    * Removed the remains of deprecated scripts (except effects.lua which
      is still awaiting replacement)
    * A plugin system is now builtin in ents.register_class
    * The scripting modules now work with milliseconds instead of seconds
      everywhere (for example in entity run() methods and in actions)
    * Better user defined entity linking - you can now link an entity
      with multiple other ones
    * Smaller adjustments and lots of bug fixes

2013-06-03 - 0.2.2 beta 3

    * Reorganized entity structure inside the engine
    * Oriented markers now have pitch
    * Generic entity attaching system with visualization in the world
    * Automatic texture extension detection (for jpg, png)
    * Icon particle type and use that for entities in edit mode
    * Reworked editmode entity icons - they're now truly per-entity-type
      as in scripted entity type, they can also be colorized per-entity-type
    * Reworked some editing commands to use named attributes (e.g. entattr),
      this breaks some stdedit code that is still to be changed
    * Optimized scripted vec3/vec4 using native FFI structures instead of
      tables
    * New entity editing HUD displaying relevant properties instead of 5
      numbers
    * Removal of sauer types from the API (not relevant anymore)
    * World_Marker is now Oriented_Marker with yaw and pitch
    * Fixed dynamic and flickering light types (temporary)
    * Removed the getter/setter system from objects, instead methods get_attr
      and set_attr are used (more explicit and faster)
    * State variables are registered on per-class basis rather than per-entity,
      that means each state var is registered just once rather than N times
      (for N entities).
    * Selection grid helpers ported from Lamiae
    * GUI eval labels only execute the command once
    * Players can crouch now
    * Removed obsolete string utils
    * New table serializer and deserializer with more options, better safety
      and better performance
    * Replaced table.sort with a custom written introsort implementation
      (3x faster than the original)
    * Light entities can now be turned off by setting flags to -1
    * Pressed modifier check function for cubescript
    * Crouch height, time, jump velocity and gravity can now be adjusted
      per player (gravity has a global fallback)
    * All engine vars that had "colour" inside them had it replaced with
      "color" for consistency (watercolour -> watercolor)
    * Disabled string.dump
    * Initial support for per-mapscript environments - when finished, you'll
      be able to restart maps without problems

2013-05-20 - 0.2.1 beta 2

    * LuaJIT removed from the main makefile (build your own e.g. from OctaForge
      organization repository)
    * ENet cflags checker script
    * Revamped Make build system
    * Support for amalgamated builds
    * Forced check for 5.2 capabilities in LuaJIT
    * Initial support for CMake based builds
    * Bug fixes (entity tag handling, clearmodel...)
    * Complete Tesseract sync (breaks model yaw and other things)
    * Support for arbitrary roll, pitch and scale on mapmodels (contributed
      by Lee Salzman)
    * Lua strict mode enabled by default
    * Cubescript safe context
    * Removed the per-entity collision box stuff
    * Removed the deprecated triggering collision handler
    * Introduced signal based collision handlers for client-client and
      mapmodel-client
    * Initial support for obstacles - solid/non-solid invisible areas that
      trigger collision handlers (useful for area based triggering, temporary
      path blocking and other purposes)
    * Removed hardcoded sounds, removed id-based sound playing (not needed)
    * More physics handling externals - client-off-map, deadly materials,
      client state change (floor state, liquid state...)

2013-05-06 - 0.2.0 beta 1

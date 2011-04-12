Editing Reference
=================

Editing
-------

  .. note ::

    When dealing with array attributes (getting a piece of information from a set of values) it is important to know that most start at zero (0) and count upwards from there. This means that the first value is 0, the second is 1, the third is 2 and so forth. Please keep this in mind, especially when dealing with entity attributes, as zero is always considered to be the first/default value, not 1.

edittoggle
^^^^^^^^^^

.. code-block :: text

    edittoggle

Switches between map edit mode and normal (default key: e). In map edit mode you can select bits of the map by clicking or dragging your crosshair on the cubes (using the "attack" command, normally MOUSE1), then use the commands below to modify the selection. While in edit mode, physics & collision don't apply (noclip), and key repeat is ON.

dragging
^^^^^^^^

.. code-block :: text

    dragging 0/1

Select cubes when set to 1. Stop selection when set to 0.

editdrag
^^^^^^^^

.. code-block :: text

    editdrag

Select cubes and entities. (Default: left mouse button)

selcorners
^^^^^^^^^^

.. code-block :: text

    selcorners

Select the corners of cubes. (Default: middle mouse button)

moving
^^^^^^

.. code-block :: text

    moving 0/1

Set to 1 to turn on. when on, it will move the selection (cubes not included) to another position. The plane on which it will move on is dependent on which side of the selection your cursor was on when turned on. set to 0 to turn off moving. if cursor is not on selection when turned on, moving will automatically be turned off.

editmovedrag
^^^^^^^^^^^^

.. code-block :: text

    editmovedrag

If cursor is in current cube selection, holding will move selection. Otherwise it will create a new selection.

cancelsel
^^^^^^^^^

.. code-block :: text

    cancelsel

Cancels out any explicit selection you currently have. (Default: space)

editface
^^^^^^^^

.. code-block :: text

    editface D N

This is the main editing command. D is the direction of the action, -1 for towards you, 1 for away from you (default: scroll wheel). N=0 to push all corners in the white box (hold F). N=1 create or destroy cubes (default). N=2 push or pull a corner you are pointing at (hold Q).

gridpower
^^^^^^^^^

.. code-block :: text

    gridpower N

Changes the size of the grid. (default: g + scrollwheel)

edittex
^^^^^^^

.. code-block :: text

    edittex D

Changes the texture on current selection by browsing through a list of textures directly shown on the cubes. D is the direction you want to cycle the textures in (1 = forwards, -1 = backwards) (default: y + scrollwheel). The way this works is slightly strange at first, but allows for very fast texture assignment. All textures are in a list. and each time a texture is used, it is moved to the top of the list. So after a bit of editing, all your most frequently used textures will come first, and the most recently used texture is set immediately when you press the forward key for the type. These lists are saved with the map.

gettex
^^^^^^

.. code-block :: text

    gettex

Moves the texture on the current selection to the top of the texture list. Useful for quickly texturing things using already textured geometry.

selextend
^^^^^^^^^

.. code-block :: text

    selextend

Extend current selection to include the cursor

passthrough
^^^^^^^^^^^

.. code-block :: text

    passthrough

Normally cubes of equal size to the grid are given priority when selecting. passthrough removes this priority while held down so that the cube the cursor is directly on is selected. Holding down passthrough will also give priority to cube over entities. (default: alt)

reorient
^^^^^^^^

.. code-block :: text

    reorient

Change the side the white box is on to be the same as where you are currently pointing. (Default: shift)

flip
^^^^

.. code-block :: text

    flip

Flip (mirror) the selected cubes front to back relative to the side of the white box. (Default: x)

rotate
^^^^^^

.. code-block :: text

    rotate D

Rotates the selection 90 degrees around the side of the white box. Automatically squares the selection if it isn't already. (Default: r + scroll wheel)

undo
^^^^

.. code-block :: text

    undo

Multi-level undo of any of the changes caused by the above operations (Default: z [or u]).

redo
^^^^

.. code-block :: text

    redo

Multi-level redo of any of the changes caused by the above undo (Default: i).

copy
^^^^

.. code-block :: text

    copy

See paste.

paste
^^^^^

.. code-block :: text

    paste

Copy copies the current selection into a buffer. Upon pressing 'paste', a selection box will be created to identify the location of the pasted cubes. Releasing the 'paste' button will actually paste the cubes. So combined with the 'moving' command you can easily place and clone sets of cubes. If the current gridsize is changed from the copy, the pasted copy will be stretched by the same factor.

editcopy
^^^^^^^^

.. code-block :: text

    editcopy

See editpaste.

editpaste
^^^^^^^^^

.. code-block :: text

    editpaste

Will copy cubes as normal copy, but also features entity copies. There are three different methods of use:

    * If no entity is explicitly selected, editcopy will copy the selected cube, just like normal the normal 'copy' command.
    * If one or more entities are selected, editcopy will copy the last entity selected. Editpaste will create a new entity using copy as the template if no entities are selected, otherwise it will overwrite all selected entities with the copied ent.
    * If there are both entity and cube selections, editcopy will copy the entire selection. In other words, when editpaste is used it will paste the cube selection along with all of the entities that were selected.

replace
^^^^^^^

.. code-block :: text

    replace

Repeats the last texture edit across the whole map. Only those faces with textures matching the one that was last edited will be replaced.

replacesel
^^^^^^^^^^

.. code-block :: text

    replacesel

Repeats the last texture edit only within the currently selected region. Only those faces with textures matching the one that was last edited will be replaced.

editmat
^^^^^^^

.. code-block :: text

    editmat MAT [FILTER]

Changes the type of material left behind when a cube is deleted to MAT. If FILTER is specified, then only cubes with that material named by FILTER are changed to MAT. MAT may also be "", indicating that only those parts of the material mask matching FILTER will be cleared, as opposed to setting MAT to "air", which would clear the entire material mask.

Currently the following types of materials are supported:

    * air: the default material, has no effect. Overwrites other volume materials.
    * water: acts as you would expect. Renders the top as a reflection/refraction and the sides as a waterfall if it isn't contained. Should be placed with a floor at the bottom to contain it. Shows blue volume in edit mode. Overwrites other volume materials.
    * glass: a clip-like material with a blended/reflective surface. Glass also stops bullets. Will reflect the closest envmap entity, or if none is in range, the skybox. Shows cyan volume in edit mode. Overwrites other volume materials.
    * lava: renders the top as a glowing lava flow and the sides as lavafalls if it isn't contained. It kills any players who enter it. Shows orange volume in edit mode. Overwrite other volume materials.
    * clip: an invisible wall that blocks players movement but not bullets. Is ideally used to keep players "in bounds" in a map. Can be used sparingly to smooth out the flow around decoration. Shows red volume in edit mode. Overwrites other clip materials.
    * noclip: cubes are always treated as empty in physics. Shows green volume in edit mode. Overwrites other clip materials.
    * gameclip: a game mode specific clip material. Currently it can block monsters in SP modes, it can stop flags from being picked up in areas in CTF/protect modes, and it can stop capturing of bases in areas in capture modes. Overwrites other clip materials.
    * death: causes the player to suicide if he is inside the material. Shows black volume in edit mode.
    * alpha: all faces of cubes with this material are rendered transparently. Use the "valpha" and "texalpha" commands to control the transparency of front and back faces. Shows pink volume in edit mode.

recalc
^^^^^^

.. code-block :: text

    recalc

Recalculates scene geometry. This also will regenerate any envmaps to reflect the changed geometry, and fix any geometry with "bumpenv*" shaders to use the closest available envmaps. This command is also implicitly used by calclight.

havesel
^^^^^^^

.. code-block :: text

    havesel

Returns the number of explicitly selected cubes for scripting purposes. Returns 0 if the cubes are only implicitly selected.

gotosel
^^^^^^^

.. code-block :: text

    gotosel

Goes to the position of the currently selected cube or entity.

Heightfield
-----------

Heightfields are very different than what most people are probably used to; they are just normal cubes and are NOT special meshes. Really, it's just another way of editing the same geometry. Editing this way is a bit different from normal editing, but just as easy. First, instead of selecting cubes, you select a brush (B+wheel) and textures (middle mouse button while in heightmap mode to toggle). Once this is done, you can apply the brush to all cubes that match the textures you've selected. Making hills and valleys can be quite fast when using this feature. By default all textures are automatically selected.

hmapedit
^^^^^^^^

.. code-block :: text

    hmapedit 0/1

Set to 1 to turn on heightmap mode (default: hold LCTRL or use H to toggle on and off). In heightmap mode the cursor will turn bright green when hilighting heightmap cubes and the editface command will now use brushes to edit heightmap cubes. In order to avoid accidental edits only heightmap cubes are editable in this mode. If a cubic selection is present, then only cubes within the column of the selection will be modifiable.

hmapselect
^^^^^^^^^^

.. code-block :: text

    hmapselect

Selects the texture and orientation of the hilighted cube (default: mouse buttons while in heightmap mode, or H key). If hmapselall is set to 1, then all textures are automatically selected, and this command will simply select the orientation. All cubes, of equal or larger size, that match the selection will be considered part of the heightmap.

hmapcancel
^^^^^^^^^^

.. code-block :: text

    hmapcancel

Return the heightmap texture selection to default (ie: select all textures).

selectbrush
^^^^^^^^^^^

.. code-block :: text

    selectbrush D

Switches between the various height map brushes (Default: hold B + wheel).

clearbrush
^^^^^^^^^^

.. code-block :: text

    clearbrush

This resets the current brush that is used during heightmap mode editing.

brushvert
^^^^^^^^^

.. code-block :: text

    brushvert x y depth

A brush is a 2D map that describes the depth that the editface commands should push into the cubes at various points. The first two parameters of brushvert are the X and Y coordinates, respectively, of a vert on this 2D map. The last parameter is used to set the depth. NOTE: if all of the brush verts are 0, then a smoothing filter will be applied instead of the brush. This filter will affect the same square sized region as the brush.

brushx
^^^^^^

.. code-block :: text

    brushx

brushy
^^^^^^

.. code-block :: text

    brushy

Along with the 2D map, all brushes also have a handle. This handle is a reference point on the 2D map which defines where the brush is relative to the editing cursor. These two variables define the brush handle's coordinates.

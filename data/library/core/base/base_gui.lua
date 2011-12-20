--[[!
    File: library/core/base/base_gui.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features GUI system.
]]

--[[!
    Package: gui
    This module handles functions for creating menus,
    widgets, editors, fonts etc. Please note that all
    sections coming after this still belong to this module,
    they're separated just for readability.
]]
module("gui", package.seeall)

--[[!
    Function: menu_key_click_trigger
    Plays menu click sound. Used as click trigger.
]]
menu_key_click_trigger = CAPI.menukeyclicktrig

--[[!
    Function: render_progress
    Shows a fullscreen progress bar.

    Parameters:
        percentage - percentage as float number from 0 to 1.
        text - the text to show.
]]
render_progress = CAPI.renderprogress

--[[!
    Function: show_scores
    Toggles the scoreboard. Gets hidden on key un-press.
]]
show_scores = CAPI.showscores

--[[!
    Package: gui
    Functions relating to bitmap font management in OctaForge.
    Deprecated; will be replaced with TTF font support.
]]

--[[!
    Function: font
    Defines a new GUI font.

    Parameters:
        name - name of the font.
        file - path to the bitmap.
        dchw - default character width.
        dchh - default character height.
]]
font = CAPI.font

--[[!
    Function: font_tex
    Defines a texture aftercoming <font_char> s will use.
    In format data/.../name.png.
]]
font_tex = CAPI.fonttex

--[[!
    Function: font_offset
    Sets a character from which the font bitmap begins.
    You don't need to call this if your bitmap begins
    with '!' character, which is engine default.

    Parameters:
        c - the character.
]]
font_offset = CAPI.fontoffset

--[[!
    Function: font_scale
    Scales a font. Accepts an integer.
    Default scale is dchh argument of <font>.
]]
font_scale = CAPI.fontscale

--[[!
    Function: font_alias
    Creates a font alias. First argument
    is the alias name, second is the font name.
]]
font_alias = CAPI.fontalias

--[[!
    Function: font_char
    Defines a font cahracter.

    Parameters:
        x - number of pixels where the character begins on X axis.
        y - number of pixels where the character begins on Y axis.
        w - number of pixels the character takes from x.
        h - number of pixels the character takes from y (optional).
        ox - X offset in pixels (optional).
        oy - Y offset in pixels (optional).
        adv - specifies by how many pixels to advance (optional).
]]
font_char = CAPI.fontchar

--[[!
    Function: font_skip
    Skips N characters.
]]
font_skip = CAPI.fontskip

--[[!
    Package: gui
    Functions relating to HUD management (rectangles, images, fonts).
]]

--[[!
    Function: hud_rectangle
    Shows a HUD rectangle.

    Parameters:
        x1 - left position on X axis (relative, 0 to 1).
        x2 - right position on X axis (relative, 0 to 1).
        y1 - top position on Y axis (relative, 0 to 1).
        y2 - bottom position on Y axis (relative, 0 to 1).
        color - rectangle color in 0xRRGGBB format.
        alpha - rectangle transparency from 0 to 1,
        0 means fully transparent, 1 is non-transparent.
]]
hud_rectangle = CAPI.showhudrect

--[[!
    Function: hud_image
    Shows a HUD image.

    Parameters:
        cx - center position on X axis (relative, 0 to 1).
        cy - center position on Y axis (relative, 0 to 1).
        w - image width (relative, 0 to 1).
        h - image height (relative, 0 to 1).
        color - image color (tint) in 0xRRGGBB.
        alpha - image transparency from 0 to 1,
        0 means fully transparent, 1 is non-transparent.
]]
hud_image = CAPI.showhudimage

--[[!
    Function: hud_label
    Shows a HUD label.

    Parameters:
        text - the text to show.
        cx - center position on X axis (relative, 0 to 1).
        cy - center position on Y axis (relative, 0 to 1).
        scale - text scale (1 being normal).
        color - text color (0xRRGGBB).
]]
hud_label = CAPI.showhudtext

--[[!
    Package: gui
    Functions relating to Cube 2 text editor system.

    There is sort of "stack" of editors, the topmost being current.
    DEPRECATED for OF API v2 (v1 will keep it).
]]

--[[!
    Variable: EDITOR_FOCUSED
    Variable specifying to keep the editor while it's focused.
]]
EDITOR_FOCUSED = 1

--[[!
    Variable: EDITOR_USED
    Variable specifying to keep the editor while it's used.
]]
EDITOR_USED    = 2

--[[!
    Variable: EDITOR_FOREVER
    Variable specifying to keep the editor forever.
]]
EDITOR_FOREVER = 3

--[[!
    Function: list_editors
    Returns a table (array) of all existing text editors.
]]
list_editors = CAPI.textlist

--[[!
    Function: get_editor
    Returns contents of the topmost editor as a string.
]]
get_editor = CAPI.textshow

--[[!
    Function: focus_editor
    Focuses editor of given name and sets its mode.
    Default mode is <EDITOR_FOREVER> (if no other provided).

    Parameters:
        name - editor name.
        mode - the mode to set. See <EDITOR_FOCUSED>,
        <EDITOR_USED>, <EDITOR_FOREVER>.
]]
focus_editor = CAPI.textfocus

--[[!
    Function: previous_editor
    Returns to previous editor on the stack.
]]
previous_editor = CAPI.textprev

--[[!
    Function: set_editor_mode
    Sets an editor mode. See <EDITOR_FOCUSED>,
    <EDITOR_USED> and <EDITOR_FOREVER>.

    Parameters:
        mode - the mode to set.
]]
set_editor_mode = CAPI.textmode

--[[!
    Function: save_editor
    Saves the topmost editor to a file.

    Parameters:
        filename - optional filename.
]]
save_editor = CAPI.textsave

--[[!
    Function: load_editor
    Loads a file into the editor. Returns a current
    filename if no argument was specified.

    Parameters:
        filename - optional filename.
]]
load_editor = CAPI.textload

--[[!
    Function: init_editor
    Initializes a text editor and optionally
    loads a file into it.

    Parameters:
        name - name of the new editor.
        filename - optional filename. You can
        always load it manually using <load_editor>.
]]
init_editor = CAPI.textinit

--[[!
    Function: editor_copy
    Copies selection in topmost editor into the clipboard.
]]
editor_copy = CAPI.textcopy

--[[!
    Function: editor_paste
    Pastes contents of the clipboard into topmost editor.
]]
editor_paste = CAPI.textpaste

--[[!
    Function: editor_selected
    Returns 1 when topmost editor is selected, 2 otherwise.
]]
editor_selected = CAPI.textmark

--[[!
    Function: editor_select_all
    Selects everything in topmost editor.
]]
editor_select_all = CAPI.textselectall

--[[!
    Function: editor_clear
    Clears contents of topmost editor.
]]
editor_clear = CAPI.textclear

--[[!
    Function: get_current_editor_line
    Returns current line in topmost editor.
]]
get_current_editor_line = CAPI.textcurrentline

--[[!
    Function: editor_execute
    Executes contents of topmost editor.
    If integral argument of value bigger than 0
    is provided, only selected part will get executed.

    Parameters:
        i - see above.
]]
editor_execute = CAPI.textexec

--[[!
    Package: gui
    Functions providing core elements for GUI building.
    Provides root objects for i.e. windows, buttons,
    scrollers and others.

    See <tgui> if you need more complete GUI elements,
    though certain ones from here are well usable
    (like labels).

    Elements can have forks and siblings. Siblings
    are elements parallel to them, forks are basically
    first of children of the element. When you run
    out of forks, any next children are assumed to be
    simple children elements.

    Please note that even children of child of parent
    are also parent's children.

    Example:
        (start code)
            -- sibling 1
            gui.scroller(0.5, 0.5, function()
                -- child 1
                gui.color(....)
            end)
            -- sibling 2
            gui.vscrollbar(0.01, 1, function()
                -- fork 1
                gui.vlist(...)
                -- fork 2
                gui.vlist(...)
                -- fork 3
                gui.vlist(...)
                -- fork 4
                gui.vlist(...)
                -- fork 5
                gui.vlist(...)
                -- child 1
                -- if this was a child
                -- of some other vscrollbar child,
                -- it'd be a child of vscrollbar
                -- itself as well.
                gui.scroll_button(...)
            end)
        (end)

    Please note that even when widths and heights are specified
    in percent as values from 0.0 to 1.0, you can set it to more
    than 1.0 as well. 1.0 means screen height, even for width
    (1.0, 1.0 makes a square) so this is useful (i.e. width
    set to "scr_w / scr_h" fills the screen width-wise).
]]

--[[!
    Variable: guis
    This table stores all available windows. Showing
    a GUI window basically involves executing a function
    from this table. It's an associative table with key
    being a GUI name.
]]
guis = {}

--[[!
    Function: show
    Shows a GUI from <guis> table.

    Parameters:
        name - GUI name.
]]
show = function(name)
    guis[name]()
end

--[[!
    Function: new
    Creates a new GUI window. Saves into <guis> storage.

    Parameters:
        name - name of the window (also key in <guis>).
        body - function specifying what to display inside the window.
        nofocus - boolean value specifying whether the window can
        take focus. False by default, windows can take focus.
        True value is useful when you're doing things like scoreboard.
        Nofocus windows are still controllable outside mouselook mode.
        This behavior is used later in <tgui>.
        on_hide - function called when the window gets hidden.
]]
new = function(name, body, nofocus, on_hide)
    guis[name] = function()
        CAPI.showui(name, body, on_hide, nofocus)
    end
end

--[[!
    Function: hide
    Hides a GUI window of specified name.

    Returns:
        If the GUI window was not shown, this returns false.
        Otherwise returns true.
]]
hide = CAPI.hideui

--[[!
    Function: replace
    Replaces a tag in a window. See <tag>.

    Parameters:
        window - name of the window the tag is in.
        tag - name of the tag.
        body - function specifying what to replace the tag with.
]]
replace = CAPI.replaceui

--[[!
    Function: align
    Sets parent widget alignment. Parent widget is a widget
    the function from which this is executed belongs to.

    Example:
        (start code)
            gui.label("foo", 1, 1, 1, 1, function()
                -- aligns the label to the left
                gui.align(-1, 0)
            end)
        (end)

    Parameters:
        x - X axis alignment. Has values of either -1 (left),
        0 (center) or 1 (right).
        y - Y axis alignment. Has values of either -1 (top),
        0 (middle) or 1 (bottom).
]]
align = CAPI.uialign

--[[!
    Function: clamp
    Sets parent widget clamping (see <align> for what parent
    widget means).

    Clamping in this case means how the widget will expand.
    All parameters have values of either 0 or 1, where 1
    means "clamp" and 0 means "no clamp".

    Parameters:
        left - clamping to the left.
        right - clamping to the right.
        up - clamping to the top.
        down - clamping to the bottom.
]]
clamp = CAPI.uiclamp

--[[!
    Function: window_mover
    Allows elements inside body of this GUI element to
    serve as input area for mouse-moving of current window.

    You'll most probably want to use <color> for body,
    because it's able of accepting mouse events, unlike
    <fill> or <label>.

    Parameters:
        body - a function inside which you create child
        elements. Accepts no arguments.
]]
window_mover = CAPI.uiwinmover

--[[!
    Function: tag
    Tag is an element in a GUI that holds contents, but
    it is named and you can actually replace its contents.
    That is handy when you're i.e. making tabs and you want
    one content area, which you replace on button presses.

    For replacing, see <replace>.

    Parameters:
        name - tag name.
        body - default tag body (usual function without arguments).
]]
tag = CAPI.uitag

--[[!
    Function: vlist
    Creates a vertical list of elements. Each GUI element pushed
    inside its body will be new list element. If you want several
    items in one list element, use some container, like <fill>
    or <color>.

    Parameters:
        space - padding between contained elements (in percent, 0.0 to 1.0).
        body - list body.

    See Also:
        <hlist>
]]
vlist = CAPI.uivlist

--[[!
    Function: hlist
    Creates a horizontal list of elements. Each GUI element pushed
    inside its body will be new list element. If you want several
    items in one list element, use some container, like <fill>
    or <color>.

    Parameters:
        space - padding between contained elements (in percent, 0.0 to 1.0).
        body - list body.

    See Also:
        <vlist>
]]
hlist = CAPI.uihlist

--[[!
    Function: table
    Creates a table. Table is basically sort of grid of elements.
    Each GUI element pushed inside its body will be new table cell.
    If you want just a simple list, see <vlist> or <hlist>.

    Each table has number of columns specified. Pushing and element
    in the body creates a new cell. Cells fill current row as long
    as they have space. If you exceed space in a row, a new one
    gets created and that one gets filled until it's exhausted as
    well (and then another one gets created ..).

    Parameters:
        columns - number of table columns.
        space - padding between cells (in percent, 0.0 to 1.0).
        body - table body.
]]
table = CAPI.uitable

--[[!
    Function: space
    A "spacer" element. Basically places the padding around its
    children. Useful if you want to create invisible border
    around something.

    Parameters:
        xp - horizontal padding (in percent, 0.0 to 1.0).
        yp - vertical padding (in percent, 0.0 to 1.0).
        body - spacer body.
]]
space = CAPI.uispace

--[[!
    Function: fill
    Creates a filler object. It's an invisible object that can take
    an amount of space and can have children. Fillers can't accept
    input, so don't use it for i.e. buttons without backdrop (same
    as i.e. labels).
    Instead, use <color> for that (with alpha set to 0).

    Parameters:
        xs - horizontal size (in percent, 0.0 to 1.0).
        ys - vertical size (in percent, 0.0 to 1.0).
        body - filler body.
]]
fill = CAPI.uifill

--[[!
    Function: clip
    Creates a clipper object. Clipper works simillar as scroller
    (see <scroll>), but you can't actually scroll in it, it just
    clips some content.

    Parameters:
        xs - horizontal size (in percent, 0.0 to 1.0).
        ys - vertical size (in percent, 0.0 to 1.0).
        body - clipper body.
]]
clip = CAPI.uiclip

--[[!
    Function: scroll
    Creates a scroller object, simillar to clipper (<clip>), but
    can actually scroll. You'll probably want to use it in combination
    with <hscrollbar> or <vscrollbar>. Please note that scrollbars
    are not children of the scroller, they're siblings (placed in
    parallel to the scroller).

    Parameters:
        xs - horizontal size (in percent, 0.0 to 1.0).
        ys - vertical size (in percent, 0.0 to 1.0).
        body - scroller body.
]]
scroll = CAPI.uiscroll

--[[!
    Function: hscrollbar
    Creates a horizontal scrollbar, which is a sibling (parallel) to
    scroller (<scroll>). It can have 5 forks and one child,
    which is <scroll_button> (it comes after forks).

    Parameters:
        xs - horizontal size (in percent, 0.0 to 1.0).
        ys - vertical size (in percent, 0.0 to 1.0).
        body - scrollbar body.

    Forks:
        idle - this is how the scrollbar looks in idle state.
        up_hover - this is how the scrollbar looks when hovering over
        up arrow.
        up_selected - this is how the scrollbar looks when up arrow
        is selected.
        down_hover - see above.
        down_selected - see above.

    Siblings:
        scroller - see <scroll>.

    See Also:
        <vscrollbar>
]]
hscrollbar = CAPI.uihscrollbar

--[[!
    Function: vscrollbar
    Creates a vertical scrollbar, which is a sibling (parallel) to
    scroller (<scroll>). It can have 5 forks and one child,
    which is <scroll_button> (it comes after forks).

    Parameters:
        xs - horizontal size (in percent, 0.0 to 1.0).
        ys - vertical size (in percent, 0.0 to 1.0).
        body - scrollbar body.

    Forks:
        idle - this is how the scrollbar looks in idle state.
        left_hover - this is how the scrollbar looks when hovering over
        left arrow.
        left_selected - this is how the scrollbar looks when left arrow
        is selected.
        right_hover - see above.
        right_selected - see above.

    Siblings:
        scroller - see <scroll>.

    See Also:
        <hscrollbar>
]]
vscrollbar = CAPI.uivscrollbar

--[[!
    Function: scroll_button
    A button meant for dragging that is drawn on the scroll bar.
    It's a child element of scrollbar, see <vscrollbar> or
    <hscrollbar>. Has 3 forks.

    Parameters:
        body - scroll button body.

    Forks:
        idle - idle scrollbutton.
        hovering - when you hover on it.
        selected - when you press it.
]]
scroll_button = CAPI.uiscrollbutton

--[[!
    Function: hslider
    Creates a horizontal slider. Slider can also have a button
    that you can drag, provided by <slider_button>. Sliders
    have a range of values or they can be assigned to engine
    variable.

    Parameters:
        var - name of the engine variable to assign slider to.
        minv - minimal value to force, can be nil.
        maxv - maximal value to force, can be nil.
        body - slider body. You'll probably want this to drag
        the slider and create slider button (see <slider_button>).
]]
hslider = CAPI.uihslider

--[[!
    Function: vslider
    Creates a vertical slider. Slider can also have a button
    that you can drag, provided by <slider_button>. Sliders
    have a range of values or they can be assigned to engine
    variable.

    Parameters:
        var - name of the engine variable to assign slider to.
        minv - minimal value to force, can be nil.
        maxv - maximal value to force, can be nil.
        body - slider body. You'll probably want this to drag
        the slider and create slider button (see <slider_button>).
]]
vslider = CAPI.uivslider

--[[!
    Function: slider_button
    Creates a draggable button for slider. It's supposed to be
    a child of either <hslider> or <vslider>. Has 3 forks.

    Parameters:
        body - slider button body.

    Forks:
        idle - idle scrollbutton.
        hovering - when you hover on it.
        selected - when you press it.
]]
slider_button = CAPI.uisliderbutton

--[[!
    Function: offset
    Offsets its children by a value
    on either X axis, Y axis or both.

    Parameters:
        xo - X offset (in percent, 0.0 to 1.0).
        yo - Y offset (in percent, 0.0 to 1.0).
        body - offsetter's children.
]]
offset = CAPI.uioffset

--[[!
    Function: button
    Creates a GUI button element. This is a raw button,
    if you're looking for something more complex,
    see <tgui>. Has 3 forks.

    Parameters:
        action - a function that is run when the button
        gets clicked. Doesn't accept any arguments.
        body - button's children.

    Forks:
        idle - how the button looks when it's idle.
        hover - how the button looks when it's hovered.
        selected - how the button looks when it's selected.
]]
button = CAPI.uibutton

--[[!
    Function: cond
    A "conditional" element. Displays elements conditionally
    based on whether the condition (evaluated per-frame) is
    fulfilled. Has 2 forks.

    To display either only true state or false state, use
    <fill> with parameters 0, 0 to hide the fork.

    Parameters:
        condition - a function that returns either true or
        false; it is evaluated per-frame and selects whether
        the "true" or "false" fork will be displayed.
        body - conditional's children.

    Forks:
        true - shown when condition returns true.
        false - shown when condition returns false.
]]
cond = CAPI.uicond

--[[!
    Function: cond_button
    Conditional button. Unlike standard <button>, it has a
    disabled state, which is used when conditional does not
    return true. It has 4 forks.

    Parameters:
        condition - a function that returns either true or
        false; it is evaluated per-frame and selects whichever
        fork will get displayed.
        action - a function that is run when the button
        gets clicked. Doesn't accept any arguments. Gets run
        only when condition is not false.
        body - button's children.

    Forks:
        false - displayed as "disabled" state. Buttons in this
        state do not accept events.
        true_idle - idle state when condition is true.
        true_hover - hovering state when condition is true.
        true_selected - selected state when condition is true.
]]
cond_button = CAPI.uicondbutton

--[[!
    Function: toggle
    This is a bit simillar to <cond_button>, except that the
    action is executed in both false and true states. It has
    4 forks.

    Useful for creating i.e. checkboxes and radioboxes.
    Unlike <cond_button>, it does not have any selected state.
    Combined with its split argument, it can as well do widgets
    like spinbuttons, where side where you clicked matters.

    The split argument basically allows user to get which part
    of the widget the select event happened to. If set to 0.5,
    it means it'll separate sides exactly in the middle of the
    widget. If you then do the event on the left side of the
    widget, it'll set "uitogglehside" engine variable to 0,
    and 1 otherwise. If you do it on top side, it'll set
    "uitogglevside" engine variable to 0, and 1 otherwise.

    This way, you can do i.e. toggle that has top arrow
    on the top and bottom arrow on the bottom and separate
    events of the arrows. It won't have visual effect though,
    since there is no separate fork for different selection
    parts.

    Parameters:
        condition - a function that returns either true or
        false; it is evaluated per-frame and selects whichever
        fork will get displayed.
        action - a function that is run when the toggle
        gets clicked. Doesn't accept any arguments.
        split - a float number from 0 to 1 specifying where to
        "split" the widget.

    Forks:
        false_idle - this is displayed when the condition is false
        and the widget is idle.
        false_hover - this is displayed when the condition is false
        and you're hovering on the widget.
        true_idle - this is displayed when the condition is true
        and the widget is idle.
        true_hover - this is displayed when the condition is true
        and you're hovering on the widget.
]]
toggle = CAPI.uitoggle

--[[!
    Function: image
    Shows an image. It won't be stretched, it'll tile instead.
    Supports all formats supported by Cube 2 texture loader,
    including png, jpg and dds. Has no forks.

    Parameters:
        image - path to the image. Searches in two paths, either
        your home directory of OctaForge or root directory.
        Usually has format of "data/....".
        hs - horizontal size (in percent, 0.0 to 1.0).
        vs - vertocal size (in percent, 0.0 to 1.0).
        body - image children.

    See Also:
        <alt_image>
        <stretched_image>
        <cropped_image>
        <bordered_image>
]]
image = CAPI.uiimage

--[[!
    Function: slot_viewer
    Views a texture slot thumbnail. Useful for i.e. texture browser.
    Accepts events, so it's good for combination with <button>.
    Has no forks.

    Thumbnails are generated as-it-goes, so there is no requirement
    to wait for thumbnails to generate before showing the GUI slot
    viewer is in.

    Parameters:
        slot - texture slot index. There is <texture.get_slots_number>
        to get the number of the texture slots, indexes start from 0,
        so the final slot is always number minus 1.
        hs - horizontal size (in percent, 0.0 to 1.0).
        vs - vertocal size (in percent, 0.0 to 1.0).
]]
slot_viewer = CAPI.uislotview

--[[!
    Function: alt_image
    If used as first child of <image>, this is displayed instead
    of the image if the previously specified image fails to load.
    It inherits properties of its parent.

    Applies also for other types of images, such as
    <stretched_image>, <cropped_image>, <bordered_image>.

    Parameters:
        image - the image to load.
]]
alt_image = CAPI.uialtimage

--[[!
    Function: color
    Creates a colored rectangle. Can be transparent, accepts input
    (unlike <fill>). Has no forks.

    Parameters:
        r - red color component as floating
        point value from 0.0 to 1.0.
        g - green color component as floating
        point value from 0.0 to 1.0.
        b - blue color component as floating
        point value from 0.0 to 1.0.
        a - alpha value as floating point value
        from 0.0 to 1.0.
        hs - horizontal size (in percent, 0.0 to 1.0).
        vs - vertical size (in percent, 0.0 to 1.0).
        body - rectangle children.

    See Also:
        <mod_color>
]]
color = CAPI.uicolor

--[[!
    Function: mod_color
    Modulates a color of parent element. It's a good idea to <clamp>
    to all sides in its body.

    Parameters:
        r - red color component as floating
        point value from 0.0 to 1.0.
        g - green color component as floating
        point value from 0.0 to 1.0.
        b - blue color component as floating
        point value from 0.0 to 1.0.
        hs - horizontal size (in percent, 0.0 to 1.0).
        vs - vertical size (in percent, 0.0 to 1.0).
        body - modulator children.
]]
mod_color = CAPI.uimodcolor

--[[!
    Function: stretched_image
    Same as <image>, but it's stretched to its area instead of tiled.

    See Also:
        <alt_image>
        <image>
        <cropped_image>
        <bordered_image>
]]
stretched_image = CAPI.uistretchedimage

--[[!
    Function: cropped_image
    Same as <image>, but cropped.

    Parameters:
        image - path to the image. Searches in two paths, either
        your home directory of OctaForge or root directory.
        Usually has format of "data/....".
        hs - horizontal size (in percent, 0.0 to 1.0).
        vs - vertocal size (in percent, 0.0 to 1.0).
        xs - a floating point number specifying where the image
        should start on X axis (== how much to crop). It ranges
        from 0.0 to 1.0. It can also be a string in format "NUMp",
        then it's interpreted as number of pixels.
        ys - see above, only it's Y axis instead of X.
        xe - see xs, except that it specifies where to end.
        ye - see xe, only it's Y axis instead of X.
        body - image children.

    See Also:
        <alt_image>
        <stretched_image>
        <image>
        <bordered_image>
]]
cropped_image = CAPI.uicroppedimage

--[[!
    Function: bordered_image
    Functions in simillar way as <alt_image>, but instead of loading
    alternate image, it turns its parent into a border.

    Without any children, only the corners will be rendered. You can
    also use <space> to offset the children from the border.

    Parameters:
        image - path to the image. See <image>.
        border_start - specifies texture offset from which to create
        the borders. Follows the same rules as start/end positions
        in <cropped_image>.
        border - specifies border width. Follows the same rules
        as start/end positions in <cropped_image>.
        body - image children.
]]
bordered_image = CAPI.uiborderedimage

--[[!
    Function: label
    Creates a GUI label. Supports basic escaped formatting (newlines,
    tabs etc.). Can be colored. Has no forks.

    This returns a number that can be later used to modify the text
    using <set_label>.

    Parameters:
        text - the text itself.
        scale - 1.0 is default. Floating point number.
        Can be bigger than 1.
        r - red color component as floating
        point value from 0.0 to 1.0.
        g - green color component as floating
        point value from 0.0 to 1.0.
        b - blue color component as floating
        point value from 0.0 to 1.0.
        body - label children.

    See Also:
        <var_label>
]]
label = CAPI.uilabel

--[[!
    Function: set_label
    Sets a label using known ID returned by <label>.

    Parameters:
        id - label ID.
        text - the text to set.
]]
set_label = CAPI.uisetlabel

--[[!
    Function: var_label
    Simillar to <label> but it doesn't return anything and
    first argument is not text, it's engine variable name.
    The label text then gets automatically updated from
    the engine variable. Useful when i.e. doing sliders -
    the <hslider> or <vslider> can put var_label on its
    <slider_button> and value of it will change everytime
    the slider changes.
]]
var_label = CAPI.uivarlabel

--[[!
    Function: editor
    Creates a text editor. It's controllable via editor
    commands, see the previous section.

    Parameters:
        name - the editor name.
        length - the editor length. If this is negative number,
        the editor will wrap lines.
        height - the editor height. 1 means one-line.
        scale - the text scale.
        initial_value - initial editor value.
        keep - if this is true, focus is not lost if the mouse
        moves away from it.
        filter - a collection of characters to filter out.
        body - editor children.
]]
editor = CAPI.uitexteditor

--[[!
    Function: field
    Simillar to <editor>, but there are a few differences.
    First argument specifies the engine variable the field should
    set / get value to / from.

    Second remains length, but third is not height (fields are
    always one-line), it's a function that is run on value change.

    Fourth argument remains, fifth argument specifies the character filter.
    If sixth argument is true, it'll be a password field.

    Seventh argument are field children as usual.
]]
field = CAPI.uifield

--[[!
    Function: clear_changes
    Clears the changes queue. See <get_changes>
    to find out what the queue is.
]]
clear_changes = CAPI.clearchanges

--[[!
    Function: apply_changes
    Applies all changes from the queue.
    See <get_changes> to find out what the queue is.
]]
apply_changes = CAPI.applychanges

--[[!
    Function: get_changes
    Gets a list of changes. When you modify certain
    engine variables (relating rendering, sound ..),
    they might need to restart the renderer or sound
    system, so they get queued. Then a window of name
    "changes" gets shown. The window can then get
    all those changes to display them via this function.

    This returns basically an array of changes, represented
    in string form.
]]
get_changes = CAPI.getchanges

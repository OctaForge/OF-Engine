--[[!
    File: base/base_gui.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features GUI system.

    Section: GUI system
]]

--[[!
    Package: gui
    This module handles functions for creating menus, widgets, editors, fonts etc.
]]
module("gui", package.seeall)

--- Define a new GUI font.
-- @param n Name of the font.
-- @param b Path to the font bitmap.
-- @param l Default character width.
-- @param s Default character height.
-- @param x X character offset. (optional)
-- @param y Y character offset. (optional)
-- @param w W character offset. (optional)
-- @param h H character offset. (optional)
-- @class function
-- @name font
font = CAPI.font

--- Set a character from which the font bitmap begins.
-- You don't need to call this when your bitmap begins
-- with '!' character, which is engine default.
-- @param c The character.
-- @class function
-- @name font_offset
font_offset = CAPI.fontoffset

--- Define a font character.
-- @param x Number of pixels where the character begins on X axis.
-- @param y Number of pixels where the character begins on Y axis.
-- @param w Number of pixels the character takes from x.
-- @param h Number of pixels the character takes from y. (optional)
-- @class function
-- @name font_char
font_char = CAPI.fontchar

--- Create a new GUI window.
-- @param n Name of the window.
-- @param c Widgets inside.
-- @param h Header of the window.
-- @class function
-- @name new
new = CAPI.newgui

--- Clear a GUI.
-- @param n Id of the GUI to clear.
-- @class function
-- @name clear
clear = CAPI.cleargui

--- Show a GUI of known name.
-- @param n Name of the GUI to show.
-- @class function
-- @name show
show = CAPI.showgui

--- Click trigger. Plays menu click sound.
-- @class function
-- @name menu_key_click_trigger
menu_key_click_trigger = CAPI.menukeyclicktrig

--- Create a GUI button widget.
-- @param l Button label.
-- @param a Action to perform on click.
-- @param i Button icon to show. (i.e. "action")
-- @class function
-- @name button
button = CAPI.guibutton

--- Create a GUI label widget.
-- @param l Label text.
-- @param i Icon to show. (i.e. "info")
-- @class function
-- @name text
text = CAPI.guitext

--- Create a GUI list widget.
-- @param c Contents of the list. (i.e. more widgets)
-- @class function
-- @name list
list = CAPI.guilist

--- Create a GUI separator bar widget.
-- @class function
-- @name bar
bar = CAPI.guibar

--- Create a GUI image widget.
-- @param p Path to the image.
-- @param a Action on click.
-- @param s Scale of the image. (float)
-- @param o Set to true if it has overlay. (optional)
-- @param t Alternate image path. (optional)
-- @class function
-- @name image
image = CAPI.guiimage

--- Create a GUI checkbox widget.
-- @param n Checkbox label.
-- @param v Engine variable to set when (un)checked (either existing or new)
-- @param t Default "on" value (float)
-- @param f Default "off" value (float)
-- @param a Action on every state change.
-- @class function
-- @name checkbox
checkbox = CAPI.guicheckbox

--- Create a GUI radiobox widget.
-- @param n Radiobox label.
-- @param v Engine variable to set when (un)selected (either existing or new)
-- @param t Value that variable must have to be shown as selected (selecting will update)
-- @param a Action on state change.
-- @class function
-- @name radiobox
radiobox = CAPI.guiradio

--- Create a GUI slider widget.
-- @param v Engine variable to set on change.
-- @param l Minimal value of the slider.
-- @param h Maximal value of the slider.
-- @param a Action on state change.
-- @class function
-- @name slider
slider = CAPI.guislider

--- Create a GUI list slider widget.
-- @param v Engine variable to set on change.
-- @param l List of numbers in format "1 5 15 20 X Y Z"
-- @param a Action on state change.
-- @class function
-- @name slider_list
slider_list = CAPI.guilistslider

--- Create a GUI name list slider widget.
-- @param v Engine variable to set on change.
-- @param n List of names in format "foo bar blah"
-- @param l List of numbers in format "1 2 3"
-- @param a Action on state change.
-- @class function
-- @name slider_name
slider_name = CAPI.guinameslider

--- Create a GUI field widget.
-- @param v Engine variable to set on change.
-- @param m Maximal length of field value.
-- @param a Action on value change.
-- @param p Setting to true makes it a password field. (optional)
-- @class function
-- @name field
field = CAPI.guifield

--- Create a GUI key field widget.
-- Keyfield is a field accepting key input and showing
-- appropriate keybinding in box (i.e. CTRL+X). Useful
-- when creating a keybinding UI.
-- @param v Engine variable to set on change.
-- @param m Maximal length of field value.
-- @param a Action on value change.
-- @class function
-- @name field_key
field_key = CAPI.guikeyfield

--- Create a GUI bit field widget. Looks like a checkbox,
-- allows bitwise matching. Look at console settings OF
-- menu for usage. (where confilter is being set)
-- @param l Bitfield label.
-- @param v Engine variable to set on change.
-- @param m Bit mask to use.
-- @param a Action on state change.
-- @class function
-- @name field_bit
field_bit = CAPI.guibitfield

--- Create a GUI editor widget (multi-line field).
-- For reference about value getting / setting / ...,
-- see the textedit OF Lua API docs.
-- @param n Name of the editor.
-- @param l Maximal length of contents.
-- @param h Height of the editor in lines.
-- @param m Editor mode, integral value, optional, default 3 (1 - EDITORFOCUSED, 2 - EDITORUSED, 3 - EDITORFOREVER)
-- @class function
-- @name editor
editor = CAPI.guieditor

--- Create a GUI textbox widget (multi-line label).
-- @param t Text to use.
-- @param w Textbox width.
-- @param h Textbox height.
-- @param c Textbox color (hex, optional).
-- @class function
-- @name textbox
textbox = CAPI.guitextbox

--- Create a GUI tab widget. Everything defined under
-- tab definition belongs to the tab.
-- @param l Tab label.
-- @class function
-- @name tab
tab = CAPI.guitab

--- Create a GUI strut widget, useful for setting minimal relative size.
-- @param s Minimal relative size. (float value from 0.0 to 1.0)
-- @param a By default, strut gets pushed into a list. Setting this to true disables the list.
-- @class function
-- @name strut
strut = CAPI.guistrut

--- Creates a GUI align widget, which is simillar to list, but allows to align things.
-- @param a Content alignment. -1 means left, 0 centered and 1 right.
-- @param c Contents of the align, same as in case of list.
-- @class function
-- @name align
align = CAPI.guialign

--- Create a GUI color widget, which basically shows a text representing hex value of a color
-- (0xFFFFFF) entered as parameter, and colorizes the text accordingly.
-- @param c Color to show (hex value)
-- @class function
-- @name color
color = CAPI.guicolor

--- Create a GUI title widget, which is basically a header text styled the same as tab labels.
-- @param t Text to show as header.
-- @class function
-- @name title
title = CAPI.guititle

--- Set an action that happens on current GUI clear.
-- @param a Action to do on current GUI clear.
-- @class function
-- @name on_clear
on_clear = CAPI.guionclear

--- Usual GUI gets closed when event happens in it.
-- In order to protect your GUI from closing, you can create event source (button, ..) in
-- stayopen. Then such behavior won't happen - useful for i.e. editor control buttons.
-- @param c Create your non-closing event sources here.
-- @class function
-- @name stayopen
stayopen = CAPI.guistayopen

--- Usual GUI gets autotabbed in a smart way. In order to protect
-- your GUI from doing that, create your widgets in noautotab.
-- @param c Create your noautotab widgets here.
-- @class function
-- @name noautotab
noautotab = CAPI.guinoautotab

--- Show a progress bar.
-- @name p Percentage as float number from 0.0 to 1.0.
-- @name t Text to show.
-- @class function
-- @name renderprogress
renderprogress = CAPI.renderprogress

--- Show a HUD rectangle.
-- @param x1 X1 position.
-- @param x2 X2 position.
-- @param y1 Y1 position.
-- @param y2 Y2 position.
-- @param c Color of the rectangle as hex number.
-- @param a Alpha of rectangle from 0.0 to 1.0.
-- @class function
-- @name showhudrect
showhudrect = CAPI.showhudrect

--- Show a HUD image.
-- @param cx X center.
-- @param cy Y center.
-- @param w Width.
-- @param h Height.
-- @param c Color of the image as hex number.
-- @param a Alpha of the image from 0.0 to 1.0.
-- @class function
-- @name showhudimage
showhudimage = CAPI.showhudimage

--- Show a HUD text.
-- @param t Text to show.
-- @param x X position.
-- @param y Y position.
-- @param s Text scale.
-- @param c Text color.
-- @class function
-- @name showhudtext
showhudtext = CAPI.showhudtext

--- Prepare entity GUI (define it).
-- @class function
-- @name prepentgui
prepentgui = CAPI.prepentgui

--- Get entity property GUI label, knowing its ID.
-- @param id ID of the entity property.
-- @return The label as string.
-- @class function
-- @name getentguilabel
getentguilabel = CAPI.getentguilabel

--- Get entity property GUI value, knowing its ID.
-- @param id ID of the entity property.
-- @return The value as string.
-- @class function
-- @name getentguival
getentguival = CAPI.getentguival

--- Set entity property GUI value.
-- @param id ID of the entity property.
-- @param val The value to set.
-- @class function
-- @name setentguival
setentguival = CAPI.setentguival

--- Show OctaForge plugins GUI. DEPRECATED.
-- @class function
-- @name show_plugins
show_plugins = CAPI.show_plugins

--- Toggle scoreboard.
-- @class function
-- @name showscores
showscores = CAPI.showscores

--- Return list text editors separated by commas.
-- @return List of text editors separated by commas.
-- @class function
-- @name textlist
textlist = CAPI.textlist

--- Return the start of the buffer.
-- @return The start of the buffer.
-- @class function
-- @name textshow
textshow = CAPI.textshow

--- Focus a specific text editor.
-- @param n Name of the text editor.
-- @param i Optional argument specifying editor mode.
-- (1 - EDITORFOCUSED, 2 - EDITORUSED, 3, <=0 - EDITORFOREVER)
-- @class function
-- @name textfocus
textfocus = CAPI.textfocus

--- Return to previous editor.
-- @class function
-- @name textprev
textprev = CAPI.textprev

--- Set text editor mode. Modes:
-- 1 = keep while focused, 2 = keep while used in gui, 3 = keep forever (i.e. until mode changes)
-- @param i The mode.
-- @class function
-- @name textmode
textmode = CAPI.textmode

--- Save contents in the topmost editor.
-- @param f Optional filename argument.
-- @class function
-- @name textsave
textsave = CAPI.textsave

--- Load a topmost editor.
-- @param f Optional filename argument.
-- @return Filename if first argument is not specified.
-- @class function
-- @name textload
textload = CAPI.textload

--- Initialize an editor.
-- @param n Name of the text editor.
-- @class function
-- @name textinit
textinit = CAPI.textinit

--- Copy selection in topmost editor into clipboard.
-- @class function
-- @name textcopy
textcopy = CAPI.textcopy

--- Paste contents of the clipboard into topmost editor.
-- @class function
-- @name textpaste
textpaste = CAPI.textpaste

--- Manipulate with selection on topmost editor.
-- @param i If this is integer bigger than 0, text editor gets unselected.
-- @return If argument is not passed and selection is valid, returns
-- 1, otherwise returns 0, if argument is passed, returns nil.
-- @class function
-- @name textmark
textmark = CAPI.textmark

--- Select everything in topmost editor.
-- @class function
-- @name textselectall
textselectall = CAPI.textselectall

--- Clear the topmost text editor.
-- @class function
-- @name textclear
textclear = CAPI.textclear

--- Return current line of topmost editor.
-- @return Current line of topmost editor.
-- @class function
-- @name textcurrentline
textcurrentline = CAPI.textcurrentline

--- Execute contents of topmost editor.
-- If integral argument > 0 is provided, selected
-- part only gets executed.
-- @param i If this is integer bigger than 0,
-- only selected part of text gets executed.
-- @class function
-- @name textexec
textexec = CAPI.textexec

--- Prepare entities GUI. (prepare classes and show the GUI)
function prepentsgui()
    CAPI.prepareentityclasses()
    show("entities")
end

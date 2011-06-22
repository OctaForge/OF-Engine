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

--- Click trigger. Plays menu click sound.
-- @class function
-- @name menu_key_click_trigger
menu_key_click_trigger = CAPI.menukeyclicktrig

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

guis = {}

show = function(name)
    guis[name]()
end

new = function(name, body, nofocus, realtime, onhide)
    guis[name] = function()
        CAPI.showui(name, body, onhide, nofocus, realtime)
    end
end

hide = CAPI.hideui
replace = CAPI.replaceui
align = CAPI.uialign
clamp = CAPI.uiclamp
winmover = CAPI.uiwinmover
tag = CAPI.uitag
vlist = CAPI.uivlist
hlist = CAPI.uihlist
table = CAPI.uitable
space = CAPI.uispace
fill = CAPI.uifill
clip = CAPI.uiclip
scroll = CAPI.uiscroll
hscrollbar = CAPI.uihscrollbar
vscrollbar = CAPI.uivscrollbar
scrollbutton = CAPI.uiscrollbutton
hslider = CAPI.uihslider
vslider = CAPI.uivslider
sliderbutton = CAPI.uisliderbutton
offset = CAPI.uioffset
button = CAPI.uibutton
cond = CAPI.uicond
condbutton = CAPI.uicondbutton
toggle = CAPI.uitoggle
image = CAPI.uiimage
slotview = CAPI.uislotview
altimage = CAPI.uialtimage
color = CAPI.uicolor
modcolor = CAPI.uimodcolor
stretchedimage = CAPI.uistretchedimage
croppedimage = CAPI.uicroppedimage
borderedimage = CAPI.uiborderedimage
colortext = CAPI.uicolortext
label = CAPI.uilabel
setlabel = CAPI.uisetlabel
varlabel = CAPI.uivarlabel
editor = CAPI.uitexteditor
field = CAPI.uifield

clearchanges = CAPI.clearchanges
applychanges = CAPI.applychanges
getchanges   = CAPI.getchanges

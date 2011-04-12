---
-- base_gui.lua, version 1<br/>
-- GUI control methods for cC Lua interface<br/>
-- <br/>
-- @author q66 (quaker66@gmail.com)<br/>
-- license: MIT/X11<br/>
-- <br/>
-- @copyright 2011 CubeCreate project<br/>
-- <br/>
-- Permission is hereby granted, free of charge, to any person obtaining a copy<br/>
-- of this software and associated documentation files (the "Software"), to deal<br/>
-- in the Software without restriction, including without limitation the rights<br/>
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell<br/>
-- copies of the Software, and to permit persons to whom the Software is<br/>
-- furnished to do so, subject to the following conditions:<br/>
-- <br/>
-- The above copyright notice and this permission notice shall be included in<br/>
-- all copies or substantial portions of the Software.<br/>
-- <br/>
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR<br/>
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,<br/>
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE<br/>
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER<br/>
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,<br/>
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN<br/>
-- THE SOFTWARE.
--

local base = _G
local CAPI = require("CAPI")

--- GUI control methods for cC Lua interface.
-- Contains widget / window creation functions
-- and various misc methods relating GUIs.
-- @class module
-- @name cc.gui
module("cc.gui")

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
--- Show a message window.
-- @param m Message to show.
-- @class function
-- @name show_message
show_message = CAPI.showmessage
--- Show input field window.
-- You can read entered input from "input_data"
-- engine variable.
-- @param m Message to show.
-- @class function
-- @name show_inputdialog
show_inputdialog = CAPI.showinputdialog
--- Show plugins GUI.
-- @class function
-- @name show_plugins
show_plugins = CAPI.show_plugins
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
-- allows bitwise matching. Look at console settings cC
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
-- see the textedit cC Lua API docs.
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
---
-- @class function
-- @name menukeyclicktrig
menukeyclicktrig = CAPI.menukeyclicktrig
---
-- @class function
-- @name prepentgui
prepentgui = CAPI.prepentgui
---
-- @class function
-- @name getentguilabel
getentguilabel = CAPI.getentguilabel
---
-- @class function
-- @name getentguival
getentguival = CAPI.getentguival
---
-- @class function
-- @name setentguival
setentguival = CAPI.setentguival
---
-- @class function
-- @name show_plugins
show_plugins = CAPI.show_plugins
---
-- @class function
-- @name loadcrosshair
loadcrosshair = CAPI.loadcrosshair
---
-- @class function
-- @name showscores
showscores = CAPI.showscores
---
-- @class function
-- @name textlist
textlist = CAPI.textlist
---
-- @class function
-- @name textshow
textshow = CAPI.textshow
---
-- @class function
-- @name textfocus
textfocus = CAPI.textfocus
---
-- @class function
-- @name textprev
textprev = CAPI.textprev
---
-- @class function
-- @name textmode
textmode = CAPI.textmode
---
-- @class function
-- @name textsave
textsave = CAPI.textsave
---
-- @class function
-- @name textload
textload = CAPI.textload
---
-- @class function
-- @name textinit
textinit = CAPI.textinit
---
-- @class function
-- @name textcopy
textcopy = CAPI.textcopy
---
-- @class function
-- @name textpaste
textpaste = CAPI.textpaste
---
-- @class function
-- @name textmark
textmark = CAPI.textmark
---
-- @class function
-- @name textselectall
textselectall = CAPI.textselectall
---
-- @class function
-- @name textclear
textclear = CAPI.textclear
---
-- @class function
-- @name textcurrentline
textcurrentline = CAPI.textcurrentline
---
-- @class function
-- @name textexec
textexec = CAPI.textexec
---
function prepentsgui()
    CAPI.prepareentityclasses()
    show("entities")
end

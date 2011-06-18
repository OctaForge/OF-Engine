/*
 * luabind_gui.hpp, version 1
 * GUI methods for Lua
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2011 q66
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

/* PROTOTYPES */
void newfont(char *name, char *tex, int *defaultw, int *defaulth, int *offsetx, int *offsety, int *offsetw, int *offseth);
void fontoffset(char *c);
void fontchar(int *x, int *y, int *w, int *h);

namespace gui
{
    void _bind_showui(lua_Engine e);
    void _bind_hideui(lua_Engine e);
    void _bind_replaceui(lua_Engine e);
    void _bind_uialign(lua_Engine e);
    void _bind_uiclamp(lua_Engine e);
    void _bind_uitag(lua_Engine e);
    void _bind_uivlist(lua_Engine e);
    void _bind_uihlist(lua_Engine e);
    void _bind_uitable(lua_Engine e);
    void _bind_uispace(lua_Engine e);
    void _bind_uifill(lua_Engine e);
    void _bind_uiclip(lua_Engine e);
    void _bind_uiscroll(lua_Engine e);
    void _bind_uihscrollbar(lua_Engine e);
    void _bind_uivscrollbar(lua_Engine e);
    void _bind_uiscrollbutton(lua_Engine e);
    void _bind_uihslider(lua_Engine e);
    void _bind_uivslider(lua_Engine e);
    void _bind_uisliderbutton(lua_Engine e);
    void _bind_uioffset(lua_Engine e);
    void _bind_uibutton(lua_Engine e);
    void _bind_uicond(lua_Engine e);
    void _bind_uicondbutton(lua_Engine e);
    void _bind_uitoggle(lua_Engine e);
    void _bind_uiimage(lua_Engine e);
    void _bind_uislotview(lua_Engine e);
    void _bind_uialtimage(lua_Engine e);
    void _bind_uicolor(lua_Engine e);
    void _bind_uimodcolor(lua_Engine e);
    void _bind_uistretchedimage(lua_Engine e);
    void _bind_uicroppedimage(lua_Engine e);
    void _bind_uiborderedimage(lua_Engine e);
    void _bind_uilabel(lua_Engine e);
    void _bind_uisetlabel(lua_Engine e);
    void _bind_uivarlabel(lua_Engine e);
    void _bind_uitexteditor(lua_Engine e);
    void _bind_uifield(lua_Engine e);
};

void _bind_clearchanges(lua_Engine e);
void _bind_applychanges(lua_Engine e);
void _bind_getchanges  (lua_Engine e);

namespace lua_binds
{
    LUA_BIND_STD_CLIENT(font, newfont, e.get<char*>(1), e.get<char*>(2), e.get<int*>(3), e.get<int*>(4), e.get<int*>(5), e.get<int*>(6), e.get<int*>(7), e.get<int*>(8))
    LUA_BIND_STD_CLIENT(fontoffset, fontoffset, e.get<char*>(1))
    LUA_BIND_STD_CLIENT(fontchar, fontchar, e.get<int*>(1), e.get<int*>(2), e.get<int*>(3), e.get<int*>(4))

    LUA_BIND_STD_CLIENT(menukeyclicktrig, GuiControl::menuKeyClickTrigger)

#ifdef CLIENT
    #define REG(n) bool __dummy_##n = lua::addcommand((LE_reg){ #n, gui::_bind_##n });

    REG(showui)
    REG(hideui)
    REG(replaceui)
    REG(uialign)
    REG(uiclamp)
    REG(uitag)
    REG(uivlist)
    REG(uihlist)
    REG(uitable)
    REG(uispace)
    REG(uifill)
    REG(uiclip)
    REG(uiscroll)
    REG(uihscrollbar)
    REG(uivscrollbar)
    REG(uiscrollbutton)
    REG(uihslider)
    REG(uivslider)
    REG(uisliderbutton)
    REG(uioffset)
    REG(uibutton)
    REG(uicond)
    REG(uicondbutton)
    REG(uitoggle)
    REG(uiimage)
    REG(uislotview)
    REG(uialtimage)
    REG(uicolor)
    REG(uimodcolor)
    REG(uistretchedimage)
    REG(uicroppedimage)
    REG(uiborderedimage)
    REG(uilabel)
    REG(uisetlabel)
    REG(uivarlabel)
    REG(uitexteditor)
    REG(uifield)

    bool __dummy_clearchanges = lua::addcommand((LE_reg){ "clearchanges", _bind_clearchanges });
    bool __dummy_applychanges = lua::addcommand((LE_reg){ "applychanges", _bind_applychanges });
    bool __dummy_getchanges   = lua::addcommand((LE_reg){ "getchanges",   _bind_getchanges   });
#endif
}

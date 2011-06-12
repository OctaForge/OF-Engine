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
    void _bind_uilist(lua_Engine e);
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
void _bind_loopchanges(lua_Engine e);

SVAR(entity_gui_title, "");
VAR(num_entity_gui_fields, 0, 0, 13);

namespace lua_binds
{
    LUA_BIND_STD_CLIENT(font, newfont, e.get<char*>(1), e.get<char*>(2), e.get<int*>(3), e.get<int*>(4), e.get<int*>(5), e.get<int*>(6), e.get<int*>(7), e.get<int*>(8))
    LUA_BIND_STD_CLIENT(fontoffset, fontoffset, e.get<char*>(1))
    LUA_BIND_STD_CLIENT(fontchar, fontchar, e.get<int*>(1), e.get<int*>(2), e.get<int*>(3), e.get<int*>(4))

    LUA_BIND_STD_CLIENT(menukeyclicktrig, GuiControl::menuKeyClickTrigger)

    // Sets up a GUI for editing an entity's state data. TODO: get rid of ugly ass STL shit
    LUA_BIND_CLIENT(prepentgui, {
        num_entity_gui_fields = 0;
        GuiControl::EditedEntity::stateData.clear();
        GuiControl::EditedEntity::sortedKeys.clear();

        GuiControl::EditedEntity::currEntity = TargetingControl::targetLogicEntity;
        if (GuiControl::EditedEntity::currEntity->isNone())
        {
            logger::log(logger::DEBUG, "No entity to show the GUI for\r\n");
            return;
        }

        int uid = GuiControl::EditedEntity::currEntity->getUniqueId();

        // we get this beforehand because of further re-use
        e.getg("entity_store").t_getraw("get").push(uid).call(1, 1);
        // we've got the entity here now (popping get out)
        e.t_getraw("create_statedatadict").push_index(-2).call(1, 1);
        // ok, state data are on stack, popping createStateDataDict out, let's ref it so we can easily get it later
        int _tmpref = e.ref();
        e.pop(2);

        e.getg("table").t_getraw("keys").getref(_tmpref).call(1, 1);
        // we've got keys on stack. let's loop the table now.
        LUA_TABLE_FOREACH(e, {
            // we have array of keys, so the original key is a value in this case
            const char *key = e.get<const char*>(-1);

            e.getg("state_variables").t_getraw("__getguin");
            e.push(uid).push(key).call(2, 1);
            const char *guiName = e.get<const char*>(-1);
            e.pop(2);

            e.getref(_tmpref);
            const char *value = e.t_get<const char*>(key);
            e.pop(1);

            GuiControl::EditedEntity::stateData.insert(
                GuiControl::EditedEntity::StateDataMap::value_type(
                    key,
                    std::pair<std::string, std::string>(
                        guiName,
                        value
                    )
                )
            );

            GuiControl::EditedEntity::sortedKeys.push_back(key);
            num_entity_gui_fields++; // increment for later loop
        });
        e.pop(2).unref(_tmpref);

        // So order is always the same
        std::sort(GuiControl::EditedEntity::sortedKeys.begin(), GuiControl::EditedEntity::sortedKeys.end());

        // Title
        e.getg("tostring").getref(GuiControl::EditedEntity::currEntity->luaRef).call(1, 1);
        char title[256];
        snprintf(title, sizeof(title), "%i: %s", uid, e.get(-1, "unknown"));
        e.pop(1);
        SETVF(entity_gui_title, title);
        // Create the gui
        char *command = newstring(
            "gui.new(\"entity\", function()\n"
            "    gui.text(entity_gui_title)\n"
            "    gui.bar()\n"
        );
        char tmp_buf[2048];
        char *n = NULL;
        for (int i = 0; i < num_entity_gui_fields; i++)
        {
            const char *key = GuiControl::EditedEntity::sortedKeys[i].c_str();
            const char *value = GuiControl::EditedEntity::stateData[key].second.c_str();
            if (strlen(value) > 50)
            {
                logger::log(logger::WARNING, "Not showing field '%s' as it is overly large for the GUI\r\n", key);
                continue; // Do not even try to show overly-large items
            }
            snprintf(
                tmp_buf, sizeof(tmp_buf),
                "    gui.list(function()\n"
                "        gui.text(gui.getentguilabel(%i))\n"
                "        engine.newvar(\"new_entity_gui_field_%i\", engine.VAR_S, gui.getentguival(%i))\n"
                "        gui.field(\"new_entity_gui_field_%i\", %i, [[gui.setentguival(%i, new_entity_gui_field_%i)]], 0)\n"
                "    end)\n", i, i, i, i, (int)strlen(value) + 25, i, i
            );
            n = new char[strlen(command) + strlen(tmp_buf) + 1];
            strcpy(n, command);
            strcat(n, tmp_buf);
            delete[] command;
            command = newstring(n);
            delete[] n;

            if ((i+1) % 10 == 0)
            {
                snprintf(tmp_buf, sizeof(tmp_buf), "    gui.tab(%i)\n", i);
                n = new char[strlen(command) + strlen(tmp_buf) + 1];
                strcpy(n, command);
                strcat(n, tmp_buf);
                delete[] command;
                command = newstring(n);
                delete[] n;
            }
        }
        char *cmd = new char[strlen(command) + 7];
        strcpy(cmd, command);
        strcat(cmd, "end)\n");
        delete[] command;

        e.exec  (cmd);
        delete[] cmd;
    })

    LUA_BIND_CLIENT(getentguilabel, {
        std::string ret = GuiControl::EditedEntity::stateData[GuiControl::EditedEntity::sortedKeys[e.get<int>(1)]].first + ": ";
        e.push(ret.c_str());
    })

    LUA_BIND_CLIENT(getentguival, {
        std::string ret = GuiControl::EditedEntity::stateData[GuiControl::EditedEntity::sortedKeys[e.get<int>(1)]].second;
        e.push(ret.c_str());
    })

    LUA_BIND_CLIENT(setentguival, {
        const char *key = GuiControl::EditedEntity::sortedKeys[e.get<int>(1)].c_str();
        const char *ov = GuiControl::EditedEntity::stateData[key].second.c_str();
        const char *nv = e.get<const char*>(2);

        if (strcmp(ov, nv))
        {
            GuiControl::EditedEntity::stateData[key].second = e.get<const char*>(2);
            int uid = GuiControl::EditedEntity::currEntity->getUniqueId();
            defformatstring(c)(
                "entity_store.get(%i).%s = state_variables.__get(%i, \"%s\"):from_wire(\"%s\")",
                uid, key, uid, key, nv
            );
            e.exec(c);
        }
    })

#ifdef CLIENT
    #define REG(n) bool __dummy_##n = lua::addcommand((LE_reg){ #n, gui::_bind_##n });

    REG(showui)
    REG(hideui)
    REG(replaceui)
    REG(uialign)
    REG(uiclamp)
    REG(uitag)
    REG(uilist)
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
    bool __dummy_loopchanges  = lua::addcommand((LE_reg){ "loopchanges",  _bind_loopchanges  });
#endif
}

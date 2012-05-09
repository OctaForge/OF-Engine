namespace gui
{
    extern int uitextrows;
}

namespace lapi_binds
{
#ifdef CLIENT
    /* return list of all editors */
    lua::Table _lua_textlist()
    {
        lua::Table t(lapi::state.new_table(editors.length()));

        loopv(editors)
            t[i + 1] = editors[i]->name;

        return t;
    }

    /* return the start of the buffer */
    lua::Object _lua_textshow()
    {
        editor *top = currentfocus();
        if (!top) return lapi::state.wrap<lua::Object>(lua::nil);

        editline line;
        line.combinelines(top->lines);

        lua::Object ret(lapi::state.wrap<lua::Object>(line.text));
        line.clear();
        return ret;
    }

    /* focus on a (or create a persistent) specific editor,
     * else returns current name
     */
    lua::Object _lua_textfocus(types::Vector<lua::Object> args)
    {
        if (args[0].type() == lua::TYPE_STRING)
        {
            int arg2 = ((args.length() >= 2) ? args[1].to<int>() : 0);
            useeditor(
                args[0].to<const char*>(),
                arg2 <=0 ? EDITORFOREVER : arg2,
                true
            );
        }
        else if (editors.length() > 0)
            return lapi::state.wrap<lua::Object>(editors.last()->name);

        return lapi::state.wrap<lua::Object>(lua::nil);
    }

    /* return to the previous editor */
    void _lua_textprev()
    {
        editor *top = currentfocus();
        if (!top) return;

        editors.insert(0, top);
        editors.pop();
    }

    /* (1 = keep while focused, 2 = keep while used in gui,
     * 3 = keep forever (i.e. until mode changes)) topmost editor,
     * return current setting if no args
     */
    lua::Object _lua_textmode(int i)
    {
        editor *top = currentfocus();
        if (!top) return lapi::state.wrap<lua::Object>(lua::nil);

        if (i)
        {
            top->mode = i;
            return lapi::state.wrap<lua::Object>(lua::nil);
        }
        return lapi::state.wrap<lua::Object>(top->mode);
    }

    /* saves the topmost (filename is optional) */
    void _lua_textsave(const char *fn)
    {
        editor *top = currentfocus();
        if (!top) return;

        if (fn && fn[0])
            top->setfile(path(fn, true));

        top->save();
    }

    lua::Object textload(const char *fn)
    {
        editor *top = currentfocus();
        if (!top) return lapi::state.wrap<lua::Object>(lua::nil);

        if (fn && fn[0])
        {
            top->setfile(path(fn, true));
            top->load();
            return lapi::state.wrap<lua::Object>(lua::nil);
        }
        else if (top->filename)
            return lapi::state.wrap<lua::Object>(top->filename);

        return lapi::state.wrap<lua::Object>(lua::nil);
    }

    void _lua_textinit(const char *name, const char *s1, const char *s2)
    {
        if (!name) name = "";
        if (!s2  ) s2   = "";

        editor *top = currentfocus();
        if (!top) return;

        editor *ed = NULL;
        loopv(editors)
        {
            if (!strcmp(name, editors[i]->name))
            {
                ed = editors[i];
                break;
            }
        }
        if (
            ed /*&& ed->rendered*/ && !ed->filename && s1 &&
            (
                ed->lines.empty() || (
                    ed->lines.length() == 1 && !strcmp(s2, ed->lines[0].text)
                )
            )
        )
        {
            ed->setfile(path(s1, true));
            ed->load();
        }
    }

    void _lua_textcopy()
    {
        editor *top = currentfocus();
        if (!top) return;

        editor *b = useeditor(PASTEBUFFER, EDITORFOREVER, false);
        top->copyselectionto(b);
    }

    void _lua_textpaste()
    {
        editor *top = currentfocus();
        if (!top) return;

        editor *b = useeditor(PASTEBUFFER, EDITORFOREVER, false);
        top->insertallfrom(b);
    }

    lua::Object _lua_textmark(int i)
    {
        editor *top = currentfocus();
        if (!top) return lapi::state.wrap<lua::Object>(lua::nil);

        editor *b = useeditor(PASTEBUFFER, EDITORFOREVER, false);
        top->insertallfrom(b);
        if (i)
        {
            top->mark(i == 1);
            return lapi::state.wrap<lua::Object>(lua::nil);
        }
        return lapi::state.wrap<lua::Object>(top->region() ? 1 : 2);
    }

    void _lua_textselectall()
    {
        editor *top = currentfocus();
        if (!top) return;

        top->selectall();
    }

    void _lua_textclear()
    {
        editor *top = currentfocus();
        if (!top) return;

        top->clear();
    }

    lua::Object _lua_textcurrentline()
    {
        editor *top = currentfocus();
        if (!top) return lapi::state.wrap<lua::Object>(lua::nil);

        return lapi::state.wrap<lua::Object>(top->currentline().text);
    }

    void _lua_textexec(bool sel)
    {
        editor *top = currentfocus();
        if (!top) return;

        auto arr = lapi::state.do_string(
            sel ? top->selectiontostring() : top->tostring(),
            lua::ERROR_TRACEBACK
        );
        if (types::get<0>(arr))
            logger::log(logger::ERROR, "%s\n", types::get<1>(arr));
    }

    lua::Object _lua_editor_use(
        const char *name, int mode, bool focus,
        const char *initval, bool password
    )
    {
        editor *ed = useeditor(name, mode, focus, initval, password);
        editor **r = (editor**)lua_newuserdata(
            lapi::state.state(), sizeof(void*)
        );
        *r = ed;

        luaL_newmetatable(lapi::state.state(), "Editor");
        lua_setmetatable (lapi::state.state(), -2);

        return lua::stack::pop_value<lua::Object>(lapi::state.state());
    }

    void _lua_editor_focus(lua::Object e)
    {
        e.push();

        editor **edp = (editor**)luaL_checkudata(
            lapi::state.state(), -1, "Editor"
        );
        luaL_argcheck(
            lapi::state.state(), edp != NULL, -1, "'Editor' expected"
        );
        lua_pop(lapi::state.state(), 1);

        focuseditor(*edp);
    }

    void _lua_editor_remove(lua::Object e)
    {
        e.push();

        editor **edp = (editor**)luaL_checkudata(
            lapi::state.state(), -1, "Editor"
        );
        luaL_argcheck(
            lapi::state.state(), edp != NULL, -1, "'Editor' expected"
        );
        lua_pop(lapi::state.state(), 1);

        removeeditor(*edp);
    }

    lua::Object _lua_editor_current_get()
    {
        editor *ed = currentfocus();
        if (!ed) return lapi::state.wrap<lua::Object>(lua::nil);

        editor **r = (editor**)lua_newuserdata(
            lapi::state.state(), sizeof(void*)
        );
        *r = ed;

        luaL_newmetatable(lapi::state.state(), "Editor");
        lua_setmetatable (lapi::state.state(), -2);

        return lua::stack::pop_value<lua::Object>(lapi::state.state());
    }

    #define EDITOR_PROP(name, valtype) \
    valtype _lua_editor_##name##_get(lua::Object e) \
    { \
        e.push(); \
 \
        editor **edp = (editor**)luaL_checkudata( \
            lapi::state.state(), -1, "Editor" \
        ); \
        luaL_argcheck( \
            lapi::state.state(), edp != NULL, -1, "'Editor' expected" \
        ); \
        lua_pop(lapi::state.state(), 1); \
 \
        return (*edp)->name; \
    } \
    void _lua_editor_##name##_set(lua::Object e, valtype val) \
    { \
        e.push(); \
 \
        editor **edp = (editor**)luaL_checkudata( \
            lapi::state.state(), -1, "Editor" \
        ); \
        luaL_argcheck( \
            lapi::state.state(), edp != NULL, -1, "'Editor' expected" \
        ); \
        lua_pop(lapi::state.state(), 1); \
 \
        (*edp)->name = val; \
    }

    EDITOR_PROP(mode, int)
    EDITOR_PROP(linewrap, bool)
    EDITOR_PROP(maxx, int)
    EDITOR_PROP(maxy, int)
    EDITOR_PROP(pixelwidth,  int)
    EDITOR_PROP(pixelheight, int)
    EDITOR_PROP(mx, int)
    EDITOR_PROP(my, int)
    EDITOR_PROP(cx, int)
    EDITOR_PROP(cy, int)
    EDITOR_PROP(scrolly, int)

    const char *_lua_editor_line_get(lua::Object e, int idx)
    {
        e.push();

        editor **edp = (editor**)luaL_checkudata(
            lapi::state.state(), -1, "Editor"
        );
        luaL_argcheck(
            lapi::state.state(), edp != NULL, -1, "'Editor' expected"
        );
        lua_pop(lapi::state.state(), 1);

        --idx;

        if (!(*edp)->lines.inrange(idx))
            return NULL;

        return (*edp)->lines[idx].text;
    }

    void _lua_editor_draw(
        lua::Object e, float sx, float sy, float scale, bool focused
    )
    {
        e.push();

        editor **edp = (editor**)luaL_checkudata(
            lapi::state.state(), -1, "Editor"
        );
        luaL_argcheck(
            lapi::state.state(), edp != NULL, -1, "'Editor' expected"
        );
        lua_pop(lapi::state.state(), 1);

        glPushMatrix();
        glTranslatef(sx, sy, 0);
        glScalef(scale/(FONTH*uitextrows), scale/(FONTH*uitextrows), 1);
        (*edp)->draw(FONTW/2, 0, 0xFFFFFF, focused);
        glColor3f(1, 1, 1);
        glPopMatrix();
    }

    void _lua_editor_hit(lua::Object e, int hitx, int hity, bool dragged)
    {
        e.push();

        editor **edp = (editor**)luaL_checkudata(
            lapi::state.state(), -1, "Editor"
        );
        luaL_argcheck(
            lapi::state.state(), edp != NULL, -1, "'Editor' expected"
        );
        lua_pop(lapi::state.state(), 1);

        (*edp)->hit(hitx, hity, dragged);
    }

    void _lua_editor_mark(lua::Object e, bool enable)
    {
        e.push();

        editor **edp = (editor**)luaL_checkudata(
            lapi::state.state(), -1, "Editor"
        );
        luaL_argcheck(
            lapi::state.state(), edp != NULL, -1, "'Editor' expected"
        );
        lua_pop(lapi::state.state(), 1);

        (*edp)->mark(enable);
    }

    void _lua_editor_key(lua::Object e, int code, int cooked)
    {
        e.push();

        editor **edp = (editor**)luaL_checkudata(
            lapi::state.state(), -1, "Editor"
        );
        luaL_argcheck(
            lapi::state.state(), edp != NULL, -1, "'Editor' expected"
        );
        lua_pop(lapi::state.state(), 1);

        (*edp)->key(code, cooked);
    }

    void _lua_editor_clear(lua::Object e, const char *init)
    {
        e.push();

        editor **edp = (editor**)luaL_checkudata(
            lapi::state.state(), -1, "Editor"
        );
        luaL_argcheck(
            lapi::state.state(), edp != NULL, -1, "'Editor' expected"
        );
        lua_pop(lapi::state.state(), 1);

        (*edp)->clear(init);
    }

#else
    LAPI_EMPTY(textlist)
    LAPI_EMPTY(textshow)
    LAPI_EMPTY(textfocus)
    LAPI_EMPTY(textprev)
    LAPI_EMPTY(textmode)
    LAPI_EMPTY(textsave)
    LAPI_EMPTY(textinit)
    LAPI_EMPTY(textcopy)
    LAPI_EMPTY(textpaste)
    LAPI_EMPTY(textmark)
    LAPI_EMPTY(textselectall)
    LAPI_EMPTY(textclear)
    LAPI_EMPTY(textcurrentline)
    LAPI_EMPTY(textexec)

    LAPI_EMPTY(editor_use)
    LAPI_EMPTY(editor_focus)
    LAPI_EMPTY(editor_remove)
    LAPI_EMPTY(editor_current_get)

    LAPI_EMPTY(editor_mode_get)
    LAPI_EMPTY(editor_mode_set)
    LAPI_EMPTY(editor_linewrap_get)
    LAPI_EMPTY(editor_linewrap_set)
    LAPI_EMPTY(editor_maxx_get)
    LAPI_EMPTY(editor_maxx_set)
    LAPI_EMPTY(editor_maxy_get)
    LAPI_EMPTY(editor_maxy_set)
    LAPI_EMPTY(editor_pixelwidth_get)
    LAPI_EMPTY(editor_pixelwidth_set)
    LAPI_EMPTY(editor_pixelheight_get)
    LAPI_EMPTY(editor_pixelheight_set)
    LAPI_EMPTY(editor_mx_get)
    LAPI_EMPTY(editor_mx_set)
    LAPI_EMPTY(editor_my_get)
    LAPI_EMPTY(editor_my_set)
    LAPI_EMPTY(editor_cx_get)
    LAPI_EMPTY(editor_cx_set)
    LAPI_EMPTY(editor_cy_get)
    LAPI_EMPTY(editor_cy_set)
    LAPI_EMPTY(editor_scrolly_get)
    LAPI_EMPTY(editor_scrolly_set)
    LAPI_EMPTY(editor_line_get)
    LAPI_EMPTY(editor_draw)
    LAPI_EMPTY(editor_hit)
    LAPI_EMPTY(editor_mark)
    LAPI_EMPTY(editor_key)
    LAPI_EMPTY(editor_clear)
#endif

    void reg_textedit(lua::Table& t)
    {
        LAPI_REG(textlist);
        LAPI_REG(textshow);
        LAPI_REG(textfocus);
        LAPI_REG(textprev);
        LAPI_REG(textmode);
        LAPI_REG(textsave);
        LAPI_REG(textinit);
        LAPI_REG(textcopy);
        LAPI_REG(textpaste);
        LAPI_REG(textmark);
        LAPI_REG(textselectall);
        LAPI_REG(textclear);
        LAPI_REG(textcurrentline);
        LAPI_REG(textexec);

        LAPI_REG(editor_use);
        LAPI_REG(editor_focus);
        LAPI_REG(editor_remove);
        LAPI_REG(editor_current_get);

        LAPI_REG(editor_mode_get);
        LAPI_REG(editor_mode_set);
        LAPI_REG(editor_linewrap_get);
        LAPI_REG(editor_linewrap_set);
        LAPI_REG(editor_maxx_get);
        LAPI_REG(editor_maxx_set);
        LAPI_REG(editor_maxy_get);
        LAPI_REG(editor_maxy_set);
        LAPI_REG(editor_pixelwidth_get);
        LAPI_REG(editor_pixelwidth_set);
        LAPI_REG(editor_pixelheight_get);
        LAPI_REG(editor_pixelheight_set);
        LAPI_REG(editor_mx_get);
        LAPI_REG(editor_mx_set);
        LAPI_REG(editor_my_get);
        LAPI_REG(editor_my_set);
        LAPI_REG(editor_cx_get);
        LAPI_REG(editor_cx_set);
        LAPI_REG(editor_cy_get);
        LAPI_REG(editor_cy_set);
        LAPI_REG(editor_scrolly_get);
        LAPI_REG(editor_scrolly_set);
        LAPI_REG(editor_line_get);
        LAPI_REG(editor_draw);
        LAPI_REG(editor_hit);
        LAPI_REG(editor_mark);
        LAPI_REG(editor_key);
        LAPI_REG(editor_clear);
    }
}

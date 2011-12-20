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
        if (!top) return lua::Object();

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

        return lua::Object();
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
        if (!top) return lua::Object();

        if (i)
        {
            top->mode = i;
            return lua::Object();
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
        if (!top) return lua::Object();

        if (fn && fn[0])
        {
            top->setfile(path(fn, true));
            top->load();
            return lua::Object();
        }
        else if (top->filename)
            return lapi::state.wrap<lua::Object>(top->filename);

        return lua::Object();
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
            ed && ed->rendered && !ed->filename && s1 &&
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
 
    #define PASTEBUFFER "#pastebuffer"

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
        if (!top) return lua::Object();

        editor *b = useeditor(PASTEBUFFER, EDITORFOREVER, false);
        top->insertallfrom(b);
        if (i)
        {
            top->mark(i == 1);
            return lua::Object();
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
        if (!top) return lua::Object();

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
    }
}

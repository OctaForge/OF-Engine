/*
 * luabind_textedit.hpp, version 1
 * Cube 2 text editor system embedding
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

namespace lua_binds
{
    #define LUA_BIND_TEXT(n, c) \
    LUA_BIND_CLIENT(n, { \
        editor *top = currentfocus(); \
        if (!top) return; \
        c \
    })

    // return list of all editors
    LUA_BIND_CLIENT(textlist, {
        string s = "";
        loopv(editors)
        {
            if(i > 0) concatstring(s, ", ");
            concatstring(s, editors[i]->name);
        }
        e.push(s);
    })

    // return the start of the buffer
    LUA_BIND_TEXT(textshow, {
        editline line;
        line.combinelines(top->lines);
        e.push(line.text);
        line.clear();
    })

    // focus on a (or create a persistent) specific editor, else returns current name
    LUA_BIND_CLIENT(textfocus, {
        if (e.is<const char*>(1))
        {
            int arg2 = e.get<int>(2);
            useeditor(e.get<const char*>(1), arg2 <= 0 ? EDITORFOREVER : arg2, true);
        }
        else if (editors.length() > 0) e.push(editors.last()->name);
        else e.push();
    })

    // return to the previous editor
    LUA_BIND_TEXT(textprev, editors.insert(0, top); editors.pop();)

    // (1 = keep while focused, 2 = keep while used in gui, 3 = keep forever (i.e. until mode changes)) topmost editor, return current setting if no args
    LUA_BIND_TEXT(textmode, {
        int arg1 = e.get<int>(2);
        if (arg1)
        {
            top->mode = arg1;
            e.push();
        }
        else e.push(top->mode);
    })

    // saves the topmost (filename is optional)
    LUA_BIND_TEXT(textsave, {
        const char *arg1 = e.get<const char*>(1);
        if (arg1) top->setfile(path(arg1, true));
        top->save();
    })

    LUA_BIND_TEXT(textload, {
        const char *arg1 = e.get<const char*>(1);
        if (arg1)
        {
            top->setfile(path(arg1, true));
            top->load();
            e.push();
        }
        else if (top->filename) e.push(top->filename);
        else e.push();
    })

    LUA_BIND_TEXT(textinit, {
        editor *ed = NULL;
        const char *arg2 = e.get<const char*>(2);
        loopv(editors) if(!strcmp(e.get<const char*>(1), editors[i]->name))
        {
            ed = editors[i];
            break;
        }
        if(ed && ed->rendered && !ed->filename && arg2 && (ed->lines.empty() || (ed->lines.length() == 1 && !strcmp(e.get<const char*>(3), ed->lines[0].text))))
        {
            ed->setfile(path(arg2, true));
            ed->load();
        }
    })
 
    #define PASTEBUFFER "#pastebuffer"

    LUA_BIND_TEXT(textcopy, editor *b = useeditor(PASTEBUFFER, EDITORFOREVER, false); top->copyselectionto(b);)

    LUA_BIND_TEXT(textpaste, editor *b = useeditor(PASTEBUFFER, EDITORFOREVER, false); top->insertallfrom(b);)

    LUA_BIND_TEXT(textmark, {
        editor *b = useeditor(PASTEBUFFER, EDITORFOREVER, false); top->insertallfrom(b);
        int arg1 = e.get<int>(1);
        if (arg1)
        {
            top->mark(arg1 == 1);
            e.push();
        }
        else e.push(top->region() ? 1 : 2);
    })

    LUA_BIND_TEXT(textselectall, top->selectall();)

    LUA_BIND_TEXT(textclear, top->clear();)

    LUA_BIND_TEXT(textcurrentline, e.push(top->currentline().text);)

    LUA_BIND_TEXT(textexec, e.exec(e.get<int>(1) ? top->selectiontostring() : top->tostring());)
}

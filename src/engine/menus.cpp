// menus.cpp: ingame menu system (also used for scores and serverlist)

#include "engine.h"

#define GUI_TITLE_COLOR  0xFFDD88
#define GUI_BUTTON_COLOR 0xFFFFFF
#define GUI_TEXT_COLOR   0xBDBDBD

static vec menupos;
static int menustart = 0;
static int menutab = 1;
static g3d_gui *cgui = NULL;

struct menu : g3d_callback
{
    char *name, *header, *onclear;
    int contents_ref;

    menu() : name(NULL), header(NULL), onclear(NULL), contents_ref(0) {}

    void gui(g3d_gui &g, bool firstpass)
    {
        cgui = &g;
        cgui->start(menustart, 0.03f, &menutab);
        cgui->tab(header ? header : name, GUI_TITLE_COLOR);
        lua::engine.getref(contents_ref).call(0, 0);
        cgui->end();
        cgui = NULL;
    }

    virtual void clear() 
    {
        DELETEA(onclear);
    }
};

class delayedupdate
{
private:
    enum
    {
        INT,
        FLOAT,
        STRING,
        ACTION
    } type;

    var::cvar *var;
    union dval_t
    {
        int i;
        float f;
        char *s;
    } val;

public:
    delayedupdate(): type(ACTION), var(NULL) { val.s = NULL; }
    ~delayedupdate() { if(type == STRING || type == ACTION) DELETEA(val.s); }

    void schedule(const char *s)
    {
        type = ACTION;
        val.s = newstring(s);
    }
    void schedule(var::cvar *v, int i)
    {
        type = INT;
        var = v;
        val.i = i;
    }
    void schedule(var::cvar *v, float f)
    {
        type = FLOAT;
        var = v;
        val.f = f;
    }
    void schedule(var::cvar *v, const char *s)
    {
        type = STRING;
        var = v;
        val.s = newstring(s);
    }

    int gi()
    {
        switch (type)
        {
            case INT:
            case FLOAT:
            case STRING: return val.i;
            default: return 0;
        }
    }

    float gf()
    {
        switch (type)
        {
            case INT:
            case FLOAT:
            case STRING: return val.f;
            default: return 0;
        }
    }

    const char *gs()
    {
        switch (type)
        {
            case INT:
            case FLOAT:
            case STRING: return val.s;
            default: return NULL;
        }
    }

    void run()
    {
        if (type == ACTION)
        {
            if (val.s) lua::engine.exec(val.s);
        }
        else if (var) switch (var->type)
        {
            case var::VAR_I: var->set(gi(), true, true); break;
            case var::VAR_F: var->set(gf(), true, true); break;
            case var::VAR_S: var->set(gs(), true); break;
        }
    }
};

static vector<delayedupdate> updatelater;
static hashtable<const char *, menu> guis;
static vector<menu *> guistack;
static bool shouldclearmenu = true, clearlater = false;

VARP(menudistance,  16, 40,  256);
VARP(menuautoclose, 32, 120, 4096);

vec menuinfrontofplayer()
{ 
    vec dir;
    vecfromyawpitch(camera1->yaw, 0, 1, 0, dir);
    dir.mul(menudistance).add(camera1->o);
    dir.z -= player->eyeheight-1;
    return dir;
}

void popgui()
{
    menu *m = guistack.pop();
    m->clear();
}

void removegui(menu *m)
{
    loopv(guistack) if(guistack[i]==m)
    {
        guistack.remove(i);
        m->clear();
        return;
    }
}

void pushgui(menu *m, int pos = -1)
{
    if(guistack.empty())
    {
        menupos = menuinfrontofplayer();
        g3d_resetcursor();
    }
    if(pos < 0) guistack.add(m);
    else guistack.insert(pos, m);
    if(pos < 0 || pos==guistack.length()-1)
    {
        menutab = 1;
        menustart = totalmillis;
    }
}

void restoregui(int pos)
{
    int clear = guistack.length()-pos-1;
    loopi(clear) popgui();
    menutab = 1;
    menustart = totalmillis;
}

void showgui(const char *name)
{
    menu *m = guis.access(name);
    if(!m) return;
    int pos = guistack.find(m);
    if(pos<0) pushgui(m);
    else restoregui(pos);
}

int cleargui(int n)
{
    int clear = guistack.length();
    if(mainmenu && !isconnected(true) && clear > 0 && guistack[0]->name && !strcmp(guistack[0]->name, "main")) 
    {
        clear--;
        if(!clear) return 1;
    }
    if(n>0) clear = min(clear, n);
    loopi(clear) popgui(); 
    if(!guistack.empty()) restoregui(guistack.length()-1);
    return clear;
}

void guionclear(char *action)
{
    if(guistack.empty()) return;
    menu *m = guistack.last();
    DELETEA(m->onclear);
    if(action[0]) m->onclear = newstring(action);
}

void guistayopen(int fref)
{
    bool oldclearmenu = shouldclearmenu;
    shouldclearmenu = false;
    lua::engine.getref(fref).call(0, 0);
    lua::engine.unref(fref);
    shouldclearmenu = oldclearmenu;
}

void guinoautotab(int fref)
{
    if(!cgui) return;
    cgui->allowautotab(false);
    lua::engine.getref(fref).call(0, 0);
    lua::engine.unref(fref);
    cgui->allowautotab(true);
}

//@DOC name and icon are optional
void guibutton(char *name, char *action, char *icon)
{
    if(!cgui) return;
    bool hideicon = (icon ? !strcmp(icon, "0") : false);
    int ret = cgui->button(name, GUI_BUTTON_COLOR, hideicon ? NULL : (icon ? icon : (strstr(action, "showgui") ? "menu" : "action")));
    if(ret&G3D_UP) 
    {
        updatelater.add().schedule(action[0] ? action : name);
        if(shouldclearmenu) clearlater = true;
    }
}

void guiimage(char *path, char *action, float *scale, int *overlaid, char *alt)
{
    if(!cgui) return;
    Texture *t = textureload(path, 0, true, false);
    if(t==notexture)
    {
        if(alt[0]) t = textureload(alt, 0, true, false);
        if(t==notexture) return;
    }
    int ret = cgui->image(t, *scale, *overlaid!=0);
    if(ret&G3D_UP)
    {
        if(*action)
        {
            updatelater.add().schedule(action);
            if(shouldclearmenu) clearlater = true;
        }
    }
}

void guicolor(int *color)
{
    if(cgui) 
    {   
        defformatstring(desc)("0x%06X", *color);
        cgui->text(desc, *color, NULL);
    }
}

void guitextbox(char *text, int *width, int *height, int *color)
{
    if(cgui && text[0]) cgui->textbox(text, *width ? *width : 12, *height ? *height : 1, *color ? *color : 0xFFFFFF);
}

void guitext(char *name, char *icon)
{
    bool hideicon = (icon ? !strcmp(icon, "0") : false);
    if(cgui) cgui->text(name, !hideicon && icon ? GUI_BUTTON_COLOR : GUI_TEXT_COLOR, hideicon ? NULL : (icon ? icon : "info"));
}

void guititle(char *name)
{
    if(cgui) cgui->title(name, GUI_TITLE_COLOR);
}

void guitab(char *name)
{
    if(cgui) cgui->tab(name, GUI_TITLE_COLOR);
}

void guibar()
{
    if(cgui) cgui->separator();
}

void guistrut(float *strut, int *alt)
{
    if(cgui)
    {
        if(!*alt) cgui->pushlist();
        cgui->strut(*strut);
        if(!*alt) cgui->poplist();
    }
}

template<class T> static void updateval(const char *var, T val, const char *onchange)
{
    // try to lookup the variable in map too
    var::cvar *ev = var::get(var);
    // when creating new, that means it should also get pushed into storage, and here we have to do it manually
    // registering into storage will also take care of further memory release
    if (!ev) ev = var::regvar(var, new var::cvar(var, val));

    updatelater.add().schedule(ev, val);
    if(onchange && onchange[0]) updatelater.add().schedule(onchange);
}

static int getval(char *var)
{
    if (!var::get(var)) return 0;
    else
    {
        var::cvar *ev = var::get(var);
        switch (ev->type)
        {
            case var::VAR_I: return ev->curv.i; break;
            case var::VAR_F: return (int)ev->curv.f; break;
            case var::VAR_S: return 0; break;
        }
    }
    return 0;
}

static float getfval(char *var)
{
    if (!var::get(var)) return 0;
    else
    {
        var::cvar *ev = var::get(var);
        switch (ev->type)
        {
            case var::VAR_I: return (float)ev->curv.i; break;
            case var::VAR_F: return ev->curv.f; break;
            case var::VAR_S: return 0; break;
        }
    }
    return 0;
}

static const char *getsval(char *var)
{
    if (!var::get(var)) return "";
    else
    {
        var::cvar *ev = var::get(var);
        string ret;
        switch (ev->type)
        {
            case var::VAR_I: formatstring(ret)("%d", ev->curv.i); break;
            case var::VAR_F: formatstring(ret)("%f", ev->curv.i); break;
            case var::VAR_S: formatstring(ret)("%s", ev->curv.s); break;
            default: formatstring(ret)(""); break;
        }
        return newstring(ret);
    }
    return "";
}

void guislider(char *var, int *min, int *max, char *onchange)
{
    if(!cgui) return;
    int oldval = getval(var), val = oldval, vmin = *max ? *min : var::get(var)->minv.i, vmax = *max ? *max : var::get(var)->maxv.i;
    cgui->slider(val, vmin, vmax, GUI_TITLE_COLOR);
    if(val != oldval) updateval(var, val, onchange);
}

void guilistslider(char *var, char *list, char *onchange)
{
    if(!cgui) return;
    vector<int> vals;
    list += strspn(list, "\n\t ");
    while(*list)
    {
        vals.add(int(strtol(list, NULL, 0)));
        list += strcspn(list, "\n\t \0");
        list += strspn(list, "\n\t ");
    }
    if(vals.empty()) return;
    int val = getval(var), oldoffset = vals.length()-1, offset = oldoffset;
    loopv(vals) if(val <= vals[i]) { oldoffset = offset = i; break; }
    defformatstring(label)("%d", val);
    cgui->slider(offset, 0, vals.length()-1, GUI_TITLE_COLOR, label);
    if(offset != oldoffset) updateval(var, vals[offset], onchange);
}

// TODO: moved from old command.cpp, remove (with new UI)
#define whitespaceskip s += strspn(s, "\n\t ")
#define elementskip *s=='"' ? (++s, s += strcspn(s, "\"\n\0"), s += *s=='"') : s += strcspn(s, "\n\t \0")

char *indexlist(const char *s, int pos)
{
    whitespaceskip;
    loopi(pos)
    {
        elementskip;
        whitespaceskip;
        if(!*s) break;
    }
    const char *e = s;
    elementskip;
    if(*e=='"')
    {
        e++;
        if(s[-1]=='"') --s;
    }
    return newstring(e, s-e);
}

void guinameslider(char *var, char *names, char *list, char *onchange)
{
    if(!cgui) return;
    vector<int> vals;
    list += strspn(list, "\n\t ");
    while(*list)
    {
        vals.add(int(strtol(list, NULL, 0)));
        list += strcspn(list, "\n\t \0");
        list += strspn(list, "\n\t ");
    }
    if(vals.empty()) return;
    int val = getval(var), oldoffset = vals.length()-1, offset = oldoffset;
    loopv(vals) if(val <= vals[i]) { oldoffset = offset = i; break; }
    char *label = indexlist(names, offset);
    cgui->slider(offset, 0, vals.length()-1, GUI_TITLE_COLOR, label);
    if(offset != oldoffset) updateval(var, vals[offset], onchange);
    delete[] label;
}

void guicheckbox(char *name, char *var, float *on, float *off, char *onchange)
{
    bool enabled = getfval(var)!=*off;
    if(cgui && cgui->button(name, GUI_BUTTON_COLOR, enabled ? "checkbox_on" : "checkbox_off")&G3D_UP)
    {
        updateval(var, enabled ? *off : (*on || *off ? *on : 1.0f), onchange);
    }
}

void guiradio(char *name, char *var, float *n, char *onchange)
{
    bool enabled = getfval(var)==*n;
    if(cgui && cgui->button(name, GUI_BUTTON_COLOR, enabled ? "radio_on" : "radio_off")&G3D_UP)
    {
        if(!enabled) updateval(var, *n, onchange);
    }
}

void guibitfield(char *name, char *var, int *mask, char *onchange)
{
    int val = getval(var);
    bool enabled = (val & *mask) != 0;
    if(cgui && cgui->button(name, GUI_BUTTON_COLOR, enabled ? "checkbox_on" : "checkbox_off")&G3D_UP)
    {
        updateval(var, enabled ? val & ~*mask : val | *mask, onchange);
    }
}

//-ve length indicates a wrapped text field of any (approx 260 chars) length, |length| is the field width
void guifield(char *var, int *maxlength, char *onchange, int *password) // INTENSITY: password
{   
    if(!cgui) return;
    const char *initval = getsval(var);
    char *result = cgui->field(var, GUI_BUTTON_COLOR, *maxlength ? *maxlength : 12, 0, initval, EDITORFOCUSED, password ? *password : false); // INTENSITY: password, and the default value before it - EDITORFOCUSED - also, as it is needed now
    if(result) updateval(var, result, onchange);
}

//-ve maxlength indicates a wrapped text field of any (approx 260 chars) length, |maxlength| is the field width
void guieditor(char *name, int *maxlength, int *height, int *mode)
{
    if(!cgui) return;
    cgui->field(name, GUI_BUTTON_COLOR, *maxlength ? *maxlength : 12, *height, NULL, *mode<=0 ? EDITORFOREVER : *mode);
    //returns a non-NULL pointer (the currentline) when the user commits, could then manipulate via text* commands
}

//-ve length indicates a wrapped text field of any (approx 260 chars) length, |length| is the field width
void guikeyfield(char *var, int *maxlength, char *onchange)
{
    if(!cgui) return;
    const char *initval = getsval(var);
    char *result = cgui->keyfield(var, GUI_BUTTON_COLOR, *maxlength ? *maxlength : -8, 0, initval);
    if(result) updateval(var, result, onchange);
}

//use text<action> to do more...


void guilist(int fref)
{
    if(!cgui) return;
    cgui->pushlist();
    lua::engine.getref(fref).call(0, 0);
    lua::engine.unref(fref);
    cgui->poplist();
}

void guialign(int *align, int fref)
{
    if(!cgui) return;
    cgui->pushlist(clamp(*align, -1, 1));
    lua::engine.getref(fref).call(0, 0);
    lua::engine.unref(fref);
    cgui->poplist();
}

void newgui(char *name, int fref, char *header)
{
    menu *m = guis.access(name);
    if(!m)
    {
        name = newstring(name);
        m = &guis[name];
        m->name = name;
    }
    else
    {
        DELETEA(m->header);
        lua::engine.unref(m->contents_ref);
    }
    m->header = header && header[0] ? newstring(header) : NULL;
    m->contents_ref = fref;
}

struct change
{
    int type;
    const char *desc;

    change() {}
    change(int type, const char *desc) : type(type), desc(desc) {}
};
static vector<change> needsapply;

static struct applymenu : menu
{
    void gui(g3d_gui &g, bool firstpass)
    {
        if(guistack.empty()) return;
        g.start(menustart, 0.03f);
        g.text("the following settings have changed:", GUI_TEXT_COLOR, "info");
        loopv(needsapply) g.text(needsapply[i].desc, GUI_TEXT_COLOR, "info");
        g.separator();
        g.text("apply changes now?", GUI_TEXT_COLOR, "info");
        if(g.button("yes", GUI_BUTTON_COLOR, "action")&G3D_UP)
        {
            int changetypes = 0;
            loopv(needsapply) changetypes |= needsapply[i].type;
            if(changetypes&CHANGE_GFX) updatelater.add().schedule("engine.resetgl()");
            if(changetypes&CHANGE_SOUND) updatelater.add().schedule("sound.reset()");
            clearlater = true;
        }
        if(g.button("no", GUI_BUTTON_COLOR, "action")&G3D_UP)
            clearlater = true;
        g.end();
    }

    void clear()
    {
        menu::clear();
        needsapply.shrink(0);
    }
} applymenu;

VARP(applydialog, 0, 1, 1);

static bool processingmenu = false;

void addchange(const char *desc, int type)
{
    if(!applydialog) return;
    loopv(needsapply) if(!strcmp(needsapply[i].desc, desc)) return;
    needsapply.add(change(type, desc));
    if(needsapply.length() && guistack.find(&applymenu) < 0)
        pushgui(&applymenu, processingmenu ? max(guistack.length()-1, 0) : -1);
}

void clearchanges(int type)
{
    loopv(needsapply)
    {
        if(needsapply[i].type&type)
        {
            needsapply[i].type &= ~type;
            if(!needsapply[i].type) needsapply.remove(i--);
        }
    }
    if(needsapply.empty()) removegui(&applymenu);
}

void menuprocess()
{
    processingmenu = true;
    int wasmain = mainmenu, level = guistack.length();
    loopv(updatelater) updatelater[i].run();
    updatelater.shrink(0);
    
    if(wasmain > mainmenu || clearlater)
    {
        if(wasmain > mainmenu || level==guistack.length()) 
        {
            loopvrev(guistack)
            {
                menu *m = guistack[i];
                if(m->onclear) 
                {
                    char *action = m->onclear;
                    m->onclear = NULL;
                    lua::engine.exec(action);
                    delete[] action;
                }
            }
            cleargui(level); 
        }
        clearlater = false;
    }
    if(mainmenu && !isconnected(true) && guistack.empty()) showgui("main");
    processingmenu = false;
}

VAR(mainmenu, 1, 1, 0);

void clearmainmenu()
{
    if(mainmenu && (isconnected() || haslocalclients()))
    {
        mainmenu = 0;
        if(!processingmenu) cleargui();
    }
}

void g3d_mainmenu()
{
    if(!guistack.empty()) 
    {
        extern int& usegui2d;
        if(!mainmenu && !usegui2d && camera1->o.dist(menupos) > menuautoclose) cleargui();
        else g3d_addgui(guistack.last(), menupos, GUI_2D | GUI_FOLLOW);
    }
}

VAR(fonth, 512, 0, 0);

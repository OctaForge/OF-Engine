
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"

#include <map>

using namespace boost;


//==================================
// Utilities. Many of these will
// simply use boost/python for now,
// but we can replace them with
// suitable portable specific
// things later
//==================================


std::string Utility::SHA256(std::string text)
{
    EXEC_PYTHON("import hashlib");

    REFLECT_PYTHON_ALTNAME(hashlib.sha256, hashlib_sha256);

    return python::extract<std::string>( hashlib_sha256(text).attr("hexdigest")() );
}

//==============================
// String utils
//==============================

std::string Utility::toString(std::string val)
{
    return val;
}

#define TO_STRING(type)                  \
std::string Utility::toString(type val)  \
{                                        \
    std::stringstream ss;                \
    std::string ret;                     \
    ss << val;                           \
    return ss.str();                     \
}

TO_STRING(int)
TO_STRING(long)
TO_STRING(double)

bool Utility::validateAlphaNumeric(std::string input, std::string alsoAllow)
{
    EXEC_PYTHON("import re");

    REFLECT_PYTHON_ALTNAME( re.escape, re_escape);

    python::object original = python::object(input);
    for (unsigned int i = 0; i < alsoAllow.size(); i++)
    {
        original = original.attr("replace")(alsoAllow[i], ""); // Ignore the alsoAllow chars
    }

    python::object test = re_escape(original);

    bool ret = (test == original); // After escaping all non-alphanumeric, must be no change

    if (!ret)
        Logging::log(Logging::WARNING, "Validation of %s failed (using alphanumeric + %s)\r\n", input.c_str(), alsoAllow.c_str());

    return ret;
}

bool Utility::validateNotContaining(std::string input, std::string disallow)
{
    python::object original = python::object(input);
    int index = python::extract<int>(original.attr("find")(disallow));
    return index == -1; // -1 means it wasn't found, which is ok
}

bool Utility::validateRelativePath(std::string input)
{
    REFLECT_PYTHON( validate_relative_path );
    return python::extract<bool>(validate_relative_path(input));
}

std::string Utility::readFile(std::string name)
{
    REFLECT_PYTHON( open );
    try
    {
        python::object data = open(name, "r").attr("read")();
        return python::extract<std::string>(data);
    }
    catch(boost::python::error_already_set const &)
    {
        printf("Error in Python execution of readFile\r\n");
        PyErr_Print();
        assert(0 && "Halting on Python error");
        throw;
    }
}

bool Utility::config_exec_json(const char *cfgfile, bool msg)
{
    string s;
    copystring(s, cfgfile);
    char *buf = loadfile(path(s), NULL);
    if(!buf)
    {
        if(msg) conoutf(CON_ERROR, "could not read \"%s\"", s);
        return false;
    }
    // let's parse!
    JSONValue *value = JSON::Parse(buf);
    // we can delete buf now. It's all safely stored in JSONValue.
    delete[] buf;

    if (value == NULL)
    {
        if(msg) conoutf(CON_ERROR, "could not load \"%s\"", s);
        return false;
    }
    else
    {
        JSONObject root;
        if (value->IsObject() == false)
        {
            if(msg) conoutf(CON_ERROR, "could not load JSON root object.");
            return false;
        }
        else
        {
            root = value->AsObject();
            if (root.find(L"crosshairs") != root.end() && root[L"crosshairs"]->IsObject())
            {
                JSONObject crls = root[L"crosshairs"]->AsObject();
                for (JSONObject::const_iterator criter = crls.begin(); criter != crls.end(); ++criter)
                {
                    defformatstring(aliasc)("CAPI.loadcrosshair(\"%s\", %i)", fromwstring(criter->first).c_str(), (int)criter->second->AsNumber());
                    lua::engine.exec(aliasc);
                }
            }
            if (root.find(L"variables") != root.end() && root[L"variables"]->IsObject())
            {
                JSONObject vars = root[L"variables"]->AsObject();
                for (JSONObject::const_iterator viter = vars.begin(); viter != vars.end(); ++viter)
                {
                    var::cvar *v = var::get(fromwstring(viter->first).c_str());
                    if (v)
                    {
                        switch (v->gt())
                        {
                            case var::VAR_I: v->s((int)viter->second->AsNumber()); break;
                            case var::VAR_F: v->s((float)viter->second->AsNumber()); break;
                            case var::VAR_S: v->s(fromwstring(viter->second->AsString()).c_str()); break;
                        }
                    }
                }
            }
            if (root.find(L"binds") != root.end() && root[L"binds"]->IsObject())
            {
                JSONObject bnds = root[L"binds"]->AsObject();
                for (JSONObject::const_iterator biter = bnds.begin(); biter != bnds.end(); ++biter)
                {
                    JSONObject bnd = biter->second->AsObject();
                    for (JSONObject::const_iterator biiter = bnd.begin(); biiter != bnd.end(); ++biiter)
                    {
                        defformatstring(bindcmd)("CAPI.%s(\"%s\", [[%s]])", fromwstring(biiter->first).c_str(), fromwstring(biter->first).c_str(), fromwstring(biiter->second->AsString()).c_str());
                        lua::engine.exec(bindcmd);
                    }
                }
            }
            if (root.find(L"aliases") != root.end() && root[L"aliases"]->IsObject())
            {
                JSONObject als = root[L"aliases"]->AsObject();
                for (JSONObject::const_iterator aiter = als.begin(); aiter != als.end(); ++aiter)
                {
                    defformatstring(aliasc)("%s = \"%s\"", fromwstring(aiter->first).c_str(), fromwstring(aiter->second->AsString()).c_str());
                    lua::engine.exec(aliasc);
                }
            }
            // TODO: completions
            /*
            if (root.find(L"completions") != root.end() && root[L"completions"]->IsObject())
            {
                JSONObject cmpl = root[L"completions"]->AsObject();
                for (JSONObject::const_iterator citer = cmpl.begin(); citer != cmpl.end(); ++citer)
                {
                    if (fromwstring(citer->first) == "listcomplete")
                    {
                        std::string cmpl;
                        JSONArray cfa = citer->second->AsArray();
                        JSONArray cfaa = cfa[1]->AsArray();
                        for (unsigned int cfai = 0; cfai < cfaa.size(); cfai++)
                        {
                            cmpl += fromwstring(cfaa[cfai]->AsString());
                            if ((cfai + 1) != cfaa.size()) cmpl += " ";
                        }
                        defformatstring(listcmplcmd)("listcomplete \"%s\" [%s]", fromwstring(cfa[0]->AsString()).c_str(), cmpl.c_str());
                        execute(listcmplcmd);
                    }
                    else
                    {
                        JSONArray cfa = citer->second->AsArray();
                        defformatstring(cmplcmd)("complete \"%s\" \"%s\" \"%s\"", fromwstring(cfa[0]->AsString()).c_str(), fromwstring(cfa[1]->AsString()).c_str(), fromwstring(cfa[2]->AsString()).c_str());
                        execute(cmplcmd);
                    }
                }
            }*/
        }
    }
    delete value;
    return true;
}

JSONObject writebinds();
JSONObject writecrosshairs();
JSONObject writecompletions();

static int sortvars(var::cvar **x, var::cvar **y)
{
    return strcmp((*x)->gn(), (*y)->gn());
}

void Utility::writecfg(const char *name)
{
    JSONObject root, vars, aliases, complet, bnds, crossh; // clientinfo;
    vector<var::cvar*> varv;
    stream *f = openfile(path(name && name[0] ? name : game::savedconfig(), true), "w");
    if(!f) return;

    //clientinfo = game::writeclientinfo();
    //root[L"clientinfo"] = new JSONValue(clientinfo);

    crossh = writecrosshairs();
    if (!crossh.empty()) root[L"crosshairs"] = new JSONValue(crossh);

    enumerate(*var::vars, var::cvar*, v, varv.add(v));
    varv.sort(sortvars);
    loopv(varv)
    {
        var::cvar *v = varv[i];
        if (v->ispersistent()) switch(v->gt())
        {
            case var::VAR_I:
            {
                vars[towstring(v->gn())] = new JSONValue((double)v->gi());
                break;
            }
            case var::VAR_F:
            {
                vars[towstring(v->gn())] = new JSONValue(v->gf());
                break;
            }
            case var::VAR_S:
            {
                char *wval = (char*)malloc(1);
                const char *p = v->gs();
                for (int i = 0; *p; i++)
                {
                    switch(*p)
                    {
                        case '\n':
                        {
                            wval = (char*)realloc(wval, i + 3);
                            strcat(wval, "^n"); i++;
                            break;
                        }
                        case '\t':
                        {
                            wval = (char*)realloc(wval, i + 3);
                            strcat(wval, "^t"); i++;
                            break;
                        }
                        case '\f':
                        {
                            wval = (char*)realloc(wval, i + 3);
                            strcat(wval, "^f"); i++;
                            break;
                        }
                        case '"':
                        {
                            wval = (char*)realloc(wval, i + 3);
                            strcat(wval, "^\""); i++;
                            break;
                        }
                        default:
                        {
                            wval = (char*)realloc(wval, i + 2);
                            wval[i] = *p; wval[i+1] = '\0';
                            break;
                        }
                    }
                    p++;
                }
                vars[towstring(v->gn())] = new JSONValue(towstring(wval ? wval : ""));
                wval = NULL; free(wval);
                break;
            }
        }
    }
    if (!vars.empty()) root[L"variables"] = new JSONValue(vars);

    bnds = writebinds();
    if (!bnds.empty()) root[L"binds"] = new JSONValue(bnds);

    loopv(varv)
    {
        var::cvar *v = varv[i];
        if (v->isalias() && v->ispersistent() && !v->isoverriden() && v->gs()[0])
        {
            if (strstr(v->gn(), "new_entity_gui_field")) continue;
            aliases[towstring(v->gn())] = new JSONValue(towstring(v->gs()));
        }
    }
    if (!aliases.empty()) root[L"aliases"] = new JSONValue(aliases);

    complet = writecompletions();
    if (!complet.empty()) root[L"completions"] = new JSONValue(complet);

    JSONValue *value = new JSONValue(root);
    f->printf("%ls", value->Stringify().c_str());
    delete value;
    delete f;
}


//==============================
// Config file utilities
//==============================

// Caches for speed; no need to call Python every time
typedef std::map<std::string, std::string> ConfigCacheString;
typedef std::map<std::string, int> ConfigCacheInt;
typedef std::map<std::string, float> ConfigCacheFloat;

ConfigCacheString configCacheString;
ConfigCacheInt configCacheInt;
ConfigCacheFloat configCacheFloat;

inline std::string getCacheKey(std::string section, std::string option)
    { return section + "|" + option; };

#define GET_CONFIG(type, Name, python_type)                                           \
type pythonGet##Name(std::string section, std::string option, type defaultVal)        \
{                                                                                     \
    Logging::log(Logging::DEBUG, "Config cache fail, going to Python: %s/%s\r\n",     \
                 section.c_str(), option.c_str());                                    \
    REFLECT_PYTHON(get_config);                                                       \
    REFLECT_PYTHON_ALTNAME(python_type, ptype);                                       \
    return python::extract<type>( ptype( get_config(section, option, defaultVal) ) ); \
} \
\
type Utility::Config::get##Name(std::string section, std::string option, type defaultVal)\
{ \
    std::string cacheKey = getCacheKey(section, option);\
    ConfigCache##Name::iterator iter = configCache##Name.find(cacheKey);\
    if (iter != configCache##Name.end())\
        return iter->second;\
    else {\
        type value = pythonGet##Name(section, option, defaultVal); \
        configCache##Name[cacheKey] = value; \
        return value; \
    } \
}

GET_CONFIG(std::string, String, str)
GET_CONFIG(int,         Int,    int)
GET_CONFIG(float,       Float,  float)

#define SET_CONFIG(type, Name)                                                  \
void Utility::Config::set##Name(std::string section, std::string option, type value) \
{                                                                               \
    REFLECT_PYTHON(set_config);                                                 \
    set_config(section, option, value);                                         \
    std::string cacheKey = getCacheKey(section, option); \
    configCache##Name[cacheKey] = value; \
}

SET_CONFIG(std::string, String)
SET_CONFIG(int,         Int)
SET_CONFIG(float,       Float)


//==============================
// System Info
//==============================

extern int clockrealbase;

int Utility::SystemInfo::currTime()
{
#ifdef SERVER
    return enet_time_get();
#else // CLIENT
    return SDL_GetTicks() - clockrealbase;
#endif
// This old method only changes during calls to updateworld etc.!
//    extern int lastmillis;
//    return lastmillis; // We wrap around the sauer clock
}


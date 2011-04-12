
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include <queue>

#include <set>


// 'Background' loading system for texture slots

static std::set<int> requested_slots;

Slot &lookupslot(int index, bool load)
{
    Slot &s = slots.inrange(index) ? *slots[index] : (slots.inrange(DEFAULT_GEOM) ? *slots[DEFAULT_GEOM] : dummyslot);
    if (load && !s.loaded)
    {
        if (slots.inrange(index))
        {
            if (requested_slots.count(index) == 0)
            {
                requested_slots.insert(index);
                loopv(s.sts) s.sts[i].t = notexture; // Until we load them, do not crash in rendering code
            }
        } else
            loadslot(s, false);
    }
    return s;
}

namespace IntensityTexture
{

void resetBackgroundLoading()
{
    requested_slots.clear();
}

void doBackgroundLoading(bool all)
{
    while (requested_slots.size() > 0)
    {
        int slot = *(requested_slots.begin());
        requested_slots.erase(slot);

        assert(slots.inrange(slot));
        Slot &s = *slots[slot];
        loadslot(s, false); // for materials, would be true

        if (!all) break;
    }
}

// Publics

#define FIX_PATH(s) \
    s = "data/" + s; \
    static string __##s; \
    copystring(__##s, s.c_str()); \
    s = path(__##s); \
    if (!Utility::validateRelativePath(s)) { printf("Relative path not validated: %s\r\n", s.c_str()); assert(0); }; \
    std::string full_##s = findfile(s.c_str(), "wb");

void convertPNGtoDDS(std::string source, std::string dest)
{
    Logging::log(Logging::WARNING, "Creating DDS files should not be done in this way!\r\n");

    FIX_PATH(source);
    FIX_PATH(dest);

    REFLECT_PYTHON( check_newer_than );
    if (boost::python::extract<bool>(check_newer_than(full_dest, full_source)))
        return;

    Logging::log(Logging::DEBUG, "convertPNGtoDDS: %s ==> %s\r\n", source.c_str(), dest.c_str());

    renderprogress(0, ("preparing dds image: " + source).c_str());

    if (hasTC) 
        gendds((char*)source.c_str(), (char*)dest.c_str());
}

void combineImages(std::string primary, std::string secondary, std::string dest)
{
    FIX_PATH(primary);
    FIX_PATH(secondary);
    FIX_PATH(dest);

    REFLECT_PYTHON( check_newer_than );
    if (boost::python::extract<bool>(check_newer_than(full_dest, full_primary, full_secondary)))
        return;

    Logging::log(Logging::DEBUG, "combineImages: %s + %s ==> %s\r\n", primary.c_str(), secondary.c_str(), dest.c_str());

    renderprogress(0, ("combining image: " + full_dest).c_str());

    ImageData rgb, a;
    if(!loadimage(primary.c_str(), rgb)) return;
    assert(rgb.bpp == 3);
    if(!loadimage(secondary.c_str(), a)) return;
    assert(a.bpp == 1 || a.bpp == 3);

    if (a.w != rgb.w || a.h != rgb.h) scaleimage(a, rgb.w, rgb.h);

    mergespec(rgb, a);

    saveimage(dest.c_str(), guessimageformat(dest.c_str(), IMG_PNG), rgb);
}

void uploadTextureData(std::string name, int x, int y, int w, int h, void *pixels)
{
    Texture *t = textures.access(path(name.c_str(), true));
    if (!t)
    {
        Logging::log(Logging::WARNING, "uploadTextureData: %s is missing\r\n", name.c_str());
        return;
    }

    GLenum format = texformat(t->bpp);
    setuptexparameters(t->id, pixels, t->clamp, 1, format, GL_TEXTURE_2D);
/*
    glBindTexture(GL_TEXTURE_2D, t->id);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); //GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); //GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
*/

    glTexImage2D(GL_TEXTURE_2D, 0, format, t->w, t->h, 0, format, GL_UNSIGNED_BYTE, NULL);
    glTexSubImage2D (GL_TEXTURE_2D, 0, x, y, w, h, format, GL_UNSIGNED_BYTE, pixels);

/* FAIL:
    uchar *buf = new uchar[w*h*t->bpp];
    int currx = x, curry = y;
    int currw = w, currh = h;
    for (int level = 0; ; level++)
    {
        glTexImage2D(GL_TEXTURE_2D, level, format, t->w, t->h, 0, format, GL_UNSIGNED_BYTE, NULL);
        glTexSubImage2D (GL_TEXTURE_2D, level, x, y, currw, currh, format, GL_UNSIGNED_BYTE, level == 0 ? pixels : buf);

        currx /= 2; // using this causes hardware flicker
        curry /= 2;
        currw /= 2;
        currh /= 2;
        if((hasGM && hwmipmap) || max(currw, currh) <= 1) break;
        scaletexture((uchar*)pixels, w, h, t->bpp, 0, buf, currw, currh);
    }
    delete[] buf;
*/
}

}


/* teh ugly file of stubs */

#include "engine.h"

int thirdperson   = 0;
int gamespeed     = 0;
int envmapradius  = 0;
int showmat       = 0;
int outline       = 0;
int glversion     = 0;

void serverkeepalive()
{
    extern ENetHost *serverhost;
    if(serverhost)
        enet_host_service(serverhost, NULL, 0);
}

Texture *notexture = NULL;

Shader *Shader::lastshader = NULL;
void Shader::allocparams(Slot*) { assert(0); }
void Shader::bindprograms() { assert(0); };

void renderprogress(float bar, const char *text, GLuint tex, bool background)
{
    // Keep connection alive
    clientkeepalive();
    serverkeepalive();

    printf("|");
    for (int i = 0; i < 10; i++)
    {
        if (i < int(bar*10))
            printf("#");
        else
            printf("-");
    }
    printf("| %s\r", text);
    fflush(stdout);
}

bool printparticles(extentity &e, char *buf) { return true; };
void clearparticleemitters() { };

vec worldpos;
vec camdir;
dynent *player = NULL;
physent *camera1 = NULL;
float loadprogress = 0.333;
int xtraverts = 0;

bool hasVBO = false;

Shader *hudshader = NULL, *ldrnotextureshader = NULL;
bool inbetweenframes = false;
int explicitsky = 0;
vtxarray *visibleva = NULL;

void clearshadowcache() {}

void calcmatbb(vtxarray *va, int cx, int cy, int cz, int size, vector<materialsurface> &matsurfs) {}

void clearmapsounds() { };
void clearparticles() { };
void cleardecals() { };
void clearlights() { };
void clearlightcache(int e) { };
void initlights() { };
void setsurfaces(cube &c, const surfaceinfo *surfs, const vertinfo *verts, int numverts) { };
void setsurface(cube &c, int orient, const surfaceinfo &src, const vertinfo *srcverts, int numsrcverts) { };
void brightencube(cube &c) { };
Texture *textureload(const char *name, int clamp, bool mipit, bool msg) { return notexture; };
void renderbackground(const char *caption, Texture *mapshot, const char *mapname, const char *mapinfo, bool restore, bool force) { };
void writebinds(stream *f) { };
int isvisiblesphere(float rad, const vec &cv) { return 0; };
Shader *lookupshaderbyname(const char *name) { return NULL; };
Shader *useshaderbyname(const char *name) { return NULL; };
ushort closestenvmap(int orient, int x, int y, int z, int size) { return 0; };
void loadalphamask(Texture *t) { };

vector<VSlot *> vslots;

Slot &lookupslot(int index, bool load)
{
    static Slot sl;
    static Shader sh;
    sl.shader = &sh;
    return sl;
};

VSlot &lookupvslot(int index, bool load)
{
    static VSlot vsl;
    static Slot sl = lookupslot(0, 0);
    vsl.slot = &sl;
    return vsl;
}

VSlot *editvslot(const VSlot &src, const VSlot &delta)
{
    return &lookupvslot(0, 0);
}

void clearslots() { };
void compactvslots(cube *c, int n) { };
void compactvslot(int &index) { };
void mergevslot(VSlot &dst, const VSlot &src, const VSlot &delta) { };

const char *getshaderparamname(const char *name) { return ""; };

void setupmaterials(int start, int len) { };
int findmaterial(const char *name) { return 0; };
void enablepolygonoffset(GLenum type) { };
void disablepolygonoffset(GLenum type) { };
void genmatsurfs(const cube &c, int cx, int cy, int cz, int size, vector<materialsurface> &matsurfs) { };
void resetqueries() { };
void initenvmaps() { };
int optimizematsurfs(materialsurface *matbuf, int matsurfs) { return 0; };

glmatrix hudmatrix;

void pushhudmatrix() {};
void flushhudmatrix(bool flushparams) {};
void pophudmatrix(bool flush, bool flushparams) {};


#define VARRAY_INTERNAL
#include "varray.h"

#ifdef WINDOWS // needs stubs too, works for now
#include "GL/gl.h"
#else // stubs everywhere!
void glDepthFunc(GLenum func) {};
void glEnable(GLenum cap) {};
void glDisable(GLenum cap) {};
void glBindTexture(GLenum target, GLuint texture) {};
void glBlendFunc(GLenum sfactor, GLenum dfactor) {};
void glDrawArrays(GLenum mode, GLint first, GLsizei count) {};
#endif

PFNGLDELETEBUFFERSARBPROC         glDeleteBuffers_            = NULL;
PFNGLGENBUFFERSARBPROC            glGenBuffers_               = NULL;
PFNGLBINDBUFFERARBPROC            glBindBuffer_               = NULL;
PFNGLBUFFERDATAARBPROC            glBufferData_               = NULL;
PFNGLBUFFERSUBDATAPROC            glBufferSubData_            = NULL;
PFNGLVERTEXATTRIB3FPROC           glVertexAttrib3f_           = NULL;
PFNGLVERTEXATTRIB4FPROC           glVertexAttrib4f_           = NULL;
PFNGLVERTEXATTRIB4NUBPROC         glVertexAttrib4Nub_         = NULL;
PFNGLUNIFORM1FVPROC               glUniform1fv_               = NULL;
PFNGLUNIFORM2FVPROC               glUniform2fv_               = NULL;
PFNGLUNIFORM3FVPROC               glUniform3fv_               = NULL;
PFNGLUNIFORM4FVPROC               glUniform4fv_               = NULL;
PFNGLUNIFORM1IVPROC               glUniform1iv_               = NULL;
PFNGLUNIFORM2IVPROC               glUniform2iv_               = NULL;
PFNGLUNIFORM3IVPROC               glUniform3iv_               = NULL;
PFNGLUNIFORM4IVPROC               glUniform4iv_               = NULL;
PFNGLUNIFORMMATRIX2FVPROC         glUniformMatrix2fv_         = NULL;
PFNGLUNIFORMMATRIX3FVPROC         glUniformMatrix3fv_         = NULL;
PFNGLUNIFORMMATRIX4FVPROC         glUniformMatrix4fv_         = NULL;
PFNGLDRAWRANGEELEMENTSPROC        glDrawRangeElements_        = NULL;
PFNGLENABLEVERTEXATTRIBARRAYPROC  glEnableVertexAttribArray_  = NULL;
PFNGLDISABLEVERTEXATTRIBARRAYPROC glDisableVertexAttribArray_ = NULL;
PFNGLVERTEXATTRIBPOINTERPROC      glVertexAttribPointer_      = NULL;
PFNGLGENVERTEXARRAYSPROC          glGenVertexArrays_          = NULL;
PFNGLDELETEVERTEXARRAYSPROC       glDeleteVertexArrays_       = NULL;
PFNGLBINDVERTEXARRAYPROC          glBindVertexArray_          = NULL;

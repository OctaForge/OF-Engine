/* teh ugly file of stubs */

#include "engine.h"

int thirdperson   = 0;
int gamespeed     = 0;
int texdefscale   = 0;
int maxvsuniforms = 0;
int shadowmapping = 0;

int xtravertsva = 0;

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
int Shader::uniformlocversion() { return 0; };

int GlobalShaderParamState::nextversion = 0;
void GlobalShaderParamState::resetversions() {}
GlobalShaderParamState *getglobalparam(const char *name) { return NULL; };

void renderprogress(float bar, const char *text)
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

void clearparticleemitters() { };

vec worldpos;
dynent *player = NULL;
physent *camera1 = NULL;
float loadprogress = 0.333;

bool inbetweenframes = false;
int explicitsky = 0;
vtxarray *visibleva = NULL;

void clearshadowcache() {}

void calcmatbb(vtxarray *va, const ivec &co, int size, vector<materialsurface> &matsurfs) {}

void cleanupvolumetric() {};
void cleardeferredlightshaders() {};
void stopmapsounds() { };
void clearparticles() { };
void clearstains() { };
void clearlightcache(int e) { };
void initlights() { };
void setsurface(cube &c, int orient, const surfaceinfo &src, const vertinfo *srcverts, int numsrcverts) { };
void brightencube(cube &c) { };
Texture *textureload(const char *name, int clamp, bool mipit, bool msg) { return notexture; };
int isvisiblesphere(float rad, const vec &cv) { return 0; };
Shader *lookupshaderbyname(const char *name) { return NULL; };
ushort closestenvmap(int orient, const ivec &co, int size) { return 0; };
ushort closestenvmap(const vec &o) { return 0; };
GLuint lookupenvmap(ushort emid) { return 0; };
uchar *loadalphamask(Texture *t) { return NULL; };
Texture *cubemapload(const char *name, bool mipit, bool msg, bool transient) { return notexture; };

vector<VSlot *> vslots;

int Slot::cancombine(int type) const
{
    return -1;
}

const char *Slot::name() const { return "slot"; }

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

VSlot &Slot::emptyvslot()
{
    return lookupvslot(0, false);
}

VSlot *editvslot(const VSlot &src, const VSlot &delta)
{
    return &lookupvslot(0, 0);
}

void clearslots() {};
void compactvslots(cube *c, int n) {};
void compactvslot(int &index) {};
void compactvslot(VSlot &vs) {};
void mergevslot(VSlot &dst, const VSlot &src, const VSlot &delta) {};
VSlot *findvslot(Slot &slot, const VSlot &src, const VSlot &delta) { return &lookupvslot(0, 0); }

void packvslot(vector<uchar> &buf, const VSlot &src) {}
void packvslot(vector<uchar> &buf, int index) {}
void packvslot(vector<uchar> &buf, const VSlot *vs) {}
bool unpackvslot(ucharbuf &buf, VSlot &dst, bool delta) { return true; }

bool shouldreuseparams(Slot &s, VSlot &p) { return true; }

const char *DecalSlot::name() const { return "decal slot"; }

DecalSlot &lookupdecalslot(int index, bool load)
{
    static DecalSlot ds;
    return ds;
}

int DecalSlot::cancombine(int type) const { return -1; }

const char *getshaderparamname(const char *name, bool insert) { return ""; };

void setupmaterials(int start, int len) { };
int findmaterial(const char *name) { return 0; };
void enablepolygonoffset(GLenum type) { };
void disablepolygonoffset(GLenum type) { };
void genmatsurfs(const cube &c, const ivec &co, int size, vector<materialsurface> &matsurfs) { };
void resetqueries() { };
void initenvmaps() { };
int optimizematsurfs(materialsurface *matbuf, int matsurfs) { return 0; };
void loadskin(const char *dir, const char *altdir, Texture *&skin, Texture *&masks) {};

matrix4 shadowmatrix, camprojmatrix;

void findanims(const char *pattern, vector<int> &anims) {};

void genstainmmtri(stainrenderer *s, const vec v[3]) {};

#ifdef WINDOWS // needs stubs too, works for now
#include "GL/gl.h"
PFNGLDRAWRANGEELEMENTSPROC glDrawRangeElements_ = NULL;
#else // stubs everywhere!
void glEnable(GLenum cap) {};
void glDrawRangeElements(GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid *indicies) {};
#endif

#ifndef __APPLE__
PFNGLDELETEBUFFERSARBPROC         glDeleteBuffers_            = NULL;
PFNGLGENBUFFERSARBPROC            glGenBuffers_               = NULL;
PFNGLBINDBUFFERARBPROC            glBindBuffer_               = NULL;
PFNGLBUFFERDATAARBPROC            glBufferData_               = NULL;
PFNGLUNIFORM4FVPROC               glUniform4fv_               = NULL;
PFNGLENABLEVERTEXATTRIBARRAYPROC  glEnableVertexAttribArray_  = NULL;
PFNGLDISABLEVERTEXATTRIBARRAYPROC glDisableVertexAttribArray_ = NULL;
PFNGLVERTEXATTRIBPOINTERPROC      glVertexAttribPointer_      = NULL;
PFNGLGETUNIFORMLOCATIONPROC       glGetUniformLocation_       = NULL;
#else
void glDeleteBuffers(GLsizei n, const GLuint *buffers) {};
void glGenBuffers(GLsizei n, GLuint *buffers) {};
void glBindBuffer(GLenum target, GLuint buffer) {};
void glBufferData(GLenum target, GLsizeiptr size, const GLvoid *data, GLenum usage) {};
void glUniform4fv(GLint location, GLsizei count, const GLfloat *value) {};
void glEnableVertexAttribArray(GLuint index) {}
void glDisableVertexAttribArray(GLuint index) {}
void glVertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid *pointer) {};
GLint glGetUniformLocation(GLuint program, const GLchar *name) { return 0; };
#endif


/* teh ugly file of stubs */

#include "engine.h"

int thirdperson   = 0;
int gamespeed     = 0;
int envmapradius  = 0;
int showmat       = 0;
int outline       = 0;
int glversion     = 0;
int texdefscale   = 0;
int maxvsuniforms = 0;
int shadowmapping = 0;

int xtravertsva;

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

void calcmatbb(vtxarray *va, const ivec &co, int size, vector<materialsurface> &matsurfs) {}

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
void renderbackground(const char *caption, Texture *mapshot, const char *mapname, const char *mapinfo, bool force) { };
void writebinds(stream *f) { };
int isvisiblesphere(float rad, const vec &cv) { return 0; };
Shader *lookupshaderbyname(const char *name) { return NULL; };
Shader *useshaderbyname(const char *name) { return NULL; };
ushort closestenvmap(int orient, const ivec &co, int size) { return 0; };
ushort closestenvmap(const vec &o) { return 0; };
GLuint lookupenvmap(ushort emid) { return 0; };
uchar *loadalphamask(Texture *t) { return NULL; };
Texture *cubemapload(const char *name, bool mipit, bool msg, bool transient) { return notexture; };

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
void genmatsurfs(const cube &c, const ivec &co, int size, vector<materialsurface> &matsurfs) { };
void resetqueries() { };
void initenvmaps() { };
int optimizematsurfs(materialsurface *matbuf, int matsurfs) { return 0; };
void loadskin(const char *dir, const char *altdir, Texture *&skin, Texture *&masks) {};

matrix4 hudmatrix, aamaskmatrix, shadowmatrix, camprojmatrix;

void pushhudmatrix() {};
void flushhudmatrix(bool flushparams) {};
void pophudmatrix(bool flush, bool flushparams) {};

void findanims(const char *pattern, vector<int> &anims) {};

#ifdef WINDOWS // needs stubs too, works for now
#include "GL/gl.h"
PFNGLDRAWRANGEELEMENTSPROC glDrawRangeElements_ = NULL;
#else // stubs everywhere!
void glDepthFunc(GLenum func) {};
void glEnable(GLenum cap) {};
void glDisable(GLenum cap) {};
void glBindTexture(GLenum target, GLuint texture) {};
void glBlendFunc(GLenum sfactor, GLenum dfactor) {};
void glDrawArrays(GLenum mode, GLint first, GLsizei count) {};
void glDrawRangeElements(GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid *indicies) {};
#endif

#ifndef __APPLE__
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
PFNGLUNIFORM1UIVPROC              glUniform1uiv_              = NULL;
PFNGLUNIFORM2UIVPROC              glUniform2uiv_              = NULL;
PFNGLUNIFORM3UIVPROC              glUniform3uiv_              = NULL;
PFNGLUNIFORM4UIVPROC              glUniform4uiv_              = NULL;
PFNGLUNIFORMMATRIX2FVPROC         glUniformMatrix2fv_         = NULL;
PFNGLUNIFORMMATRIX3FVPROC         glUniformMatrix3fv_         = NULL;
PFNGLUNIFORMMATRIX4FVPROC         glUniformMatrix4fv_         = NULL;
PFNGLENABLEVERTEXATTRIBARRAYPROC  glEnableVertexAttribArray_  = NULL;
PFNGLDISABLEVERTEXATTRIBARRAYPROC glDisableVertexAttribArray_ = NULL;
PFNGLVERTEXATTRIBPOINTERPROC      glVertexAttribPointer_      = NULL;
PFNGLGETUNIFORMLOCATIONPROC       glGetUniformLocation_       = NULL;
PFNGLMAPBUFFERRANGEPROC           glMapBufferRange_           = NULL;
PFNGLUNMAPBUFFERPROC              glUnmapBuffer_              = NULL;
PFNGLMULTIDRAWARRAYSPROC          glMultiDrawArrays_          = NULL;
#else
void glDeleteBuffers(GLsizei n, const GLuint *buffers) {};
void glGenBuffers(GLsizei n, GLuint *buffers) {};
void glBindBuffer(GLenum target, GLuint buffer) {};
void glBufferData(GLenum target, GLsizeiptr size, const GLvoid *data, GLenum usage) {};
void glBufferSubData(GLenum target, GLintptr offset, GLsizeiptr size, const GLvoid *data) {};
void glVertexAttrib3f(GLuint index, GLfloat v0, GLfloat v1, GLfloat v2) {};
void glVertexAttrib4f(GLuint index, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3) {};
void glVertexAttrib4Nub(GLuint index, GLubyte v0, GLubyte v1, GLubyte v2, GLubyte v3) {};
void glUniform1fv(GLint location, GLsizei count, const GLfloat *value) {};
void glUniform2fv(GLint location, GLsizei count, const GLfloat *value) {};
void glUniform3fv(GLint location, GLsizei count, const GLfloat *value) {};
void glUniform4fv(GLint location, GLsizei count, const GLfloat *value) {};
void glUniform1iv(GLint location, GLsizei count, const GLint *value) {};
void glUniform2iv(GLint location, GLsizei count, const GLint *value) {};
void glUniform3iv(GLint location, GLsizei count, const GLint *value) {};
void glUniform4iv(GLint location, GLsizei count, const GLint *value) {};
void glUniform1uiv(GLint location, GLsizei count, const GLuint *value) {};
void glUniform2uiv(GLint location, GLsizei count, const GLuint *value) {};
void glUniform3uiv(GLint location, GLsizei count, const GLuint *value) {};
void glUniform4uiv(GLint location, GLsizei count, const GLuint *value) {};
void glUniformMatrix2fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {};
void glUniformMatrix3fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {};
void glUniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {};
void glEnableVertexAttribArray(GLuint index) {}
void glDisableVertexAttribArray(GLuint index) {}
void glVertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid *pointer) {};
GLint glGetUniformLocation(GLuint program, const GLchar *name) { return 0; };
void *glMapBufferRange(GLenum target, GLintptr offset, GLsizeiptr length, GLbitfield access) { return NULL; };
void *glMapBuffer(GLenum target, GLenum access) { return NULL; };
void glMultiDrawArrays(	GLenum mode, const GLint *first, const GLsizei *count, GLsizei drawcount) {};
#endif

PFNGLGENVERTEXARRAYSPROC          glGenVertexArrays_          = NULL;
PFNGLDELETEVERTEXARRAYSPROC       glDeleteVertexArrays_       = NULL;
PFNGLBINDVERTEXARRAYPROC          glBindVertexArray_          = NULL;

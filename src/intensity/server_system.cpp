/* teh ugly file of stubs */

#include "engine.h"

int thirdperson   = 0;
int gamespeed     = 0;
int envmapradius  = 0;
int showmat       = 0;
int outline       = 0;

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

Shader *defaultshader = NULL, *ldrnotextureshader = NULL;
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

vector< types::Shared_Ptr<VSlot> > vslots;

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
void genmatsurfs(cube &c, int cx, int cy, int cz, int size, vector<materialsurface> &matsurfs) { };
void resetqueries() { };
void initenvmaps() { };
int optimizematsurfs(materialsurface *matbuf, int matsurfs) { return 0; };

#ifdef WINDOWS // needs stubs too, works for now
#include "GL/gl.h"
#else // stubs everywhere!
void glBegin(GLenum mode) { };
void glVertex3fv(const GLfloat *v) { };
void glEnd() { };
void glColor3f(GLfloat red , GLfloat green , GLfloat blue) { };
void glColor3ub(GLubyte red, GLubyte green, GLubyte blue) { };
void glLineWidth(GLfloat width) { };
void glDepthFunc(GLenum func) { };
void glEnable(GLenum cap) { };
void glDisable(GLenum cap) { };
void glColor4f(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) { };
void glBindTexture(GLenum target, GLuint texture) { };
void glBlendFunc( GLenum sfactor, GLenum dfactor ) { };
void glPushMatrix( void ) { };
void glPopMatrix(          void) { };
void glScalef( GLfloat x, GLfloat y, GLfloat z ) { };
void glTexCoord2fv( const GLfloat *v ) { };
void glVertex2f( GLfloat x, GLfloat y ) { };
#endif

PFNGLDELETEBUFFERSARBPROC    glDeleteBuffers_    = NULL;
PFNGLGENBUFFERSARBPROC       glGenBuffers_       = NULL;
PFNGLBINDBUFFERARBPROC       glBindBuffer_ = NULL;
PFNGLBUFFERDATAARBPROC       glBufferData_       = NULL;
PFNGLGETBUFFERSUBDATAARBPROC glGetBufferSubData_ = NULL;

#ifndef __APPLE__
PFNGLUNIFORM1FVARBPROC                glUniform1fv_               = NULL;
PFNGLUNIFORM2FVARBPROC                glUniform2fv_               = NULL;
PFNGLUNIFORM3FVARBPROC                glUniform3fv_               = NULL;
PFNGLUNIFORM4FVARBPROC                glUniform4fv_               = NULL;
PFNGLUNIFORMMATRIX2FVARBPROC          glUniformMatrix2fv_         = NULL;
PFNGLUNIFORMMATRIX3FVARBPROC          glUniformMatrix3fv_         = NULL;
PFNGLUNIFORMMATRIX4FVARBPROC          glUniformMatrix4fv_         = NULL;
#else
void glUniform1fv(GLint location, GLsizei count, const GLfloat *value) {}
void glUniform2fv(GLint location, GLsizei count, const GLfloat *value) {}
void glUniform3fv(GLint location, GLsizei count, const GLfloat *value) {}
void glUniform4fv(GLint location, GLsizei count, const GLfloat *value) {}
void glUniformMatrix2fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {}
void glUniformMatrix3fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {}
void glUniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value) {}
#endif


// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "of_tools.h"

VARR(fog, 1, 2, 300000);
VAR(thirdperson, 0, 1, 2);
VARN(gui2d, usegui2d, 0, 1, 1);
VAR(gamespeed, 0, 100, 100);
VAR(paused, 0, 0, 1);
VAR(shaderdetail, 0, 1, 3);
VAR(envmapradius, 0, 128, 10000);
VAR(nolights, 1, 0, 0);
VARN(blobs, showblobs, 0, 1, 1);
VAR(shadowmap, 0, 0, 1);
VAR(maxtmus, 1, 0, 0);
VAR(reservevpparams, 1, 16, 0);
VAR(maxvpenvparams, 1, 0, 0);
VAR(maxvplocalparams, 1, 0, 0);
VAR(maxfpenvparams, 1, 0, 0);
VAR(maxfplocalparams, 1, 0, 0);
VAR(maxvsuniforms, 1, 0, 0);
VAR(vertwater, 0, 1, 1);
VAR(reflectdist, 0, 2000, 10000);
VAR(waterrefract, 0, 1, 1);
VAR(waterreflect, 0, 1, 1);
VAR(waterfade, 0, 1, 1);
VAR(caustics, 0, 1, 1);
VAR(waterfallrefract, 0, 0, 1);
VAR(waterfog, 0, 150, 10000);
VAR(lavafog, 0, 50, 10000);
VAR(showmat, 0, 1, 1);
VAR(fullbright, 0, 0, 1);
VAR(menuautoclose, 32, 120, 4096);
VAR(outline, 0, 0, 0xFFFFFF);
VAR(oqfrags, 0, 8, 64);
VAR(renderpath, 1, R_FIXEDFUNCTION, 0);
VAR(ati_oq_bug, 0, 0, 1);
VAR(lightprecision, 1, 32, 1024);
VAR(lighterror, 1, 8, 16);
VAR(bumperror, 1, 3, 16);
VAR(lightlod, 0, 0, 10);
VAR(ambient, 1, 0x191919, 0xFFFFFF);
VAR(skylight, 0, 0, 0xFFFFFF);
VAR(watercolour, 0, 0x144650, 0xFFFFFF);
VAR(waterfallcolour, 0, 0, 0xFFFFFF);
VAR(lavacolour, 0, 0xFF4000, 0xFFFFFF);

namespace gui
{
    VAR(mainmenu, 1, 0, 0);
    void clearmainmenu() {}
    bool hascursor(bool targeting) { return false; }
}

// INTENSITY: *New* function, to parallel sauer's client version
void serverkeepalive()
{
    extern ENetHost *serverhost;
    if(serverhost)
        enet_host_service(serverhost, NULL, 0);
}

//=====================================================================================
// Utilities to make the server able to use Cube code that was client-only in the past
//=====================================================================================

#define CONSTRLEN 512

void conoutfv(int type, const char *fmt, va_list args)
{
    printf("%s\n", types::String().format(fmt, args).get_buf());
}

void conoutf(int type, const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    conoutfv(type, fmt, args);
    va_end(args);
}

void conoutf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    conoutfv(CON_INFO, fmt, args);
    va_end(args); 
}

// Stuff the client has in various files, which the server needs replacements for

Texture *notexture = NULL; // Replacement for texture.cpp's notexture

int hasstencil = 0; // For rendergl.cpp

Shader *Shader::lastshader = NULL;
void Shader::bindprograms() { assert(0); };
void Shader::flushenvparams(Slot* slot) { assert(0); };
void Shader::setslotparams(Slot& slot, VSlot &vslot) { assert(0); };

bool glaring = false; // glare.cpp

void damageblend(int n) { };

void damagecompass(int n, const vec &loc) { };

void playsound(int n, const vec *loc, extentity *ent) { }

void renderprogress(float bar, const char *text, GLuint tex, bool background)
{
    /* Keep connection alive */
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

bool interceptkey(int sym) { return false; };

void fatal(const char *s, ...)
{
    printf("FATAL: %s\r\n", s);
    exit(-1);
};

bool printparticles(extentity &e, char *buf) { return true; };
void clearparticleemitters() { };

void createtexture(int tnum, int w, int h, void *pixels, int clamp, int filter, GLenum component, GLenum subtarget, int pw, int ph, int pitch, bool resize) { assert(0); };

vec worldpos;
vec camdir;
bvec watercolor, waterfallcolor, lavacolor;
int hidehud; // to replace
dynent *player = NULL;
physent *camera1 = NULL;
float loadprogress = 0.333;
vector<LightMap> lightmaps;
int initing = NOT_INITING;
bool shadowmapping = false;
Shader *nocolorshader = NULL, *notextureshader = NULL, *lineshader = NULL;
bool fading = false;
int xtraverts = 0, xtravertsva = 0;
bool reflecting = false;
int refracting = 0;
float reflectz;
bool fogging = false;

bool hasVBO = false, hasDRE = false, hasOQ = false, hasTR = false, hasFBO = false, hasDS = false, hasTF = false, hasBE = false, hasBC = false, hasCM = false, hasNP2 = false, hasTC = false, hasTE = false, hasMT = false, hasD3 = false, hasAF = false, hasVP2 = false, hasVP3 = false, hasPP = false, hasMDA = false, hasTE3 = false, hasTE4 = false, hasVP = false, hasFP = false, hasGLSL = false, hasGM = false, hasNVFB = false, hasSGIDT = false, hasSGISH = false, hasDT = false, hasSH = false, hasNVPCF = false, hasRN = false, hasPBO = false, hasFBB = false, hasUBO = false, hasBUE = false, hasTEX = false;

GLuint fogtex = -1;
glmatrixf mvmatrix, projmatrix, mvpmatrix, invmvmatrix, invmvpmatrix, envmatrix;
volatile bool check_calclight_progress = false;
bool calclight_canceled = false;
int curtexnum = 0;
Shader *defaultshader = NULL, *rectshader = NULL, *foggedshader = NULL, *foggednotextureshader = NULL, *stdworldshader = NULL;
bool inbetweenframes = false, renderedframe = false;
vec shadowoffset(0, 0, 0), shadowfocus(0, 0, 0), shadowdir(0, 0.707, 1);
int explicitsky = 0;
double skyarea = 0;
vector<LightMapTexture> lightmaptexs;
vtxarray *visibleva = NULL;

int lightmapping = 0;

bool getkeydown() { return false; };
bool getkeyup() { return false; };
bool getmousedown() { return false; };
bool getmouseup() { return false; };
void drawminimap() { };
Texture *loadthumbnail(Slot &slot) { return notexture; };
void renderblendbrush(GLuint tex, float x, float y, float w, float h) { };
void previewblends(const ivec &bo, const ivec &bs) { };
bool loadimage(const char *filename, ImageData &image) { return false; }; // or return true?
void clearmapsounds() { };
void cleanreflections() { };
void resetlightmaps(bool fullclean) { };
void clearparticles() { };
void cleardecals() { };
void clearmainmenu() { };
void clearlights() { };
void clearlightcache(int e) { };
void lightent(extentity &e, float height) { };
void fixlightmapnormals() { };
void initlights() { };
void newsurfaces(cube &c, const surfaceinfo *surfs, int numsurfs) { };
void brightencube(cube &c) { };
Texture *textureload(const char *name, int clamp, bool mipit, bool msg) { return notexture; }; // or return no-texture texture?
void renderbackground(const char *caption, Texture *mapshot, const char *mapname, const char *mapinfo, bool restore, bool force) { };
void loadpvs(gzFile f) { };
void savepvs(gzFile f) { };
void writebinds(stream *f) { };
const char *addreleaseaction(const char *s) { return NULL; };
void freesurfaces(cube &c) { };
occludequery *newquery(void *owner) { return NULL; };
void drawbb(const ivec &bo, const ivec &br, const vec &camera) { };
void renderblob(int type, const vec &o, float radius, float fade) { };
void flushblobs() { };
bool bboccluded(const ivec &bo, const ivec &br) { return true; };
int isvisiblesphere(float rad, const vec &cv) { return 0; };
bool isfoggedsphere(float rad, const vec &cv) { return false; };
bool isshadowmapcaster(const vec &o, float rad) { return false; };
bool checkquery(occludequery *query, bool nowait) { return true; };
bool addshadowmapcaster(const vec &o, float xyrad, float zrad) { return false; };
void lightreaching(const vec &target, vec &color, vec &dir, bool fast, extentity *t, float ambient) { };
void dynlightreaching(const vec &target, vec &color, vec &dir, bool hud) { };
Shader *lookupshaderbyname(const char *name) { return NULL; };
Texture *cubemapload(const char *name, bool mipit, bool msg, bool transient) { return notexture; };
Shader *useshaderbyname(const char *name) { return NULL; };
void resettmu(int n) { };
void setuptmu(int n, const char *rgbfunc, const char *alphafunc) { };
void colortmu(int n, float r, float g, float b, float a) { };
void scaletmu(int n, int rgbscale, int alphascale) { };
void getwatercolour(uchar *wcol) { };
void createfogtex() { };
void setenvparamf(const char *name, int type, int index, float x, float y, float z, float w) { };
void setenvparamfv(const char *name, int type, int index, const float *v) { };
void setfogplane(const plane &p, bool flush) { };
ushort closestenvmap(const vec &o) { return 0; };
ushort closestenvmap(int orient, int x, int y, int z, int size) { return 0; };
GLuint lookupenvmap(Slot &slot) { return 0; };
GLuint lookupenvmap(ushort emid) { return 0; };
void loadalphamask(Texture *t) { };
void createtexture(int tnum, int w, int h, void *pixels, int clamp, int filter, GLenum component, GLenum subtarget, int pw, int ph, int pitch, bool resize, GLenum format) { };

vector< types::Shared_Ptr<VSlot> > vslots;
vector< types::Shared_Ptr< Slot> > slots;
Slot dummyslot;
VSlot dummyvslot(&dummyslot);

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

VSlot *findvslot(Slot &slot, const VSlot &src, const VSlot &delta)
{
    return &lookupvslot(0, 0);
}

void clearslots() { };
void compactvslots(cube *c, int n) { };
int compactvslots() { return 0; };
void compactvslot(int &index) { };
void mergevslot(VSlot &dst, const VSlot &src, const VSlot &delta) { };

const char *getshaderparamname(const char *name) { return ""; };

int Shader::uniformlocversion() { return 0; };

void check_calclight_canceled() { };
void setupmaterials(int start, int len) { };
void invalidatepostfx() { };
void resetblobs() { };
int findmaterial(const char *name) { return 0; };
void keyrepeat(bool on) { };
bool g3d_windowhit(bool on, bool act) { return false; };
void enablepolygonoffset(GLenum type) { };
void disablepolygonoffset(GLenum type) { };
vec menuinfrontofplayer() { return vec(0,0,0); };
void genmatsurfs(cube &c, int cx, int cy, int cz, int size, vector<materialsurface> &matsurfs, uchar &vismask, uchar &clipmask) { };
void resetqueries() { };
void initenvmaps() { };
void guessshadowdir() { };
void genenvmaps() { };
int optimizematsurfs(materialsurface *matbuf, int matsurfs) { return 0; };
void texturereset(int n) { };

void seedparticles() { };

glmatrixf fogmatrix;

#ifdef WINDOWS
// Need to create a 'stub' DLL, like with Linux, but for now try this FIXME
#include "GL/gl.h"
#else // LINUX
// OpenGL stubs - prevent the need to load OpenGL libs
void glGenTextures(GLsizei n, GLuint *textures) { };
void glBegin(GLenum mode) { };
void glVertex3fv(const GLfloat *v) { };
void glEnd() { };
void glColor3f(GLfloat red , GLfloat green , GLfloat blue) { };
void glColor3ub(GLubyte red, GLubyte green, GLubyte blue) { };
void glLineWidth(GLfloat width) { };
void glPolygonMode(GLenum face, GLenum mode) { };
void glDepthFunc(GLenum func) { };
void glFlush() { };
void glColorMask(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha) { };
void glDepthMask(GLboolean flag) { };
void glEnable(GLenum cap) { };
void glDisable(GLenum cap) { };
void glVertex3f(GLfloat x, GLfloat y ,GLfloat z) { };
void glEnableClientState(GLenum cap) { };
void glDisableClientState(GLenum cap) { };
void glVertexPointer(GLint size, GLenum type, GLsizei stride, const GLvoid *pointer) { };
void glNormalPointer(GLenum type, GLsizei stride, const GLvoid *pointer) { };
void glTexCoordPointer(GLint size, GLenum type, GLsizei stride, const GLvoid * pointer) { };
void glColor4f(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) { };
void glMaterialfv(GLenum face, GLenum pname, const GLfloat * params) { };
void glTexGeni( GLenum coord, GLenum pname, GLint param) { };
void glBindTexture(GLenum target, GLuint texture) { };
void glTexGenfv( GLenum coord, GLenum pname, const GLfloat *params ) { };
void glLightfv(    GLenum      light, GLenum      pname, const GLfloat *      params) { };
void glBlendFunc( GLenum sfactor, GLenum dfactor ) { };
void glAlphaFunc( GLenum func, GLclampf ref ) { };
void glMatrixMode( GLenum mode ) { };
void glPushMatrix( void ) { };
void glTranslatef( GLfloat x, GLfloat y, GLfloat z ) { };
void glDrawElements( GLenum mode, GLsizei count, GLenum type, const GLvoid *indices ) { };
void glPopMatrix(          void) { };
void glLightModelfv(    GLenum      pname, const GLfloat *      params) { }
void glMultMatrixf( const GLfloat *m ) { };
void glScalef( GLfloat x, GLfloat y, GLfloat z ) { };
void glLoadMatrixf( const GLfloat *m ) { };
void glLoadIdentity( void ) { };
void glTexCoord2fv( const GLfloat *v ) { };
void glVertex2f( GLfloat x, GLfloat y ) { };
void glDeleteTextures( GLsizei n, const GLuint *textures ) { };
#endif

PFNGLBEGINQUERYARBPROC glBeginQuery_ = NULL;
PFNGLENDQUERYARBPROC glEndQuery_ = NULL;
PFNGLDISABLEVERTEXATTRIBARRAYARBPROC glDisableVertexAttribArray_ = NULL;
PFNGLPROGRAMENVPARAMETERS4FVEXTPROC   glProgramEnvParameters4fv_ = NULL;
PFNGLPROGRAMENVPARAMETER4FVARBPROC   glProgramEnvParameter4fv_   = NULL;
PFNGLDELETEBUFFERSARBPROC    glDeleteBuffers_    = NULL;
PFNGLGENBUFFERSARBPROC       glGenBuffers_       = NULL;
PFNGLBINDBUFFERARBPROC       glBindBuffer_ = NULL;
PFNGLBUFFERDATAARBPROC       glBufferData_       = NULL;
PFNGLCLIENTACTIVETEXTUREARBPROC glClientActiveTexture_ = NULL;
PFNGLENABLEVERTEXATTRIBARRAYARBPROC  glEnableVertexAttribArray_  = NULL;
PFNGLVERTEXATTRIBPOINTERARBPROC      glVertexAttribPointer_      = NULL;
PFNGLACTIVETEXTUREARBPROC       glActiveTexture_ = NULL;
PFNGLDRAWRANGEELEMENTSEXTPROC glDrawRangeElements_ = NULL;
PFNGLGETBUFFERSUBDATAARBPROC glGetBufferSubData_ = NULL;
PFNGLUNIFORM4FVARBPROC                glUniform4fv_               = NULL;
PFNGLBUFFERSUBDATAARBPROC    glBufferSubData_    = NULL;
PFNGLBINDBUFFERBASEPROC          glBindBufferBase_          = NULL;
PFNGLUNIFORMBUFFEREXTPROC        glUniformBuffer_        = NULL;

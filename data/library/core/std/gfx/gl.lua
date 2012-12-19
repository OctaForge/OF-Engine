--[[! File: library/core/std/gfx/gl.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2012 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        OpenGL bindings for OctaForge scripting. Definitions taken from
        https://github.com/malkia/ufo.

        Note this does not initialize OpenGL functions in scripting
        immediately. Instead, this module first returns an empty
        table and everything OpenGL is initialized via the gl_init
        signal called after GL initialization in the engine.

        This is because by the time of first scripting init OpenGL
        is not yet loaded.
]]

if SERVER then return {} end

ffi.cdef [[
    typedef void (*glActiveTextureARBProcPtr)(GLenum);
    typedef void (*glClientActiveTextureARBProcPtr)(GLenum);
    typedef void (*glMultiTexCoord1dARBProcPtr)(GLenum, GLdouble);
    typedef void (*glMultiTexCoord1dvARBProcPtr)(GLenum, const GLdouble *);
    typedef void (*glMultiTexCoord1fARBProcPtr)(GLenum, GLfloat);
    typedef void (*glMultiTexCoord1fvARBProcPtr)(GLenum, const GLfloat *);
    typedef void (*glMultiTexCoord1iARBProcPtr)(GLenum, GLint);
    typedef void (*glMultiTexCoord1ivARBProcPtr)(GLenum, const GLint *);
    typedef void (*glMultiTexCoord1sARBProcPtr)(GLenum, GLshort);
    typedef void (*glMultiTexCoord1svARBProcPtr)(GLenum, const GLshort *);
    typedef void (*glMultiTexCoord2dARBProcPtr)(GLenum, GLdouble, GLdouble);
    typedef void (*glMultiTexCoord2dvARBProcPtr)(GLenum, const GLdouble *);
    typedef void (*glMultiTexCoord2fARBProcPtr)(GLenum, GLfloat, GLfloat);
    typedef void (*glMultiTexCoord2fvARBProcPtr)(GLenum, const GLfloat *);
    typedef void (*glMultiTexCoord2iARBProcPtr)(GLenum, GLint, GLint);
    typedef void (*glMultiTexCoord2ivARBProcPtr)(GLenum, const GLint *);
    typedef void (*glMultiTexCoord2sARBProcPtr)(GLenum, GLshort, GLshort);
    typedef void (*glMultiTexCoord2svARBProcPtr)(GLenum, const GLshort *);
    typedef void (*glMultiTexCoord3dARBProcPtr)(GLenum, GLdouble, GLdouble, GLdouble);
    typedef void (*glMultiTexCoord3dvARBProcPtr)(GLenum, const GLdouble *);
    typedef void (*glMultiTexCoord3fARBProcPtr)(GLenum, GLfloat, GLfloat, GLfloat);
    typedef void (*glMultiTexCoord3fvARBProcPtr)(GLenum, const GLfloat *);
    typedef void (*glMultiTexCoord3iARBProcPtr)(GLenum, GLint, GLint, GLint);
    typedef void (*glMultiTexCoord3ivARBProcPtr)(GLenum, const GLint *);
    typedef void (*glMultiTexCoord3sARBProcPtr)(GLenum, GLshort, GLshort, GLshort);
    typedef void (*glMultiTexCoord3svARBProcPtr)(GLenum, const GLshort *);
    typedef void (*glMultiTexCoord4dARBProcPtr)(GLenum, GLdouble, GLdouble, GLdouble, GLdouble);
    typedef void (*glMultiTexCoord4dvARBProcPtr)(GLenum, const GLdouble *);
    typedef void (*glMultiTexCoord4fARBProcPtr)(GLenum, GLfloat, GLfloat, GLfloat, GLfloat);
    typedef void (*glMultiTexCoord4fvARBProcPtr)(GLenum, const GLfloat *);
    typedef void (*glMultiTexCoord4iARBProcPtr)(GLenum, GLint, GLint, GLint, GLint);
    typedef void (*glMultiTexCoord4ivARBProcPtr)(GLenum, const GLint *);
    typedef void (*glMultiTexCoord4sARBProcPtr)(GLenum, GLshort, GLshort, GLshort, GLshort);
    typedef void (*glMultiTexCoord4svARBProcPtr)(GLenum, const GLshort *);
    typedef void (*glLoadTransposeMatrixfARBProcPtr)(const GLfloat *);
    typedef void (*glLoadTransposeMatrixdARBProcPtr)(const GLdouble *);
    typedef void (*glMultTransposeMatrixfARBProcPtr)(const GLfloat *);
    typedef void (*glMultTransposeMatrixdARBProcPtr)(const GLdouble *);
    typedef void (*glSampleCoverageARBProcPtr)(GLclampf, GLboolean);
    typedef void (*glSamplePassARBProcPtr)(GLenum);
    typedef void (*glCompressedTexImage3DARBProcPtr)(GLenum, GLint, GLenum, GLsizei, GLsizei, GLsizei, GLint, GLsizei, const GLvoid *);
    typedef void (*glCompressedTexImage2DARBProcPtr)(GLenum, GLint, GLenum, GLsizei, GLsizei, GLint, GLsizei, const GLvoid *);
    typedef void (*glCompressedTexImage1DARBProcPtr)(GLenum, GLint, GLenum, GLsizei, GLint, GLsizei, const GLvoid *);
    typedef void (*glCompressedTexSubImage3DARBProcPtr)(GLenum, GLint, GLint, GLint, GLint, GLsizei, GLsizei, GLsizei, GLenum, GLsizei, const GLvoid *);
    typedef void (*glCompressedTexSubImage2DARBProcPtr)(GLenum, GLint, GLint, GLint, GLsizei, GLsizei, GLenum, GLsizei, const GLvoid *);
    typedef void (*glCompressedTexSubImage1DARBProcPtr)(GLenum, GLint, GLint, GLsizei, GLenum, GLsizei, const GLvoid *);
    typedef void (*glGetCompressedTexImageARBProcPtr)(GLenum, GLint, GLvoid *);
    typedef void (*glWeightbvARBProcPtr)(GLint, const GLbyte *);
    typedef void (*glWeightsvARBProcPtr)(GLint, const GLshort *);
    typedef void (*glWeightivARBProcPtr)(GLint, const GLint *);
    typedef void (*glWeightfvARBProcPtr)(GLint, const GLfloat *);
    typedef void (*glWeightdvARBProcPtr)(GLint, const GLdouble *);
    typedef void (*glWeightubvARBProcPtr)(GLint, const GLubyte *);
    typedef void (*glWeightusvARBProcPtr)(GLint, const GLushort *);
    typedef void (*glWeightuivARBProcPtr)(GLint, const GLuint *);
    typedef void (*glWeightPointerARBProcPtr)(GLint, GLenum, GLsizei, const GLvoid *);
    typedef void (*glVertexBlendARBProcPtr)(GLint);
    typedef void (*glWindowPos2dARBProcPtr)(GLdouble, GLdouble);
    typedef void (*glWindowPos2dvARBProcPtr)(const GLdouble *);
    typedef void (*glWindowPos2fARBProcPtr)(GLfloat, GLfloat);
    typedef void (*glWindowPos2fvARBProcPtr)(const GLfloat *);
    typedef void (*glWindowPos2iARBProcPtr)(GLint, GLint);
    typedef void (*glWindowPos2ivARBProcPtr)(const GLint *);
    typedef void (*glWindowPos2sARBProcPtr)(GLshort, GLshort);
    typedef void (*glWindowPos2svARBProcPtr)(const GLshort *);
    typedef void (*glWindowPos3dARBProcPtr)(GLdouble, GLdouble, GLdouble);
    typedef void (*glWindowPos3dvARBProcPtr)(const GLdouble *);
    typedef void (*glWindowPos3fARBProcPtr)(GLfloat, GLfloat, GLfloat);
    typedef void (*glWindowPos3fvARBProcPtr)(const GLfloat *);
    typedef void (*glWindowPos3iARBProcPtr)(GLint, GLint, GLint);
    typedef void (*glWindowPos3ivARBProcPtr)(const GLint *);
    typedef void (*glWindowPos3sARBProcPtr)(GLshort, GLshort, GLshort);
    typedef void (*glWindowPos3svARBProcPtr)(const GLshort *);
    typedef void (*glGenQueriesARBProcPtr)(GLsizei n, GLuint *ids);
    typedef void (*glDeleteQueriesARBProcPtr)(GLsizei n, const GLuint *ids);
    typedef GLboolean (*glIsQueryARBProcPtr)(GLuint id);
    typedef void (*glBeginQueryARBProcPtr)(GLenum target, GLuint id);
    typedef void (*glEndQueryARBProcPtr)(GLenum target);
    typedef void (*glGetQueryivARBProcPtr)(GLenum target, GLenum pname, GLint *params);
    typedef void (*glGetQueryObjectivARBProcPtr)(GLuint id, GLenum pname, GLint *params);
    typedef void (*glGetQueryObjectuivARBProcPtr)(GLuint id, GLenum pname, GLuint *params);
    typedef void (*glPointParameterfARBProcPtr)(GLenum pname, GLfloat param);
    typedef void (*glPointParameterfvARBProcPtr)(GLenum pname, const GLfloat *params);
    typedef void (*glBindProgramARBProcPtr)(GLenum target, GLuint program);
    typedef void (*glDeleteProgramsARBProcPtr)(GLsizei n, const GLuint *programs);
    typedef void (*glGenProgramsARBProcPtr)(GLsizei n, GLuint *programs);
    typedef GLboolean (*glIsProgramARBProcPtr)(GLuint program);
    typedef void (*glProgramEnvParameter4dARBProcPtr)(GLenum target, GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
    typedef void (*glProgramEnvParameter4dvARBProcPtr)(GLenum target, GLuint index, const GLdouble *params);
    typedef void (*glProgramEnvParameter4fARBProcPtr)(GLenum target, GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
    typedef void (*glProgramEnvParameter4fvARBProcPtr)(GLenum target, GLuint index, const GLfloat *params);
    typedef void (*glProgramLocalParameter4dARBProcPtr)(GLenum target, GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
    typedef void (*glProgramLocalParameter4dvARBProcPtr)(GLenum target, GLuint index, const GLdouble *params);
    typedef void (*glProgramLocalParameter4fARBProcPtr)(GLenum target, GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
    typedef void (*glProgramLocalParameter4fvARBProcPtr)(GLenum target, GLuint index, const GLfloat *params);
    typedef void (*glGetProgramEnvParameterdvARBProcPtr)(GLenum target, GLuint index, GLdouble *params);
    typedef void (*glGetProgramEnvParameterfvARBProcPtr)(GLenum target, GLuint index, GLfloat *params);
    typedef void (*glProgramEnvParameters4fvEXTProcPtr)(GLenum target, GLuint index, GLsizei count, const GLfloat *params);
    typedef void (*glProgramLocalParameters4fvEXTProcPtr)(GLenum target, GLuint index, GLsizei count, const GLfloat *params);
    typedef void (*glGetProgramLocalParameterdvARBProcPtr)(GLenum target, GLuint index, GLdouble *params);
    typedef void (*glGetProgramLocalParameterfvARBProcPtr)(GLenum target, GLuint index, GLfloat *params);
    typedef void (*glProgramStringARBProcPtr)(GLenum target, GLenum format, GLsizei len, const GLvoid *string);
    typedef void (*glGetProgramStringARBProcPtr)(GLenum target, GLenum pname, GLvoid *string);
    typedef void (*glGetProgramivARBProcPtr)(GLenum target, GLenum pname, GLint *params);
    typedef void (*glVertexAttrib1dARBProcPtr)(GLuint index, GLdouble x);
    typedef void (*glVertexAttrib1dvARBProcPtr)(GLuint index, const GLdouble *v);
    typedef void (*glVertexAttrib1fARBProcPtr)(GLuint index, GLfloat x);
    typedef void (*glVertexAttrib1fvARBProcPtr)(GLuint index, const GLfloat *v);
    typedef void (*glVertexAttrib1sARBProcPtr)(GLuint index, GLshort x);
    typedef void (*glVertexAttrib1svARBProcPtr)(GLuint index, const GLshort *v);
    typedef void (*glVertexAttrib2dARBProcPtr)(GLuint index, GLdouble x, GLdouble y);
    typedef void (*glVertexAttrib2dvARBProcPtr)(GLuint index, const GLdouble *v);
    typedef void (*glVertexAttrib2fARBProcPtr)(GLuint index, GLfloat x, GLfloat y);
    typedef void (*glVertexAttrib2fvARBProcPtr)(GLuint index, const GLfloat *v);
    typedef void (*glVertexAttrib2sARBProcPtr)(GLuint index, GLshort x, GLshort y);
    typedef void (*glVertexAttrib2svARBProcPtr)(GLuint index, const GLshort *v);
    typedef void (*glVertexAttrib3dARBProcPtr)(GLuint index, GLdouble x, GLdouble y, GLdouble z);
    typedef void (*glVertexAttrib3dvARBProcPtr)(GLuint index, const GLdouble *v);
    typedef void (*glVertexAttrib3fARBProcPtr)(GLuint index, GLfloat x, GLfloat y, GLfloat z);
    typedef void (*glVertexAttrib3fvARBProcPtr)(GLuint index, const GLfloat *v);
    typedef void (*glVertexAttrib3sARBProcPtr)(GLuint index, GLshort x, GLshort y, GLshort z);
    typedef void (*glVertexAttrib3svARBProcPtr)(GLuint index, const GLshort *v);
    typedef void (*glVertexAttrib4NbvARBProcPtr)(GLuint index, const GLbyte *v);
    typedef void (*glVertexAttrib4NivARBProcPtr)(GLuint index, const GLint *v);
    typedef void (*glVertexAttrib4NsvARBProcPtr)(GLuint index, const GLshort *v);
    typedef void (*glVertexAttrib4NubARBProcPtr)(GLuint index, GLubyte x, GLubyte y, GLubyte z, GLubyte w);
    typedef void (*glVertexAttrib4NubvARBProcPtr)(GLuint index, const GLubyte *v);
    typedef void (*glVertexAttrib4NuivARBProcPtr)(GLuint index, const GLuint *v);
    typedef void (*glVertexAttrib4NusvARBProcPtr)(GLuint index, const GLushort *v);
    typedef void (*glVertexAttrib4bvARBProcPtr)(GLuint index, const GLbyte *v);
    typedef void (*glVertexAttrib4dARBProcPtr)(GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
    typedef void (*glVertexAttrib4dvARBProcPtr)(GLuint index, const GLdouble *v);
    typedef void (*glVertexAttrib4fARBProcPtr)(GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
    typedef void (*glVertexAttrib4fvARBProcPtr)(GLuint index, const GLfloat *v);
    typedef void (*glVertexAttrib4ivARBProcPtr)(GLuint index, const GLint *v);
    typedef void (*glVertexAttrib4sARBProcPtr)(GLuint index, GLshort x, GLshort y, GLshort z, GLshort w);
    typedef void (*glVertexAttrib4svARBProcPtr)(GLuint index, const GLshort *v);
    typedef void (*glVertexAttrib4ubvARBProcPtr)(GLuint index, const GLubyte *v);
    typedef void (*glVertexAttrib4uivARBProcPtr)(GLuint index, const GLuint *v);
    typedef void (*glVertexAttrib4usvARBProcPtr)(GLuint index, const GLushort *v);
    typedef void (*glVertexAttribPointerARBProcPtr)(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid *pointer);
    typedef void (*glDisableVertexAttribArrayARBProcPtr)(GLuint index);
    typedef void (*glEnableVertexAttribArrayARBProcPtr)(GLuint index);
    typedef void (*glGetVertexAttribPointervARBProcPtr)(GLuint index, GLenum pname, GLvoid **pointer);
    typedef void (*glGetVertexAttribdvARBProcPtr)(GLuint index, GLenum pname, GLdouble *params);
    typedef void (*glGetVertexAttribfvARBProcPtr)(GLuint index, GLenum pname, GLfloat *params);
    typedef void (*glGetVertexAttribivARBProcPtr)(GLuint index, GLenum pname, GLint *params);
    typedef void (*glDeleteObjectARBProcPtr)(GLhandleARB obj);
    typedef GLhandleARB (*glGetHandleARBProcPtr)(GLenum pname);
    typedef void (*glDetachObjectARBProcPtr)(GLhandleARB containerObj, GLhandleARB attachedObj);
    typedef GLhandleARB (*glCreateShaderObjectARBProcPtr)(GLenum shaderType);
    typedef void (*glShaderSourceARBProcPtr)(GLhandleARB shaderObj, GLsizei count, const GLcharARB **string, const GLint *length);
    typedef void (*glCompileShaderARBProcPtr)(GLhandleARB shaderObj);
    typedef GLhandleARB (*glCreateProgramObjectARBProcPtr)(void);
    typedef void (*glAttachObjectARBProcPtr)(GLhandleARB containerObj, GLhandleARB obj);
    typedef void (*glLinkProgramARBProcPtr)(GLhandleARB programObj);
    typedef void (*glUseProgramObjectARBProcPtr)(GLhandleARB programObj);
    typedef void (*glValidateProgramARBProcPtr)(GLhandleARB programObj);
    typedef void (*glUniform1fARBProcPtr)(GLint location, GLfloat v0);
    typedef void (*glUniform2fARBProcPtr)(GLint location, GLfloat v0, GLfloat v1);
    typedef void (*glUniform3fARBProcPtr)(GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
    typedef void (*glUniform4fARBProcPtr)(GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
    typedef void (*glUniform1iARBProcPtr)(GLint location, GLint v0);
    typedef void (*glUniform2iARBProcPtr)(GLint location, GLint v0, GLint v1);
    typedef void (*glUniform3iARBProcPtr)(GLint location, GLint v0, GLint v1, GLint v2);
    typedef void (*glUniform4iARBProcPtr)(GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
    typedef void (*glUniform1fvARBProcPtr)(GLint location, GLsizei count, const GLfloat *value);
    typedef void (*glUniform2fvARBProcPtr)(GLint location, GLsizei count, const GLfloat *value);
    typedef void (*glUniform3fvARBProcPtr)(GLint location, GLsizei count, const GLfloat *value);
    typedef void (*glUniform4fvARBProcPtr)(GLint location, GLsizei count, const GLfloat *value);
    typedef void (*glUniform1ivARBProcPtr)(GLint location, GLsizei count, const GLint *value);
    typedef void (*glUniform2ivARBProcPtr)(GLint location, GLsizei count, const GLint *value);
    typedef void (*glUniform3ivARBProcPtr)(GLint location, GLsizei count, const GLint *value);
    typedef void (*glUniform4ivARBProcPtr)(GLint location, GLsizei count, const GLint *value);
    typedef void (*glUniformMatrix2fvARBProcPtr)(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
    typedef void (*glUniformMatrix3fvARBProcPtr)(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
    typedef void (*glUniformMatrix4fvARBProcPtr)(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
    typedef void (*glGetObjectParameterfvARBProcPtr)(GLhandleARB obj, GLenum pname, GLfloat *params);
    typedef void (*glGetObjectParameterivARBProcPtr)(GLhandleARB obj, GLenum pname, GLint *params);
    typedef void (*glGetInfoLogARBProcPtr)(GLhandleARB obj, GLsizei maxLength, GLsizei *length, GLcharARB *infoLog);
    typedef void (*glGetAttachedObjectsARBProcPtr)(GLhandleARB containerObj, GLsizei maxCount, GLsizei *count, GLhandleARB *obj);
    typedef GLint (*glGetUniformLocationARBProcPtr)(GLhandleARB programObj, const GLcharARB *name);
    typedef void (*glGetActiveUniformARBProcPtr)(GLhandleARB programObj, GLuint index, GLsizei maxLength, GLsizei *length, GLint *size, GLenum *type, GLcharARB *name);
    typedef void (*glGetUniformfvARBProcPtr)(GLhandleARB programObj, GLint location, GLfloat *params);
    typedef void (*glGetUniformivARBProcPtr)(GLhandleARB programObj, GLint location, GLint *params);
    typedef void (*glGetShaderSourceARBProcPtr)(GLhandleARB obj, GLsizei maxLength, GLsizei *length, GLcharARB *source);
    typedef void (*glBindAttribLocationARBProcPtr)(GLhandleARB programObj, GLuint index, const GLcharARB *name);
    typedef void (*glGetActiveAttribARBProcPtr)(GLhandleARB programObj, GLuint index, GLsizei maxLength, GLsizei *length, GLint *size, GLenum *type, GLcharARB *name);
    typedef GLint (*glGetAttribLocationARBProcPtr)(GLhandleARB programObj, const GLcharARB *name);
    typedef void (*glBindBufferARBProcPtr)(GLenum target, GLuint buffer);
    typedef void (*glDeleteBuffersARBProcPtr)(GLsizei n, const GLuint *buffers);
    typedef void (*glGenBuffersARBProcPtr)(GLsizei n, GLuint *buffers);
    typedef GLboolean (*glIsBufferARBProcPtr)(GLuint buffer);
    typedef void (*glBufferDataARBProcPtr)(GLenum target, GLsizeiptrARB size, const GLvoid *data, GLenum usage);
    typedef void (*glBufferSubDataARBProcPtr)(GLenum target, GLintptrARB offset, GLsizeiptrARB size, const GLvoid *data);
    typedef void (*glGetBufferSubDataARBProcPtr)(GLenum target, GLintptrARB offset, GLsizeiptrARB size, GLvoid *data);
    typedef GLvoid *(*glMapBufferARBProcPtr)(GLenum target, GLenum access);
    typedef GLboolean (*glUnmapBufferARBProcPtr)(GLenum target);
    typedef void (*glGetBufferParameterivARBProcPtr)(GLenum target, GLenum pname, GLint *params);
    typedef void (*glGetBufferPointervARBProcPtr)(GLenum target, GLenum pname, GLvoid **params);
    typedef void (*glDrawBuffersARBProcPtr)(GLsizei n, const GLenum *bufs);
    typedef void (*glClampColorARBProcPtr)(GLenum target, GLenum clamp);
    typedef void (*glDrawArraysInstancedARBProcPtr)(GLenum mode, GLint first, GLsizei count, GLsizei primcount);
    typedef void (*glDrawElementsInstancedARBProcPtr)(GLenum mode, GLsizei count, GLenum type, const GLvoid *indices, GLsizei primcount);
    typedef void (*glVertexAttribDivisorARBProcPtr)(GLuint index, GLuint divisor);
    typedef void (*glGetUniformIndicesProcPtr)(GLuint program, GLsizei uniformCount, const GLchar** uniformNames, GLuint* uniformIndices);
    typedef void (*glGetActiveUniformsivProcPtr)(GLuint program, GLsizei uniformCount, const GLuint* uniformIndices, GLenum pname, GLint* params);
    typedef void (*glGetActiveUniformNameProcPtr)(GLuint program, GLuint uniformIndex, GLsizei bufSize, GLsizei* length, GLchar* uniformName);
    typedef GLuint (*glGetUniformBlockIndexProcPtr)(GLuint program, const GLchar* uniformBlockName);
    typedef void (*glGetActiveUniformBlockivProcPtr)(GLuint program, GLuint uniformBlockIndex, GLenum pname, GLint* params);
    typedef void (*glGetActiveUniformBlockNameProcPtr)(GLuint program, GLuint uniformBlockIndex, GLsizei bufSize, GLsizei* length, GLchar* uniformBlockName);
    typedef void (*glBindBufferRangeProcPtr)(GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size);
    typedef void (*glBindBufferBaseProcPtr)(GLenum target, GLuint index, GLuint buffer);
    typedef void (*glGetIntegeri_vProcPtr)(GLenum pname, GLuint index, GLint* data);
    typedef void (*glUniformBlockBindingProcPtr)(GLuint program, GLuint uniformBlockIndex, GLuint uniformBlockBinding);
    typedef void (*glBlendColorEXTProcPtr)(GLclampf, GLclampf, GLclampf, GLclampf);
    typedef void (*glBlendEquationEXTProcPtr)(GLenum);
    typedef void (*glLockArraysEXTProcPtr)(GLint, GLsizei);
    typedef void (*glUnlockArraysEXTProcPtr)(void);
    typedef void (*glDrawRangeElementsEXTProcPtr)(GLenum, GLuint, GLuint, GLsizei, GLenum, const GLvoid *);
    typedef void (*glSecondaryColor3bEXTProcPtr)(GLbyte, GLbyte, GLbyte);
    typedef void (*glSecondaryColor3bvEXTProcPtr)(const GLbyte *);
    typedef void (*glSecondaryColor3dEXTProcPtr)(GLdouble, GLdouble, GLdouble);
    typedef void (*glSecondaryColor3dvEXTProcPtr)(const GLdouble *);
    typedef void (*glSecondaryColor3fEXTProcPtr)(GLfloat, GLfloat, GLfloat);
    typedef void (*glSecondaryColor3fvEXTProcPtr)(const GLfloat *);
    typedef void (*glSecondaryColor3iEXTProcPtr)(GLint, GLint, GLint);
    typedef void (*glSecondaryColor3ivEXTProcPtr)(const GLint *);
    typedef void (*glSecondaryColor3sEXTProcPtr)(GLshort, GLshort, GLshort);
    typedef void (*glSecondaryColor3svEXTProcPtr)(const GLshort *);
    typedef void (*glSecondaryColor3ubEXTProcPtr)(GLubyte, GLubyte, GLubyte);
    typedef void (*glSecondaryColor3ubvEXTProcPtr)(const GLubyte *);
    typedef void (*glSecondaryColor3uiEXTProcPtr)(GLuint, GLuint, GLuint);
    typedef void (*glSecondaryColor3uivEXTProcPtr)(const GLuint *);
    typedef void (*glSecondaryColor3usEXTProcPtr)(GLushort, GLushort, GLushort);
    typedef void (*glSecondaryColor3usvEXTProcPtr)(const GLushort *);
    typedef void (*glSecondaryColorPointerEXTProcPtr)(GLint, GLenum, GLsizei, const GLvoid *);
    typedef void (*glMultiDrawArraysEXTProcPtr)(GLenum, const GLint *, const GLsizei *, GLsizei);
    typedef void (*glMultiDrawElementsEXTProcPtr)(GLenum, const GLsizei *, GLenum, const GLvoid* *, GLsizei);
    typedef void (*glFogCoordfEXTProcPtr)(GLfloat);
    typedef void (*glFogCoordfvEXTProcPtr)(const GLfloat *);
    typedef void (*glFogCoorddEXTProcPtr)(GLdouble);
    typedef void (*glFogCoorddvEXTProcPtr)(const GLdouble *);
    typedef void (*glFogCoordPointerEXTProcPtr)(GLenum, GLsizei, const GLvoid *);
    typedef void (*glBlendFuncSeparateEXTProcPtr)(GLenum, GLenum, GLenum, GLenum);
    typedef void (*glActiveStencilFaceEXTProcPtr)(GLenum face);
    typedef void (*glDepthBoundsEXTProcPtr)(GLclampd zmin, GLclampd zmax);
    typedef void (*glBlendEquationSeparateEXTProcPtr)(GLenum modeRGB, GLenum modeAlpha);
    typedef GLboolean (*glIsRenderbufferEXTProcPtr)(GLuint renderbuffer);
    typedef void (*glBindRenderbufferEXTProcPtr)(GLenum target, GLuint renderbuffer);
    typedef void (*glDeleteRenderbuffersEXTProcPtr)(GLsizei n, const GLuint *renderbuffers);
    typedef void (*glGenRenderbuffersEXTProcPtr)(GLsizei n, GLuint *renderbuffers);
    typedef void (*glRenderbufferStorageEXTProcPtr)(GLenum target, GLenum internalformat, GLsizei width, GLsizei height);
    typedef void (*glGetRenderbufferParameterivEXTProcPtr)(GLenum target, GLenum pname, GLint *params);
    typedef GLboolean (*glIsFramebufferEXTProcPtr)(GLuint framebuffer);
    typedef void (*glBindFramebufferEXTProcPtr)(GLenum target, GLuint framebuffer);
    typedef void (*glDeleteFramebuffersEXTProcPtr)(GLsizei n, const GLuint *framebuffers);
    typedef void (*glGenFramebuffersEXTProcPtr)(GLsizei n, GLuint *framebuffers);
    typedef GLenum (*glCheckFramebufferStatusEXTProcPtr)(GLenum target);
    typedef void (*glFramebufferTexture1DEXTProcPtr)(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
    typedef void (*glFramebufferTexture2DEXTProcPtr)(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
    typedef void (*glFramebufferTexture3DEXTProcPtr)(GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level, GLint zoffset);
    typedef void (*glFramebufferRenderbufferEXTProcPtr)(GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer);
    typedef void (*glGetFramebufferAttachmentParameterivEXTProcPtr)(GLenum target, GLenum attachment, GLenum pname, GLint *params);
    typedef void (*glGenerateMipmapEXTProcPtr)(GLenum target);
    typedef void (*glBlitFramebufferEXTProcPtr)(GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);
    typedef void (*glRenderbufferStorageMultisampleEXTProcPtr)(GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);
    typedef void (*glProgramParameteriEXTProcPtr)(GLuint program, GLenum pname, GLint value);
    typedef void (*glFramebufferTextureEXTProcPtr)(GLenum target, GLenum attachment, GLuint texture, GLint level);
    typedef void (*glFramebufferTextureFaceEXTProcPtr)(GLenum target, GLenum attachment, GLuint texture, GLint level, GLenum face);
    typedef void (*glFramebufferTextureLayerEXTProcPtr)(GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer);
    typedef GLboolean (*glIsRenderbufferProcPtr)(GLuint);
    typedef void (*glBindRenderbufferProcPtr)(GLenum, GLuint);
    typedef void (*glDeleteRenderbuffersProcPtr)(GLsizei, const GLuint *);
    typedef void (*glGenRenderbuffersProcPtr)(GLsizei, GLuint *);
    typedef void (*glRenderbufferStorageProcPtr)(GLenum, GLenum, GLsizei, GLsizei);
    typedef void (*glGetRenderbufferParameterivProcPtr)(GLenum, GLenum, GLint *);
    typedef GLboolean (*glIsFramebufferProcPtr)(GLuint);
    typedef void (*glBindFramebufferProcPtr)(GLenum, GLuint);
    typedef void (*glDeleteFramebuffersProcPtr)(GLsizei, const GLuint *);
    typedef void (*glGenFramebuffersProcPtr)(GLsizei, GLuint *);
    typedef GLenum (*glCheckFramebufferStatusProcPtr)(GLenum);
    typedef void (*glFramebufferTexture1DProcPtr)(GLenum, GLenum, GLenum, GLuint, GLint);
    typedef void (*glFramebufferTexture2DProcPtr)(GLenum, GLenum, GLenum, GLuint, GLint);
    typedef void (*glFramebufferTexture3DProcPtr)(GLenum, GLenum, GLenum, GLuint, GLint, GLint);
    typedef void (*glFramebufferRenderbufferProcPtr)(GLenum, GLenum, GLenum, GLuint);
    typedef void (*glGetFramebufferAttachmentParameterivProcPtr)(GLenum, GLenum, GLenum, GLint *);
    typedef void (*glGenerateMipmapProcPtr)(GLenum);
    typedef void (*glBlitFramebufferProcPtr)(GLint, GLint, GLint, GLint, GLint, GLint, GLint, GLint, GLbitfield, GLenum);
    typedef void (*glRenderbufferStorageMultisampleProcPtr)(GLenum, GLsizei, GLenum, GLsizei, GLsizei);
    typedef void (*glFramebufferTextureLayerProcPtr)(GLenum, GLenum, GLuint, GLint, GLint);
    typedef void (*glBindBufferRangeEXTProcPtr)(GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size);
    typedef void (*glBindBufferOffsetEXTProcPtr)(GLenum target, GLuint index, GLuint buffer, GLintptr offset);
    typedef void (*glBindBufferBaseEXTProcPtr)(GLenum target, GLuint index, GLuint buffer);
    typedef void (*glBeginTransformFeedbackEXTProcPtr)(GLenum primitiveMode);
    typedef void (*glEndTransformFeedbackEXTProcPtr)(void);
    typedef void (*glTransformFeedbackVaryingsEXTProcPtr)(GLuint program, GLsizei count, const GLchar **varyings, GLenum bufferMode);
    typedef void (*glGetTransformFeedbackVaryingEXTProcPtr)(GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLsizei *size, GLenum *type, GLchar *name);
    typedef void (*glGetIntegerIndexedvEXTProcPtr)(GLenum param, GLuint index, GLint *values);
    typedef void (*glGetBooleanIndexedvEXTProcPtr)(GLenum param, GLuint index, GLboolean *values);
    typedef void (*glUniformBufferEXTProcPtr)(GLuint program, GLint location, GLuint buffer);
    typedef GLint (*glGetUniformBufferSizeEXTProcPtr)(GLuint program, GLint location);
    typedef GLintptr (*glGetUniformOffsetEXTProcPtr)(GLuint program, GLint location);
    typedef void (*glClearColorIiEXTProcPtr)( GLint r, GLint g, GLint b, GLint a );
    typedef void (*glClearColorIuiEXTProcPtr)( GLuint r, GLuint g, GLuint b, GLuint a );
    typedef void (*glTexParameterIivEXTProcPtr)( GLenum target, GLenum pname, GLint *params );
    typedef void (*glTexParameterIuivEXTProcPtr)( GLenum target, GLenum pname, GLuint *params );
    typedef void (*glGetTexParameterIivEXTProcPtr)( GLenum target, GLenum pname, GLint *params);
    typedef void (*glGetTexParameterIuivEXTProcPtr)( GLenum target, GLenum pname, GLuint *params);
    typedef void (*glVertexAttribI1iEXTProcPtr)(GLuint index, GLint x);
    typedef void (*glVertexAttribI2iEXTProcPtr)(GLuint index, GLint x, GLint y);
    typedef void (*glVertexAttribI3iEXTProcPtr)(GLuint index, GLint x, GLint y, GLint z);
    typedef void (*glVertexAttribI4iEXTProcPtr)(GLuint index, GLint x, GLint y, GLint z, GLint w);
    typedef void (*glVertexAttribI1uiEXTProcPtr)(GLuint index, GLuint x);
    typedef void (*glVertexAttribI2uiEXTProcPtr)(GLuint index, GLuint x, GLuint y);
    typedef void (*glVertexAttribI3uiEXTProcPtr)(GLuint index, GLuint x, GLuint y, GLuint z);
    typedef void (*glVertexAttribI4uiEXTProcPtr)(GLuint index, GLuint x, GLuint y, GLuint z, GLuint w);
    typedef void (*glVertexAttribI1ivEXTProcPtr)(GLuint index, const GLint *v);
    typedef void (*glVertexAttribI2ivEXTProcPtr)(GLuint index, const GLint *v);
    typedef void (*glVertexAttribI3ivEXTProcPtr)(GLuint index, const GLint *v);
    typedef void (*glVertexAttribI4ivEXTProcPtr)(GLuint index, const GLint *v);
    typedef void (*glVertexAttribI1uivEXTProcPtr)(GLuint index, const GLuint *v);
    typedef void (*glVertexAttribI2uivEXTProcPtr)(GLuint index, const GLuint *v);
    typedef void (*glVertexAttribI3uivEXTProcPtr)(GLuint index, const GLuint *v);
    typedef void (*glVertexAttribI4uivEXTProcPtr)(GLuint index, const GLuint *v);
    typedef void (*glVertexAttribI4bvEXTProcPtr)(GLuint index, const GLbyte *v);
    typedef void (*glVertexAttribI4svEXTProcPtr)(GLuint index, const GLshort *v);
    typedef void (*glVertexAttribI4ubvEXTProcPtr)(GLuint index, const GLubyte *v);
    typedef void (*glVertexAttribI4usvEXTProcPtr)(GLuint index, const GLushort *v);
    typedef void (*glVertexAttribIPointerEXTProcPtr)(GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
    typedef void (*glGetVertexAttribIivEXTProcPtr)(GLuint index, GLenum pname, GLint *params);
    typedef void (*glGetVertexAttribIuivEXTProcPtr)(GLuint index, GLenum pname, GLuint *params);
    typedef void (*glUniform1uiEXTProcPtr)(GLint location, GLuint v0);
    typedef void (*glUniform2uiEXTProcPtr)(GLint location, GLuint v0, GLuint v1);
    typedef void (*glUniform3uiEXTProcPtr)(GLint location, GLuint v0, GLuint v1, GLuint v2);
    typedef void (*glUniform4uiEXTProcPtr)(GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
    typedef void (*glUniform1uivEXTProcPtr)(GLint location, GLsizei count, const GLuint *value);
    typedef void (*glUniform2uivEXTProcPtr)(GLint location, GLsizei count, const GLuint *value);
    typedef void (*glUniform3uivEXTProcPtr)(GLint location, GLsizei count, const GLuint *value);
    typedef void (*glUniform4uivEXTProcPtr)(GLint location, GLsizei count, const GLuint *value);
    typedef void (*glGetUniformuivEXTProcPtr)(GLuint program, GLint location, GLuint *params);
    typedef void (*glBindFragDataLocationEXTProcPtr)(GLuint program, GLuint colorNumber, const GLchar *name);
    typedef GLint (*glGetFragDataLocationEXTProcPtr)(GLuint program, const GLchar *name);
    typedef void (*glColorMaskIndexedEXTProcPtr)(GLuint index, GLboolean r, GLboolean g, GLboolean b, GLboolean a);
    typedef void (*glEnableIndexedEXTProcPtr)(GLenum target, GLuint index);
    typedef void (*glDisableIndexedEXTProcPtr)(GLenum target, GLuint index);
    typedef GLboolean (*glIsEnabledIndexedEXTProcPtr)(GLenum target, GLuint index);
    typedef void (*glProvokingVertexEXTProcPtr)(GLenum mode);
    typedef void (*glTextureRangeAPPLEProcPtr)(GLenum target, GLsizei length, const GLvoid *pointer);
    typedef void (*glGetTexParameterPointervAPPLEProcPtr)(GLenum target, GLenum pname, GLvoid **params);
    typedef void (*glVertexArrayRangeAPPLEProcPtr)(GLsizei length, const GLvoid *pointer);
    typedef void (*glFlushVertexArrayRangeAPPLEProcPtr)(GLsizei length, const GLvoid *pointer);
    typedef void (*glVertexArrayParameteriAPPLEProcPtr)(GLenum pname, GLint param);
    typedef void (*glBindVertexArrayAPPLEProcPtr)(GLuint id);
    typedef void (*glDeleteVertexArraysAPPLEProcPtr)(GLsizei n, const GLuint *ids);
    typedef void (*glGenVertexArraysAPPLEProcPtr)(GLsizei n, GLuint *ids);
    typedef GLboolean (*glIsVertexArrayAPPLEProcPtr)(GLuint id);
    typedef void (*glGenFencesAPPLEProcPtr)(GLsizei n, GLuint *fences);
    typedef void (*glDeleteFencesAPPLEProcPtr)(GLsizei n, const GLuint *fences);
    typedef void (*glSetFenceAPPLEProcPtr)(GLuint fence);
    typedef GLboolean (*glIsFenceAPPLEProcPtr)(GLuint fence);
    typedef GLboolean (*glTestFenceAPPLEProcPtr)(GLuint fence);
    typedef void (*glFinishFenceAPPLEProcPtr)(GLuint fence);
    typedef GLboolean (*glTestObjectAPPLEProcPtr)(GLenum object, GLuint name);
    typedef void (*glFinishObjectAPPLEProcPtr)(GLenum object, GLuint name);
    typedef void (*glElementPointerAPPLEProcPtr)(GLenum type, const GLvoid *pointer);
    typedef void (*glDrawElementArrayAPPLEProcPtr)(GLenum mode, GLint first, GLsizei count);
    typedef void (*glDrawRangeElementArrayAPPLEProcPtr)(GLenum mode, GLuint start, GLuint end, GLint first, GLsizei count);
    typedef void (*glMultiDrawElementArrayAPPLEProcPtr)(GLenum mode, const GLint *first, const GLsizei *count, GLsizei primcount);
    typedef void (*glMultiDrawRangeElementArrayAPPLEProcPtr)(GLenum mode, GLuint start, GLuint end, const GLint *first, const GLsizei *count, GLsizei primcount);
    typedef void (*glFlushRenderAPPLEProcPtr)(void);
    typedef void (*glFinishRenderAPPLEProcPtr)(void);
    typedef void (*glSwapAPPLEProcPtr)(void);
    typedef void (*glEnableVertexAttribAPPLEProcPtr)(GLuint index, GLenum pname);
    typedef void (*glDisableVertexAttribAPPLEProcPtr)(GLuint index, GLenum pname);
    typedef GLboolean (*glIsVertexAttribEnabledAPPLEProcPtr)(GLuint index, GLenum pname);
    typedef void (*glMapVertexAttrib1dAPPLEProcPtr)(GLuint index, GLuint size, GLdouble u1, GLdouble u2, GLint stride, GLint order, const GLdouble *points);
    typedef void (*glMapVertexAttrib1fAPPLEProcPtr)(GLuint index, GLuint size, GLfloat u1, GLfloat u2, GLint stride, GLint order, const GLfloat *points);
    typedef void (*glMapVertexAttrib2dAPPLEProcPtr)(GLuint index, GLuint size, GLdouble u1, GLdouble u2, GLint ustride, GLint uorder, GLdouble v1, GLdouble v2, GLint vstride, GLint vorder, const GLdouble *points);
    typedef void (*glMapVertexAttrib2fAPPLEProcPtr)(GLuint index, GLuint size, GLfloat u1, GLfloat u2, GLint ustride, GLint uorder, GLfloat v1, GLfloat v2, GLint vstride, GLint vorder, const GLfloat *points);
    typedef void (*glBufferParameteriAPPLEProcPtr)(GLenum target, GLenum pname, GLint param);
    typedef void (*glFlushMappedBufferRangeAPPLEProcPtr)(GLenum target, GLintptr offset, GLsizeiptr size);
    typedef GLenum (*glObjectPurgeableAPPLEProcPtr)(GLenum objectType, GLuint name, GLenum option);
    typedef GLenum (*glObjectUnpurgeableAPPLEProcPtr)(GLenum objectType, GLuint name, GLenum option);
    typedef void (*glGetObjectParameterivAPPLEProcPtr)(GLenum objectType, GLuint name, GLenum pname, GLint* params);
    typedef void (*glPNTrianglesiATIProcPtr)(GLenum pname, GLint param);
    typedef void (*glPNTrianglesfATIProcPtr)(GLenum pname, GLfloat param);
    typedef void (*glBlendEquationSeparateATIProcPtr)(GLenum equationRGB, GLenum equationAlpha);
    typedef void (*glStencilOpSeparateATIProcPtr)(GLenum face, GLenum sfail, GLenum dpfail, GLenum dppass);
    typedef void (*glStencilFuncSeparateATIProcPtr)(GLenum frontfunc, GLenum backfunc, GLint ref, GLuint mask);
    typedef void (*glPNTrianglesiATIXProcPtr)(GLenum pname, GLint param);
    typedef void (*glPNTrianglesfATIXProcPtr)(GLenum pname, GLfloat param);
    typedef void (*glPointParameteriNVProcPtr)(GLenum pname, GLint param);
    typedef void (*glPointParameterivNVProcPtr)(GLenum pname, const GLint *params);
    typedef void (*glBeginConditionalRenderNVProcPtr)(GLuint id, GLenum mode);
    typedef void (*glEndConditionalRenderNVProcPtr)(void);
    typedef void (*glAccumProcPtr)(GLenum op, GLfloat value);
    typedef void (*glAlphaFuncProcPtr)(GLenum func, GLclampf ref);
    typedef GLboolean (*glAreTexturesResidentProcPtr)(GLsizei n, const GLuint *textures, GLboolean *residences);
    typedef void (*glArrayElementProcPtr)(GLint i);
    typedef void (*glBeginProcPtr)(GLenum mode);
    typedef void (*glBindTextureProcPtr)(GLenum target, GLuint texture);
    typedef void (*glBitmapProcPtr)(GLsizei width, GLsizei height, GLfloat xorig, GLfloat yorig, GLfloat xmove, GLfloat ymove, const GLubyte *bitmap);
    typedef void (*glBlendColorProcPtr)(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
    typedef void (*glBlendEquationProcPtr)(GLenum mode);
    typedef void (*glBlendEquationSeparateProcPtr)(GLenum modeRGB, GLenum modeAlpha);
    typedef void (*glBlendFuncProcPtr)(GLenum sfactor, GLenum dfactor);
    typedef void (*glCallListProcPtr)(GLuint list);
    typedef void (*glCallListsProcPtr)(GLsizei n, GLenum type, const GLvoid *lists);
    typedef void (*glClearProcPtr)(GLbitfield mask);
    typedef void (*glClearAccumProcPtr)(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
    typedef void (*glClearColorProcPtr)(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
    typedef void (*glClearDepthProcPtr)(GLclampd depth);
    typedef void (*glClearIndexProcPtr)(GLfloat c);
    typedef void (*glClearStencilProcPtr)(GLint s);
    typedef void (*glClipPlaneProcPtr)(GLenum plane, const GLdouble *equation);
    typedef void (*glColor3bProcPtr)(GLbyte red, GLbyte green, GLbyte blue);
    typedef void (*glColor3bvProcPtr)(const GLbyte *v);
    typedef void (*glColor3dProcPtr)(GLdouble red, GLdouble green, GLdouble blue);
    typedef void (*glColor3dvProcPtr)(const GLdouble *v);
    typedef void (*glColor3fProcPtr)(GLfloat red, GLfloat green, GLfloat blue);
    typedef void (*glColor3fvProcPtr)(const GLfloat *v);
    typedef void (*glColor3iProcPtr)(GLint red, GLint green, GLint blue);
    typedef void (*glColor3ivProcPtr)(const GLint *v);
    typedef void (*glColor3sProcPtr)(GLshort red, GLshort green, GLshort blue);
    typedef void (*glColor3svProcPtr)(const GLshort *v);
    typedef void (*glColor3ubProcPtr)(GLubyte red, GLubyte green, GLubyte blue);
    typedef void (*glColor3ubvProcPtr)(const GLubyte *v);
    typedef void (*glColor3uiProcPtr)(GLuint red, GLuint green, GLuint blue);
    typedef void (*glColor3uivProcPtr)(const GLuint *v);
    typedef void (*glColor3usProcPtr)(GLushort red, GLushort green, GLushort blue);
    typedef void (*glColor3usvProcPtr)(const GLushort *v);
    typedef void (*glColor4bProcPtr)(GLbyte red, GLbyte green, GLbyte blue, GLbyte alpha);
    typedef void (*glColor4bvProcPtr)(const GLbyte *v);
    typedef void (*glColor4dProcPtr)(GLdouble red, GLdouble green, GLdouble blue, GLdouble alpha);
    typedef void (*glColor4dvProcPtr)(const GLdouble *v);
    typedef void (*glColor4fProcPtr)(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
    typedef void (*glColor4fvProcPtr)(const GLfloat *v);
    typedef void (*glColor4iProcPtr)(GLint red, GLint green, GLint blue, GLint alpha);
    typedef void (*glColor4ivProcPtr)(const GLint *v);
    typedef void (*glColor4sProcPtr)(GLshort red, GLshort green, GLshort blue, GLshort alpha);
    typedef void (*glColor4svProcPtr)(const GLshort *v);
    typedef void (*glColor4ubProcPtr)(GLubyte red, GLubyte green, GLubyte blue, GLubyte alpha);
    typedef void (*glColor4ubvProcPtr)(const GLubyte *v);
    typedef void (*glColor4uiProcPtr)(GLuint red, GLuint green, GLuint blue, GLuint alpha);
    typedef void (*glColor4uivProcPtr)(const GLuint *v);
    typedef void (*glColor4usProcPtr)(GLushort red, GLushort green, GLushort blue, GLushort alpha);
    typedef void (*glColor4usvProcPtr)(const GLushort *v);
    typedef void (*glColorMaskProcPtr)(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);
    typedef void (*glColorMaterialProcPtr)(GLenum face, GLenum mode);
    typedef void (*glColorPointerProcPtr)(GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
    typedef void (*glColorSubTableProcPtr)(GLenum target, GLsizei start, GLsizei count, GLenum format, GLenum type, const GLvoid *data);
    typedef void (*glColorTableProcPtr)(GLenum target, GLenum internalformat, GLsizei width, GLenum format, GLenum type, const GLvoid *table);
    typedef void (*glColorTableParameterfvProcPtr)(GLenum target, GLenum pname, const GLfloat *params);
    typedef void (*glColorTableParameterivProcPtr)(GLenum target, GLenum pname, const GLint *params);
    typedef void (*glConvolutionFilter1DProcPtr)(GLenum target, GLenum internalformat, GLsizei width, GLenum format, GLenum type, const GLvoid *image);
    typedef void (*glConvolutionFilter2DProcPtr)(GLenum target, GLenum internalformat, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *image);
    typedef void (*glConvolutionParameterfProcPtr)(GLenum target, GLenum pname, GLfloat params);
    typedef void (*glConvolutionParameterfvProcPtr)(GLenum target, GLenum pname, const GLfloat *params);
    typedef void (*glConvolutionParameteriProcPtr)(GLenum target, GLenum pname, GLint params);
    typedef void (*glConvolutionParameterivProcPtr)(GLenum target, GLenum pname, const GLint *params);
    typedef void (*glCopyColorSubTableProcPtr)(GLenum target, GLsizei start, GLint x, GLint y, GLsizei width);
    typedef void (*glCopyColorTableProcPtr)(GLenum target, GLenum internalformat, GLint x, GLint y, GLsizei width);
    typedef void (*glCopyConvolutionFilter1DProcPtr)(GLenum target, GLenum internalformat, GLint x, GLint y, GLsizei width);
    typedef void (*glCopyConvolutionFilter2DProcPtr)(GLenum target, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height);
    typedef void (*glCopyPixelsProcPtr)(GLint x, GLint y, GLsizei width, GLsizei height, GLenum type);
    typedef void (*glCopyTexImage1DProcPtr)(GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLint border);
    typedef void (*glCopyTexImage2DProcPtr)(GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);
    typedef void (*glCopyTexSubImage1DProcPtr)(GLenum target, GLint level, GLint xoffset, GLint x, GLint y, GLsizei width);
    typedef void (*glCopyTexSubImage2DProcPtr)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);
    typedef void (*glCopyTexSubImage3DProcPtr)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height);
    typedef void (*glCullFaceProcPtr)(GLenum mode);
    typedef void (*glDeleteListsProcPtr)(GLuint list, GLsizei range);
    typedef void (*glDeleteTexturesProcPtr)(GLsizei n, const GLuint *textures);
    typedef void (*glDepthFuncProcPtr)(GLenum func);
    typedef void (*glDepthMaskProcPtr)(GLboolean flag);
    typedef void (*glDepthRangeProcPtr)(GLclampd zNear, GLclampd zFar);
    typedef void (*glDisableProcPtr)(GLenum cap);
    typedef void (*glDisableClientStateProcPtr)(GLenum array);
    typedef void (*glDrawArraysProcPtr)(GLenum mode, GLint first, GLsizei count);
    typedef void (*glDrawBufferProcPtr)(GLenum mode);
    typedef void (*glDrawElementsProcPtr)(GLenum mode, GLsizei count, GLenum type, const GLvoid *indices);
    typedef void (*glDrawPixelsProcPtr)(GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *pixels);
    typedef void (*glDrawRangeElementsProcPtr)(GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid *indices);
    typedef void (*glEdgeFlagProcPtr)(GLboolean flag);
    typedef void (*glEdgeFlagPointerProcPtr)(GLsizei stride, const GLvoid *pointer);
    typedef void (*glEdgeFlagvProcPtr)(const GLboolean *flag);
    typedef void (*glEnableProcPtr)(GLenum cap);
    typedef void (*glEnableClientStateProcPtr)(GLenum array);
    typedef void (*glEndProcPtr)(void);
    typedef void (*glEndListProcPtr)(void);
    typedef void (*glEvalCoord1dProcPtr)(GLdouble u);
    typedef void (*glEvalCoord1dvProcPtr)(const GLdouble *u);
    typedef void (*glEvalCoord1fProcPtr)(GLfloat u);
    typedef void (*glEvalCoord1fvProcPtr)(const GLfloat *u);
    typedef void (*glEvalCoord2dProcPtr)(GLdouble u, GLdouble v);
    typedef void (*glEvalCoord2dvProcPtr)(const GLdouble *u);
    typedef void (*glEvalCoord2fProcPtr)(GLfloat u, GLfloat v);
    typedef void (*glEvalCoord2fvProcPtr)(const GLfloat *u);
    typedef void (*glEvalMesh1ProcPtr)(GLenum mode, GLint i1, GLint i2);
    typedef void (*glEvalMesh2ProcPtr)(GLenum mode, GLint i1, GLint i2, GLint j1, GLint j2);
    typedef void (*glEvalPoint1ProcPtr)(GLint i);
    typedef void (*glEvalPoint2ProcPtr)(GLint i, GLint j);
    typedef void (*glFeedbackBufferProcPtr)(GLsizei size, GLenum type, GLfloat *buffer);
    typedef void (*glFinishProcPtr)(void);
    typedef void (*glFlushProcPtr)(void);
    typedef void (*glFogfProcPtr)(GLenum pname, GLfloat param);
    typedef void (*glFogfvProcPtr)(GLenum pname, const GLfloat *params);
    typedef void (*glFogiProcPtr)(GLenum pname, GLint param);
    typedef void (*glFogivProcPtr)(GLenum pname, const GLint *params);
    typedef void (*glFrontFaceProcPtr)(GLenum mode);
    typedef void (*glFrustumProcPtr)(GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble zNear, GLdouble zFar);
    typedef GLuint (*glGenListsProcPtr)(GLsizei range);
    typedef void (*glGenTexturesProcPtr)(GLsizei n, GLuint *textures);
    typedef void (*glGetBooleanvProcPtr)(GLenum pname, GLboolean *params);
    typedef void (*glGetClipPlaneProcPtr)(GLenum plane, GLdouble *equation);
    typedef void (*glGetColorTableProcPtr)(GLenum target, GLenum format, GLenum type, GLvoid *table);
    typedef void (*glGetColorTableParameterfvProcPtr)(GLenum target, GLenum pname, GLfloat *params);
    typedef void (*glGetColorTableParameterivProcPtr)(GLenum target, GLenum pname, GLint *params);
    typedef void (*glGetConvolutionFilterProcPtr)(GLenum target, GLenum format, GLenum type, GLvoid *image);
    typedef void (*glGetConvolutionParameterfvProcPtr)(GLenum target, GLenum pname, GLfloat *params);
    typedef void (*glGetConvolutionParameterivProcPtr)(GLenum target, GLenum pname, GLint *params);
    typedef void (*glGetDoublevProcPtr)(GLenum pname, GLdouble *params);
    typedef GLenum (*glGetErrorProcPtr)(void);
    typedef void (*glGetFloatvProcPtr)(GLenum pname, GLfloat *params);
    typedef void (*glGetHistogramProcPtr)(GLenum target, GLboolean reset, GLenum format, GLenum type, GLvoid *values);
    typedef void (*glGetHistogramParameterfvProcPtr)(GLenum target, GLenum pname, GLfloat *params);
    typedef void (*glGetHistogramParameterivProcPtr)(GLenum target, GLenum pname, GLint *params);
    typedef void (*glGetIntegervProcPtr)(GLenum pname, GLint *params);
    typedef void (*glGetLightfvProcPtr)(GLenum light, GLenum pname, GLfloat *params);
    typedef void (*glGetLightivProcPtr)(GLenum light, GLenum pname, GLint *params);
    typedef void (*glGetMapdvProcPtr)(GLenum target, GLenum query, GLdouble *v);
    typedef void (*glGetMapfvProcPtr)(GLenum target, GLenum query, GLfloat *v);
    typedef void (*glGetMapivProcPtr)(GLenum target, GLenum query, GLint *v);
    typedef void (*glGetMaterialfvProcPtr)(GLenum face, GLenum pname, GLfloat *params);
    typedef void (*glGetMaterialivProcPtr)(GLenum face, GLenum pname, GLint *params);
    typedef void (*glGetMinmaxProcPtr)(GLenum target, GLboolean reset, GLenum format, GLenum type, GLvoid *values);
    typedef void (*glGetMinmaxParameterfvProcPtr)(GLenum target, GLenum pname, GLfloat *params);
    typedef void (*glGetMinmaxParameterivProcPtr)(GLenum target, GLenum pname, GLint *params);
    typedef void (*glGetPixelMapfvProcPtr)(GLenum map, GLfloat *values);
    typedef void (*glGetPixelMapuivProcPtr)(GLenum map, GLuint *values);
    typedef void (*glGetPixelMapusvProcPtr)(GLenum map, GLushort *values);
    typedef void (*glGetPointervProcPtr)(GLenum pname, GLvoid* *params);
    typedef void (*glGetPolygonStippleProcPtr)(GLubyte *mask);
    typedef void (*glGetSeparableFilterProcPtr)(GLenum target, GLenum format, GLenum type, GLvoid *row, GLvoid *column, GLvoid *span);
    typedef const GLubyte * (*glGetStringProcPtr)(GLenum name);
    typedef void (*glGetTexEnvfvProcPtr)(GLenum target, GLenum pname, GLfloat *params);
    typedef void (*glGetTexEnvivProcPtr)(GLenum target, GLenum pname, GLint *params);
    typedef void (*glGetTexGendvProcPtr)(GLenum coord, GLenum pname, GLdouble *params);
    typedef void (*glGetTexGenfvProcPtr)(GLenum coord, GLenum pname, GLfloat *params);
    typedef void (*glGetTexGenivProcPtr)(GLenum coord, GLenum pname, GLint *params);
    typedef void (*glGetTexImageProcPtr)(GLenum target, GLint level, GLenum format, GLenum type, GLvoid *pixels);
    typedef void (*glGetTexLevelParameterfvProcPtr)(GLenum target, GLint level, GLenum pname, GLfloat *params);
    typedef void (*glGetTexLevelParameterivProcPtr)(GLenum target, GLint level, GLenum pname, GLint *params);
    typedef void (*glGetTexParameterfvProcPtr)(GLenum target, GLenum pname, GLfloat *params);
    typedef void (*glGetTexParameterivProcPtr)(GLenum target, GLenum pname, GLint *params);
    typedef void (*glHintProcPtr)(GLenum target, GLenum mode);
    typedef void (*glHistogramProcPtr)(GLenum target, GLsizei width, GLenum internalformat, GLboolean sink);
    typedef void (*glIndexMaskProcPtr)(GLuint mask);
    typedef void (*glIndexPointerProcPtr)(GLenum type, GLsizei stride, const GLvoid *pointer);
    typedef void (*glIndexdProcPtr)(GLdouble c);
    typedef void (*glIndexdvProcPtr)(const GLdouble *c);
    typedef void (*glIndexfProcPtr)(GLfloat c);
    typedef void (*glIndexfvProcPtr)(const GLfloat *c);
    typedef void (*glIndexiProcPtr)(GLint c);
    typedef void (*glIndexivProcPtr)(const GLint *c);
    typedef void (*glIndexsProcPtr)(GLshort c);
    typedef void (*glIndexsvProcPtr)(const GLshort *c);
    typedef void (*glIndexubProcPtr)(GLubyte c);
    typedef void (*glIndexubvProcPtr)(const GLubyte *c);
    typedef void (*glInitNamesProcPtr)(void);
    typedef void (*glInterleavedArraysProcPtr)(GLenum format, GLsizei stride, const GLvoid *pointer);
    typedef GLboolean (*glIsEnabledProcPtr)(GLenum cap);
    typedef GLboolean (*glIsListProcPtr)(GLuint list);
    typedef GLboolean (*glIsTextureProcPtr)(GLuint texture);
    typedef void (*glLightModelfProcPtr)(GLenum pname, GLfloat param);
    typedef void (*glLightModelfvProcPtr)(GLenum pname, const GLfloat *params);
    typedef void (*glLightModeliProcPtr)(GLenum pname, GLint param);
    typedef void (*glLightModelivProcPtr)(GLenum pname, const GLint *params);
    typedef void (*glLightfProcPtr)(GLenum light, GLenum pname, GLfloat param);
    typedef void (*glLightfvProcPtr)(GLenum light, GLenum pname, const GLfloat *params);
    typedef void (*glLightiProcPtr)(GLenum light, GLenum pname, GLint param);
    typedef void (*glLightivProcPtr)(GLenum light, GLenum pname, const GLint *params);
    typedef void (*glLineStippleProcPtr)(GLint factor, GLushort pattern);
    typedef void (*glLineWidthProcPtr)(GLfloat width);
    typedef void (*glListBaseProcPtr)(GLuint base);
    typedef void (*glLoadIdentityProcPtr)(void);
    typedef void (*glLoadMatrixdProcPtr)(const GLdouble *m);
    typedef void (*glLoadMatrixfProcPtr)(const GLfloat *m);
    typedef void (*glLoadNameProcPtr)(GLuint name);
    typedef void (*glLogicOpProcPtr)(GLenum opcode);
    typedef void (*glMap1dProcPtr)(GLenum target, GLdouble u1, GLdouble u2, GLint stride, GLint order, const GLdouble *points);
    typedef void (*glMap1fProcPtr)(GLenum target, GLfloat u1, GLfloat u2, GLint stride, GLint order, const GLfloat *points);
    typedef void (*glMap2dProcPtr)(GLenum target, GLdouble u1, GLdouble u2, GLint ustride, GLint uorder, GLdouble v1, GLdouble v2, GLint vstride, GLint vorder, const GLdouble *points);
    typedef void (*glMap2fProcPtr)(GLenum target, GLfloat u1, GLfloat u2, GLint ustride, GLint uorder, GLfloat v1, GLfloat v2, GLint vstride, GLint vorder, const GLfloat *points);
    typedef void (*glMapGrid1dProcPtr)(GLint un, GLdouble u1, GLdouble u2);
    typedef void (*glMapGrid1fProcPtr)(GLint un, GLfloat u1, GLfloat u2);
    typedef void (*glMapGrid2dProcPtr)(GLint un, GLdouble u1, GLdouble u2, GLint vn, GLdouble v1, GLdouble v2);
    typedef void (*glMapGrid2fProcPtr)(GLint un, GLfloat u1, GLfloat u2, GLint vn, GLfloat v1, GLfloat v2);
    typedef void (*glMaterialfProcPtr)(GLenum face, GLenum pname, GLfloat param);
    typedef void (*glMaterialfvProcPtr)(GLenum face, GLenum pname, const GLfloat *params);
    typedef void (*glMaterialiProcPtr)(GLenum face, GLenum pname, GLint param);
    typedef void (*glMaterialivProcPtr)(GLenum face, GLenum pname, const GLint *params);
    typedef void (*glMatrixModeProcPtr)(GLenum mode);
    typedef void (*glMinmaxProcPtr)(GLenum target, GLenum internalformat, GLboolean sink);
    typedef void (*glMultMatrixdProcPtr)(const GLdouble *m);
    typedef void (*glMultMatrixfProcPtr)(const GLfloat *m);
    typedef void (*glNewListProcPtr)(GLuint list, GLenum mode);
    typedef void (*glNormal3bProcPtr)(GLbyte nx, GLbyte ny, GLbyte nz);
    typedef void (*glNormal3bvProcPtr)(const GLbyte *v);
    typedef void (*glNormal3dProcPtr)(GLdouble nx, GLdouble ny, GLdouble nz);
    typedef void (*glNormal3dvProcPtr)(const GLdouble *v);
    typedef void (*glNormal3fProcPtr)(GLfloat nx, GLfloat ny, GLfloat nz);
    typedef void (*glNormal3fvProcPtr)(const GLfloat *v);
    typedef void (*glNormal3iProcPtr)(GLint nx, GLint ny, GLint nz);
    typedef void (*glNormal3ivProcPtr)(const GLint *v);
    typedef void (*glNormal3sProcPtr)(GLshort nx, GLshort ny, GLshort nz);
    typedef void (*glNormal3svProcPtr)(const GLshort *v);
    typedef void (*glNormalPointerProcPtr)(GLenum type, GLsizei stride, const GLvoid *pointer);
    typedef void (*glOrthoProcPtr)(GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble zNear, GLdouble zFar);
    typedef void (*glPassThroughProcPtr)(GLfloat token);
    typedef void (*glPixelMapfvProcPtr)(GLenum map, GLint mapsize, const GLfloat *values);
    typedef void (*glPixelMapuivProcPtr)(GLenum map, GLint mapsize, const GLuint *values);
    typedef void (*glPixelMapusvProcPtr)(GLenum map, GLint mapsize, const GLushort *values);
    typedef void (*glPixelStorefProcPtr)(GLenum pname, GLfloat param);
    typedef void (*glPixelStoreiProcPtr)(GLenum pname, GLint param);
    typedef void (*glPixelTransferfProcPtr)(GLenum pname, GLfloat param);
    typedef void (*glPixelTransferiProcPtr)(GLenum pname, GLint param);
    typedef void (*glPixelZoomProcPtr)(GLfloat xfactor, GLfloat yfactor);
    typedef void (*glPointSizeProcPtr)(GLfloat size);
    typedef void (*glPolygonModeProcPtr)(GLenum face, GLenum mode);
    typedef void (*glPolygonOffsetProcPtr)(GLfloat factor, GLfloat units);
    typedef void (*glPolygonStippleProcPtr)(const GLubyte *mask);
    typedef void (*glPopAttribProcPtr)(void);
    typedef void (*glPopClientAttribProcPtr)(void);
    typedef void (*glPopMatrixProcPtr)(void);
    typedef void (*glPopNameProcPtr)(void);
    typedef void (*glPrioritizeTexturesProcPtr)(GLsizei n, const GLuint *textures, const GLclampf *priorities);
    typedef void (*glPushAttribProcPtr)(GLbitfield mask);
    typedef void (*glPushClientAttribProcPtr)(GLbitfield mask);
    typedef void (*glPushMatrixProcPtr)(void);
    typedef void (*glPushNameProcPtr)(GLuint name);
    typedef void (*glRasterPos2dProcPtr)(GLdouble x, GLdouble y);
    typedef void (*glRasterPos2dvProcPtr)(const GLdouble *v);
    typedef void (*glRasterPos2fProcPtr)(GLfloat x, GLfloat y);
    typedef void (*glRasterPos2fvProcPtr)(const GLfloat *v);
    typedef void (*glRasterPos2iProcPtr)(GLint x, GLint y);
    typedef void (*glRasterPos2ivProcPtr)(const GLint *v);
    typedef void (*glRasterPos2sProcPtr)(GLshort x, GLshort y);
    typedef void (*glRasterPos2svProcPtr)(const GLshort *v);
    typedef void (*glRasterPos3dProcPtr)(GLdouble x, GLdouble y, GLdouble z);
    typedef void (*glRasterPos3dvProcPtr)(const GLdouble *v);
    typedef void (*glRasterPos3fProcPtr)(GLfloat x, GLfloat y, GLfloat z);
    typedef void (*glRasterPos3fvProcPtr)(const GLfloat *v);
    typedef void (*glRasterPos3iProcPtr)(GLint x, GLint y, GLint z);
    typedef void (*glRasterPos3ivProcPtr)(const GLint *v);
    typedef void (*glRasterPos3sProcPtr)(GLshort x, GLshort y, GLshort z);
    typedef void (*glRasterPos3svProcPtr)(const GLshort *v);
    typedef void (*glRasterPos4dProcPtr)(GLdouble x, GLdouble y, GLdouble z, GLdouble w);
    typedef void (*glRasterPos4dvProcPtr)(const GLdouble *v);
    typedef void (*glRasterPos4fProcPtr)(GLfloat x, GLfloat y, GLfloat z, GLfloat w);
    typedef void (*glRasterPos4fvProcPtr)(const GLfloat *v);
    typedef void (*glRasterPos4iProcPtr)(GLint x, GLint y, GLint z, GLint w);
    typedef void (*glRasterPos4ivProcPtr)(const GLint *v);
    typedef void (*glRasterPos4sProcPtr)(GLshort x, GLshort y, GLshort z, GLshort w);
    typedef void (*glRasterPos4svProcPtr)(const GLshort *v);
    typedef void (*glReadBufferProcPtr)(GLenum mode);
    typedef void (*glReadPixelsProcPtr)(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLvoid *pixels);
    typedef void (*glRectdProcPtr)(GLdouble x1, GLdouble y1, GLdouble x2, GLdouble y2);
    typedef void (*glRectdvProcPtr)(const GLdouble *v1, const GLdouble *v2);
    typedef void (*glRectfProcPtr)(GLfloat x1, GLfloat y1, GLfloat x2, GLfloat y2);
    typedef void (*glRectfvProcPtr)(const GLfloat *v1, const GLfloat *v2);
    typedef void (*glRectiProcPtr)(GLint x1, GLint y1, GLint x2, GLint y2);
    typedef void (*glRectivProcPtr)(const GLint *v1, const GLint *v2);
    typedef void (*glRectsProcPtr)(GLshort x1, GLshort y1, GLshort x2, GLshort y2);
    typedef void (*glRectsvProcPtr)(const GLshort *v1, const GLshort *v2);
    typedef GLint (*glRenderModeProcPtr)(GLenum mode);
    typedef void (*glResetHistogramProcPtr)(GLenum target);
    typedef void (*glResetMinmaxProcPtr)(GLenum target);
    typedef void (*glRotatedProcPtr)(GLdouble angle, GLdouble x, GLdouble y, GLdouble z);
    typedef void (*glRotatefProcPtr)(GLfloat angle, GLfloat x, GLfloat y, GLfloat z);
    typedef void (*glScaledProcPtr)(GLdouble x, GLdouble y, GLdouble z);
    typedef void (*glScalefProcPtr)(GLfloat x, GLfloat y, GLfloat z);
    typedef void (*glScissorProcPtr)(GLint x, GLint y, GLsizei width, GLsizei height);
    typedef void (*glSelectBufferProcPtr)(GLsizei size, GLuint *buffer);
    typedef void (*glSeparableFilter2DProcPtr)(GLenum target, GLenum internalformat, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *row, const GLvoid *column);
    typedef void (*glShadeModelProcPtr)(GLenum mode);
    typedef void (*glStencilFuncProcPtr)(GLenum func, GLint ref, GLuint mask);
    typedef void (*glStencilMaskProcPtr)(GLuint mask);
    typedef void (*glStencilOpProcPtr)(GLenum fail, GLenum zfail, GLenum zpass);
    typedef void (*glTexCoord1dProcPtr)(GLdouble s);
    typedef void (*glTexCoord1dvProcPtr)(const GLdouble *v);
    typedef void (*glTexCoord1fProcPtr)(GLfloat s);
    typedef void (*glTexCoord1fvProcPtr)(const GLfloat *v);
    typedef void (*glTexCoord1iProcPtr)(GLint s);
    typedef void (*glTexCoord1ivProcPtr)(const GLint *v);
    typedef void (*glTexCoord1sProcPtr)(GLshort s);
    typedef void (*glTexCoord1svProcPtr)(const GLshort *v);
    typedef void (*glTexCoord2dProcPtr)(GLdouble s, GLdouble t);
    typedef void (*glTexCoord2dvProcPtr)(const GLdouble *v);
    typedef void (*glTexCoord2fProcPtr)(GLfloat s, GLfloat t);
    typedef void (*glTexCoord2fvProcPtr)(const GLfloat *v);
    typedef void (*glTexCoord2iProcPtr)(GLint s, GLint t);
    typedef void (*glTexCoord2ivProcPtr)(const GLint *v);
    typedef void (*glTexCoord2sProcPtr)(GLshort s, GLshort t);
    typedef void (*glTexCoord2svProcPtr)(const GLshort *v);
    typedef void (*glTexCoord3dProcPtr)(GLdouble s, GLdouble t, GLdouble r);
    typedef void (*glTexCoord3dvProcPtr)(const GLdouble *v);
    typedef void (*glTexCoord3fProcPtr)(GLfloat s, GLfloat t, GLfloat r);
    typedef void (*glTexCoord3fvProcPtr)(const GLfloat *v);
    typedef void (*glTexCoord3iProcPtr)(GLint s, GLint t, GLint r);
    typedef void (*glTexCoord3ivProcPtr)(const GLint *v);
    typedef void (*glTexCoord3sProcPtr)(GLshort s, GLshort t, GLshort r);
    typedef void (*glTexCoord3svProcPtr)(const GLshort *v);
    typedef void (*glTexCoord4dProcPtr)(GLdouble s, GLdouble t, GLdouble r, GLdouble q);
    typedef void (*glTexCoord4dvProcPtr)(const GLdouble *v);
    typedef void (*glTexCoord4fProcPtr)(GLfloat s, GLfloat t, GLfloat r, GLfloat q);
    typedef void (*glTexCoord4fvProcPtr)(const GLfloat *v);
    typedef void (*glTexCoord4iProcPtr)(GLint s, GLint t, GLint r, GLint q);
    typedef void (*glTexCoord4ivProcPtr)(const GLint *v);
    typedef void (*glTexCoord4sProcPtr)(GLshort s, GLshort t, GLshort r, GLshort q);
    typedef void (*glTexCoord4svProcPtr)(const GLshort *v);
    typedef void (*glTexCoordPointerProcPtr)(GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
    typedef void (*glTexEnvfProcPtr)(GLenum target, GLenum pname, GLfloat param);
    typedef void (*glTexEnvfvProcPtr)(GLenum target, GLenum pname, const GLfloat *params);
    typedef void (*glTexEnviProcPtr)(GLenum target, GLenum pname, GLint param);
    typedef void (*glTexEnvivProcPtr)(GLenum target, GLenum pname, const GLint *params);
    typedef void (*glTexGendProcPtr)(GLenum coord, GLenum pname, GLdouble param);
    typedef void (*glTexGendvProcPtr)(GLenum coord, GLenum pname, const GLdouble *params);
    typedef void (*glTexGenfProcPtr)(GLenum coord, GLenum pname, GLfloat param);
    typedef void (*glTexGenfvProcPtr)(GLenum coord, GLenum pname, const GLfloat *params);
    typedef void (*glTexGeniProcPtr)(GLenum coord, GLenum pname, GLint param);
    typedef void (*glTexGenivProcPtr)(GLenum coord, GLenum pname, const GLint *params);
    typedef void (*glTexImage1DProcPtr)(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
    typedef void (*glTexImage2DProcPtr)(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
    typedef void (*glTexImage3DProcPtr)(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
    typedef void (*glTexParameterfProcPtr)(GLenum target, GLenum pname, GLfloat param);
    typedef void (*glTexParameterfvProcPtr)(GLenum target, GLenum pname, const GLfloat *params);
    typedef void (*glTexParameteriProcPtr)(GLenum target, GLenum pname, GLint param);
    typedef void (*glTexParameterivProcPtr)(GLenum target, GLenum pname, const GLint *params);
    typedef void (*glTexSubImage1DProcPtr)(GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLenum type, const GLvoid *pixels);
    typedef void (*glTexSubImage2DProcPtr)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *pixels);
    typedef void (*glTexSubImage3DProcPtr)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const GLvoid *pixels);
    typedef void (*glTranslatedProcPtr)(GLdouble x, GLdouble y, GLdouble z);
    typedef void (*glTranslatefProcPtr)(GLfloat x, GLfloat y, GLfloat z);
    typedef void (*glVertex2dProcPtr)(GLdouble x, GLdouble y);
    typedef void (*glVertex2dvProcPtr)(const GLdouble *v);
    typedef void (*glVertex2fProcPtr)(GLfloat x, GLfloat y);
    typedef void (*glVertex2fvProcPtr)(const GLfloat *v);
    typedef void (*glVertex2iProcPtr)(GLint x, GLint y);
    typedef void (*glVertex2ivProcPtr)(const GLint *v);
    typedef void (*glVertex2sProcPtr)(GLshort x, GLshort y);
    typedef void (*glVertex2svProcPtr)(const GLshort *v);
    typedef void (*glVertex3dProcPtr)(GLdouble x, GLdouble y, GLdouble z);
    typedef void (*glVertex3dvProcPtr)(const GLdouble *v);
    typedef void (*glVertex3fProcPtr)(GLfloat x, GLfloat y, GLfloat z);
    typedef void (*glVertex3fvProcPtr)(const GLfloat *v);
    typedef void (*glVertex3iProcPtr)(GLint x, GLint y, GLint z);
    typedef void (*glVertex3ivProcPtr)(const GLint *v);
    typedef void (*glVertex3sProcPtr)(GLshort x, GLshort y, GLshort z);
    typedef void (*glVertex3svProcPtr)(const GLshort *v);
    typedef void (*glVertex4dProcPtr)(GLdouble x, GLdouble y, GLdouble z, GLdouble w);
    typedef void (*glVertex4dvProcPtr)(const GLdouble *v);
    typedef void (*glVertex4fProcPtr)(GLfloat x, GLfloat y, GLfloat z, GLfloat w);
    typedef void (*glVertex4fvProcPtr)(const GLfloat *v);
    typedef void (*glVertex4iProcPtr)(GLint x, GLint y, GLint z, GLint w);
    typedef void (*glVertex4ivProcPtr)(const GLint *v);
    typedef void (*glVertex4sProcPtr)(GLshort x, GLshort y, GLshort z, GLshort w);
    typedef void (*glVertex4svProcPtr)(const GLshort *v);
    typedef void (*glVertexPointerProcPtr)(GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
    typedef void (*glViewportProcPtr)(GLint x, GLint y, GLsizei width, GLsizei height);
    typedef void (*glSampleCoverageProcPtr)(GLclampf value, GLboolean invert);
    typedef void (*glSamplePassProcPtr)(GLenum pass);
    typedef void (*glLoadTransposeMatrixfProcPtr)(const GLfloat *m);
    typedef void (*glLoadTransposeMatrixdProcPtr)(const GLdouble *m);
    typedef void (*glMultTransposeMatrixfProcPtr)(const GLfloat *m);
    typedef void (*glMultTransposeMatrixdProcPtr)(const GLdouble *m);
    typedef void (*glCompressedTexImage3DProcPtr)(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, const GLvoid *data);
    typedef void (*glCompressedTexImage2DProcPtr)(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const GLvoid *data);
    typedef void (*glCompressedTexImage1DProcPtr)(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLint border, GLsizei imageSize, const GLvoid *data);
    typedef void (*glCompressedTexSubImage3DProcPtr)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, const GLvoid *data);
    typedef void (*glCompressedTexSubImage2DProcPtr)(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const GLvoid *data);
    typedef void (*glCompressedTexSubImage1DProcPtr)(GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLsizei imageSize, const GLvoid *data);
    typedef void (*glGetCompressedTexImageProcPtr)(GLenum target, GLint lod, GLvoid *img);
    typedef void (*glActiveTextureProcPtr)(GLenum texture);
    typedef void (*glClientActiveTextureProcPtr)(GLenum texture);
    typedef void (*glMultiTexCoord1dProcPtr)(GLenum target, GLdouble s);
    typedef void (*glMultiTexCoord1dvProcPtr)(GLenum target, const GLdouble *v);
    typedef void (*glMultiTexCoord1fProcPtr)(GLenum target, GLfloat s);
    typedef void (*glMultiTexCoord1fvProcPtr)(GLenum target, const GLfloat *v);
    typedef void (*glMultiTexCoord1iProcPtr)(GLenum target, GLint s);
    typedef void (*glMultiTexCoord1ivProcPtr)(GLenum target, const GLint *v);
    typedef void (*glMultiTexCoord1sProcPtr)(GLenum target, GLshort s);
    typedef void (*glMultiTexCoord1svProcPtr)(GLenum target, const GLshort *v);
    typedef void (*glMultiTexCoord2dProcPtr)(GLenum target, GLdouble s, GLdouble t);
    typedef void (*glMultiTexCoord2dvProcPtr)(GLenum target, const GLdouble *v);
    typedef void (*glMultiTexCoord2fProcPtr)(GLenum target, GLfloat s, GLfloat t);
    typedef void (*glMultiTexCoord2fvProcPtr)(GLenum target, const GLfloat *v);
    typedef void (*glMultiTexCoord2iProcPtr)(GLenum target, GLint s, GLint t);
    typedef void (*glMultiTexCoord2ivProcPtr)(GLenum target, const GLint *v);
    typedef void (*glMultiTexCoord2sProcPtr)(GLenum target, GLshort s, GLshort t);
    typedef void (*glMultiTexCoord2svProcPtr)(GLenum target, const GLshort *v);
    typedef void (*glMultiTexCoord3dProcPtr)(GLenum target, GLdouble s, GLdouble t, GLdouble r);
    typedef void (*glMultiTexCoord3dvProcPtr)(GLenum target, const GLdouble *v);
    typedef void (*glMultiTexCoord3fProcPtr)(GLenum target, GLfloat s, GLfloat t, GLfloat r);
    typedef void (*glMultiTexCoord3fvProcPtr)(GLenum target, const GLfloat *v);
    typedef void (*glMultiTexCoord3iProcPtr)(GLenum target, GLint s, GLint t, GLint r);
    typedef void (*glMultiTexCoord3ivProcPtr)(GLenum target, const GLint *v);
    typedef void (*glMultiTexCoord3sProcPtr)(GLenum target, GLshort s, GLshort t, GLshort r);
    typedef void (*glMultiTexCoord3svProcPtr)(GLenum target, const GLshort *v);
    typedef void (*glMultiTexCoord4dProcPtr)(GLenum target, GLdouble s, GLdouble t, GLdouble r, GLdouble q);
    typedef void (*glMultiTexCoord4dvProcPtr)(GLenum target, const GLdouble *v);
    typedef void (*glMultiTexCoord4fProcPtr)(GLenum target, GLfloat s, GLfloat t, GLfloat r, GLfloat q);
    typedef void (*glMultiTexCoord4fvProcPtr)(GLenum target, const GLfloat *v);
    typedef void (*glMultiTexCoord4iProcPtr)(GLenum target, GLint, GLint s, GLint t, GLint r);
    typedef void (*glMultiTexCoord4ivProcPtr)(GLenum target, const GLint *v);
    typedef void (*glMultiTexCoord4sProcPtr)(GLenum target, GLshort s, GLshort t, GLshort r, GLshort q);
    typedef void (*glMultiTexCoord4svProcPtr)(GLenum target, const GLshort *v);
    typedef void (*glFogCoordfProcPtr)(GLfloat coord);
    typedef void (*glFogCoordfvProcPtr)(const GLfloat *coord);
    typedef void (*glFogCoorddProcPtr)(GLdouble coord);
    typedef void (*glFogCoorddvProcPtr)(const GLdouble * coord);
    typedef void (*glFogCoordPointerProcPtr)(GLenum type, GLsizei stride, const GLvoid *pointer);
    typedef void (*glSecondaryColor3bProcPtr)(GLbyte red, GLbyte green, GLbyte blue);
    typedef void (*glSecondaryColor3bvProcPtr)(const GLbyte *v);
    typedef void (*glSecondaryColor3dProcPtr)(GLdouble red, GLdouble green, GLdouble blue);
    typedef void (*glSecondaryColor3dvProcPtr)(const GLdouble *v);
    typedef void (*glSecondaryColor3fProcPtr)(GLfloat red, GLfloat green, GLfloat blue);
    typedef void (*glSecondaryColor3fvProcPtr)(const GLfloat *v);
    typedef void (*glSecondaryColor3iProcPtr)(GLint red, GLint green, GLint blue);
    typedef void (*glSecondaryColor3ivProcPtr)(const GLint *v);
    typedef void (*glSecondaryColor3sProcPtr)(GLshort red, GLshort green, GLshort blue);
    typedef void (*glSecondaryColor3svProcPtr)(const GLshort *v);
    typedef void (*glSecondaryColor3ubProcPtr)(GLubyte red, GLubyte green, GLubyte blue);
    typedef void (*glSecondaryColor3ubvProcPtr)(const GLubyte *v);
    typedef void (*glSecondaryColor3uiProcPtr)(GLuint red, GLuint green, GLuint blue);
    typedef void (*glSecondaryColor3uivProcPtr)(const GLuint *v);
    typedef void (*glSecondaryColor3usProcPtr)(GLushort red, GLushort green, GLushort blue);
    typedef void (*glSecondaryColor3usvProcPtr)(const GLushort *v);
    typedef void (*glSecondaryColorPointerProcPtr)(GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
    typedef void (*glPointParameterfProcPtr)(GLenum pname, GLfloat param);
    typedef void (*glPointParameterfvProcPtr)(GLenum pname, const GLfloat *params);
    typedef void (*glPointParameteriProcPtr)(GLenum pname, GLint param);
    typedef void (*glPointParameterivProcPtr)(GLenum pname, const GLint *params);
    typedef void (*glBlendFuncSeparateProcPtr)(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);
    typedef void (*glMultiDrawArraysProcPtr)(GLenum mode, const GLint *first, const GLsizei *count, GLsizei primcount);
    typedef void (*glMultiDrawElementsProcPtr)(GLenum mode, const GLsizei *count, GLenum type, const GLvoid* *indices, GLsizei primcount);
    typedef void (*glWindowPos2dProcPtr)(GLdouble x, GLdouble y);
    typedef void (*glWindowPos2dvProcPtr)(const GLdouble *v);
    typedef void (*glWindowPos2fProcPtr)(GLfloat x, GLfloat y);
    typedef void (*glWindowPos2fvProcPtr)(const GLfloat *v);
    typedef void (*glWindowPos2iProcPtr)(GLint x, GLint y);
    typedef void (*glWindowPos2ivProcPtr)(const GLint *v);
    typedef void (*glWindowPos2sProcPtr)(GLshort x, GLshort y);
    typedef void (*glWindowPos2svProcPtr)(const GLshort *v);
    typedef void (*glWindowPos3dProcPtr)(GLdouble x, GLdouble y, GLdouble z);
    typedef void (*glWindowPos3dvProcPtr)(const GLdouble *v);
    typedef void (*glWindowPos3fProcPtr)(GLfloat x, GLfloat y, GLfloat z);
    typedef void (*glWindowPos3fvProcPtr)(const GLfloat *v);
    typedef void (*glWindowPos3iProcPtr)(GLint x, GLint y, GLint z);
    typedef void (*glWindowPos3ivProcPtr)(const GLint *v);
    typedef void (*glWindowPos3sProcPtr)(GLshort x, GLshort y, GLshort z);
    typedef void (*glWindowPos3svProcPtr)(const GLshort *v);
    typedef void (*glGenQueriesProcPtr)(GLsizei n, GLuint *ids);
    typedef void (*glDeleteQueriesProcPtr)(GLsizei n, const GLuint *ids);
    typedef GLboolean (*glIsQueryProcPtr)(GLuint id);
    typedef void (*glBeginQueryProcPtr)(GLenum target, GLuint id);
    typedef void (*glEndQueryProcPtr)(GLenum target);
    typedef void (*glGetQueryivProcPtr)(GLenum target, GLenum pname, GLint *params);
    typedef void (*glGetQueryObjectivProcPtr)(GLuint id, GLenum pname, GLint *params);
    typedef void (*glGetQueryObjectuivProcPtr)(GLuint id, GLenum pname, GLuint *params);
    typedef void (*glBindBufferProcPtr)(GLenum target, GLuint buffer);
    typedef void (*glDeleteBuffersProcPtr)(GLsizei n, const GLuint *buffers);
    typedef void (*glGenBuffersProcPtr)(GLsizei n, GLuint *buffers);
    typedef GLboolean (*glIsBufferProcPtr)(GLuint buffer);
    typedef void (*glBufferDataProcPtr)(GLenum target, GLsizeiptr size, const GLvoid *data, GLenum usage);
    typedef void (*glBufferSubDataProcPtr)(GLenum target, GLintptr offset, GLsizeiptr size, const GLvoid *data);
    typedef void (*glGetBufferSubDataProcPtr)(GLenum target, GLintptr offset, GLsizeiptr size, GLvoid *data);
    typedef GLvoid * (*glMapBufferProcPtr)(GLenum target, GLenum access);
    typedef GLboolean (*glUnmapBufferProcPtr)(GLenum target);
    typedef void (*glGetBufferParameterivProcPtr)(GLenum target, GLenum pname, GLint *params);
    typedef void (*glGetBufferPointervProcPtr)(GLenum target, GLenum pname, GLvoid **params);
    typedef void (*glDrawBuffersProcPtr)(GLsizei n, const GLenum *bufs);
    typedef void (*glVertexAttrib1dProcPtr)(GLuint index, GLdouble x);
    typedef void (*glVertexAttrib1dvProcPtr)(GLuint index, const GLdouble *v);
    typedef void (*glVertexAttrib1fProcPtr)(GLuint index, GLfloat x);
    typedef void (*glVertexAttrib1fvProcPtr)(GLuint index, const GLfloat *v);
    typedef void (*glVertexAttrib1sProcPtr)(GLuint index, GLshort x);
    typedef void (*glVertexAttrib1svProcPtr)(GLuint index, const GLshort *v);
    typedef void (*glVertexAttrib2dProcPtr)(GLuint index, GLdouble x, GLdouble y);
    typedef void (*glVertexAttrib2dvProcPtr)(GLuint index, const GLdouble *v);
    typedef void (*glVertexAttrib2fProcPtr)(GLuint index, GLfloat x, GLfloat y);
    typedef void (*glVertexAttrib2fvProcPtr)(GLuint index, const GLfloat *v);
    typedef void (*glVertexAttrib2sProcPtr)(GLuint index, GLshort x, GLshort y);
    typedef void (*glVertexAttrib2svProcPtr)(GLuint index, const GLshort *v);
    typedef void (*glVertexAttrib3dProcPtr)(GLuint index, GLdouble x, GLdouble y, GLdouble z);
    typedef void (*glVertexAttrib3dvProcPtr)(GLuint index, const GLdouble *v);
    typedef void (*glVertexAttrib3fProcPtr)(GLuint index, GLfloat x, GLfloat y, GLfloat z);
    typedef void (*glVertexAttrib3fvProcPtr)(GLuint index, const GLfloat *v);
    typedef void (*glVertexAttrib3sProcPtr)(GLuint index, GLshort x, GLshort y, GLshort z);
    typedef void (*glVertexAttrib3svProcPtr)(GLuint index, const GLshort *v);
    typedef void (*glVertexAttrib4NbvProcPtr)(GLuint index, const GLbyte *v);
    typedef void (*glVertexAttrib4NivProcPtr)(GLuint index, const GLint *v);
    typedef void (*glVertexAttrib4NsvProcPtr)(GLuint index, const GLshort *v);
    typedef void (*glVertexAttrib4NubProcPtr)(GLuint index, GLubyte x, GLubyte y, GLubyte z, GLubyte w);
    typedef void (*glVertexAttrib4NubvProcPtr)(GLuint index, const GLubyte *v);
    typedef void (*glVertexAttrib4NuivProcPtr)(GLuint index, const GLuint *v);
    typedef void (*glVertexAttrib4NusvProcPtr)(GLuint index, const GLushort *v);
    typedef void (*glVertexAttrib4bvProcPtr)(GLuint index, const GLbyte *v);
    typedef void (*glVertexAttrib4dProcPtr)(GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
    typedef void (*glVertexAttrib4dvProcPtr)(GLuint index, const GLdouble *v);
    typedef void (*glVertexAttrib4fProcPtr)(GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
    typedef void (*glVertexAttrib4fvProcPtr)(GLuint index, const GLfloat *v);
    typedef void (*glVertexAttrib4ivProcPtr)(GLuint index, const GLint *v);
    typedef void (*glVertexAttrib4sProcPtr)(GLuint index, GLshort x, GLshort y, GLshort z, GLshort w);
    typedef void (*glVertexAttrib4svProcPtr)(GLuint index, const GLshort *v);
    typedef void (*glVertexAttrib4ubvProcPtr)(GLuint index, const GLubyte *v);
    typedef void (*glVertexAttrib4uivProcPtr)(GLuint index, const GLuint *v);
    typedef void (*glVertexAttrib4usvProcPtr)(GLuint index, const GLushort *v);
    typedef void (*glVertexAttribPointerProcPtr)(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid *pointer);
    typedef void (*glEnableVertexAttribArrayProcPtr)(GLuint index);
    typedef void (*glDisableVertexAttribArrayProcPtr)(GLuint index);
    typedef void (*glGetVertexAttribdvProcPtr)(GLuint index, GLenum pname, GLdouble *params);
    typedef void (*glGetVertexAttribfvProcPtr)(GLuint index, GLenum pname, GLfloat *params);
    typedef void (*glGetVertexAttribivProcPtr)(GLuint index, GLenum pname, GLint *params);
    typedef void (*glGetVertexAttribPointervProcPtr)(GLuint index, GLenum pname, GLvoid* *pointer);
    typedef void (*glDeleteShaderProcPtr)(GLuint shader);
    typedef void (*glDetachShaderProcPtr)(GLuint program, GLuint shader);
    typedef GLuint (*glCreateShaderProcPtr)(GLenum type);
    typedef void (*glShaderSourceProcPtr)(GLuint shader, GLsizei count, const GLchar* *string, const GLint *length);
    typedef void (*glCompileShaderProcPtr)(GLuint shader);
    typedef GLuint (*glCreateProgramProcPtr)(void);
    typedef void (*glAttachShaderProcPtr)(GLuint program, GLuint shader);
    typedef void (*glLinkProgramProcPtr)(GLuint program);
    typedef void (*glUseProgramProcPtr)(GLuint program);
    typedef void (*glDeleteProgramProcPtr)(GLuint program);
    typedef void (*glValidateProgramProcPtr)(GLuint program);
    typedef void (*glUniform1fProcPtr)(GLint location, GLfloat v0);
    typedef void (*glUniform2fProcPtr)(GLint location, GLfloat v0, GLfloat v1);
    typedef void (*glUniform3fProcPtr)(GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
    typedef void (*glUniform4fProcPtr)(GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
    typedef void (*glUniform1iProcPtr)(GLint location, GLint v0);
    typedef void (*glUniform2iProcPtr)(GLint location, GLint v0, GLint v1);
    typedef void (*glUniform3iProcPtr)(GLint location, GLint v0, GLint v1, GLint v2);
    typedef void (*glUniform4iProcPtr)(GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
    typedef void (*glUniform1fvProcPtr)(GLint location, GLsizei count, const GLfloat *value);
    typedef void (*glUniform2fvProcPtr)(GLint location, GLsizei count, const GLfloat *value);
    typedef void (*glUniform3fvProcPtr)(GLint location, GLsizei count, const GLfloat *value);
    typedef void (*glUniform4fvProcPtr)(GLint location, GLsizei count, const GLfloat *value);
    typedef void (*glUniform1ivProcPtr)(GLint location, GLsizei count, const GLint *value);
    typedef void (*glUniform2ivProcPtr)(GLint location, GLsizei count, const GLint *value);
    typedef void (*glUniform3ivProcPtr)(GLint location, GLsizei count, const GLint *value);
    typedef void (*glUniform4ivProcPtr)(GLint location, GLsizei count, const GLint *value);
    typedef void (*glUniformMatrix2fvProcPtr)(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
    typedef void (*glUniformMatrix3fvProcPtr)(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
    typedef void (*glUniformMatrix4fvProcPtr)(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
    typedef GLboolean (*glIsShaderProcPtr)(GLuint shader);
    typedef GLboolean (*glIsProgramProcPtr)(GLuint program);
    typedef void (*glGetShaderivProcPtr)(GLuint shader, GLenum pname, GLint *params);
    typedef void (*glGetProgramivProcPtr)(GLuint program, GLenum pname, GLint *params);
    typedef void (*glGetAttachedShadersProcPtr)(GLuint program, GLsizei maxCount, GLsizei *count, GLuint *shaders);
    typedef void (*glGetShaderInfoLogProcPtr)(GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
    typedef void (*glGetProgramInfoLogProcPtr)(GLuint program, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
    typedef GLint (*glGetUniformLocationProcPtr)(GLuint program, const GLchar *name);
    typedef void (*glGetActiveUniformProcPtr)(GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
    typedef void (*glGetUniformfvProcPtr)(GLuint program, GLint location, GLfloat *params);
    typedef void (*glGetUniformivProcPtr)(GLuint program, GLint location, GLint *params);
    typedef void (*glGetShaderSourceProcPtr)(GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *source);
    typedef void (*glBindAttribLocationProcPtr)(GLuint program, GLuint index, const GLchar *name);
    typedef void (*glGetActiveAttribProcPtr)(GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
    typedef GLint (*glGetAttribLocationProcPtr)(GLuint program, const GLchar *name);
    typedef void (*glStencilFuncSeparateProcPtr)(GLenum face, GLenum func, GLint ref, GLuint mask);
    typedef void (*glStencilOpSeparateProcPtr)(GLenum face, GLenum fail, GLenum zfail, GLenum zpass);
    typedef void (*glStencilMaskSeparateProcPtr)(GLenum face, GLuint mask);
    typedef void (*glUniformMatrix2x3fvProcPtr)(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
    typedef void (*glUniformMatrix3x2fvProcPtr)(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
    typedef void (*glUniformMatrix2x4fvProcPtr)(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
    typedef void (*glUniformMatrix4x2fvProcPtr)(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
    typedef void (*glUniformMatrix3x4fvProcPtr)(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
    typedef void (*glUniformMatrix4x3fvProcPtr)(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
]]

local glptr = function(name)
    local ptr = EAPI.base_gl_get_proc_address(name)
    if    ptr == nil then return nil end
    return ffi.cast(name .. "ProcPtr", ptr)
end

external.gl_init = function()
    gl = {
        -- constants
        ["ACCUM"]                                = 0x0100,
        ["LOAD"]                                 = 0x0101,
        ["RETURN"]                               = 0x0102,
        ["MULT"]                                 = 0x0103,
        ["ADD"]                                  = 0x0104,
        ["NEVER"]                                = 0x0200,
        ["LESS"]                                 = 0x0201,
        ["EQUAL"]                                = 0x0202,
        ["LEQUAL"]                               = 0x0203,
        ["GREATER"]                              = 0x0204,
        ["NOTEQUAL"]                             = 0x0205,
        ["GEQUAL"]                               = 0x0206,
        ["ALWAYS"]                               = 0x0207,
        ["CURRENT_BIT"]                          = 0x00000001,
        ["POINT_BIT"]                            = 0x00000002,
        ["LINE_BIT"]                             = 0x00000004,
        ["POLYGON_BIT"]                          = 0x00000008,
        ["POLYGON_STIPPLE_BIT"]                  = 0x00000010,
        ["PIXEL_MODE_BIT"]                       = 0x00000020,
        ["LIGHTING_BIT"]                         = 0x00000040,
        ["FOG_BIT"]                              = 0x00000080,
        ["DEPTH_BUFFER_BIT"]                     = 0x00000100,
        ["ACCUM_BUFFER_BIT"]                     = 0x00000200,
        ["STENCIL_BUFFER_BIT"]                   = 0x00000400,
        ["VIEWPORT_BIT"]                         = 0x00000800,
        ["TRANSFORM_BIT"]                        = 0x00001000,
        ["ENABLE_BIT"]                           = 0x00002000,
        ["COLOR_BUFFER_BIT"]                     = 0x00004000,
        ["HINT_BIT"]                             = 0x00008000,
        ["EVAL_BIT"]                             = 0x00010000,
        ["LIST_BIT"]                             = 0x00020000,
        ["TEXTURE_BIT"]                          = 0x00040000,
        ["SCISSOR_BIT"]                          = 0x00080000,
        ["ALL_ATTRIB_BITS"]                      = 0x000fffff,
        ["POINTS"]                               = 0x0000,
        ["LINES"]                                = 0x0001,
        ["LINE_LOOP"]                            = 0x0002,
        ["LINE_STRIP"]                           = 0x0003,
        ["TRIANGLES"]                            = 0x0004,
        ["TRIANGLE_STRIP"]                       = 0x0005,
        ["TRIANGLE_FAN"]                         = 0x0006,
        ["QUADS"]                                = 0x0007,
        ["QUAD_STRIP"]                           = 0x0008,
        ["POLYGON"]                              = 0x0009,
        ["ZERO"]                                 = 0,
        ["ONE"]                                  = 1,
        ["SRC_COLOR"]                            = 0x0300,
        ["ONE_MINUS_SRC_COLOR"]                  = 0x0301,
        ["SRC_ALPHA"]                            = 0x0302,
        ["ONE_MINUS_SRC_ALPHA"]                  = 0x0303,
        ["DST_ALPHA"]                            = 0x0304,
        ["ONE_MINUS_DST_ALPHA"]                  = 0x0305,
        ["DST_COLOR"]                            = 0x0306,
        ["ONE_MINUS_DST_COLOR"]                  = 0x0307,
        ["SRC_ALPHA_SATURATE"]                   = 0x0308,
        ["TRUE"]                                 = 1,
        ["FALSE"]                                = 0,
        ["CLIP_PLANE0"]                          = 0x3000,
        ["CLIP_PLANE1"]                          = 0x3001,
        ["CLIP_PLANE2"]                          = 0x3002,
        ["CLIP_PLANE3"]                          = 0x3003,
        ["CLIP_PLANE4"]                          = 0x3004,
        ["CLIP_PLANE5"]                          = 0x3005,
        ["BYTE"]                                 = 0x1400,
        ["UNSIGNED_BYTE"]                        = 0x1401,
        ["SHORT"]                                = 0x1402,
        ["UNSIGNED_SHORT"]                       = 0x1403,
        ["INT"]                                  = 0x1404,
        ["UNSIGNED_INT"]                         = 0x1405,
        ["FLOAT"]                                = 0x1406,
        ["2_BYTES"]                              = 0x1407,
        ["3_BYTES"]                              = 0x1408,
        ["4_BYTES"]                              = 0x1409,
        ["DOUBLE"]                               = 0x140A,
        ["NONE"]                                 = 0,
        ["FRONT_LEFT"]                           = 0x0400,
        ["FRONT_RIGHT"]                          = 0x0401,
        ["BACK_LEFT"]                            = 0x0402,
        ["BACK_RIGHT"]                           = 0x0403,
        ["FRONT"]                                = 0x0404,
        ["BACK"]                                 = 0x0405,
        ["LEFT"]                                 = 0x0406,
        ["RIGHT"]                                = 0x0407,
        ["FRONT_AND_BACK"]                       = 0x0408,
        ["AUX0"]                                 = 0x0409,
        ["AUX1"]                                 = 0x040A,
        ["AUX2"]                                 = 0x040B,
        ["AUX3"]                                 = 0x040C,
        ["NO_ERROR"]                             = 0,
        ["INVALID_ENUM"]                         = 0x0500,
        ["INVALID_VALUE"]                        = 0x0501,
        ["INVALID_OPERATION"]                    = 0x0502,
        ["STACK_OVERFLOW"]                       = 0x0503,
        ["STACK_UNDERFLOW"]                      = 0x0504,
        ["OUT_OF_MEMORY"]                        = 0x0505,
        ["2D"]                                   = 0x0600,
        ["3D"]                                   = 0x0601,
        ["3D_COLOR"]                             = 0x0602,
        ["3D_COLOR_TEXTURE"]                     = 0x0603,
        ["4D_COLOR_TEXTURE"]                     = 0x0604,
        ["PASS_THROUGH_TOKEN"]                   = 0x0700,
        ["POINT_TOKEN"]                          = 0x0701,
        ["LINE_TOKEN"]                           = 0x0702,
        ["POLYGON_TOKEN"]                        = 0x0703,
        ["BITMAP_TOKEN"]                         = 0x0704,
        ["DRAW_PIXEL_TOKEN"]                     = 0x0705,
        ["COPY_PIXEL_TOKEN"]                     = 0x0706,
        ["LINE_RESET_TOKEN"]                     = 0x0707,
        ["EXP"]                                  = 0x0800,
        ["EXP2"]                                 = 0x0801,
        ["CW"]                                   = 0x0900,
        ["CCW"]                                  = 0x0901,
        ["COEFF"]                                = 0x0A00,
        ["ORDER"]                                = 0x0A01,
        ["DOMAIN"]                               = 0x0A02,
        ["CURRENT_COLOR"]                        = 0x0B00,
        ["CURRENT_INDEX"]                        = 0x0B01,
        ["CURRENT_NORMAL"]                       = 0x0B02,
        ["CURRENT_TEXTURE_COORDS"]               = 0x0B03,
        ["CURRENT_RASTER_COLOR"]                 = 0x0B04,
        ["CURRENT_RASTER_INDEX"]                 = 0x0B05,
        ["CURRENT_RASTER_TEXTURE_COORDS"]        = 0x0B06,
        ["CURRENT_RASTER_POSITION"]              = 0x0B07,
        ["CURRENT_RASTER_POSITION_VALID"]        = 0x0B08,
        ["CURRENT_RASTER_DISTANCE"]              = 0x0B09,
        ["POINT_SMOOTH"]                         = 0x0B10,
        ["POINT_SIZE"]                           = 0x0B11,
        ["POINT_SIZE_RANGE"]                     = 0x0B12,
        ["POINT_SIZE_GRANULARITY"]               = 0x0B13,
        ["LINE_SMOOTH"]                          = 0x0B20,
        ["LINE_WIDTH"]                           = 0x0B21,
        ["LINE_WIDTH_RANGE"]                     = 0x0B22,
        ["LINE_WIDTH_GRANULARITY"]               = 0x0B23,
        ["LINE_STIPPLE"]                         = 0x0B24,
        ["LINE_STIPPLE_PATTERN"]                 = 0x0B25,
        ["LINE_STIPPLE_REPEAT"]                  = 0x0B26,
        ["LIST_MODE"]                            = 0x0B30,
        ["MAX_LIST_NESTING"]                     = 0x0B31,
        ["LIST_BASE"]                            = 0x0B32,
        ["LIST_INDEX"]                           = 0x0B33,
        ["POLYGON_MODE"]                         = 0x0B40,
        ["POLYGON_SMOOTH"]                       = 0x0B41,
        ["POLYGON_STIPPLE"]                      = 0x0B42,
        ["EDGE_FLAG"]                            = 0x0B43,
        ["CULL_FACE"]                            = 0x0B44,
        ["CULL_FACE_MODE"]                       = 0x0B45,
        ["FRONT_FACE"]                           = 0x0B46,
        ["LIGHTING"]                             = 0x0B50,
        ["LIGHT_MODEL_LOCAL_VIEWER"]             = 0x0B51,
        ["LIGHT_MODEL_TWO_SIDE"]                 = 0x0B52,
        ["LIGHT_MODEL_AMBIENT"]                  = 0x0B53,
        ["SHADE_MODEL"]                          = 0x0B54,
        ["COLOR_MATERIAL_FACE"]                  = 0x0B55,
        ["COLOR_MATERIAL_PARAMETER"]             = 0x0B56,
        ["COLOR_MATERIAL"]                       = 0x0B57,
        ["FOG"]                                  = 0x0B60,
        ["FOG_INDEX"]                            = 0x0B61,
        ["FOG_DENSITY"]                          = 0x0B62,
        ["FOG_START"]                            = 0x0B63,
        ["FOG_END"]                              = 0x0B64,
        ["FOG_MODE"]                             = 0x0B65,
        ["FOG_COLOR"]                            = 0x0B66,
        ["DEPTH_RANGE"]                          = 0x0B70,
        ["DEPTH_TEST"]                           = 0x0B71,
        ["DEPTH_WRITEMASK"]                      = 0x0B72,
        ["DEPTH_CLEAR_VALUE"]                    = 0x0B73,
        ["DEPTH_FUNC"]                           = 0x0B74,
        ["ACCUM_CLEAR_VALUE"]                    = 0x0B80,
        ["STENCIL_TEST"]                         = 0x0B90,
        ["STENCIL_CLEAR_VALUE"]                  = 0x0B91,
        ["STENCIL_FUNC"]                         = 0x0B92,
        ["STENCIL_VALUE_MASK"]                   = 0x0B93,
        ["STENCIL_FAIL"]                         = 0x0B94,
        ["STENCIL_PASS_DEPTH_FAIL"]              = 0x0B95,
        ["STENCIL_PASS_DEPTH_PASS"]              = 0x0B96,
        ["STENCIL_REF"]                          = 0x0B97,
        ["STENCIL_WRITEMASK"]                    = 0x0B98,
        ["MATRIX_MODE"]                          = 0x0BA0,
        ["NORMALIZE"]                            = 0x0BA1,
        ["VIEWPORT"]                             = 0x0BA2,
        ["MODELVIEW_STACK_DEPTH"]                = 0x0BA3,
        ["PROJECTION_STACK_DEPTH"]               = 0x0BA4,
        ["TEXTURE_STACK_DEPTH"]                  = 0x0BA5,
        ["MODELVIEW_MATRIX"]                     = 0x0BA6,
        ["PROJECTION_MATRIX"]                    = 0x0BA7,
        ["TEXTURE_MATRIX"]                       = 0x0BA8,
        ["ATTRIB_STACK_DEPTH"]                   = 0x0BB0,
        ["CLIENT_ATTRIB_STACK_DEPTH"]            = 0x0BB1,
        ["ALPHA_TEST"]                           = 0x0BC0,
        ["ALPHA_TEST_FUNC"]                      = 0x0BC1,
        ["ALPHA_TEST_REF"]                       = 0x0BC2,
        ["DITHER"]                               = 0x0BD0,
        ["BLEND_DST"]                            = 0x0BE0,
        ["BLEND_SRC"]                            = 0x0BE1,
        ["BLEND"]                                = 0x0BE2,
        ["LOGIC_OP_MODE"]                        = 0x0BF0,
        ["INDEX_LOGIC_OP"]                       = 0x0BF1,
        ["COLOR_LOGIC_OP"]                       = 0x0BF2,
        ["AUX_BUFFERS"]                          = 0x0C00,
        ["DRAW_BUFFER"]                          = 0x0C01,
        ["READ_BUFFER"]                          = 0x0C02,
        ["SCISSOR_BOX"]                          = 0x0C10,
        ["SCISSOR_TEST"]                         = 0x0C11,
        ["INDEX_CLEAR_VALUE"]                    = 0x0C20,
        ["INDEX_WRITEMASK"]                      = 0x0C21,
        ["COLOR_CLEAR_VALUE"]                    = 0x0C22,
        ["COLOR_WRITEMASK"]                      = 0x0C23,
        ["INDEX_MODE"]                           = 0x0C30,
        ["RGBA_MODE"]                            = 0x0C31,
        ["DOUBLEBUFFER"]                         = 0x0C32,
        ["STEREO"]                               = 0x0C33,
        ["RENDER_MODE"]                          = 0x0C40,
        ["PERSPECTIVE_CORRECTION_HINT"]          = 0x0C50,
        ["POINT_SMOOTH_HINT"]                    = 0x0C51,
        ["LINE_SMOOTH_HINT"]                     = 0x0C52,
        ["POLYGON_SMOOTH_HINT"]                  = 0x0C53,
        ["FOG_HINT"]                             = 0x0C54,
        ["TEXTURE_GEN_S"]                        = 0x0C60,
        ["TEXTURE_GEN_T"]                        = 0x0C61,
        ["TEXTURE_GEN_R"]                        = 0x0C62,
        ["TEXTURE_GEN_Q"]                        = 0x0C63,
        ["PIXEL_MAP_I_TO_I"]                     = 0x0C70,
        ["PIXEL_MAP_S_TO_S"]                     = 0x0C71,
        ["PIXEL_MAP_I_TO_R"]                     = 0x0C72,
        ["PIXEL_MAP_I_TO_G"]                     = 0x0C73,
        ["PIXEL_MAP_I_TO_B"]                     = 0x0C74,
        ["PIXEL_MAP_I_TO_A"]                     = 0x0C75,
        ["PIXEL_MAP_R_TO_R"]                     = 0x0C76,
        ["PIXEL_MAP_G_TO_G"]                     = 0x0C77,
        ["PIXEL_MAP_B_TO_B"]                     = 0x0C78,
        ["PIXEL_MAP_A_TO_A"]                     = 0x0C79,
        ["PIXEL_MAP_I_TO_I_SIZE"]                = 0x0CB0,
        ["PIXEL_MAP_S_TO_S_SIZE"]                = 0x0CB1,
        ["PIXEL_MAP_I_TO_R_SIZE"]                = 0x0CB2,
        ["PIXEL_MAP_I_TO_G_SIZE"]                = 0x0CB3,
        ["PIXEL_MAP_I_TO_B_SIZE"]                = 0x0CB4,
        ["PIXEL_MAP_I_TO_A_SIZE"]                = 0x0CB5,
        ["PIXEL_MAP_R_TO_R_SIZE"]                = 0x0CB6,
        ["PIXEL_MAP_G_TO_G_SIZE"]                = 0x0CB7,
        ["PIXEL_MAP_B_TO_B_SIZE"]                = 0x0CB8,
        ["PIXEL_MAP_A_TO_A_SIZE"]                = 0x0CB9,
        ["UNPACK_SWAP_BYTES"]                    = 0x0CF0,
        ["UNPACK_LSB_FIRST"]                     = 0x0CF1,
        ["UNPACK_ROW_LENGTH"]                    = 0x0CF2,
        ["UNPACK_SKIP_ROWS"]                     = 0x0CF3,
        ["UNPACK_SKIP_PIXELS"]                   = 0x0CF4,
        ["UNPACK_ALIGNMENT"]                     = 0x0CF5,
        ["PACK_SWAP_BYTES"]                      = 0x0D00,
        ["PACK_LSB_FIRST"]                       = 0x0D01,
        ["PACK_ROW_LENGTH"]                      = 0x0D02,
        ["PACK_SKIP_ROWS"]                       = 0x0D03,
        ["PACK_SKIP_PIXELS"]                     = 0x0D04,
        ["PACK_ALIGNMENT"]                       = 0x0D05,
        ["MAP_COLOR"]                            = 0x0D10,
        ["MAP_STENCIL"]                          = 0x0D11,
        ["INDEX_SHIFT"]                          = 0x0D12,
        ["INDEX_OFFSET"]                         = 0x0D13,
        ["RED_SCALE"]                            = 0x0D14,
        ["RED_BIAS"]                             = 0x0D15,
        ["ZOOM_X"]                               = 0x0D16,
        ["ZOOM_Y"]                               = 0x0D17,
        ["GREEN_SCALE"]                          = 0x0D18,
        ["GREEN_BIAS"]                           = 0x0D19,
        ["BLUE_SCALE"]                           = 0x0D1A,
        ["BLUE_BIAS"]                            = 0x0D1B,
        ["ALPHA_SCALE"]                          = 0x0D1C,
        ["ALPHA_BIAS"]                           = 0x0D1D,
        ["DEPTH_SCALE"]                          = 0x0D1E,
        ["DEPTH_BIAS"]                           = 0x0D1F,
        ["MAX_EVAL_ORDER"]                       = 0x0D30,
        ["MAX_LIGHTS"]                           = 0x0D31,
        ["MAX_CLIP_PLANES"]                      = 0x0D32,
        ["MAX_TEXTURE_SIZE"]                     = 0x0D33,
        ["MAX_PIXEL_MAP_TABLE"]                  = 0x0D34,
        ["MAX_ATTRIB_STACK_DEPTH"]               = 0x0D35,
        ["MAX_MODELVIEW_STACK_DEPTH"]            = 0x0D36,
        ["MAX_NAME_STACK_DEPTH"]                 = 0x0D37,
        ["MAX_PROJECTION_STACK_DEPTH"]           = 0x0D38,
        ["MAX_TEXTURE_STACK_DEPTH"]              = 0x0D39,
        ["MAX_VIEWPORT_DIMS"]                    = 0x0D3A,
        ["MAX_CLIENT_ATTRIB_STACK_DEPTH"]        = 0x0D3B,
        ["SUBPIXEL_BITS"]                        = 0x0D50,
        ["INDEX_BITS"]                           = 0x0D51,
        ["RED_BITS"]                             = 0x0D52,
        ["GREEN_BITS"]                           = 0x0D53,
        ["BLUE_BITS"]                            = 0x0D54,
        ["ALPHA_BITS"]                           = 0x0D55,
        ["DEPTH_BITS"]                           = 0x0D56,
        ["STENCIL_BITS"]                         = 0x0D57,
        ["ACCUM_RED_BITS"]                       = 0x0D58,
        ["ACCUM_GREEN_BITS"]                     = 0x0D59,
        ["ACCUM_BLUE_BITS"]                      = 0x0D5A,
        ["ACCUM_ALPHA_BITS"]                     = 0x0D5B,
        ["NAME_STACK_DEPTH"]                     = 0x0D70,
        ["AUTO_NORMAL"]                          = 0x0D80,
        ["MAP1_COLOR_4"]                         = 0x0D90,
        ["MAP1_INDEX"]                           = 0x0D91,
        ["MAP1_NORMAL"]                          = 0x0D92,
        ["MAP1_TEXTURE_COORD_1"]                 = 0x0D93,
        ["MAP1_TEXTURE_COORD_2"]                 = 0x0D94,
        ["MAP1_TEXTURE_COORD_3"]                 = 0x0D95,
        ["MAP1_TEXTURE_COORD_4"]                 = 0x0D96,
        ["MAP1_VERTEX_3"]                        = 0x0D97,
        ["MAP1_VERTEX_4"]                        = 0x0D98,
        ["MAP2_COLOR_4"]                         = 0x0DB0,
        ["MAP2_INDEX"]                           = 0x0DB1,
        ["MAP2_NORMAL"]                          = 0x0DB2,
        ["MAP2_TEXTURE_COORD_1"]                 = 0x0DB3,
        ["MAP2_TEXTURE_COORD_2"]                 = 0x0DB4,
        ["MAP2_TEXTURE_COORD_3"]                 = 0x0DB5,
        ["MAP2_TEXTURE_COORD_4"]                 = 0x0DB6,
        ["MAP2_VERTEX_3"]                        = 0x0DB7,
        ["MAP2_VERTEX_4"]                        = 0x0DB8,
        ["MAP1_GRID_DOMAIN"]                     = 0x0DD0,
        ["MAP1_GRID_SEGMENTS"]                   = 0x0DD1,
        ["MAP2_GRID_DOMAIN"]                     = 0x0DD2,
        ["MAP2_GRID_SEGMENTS"]                   = 0x0DD3,
        ["TEXTURE_1D"]                           = 0x0DE0,
        ["TEXTURE_2D"]                           = 0x0DE1,
        ["FEEDBACK_BUFFER_POINTER"]              = 0x0DF0,
        ["FEEDBACK_BUFFER_SIZE"]                 = 0x0DF1,
        ["FEEDBACK_BUFFER_TYPE"]                 = 0x0DF2,
        ["SELECTION_BUFFER_POINTER"]             = 0x0DF3,
        ["SELECTION_BUFFER_SIZE"]                = 0x0DF4,
        ["TEXTURE_WIDTH"]                        = 0x1000,
        ["TEXTURE_HEIGHT"]                       = 0x1001,
        ["TEXTURE_INTERNAL_FORMAT"]              = 0x1003,
        ["TEXTURE_BORDER_COLOR"]                 = 0x1004,
        ["TEXTURE_BORDER"]                       = 0x1005,
        ["DONT_CARE"]                            = 0x1100,
        ["FASTEST"]                              = 0x1101,
        ["NICEST"]                               = 0x1102,
        ["LIGHT0"]                               = 0x4000,
        ["LIGHT1"]                               = 0x4001,
        ["LIGHT2"]                               = 0x4002,
        ["LIGHT3"]                               = 0x4003,
        ["LIGHT4"]                               = 0x4004,
        ["LIGHT5"]                               = 0x4005,
        ["LIGHT6"]                               = 0x4006,
        ["LIGHT7"]                               = 0x4007,
        ["AMBIENT"]                              = 0x1200,
        ["DIFFUSE"]                              = 0x1201,
        ["SPECULAR"]                             = 0x1202,
        ["POSITION"]                             = 0x1203,
        ["SPOT_DIRECTION"]                       = 0x1204,
        ["SPOT_EXPONENT"]                        = 0x1205,
        ["SPOT_CUTOFF"]                          = 0x1206,
        ["CONSTANT_ATTENUATION"]                 = 0x1207,
        ["LINEAR_ATTENUATION"]                   = 0x1208,
        ["QUADRATIC_ATTENUATION"]                = 0x1209,
        ["COMPILE"]                              = 0x1300,
        ["COMPILE_AND_EXECUTE"]                  = 0x1301,
        ["CLEAR"]                                = 0x1500,
        ["AND"]                                  = 0x1501,
        ["AND_REVERSE"]                          = 0x1502,
        ["COPY"]                                 = 0x1503,
        ["AND_INVERTED"]                         = 0x1504,
        ["NOOP"]                                 = 0x1505,
        ["XOR"]                                  = 0x1506,
        ["OR"]                                   = 0x1507,
        ["NOR"]                                  = 0x1508,
        ["EQUIV"]                                = 0x1509,
        ["INVERT"]                               = 0x150A,
        ["OR_REVERSE"]                           = 0x150B,
        ["COPY_INVERTED"]                        = 0x150C,
        ["OR_INVERTED"]                          = 0x150D,
        ["NAND"]                                 = 0x150E,
        ["SET"]                                  = 0x150F,
        ["EMISSION"]                             = 0x1600,
        ["SHININESS"]                            = 0x1601,
        ["AMBIENT_AND_DIFFUSE"]                  = 0x1602,
        ["COLOR_INDEXES"]                        = 0x1603,
        ["MODELVIEW"]                            = 0x1700,
        ["PROJECTION"]                           = 0x1701,
        ["TEXTURE"]                              = 0x1702,
        ["COLOR"]                                = 0x1800,
        ["DEPTH"]                                = 0x1801,
        ["STENCIL"]                              = 0x1802,
        ["COLOR_INDEX"]                          = 0x1900,
        ["STENCIL_INDEX"]                        = 0x1901,
        ["DEPTH_COMPONENT"]                      = 0x1902,
        ["RED"]                                  = 0x1903,
        ["GREEN"]                                = 0x1904,
        ["BLUE"]                                 = 0x1905,
        ["ALPHA"]                                = 0x1906,
        ["RGB"]                                  = 0x1907,
        ["RGBA"]                                 = 0x1908,
        ["LUMINANCE"]                            = 0x1909,
        ["LUMINANCE_ALPHA"]                      = 0x190A,
        ["BITMAP"]                               = 0x1A00,
        ["POINT"]                                = 0x1B00,
        ["LINE"]                                 = 0x1B01,
        ["FILL"]                                 = 0x1B02,
        ["RENDER"]                               = 0x1C00,
        ["FEEDBACK"]                             = 0x1C01,
        ["SELECT"]                               = 0x1C02,
        ["FLAT"]                                 = 0x1D00,
        ["SMOOTH"]                               = 0x1D01,
        ["KEEP"]                                 = 0x1E00,
        ["REPLACE"]                              = 0x1E01,
        ["INCR"]                                 = 0x1E02,
        ["DECR"]                                 = 0x1E03,
        ["VENDOR"]                               = 0x1F00,
        ["RENDERER"]                             = 0x1F01,
        ["VERSION"]                              = 0x1F02,
        ["EXTENSIONS"]                           = 0x1F03,
        ["S"]                                    = 0x2000,
        ["T"]                                    = 0x2001,
        ["R"]                                    = 0x2002,
        ["Q"]                                    = 0x2003,
        ["MODULATE"]                             = 0x2100,
        ["DECAL"]                                = 0x2101,
        ["TEXTURE_ENV_MODE"]                     = 0x2200,
        ["TEXTURE_ENV_COLOR"]                    = 0x2201,
        ["TEXTURE_ENV"]                          = 0x2300,
        ["EYE_LINEAR"]                           = 0x2400,
        ["OBJECT_LINEAR"]                        = 0x2401,
        ["SPHERE_MAP"]                           = 0x2402,
        ["TEXTURE_GEN_MODE"]                     = 0x2500,
        ["OBJECT_PLANE"]                         = 0x2501,
        ["EYE_PLANE"]                            = 0x2502,
        ["NEAREST"]                              = 0x2600,
        ["LINEAR"]                               = 0x2601,
        ["NEAREST_MIPMAP_NEAREST"]               = 0x2700,
        ["LINEAR_MIPMAP_NEAREST"]                = 0x2701,
        ["NEAREST_MIPMAP_LINEAR"]                = 0x2702,
        ["LINEAR_MIPMAP_LINEAR"]                 = 0x2703,
        ["TEXTURE_MAG_FILTER"]                   = 0x2800,
        ["TEXTURE_MIN_FILTER"]                   = 0x2801,
        ["TEXTURE_WRAP_S"]                       = 0x2802,
        ["TEXTURE_WRAP_T"]                       = 0x2803,
        ["CLAMP"]                                = 0x2900,
        ["REPEAT"]                               = 0x2901,
        ["CLIENT_PIXEL_STORE_BIT"]               = 0x00000001,
        ["CLIENT_VERTEX_ARRAY_BIT"]              = 0x00000002,
        ["CLIENT_ALL_ATTRIB_BITS"]               = 0xffffffff,
        ["POLYGON_OFFSET_FACTOR"]                = 0x8038,
        ["POLYGON_OFFSET_UNITS"]                 = 0x2A00,
        ["POLYGON_OFFSET_POINT"]                 = 0x2A01,
        ["POLYGON_OFFSET_LINE"]                  = 0x2A02,
        ["POLYGON_OFFSET_FILL"]                  = 0x8037,
        ["ALPHA4"]                               = 0x803B,
        ["ALPHA8"]                               = 0x803C,
        ["ALPHA12"]                              = 0x803D,
        ["ALPHA16"]                              = 0x803E,
        ["LUMINANCE4"]                           = 0x803F,
        ["LUMINANCE8"]                           = 0x8040,
        ["LUMINANCE12"]                          = 0x8041,
        ["LUMINANCE16"]                          = 0x8042,
        ["LUMINANCE4_ALPHA4"]                    = 0x8043,
        ["LUMINANCE6_ALPHA2"]                    = 0x8044,
        ["LUMINANCE8_ALPHA8"]                    = 0x8045,
        ["LUMINANCE12_ALPHA4"]                   = 0x8046,
        ["LUMINANCE12_ALPHA12"]                  = 0x8047,
        ["LUMINANCE16_ALPHA16"]                  = 0x8048,
        ["INTENSITY"]                            = 0x8049,
        ["INTENSITY4"]                           = 0x804A,
        ["INTENSITY8"]                           = 0x804B,
        ["INTENSITY12"]                          = 0x804C,
        ["INTENSITY16"]                          = 0x804D,
        ["R3_G3_B2"]                             = 0x2A10,
        ["RGB4"]                                 = 0x804F,
        ["RGB5"]                                 = 0x8050,
        ["RGB8"]                                 = 0x8051,
        ["RGB10"]                                = 0x8052,
        ["RGB12"]                                = 0x8053,
        ["RGB16"]                                = 0x8054,
        ["RGBA2"]                                = 0x8055,
        ["RGBA4"]                                = 0x8056,
        ["RGB5_A1"]                              = 0x8057,
        ["RGBA8"]                                = 0x8058,
        ["RGB10_A2"]                             = 0x8059,
        ["RGBA12"]                               = 0x805A,
        ["RGBA16"]                               = 0x805B,
        ["TEXTURE_RED_SIZE"]                     = 0x805C,
        ["TEXTURE_GREEN_SIZE"]                   = 0x805D,
        ["TEXTURE_BLUE_SIZE"]                    = 0x805E,
        ["TEXTURE_ALPHA_SIZE"]                   = 0x805F,
        ["TEXTURE_LUMINANCE_SIZE"]               = 0x8060,
        ["TEXTURE_INTENSITY_SIZE"]               = 0x8061,
        ["PROXY_TEXTURE_1D"]                     = 0x8063,
        ["PROXY_TEXTURE_2D"]                     = 0x8064,
        ["TEXTURE_PRIORITY"]                     = 0x8066,
        ["TEXTURE_RESIDENT"]                     = 0x8067,
        ["TEXTURE_BINDING_1D"]                   = 0x8068,
        ["TEXTURE_BINDING_2D"]                   = 0x8069,
        ["TEXTURE_BINDING_3D"]                   = 0x806A,
        ["VERTEX_ARRAY"]                         = 0x8074,
        ["NORMAL_ARRAY"]                         = 0x8075,
        ["COLOR_ARRAY"]                          = 0x8076,
        ["INDEX_ARRAY"]                          = 0x8077,
        ["TEXTURE_COORD_ARRAY"]                  = 0x8078,
        ["EDGE_FLAG_ARRAY"]                      = 0x8079,
        ["VERTEX_ARRAY_SIZE"]                    = 0x807A,
        ["VERTEX_ARRAY_TYPE"]                    = 0x807B,
        ["VERTEX_ARRAY_STRIDE"]                  = 0x807C,
        ["NORMAL_ARRAY_TYPE"]                    = 0x807E,
        ["NORMAL_ARRAY_STRIDE"]                  = 0x807F,
        ["COLOR_ARRAY_SIZE"]                     = 0x8081,
        ["COLOR_ARRAY_TYPE"]                     = 0x8082,
        ["COLOR_ARRAY_STRIDE"]                   = 0x8083,
        ["INDEX_ARRAY_TYPE"]                     = 0x8085,
        ["INDEX_ARRAY_STRIDE"]                   = 0x8086,
        ["TEXTURE_COORD_ARRAY_SIZE"]             = 0x8088,
        ["TEXTURE_COORD_ARRAY_TYPE"]             = 0x8089,
        ["TEXTURE_COORD_ARRAY_STRIDE"]           = 0x808A,
        ["EDGE_FLAG_ARRAY_STRIDE"]               = 0x808C,
        ["VERTEX_ARRAY_POINTER"]                 = 0x808E,
        ["NORMAL_ARRAY_POINTER"]                 = 0x808F,
        ["COLOR_ARRAY_POINTER"]                  = 0x8090,
        ["INDEX_ARRAY_POINTER"]                  = 0x8091,
        ["TEXTURE_COORD_ARRAY_POINTER"]          = 0x8092,
        ["EDGE_FLAG_ARRAY_POINTER"]              = 0x8093,
        ["V2F"]                                  = 0x2A20,
        ["V3F"]                                  = 0x2A21,
        ["C4UB_V2F"]                             = 0x2A22,
        ["C4UB_V3F"]                             = 0x2A23,
        ["C3F_V3F"]                              = 0x2A24,
        ["N3F_V3F"]                              = 0x2A25,
        ["C4F_N3F_V3F"]                          = 0x2A26,
        ["T2F_V3F"]                              = 0x2A27,
        ["T4F_V4F"]                              = 0x2A28,
        ["T2F_C4UB_V3F"]                         = 0x2A29,
        ["T2F_C3F_V3F"]                          = 0x2A2A,
        ["T2F_N3F_V3F"]                          = 0x2A2B,
        ["T2F_C4F_N3F_V3F"]                      = 0x2A2C,
        ["T4F_C4F_N3F_V4F"]                      = 0x2A2D,
        ["BGR"]                                  = 0x80E0,
        ["BGRA"]                                 = 0x80E1,
        ["CONSTANT_COLOR"]                       = 0x8001,
        ["ONE_MINUS_CONSTANT_COLOR"]             = 0x8002,
        ["CONSTANT_ALPHA"]                       = 0x8003,
        ["ONE_MINUS_CONSTANT_ALPHA"]             = 0x8004,
        ["BLEND_COLOR"]                          = 0x8005,
        ["FUNC_ADD"]                             = 0x8006,
        ["MIN"]                                  = 0x8007,
        ["MAX"]                                  = 0x8008,
        ["BLEND_EQUATION"]                       = 0x8009,
        ["BLEND_EQUATION_RGB"]                   = 0x8009,
        ["BLEND_EQUATION_ALPHA"]                 = 0x883D,
        ["FUNC_SUBTRACT"]                        = 0x800A,
        ["FUNC_REVERSE_SUBTRACT"]                = 0x800B,
        ["COLOR_MATRIX"]                         = 0x80B1,
        ["COLOR_MATRIX_STACK_DEPTH"]             = 0x80B2,
        ["MAX_COLOR_MATRIX_STACK_DEPTH"]         = 0x80B3,
        ["POST_COLOR_MATRIX_RED_SCALE"]          = 0x80B4,
        ["POST_COLOR_MATRIX_GREEN_SCALE"]        = 0x80B5,
        ["POST_COLOR_MATRIX_BLUE_SCALE"]         = 0x80B6,
        ["POST_COLOR_MATRIX_ALPHA_SCALE"]        = 0x80B7,
        ["POST_COLOR_MATRIX_RED_BIAS"]           = 0x80B8,
        ["POST_COLOR_MATRIX_GREEN_BIAS"]         = 0x80B9,
        ["POST_COLOR_MATRIX_BLUE_BIAS"]          = 0x80BA,
        ["POST_COLOR_MATRIX_ALPHA_BIAS"]         = 0x80BB,
        ["COLOR_TABLE"]                          = 0x80D0,
        ["POST_CONVOLUTION_COLOR_TABLE"]         = 0x80D1,
        ["POST_COLOR_MATRIX_COLOR_TABLE"]        = 0x80D2,
        ["PROXY_COLOR_TABLE"]                    = 0x80D3,
        ["PROXY_POST_CONVOLUTION_COLOR_TABLE"]   = 0x80D4,
        ["PROXY_POST_COLOR_MATRIX_COLOR_TABLE"]  = 0x80D5,
        ["COLOR_TABLE_SCALE"]                    = 0x80D6,
        ["COLOR_TABLE_BIAS"]                     = 0x80D7,
        ["COLOR_TABLE_FORMAT"]                   = 0x80D8,
        ["COLOR_TABLE_WIDTH"]                    = 0x80D9,
        ["COLOR_TABLE_RED_SIZE"]                 = 0x80DA,
        ["COLOR_TABLE_GREEN_SIZE"]               = 0x80DB,
        ["COLOR_TABLE_BLUE_SIZE"]                = 0x80DC,
        ["COLOR_TABLE_ALPHA_SIZE"]               = 0x80DD,
        ["COLOR_TABLE_LUMINANCE_SIZE"]           = 0x80DE,
        ["COLOR_TABLE_INTENSITY_SIZE"]           = 0x80DF,
        ["CONVOLUTION_1D"]                       = 0x8010,
        ["CONVOLUTION_2D"]                       = 0x8011,
        ["SEPARABLE_2D"]                         = 0x8012,
        ["CONVOLUTION_BORDER_MODE"]              = 0x8013,
        ["CONVOLUTION_FILTER_SCALE"]             = 0x8014,
        ["CONVOLUTION_FILTER_BIAS"]              = 0x8015,
        ["REDUCE"]                               = 0x8016,
        ["CONVOLUTION_FORMAT"]                   = 0x8017,
        ["CONVOLUTION_WIDTH"]                    = 0x8018,
        ["CONVOLUTION_HEIGHT"]                   = 0x8019,
        ["MAX_CONVOLUTION_WIDTH"]                = 0x801A,
        ["MAX_CONVOLUTION_HEIGHT"]               = 0x801B,
        ["POST_CONVOLUTION_RED_SCALE"]           = 0x801C,
        ["POST_CONVOLUTION_GREEN_SCALE"]         = 0x801D,
        ["POST_CONVOLUTION_BLUE_SCALE"]          = 0x801E,
        ["POST_CONVOLUTION_ALPHA_SCALE"]         = 0x801F,
        ["POST_CONVOLUTION_RED_BIAS"]            = 0x8020,
        ["POST_CONVOLUTION_GREEN_BIAS"]          = 0x8021,
        ["POST_CONVOLUTION_BLUE_BIAS"]           = 0x8022,
        ["POST_CONVOLUTION_ALPHA_BIAS"]          = 0x8023,
        ["CONSTANT_BORDER"]                      = 0x8151,
        ["REPLICATE_BORDER"]                     = 0x8153,
        ["CONVOLUTION_BORDER_COLOR"]             = 0x8154,
        ["MAX_ELEMENTS_VERTICES"]                = 0x80E8,
        ["MAX_ELEMENTS_INDICES"]                 = 0x80E9,
        ["HISTOGRAM"]                            = 0x8024,
        ["PROXY_HISTOGRAM"]                      = 0x8025,
        ["HISTOGRAM_WIDTH"]                      = 0x8026,
        ["HISTOGRAM_FORMAT"]                     = 0x8027,
        ["HISTOGRAM_RED_SIZE"]                   = 0x8028,
        ["HISTOGRAM_GREEN_SIZE"]                 = 0x8029,
        ["HISTOGRAM_BLUE_SIZE"]                  = 0x802A,
        ["HISTOGRAM_ALPHA_SIZE"]                 = 0x802B,
        ["HISTOGRAM_LUMINANCE_SIZE"]             = 0x802C,
        ["HISTOGRAM_SINK"]                       = 0x802D,
        ["MINMAX"]                               = 0x802E,
        ["MINMAX_FORMAT"]                        = 0x802F,
        ["MINMAX_SINK"]                          = 0x8030,
        ["TABLE_TOO_LARGE"]                      = 0x8031,
        ["UNSIGNED_BYTE_3_3_2"]                  = 0x8032,
        ["UNSIGNED_SHORT_4_4_4_4"]               = 0x8033,
        ["UNSIGNED_SHORT_5_5_5_1"]               = 0x8034,
        ["UNSIGNED_INT_8_8_8_8"]                 = 0x8035,
        ["UNSIGNED_INT_10_10_10_2"]              = 0x8036,
        ["UNSIGNED_BYTE_2_3_3_REV"]              = 0x8362,
        ["UNSIGNED_SHORT_5_6_5"]                 = 0x8363,
        ["UNSIGNED_SHORT_5_6_5_REV"]             = 0x8364,
        ["UNSIGNED_SHORT_4_4_4_4_REV"]           = 0x8365,
        ["UNSIGNED_SHORT_1_5_5_5_REV"]           = 0x8366,
        ["UNSIGNED_INT_8_8_8_8_REV"]             = 0x8367,
        ["UNSIGNED_INT_2_10_10_10_REV"]          = 0x8368,
        ["RESCALE_NORMAL"]                       = 0x803A,
        ["LIGHT_MODEL_COLOR_CONTROL"]            = 0x81F8,
        ["SINGLE_COLOR"]                         = 0x81F9,
        ["SEPARATE_SPECULAR_COLOR"]              = 0x81FA,
        ["PACK_SKIP_IMAGES"]                     = 0x806B,
        ["PACK_IMAGE_HEIGHT"]                    = 0x806C,
        ["UNPACK_SKIP_IMAGES"]                   = 0x806D,
        ["UNPACK_IMAGE_HEIGHT"]                  = 0x806E,
        ["TEXTURE_3D"]                           = 0x806F,
        ["PROXY_TEXTURE_3D"]                     = 0x8070,
        ["TEXTURE_DEPTH"]                        = 0x8071,
        ["TEXTURE_WRAP_R"]                       = 0x8072,
        ["MAX_3D_TEXTURE_SIZE"]                  = 0x8073,
        ["CLAMP_TO_EDGE"]                        = 0x812F,
        ["CLAMP_TO_BORDER"]                      = 0x812D,
        ["TEXTURE_MIN_LOD"]                      = 0x813A,
        ["TEXTURE_MAX_LOD"]                      = 0x813B,
        ["TEXTURE_BASE_LEVEL"]                   = 0x813C,
        ["TEXTURE_MAX_LEVEL"]                    = 0x813D,
        ["SMOOTH_POINT_SIZE_RANGE"]              = 0x0B12,
        ["SMOOTH_POINT_SIZE_GRANULARITY"]        = 0x0B13,
        ["SMOOTH_LINE_WIDTH_RANGE"]              = 0x0B22,
        ["SMOOTH_LINE_WIDTH_GRANULARITY"]        = 0x0B23,
        ["ALIASED_POINT_SIZE_RANGE"]             = 0x846D,
        ["ALIASED_LINE_WIDTH_RANGE"]             = 0x846E,
        ["TEXTURE0"]                             = 0x84C0,
        ["TEXTURE1"]                             = 0x84C1,
        ["TEXTURE2"]                             = 0x84C2,
        ["TEXTURE3"]                             = 0x84C3,
        ["TEXTURE4"]                             = 0x84C4,
        ["TEXTURE5"]                             = 0x84C5,
        ["TEXTURE6"]                             = 0x84C6,
        ["TEXTURE7"]                             = 0x84C7,
        ["TEXTURE8"]                             = 0x84C8,
        ["TEXTURE9"]                             = 0x84C9,
        ["TEXTURE10"]                            = 0x84CA,
        ["TEXTURE11"]                            = 0x84CB,
        ["TEXTURE12"]                            = 0x84CC,
        ["TEXTURE13"]                            = 0x84CD,
        ["TEXTURE14"]                            = 0x84CE,
        ["TEXTURE15"]                            = 0x84CF,
        ["TEXTURE16"]                            = 0x84D0,
        ["TEXTURE17"]                            = 0x84D1,
        ["TEXTURE18"]                            = 0x84D2,
        ["TEXTURE19"]                            = 0x84D3,
        ["TEXTURE20"]                            = 0x84D4,
        ["TEXTURE21"]                            = 0x84D5,
        ["TEXTURE22"]                            = 0x84D6,
        ["TEXTURE23"]                            = 0x84D7,
        ["TEXTURE24"]                            = 0x84D8,
        ["TEXTURE25"]                            = 0x84D9,
        ["TEXTURE26"]                            = 0x84DA,
        ["TEXTURE27"]                            = 0x84DB,
        ["TEXTURE28"]                            = 0x84DC,
        ["TEXTURE29"]                            = 0x84DD,
        ["TEXTURE30"]                            = 0x84DE,
        ["TEXTURE31"]                            = 0x84DF,
        ["ACTIVE_TEXTURE"]                       = 0x84E0,
        ["CLIENT_ACTIVE_TEXTURE"]                = 0x84E1,
        ["MAX_TEXTURE_UNITS"]                    = 0x84E2,
        ["COMBINE"]                              = 0x8570,
        ["COMBINE_RGB"]                          = 0x8571,
        ["COMBINE_ALPHA"]                        = 0x8572,
        ["RGB_SCALE"]                            = 0x8573,
        ["ADD_SIGNED"]                           = 0x8574,
        ["INTERPOLATE"]                          = 0x8575,
        ["CONSTANT"]                             = 0x8576,
        ["PRIMARY_COLOR"]                        = 0x8577,
        ["PREVIOUS"]                             = 0x8578,
        ["SUBTRACT"]                             = 0x84E7,
        ["SR0_RGB"]                              = 0x8580,
        ["SRC1_RGB"]                             = 0x8581,
        ["SRC2_RGB"]                             = 0x8582,
        ["SRC3_RGB"]                             = 0x8583,
        ["SRC4_RGB"]                             = 0x8584,
        ["SRC5_RGB"]                             = 0x8585,
        ["SRC6_RGB"]                             = 0x8586,
        ["SRC7_RGB"]                             = 0x8587,
        ["SRC0_ALPHA"]                           = 0x8588,
        ["SRC1_ALPHA"]                           = 0x8589,
        ["SRC2_ALPHA"]                           = 0x858A,
        ["SRC3_ALPHA"]                           = 0x858B,
        ["SRC4_ALPHA"]                           = 0x858C,
        ["SRC5_ALPHA"]                           = 0x858D,
        ["SRC6_ALPHA"]                           = 0x858E,
        ["SRC7_ALPHA"]                           = 0x858F,
        ["SOURCE0_RGB"]                          = 0x8580,
        ["SOURCE1_RGB"]                          = 0x8581,
        ["SOURCE2_RGB"]                          = 0x8582,
        ["SOURCE3_RGB"]                          = 0x8583,
        ["SOURCE4_RGB"]                          = 0x8584,
        ["SOURCE5_RGB"]                          = 0x8585,
        ["SOURCE6_RGB"]                          = 0x8586,
        ["SOURCE7_RGB"]                          = 0x8587,
        ["SOURCE0_ALPHA"]                        = 0x8588,
        ["SOURCE1_ALPHA"]                        = 0x8589,
        ["SOURCE2_ALPHA"]                        = 0x858A,
        ["SOURCE3_ALPHA"]                        = 0x858B,
        ["SOURCE4_ALPHA"]                        = 0x858C,
        ["SOURCE5_ALPHA"]                        = 0x858D,
        ["SOURCE6_ALPHA"]                        = 0x858E,
        ["SOURCE7_ALPHA"]                        = 0x858F,
        ["OPERAND0_RGB"]                         = 0x8590,
        ["OPERAND1_RGB"]                         = 0x8591,
        ["OPERAND2_RGB"]                         = 0x8592,
        ["OPERAND3_RGB"]                         = 0x8593,
        ["OPERAND4_RGB"]                         = 0x8594,
        ["OPERAND5_RGB"]                         = 0x8595,
        ["OPERAND6_RGB"]                         = 0x8596,
        ["OPERAND7_RGB"]                         = 0x8597,
        ["OPERAND0_ALPHA"]                       = 0x8598,
        ["OPERAND1_ALPHA"]                       = 0x8599,
        ["OPERAND2_ALPHA"]                       = 0x859A,
        ["OPERAND3_ALPHA"]                       = 0x859B,
        ["OPERAND4_ALPHA"]                       = 0x859C,
        ["OPERAND5_ALPHA"]                       = 0x859D,
        ["OPERAND6_ALPHA"]                       = 0x859E,
        ["OPERAND7_ALPHA"]                       = 0x859F,
        ["DOT3_RGB"]                             = 0x86AE,
        ["DOT3_RGBA"]                            = 0x86AF,
        ["TRANSPOSE_MODELVIEW_MATRIX"]           = 0x84E3,
        ["TRANSPOSE_PROJECTION_MATRIX"]          = 0x84E4,
        ["TRANSPOSE_TEXTURE_MATRIX"]             = 0x84E5,
        ["TRANSPOSE_COLOR_MATRIX"]               = 0x84E6,
        ["NORMAL_MAP"]                           = 0x8511,
        ["REFLECTION_MAP"]                       = 0x8512,
        ["TEXTURE_CUBE_MAP"]                     = 0x8513,
        ["TEXTURE_BINDING_CUBE_MAP"]             = 0x8514,
        ["TEXTURE_CUBE_MAP_POSITIVE_X"]          = 0x8515,
        ["TEXTURE_CUBE_MAP_NEGATIVE_X"]          = 0x8516,
        ["TEXTURE_CUBE_MAP_POSITIVE_Y"]          = 0x8517,
        ["TEXTURE_CUBE_MAP_NEGATIVE_Y"]          = 0x8518,
        ["TEXTURE_CUBE_MAP_POSITIVE_Z"]          = 0x8519,
        ["TEXTURE_CUBE_MAP_NEGATIVE_Z"]          = 0x851A,
        ["PROXY_TEXTURE_CUBE_MAP"]               = 0x851B,
        ["MAX_CUBE_MAP_TEXTURE_SIZE"]            = 0x851C,
        ["COMPRESSED_ALPHA"]                     = 0x84E9,
        ["COMPRESSED_LUMINANCE"]                 = 0x84EA,
        ["COMPRESSED_LUMINANCE_ALPHA"]           = 0x84EB,
        ["COMPRESSED_INTENSITY"]                 = 0x84EC,
        ["COMPRESSED_RGB"]                       = 0x84ED,
        ["COMPRESSED_RGBA"]                      = 0x84EE,
        ["TEXTURE_COMPRESSION_HINT"]             = 0x84EF,
        ["TEXTURE_COMPRESSED_IMAGE_SIZE"]        = 0x86A0,
        ["TEXTURE_COMPRESSED"]                   = 0x86A1,
        ["NUM_COMPRESSED_TEXTURE_FORMATS"]       = 0x86A2,
        ["COMPRESSED_TEXTURE_FORMATS"]           = 0x86A3,
        ["MULTISAMPLE"]                          = 0x809D,
        ["SAMPLE_ALPHA_TO_COVERAGE"]             = 0x809E,
        ["SAMPLE_ALPHA_TO_ONE"]                  = 0x809F,
        ["SAMPLE_COVERAGE"]                      = 0x80A0,
        ["SAMPLE_BUFFERS"]                       = 0x80A8,
        ["SAMPLES"]                              = 0x80A9,
        ["SAMPLE_COVERAGE_VALUE"]                = 0x80AA,
        ["SAMPLE_COVERAGE_INVERT"]               = 0x80AB,
        ["MULTISAMPLE_BIT"]                      = 0x20000000,
        ["DEPTH_COMPONENT16"]                    = 0x81A5,
        ["DEPTH_COMPONENT24"]                    = 0x81A6,
        ["DEPTH_COMPONENT32"]                    = 0x81A7,
        ["TEXTURE_DEPTH_SIZE"]                   = 0x884A,
        ["DEPTH_TEXTURE_MODE"]                   = 0x884B,
        ["TEXTURE_COMPARE_MODE"]                 = 0x884C,
        ["TEXTURE_COMPARE_FUNC"]                 = 0x884D,
        ["COMPARE_R_TO_TEXTURE"]                 = 0x884E,
        ["QUERY_COUNTER_BITS"]                   = 0x8864,
        ["CURRENT_QUERY"]                        = 0x8865,
        ["QUERY_RESULT"]                         = 0x8866,
        ["QUERY_RESULT_AVAILABLE"]               = 0x8867,
        ["SAMPLES_PASSED"]                       = 0x8914,
        ["FOG_COORD_SRC"]                        = 0x8450,
        ["FOG_COORD"]                            = 0x8451,
        ["FRAGMENT_DEPTH"]                       = 0x8452,
        ["CURRENT_FOG_COORD"]                    = 0x8453       ,
        ["FOG_COORD_ARRAY_TYPE"]                 = 0x8454,
        ["FOG_COORD_ARRAY_STRIDE"]               = 0x8455,
        ["FOG_COORD_ARRAY_POINTER"]              = 0x8456,
        ["FOG_COORD_ARRAY"]                      = 0x8457,
        ["FOG_COORDINATE_SOURCE"]                = 0x8450,
        ["FOG_COORDINATE"]                       = 0x8451,
        ["CURRENT_FOG_COORDINATE"]               = 0x8453       ,
        ["FOG_COORDINATE_ARRAY_TYPE"]            = 0x8454,
        ["FOG_COORDINATE_ARRAY_STRIDE"]          = 0x8455,
        ["FOG_COORDINATE_ARRAY_POINTER"]         = 0x8456,
        ["FOG_COORDINATE_ARRAY"]                 = 0x8457,
        ["COLOR_SUM"]                            = 0x8458,
        ["CURRENT_SECONDARY_COLOR"]              = 0x8459,
        ["SECONDARY_COLOR_ARRAY_SIZE"]           = 0x845A,
        ["SECONDARY_COLOR_ARRAY_TYPE"]           = 0x845B,
        ["SECONDARY_COLOR_ARRAY_STRIDE"]         = 0x845C,
        ["SECONDARY_COLOR_ARRAY_POINTER"]        = 0x845D,
        ["SECONDARY_COLOR_ARRAY"]                = 0x845E,
        ["POINT_SIZE_MIN"]                       = 0x8126,
        ["POINT_SIZE_MAX"]                       = 0x8127,
        ["POINT_FADE_THRESHOLD_SIZE"]            = 0x8128,
        ["POINT_DISTANCE_ATTENUATION"]           = 0x8129,
        ["BLEND_DST_RGB"]                        = 0x80C8,
        ["BLEND_SRC_RGB"]                        = 0x80C9,
        ["BLEND_DST_ALPHA"]                      = 0x80CA,
        ["BLEND_SRC_ALPHA"]                      = 0x80CB,
        ["GENERATE_MIPMAP"]                      = 0x8191,
        ["GENERATE_MIPMAP_HINT"]                 = 0x8192,
        ["INCR_WRAP"]                            = 0x8507,
        ["DECR_WRAP"]                            = 0x8508,
        ["MIRRORED_REPEAT"]                      = 0x8370,
        ["MAX_TEXTURE_LOD_BIAS"]                 = 0x84FD,
        ["TEXTURE_FILTER_CONTROL"]               = 0x8500,
        ["TEXTURE_LOD_BIAS"]                     = 0x8501,
        ["ARRAY_BUFFER"]                         = 0x8892,
        ["ELEMENT_ARRAY_BUFFER"]                 = 0x8893,
        ["ARRAY_BUFFER_BINDING"]                 = 0x8894,
        ["ELEMENT_ARRAY_BUFFER_BINDING"]         = 0x8895,
        ["VERTEX_ARRAY_BUFFER_BINDING"]          = 0x8896,
        ["NORMAL_ARRAY_BUFFER_BINDING"]          = 0x8897,
        ["COLOR_ARRAY_BUFFER_BINDING"]           = 0x8898,
        ["INDEX_ARRAY_BUFFER_BINDING"]           = 0x8899,
        ["TEXTURE_COORD_ARRAY_BUFFER_BINDING"]   = 0x889A,
        ["EDGE_FLAG_ARRAY_BUFFER_BINDING"]       = 0x889B,
        ["SECONDARY_COLOR_ARRAY_BUFFER_BINDING"] = 0x889C,
        ["FOG_COORD_ARRAY_BUFFER_BINDING"]       = 0x889D,
        ["WEIGHT_ARRAY_BUFFER_BINDING"]          = 0x889E,
        ["VERTEX_ATTRIB_ARRAY_BUFFER_BINDING"]   = 0x889F,
        ["STREAM_DRAW"]                          = 0x88E0,
        ["STREAM_READ"]                          = 0x88E1,
        ["STREAM_COPY"]                          = 0x88E2,
        ["STATIC_DRAW"]                          = 0x88E4,
        ["STATIC_READ"]                          = 0x88E5,
        ["STATIC_COPY"]                          = 0x88E6,
        ["DYNAMIC_DRAW"]                         = 0x88E8,
        ["DYNAMIC_READ"]                         = 0x88E9,
        ["DYNAMIC_COPY"]                         = 0x88EA,
        ["READ_ONLY"]                            = 0x88B8,
        ["WRITE_ONLY"]                           = 0x88B9,
        ["READ_WRITE"]                           = 0x88BA,
        ["BUFFER_SIZE"]                          = 0x8764,
        ["BUFFER_USAGE"]                         = 0x8765,
        ["BUFFER_ACCESS"]                        = 0x88BB,
        ["BUFFER_MAPPED"]                        = 0x88BC,
        ["BUFFER_MAP_POINTER"]                   = 0x88BD,
        ["FOG_COORDINATE_ARRAY_BUFFER_BINDING"]  = 0x889D,
        ["CURRENT_PROGRAM"]                      = 0x8B8D,
        ["SHADER_TYPE"]                          = 0x8B4F,
        ["DELETE_STATUS"]                        = 0x8B80,
        ["COMPILE_STATUS"]                       = 0x8B81,
        ["LINK_STATUS"]                          = 0x8B82,
        ["VALIDATE_STATUS"]                      = 0x8B83,
        ["INFO_LOG_LENGTH"]                      = 0x8B84,
        ["ATTACHED_SHADERS"]                     = 0x8B85,
        ["ACTIVE_UNIFORMS"]                      = 0x8B86,
        ["ACTIVE_UNIFORM_MAX_LENGTH"]            = 0x8B87,
        ["SHADER_SOURCE_LENGTH"]                 = 0x8B88,
        ["FLOAT_VEC2"]                           = 0x8B50,
        ["FLOAT_VEC3"]                           = 0x8B51,
        ["FLOAT_VEC4"]                           = 0x8B52,
        ["INT_VEC2"]                             = 0x8B53,
        ["INT_VEC3"]                             = 0x8B54,
        ["INT_VEC4"]                             = 0x8B55,
        ["BOOL"]                                 = 0x8B56,
        ["BOOL_VEC2"]                            = 0x8B57,
        ["BOOL_VEC3"]                            = 0x8B58,
        ["BOOL_VEC4"]                            = 0x8B59,
        ["FLOAT_MAT2"]                           = 0x8B5A,
        ["FLOAT_MAT3"]                           = 0x8B5B,
        ["FLOAT_MAT4"]                           = 0x8B5C,
        ["SAMPLER_1D"]                           = 0x8B5D,
        ["SAMPLER_2D"]                           = 0x8B5E,
        ["SAMPLER_3D"]                           = 0x8B5F,
        ["SAMPLER_CUBE"]                         = 0x8B60,
        ["SAMPLER_1D_SHADOW"]                    = 0x8B61,
        ["SAMPLER_2D_SHADOW"]                    = 0x8B62,
        ["SHADING_LANGUAGE_VERSION"]             = 0x8B8C,
        ["VERTEX_SHADER"]                        = 0x8B31,
        ["MAX_VERTEX_UNIFORM_COMPONENTS"]        = 0x8B4A,
        ["MAX_VARYING_FLOATS"]                   = 0x8B4B,
        ["MAX_VERTEX_TEXTURE_IMAGE_UNITS"]       = 0x8B4C,
        ["MAX_COMBINED_TEXTURE_IMAGE_UNITS"]     = 0x8B4D,
        ["ACTIVE_ATTRIBUTES"]                    = 0x8B89,
        ["ACTIVE_ATTRIBUTE_MAX_LENGTH"]          = 0x8B8A,
        ["FRAGMENT_SHADER"]                      = 0x8B30,
        ["MAX_FRAGMENT_UNIFORM_COMPONENTS"]      = 0x8B49,
        ["FRAGMENT_SHADER_DERIVATIVE_HINT"]      = 0x8B8B,
        ["MAX_VERTEX_ATTRIBS"]                   = 0x8869,
        ["VERTEX_ATTRIB_ARRAY_ENABLED"]          = 0x8622,
        ["VERTEX_ATTRIB_ARRAY_SIZE"]             = 0x8623,
        ["VERTEX_ATTRIB_ARRAY_STRIDE"]           = 0x8624,
        ["VERTEX_ATTRIB_ARRAY_TYPE"]             = 0x8625,
        ["VERTEX_ATTRIB_ARRAY_NORMALIZED"]       = 0x886A,
        ["CURRENT_VERTEX_ATTRIB"]                = 0x8626,
        ["VERTEX_ATTRIB_ARRAY_POINTER"]          = 0x8645,
        ["VERTEX_PROGRAM_POINT_SIZE"]            = 0x8642,
        ["VERTEX_PROGRAM_TWO_SIDE"]              = 0x8643,
        ["MAX_TEXTURE_COORDS"]                   = 0x8871,
        ["MAX_TEXTURE_IMAGE_UNITS"]              = 0x8872,
        ["MAX_DRAW_BUFFERS"]                     = 0x8824,
        ["DRAW_BUFFER0"]                         = 0x8825,
        ["DRAW_BUFFER1"]                         = 0x8826,
        ["DRAW_BUFFER2"]                         = 0x8827,
        ["DRAW_BUFFER3"]                         = 0x8828,
        ["DRAW_BUFFER4"]                         = 0x8829,
        ["DRAW_BUFFER5"]                         = 0x882A,
        ["DRAW_BUFFER6"]                         = 0x882B,
        ["DRAW_BUFFER7"]                         = 0x882C,
        ["DRAW_BUFFER8"]                         = 0x882D,
        ["DRAW_BUFFER9"]                         = 0x882E,
        ["DRAW_BUFFER10"]                        = 0x882F,
        ["DRAW_BUFFER11"]                        = 0x8830,
        ["DRAW_BUFFER12"]                        = 0x8831,
        ["DRAW_BUFFER13"]                        = 0x8832,
        ["DRAW_BUFFER14"]                        = 0x8833,
        ["DRAW_BUFFER15"]                        = 0x8834,
        ["POINT_SPRITE"]                         = 0x8861,
        ["COORD_REPLACE"]                        = 0x8862,
        ["POINT_SPRITE_COORD_ORIGIN"]            = 0x8CA0,
        ["LOWER_LEFT"]                           = 0x8CA1,
        ["UPPER_LEFT"]                           = 0x8CA2,
        ["STENCIL_BACK_FUNC"]                    = 0x8800,
        ["STENCIL_BACK_VALUE_MASK"]              = 0x8CA4,
        ["STENCIL_BACK_REF"]                     = 0x8CA3,
        ["STENCIL_BACK_FAIL"]                    = 0x8801,
        ["STENCIL_BACK_PASS_DEPTH_FAIL"]         = 0x8802,
        ["STENCIL_BACK_PASS_DEPTH_PASS"]         = 0x8803,
        ["STENCIL_BACK_WRITEMASK"]               = 0x8CA5,
        ["CURRENT_RASTER_SECONDARY_COLOR"]       = 0x845F,
        ["PIXEL_PACK_BUFFER"]                    = 0x88EB,
        ["PIXEL_UNPACK_BUFFER"]                  = 0x88EC,
        ["PIXEL_PACK_BUFFER_BINDING"]            = 0x88ED,
        ["PIXEL_UNPACK_BUFFER_BINDING"]          = 0x88EF,
        ["FLOAT_MAT2x3"]                         = 0x8B65,
        ["FLOAT_MAT2x4"]                         = 0x8B66,
        ["FLOAT_MAT3x2"]                         = 0x8B67,
        ["FLOAT_MAT3x4"]                         = 0x8B68,
        ["FLOAT_MAT4x2"]                         = 0x8B69,
        ["FLOAT_MAT4x3"]                         = 0x8B6A,
        ["SRGB"]                                 = 0x8C40,
        ["SRGB8"]                                = 0x8C41,
        ["SRGB_ALPHA"]                           = 0x8C42,
        ["SRGB8_ALPHA8"]                         = 0x8C43,
        ["SLUMINANCE_ALPHA"]                     = 0x8C44,
        ["SLUMINANCE8_ALPHA8"]                   = 0x8C45,
        ["SLUMINANCE"]                           = 0x8C46,
        ["SLUMINANCE8"]                          = 0x8C47,
        ["COMPRESSED_SRGB"]                      = 0x8C48,
        ["COMPRESSED_SRGB_ALPHA"]                = 0x8C49,
        ["COMPRESSED_SLUMINANCE"]                = 0x8C4A,
        ["COMPRESSED_SLUMINANCE_ALPHA"]          = 0x8C4B,

        -- functions
        ["ActiveTextureARB"]                       = glptr "glActiveTextureARB",
        ["ClientActiveTextureARB"]                 = glptr "glClientActiveTextureARB",
        ["MultiTexCoord1dARB"]                     = glptr "glMultiTexCoord1dARB",
        ["MultiTexCoord1dvARB"]                    = glptr "glMultiTexCoord1dvARB",
        ["MultiTexCoord1fARB"]                     = glptr "glMultiTexCoord1fARB",
        ["MultiTexCoord1fvARB"]                    = glptr "glMultiTexCoord1fvARB",
        ["MultiTexCoord1iARB"]                     = glptr "glMultiTexCoord1iARB",
        ["MultiTexCoord1ivARB"]                    = glptr "glMultiTexCoord1ivARB",
        ["MultiTexCoord1sARB"]                     = glptr "glMultiTexCoord1sARB",
        ["MultiTexCoord1svARB"]                    = glptr "glMultiTexCoord1svARB",
        ["MultiTexCoord2dARB"]                     = glptr "glMultiTexCoord2dARB",
        ["MultiTexCoord2dvARB"]                    = glptr "glMultiTexCoord2dvARB",
        ["MultiTexCoord2fARB"]                     = glptr "glMultiTexCoord2fARB",
        ["MultiTexCoord2fvARB"]                    = glptr "glMultiTexCoord2fvARB",
        ["MultiTexCoord2iARB"]                     = glptr "glMultiTexCoord2iARB",
        ["MultiTexCoord2ivARB"]                    = glptr "glMultiTexCoord2ivARB",
        ["MultiTexCoord2sARB"]                     = glptr "glMultiTexCoord2sARB",
        ["MultiTexCoord2svARB"]                    = glptr "glMultiTexCoord2svARB",
        ["MultiTexCoord3dARB"]                     = glptr "glMultiTexCoord3dARB",
        ["MultiTexCoord3dvARB"]                    = glptr "glMultiTexCoord3dvARB",
        ["MultiTexCoord3fARB"]                     = glptr "glMultiTexCoord3fARB",
        ["MultiTexCoord3fvARB"]                    = glptr "glMultiTexCoord3fvARB",
        ["MultiTexCoord3iARB"]                     = glptr "glMultiTexCoord3iARB",
        ["MultiTexCoord3ivARB"]                    = glptr "glMultiTexCoord3ivARB",
        ["MultiTexCoord3sARB"]                     = glptr "glMultiTexCoord3sARB",
        ["MultiTexCoord3svARB"]                    = glptr "glMultiTexCoord3svARB",
        ["MultiTexCoord4dARB"]                     = glptr "glMultiTexCoord4dARB",
        ["MultiTexCoord4dvARB"]                    = glptr "glMultiTexCoord4dvARB",
        ["MultiTexCoord4fARB"]                     = glptr "glMultiTexCoord4fARB",
        ["MultiTexCoord4fvARB"]                    = glptr "glMultiTexCoord4fvARB",
        ["MultiTexCoord4iARB"]                     = glptr "glMultiTexCoord4iARB",
        ["MultiTexCoord4ivARB"]                    = glptr "glMultiTexCoord4ivARB",
        ["MultiTexCoord4sARB"]                     = glptr "glMultiTexCoord4sARB",
        ["MultiTexCoord4svARB"]                    = glptr "glMultiTexCoord4svARB",
        ["LoadTransposeMatrixfARB"]                = glptr "glLoadTransposeMatrixfARB",
        ["LoadTransposeMatrixdARB"]                = glptr "glLoadTransposeMatrixdARB",
        ["MultTransposeMatrixfARB"]                = glptr "glMultTransposeMatrixfARB",
        ["MultTransposeMatrixdARB"]                = glptr "glMultTransposeMatrixdARB",
        ["SampleCoverageARB"]                      = glptr "glSampleCoverageARB",
        ["SamplePassARB"]                          = glptr "glSamplePassARB",
        ["CompressedTexImage3DARB"]                = glptr "glCompressedTexImage3DARB",
        ["CompressedTexImage2DARB"]                = glptr "glCompressedTexImage2DARB",
        ["CompressedTexImage1DARB"]                = glptr "glCompressedTexImage1DARB",
        ["CompressedTexSubImage3DARB"]             = glptr "glCompressedTexSubImage3DARB",
        ["CompressedTexSubImage2DARB"]             = glptr "glCompressedTexSubImage2DARB",
        ["CompressedTexSubImage1DARB"]             = glptr "glCompressedTexSubImage1DARB",
        ["GetCompressedTexImageARB"]               = glptr "glGetCompressedTexImageARB",
        ["WeightbvARB"]                            = glptr "glWeightbvARB",
        ["WeightsvARB"]                            = glptr "glWeightsvARB",
        ["WeightivARB"]                            = glptr "glWeightivARB",
        ["WeightfvARB"]                            = glptr "glWeightfvARB",
        ["WeightdvARB"]                            = glptr "glWeightdvARB",
        ["WeightubvARB"]                           = glptr "glWeightubvARB",
        ["WeightusvARB"]                           = glptr "glWeightusvARB",
        ["WeightuivARB"]                           = glptr "glWeightuivARB",
        ["WeightPointerARB"]                       = glptr "glWeightPointerARB",
        ["VertexBlendARB"]                         = glptr "glVertexBlendARB",
        ["WindowPos2dARB"]                         = glptr "glWindowPos2dARB",
        ["WindowPos2dvARB"]                        = glptr "glWindowPos2dvARB",
        ["WindowPos2fARB"]                         = glptr "glWindowPos2fARB",
        ["WindowPos2fvARB"]                        = glptr "glWindowPos2fvARB",
        ["WindowPos2iARB"]                         = glptr "glWindowPos2iARB",
        ["WindowPos2ivARB"]                        = glptr "glWindowPos2ivARB",
        ["WindowPos2sARB"]                         = glptr "glWindowPos2sARB",
        ["WindowPos2svARB"]                        = glptr "glWindowPos2svARB",
        ["WindowPos3dARB"]                         = glptr "glWindowPos3dARB",
        ["WindowPos3dvARB"]                        = glptr "glWindowPos3dvARB",
        ["WindowPos3fARB"]                         = glptr "glWindowPos3fARB",
        ["WindowPos3fvARB"]                        = glptr "glWindowPos3fvARB",
        ["WindowPos3iARB"]                         = glptr "glWindowPos3iARB",
        ["WindowPos3ivARB"]                        = glptr "glWindowPos3ivARB",
        ["WindowPos3sARB"]                         = glptr "glWindowPos3sARB",
        ["WindowPos3svARB"]                        = glptr "glWindowPos3svARB",
        ["GenQueriesARB"]                          = glptr "glGenQueriesARB",
        ["DeleteQueriesARB"]                       = glptr "glDeleteQueriesARB",
        ["IsQueryARB"]                             = glptr "glIsQueryARB",
        ["BeginQueryARB"]                          = glptr "glBeginQueryARB",
        ["EndQueryARB"]                            = glptr "glEndQueryARB",
        ["GetQueryivARB"]                          = glptr "glGetQueryivARB",
        ["GetQueryObjectivARB"]                    = glptr "glGetQueryObjectivARB",
        ["GetQueryObjectuivARB"]                   = glptr "glGetQueryObjectuivARB",
        ["PointParameterfARB"]                     = glptr "glPointParameterfARB",
        ["PointParameterfvARB"]                    = glptr "glPointParameterfvARB",
        ["BindProgramARB"]                         = glptr "glBindProgramARB",
        ["DeleteProgramsARB"]                      = glptr "glDeleteProgramsARB",
        ["GenProgramsARB"]                         = glptr "glGenProgramsARB",
        ["IsProgramARB"]                           = glptr "glIsProgramARB",
        ["ProgramEnvParameter4dARB"]               = glptr "glProgramEnvParameter4dARB",
        ["ProgramEnvParameter4dvARB"]              = glptr "glProgramEnvParameter4dvARB",
        ["ProgramEnvParameter4fARB"]               = glptr "glProgramEnvParameter4fARB",
        ["ProgramEnvParameter4fvARB"]              = glptr "glProgramEnvParameter4fvARB",
        ["ProgramLocalParameter4dARB"]             = glptr "glProgramLocalParameter4dARB",
        ["ProgramLocalParameter4dvARB"]            = glptr "glProgramLocalParameter4dvARB",
        ["ProgramLocalParameter4fARB"]             = glptr "glProgramLocalParameter4fARB",
        ["ProgramLocalParameter4fvARB"]            = glptr "glProgramLocalParameter4fvARB",
        ["GetProgramEnvParameterdvARB"]            = glptr "glGetProgramEnvParameterdvARB",
        ["GetProgramEnvParameterfvARB"]            = glptr "glGetProgramEnvParameterfvARB",
        ["ProgramEnvParameters4fvEXT"]             = glptr "glProgramEnvParameters4fvEXT",
        ["ProgramLocalParameters4fvEXT"]           = glptr "glProgramLocalParameters4fvEXT",
        ["GetProgramLocalParameterdvARB"]          = glptr "glGetProgramLocalParameterdvARB",
        ["GetProgramLocalParameterfvARB"]          = glptr "glGetProgramLocalParameterfvARB",
        ["ProgramStringARB"]                       = glptr "glProgramStringARB",
        ["GetProgramStringARB"]                    = glptr "glGetProgramStringARB",
        ["GetProgramivARB"]                        = glptr "glGetProgramivARB",
        ["VertexAttrib1dARB"]                      = glptr "glVertexAttrib1dARB",
        ["VertexAttrib1dvARB"]                     = glptr "glVertexAttrib1dvARB",
        ["VertexAttrib1fARB"]                      = glptr "glVertexAttrib1fARB",
        ["VertexAttrib1fvARB"]                     = glptr "glVertexAttrib1fvARB",
        ["VertexAttrib1sARB"]                      = glptr "glVertexAttrib1sARB",
        ["VertexAttrib1svARB"]                     = glptr "glVertexAttrib1svARB",
        ["VertexAttrib2dARB"]                      = glptr "glVertexAttrib2dARB",
        ["VertexAttrib2dvARB"]                     = glptr "glVertexAttrib2dvARB",
        ["VertexAttrib2fARB"]                      = glptr "glVertexAttrib2fARB",
        ["VertexAttrib2fvARB"]                     = glptr "glVertexAttrib2fvARB",
        ["VertexAttrib2sARB"]                      = glptr "glVertexAttrib2sARB",
        ["VertexAttrib2svARB"]                     = glptr "glVertexAttrib2svARB",
        ["VertexAttrib3dARB"]                      = glptr "glVertexAttrib3dARB",
        ["VertexAttrib3dvARB"]                     = glptr "glVertexAttrib3dvARB",
        ["VertexAttrib3fARB"]                      = glptr "glVertexAttrib3fARB",
        ["VertexAttrib3fvARB"]                     = glptr "glVertexAttrib3fvARB",
        ["VertexAttrib3sARB"]                      = glptr "glVertexAttrib3sARB",
        ["VertexAttrib3svARB"]                     = glptr "glVertexAttrib3svARB",
        ["VertexAttrib4NbvARB"]                    = glptr "glVertexAttrib4NbvARB",
        ["VertexAttrib4NivARB"]                    = glptr "glVertexAttrib4NivARB",
        ["VertexAttrib4NsvARB"]                    = glptr "glVertexAttrib4NsvARB",
        ["VertexAttrib4NubARB"]                    = glptr "glVertexAttrib4NubARB",
        ["VertexAttrib4NubvARB"]                   = glptr "glVertexAttrib4NubvARB",
        ["VertexAttrib4NuivARB"]                   = glptr "glVertexAttrib4NuivARB",
        ["VertexAttrib4NusvARB"]                   = glptr "glVertexAttrib4NusvARB",
        ["VertexAttrib4bvARB"]                     = glptr "glVertexAttrib4bvARB",
        ["VertexAttrib4dARB"]                      = glptr "glVertexAttrib4dARB",
        ["VertexAttrib4dvARB"]                     = glptr "glVertexAttrib4dvARB",
        ["VertexAttrib4fARB"]                      = glptr "glVertexAttrib4fARB",
        ["VertexAttrib4fvARB"]                     = glptr "glVertexAttrib4fvARB",
        ["VertexAttrib4ivARB"]                     = glptr "glVertexAttrib4ivARB",
        ["VertexAttrib4sARB"]                      = glptr "glVertexAttrib4sARB",
        ["VertexAttrib4svARB"]                     = glptr "glVertexAttrib4svARB",
        ["VertexAttrib4ubvARB"]                    = glptr "glVertexAttrib4ubvARB",
        ["VertexAttrib4uivARB"]                    = glptr "glVertexAttrib4uivARB",
        ["VertexAttrib4usvARB"]                    = glptr "glVertexAttrib4usvARB",
        ["VertexAttribPointerARB"]                 = glptr "glVertexAttribPointerARB",
        ["DisableVertexAttribArrayARB"]            = glptr "glDisableVertexAttribArrayARB",
        ["EnableVertexAttribArrayARB"]             = glptr "glEnableVertexAttribArrayARB",
        ["GetVertexAttribPointervARB"]             = glptr "glGetVertexAttribPointervARB",
        ["GetVertexAttribdvARB"]                   = glptr "glGetVertexAttribdvARB",
        ["GetVertexAttribfvARB"]                   = glptr "glGetVertexAttribfvARB",
        ["GetVertexAttribivARB"]                   = glptr "glGetVertexAttribivARB",
        ["DeleteObjectARB"]                        = glptr "glDeleteObjectARB",
        ["GetHandleARB"]                           = glptr "glGetHandleARB",
        ["DetachObjectARB"]                        = glptr "glDetachObjectARB",
        ["CreateShaderObjectARB"]                  = glptr "glCreateShaderObjectARB",
        ["ShaderSourceARB"]                        = glptr "glShaderSourceARB",
        ["CompileShaderARB"]                       = glptr "glCompileShaderARB",
        ["CreateProgramObjectARB"]                 = glptr "glCreateProgramObjectARB",
        ["AttachObjectARB"]                        = glptr "glAttachObjectARB",
        ["LinkProgramARB"]                         = glptr "glLinkProgramARB",
        ["UseProgramObjectARB"]                    = glptr "glUseProgramObjectARB",
        ["ValidateProgramARB"]                     = glptr "glValidateProgramARB",
        ["Uniform1fARB"]                           = glptr "glUniform1fARB",
        ["Uniform2fARB"]                           = glptr "glUniform2fARB",
        ["Uniform3fARB"]                           = glptr "glUniform3fARB",
        ["Uniform4fARB"]                           = glptr "glUniform4fARB",
        ["Uniform1iARB"]                           = glptr "glUniform1iARB",
        ["Uniform2iARB"]                           = glptr "glUniform2iARB",
        ["Uniform3iARB"]                           = glptr "glUniform3iARB",
        ["Uniform4iARB"]                           = glptr "glUniform4iARB",
        ["Uniform1fvARB"]                          = glptr "glUniform1fvARB",
        ["Uniform2fvARB"]                          = glptr "glUniform2fvARB",
        ["Uniform3fvARB"]                          = glptr "glUniform3fvARB",
        ["Uniform4fvARB"]                          = glptr "glUniform4fvARB",
        ["Uniform1ivARB"]                          = glptr "glUniform1ivARB",
        ["Uniform2ivARB"]                          = glptr "glUniform2ivARB",
        ["Uniform3ivARB"]                          = glptr "glUniform3ivARB",
        ["Uniform4ivARB"]                          = glptr "glUniform4ivARB",
        ["UniformMatrix2fvARB"]                    = glptr "glUniformMatrix2fvARB",
        ["UniformMatrix3fvARB"]                    = glptr "glUniformMatrix3fvARB",
        ["UniformMatrix4fvARB"]                    = glptr "glUniformMatrix4fvARB",
        ["GetObjectParameterfvARB"]                = glptr "glGetObjectParameterfvARB",
        ["GetObjectParameterivARB"]                = glptr "glGetObjectParameterivARB",
        ["GetInfoLogARB"]                          = glptr "glGetInfoLogARB",
        ["GetAttachedObjectsARB"]                  = glptr "glGetAttachedObjectsARB",
        ["GetUniformLocationARB"]                  = glptr "glGetUniformLocationARB",
        ["GetActiveUniformARB"]                    = glptr "glGetActiveUniformARB",
        ["GetUniformfvARB"]                        = glptr "glGetUniformfvARB",
        ["GetUniformivARB"]                        = glptr "glGetUniformivARB",
        ["GetShaderSourceARB"]                     = glptr "glGetShaderSourceARB",
        ["BindAttribLocationARB"]                  = glptr "glBindAttribLocationARB",
        ["GetActiveAttribARB"]                     = glptr "glGetActiveAttribARB",
        ["GetAttribLocationARB"]                   = glptr "glGetAttribLocationARB",
        ["BindBufferARB"]                          = glptr "glBindBufferARB",
        ["DeleteBuffersARB"]                       = glptr "glDeleteBuffersARB",
        ["GenBuffersARB"]                          = glptr "glGenBuffersARB",
        ["IsBufferARB"]                            = glptr "glIsBufferARB",
        ["BufferDataARB"]                          = glptr "glBufferDataARB",
        ["BufferSubDataARB"]                       = glptr "glBufferSubDataARB",
        ["GetBufferSubDataARB"]                    = glptr "glGetBufferSubDataARB",
        ["MapBufferARB"]                           = glptr "glMapBufferARB",
        ["UnmapBufferARB"]                         = glptr "glUnmapBufferARB",
        ["GetBufferParameterivARB"]                = glptr "glGetBufferParameterivARB",
        ["GetBufferPointervARB"]                   = glptr "glGetBufferPointervARB",
        ["DrawBuffersARB"]                         = glptr "glDrawBuffersARB",
        ["ClampColorARB"]                          = glptr "glClampColorARB",
        ["DrawArraysInstancedARB"]                 = glptr "glDrawArraysInstancedARB",
        ["DrawElementsInstancedARB"]               = glptr "glDrawElementsInstancedARB",
        ["VertexAttribDivisorARB"]                 = glptr "glVertexAttribDivisorARB",
        ["GetUniformIndices"]                      = glptr "glGetUniformIndices",
        ["GetActiveUniformsiv"]                    = glptr "glGetActiveUniformsiv",
        ["GetActiveUniformName"]                   = glptr "glGetActiveUniformName",
        ["GetUniformBlockIndex"]                   = glptr "glGetUniformBlockIndex",
        ["GetActiveUniformBlockiv"]                = glptr "glGetActiveUniformBlockiv",
        ["GetActiveUniformBlockName"]              = glptr "glGetActiveUniformBlockName",
        ["BindBufferRange"]                        = glptr "glBindBufferRange",
        ["BindBufferBase"]                         = glptr "glBindBufferBase",
        ["GetIntegeri_v"]                          = glptr "glGetIntegeri_v",
        ["UniformBlockBinding"]                    = glptr "glUniformBlockBinding",
        ["BlendColorEXT"]                          = glptr "glBlendColorEXT",
        ["BlendEquationEXT"]                       = glptr "glBlendEquationEXT",
        ["LockArraysEXT"]                          = glptr "glLockArraysEXT",
        ["UnlockArraysEXT"]                        = glptr "glUnlockArraysEXT",
        ["DrawRangeElementsEXT"]                   = glptr "glDrawRangeElementsEXT",
        ["SecondaryColor3bEXT"]                    = glptr "glSecondaryColor3bEXT",
        ["SecondaryColor3bvEXT"]                   = glptr "glSecondaryColor3bvEXT",
        ["SecondaryColor3dEXT"]                    = glptr "glSecondaryColor3dEXT",
        ["SecondaryColor3dvEXT"]                   = glptr "glSecondaryColor3dvEXT",
        ["SecondaryColor3fEXT"]                    = glptr "glSecondaryColor3fEXT",
        ["SecondaryColor3fvEXT"]                   = glptr "glSecondaryColor3fvEXT",
        ["SecondaryColor3iEXT"]                    = glptr "glSecondaryColor3iEXT",
        ["SecondaryColor3ivEXT"]                   = glptr "glSecondaryColor3ivEXT",
        ["SecondaryColor3sEXT"]                    = glptr "glSecondaryColor3sEXT",
        ["SecondaryColor3svEXT"]                   = glptr "glSecondaryColor3svEXT",
        ["SecondaryColor3ubEXT"]                   = glptr "glSecondaryColor3ubEXT",
        ["SecondaryColor3ubvEXT"]                  = glptr "glSecondaryColor3ubvEXT",
        ["SecondaryColor3uiEXT"]                   = glptr "glSecondaryColor3uiEXT",
        ["SecondaryColor3uivEXT"]                  = glptr "glSecondaryColor3uivEXT",
        ["SecondaryColor3usEXT"]                   = glptr "glSecondaryColor3usEXT",
        ["SecondaryColor3usvEXT"]                  = glptr "glSecondaryColor3usvEXT",
        ["SecondaryColorPointerEXT"]               = glptr "glSecondaryColorPointerEXT",
        ["MultiDrawArraysEXT"]                     = glptr "glMultiDrawArraysEXT",
        ["MultiDrawElementsEXT"]                   = glptr "glMultiDrawElementsEXT",
        ["FogCoordfEXT"]                           = glptr "glFogCoordfEXT",
        ["FogCoordfvEXT"]                          = glptr "glFogCoordfvEXT",
        ["FogCoorddEXT"]                           = glptr "glFogCoorddEXT",
        ["FogCoorddvEXT"]                          = glptr "glFogCoorddvEXT",
        ["FogCoordPointerEXT"]                     = glptr "glFogCoordPointerEXT",
        ["BlendFuncSeparateEXT"]                   = glptr "glBlendFuncSeparateEXT",
        ["ActiveStencilFaceEXT"]                   = glptr "glActiveStencilFaceEXT",
        ["DepthBoundsEXT"]                         = glptr "glDepthBoundsEXT",
        ["BlendEquationSeparateEXT"]               = glptr "glBlendEquationSeparateEXT",
        ["IsRenderbufferEXT"]                      = glptr "glIsRenderbufferEXT",
        ["BindRenderbufferEXT"]                    = glptr "glBindRenderbufferEXT",
        ["DeleteRenderbuffersEXT"]                 = glptr "glDeleteRenderbuffersEXT",
        ["GenRenderbuffersEXT"]                    = glptr "glGenRenderbuffersEXT",
        ["RenderbufferStorageEXT"]                 = glptr "glRenderbufferStorageEXT",
        ["GetRenderbufferParameterivEXT"]          = glptr "glGetRenderbufferParameterivEXT",
        ["IsFramebufferEXT"]                       = glptr "glIsFramebufferEXT",
        ["BindFramebufferEXT"]                     = glptr "glBindFramebufferEXT",
        ["DeleteFramebuffersEXT"]                  = glptr "glDeleteFramebuffersEXT",
        ["GenFramebuffersEXT"]                     = glptr "glGenFramebuffersEXT",
        ["CheckFramebufferStatusEXT"]              = glptr "glCheckFramebufferStatusEXT",
        ["FramebufferTexture1DEXT"]                = glptr "glFramebufferTexture1DEXT",
        ["FramebufferTexture2DEXT"]                = glptr "glFramebufferTexture2DEXT",
        ["FramebufferTexture3DEXT"]                = glptr "glFramebufferTexture3DEXT",
        ["FramebufferRenderbufferEXT"]             = glptr "glFramebufferRenderbufferEXT",
        ["GetFramebufferAttachmentParameterivEXT"] = glptr "glGetFramebufferAttachmentParameterivEXT",
        ["GenerateMipmapEXT"]                      = glptr "glGenerateMipmapEXT",
        ["BlitFramebufferEXT"]                     = glptr "glBlitFramebufferEXT",
        ["RenderbufferStorageMultisampleEXT"]      = glptr "glRenderbufferStorageMultisampleEXT",
        ["ProgramParameteriEXT"]                   = glptr "glProgramParameteriEXT",
        ["FramebufferTextureEXT"]                  = glptr "glFramebufferTextureEXT",
        ["FramebufferTextureFaceEXT"]              = glptr "glFramebufferTextureFaceEXT",
        ["FramebufferTextureLayerEXT"]             = glptr "glFramebufferTextureLayerEXT",
        ["IsRenderbuffer"]                         = glptr "glIsRenderbuffer",
        ["BindRenderbuffer"]                       = glptr "glBindRenderbuffer",
        ["DeleteRenderbuffers"]                    = glptr "glDeleteRenderbuffers",
        ["GenRenderbuffers"]                       = glptr "glGenRenderbuffers",
        ["RenderbufferStorage"]                    = glptr "glRenderbufferStorage",
        ["GetRenderbufferParameteriv"]             = glptr "glGetRenderbufferParameteriv",
        ["IsFramebuffer"]                          = glptr "glIsFramebuffer",
        ["BindFramebuffer"]                        = glptr "glBindFramebuffer",
        ["DeleteFramebuffers"]                     = glptr "glDeleteFramebuffers",
        ["GenFramebuffers"]                        = glptr "glGenFramebuffers",
        ["CheckFramebufferStatus"]                 = glptr "glCheckFramebufferStatus",
        ["FramebufferTexture1D"]                   = glptr "glFramebufferTexture1D",
        ["FramebufferTexture2D"]                   = glptr "glFramebufferTexture2D",
        ["FramebufferTexture3D"]                   = glptr "glFramebufferTexture3D",
        ["FramebufferRenderbuffer"]                = glptr "glFramebufferRenderbuffer",
        ["GetFramebufferAttachmentParameteriv"]    = glptr "glGetFramebufferAttachmentParameteriv",
        ["GenerateMipmap"]                         = glptr "glGenerateMipmap",
        ["BlitFramebuffer"]                        = glptr "glBlitFramebuffer",
        ["RenderbufferStorageMultisample"]         = glptr "glRenderbufferStorageMultisample",
        ["FramebufferTextureLayer"]                = glptr "glFramebufferTextureLayer",
        ["BindBufferRangeEXT"]                     = glptr "glBindBufferRangeEXT",
        ["BindBufferOffsetEXT"]                    = glptr "glBindBufferOffsetEXT",
        ["BindBufferBaseEXT"]                      = glptr "glBindBufferBaseEXT",
        ["BeginTransformFeedbackEXT"]              = glptr "glBeginTransformFeedbackEXT",
        ["EndTransformFeedbackEXT"]                = glptr "glEndTransformFeedbackEXT",
        ["TransformFeedbackVaryingsEXT"]           = glptr "glTransformFeedbackVaryingsEXT",
        ["GetTransformFeedbackVaryingEXT"]         = glptr "glGetTransformFeedbackVaryingEXT",
        ["GetIntegerIndexedvEXT"]                  = glptr "glGetIntegerIndexedvEXT",
        ["GetBooleanIndexedvEXT"]                  = glptr "glGetBooleanIndexedvEXT",
        ["UniformBufferEXT"]                       = glptr "glUniformBufferEXT",
        ["GetUniformBufferSizeEXT"]                = glptr "glGetUniformBufferSizeEXT",
        ["GetUniformOffsetEXT"]                    = glptr "glGetUniformOffsetEXT",
        ["ClearColorIiEXT"]                        = glptr "glClearColorIiEXT",
        ["ClearColorIuiEXT"]                       = glptr "glClearColorIuiEXT",
        ["TexParameterIivEXT"]                     = glptr "glTexParameterIivEXT",
        ["TexParameterIuivEXT"]                    = glptr "glTexParameterIuivEXT",
        ["GetTexParameterIivEXT"]                  = glptr "glGetTexParameterIivEXT",
        ["GetTexParameterIuivEXT"]                 = glptr "glGetTexParameterIuivEXT",
        ["VertexAttribI1iEXT"]                     = glptr "glVertexAttribI1iEXT",
        ["VertexAttribI2iEXT"]                     = glptr "glVertexAttribI2iEXT",
        ["VertexAttribI3iEXT"]                     = glptr "glVertexAttribI3iEXT",
        ["VertexAttribI4iEXT"]                     = glptr "glVertexAttribI4iEXT",
        ["VertexAttribI1uiEXT"]                    = glptr "glVertexAttribI1uiEXT",
        ["VertexAttribI2uiEXT"]                    = glptr "glVertexAttribI2uiEXT",
        ["VertexAttribI3uiEXT"]                    = glptr "glVertexAttribI3uiEXT",
        ["VertexAttribI4uiEXT"]                    = glptr "glVertexAttribI4uiEXT",
        ["VertexAttribI1ivEXT"]                    = glptr "glVertexAttribI1ivEXT",
        ["VertexAttribI2ivEXT"]                    = glptr "glVertexAttribI2ivEXT",
        ["VertexAttribI3ivEXT"]                    = glptr "glVertexAttribI3ivEXT",
        ["VertexAttribI4ivEXT"]                    = glptr "glVertexAttribI4ivEXT",
        ["VertexAttribI1uivEXT"]                   = glptr "glVertexAttribI1uivEXT",
        ["VertexAttribI2uivEXT"]                   = glptr "glVertexAttribI2uivEXT",
        ["VertexAttribI3uivEXT"]                   = glptr "glVertexAttribI3uivEXT",
        ["VertexAttribI4uivEXT"]                   = glptr "glVertexAttribI4uivEXT",
        ["VertexAttribI4bvEXT"]                    = glptr "glVertexAttribI4bvEXT",
        ["VertexAttribI4svEXT"]                    = glptr "glVertexAttribI4svEXT",
        ["VertexAttribI4ubvEXT"]                   = glptr "glVertexAttribI4ubvEXT",
        ["VertexAttribI4usvEXT"]                   = glptr "glVertexAttribI4usvEXT",
        ["VertexAttribIPointerEXT"]                = glptr "glVertexAttribIPointerEXT",
        ["GetVertexAttribIivEXT"]                  = glptr "glGetVertexAttribIivEXT",
        ["GetVertexAttribIuivEXT"]                 = glptr "glGetVertexAttribIuivEXT",
        ["Uniform1uiEXT"]                          = glptr "glUniform1uiEXT",
        ["Uniform2uiEXT"]                          = glptr "glUniform2uiEXT",
        ["Uniform3uiEXT"]                          = glptr "glUniform3uiEXT",
        ["Uniform4uiEXT"]                          = glptr "glUniform4uiEXT",
        ["Uniform1uivEXT"]                         = glptr "glUniform1uivEXT",
        ["Uniform2uivEXT"]                         = glptr "glUniform2uivEXT",
        ["Uniform3uivEXT"]                         = glptr "glUniform3uivEXT",
        ["Uniform4uivEXT"]                         = glptr "glUniform4uivEXT",
        ["GetUniformuivEXT"]                       = glptr "glGetUniformuivEXT",
        ["BindFragDataLocationEXT"]                = glptr "glBindFragDataLocationEXT",
        ["GetFragDataLocationEXT"]                 = glptr "glGetFragDataLocationEXT",
        ["ColorMaskIndexedEXT"]                    = glptr "glColorMaskIndexedEXT",
        ["EnableIndexedEXT"]                       = glptr "glEnableIndexedEXT",
        ["DisableIndexedEXT"]                      = glptr "glDisableIndexedEXT",
        ["IsEnabledIndexedEXT"]                    = glptr "glIsEnabledIndexedEXT",
        ["ProvokingVertexEXT"]                     = glptr "glProvokingVertexEXT",
        ["TextureRangeAPPLE"]                      = glptr "glTextureRangeAPPLE",
        ["GetTexParameterPointervAPPLE"]           = glptr "glGetTexParameterPointervAPPLE",
        ["VertexArrayRangeAPPLE"]                  = glptr "glVertexArrayRangeAPPLE",
        ["FlushVertexArrayRangeAPPLE"]             = glptr "glFlushVertexArrayRangeAPPLE",
        ["VertexArrayParameteriAPPLE"]             = glptr "glVertexArrayParameteriAPPLE",
        ["BindVertexArrayAPPLE"]                   = glptr "glBindVertexArrayAPPLE",
        ["DeleteVertexArraysAPPLE"]                = glptr "glDeleteVertexArraysAPPLE",
        ["GenVertexArraysAPPLE"]                   = glptr "glGenVertexArraysAPPLE",
        ["IsVertexArrayAPPLE"]                     = glptr "glIsVertexArrayAPPLE",
        ["GenFencesAPPLE"]                         = glptr "glGenFencesAPPLE",
        ["DeleteFencesAPPLE"]                      = glptr "glDeleteFencesAPPLE",
        ["SetFenceAPPLE"]                          = glptr "glSetFenceAPPLE",
        ["IsFenceAPPLE"]                           = glptr "glIsFenceAPPLE",
        ["TestFenceAPPLE"]                         = glptr "glTestFenceAPPLE",
        ["FinishFenceAPPLE"]                       = glptr "glFinishFenceAPPLE",
        ["TestObjectAPPLE"]                        = glptr "glTestObjectAPPLE",
        ["FinishObjectAPPLE"]                      = glptr "glFinishObjectAPPLE",
        ["ElementPointerAPPLE"]                    = glptr "glElementPointerAPPLE",
        ["DrawElementArrayAPPLE"]                  = glptr "glDrawElementArrayAPPLE",
        ["DrawRangeElementArrayAPPLE"]             = glptr "glDrawRangeElementArrayAPPLE",
        ["MultiDrawElementArrayAPPLE"]             = glptr "glMultiDrawElementArrayAPPLE",
        ["MultiDrawRangeElementArrayAPPLE"]        = glptr "glMultiDrawRangeElementArrayAPPLE",
        ["FlushRenderAPPLE"]                       = glptr "glFlushRenderAPPLE",
        ["FinishRenderAPPLE"]                      = glptr "glFinishRenderAPPLE",
        ["SwapAPPLE"]                              = glptr "glSwapAPPLE",
        ["EnableVertexAttribAPPLE"]                = glptr "glEnableVertexAttribAPPLE",
        ["DisableVertexAttribAPPLE"]               = glptr "glDisableVertexAttribAPPLE",
        ["IsVertexAttribEnabledAPPLE"]             = glptr "glIsVertexAttribEnabledAPPLE",
        ["MapVertexAttrib1dAPPLE"]                 = glptr "glMapVertexAttrib1dAPPLE",
        ["MapVertexAttrib1fAPPLE"]                 = glptr "glMapVertexAttrib1fAPPLE",
        ["MapVertexAttrib2dAPPLE"]                 = glptr "glMapVertexAttrib2dAPPLE",
        ["MapVertexAttrib2fAPPLE"]                 = glptr "glMapVertexAttrib2fAPPLE",
        ["BufferParameteriAPPLE"]                  = glptr "glBufferParameteriAPPLE",
        ["FlushMappedBufferRangeAPPLE"]            = glptr "glFlushMappedBufferRangeAPPLE",
        ["ObjectPurgeableAPPLE"]                   = glptr "glObjectPurgeableAPPLE",
        ["ObjectUnpurgeableAPPLE"]                 = glptr "glObjectUnpurgeableAPPLE",
        ["GetObjectParameterivAPPLE"]              = glptr "glGetObjectParameterivAPPLE",
        ["PNTrianglesiATI"]                        = glptr "glPNTrianglesiATI",
        ["PNTrianglesfATI"]                        = glptr "glPNTrianglesfATI",
        ["BlendEquationSeparateATI"]               = glptr "glBlendEquationSeparateATI",
        ["StencilOpSeparateATI"]                   = glptr "glStencilOpSeparateATI",
        ["StencilFuncSeparateATI"]                 = glptr "glStencilFuncSeparateATI",
        ["PNTrianglesiATIX"]                       = glptr "glPNTrianglesiATIX",
        ["PNTrianglesfATIX"]                       = glptr "glPNTrianglesfATIX",
        ["PointParameteriNV"]                      = glptr "glPointParameteriNV",
        ["PointParameterivNV"]                     = glptr "glPointParameterivNV",
        ["BeginConditionalRenderNV"]               = glptr "glBeginConditionalRenderNV",
        ["EndConditionalRenderNV"]                 = glptr "glEndConditionalRenderNV",
        ["Accum"]                                  = glptr "glAccum",
        ["AlphaFunc"]                              = glptr "glAlphaFunc",
        ["AreTexturesResident"]                    = glptr "glAreTexturesResident",
        ["ArrayElement"]                           = glptr "glArrayElement",
        ["Begin"]                                  = glptr "glBegin",
        ["BindTexture"]                            = glptr "glBindTexture",
        ["Bitmap"]                                 = glptr "glBitmap",
        ["BlendColor"]                             = glptr "glBlendColor",
        ["BlendEquation"]                          = glptr "glBlendEquation",
        ["BlendEquationSeparate"]                  = glptr "glBlendEquationSeparate",
        ["BlendFunc"]                              = glptr "glBlendFunc",
        ["CallList"]                               = glptr "glCallList",
        ["CallLists"]                              = glptr "glCallLists",
        ["Clear"]                                  = glptr "glClear",
        ["ClearAccum"]                             = glptr "glClearAccum",
        ["ClearColor"]                             = glptr "glClearColor",
        ["ClearDepth"]                             = glptr "glClearDepth",
        ["ClearIndex"]                             = glptr "glClearIndex",
        ["ClearStencil"]                           = glptr "glClearStencil",
        ["ClipPlane"]                              = glptr "glClipPlane",
        ["Color3b"]                                = glptr "glColor3b",
        ["Color3bv"]                               = glptr "glColor3bv",
        ["Color3d"]                                = glptr "glColor3d",
        ["Color3dv"]                               = glptr "glColor3dv",
        ["Color3f"]                                = glptr "glColor3f",
        ["Color3fv"]                               = glptr "glColor3fv",
        ["Color3i"]                                = glptr "glColor3i",
        ["Color3iv"]                               = glptr "glColor3iv",
        ["Color3s"]                                = glptr "glColor3s",
        ["Color3sv"]                               = glptr "glColor3sv",
        ["Color3ub"]                               = glptr "glColor3ub",
        ["Color3ubv"]                              = glptr "glColor3ubv",
        ["Color3ui"]                               = glptr "glColor3ui",
        ["Color3uiv"]                              = glptr "glColor3uiv",
        ["Color3us"]                               = glptr "glColor3us",
        ["Color3usv"]                              = glptr "glColor3usv",
        ["Color4b"]                                = glptr "glColor4b",
        ["Color4bv"]                               = glptr "glColor4bv",
        ["Color4d"]                                = glptr "glColor4d",
        ["Color4dv"]                               = glptr "glColor4dv",
        ["Color4f"]                                = glptr "glColor4f",
        ["Color4fv"]                               = glptr "glColor4fv",
        ["Color4i"]                                = glptr "glColor4i",
        ["Color4iv"]                               = glptr "glColor4iv",
        ["Color4s"]                                = glptr "glColor4s",
        ["Color4sv"]                               = glptr "glColor4sv",
        ["Color4ub"]                               = glptr "glColor4ub",
        ["Color4ubv"]                              = glptr "glColor4ubv",
        ["Color4ui"]                               = glptr "glColor4ui",
        ["Color4uiv"]                              = glptr "glColor4uiv",
        ["Color4us"]                               = glptr "glColor4us",
        ["Color4usv"]                              = glptr "glColor4usv",
        ["ColorMask"]                              = glptr "glColorMask",
        ["ColorMaterial"]                          = glptr "glColorMaterial",
        ["ColorPointer"]                           = glptr "glColorPointer",
        ["ColorSubTable"]                          = glptr "glColorSubTable",
        ["ColorTable"]                             = glptr "glColorTable",
        ["ColorTableParameterfv"]                  = glptr "glColorTableParameterfv",
        ["ColorTableParameteriv"]                  = glptr "glColorTableParameteriv",
        ["ConvolutionFilter1D"]                    = glptr "glConvolutionFilter1D",
        ["ConvolutionFilter2D"]                    = glptr "glConvolutionFilter2D",
        ["ConvolutionParameterf"]                  = glptr "glConvolutionParameterf",
        ["ConvolutionParameterfv"]                 = glptr "glConvolutionParameterfv",
        ["ConvolutionParameteri"]                  = glptr "glConvolutionParameteri",
        ["ConvolutionParameteriv"]                 = glptr "glConvolutionParameteriv",
        ["CopyColorSubTable"]                      = glptr "glCopyColorSubTable",
        ["CopyColorTable"]                         = glptr "glCopyColorTable",
        ["CopyConvolutionFilter1D"]                = glptr "glCopyConvolutionFilter1D",
        ["CopyConvolutionFilter2D"]                = glptr "glCopyConvolutionFilter2D",
        ["CopyPixels"]                             = glptr "glCopyPixels",
        ["CopyTexImage1D"]                         = glptr "glCopyTexImage1D",
        ["CopyTexImage2D"]                         = glptr "glCopyTexImage2D",
        ["CopyTexSubImage1D"]                      = glptr "glCopyTexSubImage1D",
        ["CopyTexSubImage2D"]                      = glptr "glCopyTexSubImage2D",
        ["CopyTexSubImage3D"]                      = glptr "glCopyTexSubImage3D",
        ["CullFace"]                               = glptr "glCullFace",
        ["DeleteLists"]                            = glptr "glDeleteLists",
        ["DeleteTextures"]                         = glptr "glDeleteTextures",
        ["DepthFunc"]                              = glptr "glDepthFunc",
        ["DepthMask"]                              = glptr "glDepthMask",
        ["DepthRange"]                             = glptr "glDepthRange",
        ["Disable"]                                = glptr "glDisable",
        ["DisableClientState"]                     = glptr "glDisableClientState",
        ["DrawArrays"]                             = glptr "glDrawArrays",
        ["DrawBuffer"]                             = glptr "glDrawBuffer",
        ["DrawElements"]                           = glptr "glDrawElements",
        ["DrawPixels"]                             = glptr "glDrawPixels",
        ["DrawRangeElements"]                      = glptr "glDrawRangeElements",
        ["EdgeFlag"]                               = glptr "glEdgeFlag",
        ["EdgeFlagPointer"]                        = glptr "glEdgeFlagPointer",
        ["EdgeFlagv"]                              = glptr "glEdgeFlagv",
        ["Enable"]                                 = glptr "glEnable",
        ["EnableClientState"]                      = glptr "glEnableClientState",
        ["End"]                                    = glptr "glEnd",
        ["EndList"]                                = glptr "glEndList",
        ["EvalCoord1d"]                            = glptr "glEvalCoord1d",
        ["EvalCoord1dv"]                           = glptr "glEvalCoord1dv",
        ["EvalCoord1f"]                            = glptr "glEvalCoord1f",
        ["EvalCoord1fv"]                           = glptr "glEvalCoord1fv",
        ["EvalCoord2d"]                            = glptr "glEvalCoord2d",
        ["EvalCoord2dv"]                           = glptr "glEvalCoord2dv",
        ["EvalCoord2f"]                            = glptr "glEvalCoord2f",
        ["EvalCoord2fv"]                           = glptr "glEvalCoord2fv",
        ["EvalMesh1"]                              = glptr "glEvalMesh1",
        ["EvalMesh2"]                              = glptr "glEvalMesh2",
        ["EvalPoint1"]                             = glptr "glEvalPoint1",
        ["EvalPoint2"]                             = glptr "glEvalPoint2",
        ["FeedbackBuffer"]                         = glptr "glFeedbackBuffer",
        ["Finish"]                                 = glptr "glFinish",
        ["Flush"]                                  = glptr "glFlush",
        ["Fogf"]                                   = glptr "glFogf",
        ["Fogfv"]                                  = glptr "glFogfv",
        ["Fogi"]                                   = glptr "glFogi",
        ["Fogiv"]                                  = glptr "glFogiv",
        ["FrontFace"]                              = glptr "glFrontFace",
        ["Frustum"]                                = glptr "glFrustum",
        ["GenLists"]                               = glptr "glGenLists",
        ["GenTextures"]                            = glptr "glGenTextures",
        ["GetBooleanv"]                            = glptr "glGetBooleanv",
        ["GetClipPlane"]                           = glptr "glGetClipPlane",
        ["GetColorTable"]                          = glptr "glGetColorTable",
        ["GetColorTableParameterfv"]               = glptr "glGetColorTableParameterfv",
        ["GetColorTableParameteriv"]               = glptr "glGetColorTableParameteriv",
        ["GetConvolutionFilter"]                   = glptr "glGetConvolutionFilter",
        ["GetConvolutionParameterfv"]              = glptr "glGetConvolutionParameterfv",
        ["GetConvolutionParameteriv"]              = glptr "glGetConvolutionParameteriv",
        ["GetDoublev"]                             = glptr "glGetDoublev",
        ["GetError"]                               = glptr "glGetError",
        ["GetFloatv"]                              = glptr "glGetFloatv",
        ["GetHistogram"]                           = glptr "glGetHistogram",
        ["GetHistogramParameterfv"]                = glptr "glGetHistogramParameterfv",
        ["GetHistogramParameteriv"]                = glptr "glGetHistogramParameteriv",
        ["GetIntegerv"]                            = glptr "glGetIntegerv",
        ["GetLightfv"]                             = glptr "glGetLightfv",
        ["GetLightiv"]                             = glptr "glGetLightiv",
        ["GetMapdv"]                               = glptr "glGetMapdv",
        ["GetMapfv"]                               = glptr "glGetMapfv",
        ["GetMapiv"]                               = glptr "glGetMapiv",
        ["GetMaterialfv"]                          = glptr "glGetMaterialfv",
        ["GetMaterialiv"]                          = glptr "glGetMaterialiv",
        ["GetMinmax"]                              = glptr "glGetMinmax",
        ["GetMinmaxParameterfv"]                   = glptr "glGetMinmaxParameterfv",
        ["GetMinmaxParameteriv"]                   = glptr "glGetMinmaxParameteriv",
        ["GetPixelMapfv"]                          = glptr "glGetPixelMapfv",
        ["GetPixelMapuiv"]                         = glptr "glGetPixelMapuiv",
        ["GetPixelMapusv"]                         = glptr "glGetPixelMapusv",
        ["GetPointerv"]                            = glptr "glGetPointerv",
        ["GetPolygonStipple"]                      = glptr "glGetPolygonStipple",
        ["GetSeparableFilter"]                     = glptr "glGetSeparableFilter",
        ["GetString"]                              = glptr "glGetString",
        ["GetTexEnvfv"]                            = glptr "glGetTexEnvfv",
        ["GetTexEnviv"]                            = glptr "glGetTexEnviv",
        ["GetTexGendv"]                            = glptr "glGetTexGendv",
        ["GetTexGenfv"]                            = glptr "glGetTexGenfv",
        ["GetTexGeniv"]                            = glptr "glGetTexGeniv",
        ["GetTexImage"]                            = glptr "glGetTexImage",
        ["GetTexLevelParameterfv"]                 = glptr "glGetTexLevelParameterfv",
        ["GetTexLevelParameteriv"]                 = glptr "glGetTexLevelParameteriv",
        ["GetTexParameterfv"]                      = glptr "glGetTexParameterfv",
        ["GetTexParameteriv"]                      = glptr "glGetTexParameteriv",
        ["Hint"]                                   = glptr "glHint",
        ["Histogram"]                              = glptr "glHistogram",
        ["IndexMask"]                              = glptr "glIndexMask",
        ["IndexPointer"]                           = glptr "glIndexPointer",
        ["Indexd"]                                 = glptr "glIndexd",
        ["Indexdv"]                                = glptr "glIndexdv",
        ["Indexf"]                                 = glptr "glIndexf",
        ["Indexfv"]                                = glptr "glIndexfv",
        ["Indexi"]                                 = glptr "glIndexi",
        ["Indexiv"]                                = glptr "glIndexiv",
        ["Indexs"]                                 = glptr "glIndexs",
        ["Indexsv"]                                = glptr "glIndexsv",
        ["Indexub"]                                = glptr "glIndexub",
        ["Indexubv"]                               = glptr "glIndexubv",
        ["InitNames"]                              = glptr "glInitNames",
        ["InterleavedArrays"]                      = glptr "glInterleavedArrays",
        ["IsEnabled"]                              = glptr "glIsEnabled",
        ["IsList"]                                 = glptr "glIsList",
        ["IsTexture"]                              = glptr "glIsTexture",
        ["LightModelf"]                            = glptr "glLightModelf",
        ["LightModelfv"]                           = glptr "glLightModelfv",
        ["LightModeli"]                            = glptr "glLightModeli",
        ["LightModeliv"]                           = glptr "glLightModeliv",
        ["Lightf"]                                 = glptr "glLightf",
        ["Lightfv"]                                = glptr "glLightfv",
        ["Lighti"]                                 = glptr "glLighti",
        ["Lightiv"]                                = glptr "glLightiv",
        ["LineStipple"]                            = glptr "glLineStipple",
        ["LineWidth"]                              = glptr "glLineWidth",
        ["ListBase"]                               = glptr "glListBase",
        ["LoadIdentity"]                           = glptr "glLoadIdentity",
        ["LoadMatrixd"]                            = glptr "glLoadMatrixd",
        ["LoadMatrixf"]                            = glptr "glLoadMatrixf",
        ["LoadName"]                               = glptr "glLoadName",
        ["LogicOp"]                                = glptr "glLogicOp",
        ["Map1d"]                                  = glptr "glMap1d",
        ["Map1f"]                                  = glptr "glMap1f",
        ["Map2d"]                                  = glptr "glMap2d",
        ["Map2f"]                                  = glptr "glMap2f",
        ["MapGrid1d"]                              = glptr "glMapGrid1d",
        ["MapGrid1f"]                              = glptr "glMapGrid1f",
        ["MapGrid2d"]                              = glptr "glMapGrid2d",
        ["MapGrid2f"]                              = glptr "glMapGrid2f",
        ["Materialf"]                              = glptr "glMaterialf",
        ["Materialfv"]                             = glptr "glMaterialfv",
        ["Materiali"]                              = glptr "glMateriali",
        ["Materialiv"]                             = glptr "glMaterialiv",
        ["MatrixMode"]                             = glptr "glMatrixMode",
        ["Minmax"]                                 = glptr "glMinmax",
        ["MultMatrixd"]                            = glptr "glMultMatrixd",
        ["MultMatrixf"]                            = glptr "glMultMatrixf",
        ["NewList"]                                = glptr "glNewList",
        ["Normal3b"]                               = glptr "glNormal3b",
        ["Normal3bv"]                              = glptr "glNormal3bv",
        ["Normal3d"]                               = glptr "glNormal3d",
        ["Normal3dv"]                              = glptr "glNormal3dv",
        ["Normal3f"]                               = glptr "glNormal3f",
        ["Normal3fv"]                              = glptr "glNormal3fv",
        ["Normal3i"]                               = glptr "glNormal3i",
        ["Normal3iv"]                              = glptr "glNormal3iv",
        ["Normal3s"]                               = glptr "glNormal3s",
        ["Normal3sv"]                              = glptr "glNormal3sv",
        ["NormalPointer"]                          = glptr "glNormalPointer",
        ["Ortho"]                                  = glptr "glOrtho",
        ["PassThrough"]                            = glptr "glPassThrough",
        ["PixelMapfv"]                             = glptr "glPixelMapfv",
        ["PixelMapuiv"]                            = glptr "glPixelMapuiv",
        ["PixelMapusv"]                            = glptr "glPixelMapusv",
        ["PixelStoref"]                            = glptr "glPixelStoref",
        ["PixelStorei"]                            = glptr "glPixelStorei",
        ["PixelTransferf"]                         = glptr "glPixelTransferf",
        ["PixelTransferi"]                         = glptr "glPixelTransferi",
        ["PixelZoom"]                              = glptr "glPixelZoom",
        ["PointSize"]                              = glptr "glPointSize",
        ["PolygonMode"]                            = glptr "glPolygonMode",
        ["PolygonOffset"]                          = glptr "glPolygonOffset",
        ["PolygonStipple"]                         = glptr "glPolygonStipple",
        ["PopAttrib"]                              = glptr "glPopAttrib",
        ["PopClientAttrib"]                        = glptr "glPopClientAttrib",
        ["PopMatrix"]                              = glptr "glPopMatrix",
        ["PopName"]                                = glptr "glPopName",
        ["PrioritizeTextures"]                     = glptr "glPrioritizeTextures",
        ["PushAttrib"]                             = glptr "glPushAttrib",
        ["PushClientAttrib"]                       = glptr "glPushClientAttrib",
        ["PushMatrix"]                             = glptr "glPushMatrix",
        ["PushName"]                               = glptr "glPushName",
        ["RasterPos2d"]                            = glptr "glRasterPos2d",
        ["RasterPos2dv"]                           = glptr "glRasterPos2dv",
        ["RasterPos2f"]                            = glptr "glRasterPos2f",
        ["RasterPos2fv"]                           = glptr "glRasterPos2fv",
        ["RasterPos2i"]                            = glptr "glRasterPos2i",
        ["RasterPos2iv"]                           = glptr "glRasterPos2iv",
        ["RasterPos2s"]                            = glptr "glRasterPos2s",
        ["RasterPos2sv"]                           = glptr "glRasterPos2sv",
        ["RasterPos3d"]                            = glptr "glRasterPos3d",
        ["RasterPos3dv"]                           = glptr "glRasterPos3dv",
        ["RasterPos3f"]                            = glptr "glRasterPos3f",
        ["RasterPos3fv"]                           = glptr "glRasterPos3fv",
        ["RasterPos3i"]                            = glptr "glRasterPos3i",
        ["RasterPos3iv"]                           = glptr "glRasterPos3iv",
        ["RasterPos3s"]                            = glptr "glRasterPos3s",
        ["RasterPos3sv"]                           = glptr "glRasterPos3sv",
        ["RasterPos4d"]                            = glptr "glRasterPos4d",
        ["RasterPos4dv"]                           = glptr "glRasterPos4dv",
        ["RasterPos4f"]                            = glptr "glRasterPos4f",
        ["RasterPos4fv"]                           = glptr "glRasterPos4fv",
        ["RasterPos4i"]                            = glptr "glRasterPos4i",
        ["RasterPos4iv"]                           = glptr "glRasterPos4iv",
        ["RasterPos4s"]                            = glptr "glRasterPos4s",
        ["RasterPos4sv"]                           = glptr "glRasterPos4sv",
        ["ReadBuffer"]                             = glptr "glReadBuffer",
        ["ReadPixels"]                             = glptr "glReadPixels",
        ["Rectd"]                                  = glptr "glRectd",
        ["Rectdv"]                                 = glptr "glRectdv",
        ["Rectf"]                                  = glptr "glRectf",
        ["Rectfv"]                                 = glptr "glRectfv",
        ["Recti"]                                  = glptr "glRecti",
        ["Rectiv"]                                 = glptr "glRectiv",
        ["Rects"]                                  = glptr "glRects",
        ["Rectsv"]                                 = glptr "glRectsv",
        ["RenderMode"]                             = glptr "glRenderMode",
        ["ResetHistogram"]                         = glptr "glResetHistogram",
        ["ResetMinmax"]                            = glptr "glResetMinmax",
        ["Rotated"]                                = glptr "glRotated",
        ["Rotatef"]                                = glptr "glRotatef",
        ["Scaled"]                                 = glptr "glScaled",
        ["Scalef"]                                 = glptr "glScalef",
        ["Scissor"]                                = glptr "glScissor",
        ["SelectBuffer"]                           = glptr "glSelectBuffer",
        ["SeparableFilter2D"]                      = glptr "glSeparableFilter2D",
        ["ShadeModel"]                             = glptr "glShadeModel",
        ["StencilFunc"]                            = glptr "glStencilFunc",
        ["StencilMask"]                            = glptr "glStencilMask",
        ["StencilOp"]                              = glptr "glStencilOp",
        ["TexCoord1d"]                             = glptr "glTexCoord1d",
        ["TexCoord1dv"]                            = glptr "glTexCoord1dv",
        ["TexCoord1f"]                             = glptr "glTexCoord1f",
        ["TexCoord1fv"]                            = glptr "glTexCoord1fv",
        ["TexCoord1i"]                             = glptr "glTexCoord1i",
        ["TexCoord1iv"]                            = glptr "glTexCoord1iv",
        ["TexCoord1s"]                             = glptr "glTexCoord1s",
        ["TexCoord1sv"]                            = glptr "glTexCoord1sv",
        ["TexCoord2d"]                             = glptr "glTexCoord2d",
        ["TexCoord2dv"]                            = glptr "glTexCoord2dv",
        ["TexCoord2f"]                             = glptr "glTexCoord2f",
        ["TexCoord2fv"]                            = glptr "glTexCoord2fv",
        ["TexCoord2i"]                             = glptr "glTexCoord2i",
        ["TexCoord2iv"]                            = glptr "glTexCoord2iv",
        ["TexCoord2s"]                             = glptr "glTexCoord2s",
        ["TexCoord2sv"]                            = glptr "glTexCoord2sv",
        ["TexCoord3d"]                             = glptr "glTexCoord3d",
        ["TexCoord3dv"]                            = glptr "glTexCoord3dv",
        ["TexCoord3f"]                             = glptr "glTexCoord3f",
        ["TexCoord3fv"]                            = glptr "glTexCoord3fv",
        ["TexCoord3i"]                             = glptr "glTexCoord3i",
        ["TexCoord3iv"]                            = glptr "glTexCoord3iv",
        ["TexCoord3s"]                             = glptr "glTexCoord3s",
        ["TexCoord3sv"]                            = glptr "glTexCoord3sv",
        ["TexCoord4d"]                             = glptr "glTexCoord4d",
        ["TexCoord4dv"]                            = glptr "glTexCoord4dv",
        ["TexCoord4f"]                             = glptr "glTexCoord4f",
        ["TexCoord4fv"]                            = glptr "glTexCoord4fv",
        ["TexCoord4i"]                             = glptr "glTexCoord4i",
        ["TexCoord4iv"]                            = glptr "glTexCoord4iv",
        ["TexCoord4s"]                             = glptr "glTexCoord4s",
        ["TexCoord4sv"]                            = glptr "glTexCoord4sv",
        ["TexCoordPointer"]                        = glptr "glTexCoordPointer",
        ["TexEnvf"]                                = glptr "glTexEnvf",
        ["TexEnvfv"]                               = glptr "glTexEnvfv",
        ["TexEnvi"]                                = glptr "glTexEnvi",
        ["TexEnviv"]                               = glptr "glTexEnviv",
        ["TexGend"]                                = glptr "glTexGend",
        ["TexGendv"]                               = glptr "glTexGendv",
        ["TexGenf"]                                = glptr "glTexGenf",
        ["TexGenfv"]                               = glptr "glTexGenfv",
        ["TexGeni"]                                = glptr "glTexGeni",
        ["TexGeniv"]                               = glptr "glTexGeniv",
        ["TexImage1D"]                             = glptr "glTexImage1D",
        ["TexImage2D"]                             = glptr "glTexImage2D",
        ["TexImage3D"]                             = glptr "glTexImage3D",
        ["TexParameterf"]                          = glptr "glTexParameterf",
        ["TexParameterfv"]                         = glptr "glTexParameterfv",
        ["TexParameteri"]                          = glptr "glTexParameteri",
        ["TexParameteriv"]                         = glptr "glTexParameteriv",
        ["TexSubImage1D"]                          = glptr "glTexSubImage1D",
        ["TexSubImage2D"]                          = glptr "glTexSubImage2D",
        ["TexSubImage3D"]                          = glptr "glTexSubImage3D",
        ["Translated"]                             = glptr "glTranslated",
        ["Translatef"]                             = glptr "glTranslatef",
        ["Vertex2d"]                               = glptr "glVertex2d",
        ["Vertex2dv"]                              = glptr "glVertex2dv",
        ["Vertex2f"]                               = glptr "glVertex2f",
        ["Vertex2fv"]                              = glptr "glVertex2fv",
        ["Vertex2i"]                               = glptr "glVertex2i",
        ["Vertex2iv"]                              = glptr "glVertex2iv",
        ["Vertex2s"]                               = glptr "glVertex2s",
        ["Vertex2sv"]                              = glptr "glVertex2sv",
        ["Vertex3d"]                               = glptr "glVertex3d",
        ["Vertex3dv"]                              = glptr "glVertex3dv",
        ["Vertex3f"]                               = glptr "glVertex3f",
        ["Vertex3fv"]                              = glptr "glVertex3fv",
        ["Vertex3i"]                               = glptr "glVertex3i",
        ["Vertex3iv"]                              = glptr "glVertex3iv",
        ["Vertex3s"]                               = glptr "glVertex3s",
        ["Vertex3sv"]                              = glptr "glVertex3sv",
        ["Vertex4d"]                               = glptr "glVertex4d",
        ["Vertex4dv"]                              = glptr "glVertex4dv",
        ["Vertex4f"]                               = glptr "glVertex4f",
        ["Vertex4fv"]                              = glptr "glVertex4fv",
        ["Vertex4i"]                               = glptr "glVertex4i",
        ["Vertex4iv"]                              = glptr "glVertex4iv",
        ["Vertex4s"]                               = glptr "glVertex4s",
        ["Vertex4sv"]                              = glptr "glVertex4sv",
        ["VertexPointer"]                          = glptr "glVertexPointer",
        ["Viewport"]                               = glptr "glViewport",
        ["SampleCoverage"]                         = glptr "glSampleCoverage",
        ["SamplePass"]                             = glptr "glSamplePass",
        ["LoadTransposeMatrixf"]                   = glptr "glLoadTransposeMatrixf",
        ["LoadTransposeMatrixd"]                   = glptr "glLoadTransposeMatrixd",
        ["MultTransposeMatrixf"]                   = glptr "glMultTransposeMatrixf",
        ["MultTransposeMatrixd"]                   = glptr "glMultTransposeMatrixd",
        ["CompressedTexImage3D"]                   = glptr "glCompressedTexImage3D",
        ["CompressedTexImage2D"]                   = glptr "glCompressedTexImage2D",
        ["CompressedTexImage1D"]                   = glptr "glCompressedTexImage1D",
        ["CompressedTexSubImage3D"]                = glptr "glCompressedTexSubImage3D",
        ["CompressedTexSubImage2D"]                = glptr "glCompressedTexSubImage2D",
        ["CompressedTexSubImage1D"]                = glptr "glCompressedTexSubImage1D",
        ["GetCompressedTexImage"]                  = glptr "glGetCompressedTexImage",
        ["ActiveTexture"]                          = glptr "glActiveTexture",
        ["ClientActiveTexture"]                    = glptr "glClientActiveTexture",
        ["MultiTexCoord1d"]                        = glptr "glMultiTexCoord1d",
        ["MultiTexCoord1dv"]                       = glptr "glMultiTexCoord1dv",
        ["MultiTexCoord1f"]                        = glptr "glMultiTexCoord1f",
        ["MultiTexCoord1fv"]                       = glptr "glMultiTexCoord1fv",
        ["MultiTexCoord1i"]                        = glptr "glMultiTexCoord1i",
        ["MultiTexCoord1iv"]                       = glptr "glMultiTexCoord1iv",
        ["MultiTexCoord1s"]                        = glptr "glMultiTexCoord1s",
        ["MultiTexCoord1sv"]                       = glptr "glMultiTexCoord1sv",
        ["MultiTexCoord2d"]                        = glptr "glMultiTexCoord2d",
        ["MultiTexCoord2dv"]                       = glptr "glMultiTexCoord2dv",
        ["MultiTexCoord2f"]                        = glptr "glMultiTexCoord2f",
        ["MultiTexCoord2fv"]                       = glptr "glMultiTexCoord2fv",
        ["MultiTexCoord2i"]                        = glptr "glMultiTexCoord2i",
        ["MultiTexCoord2iv"]                       = glptr "glMultiTexCoord2iv",
        ["MultiTexCoord2s"]                        = glptr "glMultiTexCoord2s",
        ["MultiTexCoord2sv"]                       = glptr "glMultiTexCoord2sv",
        ["MultiTexCoord3d"]                        = glptr "glMultiTexCoord3d",
        ["MultiTexCoord3dv"]                       = glptr "glMultiTexCoord3dv",
        ["MultiTexCoord3f"]                        = glptr "glMultiTexCoord3f",
        ["MultiTexCoord3fv"]                       = glptr "glMultiTexCoord3fv",
        ["MultiTexCoord3i"]                        = glptr "glMultiTexCoord3i",
        ["MultiTexCoord3iv"]                       = glptr "glMultiTexCoord3iv",
        ["MultiTexCoord3s"]                        = glptr "glMultiTexCoord3s",
        ["MultiTexCoord3sv"]                       = glptr "glMultiTexCoord3sv",
        ["MultiTexCoord4d"]                        = glptr "glMultiTexCoord4d",
        ["MultiTexCoord4dv"]                       = glptr "glMultiTexCoord4dv",
        ["MultiTexCoord4f"]                        = glptr "glMultiTexCoord4f",
        ["MultiTexCoord4fv"]                       = glptr "glMultiTexCoord4fv",
        ["MultiTexCoord4i"]                        = glptr "glMultiTexCoord4i",
        ["MultiTexCoord4iv"]                       = glptr "glMultiTexCoord4iv",
        ["MultiTexCoord4s"]                        = glptr "glMultiTexCoord4s",
        ["MultiTexCoord4sv"]                       = glptr "glMultiTexCoord4sv",
        ["FogCoordf"]                              = glptr "glFogCoordf",
        ["FogCoordfv"]                             = glptr "glFogCoordfv",
        ["FogCoordd"]                              = glptr "glFogCoordd",
        ["FogCoorddv"]                             = glptr "glFogCoorddv",
        ["FogCoordPointer"]                        = glptr "glFogCoordPointer",
        ["SecondaryColor3b"]                       = glptr "glSecondaryColor3b",
        ["SecondaryColor3bv"]                      = glptr "glSecondaryColor3bv",
        ["SecondaryColor3d"]                       = glptr "glSecondaryColor3d",
        ["SecondaryColor3dv"]                      = glptr "glSecondaryColor3dv",
        ["SecondaryColor3f"]                       = glptr "glSecondaryColor3f",
        ["SecondaryColor3fv"]                      = glptr "glSecondaryColor3fv",
        ["SecondaryColor3i"]                       = glptr "glSecondaryColor3i",
        ["SecondaryColor3iv"]                      = glptr "glSecondaryColor3iv",
        ["SecondaryColor3s"]                       = glptr "glSecondaryColor3s",
        ["SecondaryColor3sv"]                      = glptr "glSecondaryColor3sv",
        ["SecondaryColor3ub"]                      = glptr "glSecondaryColor3ub",
        ["SecondaryColor3ubv"]                     = glptr "glSecondaryColor3ubv",
        ["SecondaryColor3ui"]                      = glptr "glSecondaryColor3ui",
        ["SecondaryColor3uiv"]                     = glptr "glSecondaryColor3uiv",
        ["SecondaryColor3us"]                      = glptr "glSecondaryColor3us",
        ["SecondaryColor3usv"]                     = glptr "glSecondaryColor3usv",
        ["SecondaryColorPointer"]                  = glptr "glSecondaryColorPointer",
        ["PointParameterf"]                        = glptr "glPointParameterf",
        ["PointParameterfv"]                       = glptr "glPointParameterfv",
        ["PointParameteri"]                        = glptr "glPointParameteri",
        ["PointParameteriv"]                       = glptr "glPointParameteriv",
        ["BlendFuncSeparate"]                      = glptr "glBlendFuncSeparate",
        ["MultiDrawArrays"]                        = glptr "glMultiDrawArrays",
        ["MultiDrawElements"]                      = glptr "glMultiDrawElements",
        ["WindowPos2d"]                            = glptr "glWindowPos2d",
        ["WindowPos2dv"]                           = glptr "glWindowPos2dv",
        ["WindowPos2f"]                            = glptr "glWindowPos2f",
        ["WindowPos2fv"]                           = glptr "glWindowPos2fv",
        ["WindowPos2i"]                            = glptr "glWindowPos2i",
        ["WindowPos2iv"]                           = glptr "glWindowPos2iv",
        ["WindowPos2s"]                            = glptr "glWindowPos2s",
        ["WindowPos2sv"]                           = glptr "glWindowPos2sv",
        ["WindowPos3d"]                            = glptr "glWindowPos3d",
        ["WindowPos3dv"]                           = glptr "glWindowPos3dv",
        ["WindowPos3f"]                            = glptr "glWindowPos3f",
        ["WindowPos3fv"]                           = glptr "glWindowPos3fv",
        ["WindowPos3i"]                            = glptr "glWindowPos3i",
        ["WindowPos3iv"]                           = glptr "glWindowPos3iv",
        ["WindowPos3s"]                            = glptr "glWindowPos3s",
        ["WindowPos3sv"]                           = glptr "glWindowPos3sv",
        ["GenQueries"]                             = glptr "glGenQueries",
        ["DeleteQueries"]                          = glptr "glDeleteQueries",
        ["IsQuery"]                                = glptr "glIsQuery",
        ["BeginQuery"]                             = glptr "glBeginQuery",
        ["EndQuery"]                               = glptr "glEndQuery",
        ["GetQueryiv"]                             = glptr "glGetQueryiv",
        ["GetQueryObjectiv"]                       = glptr "glGetQueryObjectiv",
        ["GetQueryObjectuiv"]                      = glptr "glGetQueryObjectuiv",
        ["BindBuffer"]                             = glptr "glBindBuffer",
        ["DeleteBuffers"]                          = glptr "glDeleteBuffers",
        ["GenBuffers"]                             = glptr "glGenBuffers",
        ["IsBuffer"]                               = glptr "glIsBuffer",
        ["BufferData"]                             = glptr "glBufferData",
        ["BufferSubData"]                          = glptr "glBufferSubData",
        ["GetBufferSubData"]                       = glptr "glGetBufferSubData",
        ["MapBuffer"]                              = glptr "glMapBuffer",
        ["UnmapBuffer"]                            = glptr "glUnmapBuffer",
        ["GetBufferParameteriv"]                   = glptr "glGetBufferParameteriv",
        ["GetBufferPointerv"]                      = glptr "glGetBufferPointerv",
        ["DrawBuffers"]                            = glptr "glDrawBuffers",
        ["VertexAttrib1d"]                         = glptr "glVertexAttrib1d",
        ["VertexAttrib1dv"]                        = glptr "glVertexAttrib1dv",
        ["VertexAttrib1f"]                         = glptr "glVertexAttrib1f",
        ["VertexAttrib1fv"]                        = glptr "glVertexAttrib1fv",
        ["VertexAttrib1s"]                         = glptr "glVertexAttrib1s",
        ["VertexAttrib1sv"]                        = glptr "glVertexAttrib1sv",
        ["VertexAttrib2d"]                         = glptr "glVertexAttrib2d",
        ["VertexAttrib2dv"]                        = glptr "glVertexAttrib2dv",
        ["VertexAttrib2f"]                         = glptr "glVertexAttrib2f",
        ["VertexAttrib2fv"]                        = glptr "glVertexAttrib2fv",
        ["VertexAttrib2s"]                         = glptr "glVertexAttrib2s",
        ["VertexAttrib2sv"]                        = glptr "glVertexAttrib2sv",
        ["VertexAttrib3d"]                         = glptr "glVertexAttrib3d",
        ["VertexAttrib3dv"]                        = glptr "glVertexAttrib3dv",
        ["VertexAttrib3f"]                         = glptr "glVertexAttrib3f",
        ["VertexAttrib3fv"]                        = glptr "glVertexAttrib3fv",
        ["VertexAttrib3s"]                         = glptr "glVertexAttrib3s",
        ["VertexAttrib3sv"]                        = glptr "glVertexAttrib3sv",
        ["VertexAttrib4Nbv"]                       = glptr "glVertexAttrib4Nbv",
        ["VertexAttrib4Niv"]                       = glptr "glVertexAttrib4Niv",
        ["VertexAttrib4Nsv"]                       = glptr "glVertexAttrib4Nsv",
        ["VertexAttrib4Nub"]                       = glptr "glVertexAttrib4Nub",
        ["VertexAttrib4Nubv"]                      = glptr "glVertexAttrib4Nubv",
        ["VertexAttrib4Nuiv"]                      = glptr "glVertexAttrib4Nuiv",
        ["VertexAttrib4Nusv"]                      = glptr "glVertexAttrib4Nusv",
        ["VertexAttrib4bv"]                        = glptr "glVertexAttrib4bv",
        ["VertexAttrib4d"]                         = glptr "glVertexAttrib4d",
        ["VertexAttrib4dv"]                        = glptr "glVertexAttrib4dv",
        ["VertexAttrib4f"]                         = glptr "glVertexAttrib4f",
        ["VertexAttrib4fv"]                        = glptr "glVertexAttrib4fv",
        ["VertexAttrib4iv"]                        = glptr "glVertexAttrib4iv",
        ["VertexAttrib4s"]                         = glptr "glVertexAttrib4s",
        ["VertexAttrib4sv"]                        = glptr "glVertexAttrib4sv",
        ["VertexAttrib4ubv"]                       = glptr "glVertexAttrib4ubv",
        ["VertexAttrib4uiv"]                       = glptr "glVertexAttrib4uiv",
        ["VertexAttrib4usv"]                       = glptr "glVertexAttrib4usv",
        ["VertexAttribPointer"]                    = glptr "glVertexAttribPointer",
        ["EnableVertexAttribArray"]                = glptr "glEnableVertexAttribArray",
        ["DisableVertexAttribArray"]               = glptr "glDisableVertexAttribArray",
        ["GetVertexAttribdv"]                      = glptr "glGetVertexAttribdv",
        ["GetVertexAttribfv"]                      = glptr "glGetVertexAttribfv",
        ["GetVertexAttribiv"]                      = glptr "glGetVertexAttribiv",
        ["GetVertexAttribPointerv"]                = glptr "glGetVertexAttribPointerv",
        ["DeleteShader"]                           = glptr "glDeleteShader",
        ["DetachShader"]                           = glptr "glDetachShader",
        ["CreateShader"]                           = glptr "glCreateShader",
        ["ShaderSource"]                           = glptr "glShaderSource",
        ["CompileShader"]                          = glptr "glCompileShader",
        ["CreateProgram"]                          = glptr "glCreateProgram",
        ["AttachShader"]                           = glptr "glAttachShader",
        ["LinkProgram"]                            = glptr "glLinkProgram",
        ["UseProgram"]                             = glptr "glUseProgram",
        ["DeleteProgram"]                          = glptr "glDeleteProgram",
        ["ValidateProgram"]                        = glptr "glValidateProgram",
        ["Uniform1f"]                              = glptr "glUniform1f",
        ["Uniform2f"]                              = glptr "glUniform2f",
        ["Uniform3f"]                              = glptr "glUniform3f",
        ["Uniform4f"]                              = glptr "glUniform4f",
        ["Uniform1i"]                              = glptr "glUniform1i",
        ["Uniform2i"]                              = glptr "glUniform2i",
        ["Uniform3i"]                              = glptr "glUniform3i",
        ["Uniform4i"]                              = glptr "glUniform4i",
        ["Uniform1fv"]                             = glptr "glUniform1fv",
        ["Uniform2fv"]                             = glptr "glUniform2fv",
        ["Uniform3fv"]                             = glptr "glUniform3fv",
        ["Uniform4fv"]                             = glptr "glUniform4fv",
        ["Uniform1iv"]                             = glptr "glUniform1iv",
        ["Uniform2iv"]                             = glptr "glUniform2iv",
        ["Uniform3iv"]                             = glptr "glUniform3iv",
        ["Uniform4iv"]                             = glptr "glUniform4iv",
        ["UniformMatrix2fv"]                       = glptr "glUniformMatrix2fv",
        ["UniformMatrix3fv"]                       = glptr "glUniformMatrix3fv",
        ["UniformMatrix4fv"]                       = glptr "glUniformMatrix4fv",
        ["IsShader"]                               = glptr "glIsShader",
        ["IsProgram"]                              = glptr "glIsProgram",
        ["GetShaderiv"]                            = glptr "glGetShaderiv",
        ["GetProgramiv"]                           = glptr "glGetProgramiv",
        ["GetAttachedShaders"]                     = glptr "glGetAttachedShaders",
        ["GetShaderInfoLog"]                       = glptr "glGetShaderInfoLog",
        ["GetProgramInfoLog"]                      = glptr "glGetProgramInfoLog",
        ["GetUniformLocation"]                     = glptr "glGetUniformLocation",
        ["GetActiveUniform"]                       = glptr "glGetActiveUniform",
        ["GetUniformfv"]                           = glptr "glGetUniformfv",
        ["GetUniformiv"]                           = glptr "glGetUniformiv",
        ["GetShaderSource"]                        = glptr "glGetShaderSource",
        ["BindAttribLocation"]                     = glptr "glBindAttribLocation",
        ["GetActiveAttrib"]                        = glptr "glGetActiveAttrib",
        ["GetAttribLocation"]                      = glptr "glGetAttribLocation",
        ["StencilFuncSeparate"]                    = glptr "glStencilFuncSeparate",
        ["StencilOpSeparate"]                      = glptr "glStencilOpSeparate",
        ["StencilMaskSeparate"]                    = glptr "glStencilMaskSeparate",
        ["UniformMatrix2x3fv"]                     = glptr "glUniformMatrix2x3fv",
        ["UniformMatrix3x2fv"]                     = glptr "glUniformMatrix3x2fv",
        ["UniformMatrix2x4fv"]                     = glptr "glUniformMatrix2x4fv",
        ["UniformMatrix4x2fv"]                     = glptr "glUniformMatrix4x2fv",
        ["UniformMatrix3x4fv"]                     = glptr "glUniformMatrix3x4fv",
        ["UniformMatrix4x3fv"]                     = glptr "glUniformMatrix4x3fv"
    }
end

return {}

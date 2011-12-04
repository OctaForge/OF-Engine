#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <limits.h>
#include <png.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_STROKER_H
#include FT_GLYPH_H

typedef unsigned char uchar; 
typedef unsigned short ushort;
typedef unsigned int uint;

void fatal(const char *fmt, ...)    // failure exit
{
    va_list v;
    va_start(v, fmt);
    vfprintf(stderr, fmt, v);
    va_end(v);
    fputc('\n', stderr);

    exit(EXIT_FAILURE);
}

void savepng(uchar *pixels, int w, int h, const char *name)
{
    FILE *f = fopen(name, "wb");
    int y;
    png_structp p;
    png_infop i;
    if(!f) goto failed;
    p = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if(!p) goto failed;
    i = png_create_info_struct(p);
    if(!i) goto failed;
    if(!setjmp(png_jmpbuf(p)))
    {
        png_init_io(p, f);
        png_set_compression_level(p, 9);
        png_set_IHDR(p, i, w, h, 8, PNG_COLOR_TYPE_GRAY_ALPHA, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
        png_write_info(p, i);
        for(y = 0; y < h; y++)
        {
            png_write_row(p, &pixels[y*w*2]);
        }
        png_write_end(p, NULL);
        png_destroy_write_struct(&p, &i);
        fclose(f);
        return;
    }
failed:
    fatal("cube2font: failed writing %s", name);
}

int iscubeprint(int c)
{
    static const char flags[256] =
    {
        0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    };
    return flags[c];
}
        
int cube2uni(int c)
{
    static const int conv[256] =
    {
        0, 192, 193, 194, 195, 196, 197, 198, 199, 9, 10, 11, 12, 13, 200, 201,
        202, 203, 204, 205, 206, 207, 209, 210, 211, 212, 213, 214, 216, 217, 218, 219,
        32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
        48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63,
        64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
        80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
        96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,
        112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 220,
        221, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237,
        238, 239, 241, 242, 243, 244, 245, 246, 248, 249, 250, 251, 252, 253, 255, 0x104,
        0x105, 0x106, 0x107, 0x10C, 0x10D, 0x10E, 0x10F, 0x118, 0x119, 0x11A, 0x11B, 0x11E, 0x11F, 0x130, 0x131, 0x141,
        0x142, 0x143, 0x144, 0x147, 0x148, 0x150, 0x151, 0x152, 0x153, 0x158, 0x159, 0x15A, 0x15B, 0x15E, 0x15F, 0x160,
        0x161, 0x164, 0x165, 0x16E, 0x16F, 0x170, 0x171, 0x178, 0x179, 0x17A, 0x17B, 0x17C, 0x17D, 0x17E, 0x404, 0x411,
        0x413, 0x414, 0x416, 0x417, 0x418, 0x419, 0x41B, 0x41F, 0x423, 0x424, 0x426, 0x427, 0x428, 0x429, 0x42A, 0x42B,
        0x42C, 0x42D, 0x42E, 0x42F, 0x431, 0x432, 0x433, 0x434, 0x436, 0x437, 0x438, 0x439, 0x43A, 0x43B, 0x43C, 0x43D,
        0x43F, 0x442, 0x444, 0x446, 0x447, 0x448, 0x449, 0x44A, 0x44B, 0x44C, 0x44D, 0x44E, 0x44F, 0x454, 0x490, 0x491
    };
    return conv[c];
}

int uni2cube(int c)
{
    static const int offsets[256] =
    {
        0, 256, 658, 658, 512, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 
        658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 
        658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 
        658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 
        658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 
        658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 
        658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 
        658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 658, 
    };
    static const int chars[878] =
    {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 10, 11, 12, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 
        64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 
        96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        1, 2, 3, 4, 5, 6, 7, 8, 14, 15, 16, 17, 18, 19, 20, 21, 0, 22, 23, 24, 25, 26, 27, 0, 28, 29, 30, 31, 127, 128, 0, 129, 
        130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 0, 146, 147, 148, 149, 150, 151, 0, 152, 153, 154, 155, 156, 157, 0, 158, 
        0, 0, 0, 0, 159, 160, 161, 162, 0, 0, 0, 0, 163, 164, 165, 166, 0, 0, 0, 0, 0, 0, 0, 0, 167, 168, 169, 170, 0, 0, 171, 172, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 173, 174, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 175, 176, 177, 178, 0, 0, 179, 180, 0, 0, 0, 0, 0, 0, 0, 181, 182, 183, 184, 0, 0, 0, 0, 185, 186, 187, 188, 0, 0, 189, 190, 
        191, 192, 0, 0, 193, 194, 0, 0, 0, 0, 0, 0, 0, 0, 195, 196, 197, 198, 0, 0, 0, 0, 0, 0, 199, 200, 201, 202, 203, 204, 205, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 17, 0, 0, 206, 83, 73, 21, 74, 0, 0, 0, 0, 0, 0, 0, 65, 207, 66, 208, 209, 69, 210, 211, 212, 213, 75, 214, 77, 72, 79, 215, 
        80, 67, 84, 216, 217, 88, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 97, 228, 229, 230, 231, 101, 232, 233, 234, 235, 236, 237, 238, 239, 111, 240, 
        112, 99, 241, 121, 242, 120, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 0, 141, 0, 0, 253, 115, 105, 145, 106, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 254, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 
    };
    return ((uint)c) <= 0xFFFF ? chars[offsets[c>>8] + (c&0xFF)] : 0;
}

const char *encodeutf8(int uni)
{
    static char buf[7];
    char *dst = buf;
    if(uni <= 0x7F) { *dst++ = uni; goto uni1; }
    else if(uni <= 0x7FF) { *dst++ = 0xC0 | (uni>>6); goto uni2; }
    else if(uni <= 0xFFFF) { *dst++ = 0xE0 | (uni>>12); goto uni3; } 
    else if(uni <= 0x1FFFFF) { *dst++ = 0xF0 | (uni>>18); goto uni4; } 
    else if(uni <= 0x3FFFFFF) { *dst++ = 0xF8 | (uni>>24); goto uni5; } 
    else if(uni <= 0x7FFFFFFF) { *dst++ = 0xFC | (uni>>30); goto uni6; } 
    else goto uni1;
uni6: *dst++ = 0x80 | ((uni>>24)&0x3F);
uni5: *dst++ = 0x80 | ((uni>>18)&0x3F);
uni4: *dst++ = 0x80 | ((uni>>12)&0x3F);
uni3: *dst++ = 0x80 | ((uni>>6)&0x3F);
uni2: *dst++ = 0x80 | (uni&0x3F);
uni1: *dst++ = '\0';
    return buf;
}

struct fontchar { int code, uni, tex, x, y, w, h, offx, offy, advance; FT_BitmapGlyph color, alpha; };

const char *texdir = "";

const char *texfilename(const char *name, int texnum)
{
    static char file[256];
    snprintf(file, sizeof(file), "%s%d.png", name, texnum);
    return file;
}

const char *texname(const char *name, int texnum)
{
    static char file[512];
    snprintf(file, sizeof(file), "<grey>%s%s", texdir, texfilename(name, texnum));
    return file;
}

void writetexs(const char *name, struct fontchar *chars, int numchars, int numtexs, int tw, int th)
{
    int tex;
    uchar *pixels = (uchar *)malloc(tw*th*2);
    if(!pixels) fatal("cube2font: failed allocating textures");
    for(tex = 0; tex < numtexs; tex++)
    {
        const char *file = texfilename(name, tex);
        int texchars = 0, i;
        uchar *dst, *src;
        memset(pixels, 0, tw*th*2);
        for(i = 0; i < numchars; i++)
        {
            struct fontchar *c = &chars[i];
            int x, y;
            if(c->tex != tex) continue;
            texchars++;
            dst = &pixels[2*((c->y + c->alpha->top - c->color->top)*tw + c->x + c->color->left - c->alpha->left)];
            src = (uchar *)c->color->bitmap.buffer;
            for(y = 0; y < c->color->bitmap.rows; y++)
            {
                for(x = 0; x < c->color->bitmap.width; x++)
                    dst[2*x] = src[x];
                src += c->color->bitmap.pitch;
                dst += 2*tw;
            }
            dst = &pixels[2*(c->y*tw + c->x)];
            src = (uchar *)c->alpha->bitmap.buffer;
            for(y = 0; y < c->alpha->bitmap.rows; y++)
            {
                for(x = 0; x < c->alpha->bitmap.width; x++)
                    dst[2*x+1] = src[x];
                src += c->alpha->bitmap.pitch;
                dst += 2*tw;
            }
        }
        printf("cube2font: writing %d chars to %s\n", texchars, file);
        savepng(pixels, tw, th, file);
   }
   free(pixels);
}

void writecfg(const char *name, struct fontchar *chars, int numchars, int x1, int y1, int x2, int y2, int sw, int sh, int argc, char **argv)
{
    FILE *f;
    char file[256];
    int i, lastcode = 0, lasttex = 0;
    snprintf(file, sizeof(file), "%s.cfg", name);
    f = fopen(file, "w");
    if(!f) fatal("cube2font: failed writing %s", file);
    printf("cube2font: writing %d chars to %s\n", numchars, file);
    fprintf(f, "//");
    for(i = 1; i < argc; i++)
        fprintf(f, " %s", argv[i]);
    fprintf(f, "\n");
    fprintf(f, "font \"%s\" \"%s\" %d %d\n", name, texname(name, 0), sw, sh);
    for(i = 0; i < numchars; i++)
    {
        struct fontchar *c = &chars[i];
        if(!lastcode && lastcode < c->code)
        {
            fprintf(f, "fontoffset \"%s\"\n", encodeutf8(c->uni));
            lastcode = c->code;
        }
        else if(lastcode < c->code)
        {
            if(lastcode + 1 == c->code)
                fprintf(f, "fontskip // %d\n", lastcode);
            else
                fprintf(f, "fontskip %d // %d .. %d\n", c->code - lastcode, lastcode, c->code-1);
            lastcode = c->code;
        }    
        if(lasttex != c->tex)
        {
            fprintf(f, "\nfonttex \"%s\"\n", texname(name, c->tex));
            lasttex = c->tex;
        }
        if(c->code != c->uni)
            fprintf(f, "fontchar %d %d %d %d %d %d %d // %s (%d -> 0x%X)\n", c->x, c->y, c->w, c->h, c->offx, y2-c->offy, c->advance, encodeutf8(c->uni), c->code, c->uni);
        else
            fprintf(f, "fontchar %d %d %d %d %d %d %d // %s (%d)\n", c->x, c->y, c->w, c->h, c->offx, y2-c->offy, c->advance, encodeutf8(c->uni), c->code);
        lastcode++;
    }
    fclose(f);
}

int groupchar(int c)
{
    switch(c)
    {
    case 0x152: case 0x153: case 0x178: return 1;
    }
    if(c < 127 || c >= 0x2000) return 0;
    if(c < 0x100) return 1;
    if(c < 0x400) return 2;
    return 3;
}

int sortchars(const void *x, const void *y)
{
    const struct fontchar *xc = *(const struct fontchar **)x, *yc = *(const struct fontchar **)y;
    int xg = groupchar(xc->uni), yg = groupchar(yc->uni);
    if(xg < yg) return -1;
    if(xg > yg) return 1; 
    if(xc->h != yc->h) return yc->h - xc->h;
    if(xc->w != yc->w) return yc->w - xc->w;
    return yc->uni - xc->uni;
}

int main(int argc, char **argv)
{
    FT_Library l;
    FT_Face f;
    FT_Stroker s;
    int i, pad, offset, advance, w, h, tw, th, c, rw = 0, rh = 0, ry = 0, x1 = INT_MAX, x2 = INT_MIN, y1 = INT_MAX, y2 = INT_MIN, w2 = 0, h2 = 0, sw = 0, sh = 0;
    float border;
    struct fontchar chars[256];
    struct fontchar *order[256];
    int numchars = 0, numtex = 0;
    if(argc < 11)
        fatal("Usage: cube2font infile outfile border pad offset advance charwidth charheight texwidth texheight [spacewidth spaceheight texdir]");
    border = atof(argv[3]);
    pad = atoi(argv[4]);
    offset = atoi(argv[5]);
    advance = atoi(argv[6]);
    w = atoi(argv[7]);
    h = atoi(argv[8]);
    tw = atoi(argv[9]);
    th = atoi(argv[10]);
    if(argc > 11) sw = atoi(argv[11]);
    if(argc > 12) sh = atoi(argv[12]);
    if(argc > 13) texdir = argv[13];
    if(FT_Init_FreeType(&l))
        fatal("cube2font: failed initing freetype");
    if(FT_New_Face(l, argv[1], 0, &f) ||
       FT_Set_Charmap(f, f->charmaps[0]) ||
       FT_Set_Pixel_Sizes(f, w, h) ||
       FT_Stroker_New(l, &s))
        fatal("cube2font: failed loading font %s", argv[1]);
    FT_Stroker_Set(s, (FT_Fixed)(border * 64), FT_STROKER_LINECAP_ROUND, FT_STROKER_LINEJOIN_ROUND, 0);
    for(c = 0; c < 256; c++) if(iscubeprint(c)) 
    {
        FT_Glyph p, p2;
        FT_BitmapGlyph b, b2;
        struct fontchar *dst = &chars[numchars];
        dst->code = c;
        dst->uni = cube2uni(c);
        if(FT_Load_Char(f, dst->uni, FT_LOAD_DEFAULT))
            fatal("cube2font: failed loading character %s", encodeutf8(dst->uni));
        FT_Get_Glyph(f->glyph, &p);
        p2 = p;
        FT_Glyph_StrokeBorder(&p, s, 0, 0);
        FT_Glyph_To_Bitmap(&p, FT_RENDER_MODE_NORMAL, 0, 1);
        FT_Glyph_To_Bitmap(&p2, FT_RENDER_MODE_NORMAL, 0, 1);
        b = (FT_BitmapGlyph)p;
        b2 = (FT_BitmapGlyph)p2;
        dst->tex = -1;
        dst->offx = b->left + offset;
        dst->offy = b->top;
        dst->advance = offset + ((p->advance.x+0xFFFF)>>16) + advance;
        dst->w = b->bitmap.width;
        dst->h = b->bitmap.rows;
        dst->alpha = b;
        dst->color = b2;
        order[numchars++] = dst;
    }
    qsort(order, numchars, sizeof(order[0]), sortchars);
    for(i = 0; i < numchars; i++)
    {
        FT_BitmapGlyph b;
        struct fontchar *dst = order[i];
        int j, g;
        if(dst->tex >= 0) continue;
        g = groupchar(dst->uni);
        for(j = i; j < numchars; j++)
        {
            struct fontchar *fit = order[j];
            if(groupchar(fit->uni) != g) break;
            if(fit->tex >= 0) continue;
            if(rw + fit->alpha->bitmap.width <= tw && ry + fit->alpha->bitmap.rows <= th) { dst = fit; break; }
        }
        b = dst->alpha;
        if(rw + b->bitmap.width > tw)
        {
            ry += rh + pad;
            rw = rh = 0;
        } 
        if(ry + b->bitmap.rows > th)
        {
            ry = rw = rh = 0;
            numtex++;
        }
        dst->tex = numtex;
        dst->x = rw;
        dst->y = ry;
        rw += b->bitmap.width + pad;
        if(b->bitmap.rows > rh) rh = b->bitmap.rows;
        if(b->top - b->bitmap.rows < y1) y1 = b->top - b->bitmap.rows;
        if(b->top > y2) y2 = b->top;
        if(b->left < x1) x1 = b->left;
        if(b->left + b->bitmap.width > x2) x2 = b->left + b->bitmap.width;
        if(b->bitmap.width > w2) w2 = b->bitmap.width;
        if(b->bitmap.rows > h2) h2 = b->bitmap.rows;
        if(dst != order[i]) --i;
    }
    if(rh > 0) numtex++;
#if 0
    if(sw <= 0)
    {
        if(FT_Load_Char(f, ' ', FT_LOAD_DEFAULT))
            fatal("cube2font: failed loading space character");
        sw = (f->glyph->advance.x+0x3F)>>6;
    }
#endif
    if(sh <= 0) sh = y2 - y1;
    if(sw <= 0) sw = sh/3;
    writetexs(argv[2], chars, numchars, numtex, tw, th);
    writecfg(argv[2], chars, numchars, x1, y1, x2, y2, sw, sh, argc, argv);
    for(i = 0; i < numchars; i++)
    {
        FT_Done_Glyph((FT_Glyph)chars[i].alpha);
        FT_Done_Glyph((FT_Glyph)chars[i].color);
    }
    FT_Stroker_Done(s);
    FT_Done_FreeType(l);
    printf("cube2font: (%d, %d) .. (%d, %d) = (%d, %d) / (%d, %d), %d texs\n", x1, y1, x2, y2, x2 - x1, y2 - y1, w2, h2, numtex);
    return EXIT_SUCCESS;
}


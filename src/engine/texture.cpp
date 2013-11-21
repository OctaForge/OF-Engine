// texture.cpp: texture slot management

#include "engine.h"
#include "of_world.h"
#include "SDL_image.h"

template<int S>
static void halvetexture(uchar *src, uint sw, uint sh, uint stride, uchar *dst)
{
    for (uchar *yend = &src[sh*stride]; src < yend;)
    {
        for (uchar *xend = &src[stride]; src < xend; src += 2*S, dst += S) {
            loopi(S) dst[i] = (uint(src[i]) + uint(src[i+S]) + uint(src[stride+i]) + uint(src[stride+i+S]))>>2;
        }
        src += stride;
    }
}

template<int S>
static void shifttexture(uchar *src, uint sw, uint sh, uint stride, uchar *dst, uint dw, uint dh)
{
    uint wfrac = sw/dw, hfrac = sh/dh, wshift = 0, hshift = 0;
    while(dw<<wshift < sw) wshift++;
    while(dh<<hshift < sh) hshift++;
    uint tshift = wshift + hshift;
    for(uchar *yend = &src[sh*stride]; src < yend;)
    {
        for(uchar *xend = &src[stride];    src < xend; src += wfrac*S, dst += S)
        {
            uint r[S] = {0};
            for(uchar *ycur=src, *xend=&ycur[wfrac*S], *yend=&src[hfrac*stride]; ycur<yend; ycur+=stride, xend+=stride)
            {
                for(uchar *xcur = ycur; xcur < xend; xcur += S) {
                    loopi(S) r[i] += xcur[i];
                }
            }
            loopi(S) dst[i] = (r[i]) >> tshift;
        }
        src += (hfrac-1)*stride;
    }
}

template<int S>
static void scaletexture(uchar *src, uint sw, uint sh, uint stride, uchar *dst, uint dw, uint dh)
{
    uint wfrac = (sw<<12)/dw, hfrac = (sh<<12)/dh, darea = dw*dh, sarea = sw*sh;
    int over, under;
    for(over = 0; (darea>>over) > sarea; over++);
    for(under = 0; (darea<<under) < sarea; under++);
    uint cscale = clamp(under, over - 12, 12),
         ascale = clamp(12 + under - over, 0, 24),
         dscale = ascale + 12 - cscale,
         area = ((ullong)darea<<ascale)/sarea;
    dw *= wfrac;
    dh *= hfrac;
    for(uint y = 0; y < dh; y += hfrac)
    {
        const uint yn = y + hfrac - 1, yi = y>>12, h = (yn>>12) - yi, ylow = ((yn|(-int(h)>>24))&0xFFFU) + 1 - (y&0xFFFU), yhigh = (yn&0xFFFU) + 1;
        const uchar *ysrc = &src[yi*stride];
        for(uint x = 0; x < dw; x += wfrac, dst += S)
        {
            const uint xn = x + wfrac - 1, xi = x>>12, w = (xn>>12) - xi, xlow = ((w+0xFFFU)&0x1000U) - (x&0xFFFU), xhigh = (xn&0xFFFU) + 1;
            const uchar *xsrc = &ysrc[xi*S], *xend = &xsrc[w*S];
            uint r[S] = {0};
            for(const uchar *xcur = &xsrc[S]; xcur < xend; xcur += S) {
                loopi(S) r[i] += xcur[i];
            }
            loopi(S) r[i] = (ylow*(r[i] + ((xsrc[i]*xlow + xend[i]*xhigh)>>12)))>>cscale;
            if(h)
            {
                xsrc += stride;
                xend += stride;
                for(uint hcur = h; --hcur; xsrc += stride, xend += stride)
                {
                    uint p[S] = {0};
                    for(const uchar *xcur = &xsrc[S]; xcur < xend; xcur += S) {
                        loopi(S) p[i] += xcur[i];
                    }
                    loopi(S) r[i] += ((p[i]<<12) + xsrc[i]*xlow + xend[i]*xhigh)>>cscale;
                }
                uint p[S] = {0};
                for(const uchar *xcur = &xsrc[S]; xcur < xend; xcur += S) {
                    loopi(S) p[i] += xcur[i];
                }
                loopi(S) r[i] += (yhigh*(p[i] + ((xsrc[i]*xlow + xend[i]*xhigh)>>12)))>>cscale;
            }
            loopi(S) dst[i] = (r[i] * area)>>dscale;
        }
    }
}

static void scaletexture(uchar *src, uint sw, uint sh, uint bpp, uint pitch, uchar *dst, uint dw, uint dh)
{
    if(sw == dw*2 && sh == dh*2)
    {
        switch(bpp)
        {
            case 1: halvetexture<1>(src, sw, sh, pitch, dst); return;
            case 2: halvetexture<2>(src, sw, sh, pitch, dst); return;
            case 3: halvetexture<3>(src, sw, sh, pitch, dst); return;
            case 4: halvetexture<4>(src, sw, sh, pitch, dst); return;
        }
    }
    else if(sw < dw || sh < dh || sw&(sw-1) || sh&(sh-1) || dw&(dw-1) || dh&(dh-1))
    {
        switch(bpp)
        {
            case 1: scaletexture<1>(src, sw, sh, pitch, dst, dw, dh); return;
            case 2: scaletexture<2>(src, sw, sh, pitch, dst, dw, dh); return;
            case 3: scaletexture<3>(src, sw, sh, pitch, dst, dw, dh); return;
            case 4: scaletexture<4>(src, sw, sh, pitch, dst, dw, dh); return;
        }
    }
    else
    {
        switch(bpp)
        {
            case 1: shifttexture<1>(src, sw, sh, pitch, dst, dw, dh); return;
            case 2: shifttexture<2>(src, sw, sh, pitch, dst, dw, dh); return;
            case 3: shifttexture<3>(src, sw, sh, pitch, dst, dw, dh); return;
            case 4: shifttexture<4>(src, sw, sh, pitch, dst, dw, dh); return;
        }
    }
}

static inline void reorienttexture(uchar *src, int sw, int sh, int bpp, int stride, uchar *dst, bool flipx, bool flipy, bool swapxy, bool normals = false)
{
    int stridex = bpp, stridey = bpp;
    if(swapxy) stridex *= sh; else stridey *= sw;
    if(flipx) { dst += (sw-1)*stridex; stridex = -stridex; }
    if(flipy) { dst += (sh-1)*stridey; stridey = -stridey; }
    uchar *srcrow = src;
    loopi(sh)
    {
        for(uchar *curdst = dst, *src = srcrow, *end = &srcrow[sw*bpp]; src < end;)
        {
            loopk(bpp) curdst[k] = *src++;
            if(normals)
            {
                if(flipx) curdst[0] = 255-curdst[0];
                if(flipy) curdst[1] = 255-curdst[1];
                if(swapxy) swap(curdst[0], curdst[1]);
            }
            curdst += stridex;
        }
        srcrow += stride;
        dst += stridey;
    }
}

static void reorients3tc(GLenum format, int blocksize, int w, int h, uchar *src, uchar *dst, bool flipx, bool flipy, bool swapxy, bool normals = false)
{
    int bx1 = 0, by1 = 0, bx2 = min(w, 4), by2 = min(h, 4), bw = (w+3)/4, bh = (h+3)/4, stridex = blocksize, stridey = blocksize;
    if(swapxy) stridex *= bw; else stridey *= bh;
    if(flipx) { dst += (bw-1)*stridex; stridex = -stridex; bx1 += 4-bx2; bx2 = 4; }
    if(flipy) { dst += (bh-1)*stridey; stridey = -stridey; by1 += 4-by2; by2 = 4; }
    loopi(bh)
    {
        for(uchar *curdst = dst, *end = &src[bw*blocksize]; src < end; src += blocksize, curdst += stridex)
        {
            if(format == GL_COMPRESSED_RGBA_S3TC_DXT3_EXT)
            {
                ullong salpha = lilswap(*(ullong *)src), dalpha = 0;
                uint xmask = flipx ? 15 : 0, ymask = flipy ? 15 : 0, xshift = 2, yshift = 4;
                if(swapxy) swap(xshift, yshift);
                for(int y = by1; y < by2; y++) for(int x = bx1; x < bx2; x++)
                {
                    dalpha |= ((salpha&15) << (((xmask^x)<<xshift) + ((ymask^y)<<yshift)));
                    salpha >>= 4;
                }
                *(ullong *)curdst = lilswap(dalpha);
                src += 8;
                curdst += 8;
            }
            else if(format == GL_COMPRESSED_RGBA_S3TC_DXT5_EXT)
            {
                uchar alpha1 = src[0], alpha2 = src[1];
                ullong salpha = lilswap(*(ushort *)&src[2]) + ((ullong)lilswap(*(ushort *)&src[4])<<16) + ((ullong)lilswap(*(ushort *)&src[6])<<32), dalpha = 0;
                uint xmask = flipx ? 7 : 0, ymask = flipy ? 7 : 0, xshift = 0, yshift = 2;
                if(swapxy) swap(xshift, yshift);
                for(int y = by1; y < by2; y++) for(int x = bx1; x < bx2; x++)
                {
                    dalpha |= ((salpha&7) << (3*((xmask^x)<<xshift) + ((ymask^y)<<yshift)));
                    salpha >>= 3;
                }
                curdst[0] = alpha1;
                curdst[1] = alpha2;
                *(ushort *)&curdst[2] = lilswap(ushort(dalpha));
                *(ushort *)&curdst[4] = lilswap(ushort(dalpha>>16));
                *(ushort *)&curdst[6] = lilswap(ushort(dalpha>>32));
                src += 8;
                curdst += 8;
            }

            ushort color1 = lilswap(*(ushort *)src), color2 = lilswap(*(ushort *)&src[2]);
            uint sbits = lilswap(*(uint *)&src[4]);
            if(normals)
            {
                ushort ncolor1 = color1, ncolor2 = color2;
                if(flipx)
                {
                    ncolor1 = (ncolor1 & ~0xF800) | (0xF800 - (ncolor1 & 0xF800));
                    ncolor2 = (ncolor2 & ~0xF800) | (0xF800 - (ncolor2 & 0xF800));
                }
                if(flipy)
                {
                    ncolor1 = (ncolor1 & ~0x7E0) | (0x7E0 - (ncolor1 & 0x7E0));
                    ncolor2 = (ncolor2 & ~0x7E0) | (0x7E0 - (ncolor2 & 0x7E0));
                }
                if(swapxy)
                {
                    ncolor1 = (ncolor1 & 0x1F) | (((((ncolor1 >> 11) & 0x1F) * 0x3F) / 0x1F) << 5) | (((((ncolor1 >> 5) & 0x3F) * 0x1F) / 0x3F) << 11);
                    ncolor2 = (ncolor2 & 0x1F) | (((((ncolor2 >> 11) & 0x1F) * 0x3F) / 0x1F) << 5) | (((((ncolor2 >> 5) & 0x3F) * 0x1F) / 0x3F) << 11);
                }
                if(color1 <= color2 && ncolor1 > ncolor2) { color1 = ncolor2; color2 = ncolor1; }
                else { color1 = ncolor1; color2 = ncolor2; }
            }
            uint dbits = 0, xmask = flipx ? 3 : 0, ymask = flipy ? 3 : 0, xshift = 1, yshift = 3;
            if(swapxy) swap(xshift, yshift);
            for(int y = by1; y < by2; y++) for(int x = bx1; x < bx2; x++)
            {
                dbits |= ((sbits&3) << (((xmask^x)<<xshift) + ((ymask^y)<<yshift)));
                sbits >>= 2;
            }
            *(ushort *)curdst = lilswap(color1);
            *(ushort *)&curdst[2] = lilswap(color2);
            *(uint *)&curdst[4] = lilswap(dbits);

            if(blocksize > 8) { src -= 8; curdst -= 8; }
        }
        dst += stridey;
    }
}

static void reorientrgtc(GLenum format, int blocksize, int w, int h, uchar *src, uchar *dst, bool flipx, bool flipy, bool swapxy)
{
    int bx1 = 0, by1 = 0, bx2 = min(w, 4), by2 = min(h, 4), bw = (w+3)/4, bh = (h+3)/4, stridex = blocksize, stridey = blocksize;
    if(swapxy) stridex *= bw; else stridey *= bh;
    if(flipx) { dst += (bw-1)*stridex; stridex = -stridex; bx1 += 4-bx2; bx2 = 4; }
    if(flipy) { dst += (bh-1)*stridey; stridey = -stridey; by1 += 4-by2; by2 = 4; }
    stridex -= blocksize;
    loopi(bh)
    {
        for(uchar *curdst = dst, *end = &src[bw*blocksize]; src < end; curdst += stridex)
        {
            loopj(blocksize/8)
            {
                uchar val1 = src[0], val2 = src[1];
                ullong sval = lilswap(*(ushort *)&src[2]) + ((ullong)lilswap(*(ushort *)&src[4])<<16) + ((ullong)lilswap(*(ushort *)&src[6])<<32), dval = 0;
                uint xmask = flipx ? 7 : 0, ymask = flipy ? 7 : 0, xshift = 0, yshift = 2;
                if(swapxy) swap(xshift, yshift);
                for(int y = by1; y < by2; y++) for(int x = bx1; x < bx2; x++)
                {
                    dval |= ((sval&7) << (3*((xmask^x)<<xshift) + ((ymask^y)<<yshift)));
                    sval >>= 3;
                }
                curdst[0] = val1;
                curdst[1] = val2;
                *(ushort *)&curdst[2] = lilswap(ushort(dval));
                *(ushort *)&curdst[4] = lilswap(ushort(dval>>16));
                *(ushort *)&curdst[6] = lilswap(ushort(dval>>32));
                src += 8;
                curdst += 8;
            }
        }
        dst += stridey;
    }
}

#define writetex(t, body) do \
    { \
        uchar *dstrow = t.data; \
        loop(y, t.h) \
        { \
            for(uchar *dst = dstrow, *end = &dstrow[t.w*t.bpp]; dst < end; dst += t.bpp) \
            { \
                body; \
            } \
            dstrow += t.pitch; \
        } \
    } while(0)

#define readwritetex(t, s, body) do \
    { \
        uchar *dstrow = t.data, *srcrow = s.data; \
        loop(y, t.h) \
        { \
            for(uchar *dst = dstrow, *src = srcrow, *end = &srcrow[s.w*s.bpp]; src < end; dst += t.bpp, src += s.bpp) \
            { \
                body; \
            } \
            dstrow += t.pitch; \
            srcrow += s.pitch; \
        } \
    } while(0)

#define read2writetex(t, s1, src1, s2, src2, body) do \
    { \
        uchar *dstrow = t.data, *src1row = s1.data, *src2row = s2.data; \
        loop(y, t.h) \
        { \
            for(uchar *dst = dstrow, *end = &dstrow[t.w*t.bpp], *src1 = src1row, *src2 = src2row; dst < end; dst += t.bpp, src1 += s1.bpp, src2 += s2.bpp) \
            { \
                body; \
            } \
            dstrow += t.pitch; \
            src1row += s1.pitch; \
            src2row += s2.pitch; \
        } \
    } while(0)

void texreorient(ImageData &s, bool flipx, bool flipy, bool swapxy, int type = TEX_DIFFUSE)
{
    ImageData d(swapxy ? s.h : s.w, swapxy ? s.w : s.h, s.bpp, s.levels, s.align, s.compressed);
    switch(s.compressed)
    {
    case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT:
        {
            uchar *dst = d.data, *src = s.data;
            loopi(s.levels)
            {
                reorients3tc(s.compressed, s.bpp, max(s.w>>i, 1), max(s.h>>i, 1), src, dst, flipx, flipy, swapxy, type==TEX_NORMAL);
                src += s.calclevelsize(i);
                dst += d.calclevelsize(i);
            }
            break;
        }
    case GL_COMPRESSED_RED_RGTC1:
    case GL_COMPRESSED_RG_RGTC2:
    case GL_COMPRESSED_LUMINANCE_LATC1_EXT:
    case GL_COMPRESSED_LUMINANCE_ALPHA_LATC2_EXT:
        {
            uchar *dst = d.data, *src = s.data;
            loopi(s.levels)
            {
                reorientrgtc(s.compressed, s.bpp, max(s.w>>i, 1), max(s.h>>i, 1), src, dst, flipx, flipy, swapxy);
                src += s.calclevelsize(i);
                dst += d.calclevelsize(i);
            }
            break;
        }
    default:
        reorienttexture(s.data, s.w, s.h, s.bpp, s.pitch, d.data, flipx, flipy, swapxy, type==TEX_NORMAL);
        break;
    }
    s.replace(d);
}

void texrotate(ImageData &s, int numrots, int type = TEX_DIFFUSE)
{
    // 1..3 rotate through 90..270 degrees, 4 flips X, 5 flips Y
    if(numrots>=1 && numrots<=5)
        texreorient(s,
            numrots>=2 && numrots<=4, // flip X on 180/270 degrees
            numrots<=2 || numrots==5, // flip Y on 90/180 degrees
            (numrots&5)==1,           // swap X/Y on 90/270 degrees
            type);
}

void texoffset(ImageData &s, int xoffset, int yoffset)
{
    xoffset = max(xoffset, 0);
    xoffset %= s.w;
    yoffset = max(yoffset, 0);
    yoffset %= s.h;
    if(!xoffset && !yoffset) return;
    ImageData d(s.w, s.h, s.bpp);
    uchar *src = s.data;
    loop(y, s.h)
    {
        uchar *dst = (uchar *)d.data+((y+yoffset)%d.h)*d.pitch;
        memcpy(dst+xoffset*s.bpp, src, (s.w-xoffset)*s.bpp);
        memcpy(dst, src+(s.w-xoffset)*s.bpp, xoffset*s.bpp);
        src += s.pitch;
    }
    s.replace(d);
}

void texmad(ImageData &s, const vec &mul, const vec &add)
{
    int maxk = min(int(s.bpp), 3);
    writetex(s,
        loopk(maxk) dst[k] = uchar(clamp(dst[k]*mul[k] + 255*add[k], 0.0f, 255.0f));
    );
}

void texcolorify(ImageData &s, const vec &color, vec weights)
{
    if(s.bpp < 3) return;
    if(weights.iszero()) weights = vec(0.21f, 0.72f, 0.07f);
    writetex(s,
        float lum = dst[0]*weights.x + dst[1]*weights.y + dst[2]*weights.z;
        loopk(3) dst[k] = uchar(clamp(lum*color[k], 0.0f, 255.0f));
    );
}

void texcolormask(ImageData &s, const vec &color1, const vec &color2)
{
    if(s.bpp < 4) return;
    ImageData d(s.w, s.h, 3);
    readwritetex(d, s,
        vec color;
        color.lerp(color2, color1, src[3]/255.0f);
        loopk(3) dst[k] = uchar(clamp(color[k]*src[k], 0.0f, 255.0f));
    );
    s.replace(d);
}

void texdup(ImageData &s, int srcchan, int dstchan)
{
    if(srcchan==dstchan || max(srcchan, dstchan) >= s.bpp) return;
    writetex(s, dst[dstchan] = dst[srcchan]);
}

void texmix(ImageData &s, int c1, int c2, int c3, int c4)
{
    int numchans = c1 < 0 ? 0 : (c2 < 0 ? 1 : (c3 < 0 ? 2 : (c4 < 0 ? 3 : 4)));
    if(numchans <= 0) return;
    ImageData d(s.w, s.h, numchans);
    readwritetex(d, s,
        switch(numchans)
        {
            case 4: dst[3] = src[c4];
            case 3: dst[2] = src[c3];
            case 2: dst[1] = src[c2];
            case 1: dst[0] = src[c1];
        }
    );
    s.replace(d);
}

void texgrey(ImageData &s)
{
    if(s.bpp <= 2) return;
    ImageData d(s.w, s.h, s.bpp >= 4 ? 2 : 1);
    if(s.bpp >= 4)
    {
        readwritetex(d, s,
            dst[0] = src[0];
            dst[1] = src[3];
        );
    }
    else
    {
        readwritetex(d, s, dst[0] = src[0]);
    }
    s.replace(d);
}

void texpremul(ImageData &s)
{
    switch(s.bpp)
    {
        case 2:
            writetex(s,
                dst[0] = uchar((uint(dst[0])*uint(dst[1]))/255);
            );
            break;
        case 4:
            writetex(s,
                uint alpha = dst[3];
                dst[0] = uchar((uint(dst[0])*alpha)/255);
                dst[1] = uchar((uint(dst[1])*alpha)/255);
                dst[2] = uchar((uint(dst[2])*alpha)/255);
            );
            break;
    }
}

void texagrad(ImageData &s, float x2, float y2, float x1, float y1)
{
    if(s.bpp != 2 && s.bpp != 4) return;
    y1 = 1 - y1;
    y2 = 1 - y2;
    float minx = 1, miny = 1, maxx = 1, maxy = 1;
    if(x1 != x2)
    {
        minx = (0 - x1) / (x2 - x1);
        maxx = (1 - x1) / (x2 - x1);
    }
    if(y1 != y2)
    {
        miny = (0 - y1) / (y2 - y1);
        maxy = (1 - y1) / (y2 - y1);
    }
    float dx = (maxx - minx)/max(s.w-1, 1),
          dy = (maxy - miny)/max(s.h-1, 1),
          cury = miny;
    for(uchar *dstrow = s.data + s.bpp - 1, *endrow = dstrow + s.h*s.pitch; dstrow < endrow; dstrow += s.pitch)
    {
        float curx = minx;
        for(uchar *dst = dstrow, *end = &dstrow[s.w*s.bpp]; dst < end; dst += s.bpp)
        {
            dst[0] = uchar(dst[0]*clamp(curx, 0.0f, 1.0f)*clamp(cury, 0.0f, 1.0f));
            curx += dx;
        }
        cury += dy;
    }
}

VAR(hwtexsize, 1, 0, 0);
VAR(hwcubetexsize, 1, 0, 0);
VAR(hwmaxaniso, 1, 0, 0);
VAR(hwtexunits, 1, 0, 0);
VAR(hwvtexunits, 1, 0, 0);
VARFP(maxtexsize, 0, 0, 1<<12, initwarning("texture quality", INIT_LOAD));
VARFP(reducefilter, 0, 1, 1, initwarning("texture quality", INIT_LOAD));
VARFP(texreduce, 0, 0, 12, initwarning("texture quality", INIT_LOAD));
VARFP(texcompress, 0, 1536, 1<<12, initwarning("texture quality", INIT_LOAD));
VARFP(texcompressquality, -1, -1, 1, setuptexcompress());
VARFP(trilinear, 0, 1, 1, initwarning("texture filtering", INIT_LOAD));
VARFP(bilinear, 0, 1, 1, initwarning("texture filtering", INIT_LOAD));
VARFP(aniso, 0, 0, 16, initwarning("texture filtering", INIT_LOAD));
/* OF */
VARFR(texdefscale, 1, 16, 64, if (!world::loading) initwarning("texture scale", INIT_LOAD));

extern int usetexcompress;

void setuptexcompress()
{
    if(!usetexcompress) return;

    GLenum hint = GL_DONT_CARE;
    switch(texcompressquality)
    {
        case 1: hint = GL_NICEST; break;
        case 0: hint = GL_FASTEST; break;
    }
    glHint(GL_TEXTURE_COMPRESSION_HINT, hint);
}

GLenum compressedformat(GLenum format, int w, int h, int force = 0)
{
    if(usetexcompress && texcompress && force >= 0 && (force || max(w, h) >= texcompress)) switch(format)
    {
        case GL_RGB4:
        case GL_RGB5:
        case GL_RGB8:
        case GL_RGB: return usetexcompress > 1 ? GL_COMPRESSED_RGB_S3TC_DXT1_EXT : GL_COMPRESSED_RGB;
        case GL_RGB5_A1: return usetexcompress > 1 ? GL_COMPRESSED_RGBA_S3TC_DXT1_EXT : GL_COMPRESSED_RGBA;
        case GL_RGBA4:
        case GL_RGBA: return usetexcompress > 1 ? GL_COMPRESSED_RGBA_S3TC_DXT5_EXT : GL_COMPRESSED_RGBA;
        case GL_RED:
        case GL_R8: return hasRGTC ? (usetexcompress > 1 ? GL_COMPRESSED_RED_RGTC1 : GL_COMPRESSED_RED) : (usetexcompress > 1 ? GL_COMPRESSED_RGB_S3TC_DXT1_EXT : GL_COMPRESSED_RGB);
        case GL_RG:
        case GL_RG8: return hasRGTC ? (usetexcompress > 1 ? GL_COMPRESSED_RG_RGTC2 : GL_COMPRESSED_RG) : (usetexcompress > 1 ? GL_COMPRESSED_RGBA_S3TC_DXT5_EXT : GL_COMPRESSED_RGBA);
        case GL_LUMINANCE:
        case GL_LUMINANCE8: return hasLATC ? (usetexcompress > 1 ? GL_COMPRESSED_LUMINANCE_LATC1_EXT : GL_COMPRESSED_LUMINANCE) : (usetexcompress > 1 ? GL_COMPRESSED_RGB_S3TC_DXT1_EXT : GL_COMPRESSED_RGB);
        case GL_LUMINANCE_ALPHA:
        case GL_LUMINANCE8_ALPHA8: return hasLATC ? (usetexcompress > 1 ? GL_COMPRESSED_LUMINANCE_ALPHA_LATC2_EXT : GL_COMPRESSED_LUMINANCE_ALPHA) : (usetexcompress > 1 ? GL_COMPRESSED_RGBA_S3TC_DXT5_EXT : GL_COMPRESSED_RGBA);
    }
    return format;
}

int formatsize(GLenum format)
{
    switch(format)
    {
        case GL_RED:
        case GL_LUMINANCE:
        case GL_ALPHA: return 1;
        case GL_RG:
        case GL_LUMINANCE_ALPHA: return 2;
        case GL_RGB: return 3;
        case GL_RGBA: return 4;
        default: return 4;
    }
}

VARFP(usenp2, 0, 1, 1, initwarning("texture quality", INIT_LOAD));

void resizetexture(int w, int h, bool mipmap, bool canreduce, GLenum target, int compress, int &tw, int &th)
{
    int hwlimit = target==GL_TEXTURE_CUBE_MAP ? hwcubetexsize : hwtexsize,
        sizelimit = mipmap && maxtexsize ? min(maxtexsize, hwlimit) : hwlimit;
    if(compress > 0 && !usetexcompress)
    {
        w = max(w/compress, 1);
        h = max(h/compress, 1);
    }
    if(canreduce && texreduce)
    {
        w = max(w>>texreduce, 1);
        h = max(h>>texreduce, 1);
    }
    w = min(w, sizelimit);
    h = min(h, sizelimit);
    if(!usenp2 && target!=GL_TEXTURE_RECTANGLE && (w&(w-1) || h&(h-1)))
    {
        tw = th = 1;
        while(tw < w) tw *= 2;
        while(th < h) th *= 2;
        if(w < tw - tw/4) tw /= 2;
        if(h < th - th/4) th /= 2;
    }
    else
    {
        tw = w;
        th = h;
    }
}

void uploadtexture(GLenum target, GLenum internal, int tw, int th, GLenum format, GLenum type, const void *pixels, int pw, int ph, int pitch, bool mipmap)
{
    int bpp = formatsize(format), row = 0, rowalign = 0;
    if(!pitch) pitch = pw*bpp;
    uchar *buf = NULL;
    if(pw!=tw || ph!=th)
    {
        buf = new uchar[tw*th*bpp];
        scaletexture((uchar *)pixels, pw, ph, bpp, pitch, buf, tw, th);
    }
    else if(tw*bpp != pitch)
    {
        row = pitch/bpp;
        rowalign = texalign(pixels, pitch, 1);
        while(rowalign > 0 && ((row*bpp + rowalign - 1)/rowalign)*rowalign != pitch) rowalign >>= 1;
        if(!rowalign)
        {
            row = 0;
            buf = new uchar[tw*th*bpp];
            loopi(th) memcpy(&buf[i*tw*bpp], &((uchar *)pixels)[i*pitch], tw*bpp);
        }
    }
    for(int level = 0, align = 0;; level++)
    {
        uchar *src = buf ? buf : (uchar *)pixels;
        if(buf) pitch = tw*bpp;
        int srcalign = row > 0 ? rowalign : texalign(src, pitch, 1);
        if(align != srcalign) glPixelStorei(GL_UNPACK_ALIGNMENT, align = srcalign);
        if(row > 0) glPixelStorei(GL_UNPACK_ROW_LENGTH, row);
        if(target==GL_TEXTURE_1D) glTexImage1D(target, level, internal, tw, 0, format, type, src);
        else glTexImage2D(target, level, internal, tw, th, 0, format, type, src);
        if(row > 0) glPixelStorei(GL_UNPACK_ROW_LENGTH, row = 0);
        if(!mipmap || max(tw, th) <= 1) break;
        int srcw = tw, srch = th;
        if(tw > 1) tw /= 2;
        if(th > 1) th /= 2;
        if(src)
        {
            if(!buf) buf = new uchar[tw*th*bpp];
            scaletexture(src, srcw, srch, bpp, pitch, buf, tw, th);
        }
    }
    if(buf) delete[] buf;
}

void uploadcompressedtexture(GLenum target, GLenum subtarget, GLenum format, int w, int h, const uchar *data, int align, int blocksize, int levels, bool mipmap)
{
    int hwlimit = target==GL_TEXTURE_CUBE_MAP ? hwcubetexsize : hwtexsize,
        sizelimit = levels > 1 && maxtexsize ? min(maxtexsize, hwlimit) : hwlimit;
    int level = 0;
    loopi(levels)
    {
        int size = ((w + align-1)/align) * ((h + align-1)/align) * blocksize;
        if(w <= sizelimit && h <= sizelimit)
        {
            if(target==GL_TEXTURE_1D) glCompressedTexImage1D_(subtarget, level, format, w, 0, size, data);
            else glCompressedTexImage2D_(subtarget, level, format, w, h, 0, size, data);
            level++;
            if(!mipmap) break;
        }
        if(max(w, h) <= 1) break;
        if(w > 1) w /= 2;
        if(h > 1) h /= 2;
        data += size;
    }
}

GLenum textarget(GLenum subtarget)
{
    switch(subtarget)
    {
        case GL_TEXTURE_CUBE_MAP_POSITIVE_X:
        case GL_TEXTURE_CUBE_MAP_NEGATIVE_X:
        case GL_TEXTURE_CUBE_MAP_POSITIVE_Y:
        case GL_TEXTURE_CUBE_MAP_NEGATIVE_Y:
        case GL_TEXTURE_CUBE_MAP_POSITIVE_Z:
        case GL_TEXTURE_CUBE_MAP_NEGATIVE_Z:
            return GL_TEXTURE_CUBE_MAP;
    }
    return subtarget;
}

GLenum uncompressedformat(GLenum format)
{
    switch(format)
    {
        case GL_COMPRESSED_ALPHA:
            return GL_ALPHA;
        case GL_COMPRESSED_LUMINANCE:
        case GL_COMPRESSED_LUMINANCE_LATC1_EXT:
            return GL_LUMINANCE;
        case GL_COMPRESSED_LUMINANCE_ALPHA:
        case GL_COMPRESSED_LUMINANCE_ALPHA_LATC2_EXT:
            return GL_LUMINANCE_ALPHA;
        case GL_COMPRESSED_RED:
        case GL_COMPRESSED_RED_RGTC1:
            return GL_RED;
        case GL_COMPRESSED_RG:
        case GL_COMPRESSED_RG_RGTC2:
            return GL_RG;
        case GL_COMPRESSED_RGB:
        case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
            return GL_RGB;
        case GL_COMPRESSED_RGBA:
        case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:
        case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:
        case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT:
            return GL_RGBA;
    }
    return GL_FALSE;
}

const GLint *swizzlemask(GLenum format)
{
    static const GLint luminance[4] = { GL_RED, GL_RED, GL_RED, GL_ONE };
    static const GLint luminancealpha[4] = { GL_RED, GL_RED, GL_RED, GL_GREEN };
    switch(format)
    {
        case GL_RED: return luminance;
        case GL_RG: return luminancealpha;
    }
    return NULL;
}

void setuptexparameters(int tnum, const void *pixels, int clamp, int filter, GLenum format, GLenum target, bool swizzle)
{
    glBindTexture(target, tnum);
    glTexParameteri(target, GL_TEXTURE_WRAP_S, clamp&1 ? GL_CLAMP_TO_EDGE : (clamp&0x100 ? GL_MIRRORED_REPEAT : GL_REPEAT));
    if(target!=GL_TEXTURE_1D) glTexParameteri(target, GL_TEXTURE_WRAP_T, clamp&2 ? GL_CLAMP_TO_EDGE : (clamp&0x200 ? GL_MIRRORED_REPEAT : GL_REPEAT));
    if(target==GL_TEXTURE_3D) glTexParameteri(target, GL_TEXTURE_WRAP_R, clamp&4 ? GL_CLAMP_TO_EDGE : (clamp&0x400 ? GL_MIRRORED_REPEAT : GL_REPEAT));
    if(target==GL_TEXTURE_2D && hasAF && min(aniso, hwmaxaniso) > 0 && filter > 1) glTexParameteri(target, GL_TEXTURE_MAX_ANISOTROPY_EXT, min(aniso, hwmaxaniso));
    glTexParameteri(target, GL_TEXTURE_MAG_FILTER, filter && bilinear ? GL_LINEAR : GL_NEAREST);
    glTexParameteri(target, GL_TEXTURE_MIN_FILTER,
        filter > 1 ?
            (trilinear ?
                (bilinear ? GL_LINEAR_MIPMAP_LINEAR : GL_NEAREST_MIPMAP_LINEAR) :
                (bilinear ? GL_LINEAR_MIPMAP_NEAREST : GL_NEAREST_MIPMAP_NEAREST)) :
            (filter && bilinear ? GL_LINEAR : GL_NEAREST));
    if(swizzle && hasTRG && hasTSW)
    {
        const GLint *mask = swizzlemask(format);
        if(mask) glTexParameteriv(target, GL_TEXTURE_SWIZZLE_RGBA, mask);
    }
}

static GLenum textype(GLenum &component, GLenum &format)
{
    GLenum type = GL_UNSIGNED_BYTE;
    switch(component)
    {
        case GL_R16F:
        case GL_R32F:
            if(!format) format = GL_RED;
            type = GL_FLOAT;
            break;

        case GL_RG16F:
        case GL_RG32F:
            if(!format) format = GL_RG;
            type = GL_FLOAT;
            break;

        case GL_RGB16F:
        case GL_RGB32F:
        case GL_R11F_G11F_B10F:
            if(!format) format = GL_RGB;
            type = GL_FLOAT;
            break;

        case GL_RGBA16F:
        case GL_RGBA32F:
            if(!format) format = GL_RGBA;
            type = GL_FLOAT;
            break;

        case GL_DEPTH_COMPONENT16:
        case GL_DEPTH_COMPONENT24:
        case GL_DEPTH_COMPONENT32:
            if(!format) format = GL_DEPTH_COMPONENT;
            break;

        case GL_DEPTH_STENCIL:
        case GL_DEPTH24_STENCIL8:
            if(!format) format = GL_DEPTH_STENCIL;
            type = GL_UNSIGNED_INT_24_8;
            break;

        case GL_R8:
        case GL_R16:
        case GL_COMPRESSED_RED:
        case GL_COMPRESSED_RED_RGTC1:
            if(!format) format = GL_RED;
            break;

        case GL_RG8:
        case GL_RG16:
        case GL_COMPRESSED_RG:
        case GL_COMPRESSED_RG_RGTC2:
            if(!format) format = GL_RG;
            break;

        case GL_R3_G3_B2:
        case GL_RGB4:
        case GL_RGB5:
        case GL_RGB8:
        case GL_RGB16:
        case GL_RGB10:
        case GL_COMPRESSED_RGB:
        case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
            if(!format) format = GL_RGB;
            break;

        case GL_RGBA2:
        case GL_RGBA4:
        case GL_RGB5_A1:
        case GL_RGBA8:
        case GL_RGBA16:
        case GL_RGB10_A2:
        case GL_COMPRESSED_RGBA:
        case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:
        case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:
        case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT:
            if(!format) format = GL_RGBA;
            break;

        case GL_LUMINANCE8:
        case GL_LUMINANCE16:
        case GL_COMPRESSED_LUMINANCE:
        case GL_COMPRESSED_LUMINANCE_LATC1_EXT:
            if(!format) format = GL_LUMINANCE;
            break;

        case GL_LUMINANCE8_ALPHA8:
        case GL_LUMINANCE16_ALPHA16:
        case GL_COMPRESSED_LUMINANCE_ALPHA:
        case GL_COMPRESSED_LUMINANCE_ALPHA_LATC2_EXT:
            if(!format) format = GL_LUMINANCE_ALPHA;
            break;

        case GL_ALPHA8:
        case GL_COMPRESSED_ALPHA:
            if(!format) format = GL_ALPHA;
            break;

        case GL_RGB8UI:
        case GL_RGB16UI:
        case GL_RGB32UI:
        case GL_RGB8I:
        case GL_RGB16I:
        case GL_RGB32I:
            if(!format) format = GL_RGB_INTEGER;
            break;

        case GL_RGBA8UI:
        case GL_RGBA16UI:
        case GL_RGBA32UI:
        case GL_RGBA8I:
        case GL_RGBA16I:
        case GL_RGBA32I:
            if(!format) format = GL_RGBA_INTEGER;
            break;

        case GL_R8UI:
        case GL_R16UI:
        case GL_R32UI:
        case GL_R8I:
        case GL_R16I:
        case GL_R32I:
            if(!format) format = GL_RED_INTEGER;
            break;

        case GL_RG8UI:
        case GL_RG16UI:
        case GL_RG32UI:
        case GL_RG8I:
        case GL_RG16I:
        case GL_RG32I:
            if(!format) format = GL_RG_INTEGER;
            break;
    }
    if(!format) format = component;
    return type;
}

void createtexture(int tnum, int w, int h, const void *pixels, int clamp, int filter, GLenum component, GLenum subtarget, int pw, int ph, int pitch, bool resize, GLenum format, bool swizzle)
{
    GLenum target = textarget(subtarget), type = textype(component, format);
    if(tnum) setuptexparameters(tnum, pixels, clamp, filter, format, target, swizzle);
    if(!pw) pw = w;
    if(!ph) ph = h;
    int tw = w, th = h;
    bool mipmap = filter > 1;
    if(resize && pixels)
    {
        resizetexture(w, h, mipmap, false, target, 0, tw, th);
        if(mipmap) component = compressedformat(component, tw, th);
    }
    uploadtexture(subtarget, component, tw, th, format, type, pixels, pw, ph, pitch, mipmap);
}

void createcompressedtexture(int tnum, int w, int h, const uchar *data, int align, int blocksize, int levels, int clamp, int filter, GLenum format, GLenum subtarget, bool swizzle = false)
{
    GLenum target = textarget(subtarget);
    if(tnum) setuptexparameters(tnum, data, clamp, filter, format, target, swizzle);
    uploadcompressedtexture(target, subtarget, format, w, h, data, align, blocksize, levels, filter > 1);
}

void create3dtexture(int tnum, int w, int h, int d, const void *pixels, int clamp, int filter, GLenum component, GLenum target, bool swizzle)
{
    GLenum format = GL_FALSE, type = textype(component, format);
    if(tnum) setuptexparameters(tnum, pixels, clamp, filter, format, target, swizzle);
    glTexImage3D_(target, 0, component, w, h, d, 0, format, type, pixels);
}


hashnameset<Texture> textures;

Texture *notexture = NULL; // used as default, ensured to be loaded

static GLenum texformat(int bpp)
{
    switch(bpp)
    {
        case 1: return hasTRG ? GL_RED : GL_LUMINANCE;
        case 2: return hasTRG ? GL_RG : GL_LUMINANCE_ALPHA;
        case 3: return GL_RGB;
        case 4: return GL_RGBA;
        default: return 0;
    }
}

static bool alphaformat(GLenum format)
{
    switch(format)
    {
        case GL_ALPHA:
        case GL_LUMINANCE_ALPHA:
        case GL_RG:
        case GL_RGBA:
            return true;
        default:
            return false;
    }
}

int texalign(const void *data, int w, int bpp)
{
    size_t address = size_t(data) | (w*bpp);
    if(address&1) return 1;
    if(address&2) return 2;
    if(address&4) return 4;
    return 8;
}

bool floatformat(GLenum format)
{
    switch(format)
    {
        case GL_R16F:
        case GL_R32F:
        case GL_RG16F:
        case GL_RG32F:
        case GL_RGB16F:
        case GL_RGB32F:
        case GL_R11F_G11F_B10F:
        case GL_RGBA16F:
        case GL_RGBA32F:
            return true;
        default:
            return false;
    }
}

static Texture *newtexture(Texture *t, const char *rname, ImageData &s, int clamp = 0, bool mipit = true, bool canreduce = false, bool transient = false, int compress = 0)
{
    if(!t)
    {
        char *key = newstring(rname);
        t = &textures[key];
        t->name = key;
    }

    t->clamp = clamp;
    t->mipmap = mipit;
    t->type = Texture::IMAGE;
    if(transient) t->type |= Texture::TRANSIENT;
    if(!s.data)
    {
        t->type |= Texture::STUB;
        t->w = t->h = t->xs = t->ys = t->bpp = 0;
        return t;
    }
    GLenum format;
    if(s.compressed)
    {
        format = uncompressedformat(s.compressed);
        t->bpp = formatsize(format);
        t->type |= Texture::COMPRESSED;
    }
    else
    {
        format = texformat(s.bpp);
        t->bpp = s.bpp;
    }
    if(alphaformat(format)) t->type |= Texture::ALPHA;
    t->w = t->xs = s.w;
    t->h = t->ys = s.h;

    int filter = !canreduce || reducefilter ? (mipit ? 2 : 1) : 0;
    bool swizzle = !(clamp&0x10000);
    glGenTextures(1, &t->id);
    if(s.compressed)
    {
        uchar *data = s.data;
        int levels = s.levels, level = 0;
        if(canreduce && texreduce) loopi(min(texreduce, s.levels-1))
        {
            data += s.calclevelsize(level++);
            levels--;
            if(t->w > 1) t->w /= 2;
            if(t->h > 1) t->h /= 2;
        }
        int sizelimit = mipit && maxtexsize ? min(maxtexsize, hwtexsize) : hwtexsize;
        while(t->w > sizelimit || t->h > sizelimit)
        {
            data += s.calclevelsize(level++);
            levels--;
            if(t->w > 1) t->w /= 2;
            if(t->h > 1) t->h /= 2;
        }
        createcompressedtexture(t->id, t->w, t->h, data, s.align, s.bpp, levels, clamp, filter, s.compressed, GL_TEXTURE_2D, swizzle);
    }
    else
    {
        resizetexture(t->w, t->h, mipit, canreduce, GL_TEXTURE_2D, compress, t->w, t->h);
        GLenum component = compressedformat(format, t->w, t->h, compress);
        createtexture(t->id, t->w, t->h, s.data, clamp, filter, component, GL_TEXTURE_2D, t->xs, t->ys, s.pitch, false, format, swizzle);
    }
    return t;
}

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
#define RGBAMASKS 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff
#define RGBMASKS  0xff0000, 0x00ff00, 0x0000ff, 0
#else
#define RGBAMASKS 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000
#define RGBMASKS  0x0000ff, 0x00ff00, 0xff0000, 0
#endif

SDL_Surface *wrapsurface(void *data, int width, int height, int bpp)
{
    switch(bpp)
    {
        case 3: return SDL_CreateRGBSurfaceFrom(data, width, height, 8*bpp, bpp*width, RGBMASKS);
        case 4: return SDL_CreateRGBSurfaceFrom(data, width, height, 8*bpp, bpp*width, RGBAMASKS);
    }
    return NULL;
}

SDL_Surface *creatergbsurface(SDL_Surface *os)
{
    SDL_Surface *ns = SDL_CreateRGBSurface(SDL_SWSURFACE, os->w, os->h, 24, RGBMASKS);
    if(ns) SDL_BlitSurface(os, NULL, ns, NULL);
    SDL_FreeSurface(os);
    return ns;
}

SDL_Surface *creatergbasurface(SDL_Surface *os)
{
    SDL_Surface *ns = SDL_CreateRGBSurface(SDL_SWSURFACE, os->w, os->h, 32, RGBAMASKS);
    if(ns)
    {
        SDL_SetSurfaceBlendMode(os, SDL_BLENDMODE_NONE);
        SDL_BlitSurface(os, NULL, ns, NULL);
    }
    SDL_FreeSurface(os);
    return ns;
}

bool checkgrayscale(SDL_Surface *s)
{
    // gray scale images have 256 levels, no colorkey, and the palette is a ramp
    if(s->format->palette)
    {
        if(s->format->palette->ncolors != 256 || SDL_GetColorKey(s, NULL) >= 0) return false;
        const SDL_Color *colors = s->format->palette->colors;
        loopi(256) if(colors[i].r != i || colors[i].g != i || colors[i].b != i) return false;
    }
    return true;
}

SDL_Surface *fixsurfaceformat(SDL_Surface *s)
{
    if(!s) return NULL;
    if(!s->pixels || min(s->w, s->h) <= 0 || s->format->BytesPerPixel <= 0)
    {
        SDL_FreeSurface(s);
        return NULL;
    }
    static const uint rgbmasks[] = { RGBMASKS }, rgbamasks[] = { RGBAMASKS };
    switch(s->format->BytesPerPixel)
    {
        case 1:
            if(!checkgrayscale(s)) return SDL_GetColorKey(s, NULL) >= 0 ? creatergbasurface(s) : creatergbsurface(s);
            break;
        case 3:
            if(s->format->Rmask != rgbmasks[0] || s->format->Gmask != rgbmasks[1] || s->format->Bmask != rgbmasks[2])
                return creatergbsurface(s);
            break;
        case 4:
            if(s->format->Rmask != rgbamasks[0] || s->format->Gmask != rgbamasks[1] || s->format->Bmask != rgbamasks[2] || s->format->Amask != rgbamasks[3])
                return s->format->Amask ? creatergbasurface(s) : creatergbsurface(s);
            break;
    }
    return s;
}

void texflip(ImageData &s)
{
    ImageData d(s.w, s.h, s.bpp);
    uchar *dst = d.data, *src = &s.data[s.pitch*s.h];
    loopi(s.h)
    {
        src -= s.pitch;
        memcpy(dst, src, s.bpp*s.w);
        dst += d.pitch;
    }
    s.replace(d);
}

void texnormal(ImageData &s, int emphasis)
{
    ImageData d(s.w, s.h, 3);
    uchar *src = s.data, *dst = d.data;
    loop(y, s.h) loop(x, s.w)
    {
        vec normal(0.0f, 0.0f, 255.0f/emphasis);
        normal.x += src[y*s.pitch + ((x+s.w-1)%s.w)*s.bpp];
        normal.x -= src[y*s.pitch + ((x+1)%s.w)*s.bpp];
        normal.y += src[((y+s.h-1)%s.h)*s.pitch + x*s.bpp];
        normal.y -= src[((y+1)%s.h)*s.pitch + x*s.bpp];
        normal.normalize();
        *dst++ = uchar(127.5f + normal.x*127.5f);
        *dst++ = uchar(127.5f + normal.y*127.5f);
        *dst++ = uchar(127.5f + normal.z*127.5f);
    }
    s.replace(d);
}

template<int n, int bpp, bool normals>
static void blurtexture(int w, int h, uchar *dst, const uchar *src, int margin)
{
    static const int weights3x3[9] =
    {
        0x10, 0x20, 0x10,
        0x20, 0x40, 0x20,
        0x10, 0x20, 0x10
    };
    static const int weights5x5[25] =
    {
        0x05, 0x05, 0x09, 0x05, 0x05,
        0x05, 0x0A, 0x14, 0x0A, 0x05,
        0x09, 0x14, 0x28, 0x14, 0x09,
        0x05, 0x0A, 0x14, 0x0A, 0x05,
        0x05, 0x05, 0x09, 0x05, 0x05
    };
    const int *mat = n > 1 ? weights5x5 : weights3x3;
    int mstride = 2*n + 1,
        mstartoffset = n*(mstride + 1),
        stride = bpp*w,
        startoffset = n*bpp,
        nextoffset1 = stride + mstride*bpp,
        nextoffset2 = stride - mstride*bpp;
    src += margin*(stride + bpp);
    for(int y = margin; y < h-margin; y++)
    {
        for(int x = margin; x < w-margin; x++)
        {
            int dr = 0, dg = 0, db = 0;
            const uchar *p = src - startoffset;
            const int *m = mat + mstartoffset;
            for(int t = y; t >= y-n; t--, p -= nextoffset1, m -= mstride)
            {
                if(t < 0) p += stride;
                int a = 0;
                if(n > 1) { a += m[-2]; if(x >= 2) { dr += p[0] * a; dg += p[1] * a; db += p[2] * a; a = 0; } p += bpp; }
                a += m[-1]; if(x >= 1) { dr += p[0] * a; dg += p[1] * a; db += p[2] * a; a = 0; } p += bpp;
                int cr = p[0], cg = p[1], cb = p[2]; a += m[0]; dr += cr * a; dg += cg * a; db += cb * a; p += bpp;
                if(x+1 < w) { cr = p[0]; cg = p[1]; cb = p[2]; } dr += cr * m[1]; dg += cg * m[1]; db += cb * m[1]; p += bpp;
                if(n > 1) { if(x+2 < w) { cr = p[0]; cg = p[1]; cb = p[2]; } dr += cr * m[2]; dg += cg * m[2]; db += cb * m[2]; p += bpp; }
            }
            p = src - startoffset + stride;
            m = mat + mstartoffset + mstride;
            for(int t = y+1; t <= y+n; t++, p += nextoffset2, m += mstride)
            {
                if(t >= h) p -= stride;
                int a = 0;
                if(n > 1) { a += m[-2]; if(x >= 2) { dr += p[0] * a; dg += p[1] * a; db += p[2] * a; a = 0; } p += bpp; }
                a += m[-1]; if(x >= 1) { dr += p[0] * a; dg += p[1] * a; db += p[2] * a; a = 0; } p += bpp;
                int cr = p[0], cg = p[1], cb = p[2]; a += m[0]; dr += cr * a; dg += cg * a; db += cb * a; p += bpp;
                if(x+1 < w) { cr = p[0]; cg = p[1]; cb = p[2]; } dr += cr * m[1]; dg += cg * m[1]; db += cb * m[1]; p += bpp;
                if(n > 1) { if(x+2 < w) { cr = p[0]; cg = p[1]; cb = p[2]; } dr += cr * m[2]; dg += cg * m[2]; db += cb * m[2]; p += bpp; }
            }
            if(normals)
            {
                vec v(dr-0x7F80, dg-0x7F80, db-0x7F80);
                float mag = 127.5f/v.magnitude();
                dst[0] = uchar(v.x*mag + 127.5f);
                dst[1] = uchar(v.y*mag + 127.5f);
                dst[2] = uchar(v.z*mag + 127.5f);
            }
            else
            {
                dst[0] = dr>>8;
                dst[1] = dg>>8;
                dst[2] = db>>8;
            }
            if(bpp > 3) dst[3] = src[3];
            dst += bpp;
            src += bpp;
        }
        src += 2*margin*bpp;
    }
}

void blurtexture(int n, int bpp, int w, int h, uchar *dst, const uchar *src, int margin)
{
    switch((clamp(n, 1, 2)<<4) | bpp)
    {
        case 0x13: blurtexture<1, 3, false>(w, h, dst, src, margin); break;
        case 0x23: blurtexture<2, 3, false>(w, h, dst, src, margin); break;
        case 0x14: blurtexture<1, 4, false>(w, h, dst, src, margin); break;
        case 0x24: blurtexture<2, 4, false>(w, h, dst, src, margin); break;
    }
}

void blurnormals(int n, int w, int h, bvec *dst, const bvec *src, int margin)
{
    switch(clamp(n, 1, 2))
    {
        case 1: blurtexture<1, 3, true>(w, h, dst->v, src->v, margin); break;
        case 2: blurtexture<2, 3, true>(w, h, dst->v, src->v, margin); break;
    }
}

void texblur(ImageData &s, int n, int r)
{
    if(s.bpp < 3) return;
    loopi(r)
    {
        ImageData d(s.w, s.h, s.bpp);
        blurtexture(n, s.bpp, s.w, s.h, d.data, s.data);
        s.replace(d);
    }
}

void scaleimage(ImageData &s, int w, int h)
{
    ImageData d(w, h, s.bpp);
    scaletexture(s.data, s.w, s.h, s.bpp, s.pitch, d.data, w, h);
    s.replace(d);
}

#define readwritergbtex(t, s, body) \
    { \
        if(t.bpp >= 3) readwritetex(t, s, body); \
        else \
        { \
            ImageData rgb(t.w, t.h, 3); \
            read2writetex(rgb, t, orig, s, src, { dst[0] = dst[1] = dst[2] = orig[0]; body; }); \
            t.replace(rgb); \
        } \
    }

void forcergbimage(ImageData &s)
{
    if(s.bpp >= 3) return;
    ImageData d(s.w, s.h, 3);
    readwritetex(d, s, { dst[0] = dst[1] = dst[2] = src[0]; });
    s.replace(d);
}

#define readwritergbatex(t, s, body) \
    { \
        if(t.bpp >= 4) { readwritetex(t, s, body); } \
        else \
        { \
            ImageData rgba(t.w, t.h, 4); \
            if(t.bpp==3) read2writetex(rgba, t, orig, s, src, { dst[0] = orig[0]; dst[1] = orig[1]; dst[2] = orig[2]; body; }); \
            else read2writetex(rgba, t, orig, s, src, { dst[0] = dst[1] = dst[2] = orig[0]; body; }); \
            t.replace(rgba); \
        } \
    }

void forcergbaimage(ImageData &s)
{
    if(s.bpp >= 4) return;
    ImageData d(s.w, s.h, 4);
    if(s.bpp==3) readwritetex(d, s, { dst[0] = src[0]; dst[1] = src[1]; dst[2] = src[2]; });
    else readwritetex(d, s, { dst[0] = dst[1] = dst[2] = src[0]; });
    s.replace(d);
}

void swizzleimage(ImageData &s)
{
    if(s.bpp==2)
    {
        ImageData d(s.w, s.h, 4);
        readwritetex(d, s, { dst[0] = dst[1] = dst[2] = src[0]; dst[3] = src[1]; });
        s.replace(d);
    }
    else if(s.bpp==1)
    {
        ImageData d(s.w, s.h, 3);
        readwritetex(d, s, { dst[0] = dst[1] = dst[2] = src[0]; });
        s.replace(d);
    }
}

bool canloadsurface(const char *name)
{
    stream *f = openfile(name, "rb");
    if(!f) return false;
    delete f;
    return true;
}

/* OF: extension checking */
SDL_Surface *loadsurface(const char *name)
{
    /* use explicit extension for the other formats */
    const char *exts[] = { "", ".png", ".jpg" };
    SDL_Surface *s = NULL;
    string buf;
    loopi(sizeof(exts) / sizeof(char*)) {
        formatstring(buf, "%s%s", name, exts[i]);
        stream *z = openzipfile(buf, "rb");
        if (z) {
            SDL_RWops *rw = z->rwops();
            if (rw) {
                s = IMG_Load_RW(rw, 0);
                SDL_FreeRW(rw);
            }
            delete z;
        }
        if (!s) s = IMG_Load(findfile(buf, "rb"));
        if ( s) break;
    }
    return fixsurfaceformat(s);
}

static vec parsevec(const char *arg)
{
    vec v(0, 0, 0);
    int i = 0;
    for(; arg[0] && (!i || arg[0]=='/') && i<3; arg += strcspn(arg, "/,><"), i++)
    {
        if(i) arg++;
        v[i] = atof(arg);
    }
    if(i==1) v.y = v.z = v.x;
    return v;
}

VAR(usedds, 0, 1, 1);
VAR(dbgdds, 0, 0, 1);

static bool texturedata(ImageData &d, const char *tname, Slot::Tex *tex = NULL, bool msg = true, int *compress = NULL, int *wrap = NULL)
{
    const char *cmds = NULL, *file = tname;

    if(!tname)
    {
        if(!tex) return false;
        if(tex->name[0]=='<')
        {
            cmds = tex->name;
            file = strrchr(tex->name, '>');
            if(!file) { if(msg) conoutf(CON_ERROR, "could not load texture media/%s", tex->name); return false; }
            file++;
        }
        else file = tex->name;

        static string pname;
        formatstring(pname, "media/texture/%s", file);
        file = path(pname);
    }
    else if(tname[0]=='<')
    {
        cmds = tname;
        file = strrchr(tname, '>');
        if(!file) { if(msg) conoutf(CON_ERROR, "could not load texture %s", tname); return NULL; }
        file++;
    }

    bool raw = !usedds || !compress, dds = false;
    for(const char *pcmds = cmds; pcmds;)
    {
        #define PARSETEXCOMMANDS(cmds) \
            const char *cmd = NULL, *end = NULL, *arg[4] = { NULL, NULL, NULL, NULL }; \
            cmd = &cmds[1]; \
            end = strchr(cmd, '>'); \
            if(!end) break; \
            cmds = strchr(cmd, '<'); \
            size_t len = strcspn(cmd, ":,><"); \
            loopi(4) \
            { \
                arg[i] = strchr(i ? arg[i-1] : cmd, i ? ',' : ':'); \
                if(!arg[i] || arg[i] >= end) arg[i] = ""; \
                else arg[i]++; \
            }
        PARSETEXCOMMANDS(pcmds);
        if(!strncmp(cmd, "dds", len)) dds = true;
        else if(!strncmp(cmd, "thumbnail", len)) raw = true;
        else if(!strncmp(cmd, "stub", len)) return canloadsurface(file);
    }

    if(msg) renderprogress(loadprogress, file);

    int flen = strlen(file);
    if(flen >= 4 && (!strcasecmp(file + flen - 4, ".dds") || dds))
    {
        string dfile;
        copystring(dfile, file);
        memcpy(dfile + flen - 4, ".dds", 4);
        if(!raw && hasS3TC && loaddds(dfile, d)) return true;
        if(!dds || dbgdds) { if(msg) conoutf(CON_ERROR, "could not load texture %s", dfile); return false; }
    }

    SDL_Surface *s = loadsurface(file);
    if(!s) { if(msg) conoutf(CON_ERROR, "could not load texture %s", file); return false; }
    int bpp = s->format->BitsPerPixel;
    if(bpp%8 || !texformat(bpp/8)) { SDL_FreeSurface(s); conoutf(CON_ERROR, "texture must be 8, 16, 24, or 32 bpp: %s", file); return false; }
    if(max(s->w, s->h) > (1<<12)) { SDL_FreeSurface(s); conoutf(CON_ERROR, "texture size exceeded %dx%d pixels: %s", 1<<12, 1<<12, file); return false; }
    d.wrap(s);

    while(cmds)
    {
        PARSETEXCOMMANDS(cmds);
        if(!strncmp(cmd, "mad", len)) texmad(d, parsevec(arg[0]), parsevec(arg[1]));
        else if(!strncmp(cmd, "colorify", len)) texcolorify(d, parsevec(arg[0]), parsevec(arg[1]));
        else if(!strncmp(cmd, "colormask", len)) texcolormask(d, parsevec(arg[0]), *arg[1] ? parsevec(arg[1]) : vec(1, 1, 1));
        else if(!strncmp(cmd, "normal", len))
        {
            int emphasis = atoi(arg[0]);
            texnormal(d, emphasis > 0 ? emphasis : 3);
        }
        else if(!strncmp(cmd, "dup", len)) texdup(d, atoi(arg[0]), atoi(arg[1]));
        else if(!strncmp(cmd, "offset", len)) texoffset(d, atoi(arg[0]), atoi(arg[1]));
        else if(!strncmp(cmd, "rotate", len)) texrotate(d, atoi(arg[0]), tex ? tex->type : 0);
        else if(!strncmp(cmd, "reorient", len)) texreorient(d, atoi(arg[0])>0, atoi(arg[1])>0, atoi(arg[2])>0, tex ? tex->type : TEX_DIFFUSE);
        else if(!strncmp(cmd, "mix", len)) texmix(d, *arg[0] ? atoi(arg[0]) : -1, *arg[1] ? atoi(arg[1]) : -1, *arg[2] ? atoi(arg[2]) : -1, *arg[3] ? atoi(arg[3]) : -1);
        else if(!strncmp(cmd, "grey", len)) texgrey(d);
        else if(!strncmp(cmd, "blur", len))
        {
            int emphasis = atoi(arg[0]), repeat = atoi(arg[1]);
            texblur(d, emphasis > 0 ? clamp(emphasis, 1, 2) : 1, repeat > 0 ? repeat : 1);
        }
        else if(!strncmp(cmd, "premul", len)) texpremul(d);
        else if(!strncmp(cmd, "agrad", len)) texagrad(d, atof(arg[0]), atof(arg[1]), atof(arg[2]), atof(arg[3]));
        else if(!strncmp(cmd, "compress", len) || !strncmp(cmd, "dds", len))
        {
            int scale = atoi(arg[0]);
            if(scale <= 0) scale = 2;
            if(compress) *compress = scale;
        }
        else if(!strncmp(cmd, "nocompress", len))
        {
            if(compress) *compress = -1;
        }
        else if(!strncmp(cmd, "mirror", len))
        {
            if(wrap) *wrap |= 0x300;
        }
        else if(!strncmp(cmd, "noswizzle", len))
        {
            if(wrap) *wrap |= 0x10000;
        }
        else if(!strncmp(cmd, "thumbnail", len))
        {
            int w = atoi(arg[0]), h = atoi(arg[1]);
            if(w <= 0 || w > (1<<12)) w = 64;
            if(h <= 0 || h > (1<<12)) h = w;
            if(d.w > w || d.h > h) scaleimage(d, w, h);
        }
    }

    return true;
}

uchar *loadalphamask(Texture *t)
{
    if(t->alphamask) return t->alphamask;
    if((t->type&(Texture::ALPHA|Texture::COMPRESSED)) != Texture::ALPHA) return NULL;
    ImageData s;
    if(!texturedata(s, t->name, NULL, false) || !s.data || s.compressed) return NULL;
    t->alphamask = new uchar[s.h * ((s.w+7)/8)];
    uchar *srcrow = s.data, *dst = t->alphamask-1;
    loop(y, s.h)
    {
        uchar *src = srcrow+s.bpp-1;
        loop(x, s.w)
        {
            int offset = x%8;
            if(!offset) *++dst = 0;
            if(*src) *dst |= 1<<offset;
            src += s.bpp;
        }
        srcrow += s.pitch;
    }
    return t->alphamask;
}

Texture *textureload(const char *name, int clamp, bool mipit, bool msg)
{
    string tname;
    copystring(tname, name);
    Texture *t = textures.access(path(tname));
    if(t) return t;
    int compress = 0;
    ImageData s;
    if(texturedata(s, tname, NULL, msg, &compress, &clamp)) return newtexture(NULL, tname, s, clamp, mipit, false, false, compress);
    return notexture;
}

bool settexture(const char *name, int clamp)
{
    Texture *t = textureload(name, clamp, true, false);
    glBindTexture(GL_TEXTURE_2D, t->id);
    return t != notexture;
}

vector<VSlot *> vslots;
vector<Slot *> slots;
MSlot materialslots[(MATF_VOLUME|MATF_INDEX)+1];
Slot dummyslot;
VSlot dummyvslot(&dummyslot);

static bool texpackloading = false; /* OF */

void texturereset(int *n)
{
    if(!(identflags&IDF_OVERRIDDEN) && !game::allowedittoggle()) return;
    if(texpackloading) return;
    resetslotshader();
    int limit = clamp(*n, 0, slots.length());
    for(int i = limit; i < slots.length(); i++)
    {
        Slot *s = slots[i];
        for(VSlot *vs = s->variants; vs; vs = vs->next) vs->slot = &dummyslot;
        delete s;
    }
    slots.setsize(limit);
    void clear_texpacks(int n); clear_texpacks(limit);
}

COMMAND(texturereset, "i");

void materialreset(const char *type)
{
    if(!(identflags&IDF_OVERRIDDEN) && !game::allowedittoggle()) return;
    if (type[0]) {
        int matslot = findmaterial(type);
        if (matslot >= 0) {
            materialslots[matslot].reset();
            return;
        }
    }
    loopi((MATF_VOLUME|MATF_INDEX)+1) materialslots[i].reset();
}

COMMAND(materialreset, "s");

static int compactedvslots = 0, compactvslotsprogress = 0, clonedvslots = 0;
static bool markingvslots = false;

void clearslots()
{
    resetslotshader();
    slots.deletecontents();
    vslots.deletecontents();
    loopi((MATF_VOLUME|MATF_INDEX)+1) materialslots[i].reset();
    clonedvslots = 0;
}

static void assignvslot(VSlot &vs);

static inline void assignvslotlayer(VSlot &vs)
{
    if(vs.layer && vslots.inrange(vs.layer))
    {
        VSlot &layer = *vslots[vs.layer];
        if(layer.index < 0) assignvslot(layer);
    }
}

static void assignvslot(VSlot &vs)
{
    vs.index = compactedvslots++;
    assignvslotlayer(vs);
}

void compactvslot(int &index)
{
    if(vslots.inrange(index))
    {
        VSlot &vs = *vslots[index];
        if(vs.index < 0) assignvslot(vs);
        if(!markingvslots) index = vs.index;
    }
}

void compactvslots(cube *c, int n)
{
    if((compactvslotsprogress++&0xFFF)==0) renderprogress(min(float(compactvslotsprogress)/allocnodes, 1.0f), markingvslots ? "marking slots..." : "compacting slots...");
    loopi(n)
    {
        if(c[i].children) compactvslots(c[i].children);
        else loopj(6) if(vslots.inrange(c[i].texture[j]))
        {
            VSlot &vs = *vslots[c[i].texture[j]];
            if(vs.index < 0) assignvslot(vs);
            if(!markingvslots) c[i].texture[j] = vs.index;
        }
    }
}

int compactvslots(bool cull)
{
    clonedvslots = 0;
    markingvslots = cull;
    compactedvslots = 0;
    compactvslotsprogress = 0;
    loopv(vslots) vslots[i]->index = -1;
    if(cull)
    {
        void clear_texpacks(int n); clear_texpacks(0); /* OF */
        int numdefaults = min(int(NUMDEFAULTSLOTS), slots.length());
        loopi(numdefaults) slots[i]->variants->index = compactedvslots++;
        loopi(numdefaults) assignvslotlayer(*slots[i]->variants);
    }
    else
    {
        loopv(slots) slots[i]->variants->index = compactedvslots++;
        loopv(slots) assignvslotlayer(*slots[i]->variants);
        loopv(vslots)
        {
            VSlot &vs = *vslots[i];
            if(!vs.changed && vs.index < 0) { markingvslots = true; break; }
        }
    }
    compactvslots(worldroot);
    int total = compactedvslots;
    compacteditvslots();
    loopv(vslots)
    {
        VSlot *vs = vslots[i];
        if(vs->changed) continue;
        while(vs->next)
        {
            if(vs->next->index < 0) vs->next = vs->next->next;
            else vs = vs->next;
        }
    }
    if(markingvslots)
    {
        markingvslots = false;
        compactedvslots = 0;
        compactvslotsprogress = 0;
        int lastdiscard = 0;
        loopv(vslots)
        {
            VSlot &vs = *vslots[i];
            if(vs.changed || (vs.index < 0 && !vs.next)) vs.index = -1;
            else
            {
                if(!cull) while(lastdiscard < i)
                {
                    VSlot &ds = *vslots[lastdiscard++];
                    if(!ds.changed && ds.index < 0) ds.index = compactedvslots++;
                }
                vs.index = compactedvslots++;
            }
        }
        compactvslots(worldroot);
        total = compactedvslots;
        compacteditvslots();
    }
    compactmruvslots();
    loopv(vslots)
    {
        VSlot &vs = *vslots[i];
        if(vs.index >= 0 && vs.layer && vslots.inrange(vs.layer)) vs.layer = vslots[vs.layer]->index;
    }
    if(cull)
    {
        loopvrev(slots) if(slots[i]->variants->index < 0) delete slots.remove(i);
        loopv(slots) slots[i]->index = i;
    }
    loopv(vslots)
    {
        while(vslots[i]->index >= 0 && vslots[i]->index != i)
            swap(vslots[i], vslots[vslots[i]->index]);
    }
    for(int i = compactedvslots; i < vslots.length(); i++) delete vslots[i];
    vslots.setsize(compactedvslots);
    return total;
}

ICOMMAND(compactvslots, "i", (int *cull),
{
    extern int nompedit;
    if(nompedit && multiplayer()) return;
    compactvslots(*cull!=0);
    allchanged();
});

static Slot &loadslot(Slot &s, bool forceload);

static void clampvslotoffset(VSlot &dst, Slot *slot = NULL)
{
    if(!slot) slot = dst.slot;
    if(slot && slot->sts.inrange(0))
    {
        if(!slot->loaded) loadslot(*slot, false);
        int xs = slot->sts[0].t->xs, ys = slot->sts[0].t->ys;
        if((dst.rotation&5)==1) swap(xs, ys);
        dst.offset.x %= xs; if(dst.offset.x < 0) dst.offset.x += xs;
        dst.offset.y %= ys; if(dst.offset.y < 0) dst.offset.y += ys;
    }
    else dst.offset.max(0);
}

static void propagatevslot(VSlot &dst, const VSlot &src, int diff, bool edit = false)
{
    if(diff & (1<<VSLOT_SHPARAM)) loopv(src.params) dst.params.add(src.params[i]);
    if(diff & (1<<VSLOT_SCALE)) dst.scale = src.scale;
    if(diff & (1<<VSLOT_ROTATION))
    {
        dst.rotation = src.rotation;
        if(edit && !dst.offset.iszero()) clampvslotoffset(dst);
    }
    if(diff & (1<<VSLOT_OFFSET))
    {
        dst.offset = src.offset;
        if(edit) clampvslotoffset(dst);
    }
    if(diff & (1<<VSLOT_SCROLL)) dst.scroll = src.scroll;
    if(diff & (1<<VSLOT_LAYER)) dst.layer = src.layer;
    if(diff & (1<<VSLOT_ALPHA))
    {
        dst.alphafront = src.alphafront;
        dst.alphaback = src.alphaback;
    }
    if(diff & (1<<VSLOT_COLOR)) dst.colorscale = src.colorscale;
    if(diff & (1<<VSLOT_REFRACT))
    {
        dst.refractscale = src.refractscale;
        dst.refractcolor = src.refractcolor;
    }
    if(diff & (1<<VSLOT_DECAL)) dst.decal = src.decal;
}

static void propagatevslot(VSlot *root, int changed)
{
    for(VSlot *vs = root->next; vs; vs = vs->next)
    {
        int diff = changed & ~vs->changed;
        if(diff) propagatevslot(*vs, *root, diff);
    }
}

static void mergevslot(VSlot &dst, const VSlot &src, int diff, Slot *slot = NULL)
{
    if(diff & (1<<VSLOT_SHPARAM)) loopv(src.params)
    {
        const SlotShaderParam &sp = src.params[i];
        loopvj(dst.params)
        {
            SlotShaderParam &dp = dst.params[j];
            if(sp.name == dp.name)
            {
                memcpy(dp.val, sp.val, sizeof(dp.val));
                goto nextparam;
            }
        }
        dst.params.add(sp);
    nextparam:;
    }
    if(diff & (1<<VSLOT_SCALE))
    {
        dst.scale = clamp(dst.scale*src.scale, 1/8.0f, 8.0f);
    }
    if(diff & (1<<VSLOT_ROTATION))
    {
        dst.rotation = clamp(dst.rotation + src.rotation, 0, 5);
        if(!dst.offset.iszero()) clampvslotoffset(dst, slot);
    }
    if(diff & (1<<VSLOT_OFFSET))
    {
        dst.offset.add(src.offset);
        clampvslotoffset(dst, slot);
    }
    if(diff & (1<<VSLOT_SCROLL)) dst.scroll.add(src.scroll);
    if(diff & (1<<VSLOT_LAYER)) dst.layer = src.layer;
    if(diff & (1<<VSLOT_ALPHA))
    {
        dst.alphafront = src.alphafront;
        dst.alphaback = src.alphaback;
    }
    if(diff & (1<<VSLOT_COLOR)) dst.colorscale.mul(src.colorscale);
    if(diff & (1<<VSLOT_REFRACT))
    {
        dst.refractscale *= src.refractscale;
        dst.refractcolor.mul(src.refractcolor);
    }
    if(diff & (1<<VSLOT_DECAL)) dst.decal = src.decal;
}

void mergevslot(VSlot &dst, const VSlot &src, const VSlot &delta)
{
    dst.changed = src.changed | delta.changed;
    propagatevslot(dst, src, (1<<VSLOT_NUM)-1);
    mergevslot(dst, delta, delta.changed, src.slot);
}

static VSlot *reassignvslot(Slot &owner, VSlot *vs)
{
    owner.variants = vs;
    while(vs)
    {
        vs->slot = &owner;
        vs->linked = false;
        vs = vs->next;
    }
    return owner.variants;
}

/* OF */
static VSlot *emptyvslot(Slot &owner, bool &newvslot)
{
    int offset = 0;
    loopvrev(slots) if(slots[i]->variants) { offset = slots[i]->variants->index + 1; break; }
    for(int i = offset; i < vslots.length(); i++) if(!vslots[i]->changed) {
        newvslot = false;
        return reassignvslot(owner, vslots[i]);
    }
    newvslot = true;
    return vslots.add(new VSlot(&owner, vslots.length()));
}

static bool comparevslot(const VSlot &dst, const VSlot &src, int diff)
{
    if(diff & (1<<VSLOT_SHPARAM))
    {
        if(src.params.length() != dst.params.length()) return false;
        loopv(src.params)
        {
            const SlotShaderParam &sp = src.params[i], &dp = dst.params[i];
            if(sp.name != dp.name || memcmp(sp.val, dp.val, sizeof(sp.val))) return false;
        }
    }
    if(diff & (1<<VSLOT_SCALE) && dst.scale != src.scale) return false;
    if(diff & (1<<VSLOT_ROTATION) && dst.rotation != src.rotation) return false;
    if(diff & (1<<VSLOT_OFFSET) && dst.offset != src.offset) return false;
    if(diff & (1<<VSLOT_SCROLL) && dst.scroll != src.scroll) return false;
    if(diff & (1<<VSLOT_LAYER) && dst.layer != src.layer) return false;
    if(diff & (1<<VSLOT_ALPHA) && (dst.alphafront != src.alphafront || dst.alphaback != src.alphaback)) return false;
    if(diff & (1<<VSLOT_COLOR) && dst.colorscale != src.colorscale) return false;
    if(diff & (1<<VSLOT_REFRACT) && (dst.refractscale != src.refractscale || dst.refractcolor != src.refractcolor)) return false;
    if(diff & (1<<VSLOT_DECAL) && dst.decal != src.decal) return false;
    return true;
}

VSlot *findvslot(Slot &slot, const VSlot &src, const VSlot &delta)
{
    for(VSlot *dst = slot.variants; dst; dst = dst->next)
    {
        if((!dst->changed || dst->changed == (src.changed | delta.changed)) &&
           comparevslot(*dst, src, src.changed & ~delta.changed) &&
           comparevslot(*dst, delta, delta.changed))
            return dst;
    }
    return NULL;
}

static VSlot *clonevslot(const VSlot &src, const VSlot &delta)
{
    VSlot *dst = vslots.add(new VSlot(src.slot, vslots.length()));
    dst->changed = src.changed | delta.changed;
    propagatevslot(*dst, src, ((1<<VSLOT_NUM)-1) & ~delta.changed);
    propagatevslot(*dst, delta, delta.changed, true);
    return dst;
}

VARP(autocompactvslots, 0, 256, 0x10000);

VSlot *editvslot(const VSlot &src, const VSlot &delta)
{
    VSlot *exists = findvslot(*src.slot, src, delta);
    if(exists) return exists;
    if(vslots.length()>=0x10000)
    {
        compactvslots();
        allchanged();
        if(vslots.length()>=0x10000) return NULL;
    }
    if(autocompactvslots && ++clonedvslots >= autocompactvslots)
    {
        compactvslots();
        allchanged();
    }
    return clonevslot(src, delta);
}

static void fixinsidefaces(cube *c, const ivec &o, int size, int tex)
{
    loopi(8)
    {
        ivec co(i, o, size);
        if(c[i].children) fixinsidefaces(c[i].children, co, size>>1, tex);
        else loopj(6) if(!visibletris(c[i], j, co, size))
            c[i].texture[j] = tex;
    }
}

ICOMMAND(fixinsidefaces, "i", (int *tex),
{
    extern int nompedit;
    if(noedit(true) || (nompedit && multiplayer())) return;
    fixinsidefaces(worldroot, ivec(0, 0, 0), worldsize>>1, *tex && vslots.inrange(*tex) ? *tex : DEFAULT_GEOM);
    allchanged();
});

const struct slottex
{
    const char *name;
    int id;
} slottexs[] =
{
    {"0", TEX_DIFFUSE},
    {"1", TEX_UNKNOWN},

    {"c", TEX_DIFFUSE},
    {"u", TEX_UNKNOWN},
    {"n", TEX_NORMAL},
    {"g", TEX_GLOW},
    {"s", TEX_SPEC},
    {"z", TEX_DEPTH},
    {"e", TEX_ENVMAP}
};

int findslottex(const char *name)
{
    loopi(sizeof(slottexs)/sizeof(slottex))
    {
        if(!strcmp(slottexs[i].name, name)) return slottexs[i].id;
    }
    return -1;
}

/* OF: a group system */
static hashset<const char*> texgroupnames(256);

const char *get_texgroup_name(const char *name) {
    const char *group = texgroupnames.find(name, NULL);
    if (group) return group;
    return texgroupnames.add(newstring(name));
}

static const char *curtexgroup = NULL;

ICOMMAND(texgroup, "se", (char *name, uint *body), {
    const char *oldgroup = curtexgroup;
    if (oldgroup && name[0]) {
        defformatstring(tmpgroup, "%s.%s", oldgroup, name);
        curtexgroup = get_texgroup_name(tmpgroup);
    } else curtexgroup = get_texgroup_name(name);

    Shader *savedshader = NULL;
    vector<SlotShaderParam> savedparams;
    saveslotshader(savedshader, savedparams);
    execute(body);
    restoreslotshader(savedshader, savedparams);

    curtexgroup = oldgroup;
});

/* OF: a texture pack system */
struct texpack {
    texpack *prev, *next;
    char *name;
    int firstslot, nslots;
    texpack(const char *name, int firstslot): prev(NULL), next(NULL),
        name(newstring(name)), firstslot(firstslot),
        nslots(slots.length() - firstslot) {}
    ~texpack() {
        delete[] name;
    }
};

static texpack *firsttexpack = NULL, *lasttexpack = NULL;
static hashtable<const char*, texpack*> texpacks;

void clear_texpacks(int n) {
    texpack *tp = lasttexpack;
    while (tp && (!n || (tp->firstslot + tp->nslots - 1) >= n)) {
        lasttexpack = tp->prev;
        if (lasttexpack) lasttexpack->next = NULL;
        texpacks.remove(tp->name); delete tp;
        tp = lasttexpack;
    }
    if (!lasttexpack) firsttexpack = NULL;
}

static void texload(const char *pack, uint *body = NULL) {
    defformatstring(ppath, "media/texture/%s.tex", pack);
    int first = slots.length();
    bool oldloading = texpackloading;
    texpackloading = true;

    Shader *savedshader = NULL;
    vector<SlotShaderParam> savedparams;
    saveslotshader(savedshader, savedparams);
    setshader("stdworld");

    if (!body && !execfile(path(ppath), false)) {
        conoutf("could not load texture pack '%s'", pack);
        texpackloading = oldloading;
        intret(false);
        return;
    } else if (body) execute(body);

    texpackloading = oldloading;
    restoreslotshader(savedshader, savedparams);

    if (slots.length() == first) {
        conoutf("texture pack '%s' contains no slots", pack);
        intret(false);
        return;
    }
    texpack *tp = new texpack(pack, first);
    if (lasttexpack) {
        lasttexpack->next = tp;
        tp->prev = lasttexpack;
        lasttexpack = tp;
    } else lasttexpack = tp;
    if (!firsttexpack) firsttexpack = tp;
    texpacks.access(tp->name, tp);
    intret(true);
}

ICOMMAND(texpack, "se", (char *pack, uint *body), {
    if (texpackloading) return;
    if (texpacks.access(pack)) {
        conoutf("texture pack '%s' already loaded", pack);
        return;
    }
    texload(pack, body);
})

ICOMMAND(texpackload, "s", (const char *pack), {
    if (texpacks.access(pack)) {
        conoutf("texture pack '%s' already loaded", pack);
        return;
    }
    texload(pack);
});

static vector<VSlot*> saved_vslots;

static void clearslotrange(int firstslot, int nslots) {
    int tnslots = slots.length();
    for (int i = (firstslot + nslots - 1); i >= firstslot; --i) {
        Slot *s = slots[i];
        saved_vslots.add(s->variants);
        for (VSlot *vs = s->variants; vs; vs = vs->next) {
            vs->slot = &dummyslot;
        }
        delete s;
    }
    for (int i = firstslot + nslots; i < tnslots; ++i) {
        slots[i - nslots] = slots[i];
        slots[i - nslots]->index = i - nslots;
    }
    slots.setsize(tnslots - nslots);
}

static void texunload(const char *pack, texpack *tp) {
    int ncleared = tp->nslots;
    texpack *ntp = tp->next;

    clearslotrange(tp->firstslot, tp->nslots);
    if (tp->prev) tp->prev->next = tp->next;
    else firsttexpack = tp->next;
    if (tp->next) tp->next->prev = tp->prev;
    else lasttexpack = tp->prev;

    texpacks.remove(pack);
    delete tp;
    for (tp = ntp; tp; tp = tp->next) {
        tp->firstslot -= ncleared;
    }
}

ICOMMAND(texpackunload, "s", (const char *pack), {
    texpack **tpp = texpacks.access(pack);
    if (!tpp) { conoutf("texture pack '%s' is not loaded", pack); return; }
    texunload(pack, *tpp);
});

ICOMMAND(texpackreload, "s", (const char *pack), {
    texpack **tpp = texpacks.access(pack);
    if (!tpp) { conoutf("texture pack '%s' is not loaded", pack); return; }
    texunload(pack, *tpp);
    texload(pack);
});

LUAICOMMAND(texture_get_packs, {
    lua_createtable(L, texpacks.numelems, 0);
    int i = 1;
    for (texpack *tp = firsttexpack; tp; tp = tp->next) {
        lua_createtable(L, 3, 0);
        lua_pushstring (L, tp->name);      lua_rawseti(L, -2, 1);
        lua_pushinteger(L, tp->firstslot); lua_rawseti(L, -2, 2);
        lua_pushinteger(L, tp->nslots);    lua_rawseti(L, -2, 3);
        lua_rawseti(L, -2, i++);
    }
    return 1;
});

/* diffuse, normal, glow, envmap, spec, depth, unknown */
const char slotvariants[] = {
    'c', 'n', 'g', 'e', 's', 'z', 'u'
};

static void printindent(stream *f, int n) {
    for (; n > 0; --n) f->printf("    ");
}

static void dumpvslot(stream *f, const VSlot &vs, int indent) {
    if (vs.scroll.x || vs.scroll.y) {
        printindent(f, indent);
        f->printf("texscroll %f %f\n", vs.scroll.x * 1000.0f,
            vs.scroll.y * 1000.0f);
    }
    if (vs.layer) {
        printindent(f, indent);
        f->printf("texlayer %d\n", vs.layer);
    }
    if (vs.decal) {
        printindent(f, indent);
        f->printf("texdecal %d\n", vs.decal);
    }
    if (vs.alphafront != 0.5f || vs.alphaback != 0) {
        printindent(f, indent);
        f->printf("texalpha %f %f\n", vs.alphafront, vs.alphaback);
    }
    const vec &col = vs.colorscale;
    if (col.r != 1.0f || col.g != 1.0f || col.b != 1.0f) {
        printindent(f, indent);
        f->printf("texcolor %f %f %f\n", col.r, col.g, col.b);
    }
    const vec &rfc = vs.refractcolor;
    if (vs.refractscale || rfc.r != 1.0f || rfc.g != 1.0f || rfc.b != 1.0f) {
        printindent(f, indent);
        const vec &rfc = vs.refractcolor;
        f->printf("texrefract %f %f %f %f\n", vs.refractscale,
            rfc.r, rfc.g, rfc.b);
    }
}

static void dumpslot(stream *f, const Slot &s, int index, int indent) {
    if (index >= 0) {
        printindent(f, indent);
        f->printf("setshader \"%s\"\n", s.shader->name);
        loopv(s.params) {
            const SlotShaderParam &p = s.params[i];
            if (indent) printindent(f, indent);
            f->printf("setshaderparam \"%s\" %f %f %f %f\n", p.name, p.val[0],
                p.val[1], p.val[2], p.val[3]);
        }
        if (s.params.length()) f->printf("\n");
    }
    const VSlot &vs = *s.variants;
    loopv(s.sts) {
        const Slot::Tex &st = s.sts[i];
        printindent(f, indent);
        f->printf("texture ");
        if (index >= 0) {
            f->printf("%c", slotvariants[st.type]);
        } else if (!i) {
            f->printf("%s", findmaterialname(-index));
        } else {
            f->printf("1");
        }
        f->printf(" \"%s\"", st.name);
        if (st.type == TEX_DIFFUSE) {
            f->printf(" %d %d %d %f", vs.rotation, vs.offset.x, vs.offset.y,
                vs.scale);
            if (index >= 0)
                f->printf(" // %d\n", index);
            else
                f->printf("\n");
        } else f->printf("\n");
    }
    if (index >= 0) {
        if (s.grass) {
            printindent(f, indent);
            f->printf("texgrass \"%s\"\n", s.grass);
        }
        if (s.smooth >= 0) {
            extern vector<int> smoothgroups;
            printindent(f, indent);
            f->printf("texsmooth %d %d\n", s.smooth, smoothgroups[s.smooth]);
        }
        dumpvslot(f, *s.variants, indent);
    }
}

static void dumpslotrange(stream *f, int firstslot, int nslots, int indent = 0) {
    const char *lastgroup = NULL;
    bool endgroup = false;
    int nextfirstslot = firstslot + nslots;
    printindent(f, indent);
    f->printf("// slot range %d-%d\n", firstslot, nextfirstslot - 1);
    for (int i = firstslot; i < nextfirstslot; ++i) {
        renderprogress((i - firstslot) / float(nslots), "saving slots...");
        const Slot &s = *slots[i];
        int ind = indent;
        if (lastgroup != s.group) {
            if (lastgroup) {
                printindent(f, indent);
                f->printf("]\n");
                endgroup = false;
            }
            lastgroup = s.group;
            if (lastgroup) {
                printindent(f, indent);
                f->printf("texgroup \"%s\" [\n", lastgroup);
                endgroup = true;
                ++ind;
            }
        }
        dumpslot(f, s, i, ind);
        if (i != (nextfirstslot - 1)) f->printf("\n");
    }
    if (endgroup) {
        printindent(f, indent);
        f->printf("]\n");
    }
}

ICOMMAND(writemediacfg, "i", (int *level), {
    stream *f = openutf8file(world::get_mapfile_path("media.cfg"), "w");
    if (!f) return;
    f->printf("// generated automatically by writemediacfg\n\n");
    f->printf("// material slots\nmaterialreset\n\n");
    int nummat = sizeof(materialslots) / sizeof(materialslots[0]);
    loopi(nummat) {
        renderprogress(i / float(nummat), "saving material slots...");
        switch (i & MATF_VOLUME) {
            case MAT_GLASS:
            case MAT_WATER:
            case MAT_LAVA:
                dumpslot(f, materialslots[i], -i, 0);
                f->printf("\n");
                break;
        }
    }
    f->printf("// texture slots\ntexturereset\n\n");
    if (!firsttexpack) {
        dumpslotrange(f, 0, slots.length());
    } else {
        if (firsttexpack->firstslot > 0) {
            dumpslotrange(f, 0, firsttexpack->firstslot);
            f->printf("\n");
        }
        texpack *ptp = NULL;
        int i = 0;
        for (texpack *tp = firsttexpack; tp; tp = tp->next) {
            renderprogress(float(i++) / texpacks.numelems,
                "saving texture packs...");
            if (ptp) {
                int offstart = ptp->firstslot + ptp->nslots;
                if (offstart != tp->firstslot) {
                    dumpslotrange(f, offstart, tp->firstslot - offstart);
                    if (tp) f->printf("\n");
                }
            }
            f->printf("texpack \"%s\" [\n", tp->name);
            dumpslotrange(f, tp->firstslot, tp->nslots, 1);
            f->printf("]\n\n");
            ptp = tp;
        }
        if (ptp) {
            int offstart = ptp->firstslot + ptp->nslots;
            if (slots.inrange(offstart))
                dumpslotrange(f, offstart, slots.length() - offstart);
        }
    }
    int lvl = *level;
    if (lvl >= 1) {
        vector<extentity*> models;
        vector<extentity*> sounds;
        const vector<extentity*> &ents = entities::getents();
        loopv(ents) {
            renderprogress(i / float(ents.length()), "checking entities...");
            extentity *e = ents[i];
            switch (e->type) {
                case ET_MAPMODEL:
                    models.add(e);
                    break;
                case ET_SOUND:
                    if (lvl <= 1) break;
                    sounds.add(e);
                    break;
            }
        }
        if (!models.length()) goto sounds;
        f->printf("// models\n");
        loopv(models) {
            renderprogress(i / float(models.length()), "saving models...");
            const extentity &e = *models[i];
            if (e.m) f->printf("preloadmodel \"%s\"\n", e.m->name);
        }
sounds:
        if (!sounds.length()) goto none;
        f->printf("\n// sounds\n");
        lua::push_external("entity_get_attr");
        loopv(sounds) {
            renderprogress(i / float(sounds.length()), "saving sounds...");
            lua_pushvalue(lua::L, -1);
            const extentity &e = *sounds[i];

            lua_rawgeti(lua::L, LUA_REGISTRYINDEX,
                LogicSystem::getLogicEntity(e)->lua_ref);
            lua_pushliteral(lua::L, "sound_name");
            lua_call(lua::L, 2, 1);

            const char *sn = lua_tostring(lua::L, -1);
            f->printf("preloadmapsound \"%s\" %d\n", sn, e.attr[2]);
            lua_pop(lua::L, 1);
        }
        lua_pop(lua::L, 1);
none:
        delete f;
        return;
    }
    delete f;
});

static int comparevslot(const VSlot &dst, const VSlot &src) {
    int changed = 0;
    if (src.params.length() != dst.params.length())
        changed |= 1 << VSLOT_SHPARAM;
    else {
        loopv(src.params) {
            const SlotShaderParam &sp = src.params[i], &dp = dst.params[i];
            if (sp.name != dp.name || memcmp(sp.val, dp.val, sizeof(sp.val))) {
                changed |= 1 << VSLOT_SHPARAM;
                break;
            }
        }
    }
    if (dst.scale    != src.scale)    changed |= 1 << VSLOT_SCALE;
    if (dst.rotation != src.rotation) changed |= 1 << VSLOT_ROTATION;
    if (dst.offset   != src.offset)   changed |= 1 << VSLOT_OFFSET;
    if (dst.scroll   != src.scroll)   changed |= 1 << VSLOT_SCROLL;
    if (dst.layer    != src.layer)    changed |= 1 << VSLOT_LAYER;
    if (dst.decal    != src.decal)    changed |= 1 << VSLOT_DECAL;
    if (dst.alphafront != src.alphafront || dst.alphaback != src.alphaback)
        changed |= 1 << VSLOT_ALPHA;
    if (dst.colorscale != src.colorscale)
        changed |= 1 << VSLOT_COLOR;
    if (dst.refractscale != src.refractscale || dst.refractcolor != src.refractcolor)
        changed |= 1 << VSLOT_REFRACT;
    return changed;
}

void texture(char *type, char *name, int *rot, int *xoffset, int *yoffset, float *scale)
{
    if(slots.length()>=0x10000) return;
    static int lastmatslot = -1;
    int matslot = findmaterial(type);
    /* OF */
    if (type[0] != '\0' && type[1] != '\0' && matslot < 0) {
        char buf[2];
        buf[1] = '\0';
        if (type[0] == 'c' || type[0] == '0') {
            buf[0] = (type++)[0];
            texture(buf, name, rot, xoffset, yoffset, scale);
        }
        while (*type) {
            buf[0] = (type++)[0];
            /* the last 4 arguments will always be unused */
            if (buf[0] != 'c' && buf[0] != '0')
                texture(buf, (char*)"", NULL, NULL, NULL, NULL);
        }
        return;
    }
    int tnum = findslottex(type);
    if(tnum<0) tnum = matslot >= 0 ? TEX_DIFFUSE : TEX_UNKNOWN;
    if(tnum==TEX_DIFFUSE) lastmatslot = matslot;
    else if(lastmatslot>=0) matslot = lastmatslot;
    else if(slots.empty()) return;
    Slot &s = matslot>=0 ? materialslots[matslot] : *(tnum!=TEX_DIFFUSE ? slots.last() : slots.add(new Slot(slots.length())));

    s.group = curtexgroup;
    s.loaded = false;
    s.texmask |= 1<<tnum;
    if(s.sts.length()>=8) conoutf(CON_WARN, "warning: too many textures in slot %d", slots.length()-1);
    Slot::Tex &st = s.sts.add();
    st.type = tnum;
    st.combined = -1;
    st.t = NULL;
    /* OF */
    if (tnum != TEX_DIFFUSE && !name[0] && matslot < 0) {
        string nname;
        const char *tname = s.sts[0].name, *ext = strrchr(tname, '.');
        copystring(nname, tname);
        char *buf = nname + strlen(tname) - (ext ? strlen(ext) : 0);
        *(buf++) = '_';
        *(buf++) = type[0];
        copystring(buf, ext ? ext : "");
        copystring(st.name, nname);
    } else copystring(st.name, name);
    path(st.name);
    if(tnum==TEX_DIFFUSE)
    {
        setslotshader(s);
        bool newvslot = false;
        VSlot *vs = matslot >= 0 ? &materialslots[matslot] : emptyvslot(s, newvslot);
        vs->reset();
        vs->rotation = clamp(*rot, 0, 5);
        vs->offset = ivec2(*xoffset, *yoffset).max(0);
        vs->scale = *scale <= 0 ? 1 : *scale;
        /* OF */
        if (matslot < 0 && !saved_vslots.empty()) {
            VSlot *svs = saved_vslots.pop();
            svs->changed = comparevslot(*vs, *svs);
            if (!svs->changed) {
                if (newvslot) delete vslots.pop();
                vs = svs;
                s.variants = NULL;
            }
            svs->addvariant(&s);
            while (svs) {
                svs->slot = &s;
                svs->linked = false;
                svs = svs->next;
            }
        }
        propagatevslot(vs, (1<<VSLOT_NUM)-1);
    }
}

COMMAND(texture, "ssiiif");

void texgrass(char *name)
{
    if(slots.empty()) return;
    Slot &s = *slots.last();
    DELETEA(s.grass);
    s.grass = name[0] ? newstring(makerelpath("media/texture", name)) : NULL;
}
COMMAND(texgrass, "s");

void texscroll(float *scrollS, float *scrollT)
{
    if(slots.empty()) return;
    Slot &s = *slots.last();
    s.variants->scroll = vec2(*scrollS/1000.0f, *scrollT/1000.0f);
    propagatevslot(s.variants, 1<<VSLOT_SCROLL);
}
COMMAND(texscroll, "ff");

void texoffset_(int *xoffset, int *yoffset)
{
    if(slots.empty()) return;
    Slot &s = *slots.last();
    s.variants->offset = ivec2(*xoffset, *yoffset).max(0);
    propagatevslot(s.variants, 1<<VSLOT_OFFSET);
}
COMMANDN(texoffset, texoffset_, "ii");

void texrotate_(int *rot)
{
    if(slots.empty()) return;
    Slot &s = *slots.last();
    s.variants->rotation = clamp(*rot, 0, 5);
    propagatevslot(s.variants, 1<<VSLOT_ROTATION);
}
COMMANDN(texrotate, texrotate_, "i");

void texscale(float *scale)
{
    if(slots.empty()) return;
    Slot &s = *slots.last();
    s.variants->scale = *scale <= 0 ? 1 : *scale;
    propagatevslot(s.variants, 1<<VSLOT_SCALE);
}
COMMAND(texscale, "f");

void texlayer(int *layer)
{
    if(slots.empty()) return;
    Slot &s = *slots.last();
    s.variants->layer = *layer < 0 ? max(slots.length()-1+*layer, 0) : *layer;
    propagatevslot(s.variants, 1<<VSLOT_LAYER);
}
COMMAND(texlayer, "i");

void texdecal(int *decal)
{
    if(slots.empty()) return;
    Slot &s = *slots.last();
    s.variants->decal = *decal < 0 ? max(slots.length()-1+*decal, 0) : *decal;
    propagatevslot(s.variants, 1<<VSLOT_DECAL);
}
COMMAND(texdecal, "i");

void texalpha(float *front, float *back)
{
    if(slots.empty()) return;
    Slot &s = *slots.last();
    s.variants->alphafront = clamp(*front, 0.0f, 1.0f);
    s.variants->alphaback = clamp(*back, 0.0f, 1.0f);
    propagatevslot(s.variants, 1<<VSLOT_ALPHA);
}
COMMAND(texalpha, "ff");

void texcolor(float *r, float *g, float *b)
{
    if(slots.empty()) return;
    Slot &s = *slots.last();
    s.variants->colorscale = vec(clamp(*r, 0.0f, 1.0f), clamp(*g, 0.0f, 1.0f), clamp(*b, 0.0f, 1.0f));
    propagatevslot(s.variants, 1<<VSLOT_COLOR);
}
COMMAND(texcolor, "fff");

void texrefract(float *k, float *r, float *g, float *b)
{
    if(slots.empty()) return;
    Slot &s = *slots.last();
    s.variants->refractscale = clamp(*k, 0.0f, 1.0f);
    if(s.variants->refractscale > 0 && (*r > 0 || *g > 0 || *b > 0))
        s.variants->refractcolor = vec(clamp(*r, 0.0f, 1.0f), clamp(*g, 0.0f, 1.0f), clamp(*b, 0.0f, 1.0f));
    else
        s.variants->refractcolor = vec(1, 1, 1);
    propagatevslot(s.variants, 1<<VSLOT_REFRACT);
}
COMMAND(texrefract, "ffff");

void texsmooth(int *id, int *angle)
{
    if(slots.empty()) return;
    Slot &s = *slots.last();
    s.smooth = smoothangle(*id, *angle);
}
COMMAND(texsmooth, "ib");

static int findtextype(Slot &s, int type, int last = -1)
{
    for(int i = last+1; i<s.sts.length(); i++) if((type&(1<<s.sts[i].type)) && s.sts[i].combined<0) return i;
    return -1;
}

static void addglow(ImageData &c, ImageData &g, const vec &glowcolor)
{
    if(g.bpp < 3)
    {
        readwritergbtex(c, g,
            loopk(3) dst[k] = clamp(int(dst[k]) + int(src[0]*glowcolor[k]), 0, 255);
        );
    }
    else
    {
        readwritergbtex(c, g,
            loopk(3) dst[k] = clamp(int(dst[k]) + int(src[k]*glowcolor[k]), 0, 255);
        );
    }
}

static void mergespec(ImageData &c, ImageData &s)
{
    if(s.bpp < 3)
    {
        readwritergbatex(c, s,
            dst[3] = src[0];
        );
    }
    else
    {
        readwritergbatex(c, s,
            dst[3] = (int(src[0]) + int(src[1]) + int(src[2]))/3;
        );
    }
}

static void mergedepth(ImageData &c, ImageData &z)
{
    readwritergbatex(c, z,
        dst[3] = src[0];
    );
}

static void addname(vector<char> &key, Slot &slot, Slot::Tex &t, bool combined = false, const char *prefix = NULL)
{
    if(combined) key.add('&');
    if(prefix) { while(*prefix) key.add(*prefix++); }
    defformatstring(tname, "media/texture/%s", t.name);
    for(const char *s = path(tname); *s; key.add(*s++));
}

static void texcombine(Slot &s, int index, Slot::Tex &t, bool forceload = false)
{
    vector<char> key;
    addname(key, s, t);
    int texmask = 0;
    if(!forceload) switch(t.type)
    {
        case TEX_DIFFUSE:
        case TEX_NORMAL:
        {
            int i = findtextype(s, t.type==TEX_DIFFUSE ? (1<<TEX_SPEC) : (1<<TEX_DEPTH));
            if(i<0) break;
            texmask |= 1<<s.sts[i].type;
            s.sts[i].combined = index;
            addname(key, s, s.sts[i], true);
            break;
        }
    }
    key.add('\0');
    t.t = textures.access(key.getbuf());
    if(t.t) return;
    int compress = 0, wrap = 0;
    ImageData ts;
    if(!texturedata(ts, NULL, &t, true, &compress, &wrap)) { t.t = notexture; return; }
    switch(t.type)
    {
        case TEX_DIFFUSE:
        case TEX_NORMAL:
            if(ts.compressed) break;
            loopv(s.sts)
            {
                Slot::Tex &a = s.sts[i];
                if(a.combined!=index) continue;
                ImageData as;
                if(!texturedata(as, NULL, &a)) continue;
                if(as.w!=ts.w || as.h!=ts.h) scaleimage(as, ts.w, ts.h);
                switch(a.type)
                {
                    case TEX_SPEC: mergespec(ts, as); break;
                    case TEX_DEPTH: mergedepth(ts, as); break;
                }
                break; // only one combination
            }
            if(ts.bpp < 3) swizzleimage(ts);
            break;
    }
    t.t = newtexture(NULL, key.getbuf(), ts, wrap, true, true, true, compress);
}

static Slot &loadslot(Slot &s, bool forceload)
{
    linkslotshader(s);
    loopv(s.sts)
    {
        Slot::Tex &t = s.sts[i];
        if(t.combined >= 0) continue;
        switch(t.type)
        {
            case TEX_ENVMAP:
                t.t = cubemapload(t.name);
                break;

            default:
                texcombine(s, i, t, forceload);
                break;
        }
    }
    s.loaded = true;
    return s;
}

MSlot &lookupmaterialslot(int index, bool load)
{
    MSlot &s = materialslots[index];
    if(load && !s.linked)
    {
        if(!s.loaded) loadslot(s, true);
        linkvslotshader(s);
        s.linked = true;
    }
    return s;
}

Slot &lookupslot(int index, bool load)
{
    Slot &s = slots.inrange(index) ? *slots[index] : (slots.inrange(DEFAULT_GEOM) ? *slots[DEFAULT_GEOM] : dummyslot);
    return s.loaded || !load ? s : loadslot(s, false);
}

VSlot &lookupvslot(int index, bool load)
{
    VSlot &s = vslots.inrange(index) && vslots[index]->slot ? *vslots[index] : (slots.inrange(DEFAULT_GEOM) && slots[DEFAULT_GEOM]->variants ? *slots[DEFAULT_GEOM]->variants : dummyvslot);
    if(load && !s.linked)
    {
        if(!s.slot->loaded) loadslot(*s.slot, false);
        linkvslotshader(s);
        s.linked = true;
    }
    return s;
}

void linkslotshaders()
{
    loopv(slots) if(slots[i]->loaded) linkslotshader(*slots[i]);
    loopv(vslots) if(vslots[i]->linked) linkvslotshader(*vslots[i]);
    loopi((MATF_VOLUME|MATF_INDEX)+1) if(materialslots[i].loaded)
    {
        linkslotshader(materialslots[i]);
        linkvslotshader(materialslots[i]);
    }
}

static void blitthumbnail(ImageData &d, ImageData &s, int x, int y)
{
    forcergbimage(d);
    forcergbimage(s);
    uchar *dstrow = &d.data[d.pitch*y + d.bpp*x], *srcrow = s.data;
    loop(y, s.h)
    {
        for(uchar *dst = dstrow, *src = srcrow, *end = &srcrow[s.w*s.bpp]; src < end; dst += d.bpp, src += s.bpp)
        loopk(3) dst[k] = src[k];
        dstrow += d.pitch;
        srcrow += s.pitch;
    }
}

Texture *loadthumbnail(Slot &slot)
{
    if(slot.thumbnail) return slot.thumbnail;
    if(!slot.variants)
    {
        slot.thumbnail = notexture;
        return slot.thumbnail;
    }
    VSlot &vslot = *slot.variants;
    linkslotshader(slot, false);
    linkvslotshader(vslot, false);
    vector<char> name;
    if(vslot.colorscale == vec(1, 1, 1)) addname(name, slot, slot.sts[0], false, "<thumbnail>");
    else
    {
        defformatstring(prefix, "<thumbnail:%.2f/%.2f/%.2f>", vslot.colorscale.x, vslot.colorscale.y, vslot.colorscale.z);
        addname(name, slot, slot.sts[0], false, prefix);
    }
    int glow = -1;
    if(slot.texmask&(1<<TEX_GLOW))
    {
        loopvj(slot.sts) if(slot.sts[j].type==TEX_GLOW) { glow = j; break; }
        if(glow >= 0)
        {
            defformatstring(prefix, "<glow:%.2f/%.2f/%.2f>", vslot.glowcolor.x, vslot.glowcolor.y, vslot.glowcolor.z);
            addname(name, slot, slot.sts[glow], true, prefix);
        }
    }
    VSlot *layer = vslot.layer ? &lookupvslot(vslot.layer, false) : NULL;
    if(layer)
    {
        if(layer->colorscale == vec(1, 1, 1)) addname(name, *layer->slot, layer->slot->sts[0], true, "<layer>");
        else
        {
            defformatstring(prefix, "<layer:%.2f/%.2f/%.2f>", layer->colorscale.x, layer->colorscale.y, layer->colorscale.z);
            addname(name, *layer->slot, layer->slot->sts[0], true, prefix);
        }
    }
    VSlot *decal = vslot.decal ? &lookupvslot(vslot.decal, false) : NULL;
    if(decal) addname(name, *decal->slot, decal->slot->sts[0], true, "<decal>");
    name.add('\0');
    Texture *t = textures.access(path(name.getbuf()));
    if(t) slot.thumbnail = t;
    else
    {
        ImageData s, g, l, d;
        texturedata(s, NULL, &slot.sts[0], false);
        if(glow >= 0) texturedata(g, NULL, &slot.sts[glow], false);
        if(layer) texturedata(l, NULL, &layer->slot->sts[0], false);
        if(decal) texturedata(d, NULL, &decal->slot->sts[0], false);
        if(!s.data) t = slot.thumbnail = notexture;
        else
        {
            if(vslot.colorscale != vec(1, 1, 1)) texmad(s, vslot.colorscale, vec(0, 0, 0));
            int xs = s.w, ys = s.h;
            if(s.w > 128 || s.h > 128) scaleimage(s, min(s.w, 128), min(s.h, 128));
            if(g.data)
            {
                if(g.w != s.w || g.h != s.h) scaleimage(g, s.w, s.h);
                addglow(s, g, vslot.glowcolor);
            }
            if(l.data)
            {
                if(layer->colorscale != vec(1, 1, 1)) texmad(l, layer->colorscale, vec(0, 0, 0));
                if(l.w != s.w/2 || l.h != s.h/2) scaleimage(l, s.w/2, s.h/2);
                blitthumbnail(s, l, s.w-l.w, s.h-l.h);
            }
            if(d.data)
            {
                if(vslot.colorscale != vec(1, 1, 1)) texmad(d, vslot.colorscale, vec(0, 0, 0));
                if(d.w != s.w/2 || d.h != s.h/2) scaleimage(d, s.w/2, s.h/2);
                blitthumbnail(s, d, 0, 0);
            }
            if(s.bpp < 3) forcergbimage(s);
            t = newtexture(NULL, name.getbuf(), s, 0, false, false, true);
            t->xs = xs;
            t->ys = ys;
            slot.thumbnail = t;
        }
    }
    return t;
}

// environment mapped reflections

extern const cubemapside cubemapsides[6] =
{
    { GL_TEXTURE_CUBE_MAP_NEGATIVE_X, "lf", false, true,  true  },
    { GL_TEXTURE_CUBE_MAP_POSITIVE_X, "rt", true,  false, true  },
    { GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, "bk", false, false, false },
    { GL_TEXTURE_CUBE_MAP_POSITIVE_Y, "ft", true,  true,  false },
    { GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, "dn", true,  false, true  },
    { GL_TEXTURE_CUBE_MAP_POSITIVE_Z, "up", true,  false, true  },
};

VARFP(envmapsize, 4, 7, 10, setupmaterials());

Texture *cubemaploadwildcard(Texture *t, const char *name, bool mipit, bool msg, bool transient = false)
{
    string tname;
    if(!name) copystring(tname, t->name);
    else
    {
        copystring(tname, name);
        t = textures.access(path(tname));
        if(t)
        {
            if(!transient && t->type&Texture::TRANSIENT) t->type &= ~Texture::TRANSIENT;
            return t;
        }
    }
    char *wildcard = strchr(tname, '*');
    ImageData surface[6];
    string sname;
    if(!wildcard) copystring(sname, tname);
    int tsize = 0, compress = 0;
    loopi(6)
    {
        if(wildcard)
        {
            copystring(sname, tname, wildcard-tname+1);
            concatstring(sname, cubemapsides[i].name);
            concatstring(sname, wildcard+1);
        }
        ImageData &s = surface[i];
        texturedata(s, sname, NULL, msg, &compress);
        if(!s.data) return NULL;
        if(s.w != s.h)
        {
            if(msg) conoutf(CON_ERROR, "cubemap texture %s does not have square size", sname);
            return NULL;
        }
        if(s.compressed ? s.compressed!=surface[0].compressed || s.w!=surface[0].w || s.h!=surface[0].h || s.levels!=surface[0].levels : surface[0].compressed || s.bpp!=surface[0].bpp)
        {
            if(msg) conoutf(CON_ERROR, "cubemap texture %s doesn't match other sides' format", sname);
            return NULL;
        }
        tsize = max(tsize, max(s.w, s.h));
    }
    if(name)
    {
        char *key = newstring(tname);
        t = &textures[key];
        t->name = key;
    }
    t->type = Texture::CUBEMAP;
    if(transient) t->type |= Texture::TRANSIENT;
    GLenum format;
    if(surface[0].compressed)
    {
        format = uncompressedformat(surface[0].compressed);
        t->bpp = formatsize(format);
        t->type |= Texture::COMPRESSED;
    }
    else
    {
        format = texformat(surface[0].bpp);
        t->bpp = surface[0].bpp;
        if(hasTRG && !hasTSW && swizzlemask(format))
        {
            loopi(6) swizzleimage(surface[i]);
            format = texformat(surface[0].bpp);
            t->bpp = surface[0].bpp;
        }
    }
    if(alphaformat(format)) t->type |= Texture::ALPHA;
    t->mipmap = mipit;
    t->clamp = 3;
    t->xs = t->ys = tsize;
    t->w = t->h = min(1<<envmapsize, tsize);
    resizetexture(t->w, t->h, mipit, false, GL_TEXTURE_CUBE_MAP, compress, t->w, t->h);
    GLenum component = format;
    if(!surface[0].compressed)
    {
        component = compressedformat(format, t->w, t->h, compress);
        switch(component)
        {
            case GL_RGB: component = GL_RGB5; break;
        }
    }
    glGenTextures(1, &t->id);
    loopi(6)
    {
        ImageData &s = surface[i];
        const cubemapside &side = cubemapsides[i];
        texreorient(s, side.flipx, side.flipy, side.swapxy);
        if(s.compressed)
        {
            int w = s.w, h = s.h, levels = s.levels, level = 0;
            uchar *data = s.data;
            while(levels > 1 && (w > t->w || h > t->h))
            {
                data += s.calclevelsize(level++);
                levels--;
                if(w > 1) w /= 2;
                if(h > 1) h /= 2;
            }
            createcompressedtexture(!i ? t->id : 0, w, h, data, s.align, s.bpp, levels, 3, mipit ? 2 : 1, s.compressed, side.target, true);
        }
        else
        {
            createtexture(!i ? t->id : 0, t->w, t->h, s.data, 3, mipit ? 2 : 1, component, side.target, s.w, s.h, s.pitch, false, format, true);
        }
    }
    return t;
}

Texture *cubemapload(const char *name, bool mipit, bool msg, bool transient)
{
    string pname;
    copystring(pname, makerelpath("media/sky", name));
    path(pname);
    Texture *t = NULL;
    if(!strchr(pname, '*'))
    {
        /* OF */
        defformatstring(fname, "%s_*", pname);
        t = cubemaploadwildcard(NULL, fname, mipit, false, transient);
        if (!t && msg) conoutf(CON_ERROR, "could not load envmap %s", name);
    }
    else t = cubemaploadwildcard(NULL, pname, mipit, msg, transient);
    return t;
}

VARR(envmapradius, 0, 128, 10000);
VARP(aaenvmap, 0, 1, 1);

struct envmap
{
    int radius, size, blur;
    vec o;
    GLuint tex;

    envmap() : radius(-1), size(0), blur(0), o(0, 0, 0), tex(0) {}

    void clear()
    {
        if(tex) { glDeleteTextures(1, &tex); tex = 0; }
    }
};

static vector<envmap> envmaps;

void clearenvmaps()
{
    loopv(envmaps) envmaps[i].clear();
    envmaps.shrink(0);
}

static GLuint emfbo[3] = { 0, 0, 0 }, emtex[2] = { 0, 0 };
static int emtexsize = -1;

GLuint genenvmap(const vec &o, int envmapsize, int blur, bool onlysky)
{
    int rendersize = 1<<(envmapsize+aaenvmap), sizelimit = min(hwcubetexsize, min(gw, gh));
    if(maxtexsize) sizelimit = min(sizelimit, maxtexsize);
    while(rendersize > sizelimit) rendersize /= 2;
    int texsize = min(rendersize, 1<<envmapsize);
    if(!aaenvmap) rendersize = texsize;
    if(!emtex[0]) glGenTextures(2, emtex);
    if(!emfbo[0]) glGenFramebuffers_(3, emfbo);
    if(emtexsize != texsize)
    {
        emtexsize = texsize;
        loopi(2)
        {
            createtexture(emtex[i], emtexsize, emtexsize, NULL, 3, 1, GL_RGB, GL_TEXTURE_RECTANGLE);
            glBindFramebuffer_(GL_FRAMEBUFFER, emfbo[i]);
            glFramebufferTexture2D_(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE, emtex[i], 0);
            if(glCheckFramebufferStatus_(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
                fatal("failed allocating envmap buffer!");
        }
    }
    GLuint tex = 0;
    glGenTextures(1, &tex);
    // workaround for Catalyst bug:
    // all texture levels must be specified before glCopyTexSubImage2D is called, otherwise it crashes
    loopi(6) createtexture(!i ? tex : 0, texsize, texsize, NULL, 3, 2, GL_RGB5, cubemapsides[i].target);
    float yaw = 0, pitch = 0;
    loopi(6)
    {
        const cubemapside &side = cubemapsides[i];
        switch(side.target)
        {
            case GL_TEXTURE_CUBE_MAP_NEGATIVE_X: // lf
                yaw = 90; pitch = 0; break;
            case GL_TEXTURE_CUBE_MAP_POSITIVE_X: // rt
                yaw = 270; pitch = 0; break;
            case GL_TEXTURE_CUBE_MAP_NEGATIVE_Y: // bk
                yaw = 180; pitch = 0; break;
            case GL_TEXTURE_CUBE_MAP_POSITIVE_Y: // ft
                yaw = 0; pitch = 0; break;
            case GL_TEXTURE_CUBE_MAP_NEGATIVE_Z: // dn
                yaw = 270; pitch = -90; break;
            case GL_TEXTURE_CUBE_MAP_POSITIVE_Z: // up
                yaw = 270; pitch = 90; break;
        }
        drawcubemap(rendersize, o, yaw, pitch, side, onlysky);
        copyhdr(rendersize, rendersize, emfbo[0], texsize, texsize, side.flipx, !side.flipy, side.swapxy);
        if(blur > 0)
        {
            float blurweights[MAXBLURRADIUS+1], bluroffsets[MAXBLURRADIUS+1];
            setupblurkernel(blur, blurweights, bluroffsets);
            loopj(2)
            {
                glBindFramebuffer_(GL_FRAMEBUFFER, emfbo[1]);
                glViewport(0, 0, texsize, texsize);
                setblurshader(j, 1, blur, blurweights, bluroffsets, GL_TEXTURE_RECTANGLE);
                glBindTexture(GL_TEXTURE_RECTANGLE, emtex[0]);
                screenquad(texsize, texsize);
                swap(emfbo[0], emfbo[1]);
                swap(emtex[0], emtex[1]);
            }
        }
        for(int level = 0, lsize = texsize;; level++)
        {
            if(hasFBB)
            {
                glBindFramebuffer_(GL_READ_FRAMEBUFFER, emfbo[0]);
                glBindFramebuffer_(GL_DRAW_FRAMEBUFFER, emfbo[2]);
                glFramebufferTexture2D_(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, side.target, tex, level);
                glBlitFramebuffer_(0, 0, lsize, lsize, 0, 0, lsize, lsize, GL_COLOR_BUFFER_BIT, GL_NEAREST);
            }
            else
            {
                glBindFramebuffer_(GL_FRAMEBUFFER, emfbo[0]);
                glBindTexture(GL_TEXTURE_CUBE_MAP, tex);
                glCopyTexSubImage2D(side.target, level, 0, 0, 0, 0, lsize, lsize);
            }
            if(lsize <= 1) break;
            int dsize = lsize/2;
            if(hasFBB)
            {
                glBindFramebuffer_(GL_READ_FRAMEBUFFER, emfbo[0]);
                glBindFramebuffer_(GL_DRAW_FRAMEBUFFER, emfbo[1]);
                glBlitFramebuffer_(0, 0, lsize, lsize, 0, 0, dsize, dsize, GL_COLOR_BUFFER_BIT, GL_LINEAR);
            }
            else
            {
                glBindFramebuffer_(GL_FRAMEBUFFER, emfbo[1]);
                glBindTexture(GL_TEXTURE_RECTANGLE, emtex[0]);
                glViewport(0, 0, dsize, dsize);
                SETSHADER(scalelinear);
                screenquad(lsize, lsize);
            }
            lsize = dsize;
            swap(emfbo[0], emfbo[1]);
            swap(emtex[0], emtex[1]);
        }
    }
    glBindFramebuffer_(GL_FRAMEBUFFER, 0);
    glViewport(0, 0, hudw, hudh);
    clientkeepalive();
    return tex;
}

void initenvmaps()
{
    clearenvmaps();
    envmaps.add().size = hasskybox() ? 0 : 1;
    const vector<extentity *> &ents = entities::getents();
    loopv(ents)
    {
        const extentity &ent = *ents[i];
        if(ent.type != ET_ENVMAP) continue;
        envmap &em = envmaps.add();
        em.radius = ent.attr[0] ? clamp(int(ent.attr[0]), 0, 10000) : envmapradius;
        em.size = ent.attr[1] ? clamp(int(ent.attr[1]), 4, 9) : 0;
        em.blur = ent.attr[2] ? clamp(int(ent.attr[2]), 1, 2) : 0;
        em.o = ent.o;
    }
}

void genenvmaps()
{
    if(envmaps.empty()) return;
    renderprogress(0, "generating environment maps...");
    int lastprogress = SDL_GetTicks();
    gl_setupframe(true);
    loopv(envmaps)
    {
        envmap &em = envmaps[i];
        em.tex = genenvmap(em.o, em.size ? min(em.size, envmapsize) : envmapsize, em.blur, em.radius < 0);
        if(renderedframe) continue;
        int millis = SDL_GetTicks();
        if(millis - lastprogress >= 250)
        {
            renderprogress(float(i+1)/envmaps.length(), "generating environment maps...", 0, true);
            lastprogress = millis;
        }
    }
    if(emfbo[0]) { glDeleteFramebuffers_(3, emfbo); memset(emfbo, 0, sizeof(emfbo)); }
    if(emtex[0]) { glDeleteTextures(2, emtex); memset(emtex, 0, sizeof(emtex)); }
    emtexsize = -1;
}

ushort closestenvmap(const vec &o)
{
    ushort minemid = EMID_SKY;
    float mindist = 1e16f;
    loopv(envmaps)
    {
        envmap &em = envmaps[i];
        float dist = em.o.dist(o);
        if(dist < em.radius && dist < mindist)
        {
            minemid = EMID_RESERVED + i;
            mindist = dist;
        }
    }
    return minemid;
}

ushort closestenvmap(int orient, const ivec &co, int size)
{
    vec loc(co);
    int dim = dimension(orient);
    if(dimcoord(orient)) loc[dim] += size;
    loc[R[dim]] += size/2;
    loc[C[dim]] += size/2;
    return closestenvmap(loc);
}

static inline GLuint lookupskyenvmap()
{
    return envmaps.length() && envmaps[0].radius < 0 ? envmaps[0].tex : 0;
}

GLuint lookupenvmap(Slot &slot)
{
    loopv(slot.sts) if(slot.sts[i].type==TEX_ENVMAP && slot.sts[i].t) return slot.sts[i].t->id;
    return lookupskyenvmap();
}

GLuint lookupenvmap(ushort emid)
{
    if(emid==EMID_SKY || emid==EMID_CUSTOM || drawtex) return lookupskyenvmap();
    if(emid==EMID_NONE || !envmaps.inrange(emid-EMID_RESERVED)) return 0;
    GLuint tex = envmaps[emid-EMID_RESERVED].tex;
    return tex ? tex : lookupskyenvmap();
}

void cleanuptexture(Texture *t)
{
    DELETEA(t->alphamask);
    if(t->id) { glDeleteTextures(1, &t->id); t->id = 0; }
    if(t->type&Texture::TRANSIENT) textures.remove(t->name);
}

void cleanuptextures()
{
    clearenvmaps();
    loopv(slots) slots[i]->cleanup();
    loopv(vslots) vslots[i]->cleanup();
    loopi((MATF_VOLUME|MATF_INDEX)+1) materialslots[i].cleanup();
    enumerate(textures, Texture, tex, cleanuptexture(&tex));
}

bool reloadtexture(const char *name)
{
    Texture *t = textures.access(path(name, true));
    if(t) return reloadtexture(*t);
    return true;
}

bool reloadtexture(Texture &tex)
{
    if(tex.id) return true;
    switch(tex.type&Texture::TYPE)
    {
        case Texture::IMAGE:
        {
            int compress = 0;
            ImageData s;
            if(!texturedata(s, tex.name, NULL, true, &compress) || !newtexture(&tex, NULL, s, tex.clamp, tex.mipmap, false, false, compress)) return false;
            break;
        }

        case Texture::CUBEMAP:
            if(!cubemaploadwildcard(&tex, NULL, tex.mipmap, true)) return false;
            break;
    }
    return true;
}

void reloadtex(char *name)
{
    Texture *t = textures.access(path(name, true));
    if(!t) { conoutf(CON_ERROR, "texture %s is not loaded", name); return; }
    if(t->type&Texture::TRANSIENT) { conoutf(CON_ERROR, "can't reload transient texture %s", name); return; }
    DELETEA(t->alphamask);
    Texture oldtex = *t;
    t->id = 0;
    if(!reloadtexture(*t))
    {
        if(t->id) glDeleteTextures(1, &t->id);
        *t = oldtex;
        conoutf(CON_ERROR, "failed to reload texture %s", name);
    }
}

COMMAND(reloadtex, "s");

void reloadtextures()
{
    int reloaded = 0;
    enumerate(textures, Texture, tex,
    {
        loadprogress = float(++reloaded)/textures.numelems;
        reloadtexture(tex);
    });
    loadprogress = 0;
}

enum
{
    DDSD_CAPS                  = 0x00000001,
    DDSD_HEIGHT                = 0x00000002,
    DDSD_WIDTH                 = 0x00000004,
    DDSD_PITCH                 = 0x00000008,
    DDSD_PIXELFORMAT           = 0x00001000,
    DDSD_MIPMAPCOUNT           = 0x00020000,
    DDSD_LINEARSIZE            = 0x00080000,
    DDSD_BACKBUFFERCOUNT       = 0x00800000,
    DDPF_ALPHAPIXELS           = 0x00000001,
    DDPF_FOURCC                = 0x00000004,
    DDPF_INDEXED               = 0x00000020,
    DDPF_ALPHA                 = 0x00000002,
    DDPF_RGB                   = 0x00000040,
    DDPF_COMPRESSED            = 0x00000080,
    DDPF_LUMINANCE             = 0x00020000,
    DDSCAPS_COMPLEX            = 0x00000008,
    DDSCAPS_TEXTURE            = 0x00001000,
    DDSCAPS_MIPMAP             = 0x00400000,
    DDSCAPS2_CUBEMAP           = 0x00000200,
    DDSCAPS2_CUBEMAP_POSITIVEX = 0x00000400,
    DDSCAPS2_CUBEMAP_NEGATIVEX = 0x00000800,
    DDSCAPS2_CUBEMAP_POSITIVEY = 0x00001000,
    DDSCAPS2_CUBEMAP_NEGATIVEY = 0x00002000,
    DDSCAPS2_CUBEMAP_POSITIVEZ = 0x00004000,
    DDSCAPS2_CUBEMAP_NEGATIVEZ = 0x00008000,
    DDSCAPS2_VOLUME            = 0x00200000,
    FOURCC_DXT1                = 0x31545844,
    FOURCC_DXT2                = 0x32545844,
    FOURCC_DXT3                = 0x33545844,
    FOURCC_DXT4                = 0x34545844,
    FOURCC_DXT5                = 0x35545844,
    FOURCC_ATI1                = 0x31495441,
    FOURCC_ATI2                = 0x32495441
};

struct DDCOLORKEY { uint dwColorSpaceLowValue, dwColorSpaceHighValue; };
struct DDPIXELFORMAT
{
    uint dwSize, dwFlags, dwFourCC;
    union { uint dwRGBBitCount, dwYUVBitCount, dwZBufferBitDepth, dwAlphaBitDepth, dwLuminanceBitCount, dwBumpBitCount, dwPrivateFormatBitCount; };
    union { uint dwRBitMask, dwYBitMask, dwStencilBitDepth, dwLuminanceBitMask, dwBumpDuBitMask, dwOperations; };
    union { uint dwGBitMask, dwUBitMask, dwZBitMask, dwBumpDvBitMask; struct { ushort wFlipMSTypes, wBltMSTypes; } MultiSampleCaps; };
    union { uint dwBBitMask, dwVBitMask, dwStencilBitMask, dwBumpLuminanceBitMask; };
    union { uint dwRGBAlphaBitMask, dwYUVAlphaBitMask, dwLuminanceAlphaBitMask, dwRGBZBitMask, dwYUVZBitMask; };

};
struct DDSCAPS2 { uint dwCaps, dwCaps2, dwCaps3, dwCaps4; };
struct DDSURFACEDESC2
{
    uint dwSize, dwFlags, dwHeight, dwWidth;
    union { int lPitch; uint dwLinearSize; };
    uint dwBackBufferCount;
    union { uint dwMipMapCount, dwRefreshRate, dwSrcVBHandle; };
    uint dwAlphaBitDepth, dwReserved, lpSurface;
    union { DDCOLORKEY ddckCKDestOverlay; uint dwEmptyFaceColor; };
    DDCOLORKEY ddckCKDestBlt, ddckCKSrcOverlay, ddckCKSrcBlt;
    union { DDPIXELFORMAT ddpfPixelFormat; uint dwFVF; };
    DDSCAPS2 ddsCaps;
    uint dwTextureStage;
};

bool loaddds(const char *filename, ImageData &image)
{
    stream *f = openfile(filename, "rb");
    if(!f) return false;
    GLenum format = GL_FALSE;
    uchar magic[4];
    if(f->read(magic, 4) != 4 || memcmp(magic, "DDS ", 4)) { delete f; return false; }
    DDSURFACEDESC2 d;
    if(f->read(&d, sizeof(d)) != sizeof(d)) { delete f; return false; }
    lilswap((uint *)&d, sizeof(d)/sizeof(uint));
    if(d.dwSize != sizeof(DDSURFACEDESC2) || d.ddpfPixelFormat.dwSize != sizeof(DDPIXELFORMAT)) { delete f; return false; }
    if(d.ddpfPixelFormat.dwFlags & DDPF_FOURCC)
    {
        switch(d.ddpfPixelFormat.dwFourCC)
        {
            case FOURCC_DXT1: if(hasS3TC) format = d.ddpfPixelFormat.dwFlags & DDPF_ALPHAPIXELS ? GL_COMPRESSED_RGBA_S3TC_DXT1_EXT : GL_COMPRESSED_RGB_S3TC_DXT1_EXT; break;
            case FOURCC_DXT2:
            case FOURCC_DXT3: if(hasS3TC) format = GL_COMPRESSED_RGBA_S3TC_DXT3_EXT; break;
            case FOURCC_DXT4:
            case FOURCC_DXT5: if(hasS3TC) format = GL_COMPRESSED_RGBA_S3TC_DXT5_EXT; break;
            case FOURCC_ATI1:
                if(hasRGTC) format = GL_COMPRESSED_RED_RGTC1;
                else if(hasLATC) format = GL_COMPRESSED_LUMINANCE_LATC1_EXT;
                break;
            case FOURCC_ATI2:
                if(hasRGTC) format = GL_COMPRESSED_RG_RGTC2;
                else if(hasLATC) format = GL_COMPRESSED_LUMINANCE_ALPHA_LATC2_EXT;
                break;
        }
    }
    if(!format) { delete f; return false; }
    if(dbgdds) conoutf(CON_DEBUG, "%s: format 0x%X, %d x %d, %d mipmaps", filename, format, d.dwWidth, d.dwHeight, d.dwMipMapCount);
    int bpp = 0;
    switch(format)
    {
        case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
        case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT: bpp = 8; break;
        case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:
        case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT: bpp = 16; break;
        case GL_COMPRESSED_LUMINANCE_LATC1_EXT:
        case GL_COMPRESSED_RED_RGTC1: bpp = 8; break;
        case GL_COMPRESSED_LUMINANCE_ALPHA_LATC2_EXT:
        case GL_COMPRESSED_RG_RGTC2: bpp = 16; break;

    }
    image.setdata(NULL, d.dwWidth, d.dwHeight, bpp, d.dwMipMapCount, 4, format);
    int size = image.calcsize();
    if(f->read(image.data, size) != size) { delete f; image.cleanup(); return false; }
    delete f;
    return true;
}

void gendds(char *infile, char *outfile)
{
    if(!hasS3TC || usetexcompress <= 1) { conoutf(CON_ERROR, "OpenGL driver does not support S3TC texture compression"); return; }

    glHint(GL_TEXTURE_COMPRESSION_HINT, GL_NICEST);

    defformatstring(cfile, "<compress>%s", infile);
    extern void reloadtex(char *name);
    Texture *t = textures.access(path(cfile));
    if(t) reloadtex(cfile);
    t = textureload(cfile);
    if(t==notexture) { conoutf(CON_ERROR, "failed loading %s", infile); return; }

    glBindTexture(GL_TEXTURE_2D, t->id);
    GLint compressed = 0, format = 0, width = 0, height = 0;
    glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_COMPRESSED, &compressed);
    glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_INTERNAL_FORMAT, &format);
    glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, &width);
    glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, &height);

    if(!compressed) { conoutf(CON_ERROR, "failed compressing %s", infile); return; }
    int fourcc = 0;
    switch(format)
    {
        case GL_COMPRESSED_RGB_S3TC_DXT1_EXT: fourcc = FOURCC_DXT1; conoutf("compressed as DXT1"); break;
        case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT: fourcc = FOURCC_DXT1; conoutf("compressed as DXT1a"); break;
        case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT: fourcc = FOURCC_DXT3; conoutf("compressed as DXT3"); break;
        case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT: fourcc = FOURCC_DXT5; conoutf("compressed as DXT5"); break;
        case GL_COMPRESSED_LUMINANCE_LATC1_EXT:
        case GL_COMPRESSED_RED_RGTC1: fourcc = FOURCC_ATI1; conoutf("compressed as ATI1"); break;
        case GL_COMPRESSED_LUMINANCE_ALPHA_LATC2_EXT:
        case GL_COMPRESSED_RG_RGTC2: fourcc = FOURCC_ATI2; conoutf("compressed as ATI2"); break;
        default:
            conoutf(CON_ERROR, "failed compressing %s: unknown format: 0x%X", infile, format); break;
            return;
    }

    if(!outfile[0])
    {
        static string buf;
        copystring(buf, infile);
        int len = strlen(buf);
        if(len > 4 && buf[len-4]=='.') memcpy(&buf[len-4], ".dds", 4);
        else concatstring(buf, ".dds");
        outfile = buf;
    }

    stream *f = openfile(path(outfile, true), "wb");
    if(!f) { conoutf(CON_ERROR, "failed writing to %s", outfile); return; }

    int csize = 0;
    for(int lw = width, lh = height, level = 0;;)
    {
        GLint size = 0;
        glGetTexLevelParameteriv(GL_TEXTURE_2D, level++, GL_TEXTURE_COMPRESSED_IMAGE_SIZE, &size);
        csize += size;
        if(max(lw, lh) <= 1) break;
        if(lw > 1) lw /= 2;
        if(lh > 1) lh /= 2;
    }

    DDSURFACEDESC2 d;
    memset(&d, 0, sizeof(d));
    d.dwSize = sizeof(DDSURFACEDESC2);
    d.dwWidth = width;
    d.dwHeight = height;
    d.dwLinearSize = csize;
    d.dwFlags = DDSD_CAPS | DDSD_HEIGHT | DDSD_WIDTH | DDSD_PIXELFORMAT | DDSD_LINEARSIZE | DDSD_MIPMAPCOUNT;
    d.ddsCaps.dwCaps = DDSCAPS_TEXTURE | DDSCAPS_COMPLEX | DDSCAPS_MIPMAP;
    d.ddpfPixelFormat.dwSize = sizeof(DDPIXELFORMAT);
    d.ddpfPixelFormat.dwFlags = DDPF_FOURCC | (alphaformat(uncompressedformat(format)) ? DDPF_ALPHAPIXELS : 0);
    d.ddpfPixelFormat.dwFourCC = fourcc;

    uchar *data = new uchar[csize], *dst = data;
    for(int lw = width, lh = height;;)
    {
        GLint size;
        glGetTexLevelParameteriv(GL_TEXTURE_2D, d.dwMipMapCount, GL_TEXTURE_COMPRESSED_IMAGE_SIZE, &size);
        glGetCompressedTexImage_(GL_TEXTURE_2D, d.dwMipMapCount++, dst);
        dst += size;
        if(max(lw, lh) <= 1) break;
        if(lw > 1) lw /= 2;
        if(lh > 1) lh /= 2;
    }

    lilswap((uint *)&d, sizeof(d)/sizeof(uint));

    f->write("DDS ", 4);
    f->write(&d, sizeof(d));
    f->write(data, csize);
    delete f;

    delete[] data;

    conoutf("wrote DDS file %s", outfile);

    setuptexcompress();
}
COMMAND(gendds, "ss");

void writepngchunk(stream *f, const char *type, uchar *data = NULL, uint len = 0)
{
    f->putbig<uint>(len);
    f->write(type, 4);
    f->write(data, len);

    uint crc = crc32(0, Z_NULL, 0);
    crc = crc32(crc, (const Bytef *)type, 4);
    if(data) crc = crc32(crc, data, len);
    f->putbig<uint>(crc);
}

VARP(compresspng, 0, 9, 9);

void savepng(const char *filename, ImageData &image, bool flip)
{
    uchar ctype = 0;
    switch(image.bpp)
    {
        case 1: ctype = 0; break;
        case 2: ctype = 4; break;
        case 3: ctype = 2; break;
        case 4: ctype = 6; break;
        default: conoutf(CON_ERROR, "failed saving png to %s", filename); return;
    }
    stream *f = openfile(filename, "wb");
    if(!f) { conoutf(CON_ERROR, "could not write to %s", filename); return; }

    uchar signature[] = { 137, 80, 78, 71, 13, 10, 26, 10 };
    f->write(signature, sizeof(signature));

    struct pngihdr
    {
        uint width, height;
        uchar bitdepth, colortype, compress, filter, interlace;
    } ihdr = { bigswap<uint>(image.w), bigswap<uint>(image.h), 8, ctype, 0, 0, 0 };
    writepngchunk(f, "IHDR", (uchar *)&ihdr, 13);

    stream::offset idat = f->tell();
    uint len = 0;
    f->write("\0\0\0\0IDAT", 8);
    uint crc = crc32(0, Z_NULL, 0);
    crc = crc32(crc, (const Bytef *)"IDAT", 4);

    z_stream z;
    z.zalloc = NULL;
    z.zfree = NULL;
    z.opaque = NULL;

    if(deflateInit(&z, compresspng) != Z_OK)
        goto error;

    uchar buf[1<<12];
    z.next_out = (Bytef *)buf;
    z.avail_out = sizeof(buf);

    loopi(image.h)
    {
        uchar filter = 0;
        loopj(2)
        {
            z.next_in = j ? (Bytef *)image.data + (flip ? image.h-i-1 : i)*image.pitch : (Bytef *)&filter;
            z.avail_in = j ? image.w*image.bpp : 1;
            while(z.avail_in > 0)
            {
                if(deflate(&z, Z_NO_FLUSH) != Z_OK) goto cleanuperror;
                #define FLUSHZ do { \
                    int flush = sizeof(buf) - z.avail_out; \
                    crc = crc32(crc, buf, flush); \
                    len += flush; \
                    f->write(buf, flush); \
                    z.next_out = (Bytef *)buf; \
                    z.avail_out = sizeof(buf); \
                } while(0)
                FLUSHZ;
            }
        }
    }

    for(;;)
    {
        int err = deflate(&z, Z_FINISH);
        if(err != Z_OK && err != Z_STREAM_END) goto cleanuperror;
        FLUSHZ;
        if(err == Z_STREAM_END) break;
    }

    deflateEnd(&z);

    f->seek(idat, SEEK_SET);
    f->putbig<uint>(len);
    f->seek(0, SEEK_END);
    f->putbig<uint>(crc);

    writepngchunk(f, "IEND");

    delete f;
    return;

cleanuperror:
    deflateEnd(&z);

error:
    delete f;

    conoutf(CON_ERROR, "failed saving png to %s", filename);
}

struct tgaheader
{
    uchar  identsize;
    uchar  cmaptype;
    uchar  imagetype;
    uchar  cmaporigin[2];
    uchar  cmapsize[2];
    uchar  cmapentrysize;
    uchar  xorigin[2];
    uchar  yorigin[2];
    uchar  width[2];
    uchar  height[2];
    uchar  pixelsize;
    uchar  descbyte;
};

VARP(compresstga, 0, 1, 1);

void savetga(const char *filename, ImageData &image, bool flip)
{
    switch(image.bpp)
    {
        case 3: case 4: break;
        default: conoutf(CON_ERROR, "failed saving tga to %s", filename); return;
    }

    stream *f = openfile(filename, "wb");
    if(!f) { conoutf(CON_ERROR, "could not write to %s", filename); return; }

    tgaheader hdr;
    memset(&hdr, 0, sizeof(hdr));
    hdr.pixelsize = image.bpp*8;
    hdr.width[0] = image.w&0xFF;
    hdr.width[1] = (image.w>>8)&0xFF;
    hdr.height[0] = image.h&0xFF;
    hdr.height[1] = (image.h>>8)&0xFF;
    hdr.imagetype = compresstga ? 10 : 2;
    f->write(&hdr, sizeof(hdr));

    uchar buf[128*4];
    loopi(image.h)
    {
        uchar *src = image.data + (flip ? i : image.h - i - 1)*image.pitch;
        for(int remaining = image.w; remaining > 0;)
        {
            int raw = 1;
            if(compresstga)
            {
                int run = 1;
                for(uchar *scan = src; run < min(remaining, 128); run++)
                {
                    scan += image.bpp;
                    if(src[0]!=scan[0] || src[1]!=scan[1] || src[2]!=scan[2] || (image.bpp==4 && src[3]!=scan[3])) break;
                }
                if(run > 1)
                {
                    f->putchar(0x80 | (run-1));
                    f->putchar(src[2]); f->putchar(src[1]); f->putchar(src[0]);
                    if(image.bpp==4) f->putchar(src[3]);
                    src += run*image.bpp;
                    remaining -= run;
                    if(remaining <= 0) break;
                }
                for(uchar *scan = src; raw < min(remaining, 128); raw++)
                {
                    scan += image.bpp;
                    if(src[0]==scan[0] && src[1]==scan[1] && src[2]==scan[2] && (image.bpp!=4 || src[3]==scan[3])) break;
                }
                f->putchar(raw - 1);
            }
            else raw = min(remaining, 128);
            uchar *dst = buf;
            loopj(raw)
            {
                dst[0] = src[2];
                dst[1] = src[1];
                dst[2] = src[0];
                if(image.bpp==4) dst[3] = src[3];
                dst += image.bpp;
                src += image.bpp;
            }
            f->write(buf, raw*image.bpp);
            remaining -= raw;
        }
    }

    delete f;
}

enum
{
    IMG_BMP = 0,
    IMG_TGA = 1,
    IMG_PNG = 2,
    NUMIMG
};

VARP(screenshotformat, 0, IMG_PNG, NUMIMG-1);

const char *imageexts[NUMIMG] = { ".bmp", ".tga", ".png" };

int guessimageformat(const char *filename, int format = IMG_BMP)
{
    int len = strlen(filename);
    loopi(NUMIMG)
    {
        int extlen = strlen(imageexts[i]);
        if(len >= extlen && !strcasecmp(&filename[len-extlen], imageexts[i])) return i;
    }
    return format;
}

void saveimage(const char *filename, int format, ImageData &image, bool flip = false)
{
    switch(format)
    {
        case IMG_PNG: savepng(filename, image, flip); break;
        case IMG_TGA: savetga(filename, image, flip); break;
        default:
        {
            ImageData flipped(image.w, image.h, image.bpp, image.data);
            if(flip) texflip(flipped);
            SDL_Surface *s = wrapsurface(flipped.data, flipped.w, flipped.h, flipped.bpp);
            if(!s) break;
            stream *f = openfile(filename, "wb");
            if(f)
            {
                SDL_SaveBMP_RW(s, f->rwops(), 1);
                delete f;
            }
            SDL_FreeSurface(s);
            break;
        }
    }
}

bool loadimage(const char *filename, ImageData &image)
{
    SDL_Surface *s = loadsurface(path(filename, true));
    if(!s) return false;
    image.wrap(s);
    return true;
}

SVARP(screenshotdir, "screenshot");

void screenshot(char *filename)
{
    static string buf;
    int format = -1, dirlen = 0;
    copystring(buf, screenshotdir);
    if(screenshotdir[0])
    {
        dirlen = strlen(buf);
        if(buf[dirlen] != '/' && buf[dirlen] != '\\' && dirlen+1 < (int)sizeof(buf)) { buf[dirlen++] = '/'; buf[dirlen] = '\0'; }
        const char *dir = findfile(buf, "w");
        if(!fileexists(dir, "w")) createdir(dir);
    }
    if(filename[0])
    {
        concatstring(buf, filename);
        format = guessimageformat(buf, -1);
    }
    else
    {
        string sstime;
        time_t t = time(NULL);
        size_t len = strftime(sstime, sizeof(sstime), "%Y-%m-%d_%H.%M.%S", localtime(&t));
        sstime[min(len, sizeof(sstime)-1)] = '\0';
        concatstring(buf, sstime);

        const char *map = game::getclientmap();
        if(map && map[0])
        {
            concatstring(buf, "_");
            concatstring(buf, map);
        }
        for(char *s = &buf[dirlen]; *s; s++) if(iscubespace(*s) || *s == '/' || *s == '\\') *s = '-';
    }
    if(format < 0)
    {
        format = screenshotformat;
        concatstring(buf, imageexts[format]);
    }

    ImageData image(screenw, screenh, 3);
    glPixelStorei(GL_PACK_ALIGNMENT, texalign(image.data, screenw, 3));
    glReadPixels(0, 0, screenw, screenh, GL_RGB, GL_UNSIGNED_BYTE, image.data);
    saveimage(path(buf), format, image, true);
}

COMMAND(screenshot, "s");

void flipnormalmapy(char *destfile, char *normalfile) // jpg/png/tga-> tga
{
    ImageData ns;
    if(!loadimage(normalfile, ns)) return;
    ImageData d(ns.w, ns.h, 3);
    readwritetex(d, ns,
        dst[0] = src[0];
        dst[1] = 255 - src[1];
        dst[2] = src[2];
    );
    saveimage(destfile, guessimageformat(destfile, IMG_TGA), d);
}

void mergenormalmaps(char *heightfile, char *normalfile) // jpg/png/tga + tga -> tga
{
    ImageData hs, ns;
    if(!loadimage(heightfile, hs) || !loadimage(normalfile, ns) || hs.w != ns.w || hs.h != ns.h) return;
    ImageData d(ns.w, ns.h, 3);
    read2writetex(d, hs, srch, ns, srcn,
        *(bvec *)dst = bvec(((bvec *)srcn)->tonormal().mul(2).add(((bvec *)srch)->tonormal()).normalize());
    );
    saveimage(normalfile, guessimageformat(normalfile, IMG_TGA), d);
}

void normalizenormalmap(char *destfile, char *normalfile) // jpg/png/tga-> tga
{
    ImageData ns;
    if(!loadimage(normalfile, ns)) return;
    ImageData d(ns.w, ns.h, 3);
    readwritetex(d, ns,
        *(bvec *)dst = bvec(src[0], src[1], src[2]).normalize();
    );
    saveimage(destfile, guessimageformat(destfile, IMG_TGA), d);
}

void removealphachannel(char *destfile, char *rgbafile)
{
    ImageData ns;
    if(!loadimage(rgbafile, ns)) return;
    ImageData d(ns.w, ns.h, 3);
    readwritetex(d, ns,
        dst[0] = src[0];
        dst[1] = src[1];
        dst[2] = src[2];
    );
    saveimage(destfile, guessimageformat(destfile, IMG_TGA), d);
}

COMMAND(flipnormalmapy, "ss");
COMMAND(mergenormalmaps, "ss");
COMMAND(normalizenormalmap, "ss");
COMMAND(removealphachannel, "ss");

/* OF */

LUAICOMMAND(texture_get_data, {
    const char *fn = "";
    if (!lua_isnoneornil(L, 1)) fn = luaL_checkstring(L, 1);

    ImageData d;
    if (!loadimage(fn, d)) return 0;

    lua_pushinteger(L, d.w);
    lua_pushinteger(L, d.h);

    lua_createtable(L,  d.w, 0);
    for (int x = 0; x < d.w; ++x)
    {
        lua_pushinteger(L, x + 1);
        lua_createtable(L,  d.h, 0);
        for (int y = 0; y < d.h; ++y)
        {
            uchar *p = d.data + y * d.pitch + x * d.bpp;

            Uint32 ret;
            switch (d.bpp)
            {
                case 1:
                    ret = *p;
                    break;
                case 2:
                    ret = *(Uint16*)p;
                    break;
                case 3:
                    if (SDL_BYTEORDER == SDL_BIG_ENDIAN)
                        ret = (p[0] << 16 | p[1] << 8 | p[2]);
                    else
                        ret = (p[0] | p[1] << 8 | p[2] << 16);
                    break;
                case 4:
                    ret = *(Uint32*)p;
                    break;
                default:
                    ret = 0;
                    break;
            }

            uchar r; uchar g; uchar b;
            SDL_GetRGB(ret, ((SDL_Surface*)d.owner)->format, &r, &g, &b);

            lua_pushinteger(L, y + 1);
            lua_createtable(L, 0, 3);
            lua_pushinteger(L, r); lua_setfield(L, -2, "r");
            lua_pushinteger(L, g); lua_setfield(L, -2, "g");
            lua_pushinteger(L, b); lua_setfield(L, -2, "b");
            lua_settable   (L, -3);
        }
        lua_settable(L, -3);
    }
    return 3;
});

CLUAICOMMAND(texture_load, Texture*, (const char *name), {
    return textureload(name, 3, true, false);
});

CLUAICOMMAND(texture_get_notexture, Texture*, (), {
    return notexture;
});

CLUAICOMMAND(texture_load_alpha_mask, uchar*, (Texture *tex), {
    return loadalphamask(tex);
});

VAR(thumbtime, 0, 25, 1000);
static int lastthumbnail = 0;

static void quad(float x, float y, float w, float h, const vec2 tc[4])
{
    gle::defvertex(2);
    gle::deftexcoord0();
    gle::begin(GL_TRIANGLE_STRIP);
    gle::attribf(x+w, y);   gle::attrib(tc[1]);
    gle::attribf(x,   y);   gle::attrib(tc[0]);
    gle::attribf(x+w, y+h); gle::attrib(tc[2]);
    gle::attribf(x,   y+h); gle::attrib(tc[3]);
    gle::end();
}

static void drawslot(Slot &slot, VSlot &vslot, float w, float h, float x, float y) {
    if (slot.sts.empty()) return;
    VSlot *layer = NULL, *decal = NULL;
    Texture *t = NULL, *glowtex = NULL, *layertex = NULL, *decaltex = NULL;
    if (slot.loaded) {
        t = slot.sts[0].t;
        if (t == notexture) return;
        Slot &slot = *vslot.slot;
        if (slot.texmask&(1<<TEX_GLOW)) {
            loopvj(slot.sts) if (slot.sts[j].type==TEX_GLOW) {
                glowtex = slot.sts[j].t; break;
            }
        }
        if (vslot.layer) {
            layer = &lookupvslot(vslot.layer);
            if (!layer->slot->sts.empty()) layertex = layer->slot->sts[0].t;
        }
        if (vslot.decal) {
            decal = &lookupvslot(vslot.decal);
            if (!decal->slot->sts.empty()) decaltex = decal->slot->sts[0].t;
        }
    } else {
        if (!slot.thumbnail) {
            if(totalmillis - lastthumbnail < thumbtime) return;
            loadthumbnail(slot);
            lastthumbnail = totalmillis;
        }
        if (slot.thumbnail != notexture) t = slot.thumbnail;
        else return;
    }
    SETSHADER(hudrgb);
    vec2 tc[4] = { vec2(0, 0), vec2(1, 0), vec2(1, 1), vec2(0, 1) };
    int xoff = vslot.offset.x, yoff = vslot.offset.y;
    if (vslot.rotation) {
        if ((vslot.rotation & 5) == 1) {
            swap(xoff, yoff); loopk(4) swap(tc[k].x, tc[k].y);
        }
        if (vslot.rotation >= 2 && vslot.rotation <= 4) {
            xoff *= -1; loopk(4) tc[k].x *= -1;
        }
        if (vslot.rotation <= 2 || vslot.rotation == 5) {
            yoff *= -1; loopk(4) tc[k].y *= -1;
        }
    }
    float xt = min(1.0f, t->xs/float(t->ys)),
          yt = min(1.0f, t->ys/float(t->xs));
    loopk(4) {
        tc[k].x = tc[k].x/xt - float(xoff)/t->xs;
        tc[k].y = tc[k].y/yt - float(yoff)/t->ys;
    }
    glBindTexture(GL_TEXTURE_2D, t->id);
    if (slot.loaded) gle::color(vslot.colorscale);
    else gle::colorf(1, 1, 1);
    quad(x, y, w, h, tc);
    if (decaltex) {
        glBindTexture(GL_TEXTURE_2D, decaltex->id);
        quad(x + w/2, y + h/2, w/2, h/2, tc);
    }
    if (glowtex) {
        glBlendFunc(GL_SRC_ALPHA, GL_ONE);
        glBindTexture(GL_TEXTURE_2D, glowtex->id);
        gle::color(vslot.glowcolor);
        quad(x, y, w, h, tc);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }
    if(layertex) {
        glBindTexture(GL_TEXTURE_2D, layertex->id);
        gle::color(layer->colorscale);
        quad(x, y, w/2, h/2, tc);
    }
    gle::colorf(1, 1, 1);
    hudshader->set();
}

CLUAICOMMAND(texture_draw_slot, void, (int idx, float w, float h, float x, float y), {
    Slot &slot = lookupslot(idx, false);
    drawslot(slot, *slot.variants, w, h, x, y);
});

CLUAICOMMAND(texture_draw_vslot, void, (int idx, float w, float h, float x, float y), {
    VSlot &vslot = lookupvslot(idx, false);
    drawslot(*vslot.slot, vslot, w, h, x, y);
});

CLUAICOMMAND(thumbnail_load, Texture*, (const char *p, bool force), {
    string tname;
    copystring(tname, p);
    Texture *t = textures.access(path(tname));
    if (t) goto finalize;

    copystring(tname, makerelpath(NULL, p, "<thumbnail>", NULL));
    t = textures.access(path(tname));
    if (t) goto finalize;

    if (force || (totalmillis - lastthumbnail) >= thumbtime)
        t = textureload(p, 3, true, false);

    if (!t || t == notexture) {
        return notexture;
    }
finalize:
    lastthumbnail = totalmillis;
    return t;
})

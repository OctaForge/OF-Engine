/*
 * of_tools.h, version 1
 * Various utilities for OctaForge engine (header)
 *
 * author: q66 <quaker66@gmail.com>
 * license: MIT/X11
 *
 * Copyright (c) 2011 q66
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#ifndef OF_TOOLS_H
#define OF_TOOLS_H

#define OF_CFG_VERSION 2

namespace tools
{
    bool  valanumeric(const char *str, const char *allow);
    bool  valrpath(const char *path);

    bool  fnewer(const char *file, const char *otherfile);
    bool  fcopy(const char *src, const char *dest);
    bool  fdel(const char *file);
    bool  fempty(const char *file);

    bool  mkpath(const char *path);
    char *sread(const char *fname);

    void  writecfg(const char *name = NULL);
    bool  execcfg(const char *cfgfile, bool ignore_ret = false);

    int   currtime();
} /* end namespace tools */

#endif

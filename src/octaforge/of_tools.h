/*
 * of_tools.h, version 1
 * Various utilities for OctaForge engine (header)
 *
 * author: q66 <quaker66@gmail.com>
 * license: see COPYING.txt
 */

#ifndef OF_TOOLS_H
#define OF_TOOLS_H

#define OF_CFG_VERSION 3

namespace tools
{
    bool  valanumeric(const char *str, const char *allow);
    bool  valrpath(const char *path);

    bool  fnewer(const char *file, const char *otherfile);
    bool  fcopy(const char *src, const char *dest);
    bool  fdel(const char *file);
    bool  fempty(const char *file);

    bool  execfile(const char *cfgfile, bool msg = true);
} /* end namespace tools */

#endif

/*
 * of_logger.cpp, version 1
 * Logging facilities for OctaForge.
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

#include "cube.h"
#include "engine.h"
#include "of_tools.h"

namespace logger
{
    int current_indent = 0;

    const char *names[LEVELNUM] = { "INFO", "DEBUG", "WARNING", "ERROR", "INIT", "OFF" };
    loglevel  numbers[LEVELNUM] = {  INFO,   DEBUG,   WARNING,   ERROR,   INIT,   OFF  };
    loglevel  current_level     = WARNING;

    loglevel name_to_num(const char *name)
    {
        for (int i = 0; i < LEVELNUM; i++)
            if (!strcmp( names[i], name))
                return numbers[i];

        log(ERROR, "no such loglevel: %s\n", name);
        return numbers[0];
    }

    void setlevel(loglevel level)
    {
        assert(level >= 0 && level < LEVELNUM);

        current_level = level;
        printf("<<< setting loglevel to %s >>>\n", names[level]);
    }

    void setlevel(const char *level)
    {
        setlevel(name_to_num(level));
    }

    bool should_log(loglevel level)
    {
        return (level >= current_level);
    }

    void log(loglevel level, const char *fmt, ...)
    {
        assert (current_level >= 0 && current_level < LEVELNUM);
        if (!should_log(level)) return;

        const char *level_s = names[level];

        for (int i = 0; i < current_indent; i++)
            printf("    ");

        va_list  ap;
        va_start(ap, fmt);
        types::string buf = types::string().format(fmt, ap);
        va_end(ap);

#ifdef CLIENT
        if (level == ERROR)
        {
            conoutf(CON_ERROR, types::string().format(
                "[[%s]] - %s", level_s, buf.get_buf()
            ).get_buf());
        }
        else
#endif
        printf("[[%s]] - %s", level_s, buf.get_buf());

        fflush(stdout);
    }

    logindent::logindent(loglevel level)
    {
        if (should_log(level))
        {
             current_indent++;
             done = true;
        }
        else done = false;
    }

    logindent::~logindent()
    {
        if (done) current_indent--;
    }
} /* end namespace logger */

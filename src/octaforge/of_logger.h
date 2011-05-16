/*
 * of_logger.h, version 1
 * Logging facilities for OctaForge (header)
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

#ifndef OF_LOGGER_H
#define OF_LOGGER_H

#define INDENT_LOG(level) logger::logindent ind(level)

namespace logger
{
    #define LEVELNUM 6

    enum loglevel
    {
        INFO,
        DEBUG,
        WARNING,
        ERROR,
        INIT,
        OFF
    };

    loglevel name_to_num(const char *name);
    void setlevel       (loglevel    level);
    void setlevel       (const char *level = "WARNING");
    bool should_log     (loglevel    level);
    void log            (loglevel    level, const char *fmt, ...);

    extern loglevel    current_level;
    extern loglevel    numbers[LEVELNUM];
    extern const char *names  [LEVELNUM];

    struct logindent
    {
        logindent(loglevel level);
       ~logindent();
        bool done;
    };
} /* end namespace logger */

#endif

/*
 * of_logger.cpp, version 1
 * Logging facilities for OctaForge.
 *
 * author: q66 <daniel@octaforge.org>
 * license: see COPYING.txt
 */

#include "cube.h"
#include "engine.h"

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

        char sbuf[512];
        char *buf = sbuf;
        va_list ap;
#if defined(WIN32) && !defined(__GNUC__)
        va_start(ap, fmt);
        size_t len = _vscprintf(fmt, ap);
        if (len >= sizeof(sbuf)) {
            buf = new char[len + 1];
        }
        _vsnprintf(buf, len + 1, fmt, ap);
        va_end(ap);
#else
        va_start(ap, fmt);
        size_t len = vsnprintf(sbuf, sizeof(sbuf), fmt, ap);
        va_end(ap);
        if (len >= sizeof(sbuf)) {
            buf = new char[len + 1];
            va_start(ap, fmt);
            vsnprintf(buf, len + 1, fmt, ap);
            va_end(ap);
        }
#endif

#ifndef STANDALONE
        if (level == ERROR) {
            conoutf(CON_ERROR, "[[%s]] - %s", level_s, buf);
        }
        else
#endif
        logoutf("[[%s]] - %s", level_s, buf);
        if (buf != sbuf) {
            delete[] buf;
        }

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

    CLUAICOMMAND(log, void, (int level, const char *msg), {
        log((loglevel)level, "%s", msg);
    });

    CLUAICOMMAND(should_log, bool, (int level), {
        return should_log((loglevel)level);
    });

    CLUAICOMMAND(echo, void, (const char *msg), {
        conoutf("\f1%s", msg);
    });
} /* end namespace logger */

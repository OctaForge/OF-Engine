/*
 * of_logger.h, version 1
 * Logging facilities for OctaForge (header)
 *
 * author: q66 <quaker66@gmail.com>
 * license: see COPYING.txt
 */

#ifndef OF_LOGGER_H
#define OF_LOGGER_H

#define INDENT_LOG(level) logger::logindent ind(level)

/* Windows */
#ifdef ERROR
#undef ERROR
#endif

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

/*
 * of_localserver.cpp, version 1
 * Local server handler for OctaForge.
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
#include "of_tools.h"
#include "of_localserver.h"
#include "client_system.h"

extern string homedir;

void trydisconnect();

namespace local_server
{
    /* private prototypes */
    bool is_ready();

    int last_connect_trial = 0;
    int num_trials         = 0;

    bool ready   = false;
    bool started = false;

    /* get this into use at some point to make this server runner better. */
    FILE *popen_out = NULL;

    bool is_running()
    {
        return ready;
    }

    void try_connect()
    {
        if (!ready && started && num_trials <= 20 && lastmillis - last_connect_trial >= 1000)
        {
            if (is_ready())
            {
                ready = true;
                ClientSystem::connect("127.0.0.1", 28787);
            }
            else conoutf("Waiting for server to finish starting up .. (%i)", num_trials);

            if (num_trials == 20)
                logger::log(logger::ERROR, "Failed to start server. See "SERVER_LOGFILE" for more information.\n");

            num_trials++;
            last_connect_trial = lastmillis;
        }
    }

    void run(const char *map)
    {
        if (started)
        {
            conoutf("Stopping old server instance ..");
            stop();
        }
        conoutf("Starting server, please wait ..");

        types::string buf = types::string().format(
            "%s -g%s -mmaps/%s.tar.gz -shutdown-if-idle -shutdown-if-empty >\"%s%s\" 2>&1",
#ifdef WIN32
            "run_server.bat",
#else
            "exec ./run_server.sh",
#endif
            logger::names[logger::current_level], map, homedir, SERVER_LOGFILE
        );

#ifdef WIN32
        popen_out = _popen(buf.buf, "r");
#else
        popen_out =  popen(buf.buf, "r");
#endif

        started = true;
    }

    void stop()
    {
        if (!started) return;

        trydisconnect();
#ifdef WIN32
        _pclose(popen_out);
#else
         pclose(popen_out);
#endif

        last_connect_trial = num_trials = 0;
        ready = started = false;
    }

    bool is_ready()
    {
        defformatstring(path)("%s%s", homedir, SERVER_READYFILE);
        if (fileexists(path, "r"))
        {
            tools::fdel(path);
            return true;
        }
        else return false;
    }
} /* end namespace local_server */


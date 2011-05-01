/*
 * of_localserver.c, version 1
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

/* General includes */
#include "cube.h"

/* OF includes */
#include "of_tools.h"
#include "of_localserver.h"

/* old Syntensity includes. */
#include "client_system.h"

/* Access the home directory. */
extern string homedir;

/* Engine-wide prototypes. */
void trydisconnect();
/* Nasty extern abuse */
namespace Logging
{
    extern Level currLevel;
    extern std::string levelNames[6];
}

/* Private OF localserver prototypes */
bool is_server_ready();

/* Private variables */
char localserver_buf[4096];

int last_connect_trial = 0;
int num_trials         = 0;

bool server_ready     = false;
bool server_started   = false;

/* Return true if local server is running, false otherwise. */
bool of_localserver_get_running() { return server_ready; }

/*
 * Try connecting. Ran in mainloop every frame, but doesn't usually
 * pass the first condition which is fast (only integral comparisons)
 */
void of_localserver_try_connect()
{
    /* You mostly don't get through this, only when local server is stopped and you want to start it. */
    if (!server_ready && server_started && num_trials <= 20 && lastmillis - last_connect_trial >= 1000)
    {
        /*
         * if we're ready, tell the client system to connect.
         * Otherwise just keep trying. We try for 20 seconds, then just fail.
         */
        if (is_server_ready())
        {
            server_ready = true;
            ClientSystem::connect("127.0.0.1", 28787);
            return;
        }
        else conoutf("Waiting for server to finish starting up .. (%i)", num_trials);

        if (num_trials == 20)
            Logging::log(Logging::ERROR, "Failed to start server. See "SERVER_LOGFILE" for more information.\n");

        /* Increment number of trials and set millis of last trial. */
        num_trials++;
        last_connect_trial = lastmillis;
    }
}

/*
 * Run the local server. This executes the server proccess, but does not connect.
 * It also opens all required streams and sets server_started to true.
 * Before starting new instance, it stops the old one if running, so it's safe.
 */
void of_localserver_run(const char *map)
{
    /* Stop the old instance if required */
    if (server_started)
    {
        conoutf("Stopping old server instance ..");
        of_localserver_stop();
    }
    conoutf("Starting server, please wait ..");

    /* Make sure that home directory does NOT end with a slash */
    char *hdir = strdup(homedir);
    if (!strcmp(hdir + strlen(hdir) - 1,   "/"))
                hdir[  strlen(hdir) - 1] = '\0';

    /* Platform specific, so ifdef it. And open the process stream. */
    snprintf(
        localserver_buf, sizeof(localserver_buf),
        "%s -q%s -g%s -set-map:base/%s.tar.gz -shutdown-if-idle -shutdown-if-empty >%s/%s 2>&1",
#ifdef WIN32
        "intensity_server.bat",
#else
        "exec ./intensity_server.sh",
#endif
        hdir, Logging::levelNames[Logging::currLevel].c_str(), map, hdir, SERVER_LOGFILE
    );
    OF_FREE(hdir);
#ifdef WIN32
    _popen(localserver_buf, "r");
#else
    popen(localserver_buf, "r");
#endif

    /* Inform the engine that server is started. */
    server_started = true;
}

/*
 * Stop the local server. Besides stopping it,
 * it also closes all streams and resets variables.
 */
void of_localserver_stop()
{
    /* Do not stop if not started, then attempt to disconnect. */
    if (!server_started) return;
    trydisconnect();

    /* Reset variables. */
    last_connect_trial = num_trials = 0;
    server_ready = server_started   = false;
}

/* This checks if server is ready by reading its messages. */
bool is_server_ready()
{
    /* Make sure that home directory does NOT end with a slash */
    char *hdir = strdup(homedir);
    if (!strcmp(hdir + strlen(hdir) - 1,   "/"))
                hdir[  strlen(hdir) - 1] = '\0';

    /* Build a path for the log file */
    snprintf(localserver_buf, sizeof(localserver_buf), "%s/%s", hdir, SERVER_LOGFILE);

    /* Read the file. If it's not readable, just return as not ready. */
    char *out = loadfile(localserver_buf, NULL);
    if  (!out)
    {
        OF_FREE(hdir);
        return false;
    }
    else
    {
        /* If the string was found, return as ready. */
        if (strstr(out, "[[MAP LOADING]] - Success"))
        {
            OF_FREE(hdir);
            OF_FREE(out);
            return true;
        }
        else
        {
            OF_FREE(hdir);
            OF_FREE(out);
            return false;
        }
    }
    return false;
}

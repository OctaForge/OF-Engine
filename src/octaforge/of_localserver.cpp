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
#include "game.h"
#include "of_tools.h"
#include "of_localserver.h"
#include "client_system.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

void trydisconnect(bool local);

_SVAR(server_log_file, server_log_file, "out_server.log", IDF_READONLY);

namespace local_server {
    /* private prototypes */
    bool is_ready();

    int last_connect_trial = 0;
    int num_trials         = 0;

    bool ready   = false;
    bool started = false;

    bool is_running() {
        return ready;
    }

    void try_connect() {
        if (!ready && started && num_trials <= 20
        && lastmillis - last_connect_trial >= 1000) {
            if (is_ready()) {
                ready = true;
                ClientSystem::connect("127.0.0.1", TESSERACT_SERVER_PORT);
            }
            else {
                conoutf("Waiting for server to finish starting up .. (%d)",
                    num_trials);
            }

            if (num_trials == 20) {
                logger::log(logger::ERROR,
                    "Failed to start server. See %s for more information.",
                    server_log_file);
            }

            num_trials++;
            last_connect_trial = lastmillis;
        }
    }

    static void build_args(const char *map, vector<char*> &args) {
        args.add(newstring("bin_unix/server_" BINARY_OS_STR "_"
            BINARY_ARCH_STR));
        defformatstring(arg, "-g%s", logger::names[logger::current_level]);
        args.add(newstring(arg));
        formatstring(arg, "-l%s", server_log_file);
        args.add(newstring(arg));
        formatstring(arg, "-mmap/%s.tar.gz", map);
        args.add(newstring(arg));
        copystring(arg, "-shutdown-if-idle");
        args.add(newstring(arg));
        copystring(arg, "-shutdown-if-empty");
        args.add(newstring(arg));
        args.add(NULL);
    }

    void run(const char *map) {
        if (started) {
            conoutf("Stopping old server instance ..");
            stop();
        }
        conoutf("Starting server, please wait ..");
        if (!fork()) {
            vector<char*> args;
            build_args(map, args);
            execv(args[0], args.getbuf());
            args.deletearrays();
            exit(0);
        }

        started = true;
    }

    void stop() {
        if (!started) return;
        trydisconnect(false);
        last_connect_trial = num_trials = 0;
        ready = started = false;
    }

    bool is_ready() {
        defformatstring(path, "%s%s", homedir, SERVER_READYFILE);
        if (fileexists(path, "r")) {
            tools::fdel(path);
            return true;
        }
        else return false;
    }
} /* end namespace local_server */


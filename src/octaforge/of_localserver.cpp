/*
 * of_localserver.cpp, version 1
 * Local server handler for OctaForge.
 *
 * author: q66 <quaker66@gmail.com>
 * license: see COPYING.txt
 */

#include "cube.h"
#include "game.h"
#include "of_localserver.h"
#include "client_system.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

void trydisconnect(bool local);

_SVAR(server_log_file, server_log_file, "out_server.log", IDF_READONLY);

namespace local_server {
    /* private prototypes */
    static bool is_ready();

    static int last_disconnect    = 0;
    static int last_connect_trial = 0;
    static int num_trials         = 0;

    static string map_to_run;

    static bool ready   = false;
    static bool started = false;

    bool is_running() {
        return ready;
    }

    void try_connect() {
        /* if we disconnected and now are trying to connect again */
        if (last_disconnect > 0 && lastmillis - last_disconnect >= 1000) {
            last_disconnect = 0;
            run(map_to_run);
            return;
        }
        if (!ready && started && num_trials <= 20
        && lastmillis - last_connect_trial >= 1000) {
            if (is_ready()) {
                ready = true;
                ClientSystem::connect("127.0.0.1", TESSERACT_STANDALONE_PORT);
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

    void run(const char *map) {
        if (started) {
            conoutf("Stopping old server instance ..");
            stop();
            /* sleep a bit here to give the old server time to shutdown */
            copystring(map_to_run, map);
            last_disconnect = lastmillis;
            return;
        }
        conoutf("Starting server, please wait ..");
#ifndef WIN32
        if (!fork()) {
            const char *a0 = "bin_unix/server_" BINARY_OS_STR "_"
                BINARY_ARCH_STR;

            defformatstring(a1, "-g%s", logger::names[logger::current_level]);
            defformatstring(a2, "-l%s", server_log_file);
            defformatstring(a3, "-mmap/%s.tar.gz", map);

            execl(a0, a0, a1, a2, a3, "-shutdown-if-idle",
                "-shutdown-if-empty", (char*)NULL);
            exit(0);
        }
#else
#ifdef WIN64
        const char *exe = "bin_win64\\server_" BINARY_OS_STR "_"
            BINARY_ARCH_STR ".exe";
#else
        const char *exe = "bin_win32\\server_" BINARY_OS_STR "_"
            BINARY_ARCH_STR ".exe";
#endif
        char buf[4096];
        char *cptr = buf;

        defformatstring(a1, "-g%s", logger::names[logger::current_level]);
        defformatstring(a2, "-l%s", server_log_file);
        defformatstring(a3, "-mmap/%s.tar.gz", map);
        const char a4[] = "-shutdown-if-idle";
        const char a5[] = "-shutdown-if-empty";

        size_t len = strlen(a1);
        memcpy(cptr, a1, len); cptr += len; *(cptr++) = ' ';
        len = strlen(a2);
        memcpy(cptr, a2, len); cptr += len; *(cptr++) = ' ';
        len = strlen(a3);
        memcpy(cptr, a3, len); cptr += len; *(cptr++) = ' ';
        len = sizeof(a4) - 1;
        memcpy(cptr, a4, len); cptr += len; *(cptr++) = ' ';
        len = sizeof(a5) - 1;
        memcpy(cptr, a5, len); cptr += len; *cptr = '\0';

        STARTUPINFO si;
        PROCESS_INFORMATION pi;
        ZeroMemory(&si, sizeof(si));
        si.cb = sizeof(si);
        ZeroMemory(&si, sizeof(pi));

        CreateProcess(exe, buf, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
#endif

        started = true;
    }

    void stop() {
        if (!started) return;
        trydisconnect(false);
        last_connect_trial = num_trials = 0;
        ready = started = false;
    }

    static bool is_ready() {
        defformatstring(path, "%s%s", homedir, STANDALONE_READYFILE);
        if (fileexists(path, "r")) {
#ifdef WIN32
            DeleteFile(path);
#else
            remove(path);
#endif
            return true;
        }
        else return false;
    }
} /* end namespace local_server */


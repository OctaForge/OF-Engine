
# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

import os, sys, __main__, json, shutil

## Base module - foundational stuff

WINDOWS = sys.platform.find("win32") != -1 or sys.platform.find("win64") != -1 # ??? FIXME

LINUX = sys.platform.find("linux") != -1
OSX = sys.platform.find("darwin") != -1
BSD = sys.platform.find("bsd") != -1

UNIX = LINUX or OSX or BSD

assert(WINDOWS or UNIX)

## Global constants
class Global:
    ## Read this to know if the current script is running on the client. Always the opposite of SERVER.
    CLIENT = None

    ## Read this to know if the current script is running on the server. Always the opposite of CLIENT.
    SERVER = None

    ## Called once on initialization, to mark the running instance as a client. Sets SERVER, CLIENT.
    @staticmethod
    def init_as_client():
        Global.CLIENT = True
        Global.SERVER = False

    ## Called once on initialization, to mark the running instance as a server. Sets SERVER, CLIENT.
    @staticmethod
    def init_as_server():
        Global.SERVER = True
        Global.CLIENT = False

#
# Directory stuff
#

## Directory where our python scripts and modules reside
PYTHON_SCRIPT_DIR = os.path.join("src", "python", "intensity")

_should_quit = False

## Notifies us to quit. Sauer checks should_quit, and quits if set to true
def quit():
    global _should_quit
    _should_quit = True

## @return Whether quitting has been called, and we should shut down.
def should_quit():
    global _should_quit
    return _should_quit



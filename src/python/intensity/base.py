
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


HOME_SUBDIR = None

def set_home_dir(home_dir):
    print "Set home dir:", home_dir
    global HOME_SUBDIR
    HOME_SUBDIR = home_dir

## The subdirectory under the user's home directory which we use.
def get_home_subdir():
    global HOME_SUBDIR

    if Global.CLIENT:
        suffix = "client"
    else:
        # If no home dir is given, the default for the server is to share it with the client
        suffix = "server" if HOME_SUBDIR is not None else 'client'

    # Use default value if none given to us
    if HOME_SUBDIR is None:
        if UNIX:
            HOME_SUBDIR = os.path.join( os.path.expanduser('~'), '.octaforge_'+suffix )
        elif WINDOWS:
            HOME_SUBDIR = os.path.join( os.path.expanduser('~'), 'octaforge_'+suffix )
        else:
            print "Error: Not sure where to set the home directory for this platform,", sys.platform
            raise Exception
        print 'Home dir:', HOME_SUBDIR

    # Ensure it exists.
    if not os.path.exists(HOME_SUBDIR):
        os.makedirs(HOME_SUBDIR)

    return HOME_SUBDIR


## The subdirectory name (single name) under home
def get_asset_subdir():
    return 'data'

## The directory to which the client saves assets
def get_asset_dir():
    ASSET_DIR = os.path.join( get_home_subdir(), get_asset_subdir() )

    # Ensure it exists.
    if not os.path.exists(ASSET_DIR):
        os.makedirs(ASSET_DIR)

    return ASSET_DIR

## The directory to which the client saves assets
def get_map_dir():
    MAP_DIR = os.path.join( get_asset_dir(), 'base' )

    # Ensure it exists. Done only if we are called (the server doesn't call us)
    if not os.path.exists(MAP_DIR):
        os.makedirs(MAP_DIR)

    return MAP_DIR

_should_quit = False

## Notifies us to quit. Sauer checks should_quit, and quits if set to true
def quit():
    global _should_quit
    _should_quit = True

## @return Whether quitting has been called, and we should shut down.
def should_quit():
    global _should_quit
    return _should_quit



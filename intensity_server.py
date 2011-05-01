#!/usr/bin/python

# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

from __future__ import with_statement

import os, sys, time

from intensity.base import *
Global.init_as_server()

import intensity.c_module
CModule = intensity.c_module.CModule.holder

print "Intensity Engine Server parameters:", sys.argv

execfile( os.path.join(PYTHON_SCRIPT_DIR, "init.py") )

print "Initializing C Server's Python connection system"

import __main__

print "Initializing scripting engine"
CModule.create_engine()

print "<<< Server is running in local mode - only a single client from this machine can connect >>>"

print "Initializing CModule"

CModule.init()

map_asset = None
PATTERN = "-set-map:"
for arg in sys.argv:
    if arg[:len(PATTERN)] == PATTERN:
        map_asset = arg[len(PATTERN):]

# Start server slicing and main loop

print "Preparing timing and running first slice"

NETWORK_RATE = 33.0/1000.0

CModule.slice()  # Do a single time slice

# Main loop

MASTER_UPDATE_INTERVAL = 300
last_master_update = 0

def main_loop():
    try:
        last_time = time.time()
        while not should_quit():
            # Sleep just long enough for the network rate to be ok, with a minimum so that the interactive console is responsive.
            while time.time() - last_time < NETWORK_RATE: # For some reason Python 'stutters' in timekeeping, so need a loop, not a single oprt n.
                time.sleep(NETWORK_RATE - (time.time() - last_time))
            assert(time.time() - last_time >= NETWORK_RATE - 0.0001) # 0.0001 for potential rounding errors

            # TODO: In the future, might just run CModule.slice() in a separate thread in order to get responsiveness for interactive console
            # Would need to be a *real* thread, not a CPython one
            last_time = time.time()

            if not should_quit(): # If during the sleep a quit was requested, do this immediately, do not slice any more
                CModule.slice()  # Do a single time slice

            # Update master, if necessary TODO: If we add more such things, create a modular plugin system

            global last_master_update
            global last_idle_update

            if time.time() - last_master_update >= MASTER_UPDATE_INTERVAL:
                last_master_update = time.time()
                CModule.set_map(map_asset)

    except KeyboardInterrupt:
        pass # Just exit gracefully


main_loop()

print "Stopping main server"

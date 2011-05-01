
# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

"""
Manages loading maps etc.
"""

import os, tarfile, re, httplib
import uuid

from intensity.base import *

import intensity.c_module
CModule = intensity.c_module.CModule.holder

# Globals

curr_map_asset_id = None ##< The asset id of this map, whose location gives us the prefix, etc.
curr_map_prefix = None

def get_curr_map_asset_id():
    return curr_map_asset_id

def set_curr_map_asset_id(map_asset_id):
    global curr_map_asset_id
    curr_map_asset_id = map_asset_id

def get_curr_map_prefix():
    return curr_map_prefix

def set_curr_map_prefix(prefix):
    global curr_map_prefix
    curr_map_prefix = prefix


class WorldClass:
    scenario_code = None

    def start_scenario(self):
        old_scenario_code = self.scenario_code
        while old_scenario_code == self.scenario_code:
            self.scenario_code = str(uuid.uuid4())

    def running_map(self):
        return self.scenario_code is not None


## Singleton with current world info
World = WorldClass()

## Returns the path to a file in the map script directory, i.e., a file is given in
## relative position to the current map, and we return the full path
def get_mapfile_path(relative_path):
    # Check first in the installation packages
    install_path = os.path.sep.join( os.path.join('data', World.asset_location[:-7], relative_path).split('/') )
    if os.path.exists(install_path):
        return install_path
    return os.path.join(
        os.path.join(
            CModule.get_home_dir(),
            "data",
            World.asset_location.replace('/', '\\')
            if WINDOWS else World.asset_location
        ),
        relative_path
    )


## Reads a file for Scripting. Must be done safely. The path is under /data,
## and we ensure that no attempt is made to 'break out'
def read_file_safely(name):
    assert(".." not in name)
    assert("~" not in name)
    assert(name[0] != '/')
    # TODO: More checks

    # Use relative paths, if asked for, or just a path under the asset dir
    if len(name) >= 2 and name[0:2] == './':
        path = get_mapfile_path(name[2:])
    else:
        path = os.path.join(CModule.get_home_dir(), "data", name)

    try:
        f = open(path, 'r')
    except IOError:
        try:
            install_path = os.path.join('data', name)
            f = open(install_path, 'r') # Look under install /data
        except IOError:
            print "Could not load file %s (%s, %s)" % (name, path, install_path)
            assert(0)

    data = f.read()
    f.close()

    return data


## Returns the path to the map script. TODO: As an option, other map script names?
def get_map_script_filename():
    return get_mapfile_path('map.lua')

## Runs the startup script for the current map. Called from worldio.loadworld
def run_map_script():
    script = open( get_map_script_filename(), "r").read()
    CModule.run_script(script)

def export_entities(filename):
    full_path = os.path.join(CModule.get_home_dir(), "data", get_curr_map_prefix(), filename)
    data = CModule.run_script_string("return of.logent.store.save_entities()")

    # Save backup, if needed

    if os.path.exists(full_path):
        try:
            shutil.copyfile(full_path, full_path + "." + str(time.time())[-6:].replace('.', '') + '.BAK')
        except:
            pass # No worries mate

    # Save new data

    out = open(full_path, 'w')
    out.write(data)
    out.close()


# Prevent loops

from intensity.message_system import *

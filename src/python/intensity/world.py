
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

## Returns the path to the map script. TODO: As an option, other map script names?
def get_map_script_filename():
    return get_mapfile_path('map.lua')

## Runs the startup script for the current map. Called from worldio.loadworld
def run_map_script():
    script = open( get_map_script_filename(), "r").read()
    CModule.run_script(script)

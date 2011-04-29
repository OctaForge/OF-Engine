
# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

"""
Manages loading maps etc.
"""

import os, tarfile, re, httplib
import uuid

from _dispatch import Signal

from intensity.base import *
from intensity.logging import *

# Signals

map_load_start = Signal(providing_args=['activity_id', 'map_asset_id'])
map_load_finish = Signal() # Only sent if map loads successfully


# Globals

curr_activity_id = None ##< The activity ID of the current activity
curr_map_asset_id = None ##< The asset id of this map, whose location gives us the prefix, etc.
curr_map_prefix = None

def get_curr_activity_id():
    return curr_activity_id

def set_curr_activity_id(activity_id):
    global curr_activity_id
    curr_activity_id = activity_id

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

## Sets a map to be currently active, and starts a new scenario
## @param _map The asset id for the map (see curr_map_asset_id)
def set_map(activity_id, map_asset_id):
    log(logging.DEBUG, "Setting the map to %s / %s" % (activity_id, map_asset_id))

    # Determine map activity and asset and get asset info

    if Global.SERVER:
        forced_location = get_config('Activity', 'force_location', '')
        if forced_location != '':
            activity_id = '*FORCED*'
            map_asset_id = forced_location # Contains 'base/'
    else: # CLIENT
        parts = map_asset_id.split('/')
        if parts[0] == 'base':
            set_config('Activity', 'force_location', map_asset_id)

    asset_info = AssetInfo('xyz', map_asset_id, '?', 'NONE', [], 'b')

    log(logging.DEBUG, "final setting values: %s / %s" % (activity_id, map_asset_id))

    map_load_start.send(None, activity_id=activity_id, map_asset_id=map_asset_id)

    World.start_scenario()

    # Server may take a while to load and set up the map, so tell clients
    if Global.SERVER:
        MessageSystem.send(ALL_CLIENTS, CModule.PrepareForNewScenario, World.scenario_code)
        CModule.force_network_flush() # Flush message immediately to clients

    # Set globals

    set_curr_activity_id(activity_id)
    set_curr_map_asset_id(map_asset_id)
    World.asset_info = asset_info

    curr_map_prefix = asset_info.get_zip_location() + os.sep # asset_info.location
    set_curr_map_prefix(curr_map_prefix)

    log(logging.DEBUG, "Map locations: %s -- %s ++ %s" % (asset_info.location, curr_map_prefix, AssetManager.get_full_location(asset_info)))

    # Load the geometry and map settings in the .ogz
    if not CModule.load_world(curr_map_prefix + "map"):
        log(logging.ERROR, "Could not load map %s" % curr_map_prefix)
        raise Exception("set_map failure")

    if Global.SERVER:
        # Create script entities for connected clients
        log(logging.DEBUG, "Creating lua entities for map")
        CModule.create_lua_entities()

        auth.InstanceStatus.map_loaded = True

        # Send map to all connected clients, if any
        send_curr_map(ALL_CLIENTS)

        # Initialize instance status for this new map
        auth.InstanceStatus.private_edit_mode = False

    map_load_finish.send(None)

    return True # TODO: Do something with this value


def restart_map():
    set_map(get_curr_activity_id(), get_curr_map_asset_id())


## Returns the path to a file in the map script directory, i.e., a file is given in
## relative position to the current map, and we return the full path
def get_mapfile_path(relative_path):
    # Check first in the installation packages
    install_path = os.path.sep.join( os.path.join('data', World.asset_info.get_zip_location(), relative_path).split('/') )
    if os.path.exists(install_path):
        return install_path
    return os.path.join(World.asset_info.get_zip_location(AssetManager.get_full_location(World.asset_info)), relative_path)


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
        path = os.path.join( get_asset_dir(), name )

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
    log(logging.DEBUG, "Running map script...")
    CModule.run_script(script)
    log(logging.DEBUG, "Running map script complete..")

def export_entities(filename):
    full_path = os.path.join(get_asset_dir(), get_curr_map_prefix(), filename)
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

from intensity.asset import *
from intensity.message_system import *

if Global.SERVER:
    from intensity.server.persistence import *


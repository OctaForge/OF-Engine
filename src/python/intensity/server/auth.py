
# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

from intensity.logging import *


class InstanceStatus:
    in_standby = False

    ##! A server is run in local mode when its address is 'localhost'
    ##! In this mode, an instance will only let a single client connect to it,
    ##! from the same machine. This is useful for editing (stuff like heightmaps etc.
    ##! only work in this mode, they are not available in multiplayer())
    local_mode = False

    ##! Private edit mode means that only a single client may connect to this instance
    ##! (which can then, like with local mode, use heightmaps etc.).
    private_edit_mode = False

    map_loaded = False

def check_local_mode():
    InstanceStatus.local_mode = (str(get_config('Network', 'address', 'localhost')) == 'localhost')
    return InstanceStatus.local_mode

def update_master():
    log(logging.DEBUG, "Updating master...")

    def do_set_map():
        set_map(get_config('Activity', 'force_activity_id', ''), get_config('Activity', 'force_map_asset_id', ''))
    main_actionqueue.add_action(do_set_map)

# Prevent loops

from intensity.server.persistence import *
from intensity.world import *


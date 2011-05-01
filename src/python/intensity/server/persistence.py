
# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

import os, sys, shutil, time

from intensity.base import *
from intensity.message_system import *

def send_curr_map(client_number):
    if not World.running_map():
        return

    MessageSystem.send(client_number, CModule.NotifyAboutCurrentScenario, get_curr_map_asset_id(), World.scenario_code)


from intensity.world import *


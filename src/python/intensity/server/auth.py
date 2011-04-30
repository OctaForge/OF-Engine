
# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

class InstanceStatus:
    local_mode = True
    private_edit_mode = False

# Prevent loops

from intensity.server.persistence import *
from intensity.world import *


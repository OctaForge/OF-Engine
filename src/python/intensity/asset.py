
# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

import os
from intensity.logging import *

class AssetInfo:
    def __init__(self, asset_id, location, url, _hash, dependencies, _type):
        self.asset_id = asset_id
        self.location = location
        self.url = url
        self._hash = _hash ##< Form: "TYPE|HASHVAL", e.g.: "SHA256|ABE1723762", sha256 with ABE1723762
        self.dependencies = dependencies
        self._type = _type

    ## For a zipfile, returns the part of the location that is the basis, i.e., without the
    ## trailing .tar.gz or .zip
    ## @param name If None (not given), then use the location of this instance
    def get_zip_location(self, name=None):
        if name is None:
            name = self.location
        return name[:-7]


class AssetManagerClass:
    def get_full_location(self, asset_info):
        location = asset_info.location
        # We will use this as an actual path now, so fix for Windows
        if WINDOWS:
            location = location.replace('/', '\\')
        return os.path.join( get_asset_dir(), location)

# Singleton
AssetManager = AssetManagerClass()


# Prevent loops
from intensity.base import *


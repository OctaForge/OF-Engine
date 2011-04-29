
# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

import os, cgi, urllib, time, tempfile, hashlib, shutil, httplib, pickle, tarfile, urlparse
from functools import partial

from _dispatch import Signal

from intensity.logging import *
from intensity.post_multipart import post_multipart
from intensity.signals import multiple_send
from intensity.errors import IntensityUserCancellation


# Signals

# Called when checking if an asset exists in up-to-date form locally
check_existing = Signal(providing_args=['asset_info'])

# Called when an asset is actually modified, and when a file inside it (if it is
# an archive) is modified. In the latter case 'filename' is given. Filenames
# are relative to the home_dir/data/
asset_item_updated = Signal(providing_args=['asset_info', 'filename'])

# Errors

class AssetRetrievalError(Exception):
    pass


def calculate_hash(filename, hasher):
    try:
        f = open(filename, "rb")
        data = f.read()
        f.close()
        return hasher(data).hexdigest()
    except IOError:
        return None


class AssetInfo:
    def __init__(self, asset_id, location, url, _hash, dependencies, _type):
        self.asset_id = asset_id
        self.location = location
        self.url = url
        self._hash = _hash ##< Form: "TYPE|HASHVAL", e.g.: "SHA256|ABE1723762", sha256 with ABE1723762
        self.dependencies = dependencies
        self._type = _type

    def get_hash_type(self):
        return self._hash.split("|")[0]

    def get_hash_value(self):
        return self._hash.split("|")[1]

    def has_content(self):
        if self.url == "" and self.location == "":
            return False

        if self.location[-1] == "/":
            assert(self.url == "" or self.url is None) # Directories have no content to get
            return False # This is a directory

        assert(self.url != "")
        return True

    def is_valid(self):
        if self.asset_id == "":
            log(logging.ERROR, "Invalid asset info: No ID");
            return False
        elif not (self.has_content() or len(self.dependencies) > 0):
            log(logging.ERROR, "Invalid asset info for %s: No content and no dependencies" % self.asset_id);
            return False
        elif self._type == "":
            log(logging.ERROR, "Invalid asset info for %s: No type" % self.asset_id);
            return False

        return True

    ## Checks if this asset's location is of a zipfile, i.e., ending with .tar.gz, .zip, etc.
    def is_zipfile(self):
        return len(self.location) > 7 and self.location[-7:] == ".tar.gz"

    ## For a zipfile, returns the part of the location that is the basis, i.e., without the
    ## trailing .tar.gz or .zip
    ## @param name If None (not given), then use the location of this instance
    def get_zip_location(self, name=None):
        if name is None:
            name = self.location
        return name[:-7]


class AssetManagerClass:
    def __init__(self):
        self.clear_cache()

    def clear_cache(self):
        self.asset_infos = {}

    def is_needed(self, asset_info):
        if (asset_info._type == "S" and Global.CLIENT) or (asset_info._type == "C" and Global.SERVER):
            return False
        else:
            return True

    @classmethod
    def get_full_location(self, asset_info):
        location = asset_info.location
        # We will use this as an actual path now, so fix for Windows
        if WINDOWS:
            location = location.replace('/', '\\')
        return os.path.join( get_asset_dir(), location)

    def create_location(self, asset_info):
        dirname = os.path.dirname( self.get_full_location(asset_info) )

        if not os.path.exists(dirname):
            os.makedirs( dirname )

    ## Checks if we have existing data that is up to date for the asset
    def check_existing(self, asset_info):
        checks = multiple_send(check_existing, None, asset_info=asset_info)
        return True in checks and False not in checks


# Standard components

## TODO: Do this directly on disk, without loading into memory - would be more efficient perhaps
## @param hash_type The type of hash to use. If none is given, use the hash implied in
##                  the asset info
## @return The complete hash, including type and value, as appearing in AssetInfo._hash
##         Returns None if no hash could be calculated.
def get_existing_file_hash(asset_info, hash_type=None):
    if hash_type is None:
        hash_type = asset_info.get_hash_type()

    if hash_type == "MD5":
        hasher = hashlib.md5
    elif hash_type == "SHA1":
        hasher = hashlib.sha1
    elif hash_type == "SHA256":
        hasher = hashlib.sha256
    else:
        raise Exception("Unknown hash type: " + str(hash_type) + ":" + str(type(hash_type)))

    value = calculate_hash(AssetManager.get_full_location(asset_info), hasher)
    if value is None: # No such file or other error
        return None

    return hash_type + "|" + value

def check_hash(sender, **kwargs):
    asset_info = kwargs['asset_info']
    if asset_info.get_hash_type() == "NONE":
        # A None hash implies nothing to check - use local value blindly. Only return
        # False if nothing is there to use
        return os.path.exists( AssetManager.get_full_location(asset_info) )

    desired = asset_info._hash
    existing = KeepAliver.do(partial(get_existing_file_hash, asset_info), "Checking content for %s..." % asset_info.location)
    log(logging.DEBUG, "Comparing hashes: %s ? %s" % (desired, existing))
    return desired == existing

check_existing.connect(check_hash, weak=False)

# Extract existing zipfiles during check phase. This is useful for the case
# where the zipfile was part of the download binary, or we just pasted it
# in, and all we need is for it to be expanded. Extraction is only done
# if the directory doesn't exist (so we don't override local changes
# during editing).

def check_zipfiles_need_extraction(sender, **kwargs):
    asset_info = kwargs['asset_info']

    full_location = AssetManager.get_full_location(asset_info)

    if not asset_info.has_content() or not os.path.exists(full_location) or not asset_info.is_zipfile():
        return True # Not relevant to us

    if not os.path.exists(asset_info.get_zip_location(full_location)):
        asset_item_updated.send(None, asset_info=asset_info) # Treat this like it just arrived - process it, extraction etc.  

    return True

check_existing.connect(check_zipfiles_need_extraction, weak=False)

def extract_zipfiles(sender, **kwargs):
    '''
    This handles special assets like tarfile assets, which are extracted
    into a directory with their name.
    '''
    if 'filename' in kwargs:
        return True # We don't care about internal files - no recursive archives

    asset_info = kwargs['asset_info']

    full_location = AssetManager.get_full_location(asset_info)

    if not asset_info.has_content() or not os.path.exists(full_location) or not asset_info.is_zipfile():
        return True # Not relevant to us

    path = asset_info.get_zip_location(full_location) + os.sep # This is a directory, with the name of the tarfile

    if not os.path.exists(path): # Create our directory, if needed
        os.makedirs(path)

    the_zip = tarfile.open(full_location, 'r')
    names = the_zip.getnames()
    the_zip.extractall(path)
    the_zip.close()

    # Send updates for all files just created
    for name in names:
        asset_item_updated.send(
            None,
            asset_info=asset_info,
            filename=os.path.join(asset_info.get_zip_location(), name)
        )

    return True

# Extract newly retrieved zipfiles, overriding old contents if any.
asset_item_updated.connect(extract_zipfiles, weak=False)


# Singleton
AssetManager = AssetManagerClass()


# Prevent loops
from intensity.base import *


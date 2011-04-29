
# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

"""
Various utilities.
"""

import os

from intensity.base import *
from intensity.logging import *

def validate_relative_path(path):
    '''
    >>> validate_relative_path('data/models/cannon/barrel/../skin.jpg')
    True
    >>> validate_relative_path('skin.jpg')
    False
    >>> validate_relative_path('../skin.jpg')
    False
    >>> validate_relative_path('data/../skin.jpg')
    False
    >>> validate_relative_path('data/skin.jpg')
    True
    >>> validate_relative_path('data//../skin.jpg')
    False
    >>> validate_relative_path('data//skin.jpg')
    True
    >>> validate_relative_path('data/models/../../skin.jpg')
    False
    >>> validate_relative_path('data/models/../skin.jpg')
    True
    '''
    path = path.replace('\\', '/') # Use entirely UNIX-style seps to check
    level = -1 # So first addition puts us in 0, a valid level
    for seg in path.split('/'):
        if seg == '..':
            level -= 1
        elif seg != '.' and seg != '':
            level += 1
        if level < 0:
            return False
    level -= 1 # Last segment, the file itself, doesn't count
    return level >= 0


def check_newer_than(principal, *others):
    '''
    Checks if the file 'principal' is newer than
    various other files. If the principal doesn't
    exist, that is also consider not being newer than.
    '''

    if not os.path.exists(principal):
        return False

    mtime = os.stat(principal).st_mtime
    for other in others:
        if os.stat(other).st_mtime > mtime: # == means nothing to worry about
            return False

    return True

def prepare_texture_replace(filename, curr_textures):
    '''
    Given a file of old textures actually used in a map (from listtex), and a list of current texture names, makes a lookup table.
    The lookup table, given an index in the old textures, returns the new correct index for it using the current textures.

    Method:
        1. Run the old map with the old map.js script
        2. Do /listtex and save the output printed to the console to a file.
            (You may need to remove some unneeded textures at the end.)
        2. Fix the map.js to set up textures the way you want.
        3. Run with that new map.js.
        4. Do /massreplacetex FILENAME with the name of the file you created before
    '''
#    print "CURR:", curr_textures
    old_data = open(filename, 'r').read().replace('\r', '').split('\n')
#    print "OLD:", old_data
    lookup = {}
    for item in old_data:
        if item == '': continue
        index, name = item.split(' : ')
        index = int(index)
#        print "    ", index, name,
        # find new index - the index of that same name in the current textures
        lookup[index] = curr_textures.index(name)
        print lookup[index]
        curr_textures[lookup[index]] = 'zzz' # Do not find this again. This makes it ok to have the same texture twice,
                                                # with different rotations - we will process them ok

#    print "LOOKUP:", lookup
    return lookup

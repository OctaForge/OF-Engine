#!/usr/bin/python

# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

# Initialize

import os
import sys

from intensity.base import *
Global.init_as_client()

import intensity.c_module
CModule = intensity.c_module.CModule.holder

print "Intensity Engine Client parameters:", sys.argv

execfile( os.path.join(PYTHON_SCRIPT_DIR, "init.py") )

import __main__

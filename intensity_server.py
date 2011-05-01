#!/usr/bin/python

# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

from __future__ import with_statement

import os, sys, time

import intensity.c_module
CModule = intensity.c_module.CModule.holder

print "Intensity Engine Server parameters:", sys.argv

from intensity.world import *

print "Initializing C Server's Python connection system"

import __main__

print "Initializing scripting engine"
CModule.create_engine()

print "<<< Server is running in local mode - only a single client from this machine can connect >>>"

print "Initializing CModule"

CModule.init()

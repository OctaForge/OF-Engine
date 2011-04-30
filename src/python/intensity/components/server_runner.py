
# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

'''
Runs a server in a side process in a convenient way, for local gameplay.
'''

import subprocess, time
import os, signal, sys
import platform

from intensity.base import *
from intensity.signals import shutdown, show_components
from intensity.world import map_load_finish
from intensity.message_system import *
import intensity.c_module
CModule = intensity.c_module.CModule.holder


class Module:
    server_proc = None

def get_output_file():
    return os.path.join(get_home_subdir(), 'out_server.txt')

def run_server(location=None):
    CModule.run_script('echo("Starting server, please wait...")')

    if location is not None:
        location = 'base/' + location + '.tar.gz'

    activity = ''
    map_asset = '-config:Activity:force_location:%s' % location

    Module.server_proc = subprocess.Popen(
        "%s %s %s %s -component:intensity.components.shutdown_if_idle -component:intensity.components.shutdown_if_empty -config:Startup:no_console:1" % (
            'exec ./intensity_server.sh' if UNIX else 'intensity_server.bat',
            os.path.join(sys.argv[1], 'settings_server.json') if sys.argv[1][0] != '-' else '', # Home dir, if given for client - use also in server
            activity,
            map_asset,
        ),
        shell=True,
        stdout=open(get_output_file(), 'w'),
        stderr=subprocess.STDOUT,
    )
    #process.communicate()
    Module.server_proc.connected_to = False

    def prepare_to_connect():
        success = False
        for i in range(20):
            time.sleep(1.0)
            if not has_server():
                break
            elif check_server_ready():
                success = True
                def do_connect():
                    assert(not Module.server_proc.connected_to)
                    Module.server_proc.connected_to = True
                    CModule.run_script('network.connect("127.0.0.1", 28787)') # XXX: hard-coded
                main_actionqueue.add_action(do_connect)
                break
            else:
                CModule.run_script('echo("Waiting for server to finish starting up... (%d)")' % i)
    side_actionqueue.add_action(prepare_to_connect)

def has_server():
    return Module.server_proc is not None

# Check if the server is ready to be connected to
def check_server_ready():
    INDICATOR = '[[MAP LOADING]] - Success'
    return INDICATOR in open(get_output_file(), 'r').read()

def check_server_terminated():
    return Module.server_proc.poll()

def stop_server(sender=None, **kwargs):
    if Module.server_proc is not None:
        CModule.run_script("network.disconnect()")
        Module.server_proc = None

# Note strictly necessary, as the server will shut down if idle - but why not
# shut it down when the client shuts down.
shutdown.connect(stop_server, weak=False)

def show_gui(sender, **kwargs):
    if has_server():
        if check_server_ready():
            CModule.run_script('''
                gui.text("Local server: Running")
                gui.stayopen(function() gui.button("  stop", [=[network.ssls()]=]) end)
                gui.button("  show output", [[gui.show("local_server_output")]])
                gui.stayopen(function() gui.button("  save map", [=[network.do_upload()]=]) end)
                gui.button("  restart map", [[world.restart_map()]])
                gui.button("  editing commands", [[gui.show("editing")]])
            ''')
        elif check_server_terminated():
            Module.server_proc = None
        else:
            CModule.run_script('''
                gui.text("Local server: ...preparing...")
                gui.stayopen(function() gui.button("  stop", [=[network.ssls()]=]) end)
            ''')
    else:
        CModule.run_script('''
            gui.text("Local server: (not active)")

            gui.list(function()
                gui.text("Map location to run: base/")
                gui.field("local_server_location", 30, "")
                gui.text(".tar.gz")
            end)
            gui.stayopen(function()
                gui.button("  start", [=[
                    network.ssls(local_server_location)
                ]=])
            end)
            gui.button("  show output", [[ gui.show("local_server_output") ]])
        ''')
    CModule.run_script('gui.bar()')

show_components.connect(show_gui, weak=False)

def request_private_edit(sender, **kwargs):
    MessageSystem.send(CModule.RequestPrivateEditMode)
map_load_finish.connect(request_private_edit, weak=False)

CModule.run_script('''
    gui.new("local_server_output", function()
        gui.noautotab(function()
            gui.bar()
            gui.editor("%(name)s", -80, 20)
            gui.bar()
            gui.stayopen(function()
                gui.button("refresh", [[
                    gui.textfocus("%(name)s")
                    gui.textload("%(name)s")
                    gui.show("-1")
                ]])
            end)
        end)
    end)
''' % { 'name': get_output_file() })

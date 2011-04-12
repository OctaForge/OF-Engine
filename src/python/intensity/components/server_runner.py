
# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

'''
Runs a server in a side process in a convenient way, for local gameplay.

Works both when logged into the master, or when not.
'''

import subprocess, time
import os, signal, sys
import platform

from intensity.base import *
from intensity.logging import *
from intensity.signals import shutdown, show_components
from intensity.asset import AssetMetadata
from intensity.world import map_load_finish
from intensity.message_system import *


class Module:
    server_proc = None

def get_output_file():
    return os.path.join(get_home_subdir(), 'out_server.txt')

def run_server(location=None, use_master=True):
    CModule.run_script('echo("Starting server, please wait...")')

    if location is not None:
        location = 'base/' + location + '.tar.gz'

    log(logging.DEBUG, "Location: %s" % location)

    if location is not None and use_master:
        try:
            location = AssetMetadata.get_by_path('data/' + location).asset_id
        except Exception, e:
            log(logging.ERROR, "Error in getting asset info for map %s: %s" % (location, str(e)))
#            raise
            return

    if use_master:
        activity = '-config:Activity:force_activity_id:' if location is not None else ''
        map_asset = ('-config:Activity:force_map_asset_id:%s' % location) if location is not None else ''
    else:
        activity = ''
        map_asset = '-config:Activity:force_location:%s' % location

    servbin_name = ""
    if UNIX:
        machine = platform.machine()
        system = platform.system()
        if not os.path.exists("./bin/CC_Server_%s-%s" % (system, machine)):
            machine = platform.processor()
            if not os.path.exists("./bin/CC_Server_%s-%s" % (system, machine)):
                log(logging.ERROR, "Cannot find server binary (./bin/CC_Server_%s-%s)" % (system, machine))
                return
        servbin_name = "./bin/CC_Server_%s-%s" % (system, machine)

    Module.server_proc = subprocess.Popen(
        "%s %s %s %s -component:intensity.components.shutdown_if_idle -components:intensity.components.shutdown_if_empty -config:Startup:no_console:1" % (
            'exec ./%s -r' % servbin_name if UNIX else 'intensity_server.bat',
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
    log(logging.WARNING, "Starting server process: %d" % Module.server_proc.pid)

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
                    CModule.run_script('cc.network.connect("127.0.0.1", 28787)') # XXX: hard-coded
                main_actionqueue.add_action(do_connect)
                break
            else:
                CModule.run_script('echo("Waiting for server to finish starting up... (%d)")' % i)
        if not success:
            log(logging.ERROR, "Failed to start server. See out_server.txt")
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
        log(logging.WARNING, "Stopping server process: %d" % Module.server_proc.pid)
        try:
            if sys.version >= '2.6':
                Module.server_proc.terminate()
            else:
                os.kill(Module.server_proc.pid, signal.SIGKILL) # Will fail on Windows, so must have 2.6 there!
            Module.server_proc.wait()
        except OSError:
            log(logging.ERROR, "Stopping server process failed.");
        # Or, in Python 2.6:   process.terminate()
        Module.server_proc = None

        def do_disconnect():
            CModule.disconnect()
        main_actionqueue.add_action(do_disconnect)

# Note strictly necessary, as the server will shut down if idle - but why not
# shut it down when the client shuts down.
shutdown.connect(stop_server, weak=False)

def show_gui(sender, **kwargs):
    if has_server():
        if check_server_ready():
            CModule.run_script('''
                cc.gui.text("Local server: Running")
                cc.gui.stayopen(function() cc.gui.button("  stop", [=[cc.network.ssls()]=]) end)
                cc.gui.button("  show output", [[cc.gui.show("local_server_output")]])
                cc.gui.stayopen(function() cc.gui.button("  save map", [=[cc.network.do_upload()]=]) end)
                cc.gui.button("  restart map", [[cc.world.restart_map()]])
                cc.gui.button("  editing commands", [[cc.gui.show("editing")]])
            ''')
        elif check_server_terminated():
            Module.server_proc = None
            log(logging.ERROR, "Local server terminated due to an error")
        else:
            CModule.run_script('''
                cc.gui.text("Local server: ...preparing...")
                cc.gui.stayopen(function() cc.gui.button("  stop", [=[cc.network.ssls()]=]) end)
            ''')
    else:
        CModule.run_script('''
            cc.gui.text("Local server: (not active)")
            if logged_into_master == 0 then
                cc.gui.text("   << not logged into master >>")
            end

            cc.gui.list(function()
                cc.gui.text("Map location to run: base/")
                cc.gui.field("local_server_location", 30, "")
                cc.gui.text(".tar.gz")
            end)
            cc.gui.stayopen(function()
                cc.gui.button("  start", [=[
                    cc.network.ssls(local_server_location)
                ]=])
            end)
            cc.gui.button("  show output", [[ cc.gui.show("local_server_output") ]])
        ''')
    CModule.run_script('cc.gui.bar()')

show_components.connect(show_gui, weak=False)

# Always enter private edit mode if masterless
def request_private_edit(sender, **kwargs):
    if not CModule.run_script_int("return logged_into_master"):
        MessageSystem.send(CModule.RequestPrivateEditMode)
map_load_finish.connect(request_private_edit, weak=False)

CModule.run_script('''
    cc.gui.new("local_server_output", function()
        cc.gui.noautotab(function()
            cc.gui.bar()
            cc.gui.editor("%(name)s", -80, 20)
            cc.gui.bar()
            cc.gui.stayopen(function()
                cc.gui.button("refresh", [[
                    cc.gui.textfocus("%(name)s")
                    cc.gui.textload("%(name)s")
                    cc.gui.show("-1")
                ]])
            end)
        end)
    end)
''' % { 'name': get_output_file() })

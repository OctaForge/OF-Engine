
# Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
# This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

import os, sys, shutil, time

from intensity.base import *
from intensity.message_system import *

## Information about a single connected client
class Client:
    def __init__(self, number, ip_addr, admin, username, user_id):
        self.number = number
        self.ip_addr = ip_addr
        self.admin = admin
        self.username = username
        self.user_id = user_id


## Information about all connected clients
class Clients:
    _map = {}
    shutdown_if_empty = False
    shutdown_counter = 0

    @staticmethod
    def add(client_number, *args):
        Clients._map[client_number] = Client(client_number, *args)
        if Clients.shutdown_if_empty:
            Clients.shutdown_counter += 1

    @staticmethod
    def remove(client_number):
        # Client may not have fully logged in before being booted
        if client_number in Clients._map:
            del Clients._map[client_number]
        if Clients.shutdown_if_empty:
            Clients.shutdown_counter -= 1
            if Clients.shutdown_counter <= 0:
                quit()

    @staticmethod
    def count():
        return len(Clients._map)

    @staticmethod
    def get(client_number):
        return Clients._map[client_number]

    @staticmethod
    def list():
        return Clients._map.values()


def get_max_clients():
    return int(get_config('Clients', 'limit', 10))

def do_login(code, client_number, ip_addr):
    def fail(message):
        show_client_message(client_number, "Login failure", message)
        CModule.force_network_flush()
        CModule.disconnect_client(client_number, 3) # DISC_KICK... most relevant for now

    if not World.running_map():
        return fail("Login failure: instance is not running a map")

    CModule.update_username(client_number, 'local_editor')
    CModule.set_admin(client_number, True);

    Clients.add(client_number, ip_addr, True, 'local_editor', 'local_editor')

    MessageSystem.send(client_number,
                       CModule.LoginResponse,
                       1, 1); # success, local


## Called when a client is disconnected
def on_logout(client_number):
    Clients.remove(client_number)


##
def request_private_edit(client_number):
    if not Clients.get(client_number).admin:
        return show_client_message(client_number, "Request denied", "You are not an administrator of this map")
    elif Clients.count() != 1:
        return show_client_message(client_number, "Request denied", "There are other clients on this server instance")
    else:
        MessageSystem.send(client_number, CModule.NotifyPrivateEditMode)


## Notifies clients that we would like to send them the current map, as it has changed.
## We do so by sending them the current map's name. They then uses the asset system to acquire the
## map, in it's latest version, both .cfg and .ogz files, etc. etc., using the map name as the asset ID.
## @param client_number The identifier of the client to which to send the map, or ALL_CLIENTS (-1) for all
def send_curr_map(client_number):
    if not World.running_map():
        return

    MessageSystem.send(client_number, CModule.NotifyAboutCurrentScenario, get_curr_map_asset_id(), World.scenario_code)


from intensity.world import *


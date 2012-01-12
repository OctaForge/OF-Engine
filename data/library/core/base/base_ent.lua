--[[!
    File: library/core/base/base_ent.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2011 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        This file features entity system.
]]

--[[!
    Package: entity
    This module handles entities. It contains base entity class from which
    all other classes inherit.
]]
module("entity", package.seeall)

--[[!
    Class: base_root
    This represents the base class for all entities.
    It contains basic handler methods common for both client and server.

    Entity always needs a class name. You can specify class name as third
    argument to <std.class.new> (or second, if you don't  specify table mixin,
    see the class documentation). Entity class name is required for proper
    database lookups. The core library entities ALWAYS have the same class
    name as name of the class object in Lua.

    Properties:
        tags - each entity can have a set of tags, which can be then used
        when finding the entity.
        persistent - this specifies whether the entity gets saved on disk.
        Dynamic entities are usually not saved, static usually are. Non-sauer
        entities don't mostly get saved.
]]
base_root = std.class.new(nil, {
    --[[!
        Variable: should_act
        Boolean value specifying whether the entity should run <act>
        or <base_client.client_act> every frame. True for dynamic entities,
        false for static entities by default, but can be re-enabled
        for static entities as well.

        This can as well be a table, if you want the entity to i.e. act
        on server but not client_act. Then you can specify boolean values
        should_act.client and should_act.server.
    ]]
    should_act = true,

    --[[!
        Variable: properties
        Every entity has a "properties" table. It specifies state
        variables the entity should have. The entity also inherits
        properties of its parent and parent's parent and so forth.
        Properties can be changed (i.e. via the entity properties GUI).
    ]]
    properties = {
        tags       = state_variables.state_array(),
        persistent = state_variables.state_bool()
    },

    --[[!
        Function: __tostring
        Overriden metamethod specifying what is returned when
        tostring gets called on entity instance. By default,
        returns the entity class.
    ]]
    __tostring = function(self)
        return self.name
    end,

    --[[!
        Function: general_setup
        This function performs initial entity setup - creates
        its action system, calls <variable_setup>, adds
        signal methods.. Called by <base_server.entity_setup>
        (serverside) and <base_client.client_activate> (clientside).
    ]]
    general_setup = function(self)
        log(DEBUG, "base_root:general_setup")

        -- do not re-run this
        if self.general_setup_complete then
            return nil
        end

        -- add signal methods
        signals.methods_add(self)

        -- create action system
        self.action_system = actions.action_system(self)

        -- create state variable value storage
        self.state_variable_values           = {}
        -- caching for state variable changes
        self.state_variable_value_timestamps = {}

        -- we're not deactivated anymore
        self.deactivated = false

        -- set up state variables
        self:variable_setup()

        -- we're done, lock this up
        self.general_setup_complete = true
    end,

    --[[!
        Function: general_deactivate
        This is called on entity deactivation. It clears up
        the action system and unregisters entity from the engine.
    ]]
    general_deactivate = function(self)
        -- clear up actions
        self:clear_actions()

        -- unregister
        CAPI.unregister_entity(self.uid)

        -- we're deactivated now
        self.deactivated = true
    end,

    --[[!
        Function: get_state_data
        This method gets a state variable value from local storage.
        No C getters will be called.

        Parameters:
            key - Entity property name.

        Returns:
            Locally stored value (without calling
            getters on wrapped C variables)
    ]]
    get_state_data = function(self, key)
        return self.state_variable_values[key]
    end,

    --[[!
        Function: act
        Default serverside act method. It manages the action system.
        If you override this, you should always call it back (unless
        you're inheriting entity class that has already overriden it,
        then you should call its act method).

        Parameters:
            seconds - For how long to manage the action system (actions
            in system will modify their remaining time accordingly).
    ]]
    act = function(self, seconds)
        self.action_system:manage(seconds)
    end,

    --[[!
        Function: queue_action
        QUeues an action to the system.

        Parameters:
            action - the action instance to queue.
    ]]
    queue_action = function(self, action)
        self.action_system:queue(action)
    end,

    --[[!
        Function: clear_actions
        Clears up entity's action system.
    ]]
    clear_actions = function(self)
        self.action_system:clear()
    end,

    --[[!
        Function: add_tag
        Tags an entity. Basically modifies tags property (state variable).
        Tag won't get added if entity already has one.

        Parameters:
            tag - the tag to add.
    ]]
    add_tag = function(self, tag)
        -- do not add if we already have one
        if not self:has_tag(tag) then
             self.tags:push(tag)
        end
    end,

    --[[!
        Function: del_tag
        Removes a tag. Basically converts tags state variable
        value to raw array, filters it and sets the output back.

        Parameters:
            tag - the tag to remove.
    ]]
    del_tag = function(self, tag)
        log(DEBUG, "base_root:del_tag(\"" .. tag .. "\")")

        -- do not attempt to filter if we don't have the tag
        if not self:has_tag(tag) then
            return nil
        end

        -- let's filter the state variable
        self.tags = table.filter_array(
            -- convert <array_surrogate> to raw array
            self.tags:to_array(),
            -- compare the tags
            function(i, _tag)
                return _tag ~= tag
            end
        )
    end,

    --[[!
        Function: has_tag
        Checks if given tag is present for the entity.

        Parameters:
            tag - the tag to check.

        Returns:
            true if it has, false otherwise.
    ]]
    has_tag = function(self, tag)
        log(INFO, "i can has tag " .. tostring(tag))

        -- try to find the tag in raw array
        return (table.find(self.tags:to_array(), tag) ~= nil)
    end,

    --[[!
        Function: variable_setup
        Sets up state variables for the entity. Browses <properties> of
        current entity, inserts its state variables into a table, then
        browses its parent and parent's parent and so forth and does
        the insertion for every.

        Note that if child entity class already contains a state variable
        of same name as its parent, child's version is preferred.

        Then a table of state variable names is got and gets sorted by name,
        leaving state variable aliases last (so the variable they point to
        is already set up by the time they're being set up).

        Then table of names gets iterated and state variables get set up
        from the original variable table.
    ]]
    variable_setup = function(self)
        -- here state variables will be stored
        local p_table = {}

        -- we're an instance - let's get our class
        local  base = self.class
        -- loop until there are no parent classes left
        while  base do
            -- if the class has properties, let's insert state variables
            -- from them into p_table
            if base.properties then
                for name, var in pairs(base.properties) do
                    -- but do not insert if child class already inserted
                    -- state variable of the same name before
                    if not p_table[name]
                       and state_variables.is_state_variable(var) then
                           p_table[name] = var
                    end
                end
            end

            -- break out if we're already base_root and save an iteration
            if base == base_root then
                break
            end

            -- try another parent
            base =  base.base_class
        end

        -- get state variable names from p_table
        local sv_names = table.keys(p_table)

        -- sort the names
        table.sort(sv_names, function(n1, n2)
            -- if first one is alias and second not, leave the alias
            -- for the end
            if state_variables.is_state_variable_alias(p_table[n1]) and not
               state_variables.is_state_variable_alias(p_table[n2]) then
               return false
            end
            -- if first one is not alias and second is, leave the alias
            -- for the end
            if not state_variables.is_state_variable_alias(p_table[n1])
               and state_variables.is_state_variable_alias(p_table[n2]) then
               return true
            end

            -- if both are aliases or both aren't, just sort by name
            return (n1 < n2)
        end)

        -- loop the sorted names now
        for i, name in pairs(sv_names) do
            log(
                DEBUG,
                "Setting up var: %(1)s %(2)s" % {
                    name, tostring(p_table[name])
                }
            )

            -- get variable from p_table
            local var = p_table[name]

            -- register the variable
            var:register(name, self)
        end
    end,

    --[[!
        Function: create_state_data_dict
        Creates a state data JSON dictionary from properties
        (state variables) we have. Several compression methods
        can get applied (remove redundant whitespaces, convert
        names to protocol IDs), so the final dictionary is smaller
        for network transfer. Can be overriden (when we're just doing
        this locally).

        Note that if we're NOT compressing, it'll return RAW TABLE.
        No JSON encoding involved, you'll have to do that yourself if needed.

        Parameters:
            target_cn - target client number for state variable.
            Determines if state variable will get included in the dictionary.
            If it's nil, it'll get done for all clients.
            kwargs - additional parameters. Here it makes use of one of them,
            and that is "compressed", if that is true, compression methods
            (like replacing names with protocol IDs) will get applied to
            compress the dict for network transfer.

        Returns:
            The generated JSON string.
    ]]
    create_state_data_dict = function(self, target_cn, kwargs)
        -- default the values
        target_cn = target_cn or message.ALL_CLIENTS
        kwargs    = kwargs    or {}

        log(
            DEBUG,
            "create_state_data_dict(): "
                .. tostring(self)
                .. tostring(self.uid)
                .. ", "
                .. tostring(target_cn)
        )

        -- this will get returned encoded
        local r = {}

        -- get list of members of this instance
        local _names = table.keys(self)
        -- loop them
        for i, name in pairs(_names) do
            -- get the member itself
            local var = self[name]

            -- if it's state variable and keeps history, include it
            if state_variables.is_state_variable(var) and var.has_history then
                -- do not send private data
                local skip = false

                -- skip this iteration if we're sending to specific client and
                -- the variable shouldn't send to it
                if target_cn >= 0 and not var:should_send(self, target_cn) then
                    skip = true
                end

                -- if we're not skipping ..
                if not skip then
                    -- get a value of the variable
                    local val = self[var._name]

                    -- if value exists or is false (important), include
                    if val or val == false then
                        log(
                            DEBUG,
                            "create_state_data_dict() adding "
                                .. tostring(var._name)
                                .. ": "
                                .. std.json.encode(val)
                        )

                        -- get the name - if we're compressing,
                        -- convert it to protocol ID
                        local key = (not kwargs.compressed)
                                 and var._name
                                  or message.to_protocol_id(
                                    tostring(self), var._name
                                  )

                        -- insert as converted to wire (== as string)
                        r[key] = var:to_wire(val)

                        log(
                            DEBUG,
                            "create_state_data_dict() currently: "
                                .. std.json.encode(r)
                        )
                    end
                end
            end
        end

        log(
            DEBUG,
            "create_state_data_dict() returns: " .. std.json.encode(r)
        )

        -- if we're not compressing, fine, return - raw table
        if not kwargs.compressed then
            return r
        end

        -- pre-compression: keep numbers as numbers, not strings
        _names = table.keys(r)
        for i = 1, #_names do
            if tonumber(r[_names[i]]) and r[_names[i]] ~= "" then
                r[_names[i]] = tonumber(r[_names[i]])
            end
        end

        -- encode it into JSON
        r = std.json.encode(r)
        log(DEBUG, "pre-compression: " .. r)

        -- several string filters
        local _filters = {
            function(d)
                return string.gsub(d, "\", \"", "\",\"")
            end, -- "foo", "bar" --> "foo","bar"

            function(d)
                return string.gsub(d, ":\"(%d+)\.(%d+)\"", ":\"%1\".\"%2\"")
            end, -- :"3.14" --> :"3"."14"

            function(d)
                return string.gsub(d, ", ", ",")
            end, -- ", " --> "," (without quotes)
        }

        -- apply the filters - but the value after filtering gets checked by
        -- de-encoding both strings and encoding them again and checking then
        -- if they're the same.
        for i, filter in pairs(_filters) do
            local n = filter(r)

            if #n < #r
            and std.json.encode(std.json.decode(n))
             == std.json.encode(std.json.decode(r)) then
                r = n
            end
        end

        log(DEBUG, "compressed: " .. r)

        -- return with removed leading and trailing { / }
        return string.sub(r, 2, #r - 1)
    end,

    --[[!
        Function: update_complete_state_data
        Updates complete state data for entity from JSON string input.

        Parameters:
            state_data - the input string.
    ]]
    update_complete_state_data = function(self, state_data)
        log(
            DEBUG,
            "updating complete state data for "
                .. tostring(self.uid)
                .. " with "
                .. tostring(state_data)
                .. " ("
                .. type(state_data)
                .. ")"
        )

        -- if we've got input with removed { / }, append them back
        state_data = (string.sub(state_data, 1, 1) ~= "{")
            and "{" .. state_data .. "}"
            or state_data

        -- and decode it into raw table again
        local raw_state_data = std.json.decode(state_data)
        assert(type(raw_state_data) == "table")

        -- set the entity as initialized
        self.initialized = true

        -- and loop the state data
        for k, v in pairs(raw_state_data) do
            -- if the name is protocol ID (can be converted to number),
            -- convert it back to name
            k = tonumber(k)
                and message.to_protocol_name(tostring(self), tonumber(k))
                or k

            log(
                DEBUG,
                "update of complete state data: "
                    .. tostring(k)
                    .. " = "
                    .. tostring(v)
            )

            -- perform state data setting - the true value means it's internal
            -- operation, we're sending raw state data.
            self:set_state_data(k, v, nil, true)

            log(DEBUG, "update of complete state data ok")
        end

        log(DEBUG, "update of complete state data done.")
    end
}, "base")

--[[!
    Class: base_client
    This represents clientside base class. It extends <base_root> with client
    specific methods.
]]
base_client = std.class.new(base_root, {
    --[[!
        Function: client_activate
        This is called on clientside entity activation.
        It calls <base_root.general_setup>, possibly
        sets up nonsauer entity, but doesn't set the entity
        as initialized yet - that's done after receiving
        complete state data from server
        (see <base_root.update_complete_state_data>).

        Parameters:
            kwargs - table of additional parameters, this client_activate
            doesn't make use of any of them, they're mainly for further
            usage in inherited client_activate methods.
    ]]
    client_activate = function(self, kwargs)
        self:general_setup()

        if not self.sauer_type then
            log(
                DEBUG,
                "non-sauer entity going to be set up: "
                    .. tostring(self)
                    .. ", "
                    .. tostring(self.sauer_type)
            )
            CAPI.setupnonsauer(self)
        end

        -- set to true when we receive complete state data from server
        self.initialized = false
    end,

    --[[!
        Function: client_deactivate
        Client entity deactivation method.
        Calls <base_root.general_deactivate>.
    ]]
    client_deactivate = function(self)
        self:general_deactivate()
    end,

    --[[!
        Function: set_state_data
        Clientside state data setter. Depending on settings, it can
        also send an update to the server. When updating locally
        (just clientside), that means either server has initiated
        the change or the state variable is has <client_set> property set to
        true, in that case, a signal gets emitted (see <signals>).

        Call <state_variables.get_on_modify_name> to get the signal name
        with state variable name set as argument. You can connect handler
        to the entity that gets called everytime the value gets changed
        (locally).

        The handler for the signal accepts new value as the argument
        (besides 'self', of course), so you can easily take appropriate
        actions, and it also takes second boolean argument having true
        value when the value was modified for specific client.

        Parameters:
            key - name of state variable we're setting.
            value - the value we're setting.
            actor_uid - unique ID of actor we're setting the value for.
            If this is -1, it means "all clients" (see <ALL_CLIENTS>),
            so we'll send an update to the server. If it's anything else
            (including nil), it means we're setting to an explicit client
            and that means we'll emit the signal and convert value
            argument from wire format (== from string).
    ]]
    set_state_data = function(self, key, value, actor_uid)
        log(
            DEBUG,
            "setting state data: "
                .. key
                .. " = "
                .. std.json.encode(value)
                .. " for "
                .. self.uid
        )

        -- get raw state variable (omit calling getter)
        local var = self[state_variables._SV_PREFIX .. key]

        -- if the variable has custom synch flag + we're
        -- controlled here, this will be true
        local custom_synch_from_here
            = var.custom_synch and self.controlled_here

        -- state variable having client_set flag means
        -- it's always set clientside (saves bandwidth)
        local client_set = var.client_set

        -- if we're sending to all clients and not custom synching
        -- from here, let's send a message to server without emitting
        -- a signal or setting anything
        if actor_uid == -1 and not custom_synch_from_here then
            log(
                DEBUG, "sending request / notification to server."
            )

            -- TODO: supress msg sending of the same val, at least for some SVs
            message.send(
                var.reliable
                    and CAPI.statedata_changerequest
                     or CAPI.statedata_changerequest_unreliable,
                self.uid,
                message.to_protocol_id(tostring(self), var._name),
                var:to_wire(value)
            )
        end

        -- if we're sending to specific client OR the state variable
        -- has client_set flag OR we're custom synching from here,
        -- update the value locally
        if actor_uid ~= -1 or client_set or custom_synch_from_here then
            log(INFO, "updating locally")

            -- if originated from server, translate the value 
            if actor_uid ~= -1 then
                value = var:from_wire(value)
            end
            -- assert validation (TODO: omit assertions so the engine
            -- does not quit on failed changes)
            assert(var:validate(value))

            -- emit the change handler
            self:emit(
                state_variables.get_on_modify_name(key),
                value, actor_uid ~= -1
            )
            -- and locally set the value
            self.state_variable_values[key] = value
        end
    end,

    --[[!
        Function: client_act
        Clientside version of <base_root.act>.
    ]]
    client_act = function(self, seconds)
        log(
            INFO,
            "base_client:client_act, " .. self.uid
        )

        self.action_system:manage(seconds)
    end,

    --[[!
        Function: client_click
        Called clientside when some client clicks on the entity.
        See <input> and its global client_click function documentation
        and also <base_server.click>. Please note that this gets called
        by default only when global client_click is not overriden. If
        you want to call it and override global client_click at once,
        you'll have to do it manually by placing a bit of code in the
        beginning of your global client_click function.

        (start code)
            if  ent and ent.client_click then
                ent:client_click(button, down, position, x, y)
            end
        (end)

        This by default does nothing.
    ]]
    client_click = function(self, button, down, position, x, y)
    end
})

--[[!
    Class: base_server
    This represents serverside base class. It extends <base_root> with server
    specific methods.
]]
base_server = std.class.new(base_root, {
    --[[!
        Variable: sent_complete_notification
        This is set to true after <send_complete_notification>.
        It is used in <set_state_data> to determine if to set state
        data, because it can't be set when complete notification
        isn't sent yet.
    ]]
    sent_complete_notification = false,

    --[[!
        Function: init
        This gets called even before <activate>. In custom entities,
        it is used to default values of state variables
        (unless they're client_set, of course).

        Here, it sets the serverside unique ID and initializes state
        variables "tags" and "persistent" (see <base_root>).

        This function also calls <entity_setup>.

        Parameters:
            uid - unique ID the entity will have.
            kwargs - table of additional parameters. This method can
            use one of them, "persistent", a boolean value specifying
            whether the entity will be persistent (sets persistent
            property, see <base_root>).
    ]]
    init = function(self, uid, kwargs)
        log(
            DEBUG,
            "base_server:init("
                .. uid
                .. ", "
                .. tostring(kwargs)
                .. ")"
        )

        -- assertions. TODO: get rid of them to prevent engine quitting
        assert(uid ~= nil)
        assert(type(uid) == "number")

        -- set the uid and call entity_setup
        self.uid = uid
        self:entity_setup()

        -- default some stuff
        self.tags       = {}
        kwargs          = kwargs or {}
        self.persistent = kwargs.persistent or false
    end,

    --[[!
        Function: activate
        Serverside activation method. Called after <init>.
        Serverside equivalent of <base_client.client_activate>.

        Calls <entity_setup> just in case (the call does nothing
        if it was already done from <init>).

        Parameters:
            kwargs - table of additional parameters. This function can
            use one of them, "state_data", which is a JSON string
            containing state data to initialize the entity with.
    ]]
    activate = function(self, kwargs)
        log(
            DEBUG, "base_server:activate(" .. tostring(kwargs) .. ")"
        )

        -- set up the entity just in case
        self:entity_setup()

        -- if we're not sauer entity ..
        if not self.sauer_type then
            log(
                DEBUG,
                "non-sauer entity going to be set up: "
                    .. tostring(self)
                    .. ", "
                    .. tostring(self.sauer_type)
            )

            -- do a special nonsauer registration in C++
            CAPI.setupnonsauer(self)

            -- and flush changes
            self:flush_queued_state_variable_changes()
        end

        -- if we have state_data provided by kwargs,
        -- update the entity from them
        if kwargs and kwargs.state_data then
            self:update_complete_state_data(kwargs.state_data)
        end

        -- send complete notification and set it as sent
        self:send_complete_notification(message.ALL_CLIENTS)
        self.sent_complete_notification = true

        log(DEBUG, "LE.activate complete.")
    end,

    --[[!
        Function: send_complete_notification
        Sends a complete notification to client(s).

        Parameters:
            cn - client number to send the message to.
            If set to -1, a message gets sent to all
            clients (see <ALL_CLIENTS>). If it's nil,
            it defaults to <ALL_CLIENTS> as well.
    ]]
    send_complete_notification = function(self, cn)
        -- default the client number
        cn = cn or message.ALL_CLIENTS

        -- and create a table of client numbers
        local cns = (cn == message.ALL_CLIENTS)
                    and entity_store.get_all_client_numbers()
                     or { cn }

        log(
            DEBUG,
            "LE.send_complete_notification: "
            .. tostring(self.cn)
            .. ", "
            .. self.uid
        )

        -- loop the numbers and send a message for each of them
        for i, num in pairs(cns) do
            message.send(num,
                        CAPI.le_notification_complete,
                        self.cn and self.cn or message.ALL_CLIENTS,
                        self.uid,
                        tostring(self),
                        -- custom data per client
                        self:create_state_data_dict(
                            num, { compressed = true }
                        )
            )
        end

        log(DEBUG, "LE.send_complete_notification done.")
    end,

    --[[!
        Function: entity_setup
        Performs entity setup. First, does <base_root.general_setup>
        and then creates a table of queued state variable changes.
        Finally, sets the entity as initialized. Does nothing
        when already initialied.
    ]]
    entity_setup = function(self)
        -- perform only if not initialized yet
        if not self.initialized then
            log(DEBUG, "LE setup")

            -- general setup
            self:general_setup()

            -- queued changes
            self._queued_sv_changes = {}
            self._queued_sv_changes_complete = false

            -- and lock it up
            self.initialized = true
            log(DEBUG, "LE setup complete.")
        end
    end,

    --[[!
        Function: deactivate
        Serverside version of <base_client.client_deactivate>.
        Besides <base_root.general_deactivate>,
        sends a message to all clients to remove the entity.
    ]]
    deactivate = function(self)
        self:general_deactivate()
        message.send(message.ALL_CLIENTS, CAPI.le_removal, self.uid)
    end,

    --[[!
        Function: set_state_data
        Serverside state data setter. Depending on settings, it takes multiple
        other actions, like converting from wire format. Signal gets emitted.

        Call <state_variables.get_on_modify_name> to get the signal name
        with state variable name set as argument. You can connect handler
        to the entity that gets called everytime the value gets changed
        (locally).

        The handler for the signal accepts new value as the argument
        (besides 'self', of course), so you can easily take appropriate
        actions, and it also takes second boolean argument having true
        value when the value was modified for specific client.

        Parameters:
            key - name of state variable we're setting.
            value - the value we're setting.
            actor_uid - unique ID of actor we're setting the value for.
            If this is -1, it means "all clients" (see <ALL_CLIENTS>),
            so we'll send an update to the server.
            internal_op - this boolean value specifies whether
            it's internal server operation. If it is, given value
            gets converted from wire format.
    ]]
    set_state_data = function(self, key, value, actor_uid, internal_op)
        log(INFO, "Setting state data: " ..
                          key .. " = " ..
                          tostring(value) .. " (" ..
                          type(value) .. ") : " ..
                          std.json.encode(value) .. ", " ..
                          tostring(value))

        -- get entity class string
        local _class = tostring(self)

        -- get the raw variable (omit getters)
        local var = self[state_variables._SV_PREFIX .. tostring(key)]

        -- if we don't have the variable, log it and return (ignore)
        if not var then
            log(
                WARNING,
                "Ignoring SD setting for unknown (deprecated?) variable "
                    .. tostring(key)
            )
            return nil
        end

        -- if we're sending to specific client ..
        if actor_uid and actor_uid ~= -1 then
            -- convert from wire format
            value = var:from_wire(value)
            -- if the state variable is not changeable on client
            -- (through server message), return - see client_write
            -- in state variables documentation
            if not var.client_write then
                log(
                    ERROR,
                    "Client "
                        .. tostring(actor_uid)
                        .. " tried to change "
                        .. tostring(key)
                )
                return nil
            end
        elseif internal_op then
            -- internal server operation,
            -- convert from wire format in any case
            value = var:from_wire(value)
        end

        log(INFO, "Translated value: " ..
                          key .. " = " ..
                          tostring(value) .. " (" ..
                          type(value) .. ") : " ..
                          std.json.encode(value) .. ", " ..
                          tostring(value))

        -- emit the change
        local ret = self:emit(
            state_variables.get_on_modify_name(key),
            value, actor_uid
        )
        -- if the handler returns this string,
        -- cancel the update (useful in i.e. health system)
        if ret == "cancel_state_data_update" then
            return nil
        end

        -- locally save the value
        self.state_variable_values[key] = value
        log(
            INFO,
            "new state data: " .. tostring(self.state_variable_values[key])
        )

        -- if the variable has custom synch flag + we're
        -- controlled here, this will be true
        local custom_synch_from_here
            = var.custom_synch and self.controlled_here

        -- if we're not internal operation and the state variable
        -- can be read from client and we're not custom synching from here ..
        if not internal_op
           and var.client_read
           and not custom_synch_from_here then
            -- if we haven't sent complete notification yet, cancel
            if not self.sent_complete_notification then
                return nil
            end

            -- generate table of arguments
            local args = {
                -- this first arg will be client number
                nil,
                var.reliable
                    and CAPI.statedata_update
                    or  CAPI.statedata_update_unreliable,
                self.uid,
                message.to_protocol_id(_class, key),
                var:to_wire(value),
                (var.client_set and actor_uid and actor_uid ~= -1)
                    and entity_store.get(actor_uid).cn
                    or  message.ALL_CLIENTS
            }

            -- get all client numbers (we're sending to all clients)
            local cns = entity_store.get_all_client_numbers()
            for i, num in pairs(cns) do
                -- if we should send ..
                if var:should_send(self, num) then
                    -- then send the message
                    args[1] = num
                    message.send(unpack(args))
                end
            end
        end
    end,

    --[[!
        Function: queue_state_variable_change
        Queues state variable changes. Basically just inserts
        the key/value pair into queue table.

        Parameters:
            key - state variable name.
            value - the value to queue.
    ]]
    queue_state_variable_change = function(self, key, value)
        log(
            DEBUG,
            "Queueing SV change: "
                .. key
                .. " - "
                .. tostring(value)
                .. " ("
                .. type(value)
                .. ")"
        )
        self._queued_sv_changes[key] = value
    end,

    --[[!
        Function: can_call_c_functions
        Returns true if the C side is alraedy set up and we can call getters
        for wrapped variables (== internal queued state variable changes table
        is nil - that is set by <flush_queued_state_variable_changes>).
    ]]
    can_call_c_functions = function(self)
        return (not self._queued_sv_changes)
    end,

    --[[!
        Function: flush_queued_state_variable_changes
        Flushes the internal table for queued SV changes
        (applies changes from them and sets the table to nil).
    ]]
    flush_queued_state_variable_changes = function(self)
        log(
            DEBUG,
            "flushing queued SV changes for " .. self.uid
        )
        if self:can_call_c_functions() then return nil end

        local changes = self._queued_sv_changes
        self._queued_sv_changes = nil

        local _keys = table.keys(changes)
        for i = 1, #_keys do
            local val = changes[_keys[i]]
            local var = self[state_variables._SV_PREFIX .. tostring(k)]

            log(DEBUG, "(A) flushing queued SV change: " ..
                    tostring(_keys[i]) .. " - " ..
                    tostring(val) .. " (real: " ..
                    tostring(self.state_variable_values[_keys[i]]) .. ")")

            self[_keys[i]] = self.state_variable_values[_keys[i]]

            log(
                DEBUG,
                "(B) flushing of " .. tostring(_keys[i]) .. " - ok."
            )
        end

        self._queued_sv_changes_complete = true
    end,

    --[[!
        Function: click
        Called serverside when some client clicks on the entity.
        See <input> and its global click function documentation
        and also <base_client.client_click>. Please note that
        this gets called by default only when global click is
        not overriden. If you want to call it and override global
        click at once, you'll have to do it manually by placing a
        bit of code in the beginning of your global click function.

        (start code)
            if  ent and ent.click then
                ent:click(button, down, position)
            end
        (end)

        This by default does nothing.
    ]]
    click = function(self, button, down, position)
    end
})

--[[!
    Class: base
    This is either base_client or base_server,
    determined from if we're the server or client.
]]
base = CLIENT and base_client or (SERVER and base_server or nil)

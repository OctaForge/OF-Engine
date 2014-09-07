--[[!<
    Actions are basically objects that are stored in an action queue.
    You can queue new actions and those will run for example for a period
    of time, depending on the action type. They're used to for example queue
    a player animation for a few seconds, or to trigger a world event at some
    specific point. They have numerous uses generally.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

var capi = require("capi")
var logging = require("core.logger")
var log = logging.log
var INFO = logging.INFO
var WARNING = logging.WARNING

var compact = table.compact

var createtable = capi.table_create

--! Module: actions
var M = {}

--[[!
    Provides the base action object other actions can inherit from.
    Takes care of the basic action infrastructure. It doesn't really
    do anything, though.

    Fields:
        - begun - true when the action has begun.
        - finished - true when the action has finished.
        - actor - the entity this belongs to (set automatically by the action
          queue).
        - queue - the action queue this belongs to (set automatically by
          the action queue).
        - start_time - the action start time (current time around action
          initialization).
        - millis_left - how many milliseconds the action takes, can be
          initialized in constructor kwargs.
        - animation - the animation.
        - allow_multiple - a boolean specifying whether multiple actions
          of the same type can be present in one action queue, defaults to
          true (unless it's specified directly in the base object we're
          constructing from, then it defaults to that).
        - cancelable - a boolean specifying whether the action can be
          canceled, same defaults as above apply.
        - parallel_to - the action this one is parallel to, if specified,
          do this action will mirror the other action's finish status
          (i.e. it runs as long as the other action does, and it finishes
          as soon as the other action does). Useful for e.g. animations that
          run in parallel.
]]
M.Action = table.Object:clone {
    name = "Action",

    --[[!
        Constructs the action. Takes kwargs, which is an optional argument
        supplying modifiers for the action. It's an associative array.
    ]]
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}

        self.begun      = false
        self.finished   = false
        self.start_time = capi.get_current_time()

        self.millis_left = (self.millis_left) or
            kwargs.millis_left or 0

        self.animation    = (self.animation == nil) and
            kwargs.animation or false

        self.actor = false

        self.allow_multiple =
            (self.allow_multiple   == nil) and
            (kwargs.allow_multiple == nil) and true or false

        self.cancelable =
            (self.cancelable   == nil) and
            (kwargs.cancelable == nil) and true or false

        self.parallel_to =
            (self.parallel_to == nil) and kwargs.parallel_to or false
    end,

    --[[!
        Overloaded so that tostring(x) where x is an action simply
        returns the name ("Action" for the base action).
    ]]
    __tostring = function(self) return self.name end,

    priv_start = function(self)
        self.begun = true
        self:__start()
    end,

    --[[!
        By default, empty. Overload in your inherited actions as you need.
        Called when the action flow starts.
    ]]
    __start = function(self)
    end,

    priv_run = function(self, millis)
        if type(self.actor) == "table" and self.actor.deactivated do
            self.priv_finish(self)
            return true
        end

        if not self.begun do
            self.priv_start(self)

            if self.animation != false do
                var aanim = self.actor:get_attr("animation")
                var anim = self.animation
                if aanim != anim do
                    self.last_animation = aanim
                    self.actor:set_attr("animation", anim)
                end
            end
        end

        if self.parallel_to == false do
            @[debug] log(INFO, "Executing action " .. self.name)

            var finished = self:__run(millis)
            if    finished do
                self.priv_finish(self)
            end

            @[debug] log(INFO, "    finished: " .. tostring(finished))
            return finished
        else
            if  self.parallel_to.finished do
                self.parallel_to = false
                self.priv_finish(self)
                return true
            else
                return false
            end
        end
    end,

    --[[!
        Override this in inherited actions. By default does almost nothing,
        but the "almost nothing" is important, so make sure to call this
        always at the end of your custom "__run", like this:

        ```
        Foo.__run = function(self, millis)
            echo("run")
            return self.__proto.__proto.__run(self, millis)
        end
        ```

        Basically, the "almost nothing" it does is that it decrements
        the "millis_left" property appropriately and returns true if
        the action has ended (that is, if "millis_left" is lower or
        equal zero) and false otherwise.

        Of course, there are exceptions like the never ending action
        where you don't want to run this, but generally you should.

        Arguments:
            - millis - the amount of time in milliseconds to simulate this
              iteration.
    ]]
    __run = function(self, millis)
        self.millis_left = self.millis_left - millis
        return (self.millis_left <= 0)
    end,

    priv_finish = function(self)
        self.finished = true
        var sys = self.queue
        if sys do sys._changed = true end

        if self.animation and self.last_animation != nil do
            var lanim = self.last_animation
            var aanim = self.actor:get_attr("animation")
            if lanim != aanim do
                self.actor:set_attr("animation", lanim)
            end
        end

        self:__finish()
    end,

    --[[!
        By default, empty. Overload in your inherited actions as you need.
        Called when the action finishes.
    ]]
    __finish = function(self)
    end,

    --[[!
        Forces the action to finish. Effective only when the "cancelable"
        property of the action is true (it is by default).
    ]]
    cancel = function(self)
        if  self.cancelable do
            self:priv_finish()
        end
    end
}
var Action = M.Action

--[[!
    An action that never ends.
]]
M.InfiniteAction = Action:clone {
    name = "InfiniteAction",

    --[[!
        One of the exceptional cases of the "__run" method; it always returns
        false because it doesn't manipulate "millis_left".
    ]]
    __run = function(self, millis)
        return false
    end
}

--[[!
    An action queue.

    Fields:
        - parent - the parent entity of this action queue.
        - actions - an array of actions.
]]
M.ActionQueue = table.Object:clone {
    name = "ActionQueue",

    --[[!
        Initializes the queue.

        Arguments:
            - parent - the parent entity.
    ]]
    __ctor = function(self, parent)
        self.parent   = parent
        self.actions  = createtable(4)
        self._changed = false
    end,

    --[[!
        Runs the action queue. If there are any actions left from the
        previous frame that are finished, the action array is first
        compacted. Then this runs the first unfinished action in the
        list (providing the millis as an argument).
    ]]
    run = function(self, millis)
        var acts = self.actions
        if self._changed do
            compact(acts, |i, v| not v.finished)
            self._changed = false
        end
        if #acts > 0 do
            var act = acts[1]
            @[debug] log(INFO, table.concat { "Executing ", act.name })

            -- keep the removal for the next frame
            act:priv_run(millis)
        end
    end,

    --[[!
        Enqueues an action. If multiple actions of the same type are not
        enabled on the action we're queuing, this first checks the existing
        queue and if it finds an action of the same type, it warns and returns.
        Otherwise it enqueues the action.
    ]]
    enqueue = function(self, act)
        var acts = self.actions
        if not act.allow_multiple do
            var str = act.name
            for i = 1, #acts do
                if str == acts[i].name do
                    log(WARNING, table.concat { "Action of the type ",
                        str, " is already present in the queue, ",
                        "multiplication explicitly disabled for the ",
                        "action." })
                    return
                end
            end
        end

        acts[#acts + 1] = act
        act.actor = self.parent
        act.queue = self
    end,

    --[[!
        Clears the action queue (cancels every action in the queue).
    ]]
    clear = function(self)
        var acts = self.actions
        for i = 1, #acts do
            acts[i]:cancel()
        end
    end
}

return M

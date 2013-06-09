local model = require("core.engine.model")
local frame = require("core.events.frame")

module("multipart_rendering", package.seeall)

plugin = {
    activate = function(self)
        if not CLIENT then return nil end
        self.render_args_timestamp = -2

        self.render = function(...)
            if not self.initialized then
                return nil
            end

            if self.render_args_timestamp ~= frame.get_frame() then
                local anim     = self:get_multipart_animation()
                local o        = self:get_attr("position"):copy()
                local yaw      = self:get_multipart_yaw()
                local pitch    = self:get_multipart_pitch()
                local roll     = self:get_multipart_roll()
                local flags    = self:get_multipart_flags()
                local basetime = 0

                self.render_args = self:create_render_args(yaw, pitch, anim, o, flags, basetime)
                self.render_args_timestamp = frame.get_frame()
            end

            for i, args in pairs(self.render_args) do
                model.render(unpack(args))
            end
        end
    end,

    get_multipart_animation = function(self)
        return math.bor(model.anims.IDLE, model.anims.LOOP)
    end,

    get_multipart_flags = function(self)
        return math.bor(
            model.render_flags.CULL_VFC,
            model.render_flags.CULL_OCCLUDED,
            model.render_flags.CULL_QUERY,
            model.render_flags.CULL_DIST,
            model.render_flags.FULLBRIGHT
        )
    end,

    get_multipart_yaw = function(self)
        return self:get_attr("yaw")
    end,

    get_multipart_pitch = function(self)
        return self:get_attr("pitch")
    end,

    get_multipart_roll = function(self)
        return self:get_attr("roll")
    end
}

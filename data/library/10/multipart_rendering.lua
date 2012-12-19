module("multipart_rendering", package.seeall)

plugin = {
    activate = function(self)
        if not CLIENT then return nil end
        self.rendering_args_timestamp = -2

        self.render = function(...)
            if not self.initialized then
                return nil
            end

            if self.rendering_args_timestamp ~= frame.get_frame() then
                local anim     = self:get_multipart_animation()
                local o        = self.position:copy()
                local yaw      = self:get_multipart_yaw()
                local pitch    = self:get_multipart_pitch()
                local flags    = self:get_multipart_flags()
                local basetime = 0

                self.rendering_args = self:create_rendering_args(yaw, pitch, anim, o, flags, basetime)
                self.rendering_args_timestamp = frame.get_frame()
            end

            for i, args in pairs(self.rendering_args) do
                model.render(unpack(args))
            end
        end
    end,

    get_multipart_animation = function(self)
        return math.bor(model.ANIM_IDLE, model.ANIM_LOOP)
    end,

    get_multipart_flags = function(self)
        return math.bor(
            model.CULL_VFC,
            model.CULL_OCCLUDED,
            model.CULL_QUERY,
            model.CULL_DIST,
            model.FULLBRIGHT
        )
    end,

    get_multipart_yaw = function(self)
        return self.yaw
    end,

    get_multipart_pitch = function(self)
        return self.pitch
    end
}

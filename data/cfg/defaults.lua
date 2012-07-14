-- these default settings get executed whenever "config.cfg" is not available
-- do not modify anything below, instead change settings in game, or add to autoexec.cfg

echo("OctaForge defaults")

EVAR.invmouse = 0         -- 1 for flightsim mode
EVAR.sensitivity = 3      -- similar number to quake
EVAR.fov = 100            -- 90 is default in other games

EVAR.musicvol = 60       -- set higher if you want (max 255)
EVAR.soundvol = 255      -- sounds average volume is actually set per sound, average 100

EVAR.gamma = 100          -- set to your liking, 100 = default

EVAR.fullbrightmodels = 25 -- make player models a bit easier to see

EVAR.sensitivity = 3      -- similar number to quake
EVAR.fov = 100            -- 90 is default in other games

EVAR.grassheight = 10

-- console

EVAR.consize = 5            -- console is 5 lines
EVAR.miniconsize = 5        -- mini-console is 5 lines
EVAR.miniconwidth = 40      -- mini-console is 40% of screen width
EVAR.fullconsize = 75       -- full console is 75% of screen height
EVAR.miniconfilter = 0x300  -- display chat and team chat in mini-console
EVAR.confilter = math.band(0x2FFF, math.bnot(EVAR.miniconfilter)) -- don't display other player frags or mini-console stuff in console
EVAR.fullconfilter = 0xFFFF -- display all messages in full console

-- WSAD

input.bind("W", [[input.forward()]])
input.bind("S", [[input.backward()]])
input.bind("A", [[input.strafe_left()]])
input.bind("D", [[input.strafe_right()]])

input.bind("UP", [[input.look_up()]])
input.bind("DOWN", [[input.look_down()]])
input.bind("LEFT", [[input.turn_left()]])
input.bind("RIGHT", [[input.turn_right()]])

input.bind("SPACE", [[input.jump()]])

input.bind("TAB", [[gui.show_scores()]])

input.bind("T", [[console.prompt()]])
input.bind("BACKQUOTE", [[console.prompt("/")]])
input.bind("SLASH", [[console.prompt("/")]])

input.bind("E", [[edit.toggle_mode()]])
input.bind("F1", [[edit.toggle_mode()]])

input.bind("KP_MINUS", [[console.skip(5)]])
input.bind("KP_PLUS", [[console.skip(-1000)]])

input.bind_var_toggle("PAUSE", "paused")

input.bind("F11", [[console.toggle()]])
input.bind("F12", [[engine.screenshot()]])

-- mouse

input.bind("MOUSE1", [[input.mouse1click()]])
input.bind("MOUSE2", [[input.mouse2click()]])
input.bind("MOUSE3", [[input.mouse3click()]])

-- universal scrollwheel + modifier commands:

input.bind("MOUSE4", [[universaldelta(1)]]) -- also used for editing, see below
input.bind("MOUSE5", [[universaldelta(-1)]])

-- edit binds

input.bind_edit("SPACE", [[edit.cancel_selection()]])
input.bind_edit("MOUSE1", [[if EVAR.blendpaintmode ~= 0 then texture.paint_blend_map() else edit.drag() end]])
input.bind_edit("MOUSE3", [[edit.select_corners()]])
input.bind_edit("MOUSE2", [[
    if EVAR.has_mouse_target == 0 then
        if EVAR.blendpaintmode ~= 0 then
            texture.rotate_blend_brush()
        else
            edit.move_selection()
        end
    else
        tgui.show_entity_properties_tab()
    end
]])

input.bind_edit("KP_ENTER", [[edit.select_entities([=[edit.in_selection()]=])]])
-- TODO: replace with proper class-based system
-- input.bind_edit("N", [[SELECT ALL ENTITIES OF CURRENTLY SELECTED TYPE]])

input.bind_edit("LSHIFT", [[edit.cut_selection()]])
input.bind_modifier_edit("LCTRL", "passthrough")
input.bind_modifier_edit("LALT", "hmapedit")
input.bind_edit("DELETE", [[edit.delete_selection()]])

input.bind_edit("X", [[edit.flip()]])
input.bind_edit("C", [[edit.copy()]])
input.bind_edit("V", [[edit.paste()]])
input.bind_edit("Z", [[edit.undo(); EVAR.passthroughsel = 0]])
input.bind_edit("U", [[edit.undo(); EVAR.passthroughsel = 0]])
input.bind_edit("I", [[edit.redo()]])
input.bind_var_toggle_edit("H", "hmapedit")

input.bind_var_toggle_edit("5", "hidehud")
input.bind_var_toggle_edit("6", "entselsnap")
input.bind_var_toggle_edit("7", "outline")
input.bind_var_toggle_edit("8", "wireframe")
input.bind_var_toggle("9", "thirdperson")
input.bind_var_toggle_edit("0", "allfaces")
input.bind_edit("K", [[world.calc_light()]])
input.bind_var_toggle_edit("L", "fullbright")
input.bind_var_toggle_edit("M", "showmat")

input.bind_edit("F8", [[tgui.show_entities_list()]])
input.bind_edit("F9", [[echo("%(1)s : %(2)s" % {
    texture.get_selected_index(),
    texture.get_slot_name(texture.get_selected_index())
})]])

input.bind_edit("G", [[domodifier(1)]])
input.bind_edit("F", [[domodifier(2)]])
input.bind_edit("Q", [[domodifier(3)]])
input.bind_edit("R", [[domodifier(4)]])
input.bind_edit("Y", [[domodifier(5)]])
input.bind_edit("B", [[domodifier(6)]])
input.bind_edit("COMMA", [[domodifier(7); input.on_release(function() camera.center_on_entity() end)]])

input.bind_edit("1", [[domodifier(8)]]) -- vSlot: offset H
input.bind_edit("2", [[domodifier(9)]]) -- vSlot: offset V
input.bind_edit("3", [[domodifier(10)]]) -- vSlot: rotate
input.bind_edit("4", [[domodifier(11)]]) -- vSlot: scale

--input.bind_edit("LALT", [[multiplier = 10; input.on_release(function() multiplier = 1 end)]])
--input.bind_edit("RALT", [[multiplier2 = 32; input.on_release(function() multiplier2 = 16 end)]])

-- blendmap painting
input.bind_edit("KP0", [[texture.set_blend_paint_mode(EVAR.blendpaintmode ~= 0 and 0 or 1)]])
input.bind_edit("KP1", [[if EVAR.blendpaintmode ~= 0 then texture.set_blend_paint_mode(1) else input.left() end]])
input.bind_edit("KP2", [[if EVAR.blendpaintmode ~= 0 then texture.set_blend_paint_mode(2) else input.backward() end]])
input.bind_edit("KP3", [[if EVAR.blendpaintmode ~= 0 then texture.set_blend_paint_mode(3) else input.right() end]])
input.bind_edit("KP4", [[if EVAR.blendpaintmode ~= 0 then texture.set_blend_paint_mode(4) else input.turn_left() end]])
input.bind_edit("KP5", [[texture.set_blend_paint_mode(5)]])
input.bind_edit("KP6", [[input.turn_right()]])
input.bind_edit("KP8", [[if EVAR.blendpaintmode ~= 0 then texture.scroll_blend_brush(-1) else input.forward() end]])
input.bind_edit("KP9", [[texture.scroll_blend_brush(1)]])

input.bind("M", [[camera.mouselook()]])
input.bind_edit("M", [[camera.mouselook()]])
input.bind_var_toggle_edit("0", "showmat")

input.bind("PAGEDOWN", [[input.look_up()]])
input.bind("PAGEDOWN", [[input.look_down()]])

-- these default settings get executed whenever "config.cfg" is not available
-- do not modify anything below, instead change settings in game, or add to autoexec.cfg

echo("OctaForge defaults")

invmouse = 0         -- 1 for flightsim mode
sensitivity = 3      -- similar number to quake
fov = 100            -- 90 is default in other games

musicvol = 60       -- set higher if you want (max 255)
soundvol = 255      -- sounds average volume is actually set per sound, average 100

gamma = 100          -- set to your liking, 100 = default

fullbrightmodels = 60 -- make player models a bit easier to see

sensitivity = 3      -- similar number to quake
fov = 100            -- 90 is default in other games

musicvol = 60       -- set higher if you want (max 255)
soundvol = 255      -- sounds average volume is actually set per sound, average 100

gamma = 100          -- set to your liking, 100 = default

fullbrightmodels = 60 -- make player models a bit easier to see

grassheight = 10

-- console

consize = 5            -- console is 5 lines
miniconsize = 5        -- mini-console is 5 lines
miniconwidth = 40      -- mini-console is 40% of screen width
fullconsize = 75       -- full console is 75% of screen height
miniconfilter = 0x300  -- display chat and team chat in mini-console
confilter = math.band(0x2FFF, math.bnot(miniconfilter)) -- don't display other player frags or mini-console stuff in console
fullconfilter = 0xFFFF -- display all messages in full console

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

input.bind_var("PAUSE", "paused")

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
input.bind_edit("MOUSE1", [[if blendpaintmode ~= 0 then texture.blendmap.paint() else edit.drag() end]])
input.bind_edit("MOUSE3", [[edit.select_corners()]])
input.bind_edit("MOUSE2", [[
    if has_mouse_target == 0 then
        if blendpaintmode ~= 0 then
            texture.blendbrush.rotate()
        else
            edit.move_selection()
        end
    else
        gui.show_entity_properties_gui()
    end
]])

input.bind_edit("KP_ENTER", [[edit.select_entities([=[edit.in_selection()]=])]])
-- TODO: replace with proper class-based system
-- input.bind_edit("N", [[SELECT ALL ENTITIES OF CURRENTLY SELECTED TYPE]])

input.bind_edit("LSHIFT", [[edit.cut_selection()]])
input.bind_mod_edit("LCTRL", "passthrough")
input.bind_mod_edit("LALT", "hmapedit")
input.bind_edit("DELETE", [[edit.delete_selection()]])

input.bind_edit("X", [[edit.flip()]])
input.bind_edit("C", [[edit.copy()]])
input.bind_edit("V", [[edit.paste()]])
input.bind_edit("Z", [[edit.undo(); passthroughsel = 0]])
input.bind_edit("U", [[edit.undo(); passthroughsel = 0]])
input.bind_edit("I", [[edit.redo()]])
input.bind_var_edit("H", "hmapedit")

input.bind_var_edit("5", "hidehud")
input.bind_var_edit("6", "entselsnap")
input.bind_var_edit("7", "outline")
input.bind_var_edit("8", "wireframe")
input.bind_var("9", "thirdperson")
input.bind_var_edit("0", "allfaces")
input.bind_edit("K", [[world.calc_light()]])
input.bind_var_edit("L", "fullbright")
input.bind_var_edit("M", "showmat")

input.bind_edit("F9", [[echo("%(1)s : %(2)s" % { texture.getsel(), texture.getname(texture.getsel()) })]])

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

input.bind_edit("LALT", [[multiplier = 10; input.on_release(function() multiplier = 1 end)]])
input.bind_edit("RALT", [[multiplier2 = 32; input.on_release(function() multiplier2 = 16 end)]])

-- blendmap painting
input.bind_edit("KP0", [[texture.setblendpaintmode(blendpaintmode ~= 0 and 0 or 1)]])
input.bind_edit("KP1", [[if blendpaintmode ~= 0 then texture.setblendpaintmode(1) else input.left() end]])
input.bind_edit("KP2", [[if blendpaintmode ~= 0 then texture.setblendpaintmode(2) else input.backward() end]])
input.bind_edit("KP3", [[if blendpaintmode ~= 0 then texture.setblendpaintmode(3) else input.right() end]])
input.bind_edit("KP4", [[if blendpaintmode ~= 0 then texture.setblendpaintmode(4) else input.turn_left() end]])
input.bind_edit("KP5", [[texture.setblendpaintmode(5)]])
input.bind_edit("KP6", [[input.turn_right()]])
input.bind_edit("KP8", [[if blendpaintmode ~= 0 then texture.blendbrush.scroll(-1) else input.forward() end]])
input.bind_edit("KP9", [[texture.blendbrush.scroll(1)]])

input.bind("M", [[camera.mouselook()]])
input.bind_edit("M", [[camera.mouselook()]])
input.bind_var_edit("0", "showmat")

input.bind("PAGEDOWN", [[input.look_up()]])
input.bind("PAGEDOWN", [[input.look_down()]])

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

input.bind("W", function() input.forward() end)
input.bind("S", function() input.backward() end)
input.bind("A", function() input.strafe_left() end)
input.bind("D", function() input.strafe_right() end)

input.bind("UP", function() input.look_up() end)
input.bind("DOWN", function() input.look_down() end)
input.bind("LEFT", function() input.turn_left() end)
input.bind("RIGHT", function() input.turn_right() end)

input.bind("SPACE", function() input.jump() end)

input.bind("TAB", function() gui.showscores() end)

input.bind("T", function() console.prompt() end)
input.bind("BACKQUOTE", function() console.prompt("/") end)
input.bind("SLASH", function() console.prompt("/") end)

input.bind("E", function() world.edittoggle() end)
input.bind("F1", function() world.edittoggle() end)

input.bind("KP_MINUS", function() console.skip(5) end)
input.bind("KP_PLUS", function() console.skip(-1000) end)

input.bind_var("PAUSE", "paused")

input.bind("F11", function() console.toggle() end)
input.bind("F12", function() engine.screenshot() end)

-- mouse

input.bind("MOUSE1", function() input.mouse1click() end)
input.bind("MOUSE2", function() input.mouse2click() end)
input.bind("MOUSE3", function() input.mouse3click() end)

-- universal scrollwheel + modifier commands:

input.bind("MOUSE4", function() universaldelta(1) end) -- also used for editing, see below
input.bind("MOUSE5", function() universaldelta(-1) end)

-- edit binds

input.bind_edit("SPACE", function() world.cancelsel() end)
input.bind_edit("MOUSE1", function() if blendpaintmode ~= 0 then texture.blendmap.paint() else world.editdrag() end end)
input.bind_edit("MOUSE3", function() world.selcorners() end)
input.bind_edit("MOUSE2", function() if blendpaintmode ~= 0 then texture.blendbrush.rotate() else world.editextend() end end)

input.bind_edit("KP_ENTER", function() world.entselect([=[world.insel()]=]) end)
input.bind_edit("N", function() world.selentfindall() end)

input.bind_edit("LSHIFT", function() world.editcut() end)
input.bind_mod_edit("LCTRL", "passthrough")
input.bind_mod_edit("LALT", "hmapedit")
input.bind_edit("DELETE", function() world.editdel() end)

input.bind_edit("X", function() world.editflip() end)
input.bind_edit("C", function() world.editcopy() end)
input.bind_edit("V", function() world.editpaste() end)
input.bind_edit("Z", function() world.undo(); passthroughsel = 0 end)
input.bind_edit("U", function() world.undo(); passthroughsel = 0 end)
input.bind_edit("I", function() world.redo() end)
input.bind_edit("H", function() if hmapedit ~= 0 then world.editface(1, -1) else hmapedit = 1 end end)

input.bind_var_edit("5", "hidehud")
input.bind_var_edit("6", "entselsnap")
input.bind_var_edit("7", "outline")
input.bind_var_edit("8", "wireframe")
input.bind_var("9", "thirdperson")
input.bind_var_edit("0", "allfaces")
input.bind_edit("K", function() world.calclight() end)
input.bind_var_edit("L", "fullbright")
input.bind_var_edit("M", "showmat")

input.bind_edit("PERIOD", function() world.selentedit() end)

input.bind_edit("F9", function() echo("%(1)s : %(2)s" % { texture.getsel(), texture.getname(texture.getsel()) }) end)

input.bind_edit("G", function() domodifier(1) end)
input.bind_edit("F", function() domodifier(2) end)
input.bind_edit("Q", function() domodifier(3) end)
input.bind_edit("R", function() domodifier(4) end)
input.bind_edit("Y", function() domodifier(6) end)
input.bind_edit("B", function() domodifier(9) end)
input.bind_edit("COMMA", function() domodifier(10); input.on_release(function() world.entautoview() end) end)

input.bind_edit("1", function() domodifier(11) end)
input.bind_edit("2", function() domodifier(12) end)
input.bind_edit("3", function() domodifier(13) end)
input.bind_edit("4", function() domodifier(14) end)

input.bind_edit("5", function() domodifier(15) end) -- vSlot: offset H
input.bind_edit("6", function() domodifier(16) end) -- vSlot: offset V
input.bind_edit("7", function() domodifier(17) end) -- vSlot: rotate
input.bind_edit("8", function() domodifier(18) end) -- vSlot: scale

input.bind_edit("LALT", function() multiplier = 10; input.on_release(function() multiplier = 1 end) end)
input.bind_edit("RALT", function() multiplier2 = 32; input.on_release(function() multiplier2 = 16 end) end)

-- blendmap painting
input.bind_edit("KP0", function() texture.setblendpaintmode(blendpaintmode ~= 0 and 0 or 1) end)
input.bind_edit("KP1", function() if blendpaintmode ~= 0 then texture.setblendpaintmode(1) else input.left() end end)
input.bind_edit("KP2", function() if blendpaintmode ~= 0 then texture.setblendpaintmode(2) else input.backward() end end)
input.bind_edit("KP3", function() if blendpaintmode ~= 0 then texture.setblendpaintmode(3) else input.right() end end)
input.bind_edit("KP4", function() if blendpaintmode ~= 0 then texture.setblendpaintmode(4) else input.turn_left() end end)
input.bind_edit("KP5", function() texture.setblendpaintmode(5) end)
input.bind_edit("KP6", function() input.turn_right() end)
input.bind_edit("KP8", function() if blendpaintmode ~= 0 then texture.blendbrush.scroll(-1) else input.forward() end end)
input.bind_edit("KP9", function() texture.blendbrush.scroll(1) end)

input.bind("M", function() camera.mouselook() end)
input.bind_edit("M", function() camera.mouselook() end)
input.bind_var_edit("0", "showmat")

input.bind("PAGEDOWN", function() input.look_up() end)
input.bind("PAGEDOWN", function() input.look_down() end)

input.bind_edit("MOUSE2", function() world.editextend_intensity() end)
input.bind_edit("P", function() world.centerent() end)

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

of.console.binds.add("W", [[of.console.forward()]])
of.console.binds.add("S", [[of.console.backward()]])
of.console.binds.add("A", [[of.console.left()]])
of.console.binds.add("D", [[of.console.right()]])

of.console.binds.add("UP", [[of.console.forward()]])
of.console.binds.add("DOWN", [[of.console.backward()]])
of.console.binds.add("LEFT", [[of.console.left()]])
of.console.binds.add("RIGHT", [[of.console.right()]])

of.console.binds.add("SPACE", [[of.console.jump()]])

of.console.binds.add("TAB", [[of.gui.showscores()]])

of.console.binds.add("T", [[of.console.saycommand()]])
--of.console.binds.add("T", [[of.console.sayteamcommand()]])
of.console.binds.add("BACKQUOTE", [[of.console.saycommand("/")]])
of.console.binds.add("SLASH", [[of.console.saycommand("/")]])

of.console.binds.add("E", [[of.world.edittoggle()]])
of.console.binds.add("F1", [[of.world.edittoggle()]])

of.console.binds.add("KP_MINUS", [[of.console.skip(5)]])
of.console.binds.add("KP_PLUS", [[of.console.skip(-1000)]])

of.console.binds.addvar("PAUSE", "paused")

of.console.binds.add("F11", [[of.console.toggle()]])
of.console.binds.add("F12", [[of.engine.screenshot()]])

-- mouse

of.console.binds.add("MOUSE1", [[of.console.mouse1click()]])
of.console.binds.add("MOUSE2", [[of.console.mouse2click()]])
of.console.binds.add("MOUSE3", [[of.console.mouse3click()]])

-- universal scrollwheel + modifier commands:

of.console.binds.add("MOUSE4", [[universaldelta(1)]]) -- also used for editing, see below
of.console.binds.add("MOUSE5", [[universaldelta(-1)]])

-- edit binds

of.console.binds.addedit("SPACE", [[of.world.cancelsel()]])
of.console.binds.addedit("MOUSE1", [[if blendpaintmode ~= 0 then of.blend.map.paint() else of.world.editdrag() end]])
of.console.binds.addedit("MOUSE3", [[of.world.selcorners()]])
of.console.binds.addedit("MOUSE2", [[if blendpaintmode ~= 0 then of.blend.brush.rotate() else of.world.editextend() end]])

of.console.binds.addedit("KP_ENTER", [[of.world.entselect([=[of.world.insel()]=])]])
of.console.binds.addedit("N", [[of.world.selentfindall()]])

of.console.binds.addedit("LSHIFT", [[of.world.editcut()]])
of.console.binds.addmodedit("LCTRL", "passthrough")
of.console.binds.addmodedit("LALT", "hmapedit")
of.console.binds.addedit("DELETE", [[of.world.editdel()]])

of.console.binds.addedit("X", [[of.world.editflip()]])
of.console.binds.addedit("C", [[of.world.editcopy()]])
of.console.binds.addedit("V", [[of.world.editpaste()]])
of.console.binds.addedit("Z", [[of.world.undo(); passthroughsel = 0]])
of.console.binds.addedit("U", [[of.world.undo(); passthroughsel = 0]])
of.console.binds.addedit("I", [[of.world.redo()]])
of.console.binds.addedit("H", [[if hmapedit ~= 0 then of.world.editface(1, -1) else hmapedit = 1 end]])

of.console.binds.addvaredit("5", "hidehud")
of.console.binds.addvaredit("6", "entselsnap")
of.console.binds.addvaredit("7", "outline")
of.console.binds.addvaredit("8", "wireframe")
of.console.binds.addvar("9", "thirdperson")
of.console.binds.addvaredit("0", "allfaces")
of.console.binds.addedit("K", [[of.world.calclight()]])
of.console.binds.addvaredit("L", "fullbright")
of.console.binds.addvaredit("M", "showmat")

of.console.binds.addedit("PERIOD", [[of.world.selentedit()]])

of.console.binds.addedit("F2", [[of.texture.showgui()]])
of.console.binds.addedit("F3", [[if of.gui.clear() ~= 1 then showquickeditgui() end]])
of.console.binds.addedit("F4", [[if of.gui.clear() ~= 1 then of.gui.show("mapmodels") end]])
of.console.binds.addedit("F9", [[echo("%(1)s : %(2)s" % { of.texture.getsel(), of.texture.getname(of.texture.getsel()) })]])

of.console.binds.addedit("G", [[domodifier(1)]])
of.console.binds.addedit("F", [[domodifier(2)]])
of.console.binds.addedit("Q", [[domodifier(3)]])
of.console.binds.addedit("R", [[domodifier(4)]])
of.console.binds.addedit("Y", [[domodifier(6)]])
of.console.binds.addedit("B", [[domodifier(9)]])
of.console.binds.addedit("COMMA", [[domodifier(10); of.console.onrelease("of.world.entautoview()")]])

of.console.binds.addedit("1", [[domodifier(11)]])
of.console.binds.addedit("2", [[domodifier(12)]])
of.console.binds.addedit("3", [[domodifier(13)]])
of.console.binds.addedit("4", [[domodifier(14)]])

of.console.binds.addedit("5", [[domodifier(15)]]) -- vSlot: offset H
of.console.binds.addedit("6", [[domodifier(16)]]) -- vSlot: offset V
of.console.binds.addedit("7", [[domodifier(17)]]) -- vSlot: rotate
of.console.binds.addedit("8", [[domodifier(18)]]) -- vSlot: scale

of.console.binds.addedit("LALT", [[multiplier = 10; of.console.onrelease("multiplier = 1")]])
of.console.binds.addedit("RALT", [[multiplier2 = 10; of.console.onrelease("multiplier2 = 1")]])

-- blendmap painting
of.console.binds.addedit("KP0", [[of.blend.setpaintmode(blendpaintmode ~= 0 and 0 or 1)]])
of.console.binds.addedit("KP1", [[if blendpaintmode ~= 0 then of.blend.setpaintmode(1) else of.console.left() end]])
of.console.binds.addedit("KP2", [[if blendpaintmode ~= 0 then of.blend.setpaintmode(2) else of.console.backward() end]])
of.console.binds.addedit("KP3", [[if blendpaintmode ~= 0 then of.blend.setpaintmode(3) else of.console.right() end]])
of.console.binds.addedit("KP4", [[if blendpaintmode ~= 0 then of.blend.setpaintmode(4) else of.console.turn_left() end]])
of.console.binds.addedit("KP5", [[of.blend.setpaintmode(5)]])
of.console.binds.addedit("KP6", [[of.console.turn_right()]])
of.console.binds.addedit("KP8", [[if blendpaintmode ~= 0 then of.blend.brush.scroll(-1) else of.console.forward() end]])
of.console.binds.addedit("KP9", [[of.blend.brush.scroll(1)]])

of.console.binds.add("M", [[of.camera.mouselook()]])
of.console.binds.addedit("M", [[of.camera.mouselook()]])
of.console.binds.addvaredit("0", "showmat")

of.console.binds.add("PAGEDOWN", [[of.console.look_up()]])
of.console.binds.add("PAGEDOWN", [[of.console.look_down()]])

of.console.binds.addedit("MOUSE2", [[of.world.editextend_intensity()]])
of.console.binds.addedit("P", [[of.world.centerent()]])
-- create entity where we're pointing
of.console.binds.addedit("F8", [[of.console.save_mouse_pos(); of.gui.prepentsgui()]])

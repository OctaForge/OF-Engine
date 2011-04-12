-- these default settings get executed whenever "config.cfg" is not available
-- do not modify anything below, instead change settings in game, or add to autoexec.cfg

echo("CubeCreate defaults")

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

cc.console.binds.add("W", [[cc.console.forward()]])
cc.console.binds.add("S", [[cc.console.backward()]])
cc.console.binds.add("A", [[cc.console.left()]])
cc.console.binds.add("D", [[cc.console.right()]])

cc.console.binds.add("UP", [[cc.console.forward()]])
cc.console.binds.add("DOWN", [[cc.console.backward()]])
cc.console.binds.add("LEFT", [[cc.console.left()]])
cc.console.binds.add("RIGHT", [[cc.console.right()]])

cc.console.binds.add("SPACE", [[cc.console.jump()]])

cc.console.binds.add("TAB", [[cc.gui.showscores()]])

cc.console.binds.add("T", [[cc.console.saycommand()]])
--cc.console.binds.add("T", [[cc.console.sayteamcommand()]])
cc.console.binds.add("BACKQUOTE", [[cc.console.saycommand("/")]])
cc.console.binds.add("SLASH", [[cc.console.saycommand("/")]])

cc.console.binds.add("E", [[cc.world.edittoggle()]])
cc.console.binds.add("F1", [[cc.world.edittoggle()]])

cc.console.binds.add("KP_MINUS", [[cc.console.skip(5)]])
cc.console.binds.add("KP_PLUS", [[cc.console.skip(-1000)]])

cc.console.binds.addvar("PAUSE", "paused")

cc.console.binds.add("F11", [[cc.console.toggle()]])
cc.console.binds.add("F12", [[cc.engine.screenshot()]])

-- universal scrollwheel + modifier commands:

cc.console.binds.add("MOUSE4", [[universaldelta(1)]]) -- also used for editing, see below
cc.console.binds.add("MOUSE5", [[universaldelta(-1)]])

-- edit binds

cc.console.binds.addedit("SPACE", [[cc.world.cancelsel()]])
cc.console.binds.addedit("MOUSE1", [[if blendpaintmode ~= 0 then cc.blend.map.paint() else cc.world.editdrag() end]])
cc.console.binds.addedit("MOUSE3", [[cc.world.selcorners()]])
cc.console.binds.addedit("MOUSE2", [[if blendpaintmode ~= 0 then cc.blend.brush.rotate() else cc.world.editextend() end]])

cc.console.binds.addedit("KP_ENTER", [[cc.world.entselect([=[cc.world.insel()]=])]])
cc.console.binds.addedit("N", [[cc.world.selentfindall()]])

cc.console.binds.addedit("LSHIFT", [[cc.world.editcut()]])
cc.console.binds.addmodedit("LCTRL", "passthrough")
cc.console.binds.addmodedit("LALT", "hmapedit")
cc.console.binds.addedit("DELETE", [[cc.world.editdel()]])

cc.console.binds.addedit("X", [[cc.world.editflip()]])
cc.console.binds.addedit("C", [[cc.world.editcopy()]])
cc.console.binds.addedit("V", [[cc.world.editpaste()]])
cc.console.binds.addedit("Z", [[cc.world.undo(); passthroughsel = 0]])
cc.console.binds.addedit("U", [[cc.world.undo(); passthroughsel = 0]])
cc.console.binds.addedit("I", [[cc.world.redo()]])
cc.console.binds.addedit("H", [[if hmapedit ~= 0 then cc.world.editface(1, -1) else hmapedit = 1 end]])

cc.console.binds.addvaredit("5", "hidehud")
cc.console.binds.addvaredit("6", "entselsnap")
cc.console.binds.addvaredit("7", "outline")
cc.console.binds.addvaredit("8", "wireframe")
cc.console.binds.addvar("9", "thirdperson")
cc.console.binds.addvaredit("0", "allfaces")
cc.console.binds.addedit("K", [[cc.world.calclight()]])
cc.console.binds.addvaredit("L", "fullbright")
cc.console.binds.addvaredit("M", "showmat")

cc.console.binds.addedit("PERIOD", [[cc.world.selentedit()]])

cc.console.binds.addedit("F2", [[cc.texture.showgui()]])
cc.console.binds.addedit("F3", [[if cc.gui.clear() ~= 1 then showquickeditgui() end]])
cc.console.binds.addedit("F4", [[if cc.gui.clear() ~= 1 then cc.gui.show("mapmodels") end]])
cc.console.binds.addedit("F9", [[echo("%(1)s : %(2)s" % { cc.texture.getsel(), cc.texture.getname(cc.texture.getsel()) })]])

cc.console.binds.addedit("G", [[domodifier(1)]])
cc.console.binds.addedit("F", [[domodifier(2)]])
cc.console.binds.addedit("Q", [[domodifier(3)]])
cc.console.binds.addedit("R", [[domodifier(4)]])
cc.console.binds.addedit("Y", [[domodifier(6)]])
cc.console.binds.addedit("B", [[domodifier(9)]])
cc.console.binds.addedit("COMMA", [[domodifier(10); cc.console.onrelease("cc.world.entautoview()")]])

cc.console.binds.addedit("1", [[domodifier(11)]])
cc.console.binds.addedit("2", [[domodifier(12)]])
cc.console.binds.addedit("3", [[domodifier(13)]])
cc.console.binds.addedit("4", [[domodifier(14)]])

cc.console.binds.addedit("5", [[domodifier(15)]]) -- vSlot: offset H
cc.console.binds.addedit("6", [[domodifier(16)]]) -- vSlot: offset V
cc.console.binds.addedit("7", [[domodifier(17)]]) -- vSlot: rotate
cc.console.binds.addedit("8", [[domodifier(18)]]) -- vSlot: scale

cc.console.binds.addedit("LALT", [[multiplier = 10; cc.console.onrelease("multiplier = 1")]])
cc.console.binds.addedit("RALT", [[multiplier2 = 10; cc.console.onrelease("multiplier2 = 1")]])

-- blendmap painting
cc.console.binds.addedit("KP0", [[cc.blend.setpaintmode(blendpaintmode ~= 0 and 0 or 1)]])
cc.console.binds.addedit("KP1", [[if blendpaintmode ~= 0 then cc.blend.setpaintmode(1) else cc.console.left() end]])
cc.console.binds.addedit("KP2", [[if blendpaintmode ~= 0 then cc.blend.setpaintmode(2) else cc.console.backward() end]])
cc.console.binds.addedit("KP3", [[if blendpaintmode ~= 0 then cc.blend.setpaintmode(3) else cc.console.right() end]])
cc.console.binds.addedit("KP4", [[if blendpaintmode ~= 0 then cc.blend.setpaintmode(4) else cc.console.turn_left() end]])
cc.console.binds.addedit("KP5", [[cc.blend.setpaintmode(5)]])
cc.console.binds.addedit("KP6", [[cc.console.turn_right()]])
cc.console.binds.addedit("KP8", [[if blendpaintmode ~= 0 then cc.blend.brush.scroll(-1) else cc.console.forward() end]])
cc.console.binds.addedit("KP9", [[cc.blend.brush.scroll(1)]])

cc.console.binds.add("MOUSE1", [[cc.console.mouse1click()]])
cc.console.binds.add("MOUSE2", [[cc.console.mouse2click()]])
cc.console.binds.add("MOUSE3", [[cc.console.mouse3click()]])

cc.console.binds.add("H", [[cc.console.actionkey0()]]) -- by convention, a 'help' dialog should appear

cc.console.binds.add("1", [[cc.console.actionkey1()]])
cc.console.binds.add("2", [[cc.console.actionkey2()]])
cc.console.binds.add("3", [[cc.console.actionkey3()]])
cc.console.binds.add("4", [[cc.console.actionkey4()]])
cc.console.binds.add("5", [[cc.console.actionkey5()]])
cc.console.binds.add("6", [[cc.console.actionkey6()]])
cc.console.binds.add("7", [[cc.console.actionkey7()]])
cc.console.binds.add("8", [[cc.console.actionkey8()]])

cc.console.binds.add("Y", [[cc.console.actionkey9()]])
cc.console.binds.add("U", [[cc.console.actionkey10()]])
cc.console.binds.add("I", [[cc.console.actionkey11()]])
cc.console.binds.add("O", [[cc.console.actionkey12()]])
cc.console.binds.add("P", [[cc.console.actionkey13()]])
cc.console.binds.add("J", [[cc.console.actionkey14()]])
cc.console.binds.add("K", [[cc.console.actionkey15()]])
cc.console.binds.add("L", [[cc.console.actionkey16()]])

cc.console.binds.add("F", [[cc.console.actionkey17()]])
-- etc.;

cc.console.binds.add("M", [[cc.camera.mouselook()]])
cc.console.binds.addedit("M", [[cc.camera.mouselook()]])
cc.console.binds.addvaredit("0", "showmat")

cc.console.binds.add("PAGEDOWN", [[cc.console.look_up()]])
cc.console.binds.add("PAGEDOWN", [[cc.console.look_down()]])

cc.console.binds.addedit("MOUSE2", [[cc.world.editextend_intensity()]])
cc.console.binds.addedit("F7", [[cc.console.actionkey0()]])
cc.console.binds.addedit("P", [[cc.world.centerent()]])
-- create entity where we're pointing
cc.console.binds.addedit("F8", [[cc.console.save_mouse_pos(); cc.gui.prepentsgui()]])

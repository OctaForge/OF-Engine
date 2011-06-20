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

console.binds.add("W", [[console.forward()]])
console.binds.add("S", [[console.backward()]])
console.binds.add("A", [[console.left()]])
console.binds.add("D", [[console.right()]])

console.binds.add("UP", [[console.forward()]])
console.binds.add("DOWN", [[console.backward()]])
console.binds.add("LEFT", [[console.left()]])
console.binds.add("RIGHT", [[console.right()]])

console.binds.add("SPACE", [[console.jump()]])

console.binds.add("TAB", [[gui.showscores()]])

console.binds.add("T", [[console.saycommand()]])
--console.binds.add("T", [[console.sayteamcommand()]])
console.binds.add("BACKQUOTE", [[console.saycommand("/")]])
console.binds.add("SLASH", [[console.saycommand("/")]])

console.binds.add("E", [[world.edittoggle()]])
console.binds.add("F1", [[world.edittoggle()]])

console.binds.add("KP_MINUS", [[console.skip(5)]])
console.binds.add("KP_PLUS", [[console.skip(-1000)]])

console.binds.addvar("PAUSE", "paused")

console.binds.add("F11", [[console.toggle()]])
console.binds.add("F12", [[engine.screenshot()]])

-- mouse

console.binds.add("MOUSE1", [[console.mouse1click()]])
console.binds.add("MOUSE2", [[console.mouse2click()]])
console.binds.add("MOUSE3", [[console.mouse3click()]])

-- universal scrollwheel + modifier commands:

console.binds.add("MOUSE4", [[universaldelta(1)]]) -- also used for editing, see below
console.binds.add("MOUSE5", [[universaldelta(-1)]])

-- edit binds

console.binds.addedit("SPACE", [[world.cancelsel()]])
console.binds.addedit("MOUSE1", [[if blendpaintmode ~= 0 then texture.blendmap.paint() else world.editdrag() end]])
console.binds.addedit("MOUSE3", [[world.selcorners()]])
console.binds.addedit("MOUSE2", [[if blendpaintmode ~= 0 then texture.blendbrush.rotate() else world.editextend() end]])

console.binds.addedit("KP_ENTER", [[world.entselect([=[world.insel()]=])]])
console.binds.addedit("N", [[world.selentfindall()]])

console.binds.addedit("LSHIFT", [[world.editcut()]])
console.binds.addmodedit("LCTRL", "passthrough")
console.binds.addmodedit("LALT", "hmapedit")
console.binds.addedit("DELETE", [[world.editdel()]])

console.binds.addedit("X", [[world.editflip()]])
console.binds.addedit("C", [[world.editcopy()]])
console.binds.addedit("V", [[world.editpaste()]])
console.binds.addedit("Z", [[world.undo(); passthroughsel = 0]])
console.binds.addedit("U", [[world.undo(); passthroughsel = 0]])
console.binds.addedit("I", [[world.redo()]])
console.binds.addedit("H", [[if hmapedit ~= 0 then world.editface(1, -1) else hmapedit = 1 end]])

console.binds.addvaredit("5", "hidehud")
console.binds.addvaredit("6", "entselsnap")
console.binds.addvaredit("7", "outline")
console.binds.addvaredit("8", "wireframe")
console.binds.addvar("9", "thirdperson")
console.binds.addvaredit("0", "allfaces")
console.binds.addedit("K", [[world.calclight()]])
console.binds.addvaredit("L", "fullbright")
console.binds.addvaredit("M", "showmat")

console.binds.addedit("PERIOD", [[world.selentedit()]])

console.binds.addedit("F9", [[echo("%(1)s : %(2)s" % { texture.getsel(), texture.getname(texture.getsel()) })]])

console.binds.addedit("G", [[domodifier(1)]])
console.binds.addedit("F", [[domodifier(2)]])
console.binds.addedit("Q", [[domodifier(3)]])
console.binds.addedit("R", [[domodifier(4)]])
console.binds.addedit("Y", [[domodifier(6)]])
console.binds.addedit("B", [[domodifier(9)]])
console.binds.addedit("COMMA", [[domodifier(10); console.onrelease("world.entautoview()")]])

console.binds.addedit("1", [[domodifier(11)]])
console.binds.addedit("2", [[domodifier(12)]])
console.binds.addedit("3", [[domodifier(13)]])
console.binds.addedit("4", [[domodifier(14)]])

console.binds.addedit("5", [[domodifier(15)]]) -- vSlot: offset H
console.binds.addedit("6", [[domodifier(16)]]) -- vSlot: offset V
console.binds.addedit("7", [[domodifier(17)]]) -- vSlot: rotate
console.binds.addedit("8", [[domodifier(18)]]) -- vSlot: scale

console.binds.addedit("LALT", [[multiplier = 10; console.onrelease("multiplier = 1")]])
console.binds.addedit("RALT", [[multiplier2 = 32; console.onrelease("multiplier2 = 16")]])

-- blendmap painting
console.binds.addedit("KP0", [[texture.setblendpaintmode(blendpaintmode ~= 0 and 0 or 1)]])
console.binds.addedit("KP1", [[if blendpaintmode ~= 0 then texture.setblendpaintmode(1) else console.left() end]])
console.binds.addedit("KP2", [[if blendpaintmode ~= 0 then texture.setblendpaintmode(2) else console.backward() end]])
console.binds.addedit("KP3", [[if blendpaintmode ~= 0 then texture.setblendpaintmode(3) else console.right() end]])
console.binds.addedit("KP4", [[if blendpaintmode ~= 0 then texture.setblendpaintmode(4) else console.turn_left() end]])
console.binds.addedit("KP5", [[texture.setblendpaintmode(5)]])
console.binds.addedit("KP6", [[console.turn_right()]])
console.binds.addedit("KP8", [[if blendpaintmode ~= 0 then texture.blendbrush.scroll(-1) else console.forward() end]])
console.binds.addedit("KP9", [[texture.blendbrush.scroll(1)]])

console.binds.add("M", [[camera.mouselook()]])
console.binds.addedit("M", [[camera.mouselook()]])
console.binds.addvaredit("0", "showmat")

console.binds.add("PAGEDOWN", [[console.look_up()]])
console.binds.add("PAGEDOWN", [[console.look_down()]])

console.binds.addedit("MOUSE2", [[world.editextend_intensity()]])
console.binds.addedit("P", [[world.centerent()]])

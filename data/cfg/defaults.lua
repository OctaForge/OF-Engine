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

console.binds.add("W", function() console.forward() end)
console.binds.add("S", function() console.backward() end)
console.binds.add("A", function() console.left() end)
console.binds.add("D", function() console.right() end)

console.binds.add("UP", function() console.forward() end)
console.binds.add("DOWN", function() console.backward() end)
console.binds.add("LEFT", function() console.left() end)
console.binds.add("RIGHT", function() console.right() end)

console.binds.add("SPACE", function() console.jump() end)

console.binds.add("TAB", function() gui.showscores() end)

console.binds.add("T", function() console.saycommand() end)
--console.binds.add("T", function() console.sayteamcommand() end)
console.binds.add("BACKQUOTE", function() console.saycommand("/") end)
console.binds.add("SLASH", function() console.saycommand("/") end)

console.binds.add("E", function() world.edittoggle() end)
console.binds.add("F1", function() world.edittoggle() end)

console.binds.add("KP_MINUS", function() console.skip(5) end)
console.binds.add("KP_PLUS", function() console.skip(-1000) end)

console.binds.addvar("PAUSE", "paused")

console.binds.add("F11", function() console.toggle() end)
console.binds.add("F12", function() engine.screenshot() end)

-- mouse

console.binds.add("MOUSE1", function() console.mouse1click() end)
console.binds.add("MOUSE2", function() console.mouse2click() end)
console.binds.add("MOUSE3", function() console.mouse3click() end)

-- universal scrollwheel + modifier commands:

console.binds.add("MOUSE4", function() universaldelta(1) end) -- also used for editing, see below
console.binds.add("MOUSE5", function() universaldelta(-1) end)

-- edit binds

console.binds.addedit("SPACE", function() world.cancelsel() end)
console.binds.addedit("MOUSE1", function() if blendpaintmode ~= 0 then texture.blendmap.paint() else world.editdrag() end end)
console.binds.addedit("MOUSE3", function() world.selcorners() end)
console.binds.addedit("MOUSE2", function() if blendpaintmode ~= 0 then texture.blendbrush.rotate() else world.editextend() end end)

console.binds.addedit("KP_ENTER", function() world.entselect([=[world.insel()]=]) end)
console.binds.addedit("N", function() world.selentfindall() end)

console.binds.addedit("LSHIFT", function() world.editcut() end)
console.binds.addmodedit("LCTRL", "passthrough")
console.binds.addmodedit("LALT", "hmapedit")
console.binds.addedit("DELETE", function() world.editdel() end)

console.binds.addedit("X", function() world.editflip() end)
console.binds.addedit("C", function() world.editcopy() end)
console.binds.addedit("V", function() world.editpaste() end)
console.binds.addedit("Z", function() world.undo(); passthroughsel = 0 end)
console.binds.addedit("U", function() world.undo(); passthroughsel = 0 end)
console.binds.addedit("I", function() world.redo() end)
console.binds.addedit("H", function() if hmapedit ~= 0 then world.editface(1, -1) else hmapedit = 1 end end)

console.binds.addvaredit("5", "hidehud")
console.binds.addvaredit("6", "entselsnap")
console.binds.addvaredit("7", "outline")
console.binds.addvaredit("8", "wireframe")
console.binds.addvar("9", "thirdperson")
console.binds.addvaredit("0", "allfaces")
console.binds.addedit("K", function() world.calclight() end)
console.binds.addvaredit("L", "fullbright")
console.binds.addvaredit("M", "showmat")

console.binds.addedit("PERIOD", function() world.selentedit() end)

console.binds.addedit("F9", function() echo("%(1)s : %(2)s" % { texture.getsel(), texture.getname(texture.getsel()) }) end)

console.binds.addedit("G", function() domodifier(1) end)
console.binds.addedit("F", function() domodifier(2) end)
console.binds.addedit("Q", function() domodifier(3) end)
console.binds.addedit("R", function() domodifier(4) end)
console.binds.addedit("Y", function() domodifier(6) end)
console.binds.addedit("B", function() domodifier(9) end)
console.binds.addedit("COMMA", function() domodifier(10); console.onrelease(function() world.entautoview() end) end)

console.binds.addedit("1", function() domodifier(11) end)
console.binds.addedit("2", function() domodifier(12) end)
console.binds.addedit("3", function() domodifier(13) end)
console.binds.addedit("4", function() domodifier(14) end)

console.binds.addedit("5", function() domodifier(15) end) -- vSlot: offset H
console.binds.addedit("6", function() domodifier(16) end) -- vSlot: offset V
console.binds.addedit("7", function() domodifier(17) end) -- vSlot: rotate
console.binds.addedit("8", function() domodifier(18) end) -- vSlot: scale

console.binds.addedit("LALT", function() multiplier = 10; console.onrelease(function() multiplier = 1 end) end)
console.binds.addedit("RALT", function() multiplier2 = 32; console.onrelease(function() multiplier2 = 16 end) end)

-- blendmap painting
console.binds.addedit("KP0", function() texture.setblendpaintmode(blendpaintmode ~= 0 and 0 or 1) end)
console.binds.addedit("KP1", function() if blendpaintmode ~= 0 then texture.setblendpaintmode(1) else console.left() end end)
console.binds.addedit("KP2", function() if blendpaintmode ~= 0 then texture.setblendpaintmode(2) else console.backward() end end)
console.binds.addedit("KP3", function() if blendpaintmode ~= 0 then texture.setblendpaintmode(3) else console.right() end end)
console.binds.addedit("KP4", function() if blendpaintmode ~= 0 then texture.setblendpaintmode(4) else console.turn_left() end end)
console.binds.addedit("KP5", function() texture.setblendpaintmode(5) end)
console.binds.addedit("KP6", function() console.turn_right() end)
console.binds.addedit("KP8", function() if blendpaintmode ~= 0 then texture.blendbrush.scroll(-1) else console.forward() end end)
console.binds.addedit("KP9", function() texture.blendbrush.scroll(1) end)

console.binds.add("M", function() camera.mouselook() end)
console.binds.addedit("M", function() camera.mouselook() end)
console.binds.addvaredit("0", "showmat")

console.binds.add("PAGEDOWN", function() console.look_up() end)
console.binds.add("PAGEDOWN", function() console.look_down() end)

console.binds.addedit("MOUSE2", function() world.editextend_intensity() end)
console.binds.addedit("P", function() world.centerent() end)

-- default settings for maps

-- on every map load, this file will be executed, followed by mapscript.

cc.model.reset()

if not skybox or skybox == "" then
    skybox = "textures/sky/remus/sky01"
end

cc.texture.resetmat()

cc.texture.add("water", "textures/core/water.png") -- water
cc.texture.add("1", "textures/core/water.png") -- waterfall
cc.texture.add("1", "textures/core/watern.png") -- water normalmap
cc.texture.add("1", "textures/core/waterd.png") -- water dudv
cc.texture.add("1", "textures/core/watern.png") -- waterfall normalmap
cc.texture.add("1", "textures/core/waterd.png") -- waterfall dudv

cc.texture.add("lava", "textures/core/lava.png",  0, 0, 0, 2) -- lava
cc.texture.add("1",    "textures/core/lava.png", 0, 0, 0, 2) -- falling lava

cc.texture.reset() -- let's start at texture slot 0

cc.shader.set("stdworld") -- default world shader

cc.texture.add("0", "textures/core/defsky.png") -- fallback sky
cc.texture.add("0", "textures/core/256.png") -- fallback geometry
cc.texture.add("0", "textures/core/256.png")
cc.texture.add("0", "textures/core/256.png")
cc.texture.add("0", "textures/core/256.png")
cc.texture.add("0", "textures/core/128.png")
cc.texture.add("0", "textures/core/64.png")
cc.texture.add("0", "textures/core/32.png")
cc.texture.add("0", "textures/core/16.png")
cc.texture.add("0", "textures/core/8.png")
cc.texture.add("0", "textures/core/256i.png")
cc.texture.add("0", "textures/core/128i.png")
cc.texture.add("0", "textures/core/64i.png")
cc.texture.add("0", "textures/core/32i.png")
cc.texture.add("0", "textures/core/16i.png")
cc.texture.add("0", "textures/core/8i.png")

cc.shader.set("stdworld")

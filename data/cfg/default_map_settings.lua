-- default settings for maps

-- on every map load, this file will be executed, followed by mapscript.

of.model.reset()

if not skybox or skybox == "" then
    skybox = "textures/sky/remus/sky01"
end

of.texture.resetmat()

of.texture.add("water", "textures/core/water.png") -- water
of.texture.add("1", "textures/core/water.png") -- waterfall
of.texture.add("1", "textures/core/watern.png") -- water normalmap
of.texture.add("1", "textures/core/waterd.png") -- water dudv
of.texture.add("1", "textures/core/watern.png") -- waterfall normalmap
of.texture.add("1", "textures/core/waterd.png") -- waterfall dudv

of.texture.add("lava", "textures/core/lava.png",  0, 0, 0, 2) -- lava
of.texture.add("1",    "textures/core/lava.png", 0, 0, 0, 2) -- falling lava

of.texture.reset() -- let's start at texture slot 0

of.shader.set("stdworld") -- default world shader

of.texture.add("0", "textures/core/defsky.png") -- fallback sky
of.texture.add("0", "textures/core/256.png") -- fallback geometry
of.texture.add("0", "textures/core/256.png")
of.texture.add("0", "textures/core/256.png")
of.texture.add("0", "textures/core/256.png")
of.texture.add("0", "textures/core/128.png")
of.texture.add("0", "textures/core/64.png")
of.texture.add("0", "textures/core/32.png")
of.texture.add("0", "textures/core/16.png")
of.texture.add("0", "textures/core/8.png")
of.texture.add("0", "textures/core/256i.png")
of.texture.add("0", "textures/core/128i.png")
of.texture.add("0", "textures/core/64i.png")
of.texture.add("0", "textures/core/32i.png")
of.texture.add("0", "textures/core/16i.png")
of.texture.add("0", "textures/core/8i.png")

of.shader.set("stdworld")

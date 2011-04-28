-- default settings for maps

-- on every map load, this file will be executed, followed by mapscript.

model.reset()

if not skybox or skybox == "" then
    skybox = "textures/sky/remus/sky01"
end

texture.resetmat()

texture.add("water", "textures/core/water.png") -- water
texture.add("1", "textures/core/water.png") -- waterfall
texture.add("1", "textures/core/watern.png") -- water normalmap
texture.add("1", "textures/core/waterd.png") -- water dudv
texture.add("1", "textures/core/watern.png") -- waterfall normalmap
texture.add("1", "textures/core/waterd.png") -- waterfall dudv

texture.add("lava", "textures/core/lava.png",  0, 0, 0, 2) -- lava
texture.add("1",    "textures/core/lava.png", 0, 0, 0, 2) -- falling lava

texture.reset() -- let's start at texture slot 0

shader.set("stdworld") -- default world shader

texture.add("0", "textures/core/defsky.png") -- fallback sky
texture.add("0", "textures/core/256.png") -- fallback geometry
texture.add("0", "textures/core/256.png")
texture.add("0", "textures/core/256.png")
texture.add("0", "textures/core/256.png")
texture.add("0", "textures/core/128.png")
texture.add("0", "textures/core/64.png")
texture.add("0", "textures/core/32.png")
texture.add("0", "textures/core/16.png")
texture.add("0", "textures/core/8.png")
texture.add("0", "textures/core/256i.png")
texture.add("0", "textures/core/128i.png")
texture.add("0", "textures/core/64i.png")
texture.add("0", "textures/core/32i.png")
texture.add("0", "textures/core/16i.png")
texture.add("0", "textures/core/8i.png")

shader.set("stdworld")

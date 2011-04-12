-- Heightmap brushes

cc.world.hmap.brush.new("Circle 1-0 Brush", 0, 0, { 1 })
cc.world.hmap.brush.new("Circle 2-1 Brush", 2, 2, {
    {},
    { 0,0,1 },
    { 0,1,2,1 },
    { 0,0,1 }
})
cc.world.hmap.brush.new("Circle 4-2-1 Brush", 2, 2, {
    { 0,0,1 },
    { 0,1,2,1 },
    { 1,2,4,2,1 },
    { 0,1,2,1 },
    { 0,0,1 }
})
cc.world.hmap.brush.new("Square 3x3 brush", 1, 1, {
    { 1,1,1 },
    { 1,1,1 },
    { 1,1,1 }
})
cc.world.hmap.brush.new("Square 5x5 brush", 2, 2, {
    { 1,1,1,1,1 },
    { 1,1,1,1,1 },
    { 1,1,1,1,1 },
    { 1,1,1,1,1 },
    { 1,1,1,1,1 }
})
cc.world.hmap.brush.new("Square 7x7 brush", 3, 3, {
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 }
})

cc.world.hmap.brush.new("Smooth 3x3 brush", 1, 1, {
    { 0,0,0 },
    { 0 },
    { 0 }
})
cc.world.hmap.brush.new("Smooth 5x5 brush", 2, 2, {
    { 0,0,0,0,0 },
    { 0 },
    { 0 },
    { 0 },
    { 0 }
})
cc.world.hmap.brush.new("Smooth 7x7 brush", 3, 3, {
    { 0,0,0,0,0,0,0 },
    { 0 },
    { 0 },
    { 0 },
    { 0 },
    { 0 },
    { 0 }
})

cc.world.hmap.brush.new("Noise 25x25 Brush", 12, 12, {
    { 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1 },
    {},
    { 0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,1,1,0,1 },
    { 0,0,0,0,0,1,0,0,0,1,0,0,0,0,1,0,1,0,0,1,0,0,2,2 },
    { 0,0,0,0,1,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,1 },
    { 0,0,0,0,0,1,0,0,0,0,0,2,0,0,0,0,1,0,0,0,1,1,0,0,1 },
    { 0,0,1,0,0,0,1,0,1,1,0,0,0,0,1,0,0,1,0,0,0,0,2 },
    { 0,0,0,1,0,1,1,0,0,0,0,0,0,0,0,0,0,1,1,1,2 },
    { 0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,1,1 },
    { 0,0,0,0,1,1,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,1 },
    { 0,1,0,2,0,1,1,1,1,0,0,1,0,0,0,0,1 },
    { 0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1,1 },
    { 1,0,1,0,0,0,0,0,1,0,0,0,1,0,1 },
    { 0,0,0,0,0,0,0,1,1,0,1,1,0,0,1,0,0,1,0,0,0,0,1,0,0,1 },
    { 0,1,1,1,0,3,0,2,0,0,0,1,1,0,0,0,1,1 },
    { 0,0,1,0,0,1,0,0,1,0,1,1,0,1,0,0,0,0,0,1 },
    { 0,0,1,1,0,0,0,0,2,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,1 },
    { 0,1,1,0,1,0,0,1,0,0,0,0,0,1,0,0,1,1,0,0,0,0,1 },
    { 1,0,0,0,0,0,1,0,0,1,0,0,1,0,0,0,0,0,0,0,1,0,0,1,0,1 },
    { 0,0,0,1,0,0,1,0,1,1,0,0,0,0,0,0,0,1 },
    { 0,0,0,0,0,0,1,1,1,0,1,1,1,0,0,0,0,0,0,0,0,0,0,1 },
    { 0,0,0,0,1,0,1,1,0,2,0,0,0,0,0,1,0,0,0,1,0,0,0,0,1 },
    { 0,0,0,0,0,0,0,0,0,1,0,1 },
    { 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1 }
})

cc.world.hmap.brush_2() -- 421

-- Texture blending

cc.blend.brush.add("Circle, 16px, soft", "data/textures/brushes/circle_16_soft.png")
cc.blend.brush.add("Circle, 16px, hard", "data/textures/brushes/circle_16_hard.png")
cc.blend.brush.add("Circle, 16px, solid", "data/textures/brushes/circle_16_solid.png")
cc.blend.brush.add("Circle, 32px, soft", "data/textures/brushes/circle_32_soft.png")
cc.blend.brush.add("Circle, 32px, hard", "data/textures/brushes/circle_32_hard.png")
cc.blend.brush.add("Circle, 32px, solid", "data/textures/brushes/circle_32_solid.png")
cc.blend.brush.add("Circle, 64px, soft", "data/textures/brushes/circle_64_soft.png")
cc.blend.brush.add("Circle, 64px, hard", "data/textures/brushes/circle_64_hard.png")
cc.blend.brush.add("Circle, 64px, solid", "data/textures/brushes/circle_64_solid.png")
cc.blend.brush.add("Circle, 128px, soft", "data/textures/brushes/circle_128_soft.png")
cc.blend.brush.add("Circle, 128px, hard", "data/textures/brushes/circle_128_hard.png")
cc.blend.brush.add("Circle, 128px, solid", "data/textures/brushes/circle_128_solid.png")
cc.blend.brush.add("Noise, 64px", "data/textures/brushes/noise_64.png")
cc.blend.brush.add("Noise, 128px", "data/textures/brushes/noise_128.png")
cc.blend.brush.add("Square, 16px, hard", "data/textures/brushes/square_16_hard.png")
cc.blend.brush.add("Square, 16px, solid", "data/textures/brushes/square_16_solid.png")
cc.blend.brush.add("Square, 32px, hard", "data/textures/brushes/square_32_hard.png")
cc.blend.brush.add("Square, 32px, solid", "data/textures/brushes/square_32_solid.png")
cc.blend.brush.add("Square, 64px, hard", "data/textures/brushes/square_64_hard.png")
cc.blend.brush.add("Square, 64px, solid", "data/textures/brushes/square_64_solid.png")
cc.blend.brush.add("Gradient, 16px", "data/textures/brushes/gradient_16.png")
cc.blend.brush.add("Gradient, 32px", "data/textures/brushes/gradient_32.png")
cc.blend.brush.add("Gradient, 64px", "data/textures/brushes/gradient_64.png")
cc.blend.brush.add("Gradient, 128px", "data/textures/brushes/gradient_128.png")

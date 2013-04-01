-- Heightmap brushes

edit.new_height_brush("Circle 1-0 Brush", 0, 0, { 1 })
edit.new_height_brush("Circle 2-1 Brush", 2, 2, {
    {},
    { 0,0,1 },
    { 0,1,2,1 },
    { 0,0,1 }
})
edit.new_height_brush("Circle 4-2-1 Brush", 2, 2, {
    { 0,0,1 },
    { 0,1,2,1 },
    { 1,2,4,2,1 },
    { 0,1,2,1 },
    { 0,0,1 }
})
edit.new_height_brush("Square 3x3 brush", 1, 1, {
    { 1,1,1 },
    { 1,1,1 },
    { 1,1,1 }
})
edit.new_height_brush("Square 5x5 brush", 2, 2, {
    { 1,1,1,1,1 },
    { 1,1,1,1,1 },
    { 1,1,1,1,1 },
    { 1,1,1,1,1 },
    { 1,1,1,1,1 }
})
edit.new_height_brush("Square 7x7 brush", 3, 3, {
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 },
    { 1,1,1,1,1,1,1 }
})

edit.new_height_brush("Smooth 3x3 brush", 1, 1, {
    { 0,0,0 },
    { 0 },
    { 0 }
})
edit.new_height_brush("Smooth 5x5 brush", 2, 2, {
    { 0,0,0,0,0 },
    { 0 },
    { 0 },
    { 0 },
    { 0 }
})
edit.new_height_brush("Smooth 7x7 brush", 3, 3, {
    { 0,0,0,0,0,0,0 },
    { 0 },
    { 0 },
    { 0 },
    { 0 },
    { 0 },
    { 0 }
})

edit.new_height_brush("Noise 25x25 Brush", 12, 12, {
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

edit.select_height_brush(3, true) -- 421

-- Texture blending
--[[
texture.add_blend_brush("Circle, 8px, soft", "data/textures/brushes/circle_8_soft.png")
texture.add_blend_brush("Circle, 8px, hard", "data/textures/brushes/circle_8_hard.png")
texture.add_blend_brush("Circle, 8px, solid", "data/textures/brushes/circle_8_solid.png")
texture.add_blend_brush("Circle, 16px, soft", "data/textures/brushes/circle_16_soft.png")
texture.add_blend_brush("Circle, 16px, hard", "data/textures/brushes/circle_16_hard.png")
texture.add_blend_brush("Circle, 16px, solid", "data/textures/brushes/circle_16_solid.png")
texture.add_blend_brush("Circle, 32px, soft", "data/textures/brushes/circle_32_soft.png")
texture.add_blend_brush("Circle, 32px, hard", "data/textures/brushes/circle_32_hard.png")
texture.add_blend_brush("Circle, 32px, solid", "data/textures/brushes/circle_32_solid.png")
texture.add_blend_brush("Circle, 64px, soft", "data/textures/brushes/circle_64_soft.png")
texture.add_blend_brush("Circle, 64px, hard", "data/textures/brushes/circle_64_hard.png")
texture.add_blend_brush("Circle, 64px, solid", "data/textures/brushes/circle_64_solid.png")
texture.add_blend_brush("Circle, 128px, soft", "data/textures/brushes/circle_128_soft.png")
texture.add_blend_brush("Circle, 128px, hard", "data/textures/brushes/circle_128_hard.png")
texture.add_blend_brush("Circle, 128px, solid", "data/textures/brushes/circle_128_solid.png")
texture.add_blend_brush("Noise, 64px", "data/textures/brushes/noise_64.png")
texture.add_blend_brush("Noise, 128px", "data/textures/brushes/noise_128.png")
texture.add_blend_brush("Square, 16px, hard", "data/textures/brushes/square_16_hard.png")
texture.add_blend_brush("Square, 16px, solid", "data/textures/brushes/square_16_solid.png")
texture.add_blend_brush("Square, 32px, hard", "data/textures/brushes/square_32_hard.png")
texture.add_blend_brush("Square, 32px, solid", "data/textures/brushes/square_32_solid.png")
texture.add_blend_brush("Square, 64px, hard", "data/textures/brushes/square_64_hard.png")
texture.add_blend_brush("Square, 64px, solid", "data/textures/brushes/square_64_solid.png")
texture.add_blend_brush("Gradient, 16px", "data/textures/brushes/gradient_16.png")
texture.add_blend_brush("Gradient, 32px", "data/textures/brushes/gradient_32.png")
texture.add_blend_brush("Gradient, 64px", "data/textures/brushes/gradient_64.png")
texture.add_blend_brush("Gradient, 128px", "data/textures/brushes/gradient_128.png")]]

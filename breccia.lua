local S = summer.S

--_____ Breccia _____--
minetest.register_node("summer:breccia", {
	description = S("Gray Rubble"),
	tiles = {"breccia.png"},
	groups = {crumbly = 2, falling_node = 1},
    --groups = {cracky = 3, stone = 1},
	drop = '"summer:pietra" 9',
	--legacy_mineral = true,
	is_ground_content = true, --
    sounds = default.node_sound_gravel_defaults(),
	--sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("summer:breccia_2", {
	description = S("White Rubble "),
	tiles = {"breccia2.png"},
	groups = {crumbly = 2, falling_node = 1},
    --groups = {cracky = 3, stone = 1},
	drop = '"summer:pietraA" 9',
	--legacy_mineral = true,
    sounds = default.node_sound_gravel_defaults(),
	--sounds = default.node_sound_stone_defaults(),
})

    minetest.register_node("summer:desert_breccia_2", {
	description = S("Corten Rubble"),
	tiles = {"desert_breccia2.png"},
	groups = {crumbly = 2, falling_node = 1},
    --groups = {cracky = 3, stone = 1},
	drop = '"summer:desert_pietra" 9',
	--legacy_mineral = true,
    sounds = default.node_sound_gravel_defaults(),
	--sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("summer:desert_breccia", {
	description = S("Pink Rubble"),
	tiles = {"desert_breccia.png"},
	groups = {crumbly = 2, falling_node = 1},
    --groups = {cracky = 3, stone = 1},
	drop = '"summer:pietraP" 9',
	--legacy_mineral = true,
    sounds = default.node_sound_gravel_defaults(),
	--sounds = default.node_sound_stone_defaults(),
})


minetest.register_node("summer:brecciaC", {
	description = S("Cyan Rubble"),
	tiles = {"brecciaC.png"},
	groups = {crumbly = 2, falling_node = 1},
    --groups = {cracky = 3, stone = 1},
	drop = '"summer:pietraC" 9',
	--legacy_mineral = true,
	is_ground_content = true, --
    sounds = default.node_sound_gravel_defaults(),
	--sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("summer:brecciaB", {
	description = S("black Rubble"),
	tiles = {"brecciaB.png"},
	groups = {crumbly = 2, falling_node = 1},
    --groups = {cracky = 3, stone = 1},
	drop = '"summer:pietraB" 9',
	--legacy_mineral = true,
	is_ground_content = true, --
    sounds = default.node_sound_gravel_defaults(),
	--sounds = default.node_sound_stone_defaults(),
})

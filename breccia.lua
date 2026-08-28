local S = summer.S

--_____ Breccia _____--
minetest.register_node("summer:breccia", {
	description = S("Breccia"),
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
	description = S("Breccia B"),
	tiles = {"breccia2.png"},
	groups = {crumbly = 2, falling_node = 1},
    --groups = {cracky = 3, stone = 1},
	drop = '"summer:pietraA" 9',
	--legacy_mineral = true,
    sounds = default.node_sound_gravel_defaults(),
	--sounds = default.node_sound_stone_defaults(),
})
    minetest.register_node("summer:desert_breccia_2", {
	description = S("Red Breccia"),
	tiles = {"desert_breccia2.png"},
	groups = {crumbly = 2, falling_node = 1},
    --groups = {cracky = 3, stone = 1},
	drop = '"summer:desert_pietra" 9',
	--legacy_mineral = true,
    sounds = default.node_sound_gravel_defaults(),
	--sounds = default.node_sound_stone_defaults(),
})
minetest.register_node("summer:desert_breccia", {
	description = S("Desert Breccia"),
	tiles = {"desert_breccia.png"},
	groups = {crumbly = 2, falling_node = 1},
    --groups = {cracky = 3, stone = 1},
	drop = '"summer:pietraP" 9',
	--legacy_mineral = true,
    sounds = default.node_sound_gravel_defaults(),
	--sounds = default.node_sound_stone_defaults(),
})


minetest.register_node("summer:brecciaC", {
	description = S("Cyan Breccia"),
	tiles = {"brecciaC.png"},
	groups = {crumbly = 2, falling_node = 1},
    --groups = {cracky = 3, stone = 1},
	drop = '"summer:pietraC" 9',
	--legacy_mineral = true,
	is_ground_content = true, --
    sounds = default.node_sound_gravel_defaults(),
	--sounds = default.node_sound_stone_defaults(),
})

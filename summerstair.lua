local S = summer.S

--_____ Compact granite registration _____--

local graniti = {

	A = {
		texture = "graniteA.png",
		mattone = "summer:mattoneA",
		nome = S("Ivory"),
	},

	P = {
		texture = "graniteP.png",
		mattone = "summer:mattoneP",
		nome = S("Pink"),
	},

	R = {
		texture = "graniteR.png",
		mattone = "summer:mattoneR",
		nome = S("Red"),
	},

	G = {
		texture = "graniteG.png",
		mattone = "summer:mattoneG",
		nome = S("Grey"),
	},

	C = {
		texture = "graniteC.png",
		mattone = "summer:mattoneC",
		nome = S("Cyan"),
	},

	B = {
		texture = "graniteB.png",
		mattone = "summer:mattoneB",
		nome = S("Black"),
	},
}


--_____ Textures _____--

local function get_tiles(texture)

	return {
		texture,
		texture,
		texture,
		texture,
		texture,
		texture
	}

end


--_____ Create granite blocks _____--

local function crea_granito(lettera, dati)

	local suffix = lettera == "G" and "" or lettera

	local angstair   = "summer:angstair"    .. suffix
	local angstair2  = "summer:angstair2"   .. suffix
	local stair      = "summer:stair"       .. suffix
	local battiscopa = "summer:battiscopa"  .. suffix
	local slab       = "summer:slab"        .. suffix

	local mattone = dati.mattone
	local texture = dati.texture
	local nome = dati.nome


	--_____ Stair corner _____--

	minetest.register_node(angstair, {

		description = S("Granite Corner Stair") .. " " .. nome,

		tiles = get_tiles(texture),

		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",

		node_box = {
			type = "fixed",

			fixed = {

				{-0.5, -0.5, -0.5, 0, 0.5, 0.5},

				{-0.5, -0.5, 0, 0.5, 0.5, 0.5},

				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},

			}
		},

		groups = {
			cracky = 3,
			stone = 1
		},

		sounds = default.node_sound_stone_defaults(),

	})


	minetest.register_craft({

		output = angstair,

		recipe = {

			{mattone, mattone, ""},

			{mattone, mattone, ""},

			{mattone, mattone, mattone},

		}

	})


	--_____ Stair edge _____--

	minetest.register_node(angstair2, {

		description = S("Granite Stair Corner") .. " " .. nome,

		tiles = get_tiles(texture),

		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",

		node_box = {
			type = "fixed",

			fixed = {

				{-0.5, -0.5, 0, 0, 0.5, 0.5},

				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},

			}
		},

		groups = {
			cracky = 3,
			stone = 1
		},

		sounds = default.node_sound_stone_defaults(),

	})


	minetest.register_craft({

		output = angstair2,

		recipe = {

			{"", mattone, ""},

			{"", mattone, ""},

			{mattone, mattone, mattone},

		}

	})


	--_____ Stairs _____--

	minetest.register_node(stair, {

		description = S("Granite Stair") .. " " .. nome,

		tiles = get_tiles(texture),

		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",

		node_box = {
			type = "fixed",

			fixed = {

				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},

				{-0.5, -0.5, 0, 0.5, 0.5, 0.5},

			}
		},

		groups = {
			cracky = 3,
			stone = 1
		},

		sounds = default.node_sound_stone_defaults(),

	})


	minetest.register_craft({

		output = stair,

		recipe = {

			{mattone, "", ""},

			{mattone, mattone, ""},

			{mattone, mattone, mattone},

		}

	})


	--_____ Baseboard _____--

	minetest.register_node(battiscopa, {

		description = S("Granite Baseboard") .. " " .. nome,

		tiles = get_tiles(texture),

		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",

		node_box = {
			type = "fixed",

			fixed = {

				{-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},

				{-0.5, -0.5, -0.375, 0.5, 0.25, 0.5},

				{-0.5, 0, -0.5, 0.5, 0.5, 0.5},

			}
		},

		groups = {
			cracky = 3,
			stone = 1
		},

		sounds = default.node_sound_stone_defaults(),

	})


	minetest.register_craft({

		output = battiscopa,

		recipe = {

			{mattone, mattone, mattone},

			{mattone, mattone, ""},

			{mattone, mattone, mattone},

		}

	})


	--_____ Slabs _____--

	minetest.register_node(slab, {

		description = S("Granite Stair") .. " " .. nome,

		tiles = get_tiles(texture),

		drawtype = "nodebox",
		paramtype = "light",
		paramtype2 = "facedir",

		node_box = {
			type = "fixed",

			fixed = {

				{-0.5, -0.5, -0.5, 0.5, 0, 0.5},

			}
		},

		groups = {
			cracky = 3,
			stone = 1
		},

		sounds = default.node_sound_stone_defaults(),

	})


	minetest.register_craft({

		output = slab,

		recipe = {

			{"", "", ""},

			{"", "", ""},

			{mattone, mattone, mattone},

		}

	})

end


--_____ Generate all granite variants _____--

for lettera, dati in pairs(graniti) do

	crea_granito(lettera, dati)

end

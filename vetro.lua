local S = summer.S

--_____ Compact glass registration _____--
--_____ Withe changed to White. Fuxia unchanged. _____--
--_____ Added summer:mattoneC. _____--

local vetro_list = {
	{ S("Red Glass"), "red"},
	{ S("Orange Glass"), "orange"},
	{ S("Black Glass"), "black"},
	{ S("Yellow Glass"), "yellow"},
	{ S("Green Glass"), "green"},
	{ S("Dark Green Glass"), "dark_green"},
	{ S("Cyan Glass"), "cyan"},
	{ S("Grey Glass"), "grey"},
	{ S("White Glass"), "white"},
	{ S("Fuxia Glass"), "magenta"},
	{ S("Transparent Glass"), "trasp"},
	{ S("Blue Glass"), "blue"},
	{ S("Violet Glass"), "violet"},
}

--_____ Base glass item: registered once _____--
minetest.register_craftitem("summer:vetro_traspp", {
	description = S("Glass Pane"),
	inventory_image = "vetro_traspp.png",
})

--_____ Brick cooking recipes _____--
local mattone_list = {
	"summer:mattoneG",
	"summer:mattoneA",
	"summer:mattoneR",
	"summer:mattoneP",
	"summer:mattoneC",
}

for _, mattone in ipairs(mattone_list) do
	minetest.register_craft({
		type = "cooking",
		cooktime = 10,
		output = "summer:vetro_traspp",
		recipe = mattone,
	})
end

local function crea_vetri(vetrodesc, colour)

	minetest.register_node("summer:vetro_" .. colour, {
		description = vetrodesc .. " " .. S("transparent framed"),
		tiles = {"vetro_" .. colour .. ".png"},
		sunlight_propagates = true,
		drawtype = "glasslike",
		paramtype = "light",
		paramtype2 = "glasslikeliquidlevel",
		groups = {snappy=2, cracky=3, oddly_breakable_by_hand=3, not_in_creative_inventory=0},
		drop = "summer:vetro_" .. colour,
		sounds = default.node_sound_glass_defaults(),
	})

	minetest.register_node("summer:vetro_unito_" .. colour, {
		description = vetrodesc .. " " .. S("transparent framed connected"),
		tiles = {"vetro_" .. colour .. ".png", "vetro_trasp.png"},
		sunlight_propagates = true,
		drawtype = "glasslike_framed",
		use_texture_alpha = true,
		paramtype = "light",
		paramtype2 = "glasslikeliquidlevel",
		groups = {snappy=2, cracky=3, oddly_breakable_by_hand=3, not_in_creative_inventory=0},
		drop = "summer:vetro_unito_" .. colour,
		sounds = default.node_sound_glass_defaults(),
	})

	minetest.register_node("summer:vetro_colorato_" .. colour, {
		description = vetrodesc .. " " .. S("colored frame"),
		tiles = {"vetro_traspc_" .. colour .. ".png"},
		sunlight_propagates = true,
		drawtype = "glasslike",
		use_texture_alpha = true,
		paramtype = "light",
		paramtype2 = "glasslikeliquidlevel",
		groups = {snappy=2, cracky=3, oddly_breakable_by_hand=3, not_in_creative_inventory=0},
		drop = "summer:vetro_colorato_" .. colour,
		sounds = default.node_sound_glass_defaults(),
	})

	minetest.register_node("summer:vetro_colorato_unito_" .. colour, {
		description = vetrodesc .. " " .. S("connected colored"),
		tiles = {"vetro_traspc_" .. colour .. ".png", "vetro_trasp_" .. colour .. ".png"},
		sunlight_propagates = true,
		drawtype = "glasslike_framed",
		use_texture_alpha = true,
		paramtype = "light",
		paramtype2 = "glasslikeliquidlevel",
		groups = {snappy=2, cracky=3, oddly_breakable_by_hand=3, not_in_creative_inventory=0},
		drop = "summer:vetro_colorato_unito_" .. colour,
		sounds = default.node_sound_glass_defaults(),
	})

	minetest.register_node("summer:vetro_colorato_uni_" .. colour, {
		description = vetrodesc .. " " .. S("uniform colored"),
		tiles = {"vetro_trasp_" .. colour .. ".png"},
		sunlight_propagates = true,
		drawtype = "glasslike",
		use_texture_alpha = true,
		paramtype = "light",
		paramtype2 = "glasslikeliquidlevel",
		groups = {snappy=2, cracky=3, oddly_breakable_by_hand=3, not_in_creative_inventory=0},
		drop = "summer:vetro_colorato_uni_" .. colour,
		sounds = default.node_sound_glass_defaults(),
	})

	--_____ Frameless glass _____--
	minetest.register_craft({
		output = "summer:vetro_colorato_uni_" .. colour,
		recipe = {
			{"", "dye:" .. colour, ""},
			{"", "summer:vetro_traspp", ""},
			{"", "", ""},
		}
	})

	--_____ Framed transparent glass _____--
	minetest.register_craft({
		output = "summer:vetro_" .. colour,
		recipe = {
			{"default:stick", "dye:" .. colour, "default:stick"},
			{"default:stick", "summer:vetro_traspp", "default:stick"},
			{"default:stick", "default:stick", "default:stick"},
		}
	})

	--_____ Joined framed transparent glass _____--
	minetest.register_craft({
		output = "summer:vetro_unito_" .. colour,
		recipe = {
			{"", "dye:" .. colour, ""},
			{"", "summer:vetro_traspp", ""},
			{"default:stick", "default:stick", "default:stick"},
		}
	})

	--_____ Colored framed glass _____--
	minetest.register_craft({
		output = "summer:vetro_colorato_" .. colour,
		recipe = {
			{"default:stick", "dye:" .. colour, "default:stick"},
			{"default:stick", "summer:vetro_" .. colour, "default:stick"},
			{"default:stick", "default:stick", "default:stick"},
		}
	})

	--_____ Joined colored framed glass _____--
	minetest.register_craft({
		output = "summer:vetro_colorato_unito_" .. colour,
		recipe = {
			{"", "dye:" .. colour, ""},
			{"", "summer:vetro_" .. colour, ""},
			{"default:stick", "default:stick", "default:stick"},
		}
	})
end

--_____ Special transparent glass _____--
minetest.register_craft({
	output = "summer:vetro_colorato_trasp",
	recipe = {
		{"default:stick", "default:stick", "default:stick"},
		{"default:stick", "summer:vetro_traspp", "default:stick"},
		{"default:stick", "default:stick", "default:stick"},
	}
})

minetest.register_craft({
	output = "summer:vetro_colorato_unito_trasp",
	recipe = {
		{"", "", ""},
		{"", "summer:vetro_traspp", ""},
		{"default:stick", "default:stick", "default:stick"},
	}
})

minetest.register_craft({
	output = "summer:vetro_unito_trasp",
	recipe = {
		{"default:stick", "", ""},
		{"default:stick", "summer:vetro_traspp", ""},
		{"default:stick", "", ""},
	}
})

minetest.register_craft({
	output = "summer:vetro_colorato_uni_trasp",
	recipe = {
		{"", "", ""},
		{"summer:vetro_traspp", "summer:vetro_traspp", ""},
		{"summer:vetro_traspp", "summer:vetro_traspp", ""},
	}
})

minetest.register_craft({
	output = "summer:vetro_trasp",
	recipe = {
		{"default:stick", "default:stick", "default:stick"},
		{"default:stick", "summer:vetro_traspp", "default:stick"},
		{"default:stick", "", "default:stick"},
	}
})

for _, vetro in ipairs(vetro_list) do
	crea_vetri(vetro[1], vetro[2])
end


local S = summer.S

if not minetest.get_modpath("wool") 
or not minetest.get_modpath("flowers")
or not minetest.get_modpath("dye") then
	return
end



-- Helper functions


local function register_craft(output, recipe)
	minetest.register_craft({
		output = output,
		recipe = recipe,
	})
end

local function full_recipe(item)
	return {
		{item, item, item},
		{item, item, item},
		{item, item, item},
	}
end

local function register_full_craft(output, count, item)
	register_craft(output .. " " .. count, full_recipe(item))
end

--Scivolo
register_craft("summer:scivolo_slope 10", {
	{"group:wood", "default:steel_ingot", "group:wood"},
	{"group:wood", "default:steel_ingot", "group:wood"},
	{"group:wood", "default:steel_ingot", "group:wood"},
})
register_craft("summer:scivolo 5", {
	{"group:wood", "default:steel_ingot", "group:wood"},
	{"group:wood", "flowers:mushroom_red", "group:wood"},
	{"group:wood", "group:wool", "group:wood"},
})
register_craft("summer:scivolo_top", {
	{"default:stick", "default:steel_ingot", "default:stick"},
	{"default:stick", "default:stick", "default:stick"},
	{"default:stick", "default:gold_ingot", "default:stick"},
})

-- Rake


register_craft("summer:rake", {
	{"default:stick", "default:steel_ingot", "default:stick"},
	{"", "default:stick", ""},
	{"", "default:gold_ingot", ""},
})



-- Breccia


register_full_craft(
	"summer:breccia",
	4,
	"summer:pietra"
)

register_full_craft(
	"summer:brecciaC",
	4,
	"summer:pietraC"
)

register_full_craft(
	"summer:desert_breccia_2",
	4,
	"summer:desert_pietra"
)

register_full_craft(
	"summer:breccia_2",
	4,
	"summer:pietraA"
)

register_full_craft(
	"summer:desert_breccia",
	4,
	"summer:pietraP"
)



-- Granite


register_craft("summer:graniteBC 5", {
	{"", "", ""},
	{"summer:pietraA", "", ""},
	{"summer:graniteB", "", ""},
})

register_craft("summer:graniteB 5", {
	{"", "", ""},
	{"summer:graniteP", "summer:graniteA", ""},
	{"summer:graniteR", "summer:graniteG", ""},
})

register_full_craft(
	"summer:graniteR",
	5,
	"summer:mattoneR"
)

register_full_craft(
	"summer:graniteC",
	5,
	"summer:mattoneC"
)

register_full_craft(
	"summer:graniteA",
	5,
	"summer:mattoneA"
)

register_full_craft(
	"summer:graniteG",
	5,
	"summer:mattoneG"
)

register_full_craft(
	"summer:graniteP",
	5,
	"summer:mattoneP"
)



-- Coloured items


local colours = {
	"red",
	"orange",
	"black",
	"yellow",
	"green",
	"blue",
	"violet",
	"white",
}


for _, colour in ipairs(colours) do

	local wool = "wool:" .. colour
	local dye = "dye:" .. colour


	
	-- Deck chair
	

	register_craft("summer:sdraia_" .. colour, {
		{"default:stick", wool, ""},
		{"default:paper", "default:paper", "default:paper"},
		{"default:stick", "", "default:stick"},
	})


	
	-- Ashtray
	

	register_craft("summer:Portacenere_" .. colour, {
		{"group:wood", "", "group:wood"},
		{"default:stick", "default:paper", "default:stick"},
		{"default:paper", wool, "default:paper"},
	})



	

	register_craft("summer:porta_" .. colour, {
		{"group:wood", wool, ""},
		{wool, "group:wood", ""},
		{"group:wood", "group:wood", ""},
	})


	
	-- Goggles
	

	register_craft("summer:occhiali_" .. colour, {
		{"", wool, ""},
		{"default:stick", "", "default:stick"},
		{"default:glass", "default:stick", "default:glass"},
	})


	
	-- Towel
	

	register_craft("summer:asciugamano_" .. colour, {
		{"", "", ""},
		{wool, "", ""},
		{
			"default:ladder_wood",
			"default:ladder_wood",
			"default:ladder_wood"
		},
	})


	
	-- Beach umbrella
	

	register_craft("summer:ombrellone_" .. colour, {
		{"default:paper", wool, "default:paper"},
		{"", "default:stick", ""},
		{"", "default:stick", ""},
	})

	register_craft("summer:ombrellone_n_" .. colour, {
		{"", wool, ""},
		{"default:paper", "default:stick", "default:paper"},
		{"", "default:stick", ""},
	})


	
	-- Chest
	

	local chest = "summer:chest" .. colour

	register_craft(chest, {
		{"default:stone", dye, "default:stone"},
		{"group:wood", "", "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
	})

	register_craft("summer:chest_lock" .. colour, {
		{chest, "default:diamond", ""},
	})

end

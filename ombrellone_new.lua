local S = summer.S

local Ombrellone_n_list = {
	{ S("Red Umbrella N"), "red"},
	{ S("Orange Umbrella N"), "orange"},
    { S("Black Umbrella N"), "black"},
	{ S("Yellow Umbrella N"), "yellow"},
	{ S("Green Umbrella N"), "green"},
	{ S("Blue Umbrella N"), "blue"},
	{ S("Violet Umbrella N"), "violet"},
	{ S("White Umbrella N"), "white"},
}

for i in ipairs(Ombrellone_n_list) do
	local Ombrellone_ndesc = Ombrellone_n_list[i][1]
	local colour = Ombrellone_n_list[i][2]

   minetest.register_node("summer:ombrellone_n_"..colour.."", {
	    description = Ombrellone_ndesc.."",
	    drawtype = "mesh",
		mesh = "omb_n_o.obj",
	    tiles = {"Ombrellone_n_"..colour..".png"},

        inventory_image = "ombo_"..colour.."_r.png",

        wield_image  = "ombo_"..colour.."_r.png" ,
	    paramtype = "light",
	    paramtype2 = "facedir",
	    sunlight_propagates = true,
	    walkable = false,
	    selection_box = {
	        type = "fixed",
	        fixed = { -0.25, -0.5, -0.25, 0.25,0.5, 0.25 },
	    },
		groups = {snappy=2,cracky=3,oddly_breakable_by_hand=3,not_in_creative_inventory = 0},
		--sounds = default.node_sound_glass_defaults(),
        drop = "summer:ombrellone_n_"..colour.."_ch",
		on_rightclick = function(pos, node, clicker)
	        node.name = "summer:Ombrellone_n_"..colour.."_ch"
	        minetest.set_node(pos, node)
	    end,
	})


minetest.register_node("summer:ombrellone_n_"..colour.."_ch", {
	    description = Ombrellone_ndesc .. " " .. S("closed"),
	    drawtype = "mesh",
		mesh = "omb_n_c.obj",
	    tiles = {"Ombrellone_n_"..colour..".png"},

       inventory_image = "ombc_"..colour.."_r.png",

        wield_image  = "ombc_"..colour.."_r.png",
	    paramtype = "light",
	    paramtype2 = "facedir",
	    sunlight_propagates = true,
	    walkable = false,
	    selection_box = {
	        type = "fixed",
	        fixed = { -0.25, -0.5, -0.25, 0.25,0.5, 0.25 },
	    },
		groups = {snappy=2,cracky=3,oddly_breakable_by_hand=3, not_in_creative_inventory=0},
		--sounds = default.node_sound_glass_defaults(),
		drop = "summer:ombrellone_n_"..colour,
		on_rightclick = function(pos, node, clicker)
	        node.name = "summer:Ombrellone_n_"..colour..""
	        minetest.set_node(pos, node)
	    end,
	})
end


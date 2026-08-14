local S = summer.S

local Occhiali_list = {
	{ S("Red Goggles"), "red"},
	{ S("Orange Goggles"), "orange"},
    { S("Black Goggles"), "black"},
	{ S("Yellow Goggles"), "yellow"},
	{ S("Green Goggles"), "green"},
	{ S("Blue Goggles"), "blue"},
    { S("Jam Goggles"), "jam"},
	{ S("Violet Goggles"), "violet"},
}

for i in ipairs(Occhiali_list) do
	local Occhialidesc = Occhiali_list[i][1]
	local colour = Occhiali_list[i][2]
minetest.register_alias("occhiali"..colour.."","summer:occhiali"..colour.."")
if minetest.get_modpath("summer") then
	local stats = {
		Occhialidesc = { name=Occhialidesc, armor=1.8, heal=0, use=650 },

	}
	--[[local mats = {
		fibra="cannabis:fibra_ingot",
		tessuto="cannabis:tessuto_ingot",
		foglie="cannabis:foglie_ingot",
		high="cannabis:high_performance_ingot",
	}]]
	for k, v in pairs(stats) do
		minetest.register_tool("summer:occhiali_"..colour.."", {
			description = Occhialidesc,
            tiles= "occhiali_"..colour..".png",
			inventory_image = "occhiali_"..colour.."_inv.png",
			groups = {armor_head=math.floor(5*v.armor), armor_heal=v.heal, armor_use=v.use},
			wear = 0,
		})

end
end


end

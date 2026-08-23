local S = summer.S

if minetest.get_modpath("wool") and minetest.get_modpath("dye") then

--_____ Rake _____--
minetest.register_craft({
    output = "summer:rake",
    recipe = {
        {"default:stick", "default:steel_ingot", "default:stick"},
        {"", "default:stick", ""},
        {"", "default:gold_ingot", ""}
    }
})

--_____ Breccia _____--
minetest.register_craft({
    output = "summer:breccia 4",
    recipe = {
        {"summer:pietra", "summer:pietra", "summer:pietra"},
        {"summer:pietra", "summer:pietra", "summer:pietra"},
        {"summer:pietra", "summer:pietra", "summer:pietra"},
    },
})

minetest.register_craft({
    output = "summer:brecciaC 4",
    recipe = {
        {"summer:pietraC", "summer:pietraC", "summer:pietraC"},
        {"summer:pietraC", "summer:pietraC", "summer:pietraC"},
        {"summer:pietraC", "summer:pietraC", "summer:pietraC"},
    },
})

minetest.register_craft({
    output = "summer:desert_breccia_2 4",
    recipe = {
        {"summer:desert_pietra", "summer:desert_pietra", "summer:desert_pietra"},
        {"summer:desert_pietra", "summer:desert_pietra", "summer:desert_pietra"},
        {"summer:desert_pietra", "summer:desert_pietra", "summer:desert_pietra"},
    },
})

minetest.register_craft({
    output = "summer:breccia_2 4",
    recipe = {
        {"summer:pietraA", "summer:pietraA", "summer:pietraA"},
        {"summer:pietraA", "summer:pietraA", "summer:pietraA"},
        {"summer:pietraA", "summer:pietraA", "summer:pietraA"},
    },
})

minetest.register_craft({
    output = "summer:desert_breccia 4",
    recipe = {
        {"summer:pietraP", "summer:pietraP", "summer:pietraP"},
        {"summer:pietraP", "summer:pietraP", "summer:pietraP"},
        {"summer:pietraP", "summer:pietraP", "summer:pietraP"},
    },
})

--_____ Granite _____--
minetest.register_craft({
    output = "summer:graniteBC 5",
    recipe = {
        {"", "", ""},
        {"summer:pietraA", "", ""},
        {"summer:graniteB", "", ""},
    },
})

minetest.register_craft({
    output = "summer:graniteB 5",
    recipe = {
        {"", "", ""},
        {"summer:graniteP", "summer:graniteA", ""},
        {"summer:graniteR", "summer:graniteG", ""},
    },
})

minetest.register_craft({
    output = "summer:graniteR 5",
    recipe = {
        {"summer:mattoneR", "summer:mattoneR", "summer:mattoneR"},
        {"summer:mattoneR", "summer:mattoneR", "summer:mattoneR"},
        {"summer:mattoneR", "summer:mattoneR", "summer:mattoneR"},
    },
})

minetest.register_craft({
    output = "summer:graniteC 5",
    recipe = {
        {"summer:mattoneC", "summer:mattoneC", "summer:mattoneC"},
        {"summer:mattoneC", "summer:mattoneC", "summer:mattoneC"},
        {"summer:mattoneC", "summer:mattoneC", "summer:mattoneC"},
    },
})

minetest.register_craft({
    output = "summer:graniteA 5",
    recipe = {
        {"summer:mattoneA", "summer:mattoneA", "summer:mattoneA"},
        {"summer:mattoneA", "summer:mattoneA", "summer:mattoneA"},
        {"summer:mattoneA", "summer:mattoneA", "summer:mattoneA"},
    },
})

minetest.register_craft({
    output = "summer:graniteG 5",
    recipe = {
        {"summer:mattoneG", "summer:mattoneG", "summer:mattoneG"},
        {"summer:mattoneG", "summer:mattoneG", "summer:mattoneG"},
        {"summer:mattoneG", "summer:mattoneG", "summer:mattoneG"},
    },
})

minetest.register_craft({
    output = "summer:graniteP 5",
    recipe = {
        {"summer:mattoneP", "summer:mattoneP", "summer:mattoneP"},
        {"summer:mattoneP", "summer:mattoneP", "summer:mattoneP"},
        {"summer:mattoneP", "summer:mattoneP", "summer:mattoneP"},
    },
})

local lchest_list = {
    {S("Red Chest"), "red"},
    {S("Orange Chest"), "orange"},
    {S("Black Chest"), "black"},
    {S("Yellow Chest"), "yellow"},
    {S("Green Chest"), "green"},
    {S("Blue Chest"), "blue"},
    {S("Violet Chest"), "violet"},
    {S("White Chest"), "white"}
}

for i in ipairs(lchest_list) do
    local desc = lchest_list[i][1]
    local colour = lchest_list[i][2]

    --_____ Deck chair _____--
    minetest.register_craft({
        output = "summer:sdraia_" .. colour,
        recipe = {
            {"default:stick", "wool:" .. colour, ""},
            {"default:paper", "default:paper", "default:paper"},
            {"default:stick", "", "default:stick"}
        }
    })

    --_____ Ashtray _____--
    minetest.register_craft({
        output = "summer:Portacenere_" .. colour,
        recipe = {
            {"group:wood", "", "group:wood"},
            {"default:stick", "default:paper", "default:stick"},
            {"default:paper", "wool:" .. colour, "default:paper"}
        }
    })

    --_____ Door _____--
    minetest.register_craft({
        output = "summer:porta_" .. colour .. "_ch",
        recipe = {
            {"group:wood", "wool:" .. colour, ""},
            {"wool:" .. colour, "group:wood", ""},
            {"group:wood", "group:wood", ""}
        }
    })

    --_____ Goggles _____--
    minetest.register_craft({
        output = "summer:occhiali_" .. colour,
        recipe = {
            {"", "wool:" .. colour, ""},
            {"default:stick", "", "default:stick"},
            {"default:glass", "default:stick", "default:glass"}
        }
    })

    --_____ Towel _____--
    minetest.register_craft({
        output = "summer:asciugamano_" .. colour,
        recipe = {
            {"", "", ""},
            {"wool:" .. colour, "", ""},
            {"default:ladder_wood", "default:ladder_wood", "default:ladder_wood"}
        }
    })

    --_____ Beach umbrella _____--
    minetest.register_craft({
        output = "summer:ombrellone_" .. colour,
        recipe = {
            {"default:paper", "wool:" .. colour, "default:paper"},
            {"", "default:stick", ""},
            {"", "default:stick", ""}
        }
    })

    minetest.register_craft({
        output = "summer:ombrellone_n_" .. colour,
        recipe = {
            {"", "wool:" .. colour, ""},
            {"default:paper", "default:stick", "default:paper"},
            {"", "default:stick", ""}
        }
    })

    --_____ Chest _____--
    minetest.register_craft({
        output = "summer:chest" .. colour,
        recipe = {
            {"default:stone", "dye:" .. colour, "default:stone"},
            {"group:wood", "", "group:wood"},
            {"group:wood", "group:wood", "group:wood"}
        }
    })

    minetest.register_craft({
        output = "summer:chest_lock" .. colour,
        recipe = {
            {"summer:chest" .. colour, "default:diamond", ""}
        }
    })
end

end

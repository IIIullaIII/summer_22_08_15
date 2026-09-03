local S = summer.S

if minetest.get_modpath("wool") and minetest.get_modpath("dye") then
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
        
     

        -- ____barca____----
        minetest.register_craft({
            -- CORRETTO: Usata la variabile "color" del ciclo for
            output = "summer:barca2_" .. colour .. "_item",
            recipe = {
                {"", "", ""},
                { "cannabis:canapa_plastic", "wool:" .. colour, "cannabis:canapa_plastic" },
                { "cannabis:canapa_plastic", "cannabis:canapa_plastic", "cannabis:canapa_plastic" },
            },
        })
   


	--_____ materassino _____--

		minetest.register_craft({
			output ="summer:materassino_" .. colour .. "_item",
			recipe = {
				{"", "", ""},
				{"cannabis:canapa_plastic", "wool:"..colour, ""},
				{"cannabis:canapa_plastic", "cannabis:canapa_plastic", "cannabis:canapa_plastic"},
			},
		})
	



--____ salvagente______--

		minetest.register_craft({
			output ="summer:salvag_" .. colour .. "_item",
			recipe = {
				{"", "cannabis:canapa_plastic", ""},
				{"cannabis:canapa_plastic", "wool:" .. colour, "cannabis:canapa_plastic"},
				{"", "cannabis:canapa_plastic", ""},
			},
		})


--_____ Deck chair _____--
minetest.register_craft({
		output = "summer:sdraia_"..colour.."",
		recipe = {
			{"", "wool:"..colour, "", },
			{"cannabis:canapa_fiber", "cannabis:canapa_plastic", "cannabis:canapa_fiber", },
			{"", "cannabis:canapa_fiber", "", }
		}
	})

--_____ Ashtray _____--

		minetest.register_craft({
		output = "summer:Portacenere_"..colour.."",
		recipe = {
			{"cannabis:canapa_fiber", "", "cannabis:canapa_fiber" },
			{"cannabis:canapa_plastic", "", "cannabis:canapa_plastic" },
			{"cannabis:canapa_plastic", "wool:"..colour, "cannabis:canapa_plastic" }
		}
	})
--_____ Goggles _____--
minetest.register_craft({
		output = "summer:occhiali_"..colour.."",
		recipe = {
			{"", "wool:"..colour, "", },
			{"", "cannabis:canapa_fiber", "", },
			{"cannabis:canapa_plastic", "", "cannabis:canapa_plastic", }
		}
	})
--_____ Door _____--
	minetest.register_craft({
		output = "summer:porta_"..colour.."_ch",
		recipe = {
			{"cannabis:canapa_fiber", "wool:"..colour, "", },
			{"wool:"..colour, "cannabis:canapa_fiber", "", },
			{"cannabis:canapa_fiber", "cannabis:canapa_fiber", "", }
		}
	})


--_____ Towel _____--

minetest.register_craft({
		output = "summer:asciugamano_"..colour.."",
		recipe = {
			{"","","", },
			{"wool:"..colour, "", "", },
			{"cannabis:canapa_fiber", "cannabis:canapa_fiber", "cannabis:canapa_fiber", }
		}
	})


--_____ Beach umbrella _____--
	minetest.register_craft({
		output = "summer:ombrellone_"..colour.."",
		recipe = {
			{"", "wool:"..colour, "", },
			{"", "cannabis:canapa_plastic", "", },
			{"", "cannabis:canapa_fiber", "", }
		}
	})


	minetest.register_craft({
		output = "summer:ombrellone_n_"..colour.."",
		recipe = {
			{"cannabis:canapa_fiber", "wool:"..colour, "cannabis:canapa_fiber" },
			{"", "cannabis:canapa_plastic", "" },
			{"", "cannabis:canapa_plastic", "" }
		}
	})


--_____ Chest _____--
minetest.register_craft({
		output = "summer:modern_chest_"..colour.."",
		recipe = {
		{"cannabis:canapa_plastic","dye:"..colour.."","cannabis:canapa_plastic"},
		{"group:wood","","group:wood"},
		{"group:wood","group:wood","group:wood"}

		}
	})


	minetest.register_craft({
		output = "summer:locked_chest_"..colour.."",
		recipe = {
		{"summer:chest"..colour.."","cannabis:high_performance_ingot",""}
		--{"","",""},
		--{"","",""}

		}
	})
	minetest.register_craft({
		output = "summer:protected_chest_"..colour.."",
		recipe = {
		{"summer:chest"..colour.."","cannabis:fibra_ingot",""}
		--{"","",""},
		--{"","",""}

		}
	})

end


end

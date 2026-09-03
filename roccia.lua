
local S = summer.S
--_____ Rock _____--
minetest.register_alias("desert_roccia_1","desert_roccia")
minetest.register_alias("roccia_1","roccia")

minetest.register_node("summer:roccia_1", {
    description = S("Grey Rock"),
    drawtype = "mesh",
    mesh = "roccia.obj",
	tiles = {"roccia.png"},
    paramtype = "light",
	    paramtype2 = "facedir",
	    sunlight_propagates = true,
	    walkable = true,
	groups = {cracky = 3, stone = 1},
	drop = '"summer:pietra" 5',
     selection_box = {
	        type = "fixed",
	        fixed = { -0.5, -0.5,-0.5, 0.5,0.1, 0.5 },
	    },
        	 on_place = function(itemstack, placer, pointed_thing)
		--_____ Place a random rock fragment node _____--
		local stack = ItemStack("summer:roccia_"..math.random(1,2))
		local ret = minetest.item_place(stack, placer, pointed_thing)
		return ItemStack("summer:roccia_1 "..itemstack:get_count()-(1-ret:get_count()))
	end,--legacy_mineral = true,
	sounds = default.node_sound_stone_defaults(),

})

minetest.register_node("summer:desert_roccia_1", {
    description = S("Desert Rock"),
    drawtype = "mesh",
    mesh = "roccia.obj",
	tiles = {"desert_roccia.png"},
    paramtype = "light",
	    paramtype2 = "facedir",
	    sunlight_propagates = true,
	    walkable = true,
	groups = {cracky = 3, stone = 1},
	drop = '"summer:desert_pietra" 5',
     selection_box = {
	        type = "fixed",
	        fixed = { -0.5, -0.5,-0.5, 0.5,0.1, 0.5 },
	    },
         on_place = function(itemstack, placer, pointed_thing)
		--_____ Place a random rock fragment node _____--
		local stack = ItemStack("summer:desert_roccia_"..math.random(1,2))
		local ret = minetest.item_place(stack, placer, pointed_thing)
		return ItemStack("summer:desert_roccia_1  "..itemstack:get_count()-(1-ret:get_count()))
	end,
	--legacy_mineral = true,
	sounds = default.node_sound_stone_defaults(),

})
minetest.register_node("summer:roccia_2", {
    description = S("Grey Rock"),
    drawtype = "mesh",
    mesh = "roccia.obj",
	tiles = {"roccia.png"},
    paramtype = "light",
	    paramtype2 = "facedir",
	    sunlight_propagates = true,
	    walkable = true,
	groups = {cracky=3, stone=1, not_in_creative_inventory=1},
	drop = '"summer:pietra" 5',
     selection_box = {
	        type = "fixed",
	        fixed = { -0.5, -0.5,-0.5, 0.5,0.1, 0.5 },
	    },
        	--legacy_mineral = true,
	sounds = default.node_sound_stone_defaults(),

})

minetest.register_node("summer:desert_roccia_2", {
    description = S("Desert Rock"),
    drawtype = "mesh",
    mesh = "roccia.obj",
	tiles = {"desert_roccia.png"},
    paramtype = "light",
	    paramtype2 = "facedir",
	    sunlight_propagates = true,
	    walkable = true,
	groups = {cracky=3, stone=1, not_in_creative_inventory=1},
	drop = '"summer:desert_pietra" 5',
     selection_box = {
	        type = "fixed",
	        fixed = { -0.5, -0.5,-0.5, 0.5,0.1, 0.5 },
	    },
	--legacy_mineral = true,
	sounds = default.node_sound_stone_defaults(),

})
--_____ Mapgen _____--
minetest.register_on_generated(function(minp, maxp, seed)
	if maxp.y >= 2 and minp.y <= 0 then
		--_____ Generate rocks _____--
		local perlin1 = minetest.get_perlin(329, 3, 0.6, 100)
		--_____ Assume X and Z lengths are equal _____--
		local divlen = 32
		local divs = (maxp.x-minp.x)/divlen+1;
		for divx=0,divs-1 do
		for divz=0,divs-1 do
			local x0 = minp.x + math.floor((divx+0)*divlen)
			local z0 = minp.z + math.floor((divz+0)*divlen)
			local x1 = minp.x + math.floor((divx+1)*divlen)
			local z1 = minp.z + math.floor((divz+1)*divlen)
			--_____ Determine rock amount from Perlin noise _____--
			local roccia_amount = math.floor(perlin1:get2d({x=x0, y=z0}) ^ 2 * 2)
			--_____ Find random rock positions _____--
			local pr = PseudoRandom(seed+1)
			for i=0,roccia_amount do
				local x = pr:next(x0, x1)
				local z = pr:next(z0, z1)
				--_____ Find ground level (0...15) _____--
				local ground_y = nil
				for y=30,0,-1 do
					if minetest.get_node({x=x,y=y,z=z}).name ~= "air" then
						ground_y = y
						break
					end
				end

				if ground_y then
					local p = {x=x,y=ground_y+1,z=z}
					local nn = minetest.get_node(p).name
					--_____ Check if the node can be replaced _____--
					if minetest.registered_nodes[nn] and
						minetest.registered_nodes[nn].buildable_to then
						nn = minetest.get_node({x=x,y=ground_y,z=z}).name
						--_____ If desert sand, add dry shrub _____--
						if nn == "default:dirt_with_grass" then
							minetest.set_node(p,{name="summer:roccia_"..pr:next(1,2), param2=math.random(0,3)})
						elseif nn == "default:desert_sand" then
							minetest.set_node(p,{name="summer:desert_roccia_"..pr:next(1,2), param2=math.random(0,3)})
					    end
					end
				end

			end
		end
		end
	end
end)


summer_fur = {}

-- If true, you can sit on chairs and benches, when right-click them.
summer_fur.enable_layng = minetest.settings:get_bool("summer_fur.enable_layng", true)
summer_fur.globalstep = minetest.settings:get_bool("summer_fur.globalstep", true)


-- Used for localization
local S = minetest.get_translator("summer_fur")
local has_player_monoids = minetest.get_modpath("player_monoids")

-- Get texture by node name
local T = function (node_name)
	local def = minetest.registered_nodes[node_name]
	if not (def and def.tiles) then
		return ""
	end
	local tile = def.tiles[5] or def.tiles[4] or def.tiles[3] or def.tiles[2] or def.tiles[1]
	if type(tile) == "string" then
		return tile
	elseif type(tile) == "table" and tile.name then
		return tile.name
	end
	return ""
end

-- The following code is from "Get Comfortable [cozy]" (by everamzah; published under WTFPL)
-- Thomas S. modified it, so that it can be used in this mod
if summer_fur.enable_layng then
	summer_fur.lay = function(pos, _, player)
		local name = player:get_player_name()
		if not player_api.player_attached[name] then
			if vector.length(player:get_velocity()) > 0.5 then
				minetest.chat_send_player(player:get_player_name(), 'Stop first.')
				return
			end
			player:move_to(pos)
			player:set_eye_offset({x = 0, y = 0.5, z = 2}, {x = 0, y = 0.2, z = 0})
			if has_player_monoids then
				player_monoids.speed:add_change(player, 0, "summer_fur:lay")
				player_monoids.jump:add_change(player, 0, "summer_fur:lay")
				player_monoids.gravity:add_change(player, 0, "summer_fur:lay")
			else
				player:set_physics_override({speed = 0, jump = 0, gravity = 0})
			end
			player_api.player_attached[name] = true
			minetest.after(0.1, function()
				if player then
					player_api.set_animation(player, "lay" , 30)
				end
			end)
		else
			summer_fur.stand(player, name)
		end
	end

	summer_fur.st = function(_, _, player)
		local name = player:get_player_name()
		if player_api.player_attached[name] then
			summer_fur.stand(player, name)
		end
	end

	summer_fur.stand = function(player, name)
		player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
		if has_player_monoids then
			player_monoids.speed:del_change(player, "summer_fur:lay")
			player_monoids.jump:del_change(player, "summer_fur:lay")
			player_monoids.gravity:del_change(player, "summer_fur:lay")
		else
			player:set_physics_override({speed = 1, jump = 1, gravity = 1})
		end
		player_api.player_attached[name] = false
		player_api.set_animation(player, "stand", 30)
	end

	-- The player will stand at the beginning of the movement
	if summer_fur.globalstep  then
		minetest.register_globalstep(function(dtime)
			local players = minetest.get_connected_players()
			for i = 1, #players do
				local player = players[i]
				local name = player:get_player_name()
				local ctrl = player:get_player_control()
				if default.player_attached[name] and not player:get_attach() and
				(ctrl.up or ctrl.down or ctrl.left or ctrl.right or ctrl.jump) then
					summer_fur.st(nil, nil, player)
				end
			end
		end)
	end
end
    
    local Asciugamano_list = {
	{ "Red Asciugamano", "red"},
	{ "Orange Asciugamano", "orange"},
    { "Black Asciugamano", "black"},
	{ "Yellow Asciugamano", "yellow"},
	{ "Green Asciugamano", "green"},
	{ "Blue Asciugamano", "blue"},
	{ "Violet Asciugamano", "violet"},
}

for i in ipairs(Asciugamano_list) do
	local asciugamanodesc = Asciugamano_list[i][1]
	local colour = Asciugamano_list[i][2]
 


    
   minetest.register_node("summer:asciugamano_"..colour.."", {
	    description = asciugamanodesc.."",
	    drawtype = "mesh",
		mesh = "asciugamano.obj",
	    tiles = {"asciugsmano_"..colour..".png"},	    
        inventory_image = "asciugsmano_a_"..colour..".png",
	    
        wield_image  = "asciugsmano_a_"..colour..".png",
	    
	    paramtype = "light",
	    paramtype2 = "facedir",
	    sunlight_propagates = true,
	    walkable = false,
	    selection_box = {
	        type = "fixed",
	        fixed = { -1.0, -0.5,-0.5, 1.0,-0.49, 0.5 },
	    },
		groups = {snappy=2,cracky=3,oddly_breakable_by_hand=3,not_in_creative_inventory=0},
		--sounds = default.node_sound_wood_defaults(),
        drop = "summer:asciugamano_"..colour.."",        
		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
				return summer_fur.lay( pos, node, clicker, itemstack, pointed_thing );
				end ,
		on_punch =	function(pos, node, clicker, itemstack, pointed_thing)
				return summer_fur.st( pos, node, clicker, itemstack, pointed_thing );
			end
        
 
   })
   



	
	
end
    --state=true: lay, state=false: stand up
    

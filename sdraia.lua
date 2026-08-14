summer_sdr = {}

summer_sdr.enable_layng = minetest.settings:get_bool("summer_sdr.enable_layng", true)
summer_sdr.globalstep = minetest.settings:get_bool("summer_sdr.globalstep", true)

local S = summer.S
local has_player_monoids = minetest.get_modpath("player_monoids")

local T = function(node_name)
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

if summer_sdr.enable_layng then

	summer_sdr.lay = function(pos, _, player)

		local name = player:get_player_name()

		if not player_api.player_attached[name] then

			if vector.length(player:get_velocity()) > 0.5 then
				minetest.chat_send_player(
					name,
					"Stop first."
				)
				return
			end

			local lay_pos = vector.copy(pos)
			lay_pos.y = lay_pos.y + 0.15

			player:move_to(lay_pos)

			player:set_eye_offset(
				{x = 0, y = 0.5, z = 2},
				{x = 0, y = 3, z = 0}
			)

			if has_player_monoids then

				player_monoids.speed:add_change(
					player,
					0,
					"summer_sdr:lay"
				)

				player_monoids.jump:add_change(
					player,
					0,
					"summer_sdr:lay"
				)

				player_monoids.gravity:add_change(
					player,
					0,
					"summer_sdr:lay"
				)

			else

				player:set_physics_override({
					speed = 0,
					jump = 0,
					gravity = 0
				})

			end

			player_api.player_attached[name] = true

			minetest.after(0.1, function()

				if player then
					player_api.set_animation(
						player,
						"lay",
						30
					)
				end

			end)

		else

			summer_sdr.stand(player, name)

		end
	end


	summer_sdr.st = function(_, _, player)

		local name = player:get_player_name()

		if player_api.player_attached[name] then
			summer_sdr.stand(player, name)
		end
	end


	summer_sdr.stand = function(player, name)

		player:set_eye_offset(
			{x = 0, y = 0, z = 0},
			{x = 0, y = 0, z = 0}
		)

		if has_player_monoids then

			player_monoids.speed:del_change(
				player,
				"summer_sdr:lay"
			)

			player_monoids.jump:del_change(
				player,
				"summer_sdr:lay"
			)

			player_monoids.gravity:del_change(
				player,
				"summer_sdr:lay"
			)

		else

			player:set_physics_override({
				speed = 1,
				jump = 1,
				gravity = 1
			})

		end

		player_api.player_attached[name] = false

		player_api.set_animation(
			player,
			"stand",
			30
		)
	end


	if summer_sdr.globalstep then

		minetest.register_globalstep(function(dtime)

			local players = minetest.get_connected_players()

			for i = 1, #players do

				local player = players[i]
				local name = player:get_player_name()
				local ctrl = player:get_player_control()

				if default.player_attached[name]
				and not player:get_attach()
				and (
					ctrl.up
					or ctrl.down
					or ctrl.left
					or ctrl.right
					or ctrl.jump
				) then

					summer_sdr.st(
						nil,
						nil,
						player
					)

				end
			end
		end)
	end
end


local sdraia_list = {
	{S("Red Sun Lounger"), "red"},
	{S("Orange Sun Lounger"), "orange"},
	{S("Black Sun Lounger"), "black"},
	{S("Yellow Sun Lounger"), "yellow"},
	{S("Green Sun Lounger"), "green"},
	{S("Blue Sun Lounger"), "blue"},
	{S("Violet Sun Lounger"), "violet"},
}


for i in ipairs(sdraia_list) do

	local sdraiadesc = sdraia_list[i][1]
	local colour = sdraia_list[i][2]

	minetest.register_node(
		"summer:sdraia_" .. colour,
		{

			description = sdraiadesc,

			drawtype = "mesh",

			mesh = "sdraia.obj",

			tiles = {
				"sdraia_" .. colour .. ".png"
			},

			inventory_image =
				"sdraia_" .. colour .. "_inv.png",

			wield_image =
				"sdraia_" .. colour .. ".png",

			paramtype = "light",

			paramtype2 = "facedir",

			sunlight_propagates = true,

			walkable = true,

walkable = true,

collision_box = {
	type = "fixed",
	fixed = {
		0.4,
		0.05,
		1.0,
		-0.4,
		-0.49,
		-1.0
	},
},

selection_box = {
	type = "fixed",
	fixed = {
		0.4,
		0.20,
		1.0,
		-0.4,
		-0.49,
		-1.0
	},
},
			groups = {
				snappy = 2,
				cracky = 3,
				oddly_breakable_by_hand = 3,
				not_in_creative_inventory = 0
			},

			drop =
				"summer:sdraia_" .. colour,

			on_rightclick = function(
				pos,
				node,
				clicker,
				itemstack,
				pointed_thing
			)

				return summer_sdr.lay(
					pos,
					node,
					clicker,
					itemstack,
					pointed_thing
				)

			end,

			on_punch = function(
				pos,
				node,
				clicker,
				itemstack,
				pointed_thing
			)

				return summer_sdr.st(
					pos,
					node,
					clicker,
					itemstack,
					pointed_thing
				)

			end
		}
	)
end

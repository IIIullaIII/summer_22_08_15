local S = summer.S

local Porta_list = {
	{ S("Red Door"), "red" },
	{ S("Orange Door"), "orange" },
	{ S("Black Door"), "black" },
	{ S("Yellow Door"), "yellow" },
	{ S("Green Door"), "green" },
	{ S("Blue Door"), "blue" },
	{ S("Violet Door"), "violet" },
}

for _, porta in ipairs(Porta_list) do

	local portadesc = porta[1]
	local colour = porta[2]

	local porta_ch = "summer:porta_" .. colour
	local porta_op = "summer:porta_" .. colour .. "_op"

	local porta_dx_ch = "summer:porta_" .. colour .. "_dx"
	local porta_dx_op = "summer:porta_" .. colour .. "_dx_op"


	--_____ Owner _____--

	local function is_owner(pos, player)

		if not player then
			return false
		end

		local owner = minetest.get_meta(pos):get_string("owner")

		if owner == "" then
			return true
		end

		return owner == player:get_player_name()
	end


	local function save_owner(pos, player)

		if player then
			minetest.get_meta(pos):set_string(
				"owner",
				player:get_player_name()
			)
		end
	end


	--_____ Single door closed _____--

	minetest.register_node(porta_ch, {

		description = portadesc,

		drawtype = "mesh",

		mesh = "portaop_sx.obj",

		tiles = {
			"porta_" .. colour .. ".png"
		},

		inventory_image = "summer_p_" .. colour .. ".png",
		wield_image = "summer_p_" .. colour .. ".png",

		paramtype = "light",
		paramtype2 = "facedir",

		sunlight_propagates = true,
		walkable = true,

		selection_box = {
			type = "fixed",
			fixed = {
				-0.5, -0.5, 0.40,
				 0.5,  1.5, 0.50
			},
		},

		collision_box = {
			type = "fixed",
			fixed = {
				-0.5, -0.5, 0.40,
				 0.5,  1.5, 0.50
			},
		},

		groups = {
			snappy = 2,
			cracky = 3,
			oddly_breakable_by_hand = 3,
		},

		sounds = default.node_sound_wood_defaults(),

		drop = porta_ch,


		--_____ Manual opening _____--

		on_rightclick = function(pos, node, clicker)

			if not is_owner(pos, clicker) then
				return
			end

			local owner =
				minetest.get_meta(pos):get_string("owner")

			node.name = porta_op

			minetest.set_node(pos, node)

			minetest.get_meta(pos):set_string(
				"owner",
				owner
			)

			minetest.sound_play("summer_porta_op", {
				pos = pos,
				gain = 2.0
			}, true)
		end,


		--_____ Mesecons _____--

		mesecons = {
			effector = {

				action_on = function(pos, node)

					local owner =
						minetest.get_meta(pos):get_string("owner")

					node.name = porta_op

					minetest.set_node(pos, node)

					minetest.get_meta(pos):set_string(
						"owner",
						owner
					)

					minetest.sound_play("summer_porta_op", {
						pos = pos,
						gain = 2.0
					}, true)
				end,

				action_off = function(pos, node)
				end,
			},
		},
	})


	--_____ Single door open _____--

	minetest.register_node(porta_op, {

		description = portadesc,

		drawtype = "mesh",

		mesh = "portach_sx.obj",

		tiles = {
			"porta_" .. colour .. ".png"
		},

		inventory_image = "summer_p_" .. colour .. ".png",
		wield_image = "summer_p_" .. colour .. ".png",

		paramtype = "light",
		paramtype2 = "facedir",

		sunlight_propagates = true,
		walkable = true,

		selection_box = {
			type = "fixed",
			fixed = {
				-0.40, -0.5, -0.5,
				-0.50,  1.5,  0.5
			},
		},

		collision_box = {
			type = "fixed",
			fixed = {
				-0.40, -0.5, -0.5,
				-0.50,  1.5,  0.5
			},
		},

		groups = {
			snappy = 2,
			cracky = 3,
			oddly_breakable_by_hand = 3,
			not_in_creative_inventory = 1,
		},

		sounds = default.node_sound_wood_defaults(),

		drop = porta_ch,


		--_____ Manual closing _____--

		on_rightclick = function(pos, node, clicker)

			if not is_owner(pos, clicker) then
				return
			end

			local owner =
				minetest.get_meta(pos):get_string("owner")

			node.name = porta_ch

			minetest.set_node(pos, node)

			minetest.get_meta(pos):set_string(
				"owner",
				owner
			)

			minetest.sound_play("summer_porta_ch", {
				pos = pos,
				gain = 2.0
			}, true)
		end,


		--_____ Mesecons _____--

		mesecons = {
			effector = {

				action_on = function(pos, node)
				end,

				action_off = function(pos, node)

					local owner =
						minetest.get_meta(pos):get_string("owner")

					node.name = porta_ch

					minetest.set_node(pos, node)

					minetest.get_meta(pos):set_string(
						"owner",
						owner
					)

					minetest.sound_play("summer_porta_ch", {
						pos = pos,
						gain = 2.0
					}, true)
				end,
			},
		},
	})


	--_____ Right door closed _____--
	--_____ Correct model: _____--
	--_____ portaop_dx.obj _____--

	minetest.register_node(porta_dx_ch, {

		description = portadesc,

		drawtype = "mesh",

		mesh = "portaop_dx.obj",

		tiles = {
			"porta_" .. colour .. ".png"
		},

		inventory_image = "summer_p_" .. colour .. ".png",
		wield_image = "summer_p_" .. colour .. ".png",

		paramtype = "light",
		paramtype2 = "facedir",

		sunlight_propagates = true,
		walkable = true,

		selection_box = {
			type = "fixed",
			fixed = {
				-0.5, -0.5, 0.40,
				 0.5,  1.5, 0.50
			},
		},

		collision_box = {
			type = "fixed",
			fixed = {
				-0.5, -0.5, 0.40,
				 0.5,  1.5, 0.50
			},
		},

		groups = {
			snappy = 2,
			cracky = 3,
			oddly_breakable_by_hand = 3,
			not_in_creative_inventory = 1,
		},

		sounds = default.node_sound_wood_defaults(),

		drop = porta_ch,


		--_____ Manual opening _____--

		on_rightclick = function(pos, node, clicker)

			if not is_owner(pos, clicker) then
				return
			end

			local owner =
				minetest.get_meta(pos):get_string("owner")

			node.name = porta_dx_op

			minetest.set_node(pos, node)

			minetest.get_meta(pos):set_string(
				"owner",
				owner
			)

			minetest.sound_play("summer_porta_op", {
				pos = pos,
				gain = 2.0
			}, true)
		end,


		--_____ Mesecons _____--

		mesecons = {
			effector = {

				action_on = function(pos, node)

					local owner =
						minetest.get_meta(pos):get_string("owner")

					node.name = porta_dx_op

					minetest.set_node(pos, node)

					minetest.get_meta(pos):set_string(
						"owner",
						owner
					)

					minetest.sound_play("summer_porta_op", {
						pos = pos,
						gain = 2.0
					}, true)
				end,

				action_off = function(pos, node)
				end,
			},
		},
	})


	--_____ Right door open _____--
	--_____ Correct model: _____--
	--_____ portach_dx.obj _____--

	minetest.register_node(porta_dx_op, {

		description = portadesc,

		drawtype = "mesh",

		mesh = "portach_dx.obj",

		tiles = {
			"porta_" .. colour .. ".png"
		},

		inventory_image = "summer_p_" .. colour .. ".png",
		wield_image = "summer_p_" .. colour .. ".png",

		paramtype = "light",
		paramtype2 = "facedir",

		sunlight_propagates = true,
		walkable = true,

		selection_box = {
			type = "fixed",
			fixed = {
				0.40, -0.5, -0.5,
				0.50,  1.5,  0.5
			},
		},

		collision_box = {
			type = "fixed",
			fixed = {
				0.40, -0.5, -0.5,
				0.50,  1.5,  0.5
			},
		},

		groups = {
			snappy = 2,
			cracky = 3,
			oddly_breakable_by_hand = 3,
			not_in_creative_inventory = 1,
		},

		sounds = default.node_sound_wood_defaults(),

		drop = porta_ch,


		--_____ Manual closing _____--

		on_rightclick = function(pos, node, clicker)

			if not is_owner(pos, clicker) then
				return
			end

			local owner =
				minetest.get_meta(pos):get_string("owner")

			node.name = porta_dx_ch

			minetest.set_node(pos, node)

			minetest.get_meta(pos):set_string(
				"owner",
				owner
			)

			minetest.sound_play("summer_porta_ch", {
				pos = pos,
				gain = 2.0
			}, true)
		end,


		--_____ Mesecons _____--

		mesecons = {
			effector = {

				action_on = function(pos, node)
				end,

				action_off = function(pos, node)

					local owner =
						minetest.get_meta(pos):get_string("owner")

					node.name = porta_dx_ch

					minetest.set_node(pos, node)

					minetest.get_meta(pos):set_string(
						"owner",
						owner
					)

					minetest.sound_play("summer_porta_ch", {
						pos = pos,
						gain = 2.0
					}, true)
				end,
			},
		},
	})


	--_____ Placement _____--

	minetest.override_item(porta_ch, {

		on_place = function(itemstack, placer, pointed_thing)

			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local pos = pointed_thing.above

			if not pos then
				return itemstack
			end


			--_____ Player direction _____--

			local yaw = placer:get_look_horizontal()

			local right = {
				x = math.cos(yaw),
				y = 0,
				z = math.sin(yaw)
			}


			--_____ Door to the left of the new position _____--

			local check_pos = {
				x = math.floor(pos.x - right.x + 0.5),
				y = pos.y,
				z = math.floor(pos.z - right.z + 0.5)
			}

			local vicino = minetest.get_node(check_pos)

			local usa_destra = false

			if vicino.name == porta_ch
				or vicino.name == porta_op then

				usa_destra = true
			end


			--_____ Orientation _____--

			local facedir =
				minetest.dir_to_facedir(
					placer:get_look_dir()
				)


			--_____ Position check _____--

			local old_node =
				minetest.get_node(pos)

			local old_def =
				minetest.registered_nodes[old_node.name]

			if not old_def then
				return itemstack
			end

			if not old_def.buildable_to then
				return itemstack
			end


			--_____ Placement _____--

			if usa_destra then

				minetest.set_node(pos, {
					name = porta_dx_ch,
					param2 = facedir,
				})

			else

				minetest.set_node(pos, {
					name = porta_ch,
					param2 = facedir,
				})

			end


			--_____ Owner _____--

			save_owner(pos, placer)


			--_____ Sound _____--

			minetest.sound_play(
				"default_place_node_hard",
				{
					pos = pos,
					gain = 1.0
				},
				true
			)


			--_____ Consumption _____--

			if not minetest.is_creative_enabled(
				placer:get_player_name()
			) then

				itemstack:take_item()

			end

			return itemstack
		end,
	})

end


--[[local S = summer.S

local Porta_list = {
	{ S("Red Door"), "red" },
	{ S("Orange Door"), "orange" },
	{ S("Black Door"), "black" },
	{ S("Yellow Door"), "yellow" },
	{ S("Green Door"), "green" },
	{ S("Blue Door"), "blue" },
	{ S("Violet Door"), "violet" },
}

for _, porta in ipairs(Porta_list) do

	local portadesc = porta[1]
	local colour = porta[2]

	local porta_ch = "summer:porta_" .. colour
	local porta_op = "summer:porta_" .. colour .. "_op"

	local porta_dx_ch = "summer:porta_" .. colour .. "_dx"
	local porta_dx_op = "summer:porta_" .. colour .. "_dx_op"


	--_____ Single door closed _____--

	minetest.register_node(porta_ch, {

		description = portadesc,

		drawtype = "mesh",

		mesh = "portaop_sx.obj",

		tiles = {
			"porta_" .. colour .. ".png"
		},

		inventory_image = "summer_p_" .. colour .. ".png",
		wield_image = "summer_p_" .. colour .. ".png",

		paramtype = "light",
		paramtype2 = "facedir",

		sunlight_propagates = true,
		walkable = true,

		selection_box = {
			type = "fixed",
			fixed = {
				-0.5, -0.5, 0.40,
				 0.5,  1.5, 0.50
			},
		},

		collision_box = {
			type = "fixed",
			fixed = {
				-0.5, -0.5, 0.40,
				 0.5,  1.5, 0.50
			},
		},

		groups = {
			snappy = 2,
			cracky = 3,
			oddly_breakable_by_hand = 3,
		},

		sounds = default.node_sound_wood_defaults(),

		drop = porta_ch,

		on_rightclick = function(pos, node)

			node.name = porta_op

			minetest.set_node(pos, node)

			minetest.sound_play("summer_porta_op", {
				pos = pos,
				gain = 2.0
			}, true)
		end,
	})


	--_____ Single door open _____--

	minetest.register_node(porta_op, {

		description = portadesc,

		drawtype = "mesh",

		mesh = "portach_sx.obj",

		tiles = {
			"porta_" .. colour .. ".png"
		},

		inventory_image = "summer_p_" .. colour .. ".png",
		wield_image = "summer_p_" .. colour .. ".png",

		paramtype = "light",
		paramtype2 = "facedir",

		sunlight_propagates = true,
		walkable = true,

		selection_box = {
			type = "fixed",
			fixed = {
				-0.40, -0.5, -0.5,
				-0.50,  1.5,  0.5
			},
		},

		collision_box = {
			type = "fixed",
			fixed = {
				-0.40, -0.5, -0.5,
				-0.50,  1.5,  0.5
			},
		},

		groups = {
			snappy = 2,
			cracky = 3,
			oddly_breakable_by_hand = 3,
			not_in_creative_inventory = 1,
		},

		sounds = default.node_sound_wood_defaults(),

		drop = porta_ch,

		on_rightclick = function(pos, node)

			node.name = porta_ch

			minetest.set_node(pos, node)

			minetest.sound_play("summer_porta_ch", {
				pos = pos,
				gain = 2.0
			}, true)
		end,
	})


	--_____ Right door closed _____--

	minetest.register_node(porta_dx_ch, {

		description = portadesc,

		drawtype = "mesh",

		mesh = "portaop_dx.obj",

		tiles = {
			"porta_" .. colour .. ".png"
		},

		inventory_image = "summer_p_" .. colour .. ".png",
		wield_image = "summer_p_" .. colour .. ".png",

		paramtype = "light",
		paramtype2 = "facedir",

		sunlight_propagates = true,
		walkable = true,

		selection_box = {
			type = "fixed",
			fixed = {
				-0.5, -0.5, 0.40,
				 0.5,  1.5, 0.50
			},
		},

		collision_box = {
			type = "fixed",
			fixed = {
				-0.5, -0.5, 0.40,
				 0.5,  1.5, 0.50
			},
		},

		groups = {
			snappy = 2,
			cracky = 3,
			oddly_breakable_by_hand = 3,
			not_in_creative_inventory = 1,
		},

		sounds = default.node_sound_wood_defaults(),

		drop = porta_ch,

		on_rightclick = function(pos, node)

			node.name = porta_dx_op

			minetest.set_node(pos, node)

			minetest.sound_play("summer_porta_op", {
				pos = pos,
				gain = 2.0
			}, true)
		end,
	})


	--_____ Right door open _____--

	minetest.register_node(porta_dx_op, {

		description = portadesc,

		drawtype = "mesh",

		mesh = "portach_dx.obj",

		tiles = {
			"porta_" .. colour .. ".png"
		},

		inventory_image = "summer_p_" .. colour .. ".png",
		wield_image = "summer_p_" .. colour .. ".png",

		paramtype = "light",
		paramtype2 = "facedir",

		sunlight_propagates = true,
		walkable = true,

		selection_box = {
			type = "fixed",
			fixed = {
				0.40, -0.5, -0.5,
				0.50,  1.5,  0.5
			},
		},

		collision_box = {
			type = "fixed",
			fixed = {
				0.40, -0.5, -0.5,
				0.50,  1.5,  0.5
			},
		},

		groups = {
			snappy = 2,
			cracky = 3,
			oddly_breakable_by_hand = 3,
			not_in_creative_inventory = 1,
		},

		sounds = default.node_sound_wood_defaults(),

		drop = porta_ch,

		on_rightclick = function(pos, node)

			node.name = porta_dx_ch

			minetest.set_node(pos, node)

			minetest.sound_play("summer_porta_ch", {
				pos = pos,
				gain = 2.0
			}, true)
		end,
	})


	--_____ Placement _____--
	--_____ Viewed from the player: _____--
	--_____ [ NEW DOOR ] [ SINGLE DOOR ] _____--
	--_____ TUA DESTRA       TUA SINISTRA _____--
	--_____ If a single door is to the LEFT of the new position _____--
	--_____ A single new door is available _____--
	--_____ becomes the RIGHT DOOR. _____--

	minetest.override_item(porta_ch, {

		on_place = function(itemstack, placer, pointed_thing)

			if pointed_thing.type ~= "node" then
				return itemstack
			end

			local pos = pointed_thing.above

			if not pos then
				return itemstack
			end


			--_____ Player direction _____--

			local yaw = placer:get_look_horizontal()


			--_____ Player right _____--
			--_____ This is the direction in which the new door must _____--
			--_____ be placed. _____--

			local right = {
				x = math.cos(yaw),
				y = 0,
				z = math.sin(yaw)
			}


			--_____ Position to the left of the player _____--
			--_____ relative to the new door _____--

			local check_pos = {
				x = math.floor(pos.x - right.x + 0.5),
				y = pos.y,
				z = math.floor(pos.z - right.z + 0.5)
			}


			--_____ Nearby door check _____--

			local vicino = minetest.get_node(check_pos)

			local usa_destra = false

			if vicino.name == porta_ch
				or vicino.name == porta_op then

				usa_destra = true
			end


			--_____ Door orientation _____--

			local facedir =
				minetest.dir_to_facedir(
					placer:get_look_dir()
				)


			--_____ Position check _____--

			local old_node =
				minetest.get_node(pos)

			local old_def =
				minetest.registered_nodes[old_node.name]

			if not old_def then
				return itemstack
			end

			if not old_def.buildable_to then
				return itemstack
			end


			--_____ Placement _____--

			if usa_destra then

				minetest.set_node(pos, {
					name = porta_dx_ch,
					param2 = facedir,
				})

			else

				minetest.set_node(pos, {
					name = porta_ch,
					param2 = facedir,
				})

			end


			--_____ Sound _____--

			minetest.sound_play(
				"default_place_node_hard",
				{
					pos = pos,
					gain = 1.0
				},
				true
			)


			--_____ Consumption _____--

			if not minetest.is_creative_enabled(
				placer:get_player_name()
			) then

				itemstack:take_item()

			end

			return itemstack
		end,
	})

end
]]

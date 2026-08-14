local S = summer.S

--[[
--_____ Ball module with glow, trail, sounds and special effects _____--
--_____ File: init.lua _____--

local CALCIO = 0.1
local IDLE_LIMIT = 5

local function reg_ball(color)
	local ball_item_name = "summer:ball_" .. color .. "_item"
	local ball_ent_name = "summer:ball_" .. color .. "_entity"

	minetest.register_entity(ball_ent_name, {
		initial_properties = {
			physical = true,
			collide_with_objects = true,
			visual = "mesh",
			mesh = "ball.obj",
			textures = { "ball_" .. color .. ".png" },
			collisionbox = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
			hp_max = 1000,
			pointable = true,
			glow = 10,
		},

		timer = 0,
		idle_time = 0,
		float_phase = 0,
		stabilized = false,

		on_step = function(self, dtime)
			self.timer = self.timer + dtime
			self.idle_time = self.idle_time + dtime
			local obj = self.object
			local pos = obj:get_pos()
			local vel = obj:get_velocity()
			local node = minetest.get_node_or_nil(pos)
			if not node then return end
			local node_def = minetest.registered_nodes[node.name]
			local in_liquid = node_def and node_def.liquidtype ~= "none"

			--_____ Constant floating _____--
			if in_liquid then
				self.float_phase = self.float_phase + dtime
				local oscill = math.sin(self.float_phase * 4) * 1.5
				obj:set_acceleration({ x = 0, y = 4 + oscill, z = 0 })

				vel.x = vel.x * 0.96
				vel.z = vel.z * 0.96
				obj:set_velocity(vel)

				minetest.add_particle({
					pos = pos,
					velocity = {x = math.random(-2, 2) / 10, y = 0.2, z = math.random(-2, 2) / 10},
					expirationtime = 0.4,
					size = 2,
					texture = "summer_trail.png",
					glow = 8
				})

				--_____ Restore movement when hit in water _____--
				local objs = minetest.get_objects_inside_radius(pos, 1.5)
				for _, obj2 in ipairs(objs) do
					if obj2:is_player() then
						local dir = obj2:get_look_dir()
						local mul = obj2:get_player_control().sneak and 3 or 1
						local push = vector.multiply(dir, mul * 4)
						obj:set_velocity(push)
						self.idle_time = 0
						self.stabilized = false
						minetest.sound_play("summer_ball_splash", { pos = pos, max_hear_distance = 10, gain = 1.0 })
						break
					end
				end
				return
			end

			--_____ Ground physics _____--
			local acc = { x = 0, y = -10, z = 0 }
			if not vector.equals(obj:get_acceleration(), acc) then
				obj:set_acceleration(acc)
			end

			local under = vector.new(pos)
			under.y = under.y - 0.5
			local node_below = minetest.get_node_or_nil(under)
			if node_below and minetest.registered_nodes[node_below.name].walkable then
				vel.x = vel.x * 0.9
				if vel.y < 0 then vel.y = vel.y * -0.65 end
				vel.z = vel.z * 0.9
				obj:set_velocity(vel)
			end

			--_____ Ground stabilization while keeping interaction _____--
			if self.idle_time >= IDLE_LIMIT and not in_liquid then
				if not self.stabilized then
					obj:set_velocity({ x = 0, y = 0, z = 0 })
					obj:set_acceleration({ x = 0, y = 0, z = 0 })
					self.stabilized = true
				end
			else
				self.stabilized = false
			end

			--_____ Nearby player detection _____--
			local objs = minetest.get_objects_inside_radius(pos, 1.5)
			local final_dir = { x=0, y=0, z=0 }
			local player_count = 0
			for _, obj2 in ipairs(objs) do
				if obj2:is_player() then
					local dir = obj2:get_look_dir()
					local mul = obj2:get_player_control().sneak and 3 or 1
					final_dir = vector.add(final_dir, vector.multiply(dir, mul))
					player_count = player_count + 1
				end
			end

			if player_count > 0 then
				final_dir = vector.divide(final_dir, player_count)
				final_dir = vector.multiply(final_dir, 6)
				obj:set_velocity(final_dir)
				self.idle_time = 0
				self.stabilized = false

				local sound = in_liquid and "summer_ball_splash" or "summer_ball_kick"
				minetest.sound_play(sound, { pos = pos, max_hear_distance = 10, gain = 1.0 })

				minetest.add_particlespawner({
					amount = 10,
					time = 0.1,
					minpos = pos,
					maxpos = pos,
					minvel = {x=-1, y=0, z=-1},
					maxvel = {x=1, y=2, z=1},
					texture = "boom_particle.png",
					glow = 10
				})
			end
		end,

		on_punch = function(self, puncher)
			if puncher and puncher:is_player() then
				local inv = puncher:get_inventory()
				inv:add_item("main", ItemStack(ball_item_name))
				self.object:remove()
			end
		end,
	})

	minetest.register_craftitem(ball_item_name, {
		description = S("Summer Ball") .. " (" .. color .. ")",
		inventory_image = "summer_ball_" .. color .. "_inv.png",
		on_place = function(itemstack, placer, pointed_thing)
			local pos = pointed_thing.above
			local ent = minetest.add_entity(pos, ball_ent_name)
			if ent then
				ent:set_velocity({ x = 0, y = -15, z = 0 })
				minetest.sound_play("summer_ball_kick", { pos = pos, max_hear_distance = 10, gain = 0.7 })
			end
			itemstack:take_item()
			return itemstack
		end,
	})

	--_____ Crafts _____--
	minetest.register_craft({
		output = ball_item_name,
		recipe = {
			{ "default:paper", "group:leaves", "default:paper" },
			{ "group:leaves", "wool:" .. color, "group:leaves" },
			{ "default:paper", "group:leaves", "default:paper" },
		},
	})

	if minetest.get_modpath("cannabis") then
		minetest.register_craft({
			output = ball_item_name,
			recipe = {
				{ "", "cannabis:canapa_plastic", "" },
				{ "cannabis:canapa_plastic", "wool:" .. color, "cannabis:canapa_plastic" },
				{ "", "cannabis:canapa_plastic", "" },
			},
		})
	end
end

local colors = { "black", "red", "green", "blue", "yellow", "violet", "orange" }
for _, color in ipairs(colors) do
	reg_ball(color)
end]]
--_____ Ball module with glow, trail, sounds and advanced physics bonus _____--
--_____ File: init.lua _____--

local CALCIO = 0.1
local IDLE_LIMIT = 5

local function reg_ball(color)
	local ball_item_name = "summer:ball_" .. color .. "_item"
	local ball_ent_name = "summer:ball_" .. color .. "_entity"

	minetest.register_entity(ball_ent_name, {
		initial_properties = {
			physical = true,
			collide_with_objects = true,
			visual = "mesh",
			mesh = "ball.obj",
			textures = { "ball_" .. color .. ".png" },
			collisionbox = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
			hp_max = 1000,
			pointable = true,
			glow = 10,
		},

		timer = 0,
		idle_time = 0,
		float_phase = 0,
		stabilized = false,
		roll_angle = 0,

		on_step = function(self, dtime)
			self.timer = self.timer + dtime
			self.idle_time = self.idle_time + dtime
			local obj = self.object
			local pos = obj:get_pos()
			local vel = obj:get_velocity()
			local node = minetest.get_node_or_nil(pos)
			if not node then return end
			local node_def = minetest.registered_nodes[node.name]
			local in_liquid = node_def and node_def.liquidtype ~= "none"

			local objs = minetest.get_objects_inside_radius(pos, 2.0)

			if in_liquid then
				self.float_phase = self.float_phase + dtime
				local oscill = math.sin(self.float_phase * 4) * 1.5
				obj:set_acceleration({ x = 0, y = 4 + oscill, z = 0 })

				vel.x = vel.x * 0.96
				vel.z = vel.z * 0.96
				obj:set_velocity(vel)

				minetest.add_particle({
					pos = vector.add(pos, {x=0, y=0.3, z=0}),
					velocity = {x = math.random(-2, 2) / 10, y = 0.2, z = math.random(-2, 2) / 10},
					expirationtime = 0.4,
					size = 2,
					texture = "summer_trail.png",
					glow = 8
				})

				for _, obj2 in ipairs(objs) do
					if obj2:is_player() then
						local dir = obj2:get_look_dir()
						local mul = obj2:get_player_control().sneak and 3 or 1
						local push = vector.multiply(dir, mul * 6)
						obj:set_velocity(push)
						self.idle_time = 0
						self.stabilized = false
						minetest.sound_play("summer_ball_splash", { pos = pos, max_hear_distance = 10, gain = 1.0 })
						break
					end
				end
				return
			end

			local acc = { x = 0, y = -10, z = 0 }
			if not vector.equals(obj:get_acceleration(), acc) then
				obj:set_acceleration(acc)
			end

			local under = vector.new(pos)
			under.y = under.y - 0.5
			local node_below = minetest.get_node_or_nil(under)
			if node_below and minetest.registered_nodes[node_below.name].walkable then
				vel.x = vel.x * 0.9
				if vel.y < 0 then vel.y = vel.y * -math.random(60, 85) / 100 end
				vel.z = vel.z * 0.9
				obj:set_velocity(vel)
			end

			if self.idle_time >= IDLE_LIMIT and not in_liquid then
				if not self.stabilized then
					obj:set_velocity({ x = 0, y = 0, z = 0 })
					obj:set_acceleration({ x = 0, y = 0, z = 0 })
					self.stabilized = true
				end
			else
				self.stabilized = false
			end

			local final_dir = { x=0, y=0, z=0 }
			local player_count = 0
			for _, obj2 in ipairs(objs) do
				if obj2:is_player() then
					local dir = obj2:get_look_dir()
					local mul = obj2:get_player_control().sneak and 3 or 1
					final_dir = vector.add(final_dir, vector.multiply(dir, mul))
					player_count = player_count + 1
				end
			end

			if player_count > 0 then
				final_dir = vector.divide(final_dir, player_count)
				final_dir = vector.multiply(final_dir, 8)
				obj:set_velocity(final_dir)
				self.idle_time = 0
				self.stabilized = false

				local sound = in_liquid and "summer_ball_splash" or "summer_ball_kick"
				minetest.sound_play(sound, { pos = pos, max_hear_distance = 10, gain = 1.0 })

				minetest.add_particlespawner({
					amount = 10,
					time = 0.1,
					minpos = pos,
					maxpos = pos,
					minvel = {x=-1, y=0, z=-1},
					maxvel = {x=1, y=2, z=1},
					texture = "boom_particle.png",
					glow = 10
				})
			end
		end,

		on_punch = function(self, puncher)
			if puncher and puncher:is_player() then
				local inv = puncher:get_inventory()
				inv:add_item("main", ItemStack(ball_item_name))
				self.object:remove()
			end
		end,
	})

	minetest.register_craftitem(ball_item_name, {
		description = S("Summer Ball") .. " (" .. color .. ")",
		inventory_image = "summer_ball_" .. color .. "_inv.png",
		on_place = function(itemstack, placer, pointed_thing)
			local pos = pointed_thing.above
			local node = minetest.get_node_or_nil(pos)
			if node and minetest.registered_nodes[node.name].liquidtype ~= "none" then
				pos.y = pos.y + 0.2
			end
			local ent = minetest.add_entity(pos, ball_ent_name)
			if ent then
				ent:set_velocity({ x = 0, y = -5, z = 0 })
				local sound = (node and minetest.registered_nodes[node.name].liquidtype ~= "none")
					and "summer_ball_splash" or "summer_ball_kick"
				minetest.sound_play(sound, { pos = pos, max_hear_distance = 10, gain = 0.8 })
			end
			itemstack:take_item()
			return itemstack
		end,
	})

	minetest.register_craft({
		output = ball_item_name,
		recipe = {
			{ "default:paper", "group:leaves", "default:paper" },
			{ "group:leaves", "wool:" .. color, "group:leaves" },
			{ "default:paper", "group:leaves", "default:paper" },
		},
	})

	if minetest.get_modpath("cannabis") then
		minetest.register_craft({
			output = ball_item_name,
			recipe = {
				{ "", "cannabis:canapa_plastic", "" },
				{ "cannabis:canapa_plastic", "wool:" .. color, "cannabis:canapa_plastic" },
				{ "", "cannabis:canapa_plastic", "" },
			},
		})
	end
end

local colors = { "black", "red", "green", "blue", "yellow", "violet", "orange" }
for _, color in ipairs(colors) do
	reg_ball(color)
end

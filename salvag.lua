local S = summer.S

local function is_water(pos)
	local node = minetest.get_node(pos)
	return minetest.get_item_group(node.name, "water") ~= 0
end

local function get_sign(i)
	if i > 0 then
		return 1
	elseif i < 0 then
		return -1
	end
	return 0
end

local function get_velocity(v, yaw, y)
	return {
		x = -math.sin(yaw) * v,
		y = y,
		z = math.cos(yaw) * v
	}
end

local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end

-- Height of the lifebuoy above the water surface.
-- The OBJ has its geometry below its origin, so this is intentionally
-- a little higher than the old +0.5 placement.
local WATER_OFFSET = 0.55

-- Movement tuning
local MAX_SPEED = 5
local ACCELERATION = 0.10
local FRICTION = 0.02
local STEER_SPEED = 0.03

local function set_player_animation(player, animation, speed)
	if not player or not player:is_player() then
		return
	end

	-- For the standard Minetest Game player model these are the actual
	-- animation frame ranges. Calling the engine directly is important
	-- because the player is attached to the lifebuoy.
	local fallback = {
		stand = {x = 0, y = 79},
		walk = {x = 168, y = 187},
	}

	local anim = fallback[animation]
	if anim then
		player:set_animation(
			anim,
			speed or 30,
			0,
			true
		)
	end
end

local function set_player_attached(player, attached)
	if default and default.player_attached then
		default.player_attached[player:get_player_name()] = attached
	end
end

local function get_mount_param2(pointed_thing)
	if pointed_thing.type ~= "node" then
		return nil
	end

	local dx = pointed_thing.under.x - pointed_thing.above.x
	local dy = pointed_thing.under.y - pointed_thing.above.y
	local dz = pointed_thing.under.z - pointed_thing.above.z

	-- Pointing at the top of a node: place the lifebuoy flat on the floor.
	if pointed_thing.above.y > pointed_thing.under.y then
		return 0
	end

	-- Pointing at the underside is not supported.
	if dy ~= 0 then
		return nil
	end

	return minetest.dir_to_wallmounted({
		x = dx,
		y = 0,
		z = dz
	})
end

local function detach_driver(self, player)
	if not player then
		return
	end

	local name = player:get_player_name()
	self.driver = nil
	self.driver_animation = nil

	player:set_detach()

	set_player_attached(player, false)
	set_player_animation(player, "stand", 30)

	player:set_eye_offset(
		{x = 0, y = 0.2, z = 0},
		{x = 0, y = 0, z = 0}
	)

	local pos = player:get_pos()
	pos.y = pos.y + 1

	minetest.after(0.1, function()
		if player and player:is_player() then
			player:set_pos(pos)
		end
	end)
end

local function reg_salvag(color)

	local salvag_item_name = "summer:salvag_" .. color .. "_item"
	local salvag_ent_name = "summer:salvag_" .. color

	local salvag = {
		physical = true,
		collisionbox = {-0.5, -0.35, -0.5, 0.5, 0.3, 0.5},
		visual = "mesh",
		mesh = "salvagl.obj",
		textures = {"summer_salvag_" .. color .. ".png"},

		driver = nil,
		v = 0,
		last_v = 0,
		removed = false,
		driver_animation = nil,
	}

	function salvag.on_rightclick(self, clicker)
		if not clicker or not clicker:is_player() or self.removed then
			return
		end

		local name = clicker:get_player_name()

		-- Driver gets out
		if self.driver and clicker == self.driver then
			detach_driver(self, clicker)
			return
		end

		-- Already occupied
		if self.driver then
			return
		end

		-- If the player is attached to another vehicle, detach first.
		local attach = clicker:get_attach()
		if attach and attach:get_luaentity() then
			local luaentity = attach:get_luaentity()
			if luaentity.driver then
				luaentity.driver = nil
			end
			clicker:set_detach()
		end

		self.driver = clicker

		clicker:set_attach(
			self.object,
			"",
			{x = 0, y = -10, z = 0},
			{x = 0, y = 0, z = 0}
		)

		clicker:set_eye_offset(
			{x = 0, y = -8, z = 0},
			{x = 0, y = 0, z = 0}
		)

		set_player_attached(clicker, true)
		self.driver_animation = nil

		minetest.after(0.2, function()
			if self.driver == clicker and clicker:is_player() then
				set_player_animation(clicker, "stand", 30)
				self.driver_animation = "stand"
			end
		end)

		self.object:set_yaw(clicker:get_look_yaw() - math.pi / 2)
	end

	function salvag.on_activate(self, staticdata, dtime_s)
		self.object:set_armor_groups({immortal = 1})

		if staticdata and staticdata ~= "" then
			self.v = tonumber(staticdata) or 0
		end

		self.last_v = self.v
	end

	function salvag.get_staticdata(self)
		return tostring(self.v)
	end

	function salvag.on_punch(self, puncher)
		if not puncher or not puncher:is_player() or self.removed then
			return
		end

		if self.driver and puncher == self.driver then
			detach_driver(self, puncher)
		end

		if not self.driver then
			self.removed = true

			minetest.after(0.1, function()
				if self.object then
					self.object:remove()
				end
			end)

			if not minetest.settings:get_bool("creative_mode") then
				local inv = puncher:get_inventory()

				if inv:room_for_item("main", salvag_item_name) then
					inv:add_item("main", salvag_item_name)
				else
					minetest.add_item(self.object:get_pos(), salvag_item_name)
				end
			end
		end
	end

	function salvag.on_step(self, dtime)
		if self.removed then
			return
		end

		local current_velocity = self.object:get_velocity()

		-- Recover the signed horizontal speed from the actual entity velocity.
		self.v = get_v(current_velocity) * get_sign(self.v)

		-- Controls
		if self.driver then
			local ctrl = self.driver:get_player_control()
			local yaw = self.object:get_yaw()

			if ctrl.up then
				self.v = self.v + ACCELERATION
			elseif ctrl.down then
				self.v = self.v - ACCELERATION
			end

			if ctrl.left then
				if self.v < 0 then
					self.object:set_yaw(yaw - (1 + dtime) * STEER_SPEED)
				else
					self.object:set_yaw(yaw + (1 + dtime) * STEER_SPEED)
				end
			elseif ctrl.right then
				if self.v < 0 then
					self.object:set_yaw(yaw + (1 + dtime) * STEER_SPEED)
				else
					self.object:set_yaw(yaw - (1 + dtime) * STEER_SPEED)
				end
			end

			-- Attached players are intentionally skipped by Minetest Game's
			-- normal animation globalstep. Keep the limb animation running here.
			self.animation_timer = (self.animation_timer or 0) + dtime
			if self.animation_timer >= 0.12 then
				self.animation_timer = 0
				local wanted_animation
				if ctrl.up or ctrl.down or math.abs(self.v) > 0.05 then
					wanted_animation = "walk"
				else
					wanted_animation = "stand"
				end
				set_player_animation(self.driver, wanted_animation, 30)
				self.driver_animation = wanted_animation
			end

		end

		-- Friction
		if self.v ~= 0 then
			local s = get_sign(self.v)
			self.v = self.v - FRICTION * s

			if s ~= get_sign(self.v) then
				self.v = 0
			end
		end

		if math.abs(self.v) > MAX_SPEED then
			self.v = MAX_SPEED * get_sign(self.v)
		end

		local pos = self.object:get_pos()

		-- Check the lower part of the lifebuoy against the water.
		local water_pos = {
			x = pos.x,
			y = pos.y - 0.5,
			z = pos.z
		}

		local new_velo = {x = 0, y = 0, z = 0}
		local new_acce = {x = 0, y = 0, z = 0}

		if not is_water(water_pos) then
			local node = minetest.get_node(water_pos)
			local nodedef = minetest.registered_nodes[node.name]

			if (not nodedef) or nodedef.walkable then
				self.v = 0
				new_acce = {x = 0, y = 1, z = 0}
			else
				new_acce = {x = 0, y = -9.8, z = 0}
			end

			new_velo = get_velocity(
				self.v,
				self.object:get_yaw(),
				current_velocity.y
			)
		else
			-- Check one node higher to determine whether the entity is
			-- partially or fully submerged.
			local upper_water_pos = {
				x = pos.x,
				y = pos.y + 0.5,
				z = pos.z
			}

			if is_water(upper_water_pos) then
				-- Fully/mostly submerged: stronger upward force.
				local y = current_velocity.y

				if y >= 5 then
					y = 5
				elseif y < 0 then
					new_acce = {x = 0, y = 20, z = 0}
				else
					new_acce = {x = 0, y = 5, z = 0}
				end

				new_velo = get_velocity(
					self.v,
					self.object:get_yaw(),
					y
				)
			else
				-- Floating at the surface.
				new_acce = {x = 0, y = 0, z = 0}

				if math.abs(current_velocity.y) < 1 then
					-- Do NOT use floor(pos.y) + 0.5 here.
					-- It was one of the causes of the model sitting too low.
					local target_y = math.floor(pos.y) + WATER_OFFSET
					pos.y = target_y

					self.object:set_pos(pos)

					new_velo = get_velocity(
						self.v,
						self.object:get_yaw(),
						0
					)
				else
					new_velo = get_velocity(
						self.v,
						self.object:get_yaw(),
						current_velocity.y
					)
				end
			end
		end

		self.object:set_velocity(new_velo)
		self.object:set_acceleration(new_acce)
	end

	minetest.register_entity(salvag_ent_name, salvag)

	local salvag_wall_name = "summer:salvag_"..color.."_wall"

-- One wallmounted node handles floor, ceiling and all four wall directions.
-- The mesh's local +Y axis is the mounting normal. After visual_scale=0.125
-- its geometry occupies +0.30 .. +0.50 nodes along that local axis.
-- Luanti rotates this axis according to param2: y+ (ceiling), y- (floor),
-- x+/x-/z+/z- (walls).
minetest.register_node(salvag_wall_name, {
	description = S("Mounted Lifebuoy") .. " (" .. color .. ")",
	drawtype = "mesh",
	mesh = "salvagl_wall.obj",
	visual_scale = 0.125,
	tiles = {"summer_salvag_"..color..".png"},

	paramtype = "light",
	paramtype2 = "wallmounted",
	wallmounted_rotate_vertical = false,
	sunlight_propagates = true,
	walkable = true,
	pointable = true,
	diggable = true,

	-- These boxes are in the wallmounted reference orientation.
	-- The engine rotates them together with param2.
	selection_box = {
		type = "wallmounted",
		wall_top = {-0.50,  0.30, -0.50,  0.50,  0.50,  0.50},
		wall_bottom = {-0.50, -0.50, -0.50,  0.50, -0.30,  0.50},
		wall_side = {-0.50, -0.50, -0.50, -0.30,  0.50,  0.50},
	},
	collision_box = {
		type = "wallmounted",
		wall_top = {-0.50,  0.30, -0.50,  0.50,  0.50,  0.50},
		wall_bottom = {-0.50, -0.50, -0.50,  0.50, -0.30,  0.50},
		wall_side = {-0.50, -0.50, -0.50, -0.30,  0.50,  0.50},
	},

	groups = {
		choppy = 2,
		oddly_breakable_by_hand = 2,
		attached_node = 1,
		not_in_creative_inventory = 1,
	},

	drop = salvag_item_name,

	on_punch = function(pos, node, puncher)
		if not puncher or not puncher:is_player() then
			return
		end

		minetest.remove_node(pos)

		if not minetest.settings:get_bool("creative_mode") then
			local inv = puncher:get_inventory()
			if inv:room_for_item("main", salvag_item_name) then
				inv:add_item("main", salvag_item_name)
			else
				minetest.add_item(pos, salvag_item_name)
			end
		end
	end,
})

minetest.register_craftitem(salvag_item_name, {
		description = S("Lifebuoy") .. " (" .. color .. ")",
		inventory_image = "summer_salvag_" .. color .. "_inv.png",
		wield_image = "summer_salvag_" .. color .. "_inv.png",
		wield_scale = {x = 2, y = 2, z = 1},
		liquids_pointable = true,

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return itemstack
			end

			-- Water: physical floating entity.
			if is_water(pointed_thing.under) then
				local pos = {
					x = pointed_thing.under.x,
					y = pointed_thing.under.y + WATER_OFFSET,
					z = pointed_thing.under.z
				}
				minetest.add_entity(pos, salvag_ent_name)

				if not minetest.settings:get_bool("creative_mode") then
					itemstack:take_item()
				end
				return itemstack
			end

			-- Any non-water face: place the same wallmounted node.
			-- param2=1 is floor, 0 is ceiling, 2..5 are the four walls.
			local dir = {
				x = pointed_thing.under.x - pointed_thing.above.x,
				y = pointed_thing.under.y - pointed_thing.above.y,
				z = pointed_thing.under.z - pointed_thing.above.z,
			}
			local param2 = minetest.dir_to_wallmounted(dir)
			local pos = pointed_thing.above
			local node = minetest.get_node(pos)
			local def = minetest.registered_nodes[node.name]
			if not def or not def.buildable_to then
				return itemstack
			end

			minetest.set_node(pos, {
				name = salvag_wall_name,
				param2 = param2,
			})

			if not minetest.settings:get_bool("creative_mode") then
				itemstack:take_item()
			end
			return itemstack
		end,
	})





local colors = {
	"black",
	"red",
	"green",
	"blue",
	"yellow",
	"violet",
	"orange",
}

for _, color in ipairs(colors) do
	reg_salvag(color)
end
end

local S = summer.S

local function is_water(pos)
	local nn = minetest.get_node(pos).name
	return minetest.get_item_group(nn, "water") ~= 0
end

local function get_sign(i)
	if i == 0 then
		return 0
	else
		return i / math.abs(i)
	end
end

local function get_velocity(v, yaw, y)
	local x = -math.sin(yaw) * v
	local z = math.cos(yaw) * v
	return {x = x, y = y, z = z}
end

local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end

local function reg_canoa_(color)
	local canoa_item_name = "summer:canoa_" .. color .. "_item"
	local canoa_ent_name = "summer:canoa_" .. color .. "_entity"

	local canoa_ = {
		physical = true,
		collisionbox = {-0.5, -0.35, -0.5, 0.5, 0.3, 0.5},
		visual = "mesh",
		mesh = "canoa.x",
		textures = {"canoa_" .. color .. ".png"},
		driver = nil,
		passengers = {},
		v = 0,
		last_v = 0,
		removed = false
	}

	local DRIVER_OFFSET = {x = 0, y = 1, z = 4}
	local PASSENGER_OFFSET = {x = 0, y = 1, z = -1}

	local function detach_player(self, player)
		if not player or not player:is_player() then
			return
		end

		local name = player:get_player_name()

		player:set_detach()
		default.player_attached[name] = false
		default.player_set_animation(player, "stand", 30)

		minetest.after(0.1, function()
			if not player or not player:is_player() then
				return
			end

			if not self.object then
				return
			end

			local canoe_pos = self.object:get_pos()

			if not canoe_pos then
				return
			end

			local yaw = self.object:get_yaw()
			local side = 2.0

			player:set_pos({
				x = canoe_pos.x + math.cos(yaw) * side,
				y = canoe_pos.y + 0.5,
				z = canoe_pos.z + math.sin(yaw) * side
			})
		end)
	end

	local function make_driver(self, player)
		if not player or not player:is_player() then
			return false
		end

		self.driver = player

		player:set_attach(
			self.object,
			"",
			DRIVER_OFFSET,
			{x = 0, y = 0, z = 0}
		)

		default.player_attached[player:get_player_name()] = true

		minetest.after(0.1, function()
			if player and player:is_player() then
				default.player_set_animation(player, "sit", 30)
			end
		end)

		return true
	end

	function canoa_.on_rightclick(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end

		local name = clicker:get_player_name()

		if self.driver == clicker then
			return
		end

		for _, passenger in ipairs(self.passengers) do
			if passenger == clicker then
				return
			end
		end

		if not self.driver then
			make_driver(self, clicker)

			self.object:set_yaw(
				clicker:get_look_yaw() - math.pi / 2
			)

			return
		end

		if #self.passengers >= 1 then
			minetest.chat_send_player(
				name,
				"La canoa è piena!"
			)
			return
		end

		clicker:set_attach(
			self.object,
			"",
			PASSENGER_OFFSET,
			{x = 0, y = 0, z = 0}
		)

		table.insert(self.passengers, clicker)

		default.player_attached[name] = true

		minetest.after(0.1, function()
			if clicker and clicker:is_player() then
				default.player_set_animation(clicker, "sit", 30)
			end
		end)
	end

	function canoa_.on_activate(self, staticdata, dtime_s)
		self.object:set_armor_groups({immortal = 1})

		if staticdata and staticdata ~= "" then
			self.v = tonumber(staticdata) or 0
		end

		self.last_v = self.v
	end

	function canoa_.get_staticdata(self)
		return tostring(self.v)
	end

	function canoa_.on_punch(self, puncher)
		if not puncher or not puncher:is_player() or self.removed then
			return
		end

		if self.driver then
			local driver = self.driver
			self.driver = nil

			if driver and driver:is_player() then
				detach_player(self, driver)
			end
		end

		for _, passenger in ipairs(self.passengers) do
			if passenger and passenger:is_player() then
				detach_player(self, passenger)
			end
		end

		self.passengers = {}
		self.removed = true

		minetest.after(0.1, function()
			if self.object then
				self.object:remove()
			end
		end)

		if not minetest.setting_getbool("creative_mode") then
			local inv = puncher:get_inventory()

			if inv:room_for_item("main", canoa_item_name) then
				inv:add_item("main", canoa_item_name)
			else
				minetest.add_item(
					self.object:get_pos(),
					canoa_item_name
				)
			end
		end
	end

	local function check_sneak(self)
		if self.driver and self.driver:is_player() then
			local ctrl = self.driver:get_player_control()

			if ctrl.sneak then
				local old_driver = self.driver

				self.driver = nil

				detach_player(self, old_driver)

				if #self.passengers > 0 then
					local new_driver =
						table.remove(self.passengers, 1)

					if new_driver and new_driver:is_player() then
						make_driver(self, new_driver)
					end
				end

				return
			end
		end

		for i = #self.passengers, 1, -1 do
			local passenger = self.passengers[i]

			if passenger and passenger:is_player() then
				local ctrl = passenger:get_player_control()

				if ctrl.sneak then
					table.remove(self.passengers, i)

					detach_player(
						self,
						passenger
					)

					return
				end
			else
				table.remove(self.passengers, i)
			end
		end
	end

	function canoa_.on_step(self, dtime)
		check_sneak(self)

		self.v =
			get_v(self.object:get_velocity())
			* get_sign(self.v)

		if self.driver then
			if not self.driver:is_player() then
				self.driver = nil
			else
				local ctrl =
					self.driver:get_player_control()

				local yaw =
					self.object:get_yaw()

				if ctrl.up then
					self.v = self.v + 0.1
				elseif ctrl.down then
					self.v = self.v - 0.1
				end

				if ctrl.left then
					self.object:set_yaw(
						yaw
						+ (1 + dtime)
						* 0.03
						* (self.v < 0 and -1 or 1)
					)
				elseif ctrl.right then
					self.object:set_yaw(
						yaw
						- (1 + dtime)
						* 0.03
						* (self.v < 0 and -1 or 1)
					)
				end
			end
		end

		local s = get_sign(self.v)

		self.v = self.v - 0.02 * s

		if s ~= get_sign(self.v) then
			self.object:set_velocity({
				x = 0,
				y = 0,
				z = 0
			})

			self.v = 0

			return
		end

		if math.abs(self.v) > 5 then
			self.v = 5 * get_sign(self.v)
		end

		local p = self.object:get_pos()

		p.y = p.y - 0.5

		local new_velo = {
			x = 0,
			y = 0,
			z = 0
		}

		local new_acce = {
			x = 0,
			y = 0,
			z = 0
		}

		if not is_water(p) then
			local nodedef =
				minetest.registered_nodes[
					minetest.get_node(p).name
				]

			if (not nodedef) or nodedef.walkable then
				self.v = 0

				new_acce = {
					x = 0,
					y = 1,
					z = 0
				}
			else
				new_acce = {
					x = 0,
					y = -9.8,
					z = 0
				}
			end

			new_velo = get_velocity(
				self.v,
				self.object:get_yaw(),
				self.object:get_velocity().y
			)

			self.object:set_pos(
				self.object:get_pos()
			)
		else
			p.y = p.y + 1

			if is_water(p) then
				local y =
					self.object:get_velocity().y

				y = math.max(
					math.min(y, 5),
					-10
				)

				new_acce = {
					x = 0,
					y = (y < 0) and 20 or 5,
					z = 0
				}

				new_velo = get_velocity(
					self.v,
					self.object:get_yaw(),
					y
				)

				self.object:set_pos(
					self.object:get_pos()
				)
			else
				if math.abs(
					self.object:get_velocity().y
				) < 1 then
					local pos =
						self.object:get_pos()

					pos.y =
						math.floor(pos.y) + 0.5

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
						self.object:get_velocity().y
					)

					self.object:set_pos(
						self.object:get_pos()
					)
				end

				new_acce = {
					x = 0,
					y = 0,
					z = 0
				}
			end
		end

		self.object:set_velocity(new_velo)
		self.object:set_acceleration(new_acce)
	end

	minetest.register_entity(
		canoa_ent_name,
		canoa_
	)

	minetest.register_craftitem(
		canoa_item_name,
		{
			description =
				S("Canoe")
				.. " ("
				.. color
				.. ")",

			inventory_image =
				"canoa_"
				.. color
				.. "_inv.png",

			wield_image =
				"canoa_"
				.. color
				.. "_inv.png",

			wield_scale = {
				x = 2,
				y = 2,
				z = 1
			},

			liquids_pointable = true,

			on_place = function(
				itemstack,
				placer,
				pointed_thing
			)
				if pointed_thing.type ~= "node"
				or not is_water(
					pointed_thing.under
				) then
					return
				end

				pointed_thing.under.y =
					pointed_thing.under.y + 0.5

				minetest.add_entity(
					pointed_thing.under,
					canoa_ent_name
				)

				if not minetest.setting_getbool(
					"creative_mode"
				) then
					itemstack:take_item()
				end

				return itemstack
			end
		}
	)

	minetest.register_craft({
		output = canoa_item_name,

		recipe = {
			{"", "", ""},
			{"", "wool:" .. color, ""},
			{
				"group:wood",
				"group:wood",
				"group:wood"
			},
		}
	})

	if minetest.get_modpath("cannabis") then
		minetest.register_craft({
			output = canoa_item_name,

			recipe = {
				{"", "", ""},
				{"", "wool:" .. color, ""},
				{
					"cannabis:canapa_plastic",
					"cannabis:canapa_plastic",
					"cannabis:canapa_plastic"
				},
			}
		})
	end
end

local colors = {
	"black",
	"red",
	"green",
	"blue",
	"yellow",
	"violet",
	"orange"
}

for _, color in ipairs(colors) do
	reg_canoa_(color)
end

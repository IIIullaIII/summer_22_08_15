local S = summer.S

local player_boat = {}

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

local function reg_barca(color)

	local barca_item_name = "summer:barca_"..color.."_item"
	local barca_ent_name = "summer:barca_"..color

	local barca = {
		physical = true,
		collisionbox = {-2.5, -0.5, -2.5, 2.5, 0.3, 2.5},
		visual = "mesh",
		mesh = "barca.x",
		textures = {"barca_"..color..".png"},

		driver = nil,
		passengers = {},

		v = 0,
		last_v = 0,
		removed = false
	}

	local SEATS = {
		[1] = {
			x = 0,
			y = 4,
			z = 10
		},
		[2] = {
			x = -15,
			y = 4,
			z = 0
		},
		[3] = {
			x = 15,
			y = 4,
			z = 0
		},
		[4] = {
			x = 0,
			y = 4,
			z = -20
		}
	}

	local function get_player_at_seat(self, seat)
		if seat == 1 then
			return self.driver
		end

		return self.passengers[seat - 1]
	end

	local function clear_player_boat(player)
		if not player or not player:is_player() then
			return
		end

		local name = player:get_player_name()

		if player_boat[name] then
			player_boat[name] = nil
		end
	end

	local function set_player_boat(self, player)
		if not player or not player:is_player() then
			return
		end

		player_boat[player:get_player_name()] = self.object
	end

	local function attach_player(self, player, seat)
		if not player or not player:is_player() then
			return
		end

		local offset = SEATS[seat]

		if not offset then
			return
		end

		set_player_boat(self, player)

		player:set_attach(
			self.object,
			"",
			{
				x = offset.x,
				y = offset.y,
				z = offset.z
			},
			{
				x = 0,
				y = 0,
				z = 0
			}
		)

		if seat == 1 then
			player:set_eye_offset(
				{
					x = 0,
					y = 17,
					z = 2
				},
				{
					x = 0,
					y = 0,
					z = 0
				}
			)
		else
			player:set_eye_offset(
				{
					x = 0,
					y = 17,
					z = 0
				},
				{
					x = 0,
					y = 0,
					z = 0
				}
			)
		end

		default.player_attached[
			player:get_player_name()
		] = true

		minetest.after(0.2, function()
			if player and player:is_player() then
				default.player_set_animation(
					player,
					"sit",
					30
				)
			end
		end)
	end

	local function detach_player(self, player)
		if not player or not player:is_player() then
			return
		end

		local name = player:get_player_name()

		player:set_detach()

		if player_boat[name] == self.object then
			clear_player_boat(player)
		end

		default.player_attached[name] = false

		default.player_set_animation(
			player,
			"stand",
			30
		)

		player:set_eye_offset(
			{
				x = 0,
				y = 0.2,
				z = 0
			},
			{
				x = 0,
				y = 0,
				z = 0
			}
		)

		minetest.after(0.1, function()
			if not player or not player:is_player() then
				return
			end

			local pos = player:getpos()

			player:setpos({
				x = pos.x,
				y = pos.y + 0.2,
				z = pos.z
			})
		end)
	end

	local function reorganize_players(self)
		local players = {}

		if self.driver then
			table.insert(players, self.driver)
		end

		for _, player in ipairs(self.passengers) do
			if player and player:is_player() then
				table.insert(players, player)
			end
		end

		self.driver = players[1]

		self.passengers = {}

		for i = 2, #players do
			table.insert(
				self.passengers,
				players[i]
			)
		end

		for i, player in ipairs(players) do
			attach_player(
				self,
				player,
				i
			)
		end
	end

	local function remove_driver(self)
		if not self.driver then
			return
		end

		local old_driver = self.driver

		self.driver = nil

		detach_player(
			self,
			old_driver
		)

		if #self.passengers > 0 then
			self.driver =
				table.remove(
					self.passengers,
					1
				)
		end

		reorganize_players(self)
	end

	local function remove_passenger(self, player)
		for i, passenger in ipairs(self.passengers) do
			if passenger == player then
				table.remove(
					self.passengers,
					i
				)

				detach_player(
					self,
					player
				)

				reorganize_players(self)

				return true
			end
		end

		return false
	end

	function barca.on_rightclick(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end

		local name = clicker:get_player_name()

		local assigned_boat =
			player_boat[name]

		if assigned_boat
		and assigned_boat ~= self.object then
			return
		end

		local attached =
			clicker:get_attach()

		if attached
		and attached ~= self.object then
			return
		end

		if self.driver == clicker then
			return
		end

		for _, passenger in ipairs(self.passengers) do
			if passenger == clicker then
				return
			end
		end

		if not self.driver then
			self.driver = clicker

			set_player_boat(
				self,
				clicker
			)

			attach_player(
				self,
				clicker,
				1
			)

			self.object:setyaw(
				clicker:get_look_yaw()
				- math.pi / 2
			)

			return
		end

		if #self.passengers >= 3 then
			minetest.chat_send_player(
				name,
				"La barca è piena!"
			)
			return
		end

		table.insert(
			self.passengers,
			clicker
		)

		set_player_boat(
			self,
			clicker
		)

		reorganize_players(self)
	end

	function barca.on_activate(
		self,
		staticdata,
		dtime_s
	)
		self.object:set_armor_groups({
			immortal = 1
		})

		if staticdata then
			self.v = tonumber(staticdata)
		end

		self.last_v = self.v
	end

	function barca.get_staticdata(self)
		return tostring(self.v)
	end

	function barca.on_punch(
		self,
		puncher
	)
		if not puncher
		or not puncher:is_player()
		or self.removed then
			return
		end

		if self.driver == puncher then
			remove_driver(self)

		else
			remove_passenger(
				self,
				puncher
			)
		end

		if not self.driver then
			self.removed = true

			for _, passenger in ipairs(
				self.passengers
			) do
				if passenger
				and passenger:is_player() then
					clear_player_boat(
						passenger
					)

					passenger:set_detach()

					default.player_attached[
						passenger:get_player_name()
					] = false
				end
			end

			self.passengers = {}

			minetest.after(0.1, function()
				self.object:remove()
			end)

			if not minetest.setting_getbool(
				"creative_mode"
			) then
				local inv =
					puncher:get_inventory()

				if inv:room_for_item(
					"main",
					barca_item_name
				) then
					inv:add_item(
						"main",
						barca_item_name
					)
				else
					minetest.add_item(
						self.object:getpos(),
						barca_item_name
					)
				end
			end
		end
	end

	local function check_sneak(self)
		if self.driver
		and self.driver:is_player() then

			local ctrl =
				self.driver:get_player_control()

			if ctrl.sneak then
				remove_driver(self)
				return
			end
		end

		for i = #self.passengers, 1, -1 do
			local passenger =
				self.passengers[i]

			if passenger
			and passenger:is_player() then

				local ctrl =
					passenger:get_player_control()

				if ctrl.sneak then
					remove_passenger(
						self,
						passenger
					)

					return
				end
			else
				table.remove(
					self.passengers,
					i
				)
			end
		end

		reorganize_players(self)
	end

	function barca.on_step(
		self,
		dtime
	)
		check_sneak(self)

		self.v =
			get_v(
				self.object:getvelocity()
			) * get_sign(self.v)

		if self.driver then
			local ctrl =
				self.driver:get_player_control()

			local yaw =
				self.object:getyaw()

			if ctrl.up then
				self.v = self.v + 0.1
			elseif ctrl.down then
				self.v = self.v - 0.1
			end

			if ctrl.left then
				if self.v < 0 then
					self.object:setyaw(
						yaw
						- (1 + dtime)
						* 0.03
					)
				else
					self.object:setyaw(
						yaw
						+ (1 + dtime)
						* 0.03
					)
				end
			elseif ctrl.right then
				if self.v < 0 then
					self.object:setyaw(
						yaw
						+ (1 + dtime)
						* 0.03
					)
				else
					self.object:setyaw(
						yaw
						- (1 + dtime)
						* 0.03
					)
				end
			end
		end

		local velo =
			self.object:getvelocity()

		if self.v == 0
		and velo.x == 0
		and velo.y == 0
		and velo.z == 0 then

			self.object:setpos(
				self.object:getpos()
			)

			return
		end

		local s =
			get_sign(self.v)

		self.v =
			self.v - 0.02 * s

		if s ~= get_sign(self.v) then
			self.object:setvelocity({
				x = 0,
				y = 0,
				z = 0
			})

			self.v = 0

			return
		end

		if math.abs(self.v) > 5 then
			self.v =
				5 * get_sign(self.v)
		end

		local p =
			self.object:getpos()

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

			if (not nodedef)
			or nodedef.walkable then

				self.v = 0

				new_acce = {
					x = 0,
					y = 2,
					z = 0
				}
			else
				new_acce = {
					x = 0,
					y = -1.8,
					z = 0
				}
			end

			new_velo =
				get_velocity(
					self.v,
					self.object:getyaw(),
					self.object:getvelocity().y
				)

			self.object:setpos(
				self.object:getpos()
			)

		else
			p.y = p.y + 1

			if is_water(p) then
				local y =
					self.object:getvelocity().y

				if y >= 7 then
					y = 7
				elseif y < 0 then
					new_acce = {
						x = 0,
						y = 50,
						z = 0
					}
				else
					new_acce = {
						x = 0,
						y = 7,
						z = 0
					}
				end

				new_velo =
					get_velocity(
						self.v,
						self.object:getyaw(),
						y
					)

				self.object:setpos(
					self.object:getpos()
				)

			else
				new_acce = {
					x = 0,
					y = 0,
					z = 0
				}

				if math.abs(
					self.object:getvelocity().y
				) < 1 then

					local pos =
						self.object:getpos()

					pos.y =
						math.floor(pos.y) + 1.

					self.object:setpos(pos)

					new_velo =
						get_velocity(
							self.v,
							self.object:getyaw(),
							0
						)
				else
					new_velo =
						get_velocity(
							self.v,
							self.object:getyaw(),
							self.object:getvelocity().y
						)

					self.object:setpos(
						self.object:getpos()
					)
				end
			end
		end

		self.object:setvelocity(new_velo)
		self.object:setacceleration(new_acce)
	end

	minetest.register_entity(
		barca_ent_name,
		barca
	)

	minetest.register_craftitem(
		barca_item_name,
		{
			description =
				S("Boat")
				.. " ("
				.. color
				.. ")",

			inventory_image =
				"barca_"
				.. color
				.. "_inv.png",

			wield_image =
				"barca_"
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
				if pointed_thing.type ~= "node" then
					return
				end

				if not is_water(
					pointed_thing.under
				) then
					return
				end

				pointed_thing.under.y =
					pointed_thing.under.y + 0.5

				minetest.add_entity(
					pointed_thing.under,
					barca_ent_name
				)

				if not minetest.setting_getbool(
					"creative_mode"
				) then
					itemstack:take_item()
				end

				return itemstack
			end,
		}
	)

	if minetest.get_modpath("cannabis") then
		minetest.register_craft({
			output = barca_item_name,
			recipe = {
				{"", "", ""},
				{
					"cannabis:canapa_plastic",
					"wool:"..color,
					"cannabis:canapa_plastic"
				},
				{
					"cannabis:canapa_plastic",
					"cannabis:canapa_plastic",
					"cannabis:canapa_plastic"
				},
			},
		})
	end

	minetest.register_craft({
		output = barca_item_name,
		recipe = {
			{"", "", ""},
			{
				"group:wood",
				"wool:"..color,
				"group:wood"
			},
			{
				"group:wood",
				"group:wood",
				"group:wood"
			},
		},
	})
end

colors = {
	"black",
	"red",
	"green",
	"blue",
	"yellow",
	"violet",
	"orange",
}

for _, color in ipairs(colors) do
	reg_barca(color)
end

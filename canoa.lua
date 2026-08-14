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
	local z =  math.cos(yaw) * v
	return {x = x, y = y, z = z}
end

local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end

local function reg_canoa_(color)
	local canoa_item_name = "summer:canoa_"..color.."_item"
	local canoa_ent_name = "summer:canoa_"..color.."_entity"

	local canoa_ = {
		physical = true,
		collisionbox = {-0.5, -0.35, -0.5, 0.5, 0.3, 0.5},
		visual = "mesh",
		mesh = "canoa.x",
		textures = {"canoa_"..color..".png" },
		driver = nil,
		passengers = {},
		v = 0,
		last_v = 0,
		removed = false
	}

	function canoa_.on_rightclick(self, clicker)
		if not clicker or not clicker:is_player() then return end
		local name = clicker:get_player_name()

		--_____ If already aboard as driver or passenger, detach _____--
		if self.driver == clicker then
			self.driver = nil
			clicker:set_detach()
			default.player_attached[name] = false
			default.player_set_animation(clicker, "stand", 30)
			minetest.after(0.1, function()
				local pos = clicker:getpos()
				clicker:setpos({x = pos.x, y = pos.y + 0.2, z = pos.z})
			end)
			return
		end
		for i, p in ipairs(self.passengers) do
			if p == clicker then
				table.remove(self.passengers, i)
				clicker:set_detach()
				default.player_attached[name] = false
				default.player_set_animation(clicker, "stand", 30)
				minetest.after(0.1, function()
					local pos = clicker:getpos()
					clicker:setpos({x = pos.x, y = pos.y + 0.2, z = pos.z})
				end)
				return
			end
		end

		--_____ If empty, become the driver _____--
		if not self.driver then
			self.driver = clicker
			clicker:set_attach(self.object, "", {x = 0, y = 1, z = -3}, {x = 0, y = 0, z = 0})
			default.player_attached[name] = true
			minetest.after(0.2, function()
				default.player_set_animation(clicker, "sit", 30)
			end)
			self.object:setyaw(clicker:get_look_yaw() - math.pi / 2)
			return
		end

		--_____ Add as passenger _____--
		if #self.passengers >= 2 then
			minetest.chat_send_player(name, "La canoa è piena!")
			return
		end
		local offset_z = (#self.passengers == 0) and 0 or 3
		clicker:set_attach(self.object, "", {x = 0, y = 1, z = offset_z}, {x = 0, y = 0, z = 0})
		table.insert(self.passengers, clicker)
		default.player_attached[name] = true
		minetest.after(0.2, function()
			default.player_set_animation(clicker, "sit", 30)
		end)
	end
	function canoa_.on_activate(self, staticdata, dtime_s)
		self.object:set_armor_groups({immortal = 1})
		if staticdata then
			self.v = tonumber(staticdata)
		end
		self.last_v = self.v
	end

	function canoa_.get_staticdata(self)
		return tostring(self.v)
	end

	function canoa_.on_punch(self, puncher)
		if not puncher or not puncher:is_player() or self.removed then return end

		if self.driver and puncher == self.driver then
			self.driver = nil
			puncher:set_detach()
			default.player_attached[puncher:get_player_name()] = false
		end

		for _, passenger in ipairs(self.passengers) do
			if passenger and passenger:is_player() then
				passenger:set_detach()
				default.player_attached[passenger:get_player_name()] = false
			end
		end
		self.passengers = {}

		if not self.driver then
			self.removed = true
			minetest.after(0.1, function()
				self.object:remove()
			end)
			if not minetest.setting_getbool("creative_mode") then
				local inv = puncher:get_inventory()
				if inv:room_for_item("main", canoa_item_name) then
					inv:add_item("main", canoa_item_name)
				else
					minetest.add_item(self.object:getpos(), canoa_item_name)
				end
			end
		end
	end

	function canoa_.on_step(self, dtime)
		self.v = get_v(self.object:getvelocity()) * get_sign(self.v)
		if self.driver then
			local ctrl = self.driver:get_player_control()
			local yaw = self.object:getyaw()
			if ctrl.up then self.v = self.v + 0.1
			elseif ctrl.down then self.v = self.v - 0.1 end
			if ctrl.left then
				self.object:setyaw(yaw + (1 + dtime) * 0.03 * (self.v < 0 and -1 or 1))
			elseif ctrl.right then
				self.object:setyaw(yaw - (1 + dtime) * 0.03 * (self.v < 0 and -1 or 1))
			end
		end

		local s = get_sign(self.v)
		self.v = self.v - 0.02 * s
		if s ~= get_sign(self.v) then
			self.object:setvelocity({x = 0, y = 0, z = 0})
			self.v = 0
			return
		end

		if math.abs(self.v) > 5 then self.v = 5 * get_sign(self.v) end

		local p = self.object:getpos()
		p.y = p.y - 0.5
		local new_velo = {x = 0, y = 0, z = 0}
		local new_acce = {x = 0, y = 0, z = 0}

		if not is_water(p) then
			local nodedef = minetest.registered_nodes[minetest.get_node(p).name]
			if (not nodedef) or nodedef.walkable then
				self.v = 0
				new_acce = {x = 0, y = 1, z = 0}
			else
				new_acce = {x = 0, y = -9.8, z = 0}
			end
			new_velo = get_velocity(self.v, self.object:getyaw(), self.object:getvelocity().y)
			self.object:setpos(self.object:getpos())
		else
			p.y = p.y + 1
			if is_water(p) then
				local y = self.object:getvelocity().y
				y = math.max(math.min(y, 5), -10)
				new_acce = {x = 0, y = (y < 0) and 20 or 5, z = 0}
				new_velo = get_velocity(self.v, self.object:getyaw(), y)
				self.object:setpos(self.object:getpos())
			else
				if math.abs(self.object:getvelocity().y) < 1 then
					local pos = self.object:getpos()
					pos.y = math.floor(pos.y) + 0.5
					self.object:setpos(pos)
					new_velo = get_velocity(self.v, self.object:getyaw(), 0)
				else
					new_velo = get_velocity(self.v, self.object:getyaw(), self.object:getvelocity().y)
					self.object:setpos(self.object:getpos())
				end
				new_acce = {x = 0, y = 0, z = 0}
			end
		end

		self.object:setvelocity(new_velo)
		self.object:setacceleration(new_acce)
	end

	minetest.register_entity(canoa_ent_name, canoa_)

	minetest.register_craftitem(canoa_item_name, {
		description = S("Canoe") .. " (" .. color .. ")",
		inventory_image = "canoa_"..color.."_inv.png",
		wield_image = "canoa_"..color.."_inv.png",
		wield_scale = {x = 2, y = 2, z = 1},
		liquids_pointable = true,
		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" or not is_water(pointed_thing.under) then return end
			pointed_thing.under.y = pointed_thing.under.y + 0.5
			minetest.add_entity(pointed_thing.under, canoa_ent_name)
			if not minetest.setting_getbool("creative_mode") then
				itemstack:take_item()
			end
			return itemstack
		end,
	})

	minetest.register_craft({
		output = canoa_item_name,
		recipe = {
			{"", "", ""},
			{"", "wool:"..color, ""},
			{"group:wood", "group:wood", "group:wood"},
		},
	})

	if minetest.get_modpath("cannabis") then
		minetest.register_craft({
			output = canoa_item_name,
			recipe = {
				{"", "", ""},
				{"", "wool:"..color, ""},
				{"cannabis:canapa_plastic", "cannabis:canapa_plastic", "cannabis:canapa_plastic"},
			},
		})
	end
end

colors = {"black", "red", "green", "blue", "yellow", "violet", "orange"}
for _, color in ipairs(colors) do
	reg_canoa_(color)
end

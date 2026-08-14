local S = summer.S

local function is_water(pos)
	local nn = minetest.get_node(pos).name
	return minetest.get_item_group(nn, "water") ~= 0
end

local function get_sign(i)
	if i == 0 then return 0 end
	return i / math.abs(i)
end

--_____ Optimized trigonometric functions for orientation _____--
local function get_velocity(v, yaw, y)
	local x = -math.sin(yaw) * v
	local z =  math.cos(yaw) * v
	return {x = x, y = y, z = z}
end

local function get_v(v)
	return math.sqrt(v.x ^ 2 + v.z ^ 2)
end

local function reg_materassino(color)
	local materassino_item_name = "summer:materassino_"..color.."_item"
	local materassino_ent_name = "summer:materassino_"..color -- Rimosso suffix duplicato

	local materassino = {
		physical = true,
		collisionbox = {-0.5, -0.35, -0.5, 0.5, 0.3, 0.5},
		visual = "mesh",
		mesh = "materassino.obj",
		textures = { "materassino_"..color..".png" },
		driver = nil,
		v = 0,
		last_v = 0,
		removed = false
	}

	function materassino.on_rightclick(self, clicker)
		if not clicker or not clicker:is_player() then return end
		local name = clicker:get_player_name()

		if self.driver and clicker == self.driver then
			self.driver = nil
			clicker:set_detach()
			if default.player_attached then default.player_attached[name] = false end
			default.player_set_animation(clicker, "stand", 30)

			--_____ API fix: use get_pos() and set_pos() _____--
			local pos = clicker:get_pos()
			if pos then
				pos = {x = pos.x, y = pos.y + 0.2, z = pos.z}
				minetest.after(0.1, function() clicker:set_pos(pos) end)
			end
		elseif not self.driver then
			local attach = clicker:get_attach()
			if attach and attach:get_luaentity() then
				local luaentity = attach:get_luaentity()
				if luaentity.driver then luaentity.driver = nil end
				clicker:set_detach()
			end
			self.driver = clicker
			clicker:set_attach(self.object, "", {x = 0, y = 1, z = -3}, {x = 0, y = 0, z = 0})
			if default.player_attached then default.player_attached[name] = true end

			minetest.after(0.2, function()
				default.player_set_animation(clicker, "lay", 30)
			end)
			--_____ API fix: use set_yaw() instead of setyaw() _____--
			self.object:set_yaw(clicker:get_look_yaw() - math.pi / 2)
		end
	end

	function materassino.on_activate(self, staticdata, dtime_s)
		self.object:set_armor_groups({immortal = 1})
		if staticdata and staticdata ~= "" then
			self.v = tonumber(staticdata) or 0
		end
		self.last_v = self.v
	end

	function materassino.get_staticdata(self)
		return tostring(self.v)
	end

	function materassino.on_punch(self, puncher)
		if not puncher or not puncher:is_player() or self.removed then return end

		if self.driver and puncher == self.driver then
			self.driver = nil
			puncher:set_detach()
			if default.player_attached then default.player_attached[puncher:get_player_name()] = false end
		end

		if not self.driver then
			self.removed = true
			local pos = self.object:get_pos()
			minetest.after(0.1, function() self.object:remove() end)

			--_____ API fix: use native settings instead of setting_getbool _____--
			if not minetest.settings:get_bool("creative_mode") then
				local inv = puncher:get_inventory()
				if inv and inv:room_for_item("main", materassino_item_name) then
					inv:add_item("main", materassino_item_name)
				else
					if pos then minetest.add_item(pos, materassino_item_name) end
				end
			end
		end
	end

	function materassino.on_step(self, dtime)
		--_____ API fix: use native get_velocity() and get_pos() on the entity object _____--
		local velo = self.object:get_velocity()
		self.v = get_v(velo) * get_sign(self.v)

		if self.driver then
			local ctrl = self.driver:get_player_control()
			local yaw = self.object:get_yaw()
			if ctrl.up then
				self.v = self.v + 0.1
			elseif ctrl.down then
				self.v = self.v - 0.1
			end
			if ctrl.left then
				self.object:set_yaw(yaw + (self.v < 0 and -1 or 1) * (1 + dtime) * 0.03)
			elseif ctrl.right then
				self.object:set_yaw(yaw + (self.v < 0 or -1) * (1 + dtime) * 0.03)
			end
		end

		if self.v == 0 and velo.x == 0 and velo.y == 0 and velo.z == 0 then
			return
		end

		local s = get_sign(self.v)
		self.v = self.v - 0.02 * s
		if s ~= get_sign(self.v) then
			self.object:set_velocity({x = 0, y = 0, z = 0})
			self.v = 0
			return
		end
		if math.abs(self.v) > 5 then
			self.v = 5 * get_sign(self.v)
		end

		local p = self.object:get_pos()
		if not p then return end
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
			new_velo = get_velocity(self.v, self.object:get_yaw(), self.object:get_velocity().y)
		else
			p.y = p.y + 1
			if is_water(p) then
				local y = self.object:get_velocity().y
				if y >= 5 then y = 5
				elseif y < 0 then new_acce = {x = 0, y = 20, z = 0}
				else new_acce = {x = 0, y = 5, z = 0} end
				new_velo = get_velocity(self.v, self.object:get_yaw(), y)
			else
				new_acce = {x = 0, y = 0, z = 0}
				if math.abs(self.object:get_velocity().y) < 1 then
					local pos = self.object:get_pos()
					if pos then
						pos.y = math.floor(pos.y) + 0.5
						self.object:set_pos(pos)
					end
					new_velo = get_velocity(self.v, self.object:get_yaw(), 0)
				else
					new_velo = get_velocity(self.v, self.object:get_yaw(), self.object:get_velocity().y)
				end
			end
		end
		self.object:set_velocity(new_velo)
		self.object:set_acceleration(new_acce)
	end

	minetest.register_entity(materassino_ent_name, materassino)

	minetest.register_craftitem(materassino_item_name, {
		description = S("Mattress") .. " (" .. color .. ")",
		inventory_image = "materassino_"..color.."_inv.png",
		wield_image = "materassino_"..color.."_inv.png",
		wield_scale = {x = 2, y = 2, z = 1},
		liquids_pointable = true,

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then return end
			if not is_water(pointed_thing.under) then return end

			local spawn_pos = vector.new(pointed_thing.under)
			spawn_pos.y = spawn_pos.y + 0.5

			minetest.add_entity(spawn_pos, materassino_ent_name)
			if not minetest.settings:get_bool("creative_mode") then
				itemstack:take_item()
			end
			return itemstack
		end,
	})

	--_____ Craft with the cannabis mod (optional) _____--
	if minetest.get_modpath("cannabis") then
		minetest.register_craft({
			output = materassino_item_name,
			recipe = {
				{"", "", ""},
				{"", "wool:"..color, ""},
				{"cannabis:canapa_plastic", "cannabis:canapa_plastic", "cannabis:canapa_plastic"},
			},
		})
	end

	--_____ Standard wool craft _____--
	minetest.register_craft({
		output = materassino_item_name,
		recipe = {
			{"", "", ""},
			{"", "wool:"..color, ""},
			{"wool:"..color, "wool:"..color, "wool:"..color},
		},
	})
end

local colors = {
	"black", "red", "green", "blue", "yellow", "violet", "orange",
}

for _, color in ipairs(colors) do
	reg_materassino(color)
end

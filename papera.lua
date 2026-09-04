local S = summer.S

local paperella_item_name = "summer:paperella_item"
local paperella_ent_name = "summer:paperella"

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

-- Altezza della papera rispetto alla superficie dell'acqua.
-- Da adattare solo se il modello risulta troppo alto o troppo basso.
local WATER_OFFSET = 0.55

-- Movimento
local MAX_SPEED = 5
local ACCELERATION = 0.10
local FRICTION = 0.02
local STEER_SPEED = 0.03

local function set_player_animation(player, animation, speed)
	if not player or not player:is_player() then
		return
	end

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

local function detach_driver(self, player)
	if not player then
		return
	end

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

local paperella = {
	physical = true,

	-- Collisione della papera.
	collisionbox = {-0.5, -0.35, -0.5, 0.5, 0.3, 0.5},

initial_properties = {
		visual = "mesh",
		mesh = "paperella.obj",
		textures = {"papera.png"},
		},
	driver = nil,
	v = 0,
	last_v = 0,
	removed = false,
	driver_animation = nil,
	animation_timer = 0,
}

function paperella.on_rightclick(self, clicker)
	if not clicker or not clicker:is_player() or self.removed then
		return
	end

	-- Il guidatore scende.
	if self.driver and clicker == self.driver then
		detach_driver(self, clicker)
		return
	end

	-- Papera già occupata.
	if self.driver then
		return
	end

	-- Se il giocatore è già attaccato a un altro veicolo,
	-- lo stacchiamo prima.
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

function paperella.on_activate(self, staticdata, dtime_s)
	self.object:set_armor_groups({immortal = 1})

	if staticdata and staticdata ~= "" then
		self.v = tonumber(staticdata) or 0
	end

	self.last_v = self.v
end

function paperella.get_staticdata(self)
	return tostring(self.v)
end

function paperella.on_punch(self, puncher)
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

			if inv:room_for_item("main", paperella_item_name) then
				inv:add_item("main", paperella_item_name)
			else
				minetest.add_item(self.object:get_pos(), paperella_item_name)
			end
		end
	end
end

function paperella.on_step(self, dtime)
	if self.removed then
		return
	end

	local current_velocity = self.object:get_velocity()

	-- Recupera la velocità orizzontale mantenendo il segno.
	self.v = get_v(current_velocity) * get_sign(self.v)

	-- Controlli del giocatore.
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

		-- Animazione del giocatore quando è attaccato alla papera.
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

	-- Attrito.
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

	-- Controlla la parte inferiore della papera rispetto all'acqua.
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
		-- Controlla il nodo sopra la papera per capire quanto è immersa.
		local upper_water_pos = {
			x = pos.x,
			y = pos.y + 0.5,
			z = pos.z
		}

		if is_water(upper_water_pos) then
			-- Completamente/quasi completamente immersa:
			-- maggiore spinta verso l'alto.
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
			-- Galleggiamento sulla superficie.
			new_acce = {x = 0, y = 0, z = 0}

			if math.abs(current_velocity.y) < 1 then
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

minetest.register_entity(paperella_ent_name, paperella)

minetest.register_craftitem(paperella_item_name, {
	description = S("Inflatable Duck"),
	inventory_image = "paperella_inv.png",
	wield_image = "paperella_inv.png",
	wield_scale = {x = 2, y = 2, z = 1},
	liquids_pointable = true,

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end

		-- In acqua: crea la papera galleggiante.
		if is_water(pointed_thing.under) then
			local pos = {
				x = pointed_thing.under.x,
				y = pointed_thing.under.y + WATER_OFFSET,
				z = pointed_thing.under.z
			}

			minetest.add_entity(pos, paperella_ent_name)

			if not minetest.settings:get_bool("creative_mode") then
				itemstack:take_item()
			end

			return itemstack
		end

		return itemstack
	end,
})



if minetest.get_modpath("cannabis") then
	minetest.register_craft({
		output = paperella_item_name,
		recipe = {
			{"", "", ""},
			{"cannabis:canapa_plastic", "wool:yellow", "cannabis:canapa_plastic"},
			{"cannabis:canapa_cloth", "cannabis:canapa_plastic", "cannabis:canapa_cloth"},
		},
	})
else
	minetest.register_craft({
		output = paperella_item_name,
		recipe = {
			{"group:leaves", "default:paper", "group:leaves"},
			{"default:paper", "wool:yellow", "default:paper"},
			{"group:leaves", "default:paper", "group:leaves"},
		},
	}) 
end


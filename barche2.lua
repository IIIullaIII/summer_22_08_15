-- barche.lua
-- Boats with seats, engine start/stop, idle loop, accel/decel sounds, and crew formspec
-- Visible strings wrapped with S() for translation
local S = summer.S

local player_boat = {}

-- Unique ID counter and registry for boats
local next_boat_id = 0
local boats_by_id = {}

local function generate_boat_id()
	next_boat_id = next_boat_id + 1
	return next_boat_id
end

-- Sound timing constants (match your samples)
local ENGINE_START_DURATION = 0.8 -- seconds (boat_engine_start.ogg)
local ENGINE_STOP_DURATION  = 0.8 -- seconds (boat_engine_stop.ogg)

-- Helpers
local function is_water(pos)
	local nn = minetest.get_node(pos).name
	return minetest.get_item_group(nn, "water") ~= 0
end

local function get_sign(i)
	if i == 0 then return 0 end
	return i / math.abs(i)
end

local function get_velocity(v, yaw, y)
	local x = -math.sin(yaw) * v
	local z = math.cos(yaw) * v
	return {x = x, y = y, z = z}
end

local function get_v(v)
	return math.sqrt((v.x or 0) ^ 2 + (v.z or 0) ^ 2)
end

-- Invisible seat entity used as attach pivot
minetest.register_entity("summer:boat_seat", {
	initial_properties = {
		visual = "sprite",
		textures = {"invisible.png"},
		collisionbox = {0, 0, 0, 0, 0, 0},
		pointable = false,
	},
	physical = false,
	on_activate = function(self, staticdata)
		if self.object and self.object.set_armor_groups then
			self.object:set_armor_groups({immortal = 1})
		end
	end,
})

local function reg_barca(color)
	local barca_item_name = "summer:barca2_"..color.."_item"
	local barca_ent_name = "summer:barca2_"..color

	local barca = {
		physical = true,
		collisionbox = {-2.5, -1.0, -2.5, 2.5, 0.3, 2.5},
		visual = "mesh",
		mesh = "barca2.x",
		textures = {"barca2_"..color..".png"},
		use_texture_alpha = true,

		driver = nil,
		passengers = {},

		owner = nil,
		boat_id = nil,

		engine_on = false,

		v = 0,
		last_v = 0,
		removed = false,

		seat_objects = {},
		player_seat = {},

		-- runtime sound handles / flags
		_engine_sound_handle = nil, -- idle loop handle
		_accel_sound_handle = nil,  -- not used for loop in final design (one-shots)
		_is_accelerating = false,
		_last_accel_us = 0,
		_last_decel_us = 0,
	}

	-- Seat offsets
	local SEATS = {
		[1] = { x = -10,  y = 2,  z = 4 },
		[2] = { x = 10,   y = 2,  z = 4 },
		[3] = { x = -8,   y = 2,  z = -16 },
		[4] = { x = 8,    y = 2,  z = -16 },
	}

	local EYE_OFFSETS = {
		[1] = { eye = { x = 0,  y = 3, z = 0  },  camera = { x = 0, y = 0, z = 0 } },
		[2] = { eye = { x = 0,  y = 5, z = 0  },  camera = { x = 0, y = 0, z = 0 } },
		[3] = { eye = { x = 0,  y = 5, z = 0  },  camera = { x = 0, y = 0, z = 0 } },
		[4] = { eye = { x = 0,  y = 5, z = 0  },  camera = { x = 0, y = 0, z = 0 } },
	}

	local function clear_player_boat(player)
		if not player or not player:is_player() then return end
		player_boat[player:get_player_name()] = nil
	end

	local function set_player_boat(self, player)
		if not player or not player:is_player() then return end
		player_boat[player:get_player_name()] = self.object
	end

	local function remove_seats_near(pos, radius, boat_id)
		if not pos then return 0 end
		radius = radius or 32
		local removed = 0
		for _, obj in ipairs(minetest.get_objects_inside_radius(pos, radius)) do
			local ok, lua = pcall(function() return obj:get_luaentity() end)
			if ok and lua and lua.name == "summer:boat_seat" then
				if (not boat_id) or lua.boat_id == boat_id then
					pcall(function()
						local att = obj:get_attach()
						if att then obj:set_detach() end
					end)
					pcall(function() obj:remove() end)
					removed = removed + 1
				end
			end
		end
		minetest.log("action", string.format("[boat] remove_seats_near: removed %d seats near %.2f,%.2f,%.2f (r=%d, boat_id=%s)", removed, pos.x, pos.y, pos.z, radius, tostring(boat_id)))
		return removed
	end

	local function remove_own_seats(self)
		for i = 1, 4 do
			local seat_obj = self.seat_objects and self.seat_objects[i]
			if seat_obj then
				pcall(function()
					if seat_obj:get_attach() then seat_obj:set_detach() end
				end)
				pcall(function() seat_obj:remove() end)
			end
		end
		self.seat_objects = {}
	end

	local function ensure_seats(self)
		for i = 1, 4 do
			if not self.seat_objects[i] or not self.seat_objects[i]:get_luaentity() then
				local pos = self.object and self.object:getpos() or {x=0,y=0,z=0}
				local seat_obj = minetest.add_entity(pos, "summer:boat_seat")
				self.seat_objects[i] = seat_obj

				local seat_le = seat_obj and seat_obj:get_luaentity()
				if seat_le then
					seat_le.boat_id = self.boat_id
				end

				local off = SEATS[i]
				if seat_obj and seat_le and self.object and self.object:get_luaentity() then
					seat_obj:set_attach(self.object, "", { x = off.x, y = off.y, z = off.z }, { x = 0, y = 0, z = 0 })
				end
			end
		end
	end

	local function attach_player(self, player, seat)
		if not player or not player:is_player() then return end
		local offset = SEATS[seat]
		if not offset then return end

		local pname = player:get_player_name()
		local assigned = player_boat[pname]
		if assigned and self.object and assigned ~= self.object then
			minetest.log("warning", "[boat] attach_player: '" .. pname .. "' is assigned to another boat, abort attach for safety")
			return
		end

		if not self.seat_objects then self.seat_objects = {} end
		if not self.player_seat then self.player_seat = {} end

		if player:get_attach() then player:set_detach() end

		self.player_seat[player:get_player_name()] = seat

		set_player_boat(self, player)

		local seat_obj = self.seat_objects[seat]

		if seat_obj and seat_obj:get_luaentity() then
			player:set_attach(seat_obj, "", { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 })
		else
			if self.object and self.object:get_luaentity() then
				player:set_attach(self.object, "", { x = offset.x, y = offset.y, z = offset.z }, { x = 0, y = 0, z = 0 })
			end
		end

		local eo = EYE_OFFSETS[seat]
		if eo then
			player:set_eye_offset(eo.eye, eo.camera)
		else
			player:set_eye_offset({ x = 0, y = 1.6, z = 0 }, { x = 0, y = 0, z = 0 })
		end

		default.player_attached[player:get_player_name()] = true

		minetest.after(0.2, function()
			if player and player:is_player() then
				default.player_set_animation(player, "sit", 30)
			end
		end)
	end

	local function detach_player(self, player)
		if not player or not player:is_player() then return end
		local name = player:get_player_name()

		player:set_detach()

		if player_boat[name] == self.object then
			clear_player_boat(player)
		end

		if self.player_seat then
			self.player_seat[name] = nil
		end

		player:set_eye_offset({ x = 0, y = 0.2, z = 0 }, { x = 0, y = 0, z = 0 })

		default.player_attached[name] = false

		default.player_set_animation(player, "stand", 30)

		minetest.after(0.1, function()
			if not player or not player:is_player() then return end
			local pos = player:getpos()
			player:setpos({ x = pos.x, y = pos.y + 0.2, z = pos.z })
		end)
	end

	local function reorganize_players(self)
		if self.removed then return end

		local players = {}
		if self.driver then table.insert(players, self.driver) end
		for _, player in ipairs(self.passengers) do
			if player and player:is_player() then table.insert(players, player) end
		end

		self.driver = players[1]
		self.passengers = {}
		for i = 2, #players do table.insert(self.passengers, players[i]) end

		ensure_seats(self)

		for i, player in ipairs(players) do
			if player and player:is_player() then
				player:set_detach()
				attach_player(self, player, i)
			end
		end
	end

	local function remove_driver(self)
		if not self.driver then return end
		local old_driver = self.driver
		self.driver = nil
		detach_player(self, old_driver)
		if #self.passengers > 0 then
			self.driver = table.remove(self.passengers, 1)
		end
		reorganize_players(self)
	end

	local function remove_passenger(self, player)
		for i, passenger in ipairs(self.passengers) do
			if passenger == player then
				table.remove(self.passengers, i)
				detach_player(self, player)
				reorganize_players(self)
				return true
			end
		end
		return false
	end

	local function promote_passenger(self, player_name)
		for i, p in ipairs(self.passengers) do
			if p and p:is_player() and p:get_player_name() == player_name then
				local new_driver = table.remove(self.passengers, i)
				if self.driver then table.insert(self.passengers, 1, self.driver) end
				self.driver = new_driver
				reorganize_players(self)
				return true
			end
		end
		return false
	end

	local function kick_passenger(self, player_name)
		for _, p in ipairs(self.passengers) do
			if p and p:is_player() and p:get_player_name() == player_name then
				return remove_passenger(self, p)
			end
		end
		return false
	end

	-- Start engine: play ramp-up sample then start idle loop
	local function start_engine(self)
		if self.engine_on or self._engine_starting then return end
		if self._engine_stopping then self._engine_stopping = nil end

		self._engine_starting = true

		-- play ramp-up (one-shot)
		pcall(function()
			minetest.sound_play("boat_engine_start", {pos = self.object:getpos(), gain = 1.0, max_hear_distance = 24})
		end)

		-- after the start sample finishes, set engine_on and start idle loop
		minetest.after(ENGINE_START_DURATION, function()
			if not self or not self.object or self._engine_stopping then
				self._engine_starting = nil
				return
			end
			self.engine_on = true
			self._engine_starting = nil

			-- start idle loop
			if not self._engine_sound_handle then
				pcall(function()
					local handle = minetest.sound_play("boat_idle", {pos = self.object:getpos(), loop = true, gain = 0.6, max_hear_distance = 24})
					if handle then self._engine_sound_handle = handle end
				end)
			end
		end)
	end

	-- Stop engine: stop idle loop then play ramp-down sample and disable controls
	local function stop_engine(self)
		if (not self.engine_on and not self._engine_starting) or self._engine_stopping then return end
		if self._engine_starting then self._engine_starting = nil end

		self._engine_stopping = true

		-- disable controls immediately
		self.engine_on = false

		-- zero speed immediately
		self.v = 0
		pcall(function() if self.object then self.object:setvelocity({x=0,y=0,z=0}) end end)

		-- stop accel state & timers
		self._is_accelerating = false
		self._last_accel_us = 0

		-- stop idle loop immediately
		if self._engine_sound_handle then
			pcall(function() minetest.sound_stop(self._engine_sound_handle) end)
			self._engine_sound_handle = nil
		end

		-- play ramp-down (one-shot)
		pcall(function()
			minetest.sound_play("boat_engine_stop", {pos = self.object:getpos(), gain = 1.0, max_hear_distance = 24})
		end)

		minetest.after(ENGINE_STOP_DURATION, function()
			if not self then return end
			self._engine_stopping = nil
		end)
	end

	-- Crew formspec: only Turn On / Turn Off and brief instruction
	local function show_boat_menu(self, player)
		if not self.boat_id then return end
		local formname = "summer:boat_menu_" .. tostring(self.boat_id)

		local width, height = 6.8, 4.6
		local bg_image = "summer_chest_bg.png" -- put in summer/textures/

		local formspec = {
			"formspec_version[4]",
			string.format("size[%.1f,%.1f]", width, height),
			string.format("image[0,0;%.1f,%.1f;%s]", width, height, bg_image),
			"label[0.4,0.4;" .. S("Crew management") .. "]",
		}

		table.insert(formspec, string.format("button[0.4,1.0;2.8,0.7;engine_on_%d;%s]", self.boat_id, S("Turn On")))
		table.insert(formspec, string.format("button[3.0,1.0;2.8,0.7;engine_off_%d;%s]", self.boat_id, S("Turn Off")))

		table.insert(formspec, "label[0.4,2.1;" .. S("Use W / Up to accelerate and S / Down to brake when engine is ON.") .. "]")

		table.insert(formspec, "button_exit[2.3,3.6;2.2,0.7;close;" .. S("Close") .. "]")

		minetest.show_formspec(player:get_player_name(), formname, table.concat(formspec, ""))
	end

	-- Rightclick: show menu if driver else boarding
	function barca.on_rightclick(self, clicker)
		if not clicker or not clicker:is_player() then return end

		local name = clicker:get_player_name()
		local assigned_boat = player_boat[name]
		if assigned_boat and assigned_boat ~= self.object then return end

		local attached = clicker:get_attach()
		local attached_to_own_boat = false
		if attached then
			if attached == self.object then
				attached_to_own_boat = true
			else
				for i = 1, 4 do
					if self.seat_objects[i] == attached then
						attached_to_own_boat = true
						break
					end
				end
			end
		end

		if attached and not attached_to_own_boat then return end

		if self.driver == clicker then
			show_boat_menu(self, clicker)
			return
		end

		for _, passenger in ipairs(self.passengers) do
			if passenger == clicker then return end
		end

		if not self.driver then
			self.driver = clicker
			set_player_boat(self, clicker)
			attach_player(self, clicker, 1)
			if clicker.get_look_horizontal then
				self.object:setyaw(clicker:get_look_horizontal() - math.pi / 2)
			else
				self.object:setyaw(clicker:get_look_yaw() - math.pi / 2)
			end
			return
		end

		if #self.passengers >= 3 then
			minetest.chat_send_player(name, S("The boat is full!"))
			return
		end

		table.insert(self.passengers, clicker)
		set_player_boat(self, clicker)
		reorganize_players(self)
	end

	-- Activation: initialize instance tables and restore saved state
	function barca.on_activate(self, staticdata, dtime_s)
		self.passengers = {}
		self.seat_objects = {}
		self.player_seat = {}

		self.driver = nil
		self.owner = nil
		self.boat_id = nil
		self.v = 0
		self.last_v = 0
		self.removed = false
		self.engine_on = false
		self._engine_sound_handle = nil
		self._accel_sound_handle = nil
		self._last_accel_us = 0
		self._last_decel_us = 0
		self._engine_starting = nil
		self._engine_stopping = nil
		self._is_accelerating = false

		self.object:set_armor_groups({ immortal = 1 })

		local data = {}
		if staticdata and staticdata ~= "" then
			local ok, parsed = pcall(minetest.deserialize, staticdata)
			if ok and type(parsed) == "table" then
				data = parsed
			else
				data.v = tonumber(staticdata)
			end
		end

		self.v = tonumber(data.v) or 0
		self.last_v = self.v
		self.owner = data.owner
		self.engine_on = data.engine_on or false

		self.boat_id = data.boat_id or generate_boat_id()
		if self.boat_id >= next_boat_id then next_boat_id = self.boat_id + 1 end
		boats_by_id[self.boat_id] = self.object

		ensure_seats(self)

		-- If engine_on was saved, attempt to start idle (safe)
		if self.engine_on then
			pcall(function()
				local handle = minetest.sound_play("boat_idle", {pos = self.object:getpos(), loop = true, gain = 0.6, max_hear_distance = 24})
				if handle then self._engine_sound_handle = handle end
			end)
		end
	end

	-- Deactivate: stop sounds and clear registry
	function barca.on_deactivate(self)
		if self._accel_sound_handle then
			pcall(function() minetest.sound_stop(self._accel_sound_handle) end)
			self._accel_sound_handle = nil
			self._is_accelerating = false
		end
		if self._engine_sound_handle then
			pcall(function() minetest.sound_stop(self._engine_sound_handle) end)
			self._engine_sound_handle = nil
		end
		if self.boat_id and boats_by_id[self.boat_id] == self.object then
			boats_by_id[self.boat_id] = nil
		end
	end

	-- Save state
	function barca.get_staticdata(self)
		return minetest.serialize({ v = self.v, boat_id = self.boat_id, owner = self.owner, engine_on = self.engine_on })
	end

	-- Punch: disembark or remove (owner-only when empty)
	function barca.on_punch(self, puncher)
		if not puncher or not puncher:is_player() or self.removed then return end

		if self.driver == puncher then
			remove_driver(self)
		else
			remove_passenger(self, puncher)
		end

		if not self.driver then
			local puncher_name = puncher:get_player_name()
			local is_owner = (not self.owner) or (puncher_name == self.owner)

			if not is_owner then
				minetest.chat_send_player(puncher_name, S("Only the owner can remove this boat."))
				return
			end

			self.removed = true

			for _, passenger in ipairs(self.passengers) do
				if passenger and passenger:is_player() then
					clear_player_boat(passenger)
					passenger:set_detach()
					default.player_attached[passenger:get_player_name()] = false
				end
			end

			self.passengers = {}

			remove_own_seats(self)

			-- stop engine & accel loops if running
			self._is_accelerating = false
			self._last_accel_us = 0
			if self._engine_sound_handle then
				pcall(function() minetest.sound_stop(self._engine_sound_handle) end)
				self._engine_sound_handle = nil
			end

			if self.boat_id and boats_by_id[self.boat_id] == self.object then
				boats_by_id[self.boat_id] = nil
			end

			minetest.after(0.1, function()
				if self.object and self.object:get_luaentity() then
					self.object:remove()
				end
			end)

			if not minetest.setting_getbool("creative_mode") then
				local inv = puncher:get_inventory()
				if inv:room_for_item("main", barca_item_name) then
					inv:add_item("main", barca_item_name)
				else
					minetest.add_item(self.object:getpos(), barca_item_name)
				end
			end
		end
	end

	-- Sneak checking and cleanup
	local function check_sneak(self)
		if self.driver and self.driver:is_player() then
			local ctrl = self.driver:get_player_control()
			if ctrl.sneak then
				remove_driver(self)
				return
			end
		end

		local changed = false
		for i = #self.passengers, 1, -1 do
			local passenger = self.passengers[i]
			if passenger and passenger:is_player() then
				local ctrl = passenger:get_player_control()
				if ctrl.sneak then
					remove_passenger(self, passenger)
					return
				end
			else
				table.remove(self.passengers, i)
				changed = true
			end
		end

		if changed then reorganize_players(self) end
	end

	-- on_step: movement, engine idle, accel/decel one-shots (repeated), steering
	function barca.on_step(self, dtime)
		check_sneak(self)

		self.v = get_v(self.object:getvelocity()) * get_sign(self.v)

		-- Ensure idle loop presence when engine_on
		if self.engine_on then
			if not self._engine_sound_handle then
				pcall(function()
					local handle = minetest.sound_play("boat_idle", {pos = self.object:getpos(), loop = true, gain = 0.6, max_hear_distance = 24})
					if handle then self._engine_sound_handle = handle end
				end)
			end
		else
			if self._engine_sound_handle then
				pcall(function() minetest.sound_stop(self._engine_sound_handle) end)
				self._engine_sound_handle = nil
			end
		end

		-- player controls
		local ctrl = nil
		if self.driver and self.driver.is_player and self.driver:is_player() then
			ctrl = self.driver:get_player_control()
		end

		-- steering (left/right) allowed even with engine off (you can tweak)
		if ctrl then
			local yaw = self.object:getyaw()
			if ctrl.left then
				if self.v < 0 then
					self.object:setyaw(yaw - (1 + dtime) * 0.03)
				else
					self.object:setyaw(yaw + (1 + dtime) * 0.03)
				end
			elseif ctrl.right then
				if self.v < 0 then
					self.object:setyaw(yaw + (1 + dtime) * 0.03)
				else
					self.object:setyaw(yaw - (1 + dtime) * 0.03)
				end
			end
		end

		-- Accel/brake only when engine is ON
		local accel_pressed = ctrl and ctrl.up and self.engine_on
		local brake_pressed = ctrl and ctrl.down and self.engine_on

		local accel_rate = 0.15
		local brake_rate = 0.2
		local max_forward = 5
		local max_reverse = -2.5

		-- ACCELERATION: produce repeated one-shot 'boat_accel' while holding forward.
		if accel_pressed then
			-- increase speed
			self.v = math.min(self.v + accel_rate, max_forward)

			-- mark accel state
			if not self._is_accelerating then
				self._is_accelerating = true
			end

			-- compute repetition interval and adaptive gain based on speed fraction
			local speed_frac = 0
			if max_forward > 0 then speed_frac = math.max(0, math.min(self.v / max_forward, 1)) end
			local min_us = 60000    -- 60 ms
			local max_us = 180000   -- 180 ms
			local interval = math.floor(max_us - (max_us - min_us) * speed_frac)

			local base_gain = 0.8
			local gain = base_gain + 0.6 * speed_frac

			local us = minetest.get_us_time()
			if (not self._last_accel_us) or (us - self._last_accel_us >= interval) then
				self._last_accel_us = us
				pcall(function()
					minetest.sound_play("boat_accel", {pos = self.object:getpos(), gain = gain, max_hear_distance = 24})
				end)
			end
		else
			-- release forward: if we were accelerating, play decel one-shot
			if self._is_accelerating then
				self._is_accelerating = false
				self._last_accel_us = 0
				pcall(function()
					minetest.sound_play("boat_decel", {pos = self.object:getpos(), gain = 1.0, max_hear_distance = 24})
				end)
			end
		end

		-- BRAKE / REVERSE
		if brake_pressed then
			-- ensure accel state stopped
			if self._is_accelerating then
				self._is_accelerating = false
				self._last_accel_us = 0
			end

			-- decrease speed toward reverse cap
			self.v = math.max(self.v - brake_rate, max_reverse)

			-- decel sound debounce (use microseconds)
			local now = minetest.get_us_time()
			if (not self._last_decel_us) or (now - self._last_decel_us >= 300000) then -- 300 ms
				self._last_decel_us = now
				pcall(function()
					minetest.sound_play("boat_decel", {pos = self.object:getpos(), gain = 1.0, max_hear_distance = 24})
				end)
			end
		end

		-- natural friction when no input
		if not accel_pressed and not brake_pressed then
			local s = get_sign(self.v)
			if s ~= 0 then
				self.v = self.v - 0.02 * s
			end
		end

		-- clamp tiny velocities to zero
		if math.abs(self.v) < 0.01 then self.v = 0 end
		if self.v > max_forward then self.v = max_forward end
		if self.v < max_reverse then self.v = max_reverse end

		-- If fully stopped physically, early return
		local velo = self.object:getvelocity()
		if self.v == 0 and velo.x == 0 and velo.y == 0 and velo.z == 0 then
			self.object:setpos(self.object:getpos())
			return
		end

		-- Water / vertical handling (unchanged)
		local p = self.object:getpos()
		p.y = p.y - 0.5

		local new_velo = { x = 0, y = 0, z = 0 }
		local new_acce = { x = 0, y = 0, z = 0 }

		if not is_water(p) then
			local nodedef = minetest.registered_nodes[minetest.get_node(p).name]
			if (not nodedef) or nodedef.walkable then
				self.v = 0
				new_acce = { x = 0, y = 2, z = 0 }
			else
				new_acce = { x = 0, y = -1.8, z = 0 }
			end
			new_velo = get_velocity(self.v, self.object:getyaw(), self.object:getvelocity().y)
			self.object:setpos(self.object:getpos())
		else
			p.y = p.y + 1
			if is_water(p) then
				local y = self.object:getvelocity().y
				if y >= 7 then y = 7
				elseif y < 0 then new_acce = { x = 0, y = 50, z = 0 }
				else new_acce = { x = 0, y = 7, z = 0 } end
				new_velo = get_velocity(self.v, self.object:getyaw(), y)
				self.object:setpos(self.object:getpos())
			else
				new_acce = { x = 0, y = 0, z = 0 }
				if math.abs(self.object:getvelocity().y) < 1 then
					local pos = self.object:getpos()
					pos.y = math.floor(pos.y) + 1.
					self.object:setpos(pos)
					new_velo = get_velocity(self.v, self.object:getyaw(), 0)
				else
					new_velo = get_velocity(self.v, self.object:getyaw(), self.object:getvelocity().y)
					self.object:setpos(self.object:getpos())
				end
			end
		end

		self.object:setvelocity(new_velo)
		self.object:setacceleration(new_acce)

		self.last_v = self.v
	end

	-- Expose helper methods for global handlers
	barca.promote_passenger = promote_passenger
	barca.kick_passenger = kick_passenger
	barca.show_boat_menu = show_boat_menu
	barca.ensure_seats = ensure_seats
	barca.start_engine = start_engine
	barca.stop_engine = stop_engine

	minetest.register_entity(barca_ent_name, barca)

	-- craftitem registration
	minetest.register_craftitem(barca_item_name, {
		description = S("Boat") .. " (" .. color .. ")",
		inventory_image = "barca2_" .. color .. "_inv.png",
		wield_image = "barca2_" .. color .. "_inv.png",
		wield_scale = { x = 2, y = 2, z = 1 },
		liquids_pointable = true,

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then return end
			if not is_water(pointed_thing.under) then return end
			pointed_thing.under.y = pointed_thing.under.y + 0.5

			local obj = minetest.add_entity(pointed_thing.under, barca_ent_name)
			if obj then
				local le = obj:get_luaentity()
				if le and placer and placer:is_player() then
					le.owner = placer:get_player_name()
				end
			end

			if not minetest.setting_getbool("creative_mode") then itemstack:take_item() end
			return itemstack
		end,
	})


end

-- Colors list
colors = {
	"black", "red", "green", "blue", "yellow", "violet", "orange", "white", "pink", "cyan", "magenta",
}

for _, color in ipairs(colors) do
	reg_barca(color)
	-- Alias per l'oggetto nell'inventario
	minetest.register_alias("summer:barca_" .. color, "summer:barca2_" .. color .. "_item") --compatibilita vecchia barca per server che gia avevano summer
	-- Alias per l'entità entità (la barca fisica in acqua)
	minetest.register_alias("summer:barca_" .. color .. "_entity", "summer:barca2_" .. color)  --compatibilita vecchia barca gia piazzata per server che gia avevano summer
end

-- Startup cleanup: remove orphan seats (T+1s and T+10s)
minetest.register_on_mods_loaded(function()
	local function cleanup_orphan_seats()
		local objs = minetest.get_objects_inside_radius({x=0,y=0,z=0}, 1e6)
		local removed = 0
		for _, obj in ipairs(objs) do
			local ok, le = pcall(function() return obj:get_luaentity() end)
			if not ok or not le or le.name ~= "summer:boat_seat" then goto cont end

			local attached = nil
			pcall(function() attached = obj:get_attach() end)

			local should_remove = false

			if not attached then
				should_remove = true
			else
				local boat_id = le.boat_id
				if not boat_id then
					should_remove = true
				else
					local mapped_obj = boats_by_id[boat_id]
					if not mapped_obj then
						should_remove = true
					else
						if mapped_obj ~= attached then should_remove = true end
					end
				end
			end

			if should_remove then
				pcall(function()
					if obj:get_attach() then obj:set_detach() end
					obj:remove()
				end)
				removed = removed + 1
			end

			::cont::
		end

		if removed > 0 then
			minetest.log("action", "[boat] startup: removed " .. tostring(removed) .. " orphan boat_seat entities")
		else
			minetest.log("action", "[boat] startup: no orphan boat_seat entities found")
		end
	end

	minetest.after(1, cleanup_orphan_seats)
	minetest.after(10, cleanup_orphan_seats)
end)

-- Debug listing (kept for testing)
minetest.register_on_mods_loaded(function()
	minetest.after(5, function()
		local objs = minetest.get_objects_inside_radius({x=0,y=0,z=0}, 1e6)
		local total = 0
		for _, obj in ipairs(objs) do
			local ok, le = pcall(function() return obj:get_luaentity() end)
			if not ok or not le or le.name ~= "summer:boat_seat" then goto cont end
			total = total + 1
			local boat_id = le.boat_id
			local attached = nil
			pcall(function() attached = obj:get_attach() end)
			local attached_name = "nil"
			if attached then
				local ok2, att_le = pcall(function() return attached:get_luaentity() end)
				if ok2 and att_le and att_le.name then
					attached_name = att_le.name .. " (le.boat_id: " .. tostring(att_le.boat_id) .. ")"
				else
					attached_name = tostring(attached)
				end
			end
			local mapped = boats_by_id[boat_id]
			minetest.log("action", string.format("[boat-debug] seat found: boat_id=%s attached=%s boats_by_id_has=%s", tostring(boat_id), attached_name, tostring(mapped and "yes" or "no")))
			::cont::
		end
		minetest.log("action", "[boat-debug] total summer:boat_seat found = " .. tostring(total))
	end)
end)

-- On leave: tidy mappings and regenerate seats if needed
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	local boat_obj = player_boat[name]

	player_boat[name] = nil

	if not boat_obj then return end

	local ok, le = pcall(function() return boat_obj:get_luaentity() end)
	if not ok or not le then return end

	if le.player_seat then le.player_seat[name] = nil end

	if le.driver and le.driver.get_player_name and le.driver:get_player_name() == name then
		local promoted = false
		for _, p in ipairs(le.passengers or {}) do
			if p and p:is_player() then
				pcall(function() if le.promote_passenger then le:promote_passenger(p:get_player_name()) end end)
				promoted = true
				break
			end
		end
		if not promoted then
			pcall(function() if player and player:is_player() then player:set_detach() end end)
			le.driver = nil
		end
	else
		pcall(function() if le.kick_passenger then le:kick_passenger(name) end end)
	end

	if le.passengers then
		for i = #le.passengers, 1, -1 do
			local p = le.passengers[i]
			if not p or not (p.is_player and p:is_player()) then table.remove(le.passengers, i) end
		end
	end
	if le.driver and not (le.driver.is_player and le.driver:is_player()) then le.driver = nil end

	pcall(function() if le.ensure_seats then le:ensure_seats() end end)
end)

-- Global formspec handler: Turn On / Turn Off only
minetest.register_on_player_receive_fields(function(player, formname, fields)
	local boat_id_str = formname:match("^summer:boat_menu_(%d+)$")
	if boat_id_str then
		local boat_id = tonumber(boat_id_str)
		local boat_obj = boats_by_id[boat_id]
		if not boat_obj or not boat_obj:get_luaentity() then return end
		local le = boat_obj:get_luaentity()

		-- only driver can use the menu
		if le.driver ~= player then return end

		for field in pairs(fields) do
			local toggle_on = field:match("^engine_on_(%d+)$")
			if toggle_on then
				pcall(function() if le.start_engine then le:start_engine() end end)
			end
			local toggle_off = field:match("^engine_off_(%d+)$")
			if toggle_off then
				pcall(function() if le.stop_engine then le:stop_engine() end end)
			end
		end

		return
	end
end)

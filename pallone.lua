local S = summer.S

local IDLE_LIMIT = 5

-- Asset audio richiesti:
--   summer_ball_kick.ogg
--   summer_ball_head.ogg
--   summer_ball_bounce.ogg
--   summer_ball_splash.ogg
-- Texture particella:
--   summer_ball_particle.png


-- FISICA PALLONE ESTIVO


local GRAVITY = -10

local GROUND_BOUNCE = 0.72
local WALL_BOUNCE = 0.78
local HEAD_BOUNCE = 0.82

local GROUND_FRICTION = 0.88
local AIR_FRICTION = 0.995

local KICK_SPEED = 8
local SNEAK_KICK_SPEED = 14

local STOP_SPEED = 0.15

local PLAYER_RADIUS = 2.0
local BALL_RADIUS = 0.5


-- PARTICELLE


local PARTICLE_KICK_AMOUNT = 8
local PARTICLE_HEAD_AMOUNT = 7
local PARTICLE_BOUNCE_AMOUNT = 5

local PARTICLE_COLORS = {
	black = "#202020",
	red = "#ff3030",
	green = "#35d05b",
	blue = "#3090ff",
	yellow = "#ffe33b",
	violet = "#b050ff",
	orange = "#ff8a30",
}

local function particle_texture(color, variant)
	local hex = PARTICLE_COLORS[color] or "#ffffff"
	local transforms = {
		kick = "^[transformR90",
		head = "^[transformR180",
		bounce = "^[transformR270",
	}
	return "summer_ball_particle.png^[colorize:" .. hex .. ":180"
		.. (transforms[variant] or "")
end

local function spawn_kick_particles(pos, color)
	minetest.add_particlespawner({
		amount = PARTICLE_KICK_AMOUNT,
		time = 0.08,

		minpos = {
			x = pos.x - 0.12,
			y = pos.y - 0.12,
			z = pos.z - 0.12
		},

		maxpos = {
			x = pos.x + 0.12,
			y = pos.y + 0.12,
			z = pos.z + 0.12
		},

		minvel = {
			x = -1.2,
			y = 0.1,
			z = -1.2
		},

		maxvel = {
			x = 1.2,
			y = 1.0,
			z = 1.2
		},

		minacc = {
			x = 0,
			y = -1.5,
			z = 0
		},

		maxacc = {
			x = 0,
			y = -0.5,
			z = 0
		},

		minexptime = 0.18,
		maxexptime = 0.35,

		minsize = 0.9,
		maxsize = 1.6,

		texture = particle_texture(color, "kick"),
		glow = 3,
	})
end

local function spawn_head_particles(pos, color)
	minetest.add_particlespawner({
		amount = PARTICLE_HEAD_AMOUNT,
		time = 0.08,

		minpos = {
			x = pos.x - 0.10,
			y = pos.y + 0.05,
			z = pos.z - 0.10
		},

		maxpos = {
			x = pos.x + 0.10,
			y = pos.y + 0.18,
			z = pos.z + 0.10
		},

		minvel = {
			x = -0.6,
			y = 0.4,
			z = -0.6
		},

		maxvel = {
			x = 0.6,
			y = 1.4,
			z = 0.6
		},

		minexptime = 0.15,
		maxexptime = 0.30,

		minsize = 0.7,
		maxsize = 1.3,

		texture = particle_texture(color, "head"),
		glow = 4,
	})
end

local function spawn_bounce_particles(pos, normal, color)
	-- Particelle orientate verso l'esterno della superficie.
	local spread = 0.8

	minetest.add_particlespawner({
		amount = PARTICLE_BOUNCE_AMOUNT,
		time = 0.06,

		minpos = {
			x = pos.x + normal.x * 0.15,
			y = pos.y + normal.y * 0.15,
			z = pos.z + normal.z * 0.15
		},

		maxpos = {
			x = pos.x + normal.x * 0.25,
			y = pos.y + normal.y * 0.25,
			z = pos.z + normal.z * 0.25
		},

		minvel = {
			x = normal.x * 0.5 - spread,
			y = normal.y * 0.5,
			z = normal.z * 0.5 - spread
		},

		maxvel = {
			x = normal.x * 1.2 + spread,
			y = normal.y * 1.2 + spread,
			z = normal.z * 1.2 + spread
		},

		minexptime = 0.12,
		maxexptime = 0.28,

		minsize = 0.55,
		maxsize = 1.05,

		texture = particle_texture(color, "bounce"),
		glow = 3,
	})
end


-- SUONI


local function play_ball_sound(name, pos, gain, pitch_min, pitch_max)
	minetest.sound_play(name, {
		pos = pos,
		max_hear_distance = 12,
		gain = gain or 1.0,
		pitch = pitch_min and pitch_max
			and (pitch_min + math.random() * (pitch_max - pitch_min))
			or 1.0,
	})
end


-- UTILITÀ


local function is_walkable(pos)
	local node = minetest.get_node_or_nil(pos)
	if not node then
		return false
	end

	local def = minetest.registered_nodes[node.name]
	return def and def.walkable
end

local function reflect_velocity(vel, normal, restitution)
	local dot =
		vel.x * normal.x +
		vel.y * normal.y +
		vel.z * normal.z

	if dot >= 0 then
		return vel
	end

	return {
		x = vel.x - (1 + restitution) * dot * normal.x,
		y = vel.y - (1 + restitution) * dot * normal.y,
		z = vel.z - (1 + restitution) * dot * normal.z,
	}
end

local function check_block_collision(pos, vel)
	local normals = {}
	local radius = BALL_RADIUS
	local eps = 0.05

	if vel.x > 0 then
		if is_walkable({
			x = pos.x + radius + eps,
			y = pos.y,
			z = pos.z
		}) then
			table.insert(normals, {x = -1, y = 0, z = 0})
		end
	elseif vel.x < 0 then
		if is_walkable({
			x = pos.x - radius - eps,
			y = pos.y,
			z = pos.z
		}) then
			table.insert(normals, {x = 1, y = 0, z = 0})
		end
	end

	if vel.z > 0 then
		if is_walkable({
			x = pos.x,
			y = pos.y,
			z = pos.z + radius + eps
		}) then
			table.insert(normals, {x = 0, y = 0, z = -1})
		end
	elseif vel.z < 0 then
		if is_walkable({
			x = pos.x,
			y = pos.y,
			z = pos.z - radius - eps
		}) then
			table.insert(normals, {x = 0, y = 0, z = 1})
		end
	end

	if vel.y < 0 then
		if is_walkable({
			x = pos.x,
			y = pos.y - radius - eps,
			z = pos.z
		}) then
			table.insert(normals, {x = 0, y = 1, z = 0})
		end
	elseif vel.y > 0 then
		if is_walkable({
			x = pos.x,
			y = pos.y + radius + eps,
			z = pos.z
		}) then
			table.insert(normals, {x = 0, y = -1, z = 0})
		end
	end

	return normals
end


-- REGISTRAZIONE PALLA


local function reg_ball(color)
	local ball_item_name = "summer:ball_" .. color .. "_item"
	local ball_ent_name = "summer:ball_" .. color .. "_entity"

	minetest.register_entity(ball_ent_name, {
		initial_properties = {
			physical = true,
			collide_with_objects = true,

			visual = "mesh",
			mesh = "ball.obj",
			textures = {"ball_" .. color .. ".png"},

			collisionbox = {
				-0.5, -0.5, -0.5,
				0.5, 0.5, 0.5
			},

			hp_max = 1000,
			pointable = true,
			glow = 10,
		},

		timer = 0,
		idle_time = 0,
		float_phase = 0,
		stabilized = false,

		roll_angle = 0,

		last_kick = 0,
		last_head_hit = 0,
		last_bounce = 0,

		on_step = function(self, dtime)
			self.timer = self.timer + dtime
			self.idle_time = self.idle_time + dtime

			if self.last_kick > 0 then
				self.last_kick = math.max(0, self.last_kick - dtime)
			end

			if self.last_head_hit > 0 then
				self.last_head_hit =
					math.max(0, self.last_head_hit - dtime)
			end

			if self.last_bounce > 0 then
				self.last_bounce =
					math.max(0, self.last_bounce - dtime)
			end

			local obj = self.object
			if not obj then
				return
			end

			local pos = obj:get_pos()
			if not pos then
				return
			end

			local vel = obj:get_velocity()

			local node = minetest.get_node_or_nil(pos)
			if not node then
				return
			end

			local node_def = minetest.registered_nodes[node.name]

			local in_liquid =
				node_def and node_def.liquidtype ~= "none"

			if in_liquid then
				self.float_phase =
					self.float_phase + dtime

				local oscill =
					math.sin(self.float_phase * 4) * 1.5

				obj:set_acceleration({
					x = 0,
					y = 4 + oscill,
					z = 0
				})

				vel.x = vel.x * 0.96
				vel.z = vel.z * 0.96

				vel.y = math.max(-2, math.min(3, vel.y))

				obj:set_velocity(vel)

				minetest.add_particle({
					pos = vector.add(pos, {
						x = 0,
						y = 0.3,
						z = 0
					}),

					velocity = {
						x = math.random(-2, 2) / 10,
						y = 0.2,
						z = math.random(-2, 2) / 10
					},

					expirationtime = 0.4,
					size = 2,
					texture = "summer_trail.png",
					glow = 8
				})
			else
				local gravity = {
					x = 0,
					y = GRAVITY,
					z = 0
				}

				if not vector.equals(
					obj:get_acceleration(),
					gravity
				) then
					obj:set_acceleration(gravity)
				end

				vel.x = vel.x * AIR_FRICTION
				vel.z = vel.z * AIR_FRICTION

				local normals =
					check_block_collision(pos, vel)

				local on_ground = false

				if #normals > 0 then
					for _, normal in ipairs(normals) do
						local restitution

						if normal.y > 0 then
							restitution = GROUND_BOUNCE
							on_ground = true
						else
							restitution = WALL_BOUNCE
						end

						vel =
							reflect_velocity(
								vel,
								normal,
								restitution
							)

						-- Particelle del rimbalzo.
						local impact_speed = math.abs(
							vel.x * normal.x +
							vel.y * normal.y +
							vel.z * normal.z
						)

						spawn_bounce_particles(
							pos,
							normal,
							color
						)

						if impact_speed > 1.2 and self.last_bounce <= 0 then
							local bounce_gain =
								math.min(0.95, 0.35 + impact_speed * 0.05)

							play_ball_sound(
								"summer_ball_bounce",
								pos,
								bounce_gain,
								0.90,
								1.10
							)

							self.last_bounce = 0.10
						end

						if normal.y > 0 then
							vel.x =
								vel.x * GROUND_FRICTION

							vel.z =
								vel.z * GROUND_FRICTION

							if math.abs(vel.y) < 1.0 then
								vel.y = 0
							end
						end

						self.idle_time = 0
						self.stabilized = false
					end

					obj:set_velocity(vel)
				end

				local horizontal_speed =
					math.sqrt(
						vel.x * vel.x +
						vel.z * vel.z
					)

				local total_speed =
					math.sqrt(
						vel.x * vel.x +
						vel.y * vel.y +
						vel.z * vel.z
					)

				if total_speed < STOP_SPEED then
					obj:set_velocity({
						x = 0,
						y = 0,
						z = 0
					})

					vel = {
						x = 0,
						y = 0,
						z = 0
					}
				end

				if self.idle_time >= IDLE_LIMIT then
					if not self.stabilized then
						obj:set_velocity({
							x = 0,
							y = 0,
							z = 0
						})

						obj:set_acceleration({
							x = 0,
							y = 0,
							z = 0
						})

						self.stabilized = true
					end
				else
					self.stabilized = false
				end

				-- Rotazione coerente con la velocità della palla.
				-- Funziona sia dopo un calcio/colpo di testa sia dopo
				-- un rimbalzo. L'asse di rotazione segue la direzione
				-- del movimento sul piano orizzontale.
				if horizontal_speed > 0.05 then
					local direction =
						math.atan2(vel.z, vel.x)

					local angular_speed =
						horizontal_speed / BALL_RADIUS

					if on_ground then
						self.roll_angle =
							self.roll_angle
							- angular_speed * dtime
					else
						self.roll_angle =
							self.roll_angle
							+ angular_speed * dtime * 0.85
					end

					-- Orientiamo l'asse della mesh verso la direzione
					-- di movimento, evitando la rotazione "al contrario"
					-- quando la palla viene calciata.
					obj:set_rotation({
						x = self.roll_angle * math.sin(direction),
						y = -direction,
						z = self.roll_angle * math.cos(direction)
					})
				elseif math.abs(vel.y) > 0.05 then
					-- Anche quando la palla sale/scende quasi verticalmente
					-- manteniamo una piccola rotazione visiva.
					self.roll_angle =
						self.roll_angle + dtime * 0.35

					obj:set_rotation({
						x = self.roll_angle,
						y = 0,
						z = self.roll_angle * 0.35
					})
				end
			end

			-- ======================================
			-- GIOCATORI
			-- ======================================

			local objs =
				minetest.get_objects_inside_radius(
					pos,
					PLAYER_RADIUS
				)

			-- ======================================
			-- COLPO DI TESTA / CALCIO
			-- ======================================

			-- Il colpo di testa viene controllato prima del calcio.
			-- Importante: la palla può essere già stata rallentata
			-- dalla collisione fisica con il player, quindi NON
			-- richiediamo più una velocità verticale negativa.
			if not in_liquid
				and self.last_head_hit <= 0 then

				for _, player in ipairs(objs) do
					if player:is_player() then
						local ppos = player:get_pos()

						local dx = pos.x - ppos.x
						local dz = pos.z - ppos.z

						local horizontal_distance =
							math.sqrt(dx * dx + dz * dz)

						-- Altezza approssimativa della testa del player.
						-- La fascia è volutamente abbastanza larga per
						-- intercettare anche la palla già appoggiata sopra.
						local head_center = ppos.y + 1.75
						local head_min = head_center - 0.45
						local head_max = head_center + 0.65

						local descending_or_stopped =
							vel.y <= 0.6

						if horizontal_distance < 0.80
							and pos.y >= head_min
							and pos.y <= head_max
							and descending_or_stopped then

							local look_dir =
								player:get_look_dir()

							-- Il colpo di testa manda la palla in avanti
							-- e leggermente verso l'alto.
							local head_horizontal = 6.0
							local head_up = 5.5

							obj:set_velocity({
								x = look_dir.x * head_horizontal,
								y = head_up,
								z = look_dir.z * head_horizontal
							})

							self.idle_time = 0
							self.stabilized = false
							self.last_head_hit = 0.35
							self.last_kick = 0.20

							spawn_head_particles(
								pos,
								color
							)

							play_ball_sound(
								"summer_ball_head",
								pos,
								0.9,
								0.96,
								1.08
							)

							break
						end
					end
				end
			end

			-- ======================================
			-- CALCIO
			-- ======================================

			-- Il calcio ora può avvenire solo quando la palla è
			-- nella zona delle gambe/piedi del player. Questo evita
			-- che una palla sopra la testa venga interpretata come calcio.
			if self.last_kick <= 0
				and self.last_head_hit <= 0
				and not in_liquid then

				local nearest_player = nil
				local nearest_distance = nil

				for _, obj2 in ipairs(objs) do
					if obj2:is_player() then
						local ppos = obj2:get_pos()

						local dx = pos.x - ppos.x
						local dz = pos.z - ppos.z

						local horizontal_distance =
							math.sqrt(dx * dx + dz * dz)

						-- Centro palla nella zona del piede.
						local relative_y = pos.y - ppos.y

						if horizontal_distance < 1.15
							and relative_y > -0.35
							and relative_y < 1.05 then

							local distance =
								math.sqrt(
									dx * dx +
									relative_y * relative_y +
									dz * dz
								)

							if not nearest_distance
								or distance < nearest_distance then

								nearest_player = obj2
								nearest_distance = distance
							end
						end
					end
				end

				if nearest_player then
					local control =
						nearest_player:get_player_control()

					local dir =
						nearest_player:get_look_dir()

					-- Evita di spedire la palla violentemente verso il
					-- terreno quando il player guarda completamente in basso.
					if dir.y < -0.45 then
						dir.y = -0.45
					end

					local speed =
						control.sneak
						and SNEAK_KICK_SPEED
						or KICK_SPEED

					local kick_velocity = {
						x = dir.x * speed,
						y = dir.y * speed,
						z = dir.z * speed
					}

					local new_velocity = {
						x = kick_velocity.x + vel.x * 0.20,
						y = kick_velocity.y + vel.y * 0.10,
						z = kick_velocity.z + vel.z * 0.20
					}

					obj:set_velocity(new_velocity)

					self.idle_time = 0
					self.stabilized = false
					self.last_kick = 0.15

					spawn_kick_particles(
						pos,
						color
					)

					play_ball_sound(
						"summer_ball_kick",
						pos,
						0.75,
						0.94,
						1.06
					)
				end
			end
		end,

		on_punch = function(self, puncher)
			if puncher and puncher:is_player() then
				local inv = puncher:get_inventory()

				if inv then
					inv:add_item(
						"main",
						ItemStack(ball_item_name)
					)

					self.object:remove()
				end
			end
		end,
	})

	
	-- ITEM
	

	minetest.register_craftitem(
		ball_item_name,
		{
			description =
				S("Summer Ball")
				.. " (" .. color .. ")",

			inventory_image =
				"summer_ball_"
				.. color
				.. "_inv.png",

			on_place = function(
				itemstack,
				placer,
				pointed_thing
			)
				local pos = pointed_thing.above

				local node =
					minetest.get_node_or_nil(pos)

				local in_liquid =
					node
					and minetest.registered_nodes[node.name]
					and minetest.registered_nodes[node.name].liquidtype ~= "none"

				if in_liquid then
					pos.y = pos.y + 0.2
				end

				local ent =
					minetest.add_entity(
						pos,
						ball_ent_name
					)

				if ent then
					ent:set_velocity({
						x = 0,
						y = -5,
						z = 0
					})

					local sound =
						in_liquid
						and "summer_ball_splash"
						or "summer_ball_kick"

					play_ball_sound(
						sound,
						pos,
						0.8,
						0.96,
						1.04
					)
				end

				itemstack:take_item()
				return itemstack
			end,
		}
	)

	
	-- RICETTA BASE
	

	minetest.register_craft({
		output = ball_item_name,

		recipe = {
			{
				"default:paper",
				"group:leaves",
				"default:paper"
			},

			{
				"group:leaves",
				"wool:" .. color,
				"group:leaves"
			},

			{
				"default:paper",
				"group:leaves",
				"default:paper"
			},
		},
	})

	
	-- RICETTA CANNABIS
	

	if minetest.get_modpath("cannabis") then
		minetest.register_craft({
			output = ball_item_name,

			recipe = {
				{
					"",
					"cannabis:canapa_plastic",
					""
				},

				{
					"cannabis:canapa_plastic",
					"wool:" .. color,
					"cannabis:canapa_plastic"
				},

				{
					"",
					"cannabis:canapa_plastic",
					""
				},
			},
		})
	end
end


-- COLORI


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
	reg_ball(color)
end

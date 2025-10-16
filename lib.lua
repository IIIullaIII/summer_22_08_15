-- summer/lib.lua
-- Libreria condivisa per oggetti galleggianti e altri effetti

local summer_lib = {}

-- Rileva se un nodo è liquido
function summer_lib.is_liquid(pos)
	local node = minetest.get_node_or_nil(pos)
	if not node then return false end
	local def = minetest.registered_nodes[node.name]
	return def and def.liquidtype ~= "none"
end

-- Calcola un impulso basato sulla direzione dello sguardo del giocatore
function summer_lib.get_push_vector(player, multiplier)
	if not player or not player:is_player() then return {x=0,y=0,z=0} end
	local dir = player:get_look_dir()
	local mul = player:get_player_control().sneak and 3 or 1
	return vector.multiply(dir, mul * multiplier)
end

-- Applica un suono in base al tipo di superficie
function summer_lib.play_surface_sound(pos, is_water)
	local sound = is_water and "summer_ball_splash" or "summer_ball_kick"
	minetest.sound_play(sound, { pos = pos, max_hear_distance = 10, gain = 1.0 })
end

-- Particelle di trail
function summer_lib.spawn_trail(pos)
	minetest.add_particle({
		pos = vector.add(pos, {x=0, y=0.3, z=0}),
		velocity = {x = math.random(-2, 2) / 10, y = 0.2, z = math.random(-2, 2) / 10},
		expirationtime = 0.4,
		size = 2,
		texture = "summer_trail.png",
		glow = 8
	})
end

-- Particelle d'impatto
function summer_lib.spawn_impact_particles(pos)
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

return summer_lib

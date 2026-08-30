--SPARABOLLE V1.0 BY IIIullaIII
 local S = summer.S
-- 1. REGISTRAZIONE DELL'ENTITÀ BOLLA
minetest.register_entity("summer:bolla", {
    initial_properties = {
        hp_max = 1,
        physical = false, 
        collide_with_objects = false, 
        collisionbox = {0, 0, 0, 0, 0, 0}, 
        visual = "sprite",
        visual_size = {x = 0.5, y = 0.5},
        textures = {"sparabolle_bubble.png"}, 
        glow = 8, 
    },

    timer = 0,
    lifetime = 6, 
    raggio_esplosione = 0.4, 

    on_activate = function(self, staticdata, dtime_s)
        local rand_size = 0.3 + (math.random() * 0.7)
        self.object:set_properties({
            visual_size = {x = rand_size, y = rand_size}
        })
        self.raggio_esplosione = rand_size * 0.7
        self.lifetime = 2.5 + (math.random() * 3.5)
    end,

    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        
        -- 1. Esplosione spontanea per limite di tempo
        if self.timer > self.lifetime then
            self:pop_effect()
            return
        end
        
        local pos = self.object:get_pos()
        if not pos then return end

        -- Immunità iniziale al tocco
        if self.timer > 0.5 then
            -- 2. Controllo contatto con i blocchi solidi
            local node = minetest.get_node_or_nil(pos)
            if node and node.name ~= "air" and minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].walkable then
                self:pop_effect()
                return
            end

            -- 3. Controllo contatto con Giocatori o altre Creature
            local oggetti_vicini = minetest.get_objects_inside_radius(pos, self.raggio_esplosione)
            for _, obj in ipairs(oggetti_vicini) do
                if obj ~= self.object then
                    self:pop_effect()
                    return
                end
            end
        end
        
        -- Movimento fluttuante reale (Effetto Aria)
        local vel = self.object:get_velocity()
        if vel then
            self.object:set_velocity({
                x = vel.x + (math.random() - 0.5) * 0.2,
                y = vel.y + (math.random() - 0.5) * 0.1, 
                z = vel.z + (math.random() - 0.5) * 0.2
            })
        end
    end,

    pop_effect = function(self)
        local pos = self.object:get_pos()
        if pos then
            minetest.add_particlespawner({
                amount = 12,
                time = 0.1,
                minpos = {x = pos.x - 0.1, y = pos.y - 0.1, z = pos.z - 0.1},
                maxpos = {x = pos.x + 0.1, y = pos.y + 0.1, z = pos.z + 0.1},
                minvel = {x = -2, y = -1, z = -2},
                maxvel = {x = 2, y = 2, z = 2},
                minacc = {x = 0, y = -4, z = 0},
                maxacc = {x = 0, y = -6, z = 0},
                minexptime = 0.1,
                maxexptime = 0.4,
                minsize = 0.5,
                maxsize = 1.5,
                texture = "sparabolle_bubble.png",
            })

            -- MODIFICA: Sceglie a caso tra due suoni di esplosione (summer_pop1 o summer_pop2)
            local suono_scelto = "summer_pop" .. math.random(1, 2)
            minetest.sound_play(suono_scelto, {pos = pos, gain = 0.6, max_hear_distance = 7}, true)
        end
        self.object:remove()
    end,
})

-- 2. REGISTRAZIONE DELLO STRUMENTO (SPARABOLLE MULTIPLO DISTANZIATO)
minetest.register_tool("summer:pistola", {
    description = S("Bubble Gun"),
    inventory_image = "sparabolle_gun.png", 
    
    on_use = function(itemstack, user, pointed_thing)
        if not user then return end
        
        local pos = user:get_pos()
        pos.y = pos.y + user:get_properties().eye_height
        local dir = user:get_look_dir()
        
        -- MODIFICA: Riproduce il suono dello sparo (summer_shoot) incentrato sul giocatore
        minetest.sound_play("summer_shoot", {pos = pos, gain = 0.7, max_hear_distance = 15}, true)
        
        local numero_bolle = 15 
        
        for i = 1, numero_bolle do
            local spread_x = (math.random() - 0.5) * 2.6
            local spread_y = (math.random() - 0.5) * 2.0
            local spread_z = (math.random() - 0.5) * 2.6
            
            local spawn_pos = {
                x = pos.x + dir.x * 2.8 + spread_x,
                y = pos.y + dir.y * 2.8 + spread_y,
                z = pos.z + dir.z * 2.8 + spread_z
            }
            
            local obj = minetest.add_entity(spawn_pos, "summer:bolla")
            
            if obj then
                local speed = 0.2 + (math.random() * 1.5)
                obj:set_velocity({
                    x = (dir.x + spread_x) * speed,
                    y = (dir.y + spread_y) * speed,
                    z = (dir.z + spread_z) * speed
                })
            end
        end
        
        return itemstack
    end,
})

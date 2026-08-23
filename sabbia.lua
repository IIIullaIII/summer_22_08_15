local S = summer.S

--_____ swap tool _____--
minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
    -- Verifica che sia un giocatore
    if not puncher or not puncher:is_player() then
        return
    end

    -- Verifica se il blocco colpito è un tipo di sabbia valido
    if node.name ~= "default:sand"
       and node.name ~= "default:silver_sand"
       and node.name ~= "default:desert_sand" then
        return
    end

    -- Controlla se il giocatore ha in mano il rastrello
    if puncher:get_wielded_item():get_name() ~= "summer:rake" then
        return
    end

    -- Controlla la protezione del blocco
    local player_name = puncher:get_player_name()

    if minetest.is_protected(pos, player_name) then
        -- Nessuna modifica alla sabbia
        return
    end

    -- Sostituisce il nodo
    minetest.set_node(pos, {name = "summer:sabbia_mare"})

    -- Suono udibile entro 5 nodi
    minetest.sound_play("summer_n_swap", {
        pos = pos,
        gain = 2.0,
        max_hear_distance = 5,
    })
end)


--_____ Sand _____--
minetest.register_node("summer:sabbia_mare", {
    description = S("Sea Sand"),
    tiles = {"sabbia_mare_2.png"},
    drop = "summer:sabbia_mare",
    groups = {
        crumbly = 3,
        falling_node = 1,
        sand = 1
    },
    sounds = default.node_sound_sand_defaults(),
})


--_____ Rake Tool _____--
minetest.register_tool("summer:rake", {
    description = S("Rake"),
    inventory_image = "rake.png",
})


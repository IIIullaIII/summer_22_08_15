local S = summer.S

local colors = {
    -- name = internal name, color = texture hex, dye = dye item for crafting
    {name = "blue",        color = "#2196F3", dye = "dye:blue"},
    {name = "red",         color = "#F44336", dye = "dye:red"},
    {name = "yellow",      color = "#FFEB3B", dye = "dye:yellow"},
    {name = "orange",      color = "#FF9800", dye = "dye:orange"},
    {name = "fuchsia",     color = "#E91E63", dye = "dye:magenta"},
    {name = "violet",      color = "#8E44AD", dye = "dye:violet"},
    {name = "black",       color = "#202020", dye = "dye:black"},
    {name = "light_green", color = "#7CFC00", dye = "dye:green"},
}

local summer_ladders = {}
local shadow_ladders = {}
local mapping = {}

local function texture(color)
    return "summer_slide_ladders.png^[colorize:" .. color .. ":255"
end

local nodebox = {
    type = "fixed",
    fixed = {
        {-0.5, 0.4375, 0.375, 0.5, 0.5, 0.5}, {-0.5, 0.3125, 0.375, 0.5, 0.375, 0.5},
        {-0.5, 0.1875, 0.375, 0.5, 0.25, 0.5}, {-0.5, 0.0625, 0.375, 0.5, 0.125, 0.5},
        {-0.5, -0.0625, 0.375, 0.5, 0, 0.5}, {-0.5, -0.1875, 0.375, 0.5, -0.125, 0.5},
        {-0.5, -0.3125, 0.375, 0.5, -0.25, 0.5}, {-0.5, -0.4375, 0.375, 0.5, -0.375, 0.5},
        {0.375, -0.5, 0.4375, 0.5, 0.5, 0.5}, {-0.5, -0.5, 0.4375, -0.375, 0.5, 0.5},
        {-0.5, -0.5, 0.0625, -0.375, 0.5, 0.125}, {0.375, -0.5, 0.0625, 0.5, 0.5, 0.125},
        {0.375, -0.5, 0.0625, 0.5, -0.4375, 0.5}, {0.375, 0.4375, 0.0625, 0.5, 0.5, 0.5},
        {-0.5, 0.4375, 0.0625, -0.375, 0.5, 0.5}, {-0.5, -0.5, 0.0625, -0.375, -0.4375, 0.5},
    },
}

for _, data in ipairs(colors) do
    local orig = "summer:slide_ladder_" .. data.name
    local shad = "summer:shadow_ladder_" .. data.name
    summer_ladders[orig] = true
    shadow_ladders[shad] = true
    mapping[orig] = shad
    mapping[shad] = orig

    -- Original Ladder (Climbable)
    minetest.register_node(orig, {
        description = S("Slipping Ladder ").. data.name..S(" >Use snake button for falling down< "),
        drawtype = "nodebox", 
        tiles = {texture(data.color)},
        paramtype = "light", 
        paramtype2 = "facedir",
        sunlight_propagates = true, walkable = true, climbable = true,
        node_box = nodebox, collision_box = nodebox, selection_box = nodebox,
        groups = { choppy = 2, oddly_breakable_by_hand = 2 },
        sounds = default.node_sound_wood_defaults(),
    })

    -- Crafting (Using explicit 3x3 grid, output and output_count)
    minetest.register_craft({
        recipe = {
            {"default:stick", "", "default:stick"},
            {"group:wood", data.dye, "default:stick"},
            {"default:stick", "", "default:stick"},
        },
        output =""..orig.." 5",
    
    })

    -- Shadow Ladde Not Climbable, Hidden from Creative
    minetest.register_node(shad, {
        description = S("Slipping Ladder >Use snake button for falling down<"),
        drawtype = "nodebox", 
        tiles = {texture(data.color)},
        paramtype = "light", 
        paramtype2 = "facedir",
        sunlight_propagates = true, walkable = true, climbable = false,
        node_box = nodebox, collision_box = nodebox, selection_box = nodebox,
        groups = { 
            choppy = 2, 
            oddly_breakable_by_hand = 2,
            not_in_creative_inventory = 1,
        },
        sounds = default.node_sound_wood_defaults(),
    })
end

local player_fall_velocity = {}

core.register_globalstep(function(dtime)
    for _, player in ipairs(core.get_connected_players()) do
        local name = player:get_player_name()
        local controls = player:get_player_control()
        if not controls then goto continue end

        local pos = player:get_pos()
        
        if controls.sneak then
            -- Create non-climbable tunnel below player to disable climbable friction
            for i = 0, 6 do
                local check_pos = {x = pos.x, y = pos.y - i, z = pos.z}
                local node = core.get_node(check_pos)
                if summer_ladders[node.name] then
                    core.set_node(check_pos, {
    name = mapping[node.name],
    param2 = node.param2,  --Save the rotation of the scale
})
                end
            end

            -- Gravity acceleration 
            if not player_fall_velocity[name] then player_fall_velocity[name] = 0 end
            player_fall_velocity[name] = player_fall_velocity[name] - 0.25 
            if player_fall_velocity[name] < -2.5 then player_fall_velocity[name] = -2.5 end

            local vel = player:get_velocity()
            player:set_velocity({x = vel.x, y = player_fall_velocity[name], z = vel.z})
        else
            -- Restore climbable nodes when sneak is released
            for i = -2, 8 do
                local restore_pos = {x = pos.x, y = pos.y + i, z = pos.z}
                local node = core.get_node(restore_pos)
                if shadow_ladders[node.name] then
                   core.set_node(restore_pos, {
    name = mapping[node.name],
    param2 = node.param2,  --Restore the rotation of the scale
})
                end
            end
            player_fall_velocity[name] = 0
        end
        
        ::continue::
    end
end)

minetest.register_on_leaveplayer(function(player)
    player_fall_velocity[player:get_player_name()] = nil
end)

local S = summer.S

local function safe_set_animation(player, anim_name, speed)
    if not player or not player:is_player() then
        return
    end

    local animations = {
        stand = {x = 0, y = 79},
        sit   = {x = 81, y = 160},
    }

    local anim = animations[anim_name]
    if not anim then
        return
    end

    if player.set_animation then
        pcall(function()
            player:set_animation(anim, speed or 30, 0, false)
        end)
        return
    end

    if default and default.player_set_animation then
        pcall(function()
            default.player_set_animation(player, anim_name, speed or 30)
        end)
    end
end

-- Box definitions
local top_box = {
    type = "fixed",
    fixed = {
        {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5}, 
        {0.375, -0.5, 0.25, 0.4375, 0.3125, 0.5},
        {-0.4375, -0.5, 0.25, -0.375, 0.3125, 0.5}, 
        {-0.4375, -0.5, -0.5, -0.375, 0.3125, -0.25}, 
        {0.375, -0.5, -0.5, 0.4375, 0.3125, -0.25}, 
        {0.3125, 0.25, -0.5, 0.5, 0.5, 0.5}, 
        {-0.5, 0.25, -0.5, -0.3125, 0.5, 0.5}, 
    }
}

local stop_box = {
    type = "fixed",
    fixed = {
        {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5},
        {0.4375, -0.5, -0.5, 0.5, -0.25, 0.5},
        {-0.5, -0.5, -0.5, -0.4375, -0.25, 0.5},
    }
}

local slope_box = {
    type = "fixed",
    fixed = {
        {-0.5, 0.25, 0.4375, 0.5, 0.5, 0.5},
        {-0.5, 0.25, 0.375, 0.5, 0.4375, 0.5},
        {-0.5, 0.25, 0.3125, 0.5, 0.375, 0.5},
        {-0.5, 0.25, 0.25, 0.5, 0.3125, 0.5},
        {-0.5, 0, 0.1875, 0.5, 0.25, 0.25},
        {-0.5, 0, 0.125, 0.5, 0.1875, 0.25},
        {-0.5, 0, 0.0625, 0.5, 0.125, 0.25},
        {-0.5, 0, 0, 0.5, 0.0625, 0.25},
        {-0.5, -0.25, -0.0625, 0.5, 0, 0},
        {-0.5, -0.25, -0.125, 0.5, -0.0625, 0},
        {-0.5, -0.25, -0.1875, 0.5, -0.125, 0},
        {-0.5, -0.25, -0.25, 0.5, -0.1875, 0},
        {-0.5, -0.5, -0.3125, 0.5, -0.25, -0.25},
        {-0.5, -0.5, -0.375, 0.5, -0.3125, -0.25},
        {-0.5, -0.5, -0.4375, 0.5, -0.375, -0.25},
        {-0.5, -0.5, -0.5, 0.5, -0.4375, -0.25},
        {0.4375, -0.5, -0.5, 0.5, -0.25, -0.25},
        {0.4375, -0.25, -0.25, 0.5, 0, 0},
        {0.4375, 0, 0, 0.5, 0.25, 0.25},
        {0.4375, 0.25, 0.25, 0.5, 0.5, 0.5},
        {-0.5, -0.5, -0.5, -0.4375, -0.25, -0.25},
        {-0.5, -0.25, -0.25, -0.4375, 0, 0},
        {-0.5, 0, 0, -0.4375, 0.25, 0.25},
        {-0.5, 0.25, 0.25, -0.4375, 0.5, 0.5},
    }
}

minetest.register_node("summer:scivolo_top", {
    description = S("Fence plane top"),
    tiles = {
        "summer_scivolo_top.png", "summer_scivolo_top.png", "summer_scivolo_top.png",
        "summer_scivolo_top.png", "summer_scivolo_top.png", "summer_scivolo_top.png"
    },
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    node_box = top_box,
    selection_box = top_box,
    groups = { cracky = 3, fall_damage_add_percent = -100 },
})

minetest.register_node("summer:scivolo", {
    description = S("Slide stop bottom"),
    tiles = {
        "summer_scivolo_top2.png", "summer_scivolo.png", "summer_scivolo.png",
        "summer_scivolo.png", "summer_scivolo.png", "summer_scivolo.png"
    },
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    node_box = stop_box,
    selection_box = stop_box,
    groups = { cracky = 3, fall_damage_add_percent = -100 },
})

minetest.register_node("summer:scivolo_slope", {
    description = S("Slide slope"),
    tiles = {
        "summer_scivolo_top2.png", "summer_scivolo.png", "summer_scivolo.png",
        "summer_scivolo.png", "summer_scivolo.png", "summer_scivolo_top2.png"
    },
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    node_box = slope_box,
    selection_box = slope_box,
    groups = { cracky = 3, fall_damage_add_percent = -100 },
})

local SIT_NODE = "summer:scivolo_slope"
local STAND_NODE = "summer:scivolo"

local slide_speed = {}
local last_anim = {}
local last_dir = {}

local ACCEL = 2.0
local MAX_SPEED = 3.0
local AIR_FRICTION = 0.98

local DIRS = {
    [0] = {x = 0, z = 1},
    [1] = {x = 1, z = 0},
    [2] = {x = 0, z = -1},
    [3] = {x = -1, z = 0},
}

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        if (not player) or (not player:is_player()) then
            goto next_player
        end

        local name = player:get_player_name()
        if (not name) or (name == "") then
            goto next_player
        end

        local pos = nil
        if (player.get_pos) then
            pos = player:get_pos()
        elseif (player.getpos) then
            pos = player:getpos()
        end
        if (not pos) then
            goto next_player
        end

        local ctrl = player:get_player_control()
        if (ctrl and ctrl.jump) then
            if (last_anim[name] ~= "stand") then
                safe_set_animation(player, "stand", 30)
                last_anim[name] = "stand"
            end
            slide_speed[name] = 0
            last_dir[name] = nil
            if (player.set_velocity) then
                local curv = nil
                if (player.get_player_velocity) then curv = player:get_player_velocity()
                elseif (player.get_velocity) then curv = player:get_velocity() end
                local keep_y = 0
                if (curv and type(curv) == "table" and curv.y) then keep_y = curv.y end
                player:set_velocity({ x = 0, y = keep_y, z = 0 })
            end
            goto next_player
        end

        local pos_feet = { x = pos.x, y = pos.y - 0.2, z = pos.z }
        local pos_below = { x = pos.x, y = pos.y - 1.0, z = pos.z }

        local node_feet = nil
        local node_below = nil
        if (minetest.get_node_or_nil) then
            node_feet = minetest.get_node_or_nil(pos_feet)
            node_below = minetest.get_node_or_nil(pos_below)
        else
            node_feet = minetest.get_node(pos_feet)
            node_below = minetest.get_node(pos_below)
        end

        local nodename = "air"
        if (node_feet and type(node_feet) == "table" and node_feet.name) then
            nodename = node_feet.name
        elseif (node_below and type(node_below) == "table" and node_below.name) then
            nodename = node_below.name
        else
            nodename = "air"
        end

        if (nodename == SIT_NODE) then
            if (last_anim[name] ~= "sit") then
                safe_set_animation(player, "sit", 30)
                last_anim[name] = "sit"
            end

            slide_speed[name] = (slide_speed[name] or 0) + (ACCEL * dtime)
            if (slide_speed[name] > MAX_SPEED) then slide_speed[name] = MAX_SPEED end

            local node_actual = nil
            if (node_feet and type(node_feet) == "table") then node_actual = node_feet
            elseif (node_below and type(node_below) == "table") then node_actual = node_below end

            local facedir = 0
            if (node_actual and node_actual.param2) then facedir = node_actual.param2 % 4 end

            local d = DIRS[facedir] or { x = 0, z = 1 }
            local dirx = -d.x
            local dirz = -d.z

            last_dir[name] = { x = dirx, z = dirz }

            local gravity_local = { x = dirx * 0.2, y = -2, z = dirz * 0.3 }
            local move = { x = dirx * slide_speed[name], y = 0, z = dirz * slide_speed[name] }

            if (player.add_velocity) then
                pcall(function() player:add_velocity(gravity_local) end)
                pcall(function() player:add_velocity(move) end)
            else
                if (player.set_velocity) then
                    local curv = nil
                    if (player.get_player_velocity) then curv = player:get_player_velocity()
                    elseif (player.get_velocity) then curv = player:get_velocity() end
                    local cur_y = 0
                    if (curv and type(curv) == "table" and curv.y) then cur_y = curv.y end
                    pcall(function() player:set_velocity({ x = move.x, y = cur_y + gravity_local.y, z = move.z }) end)
                end
            end

            goto next_player
        end

        if (nodename == STAND_NODE) then
            if (last_anim[name] ~= "stand") then
                safe_set_animation(player, "stand", 30)
                last_anim[name] = "stand"
            end

            slide_speed[name] = nil
            last_dir[name] = nil

            goto next_player
        end

        if (last_anim[name] == "sit") then
            if (nodename ~= "air") then
                safe_set_animation(player, "stand", 30)
                last_anim[name] = "stand"
                slide_speed[name] = nil
                last_dir[name] = nil
                goto next_player
            end

            local dir = last_dir[name]
            if (dir and slide_speed[name] and slide_speed[name] > 0) then
                slide_speed[name] = slide_speed[name] * (AIR_FRICTION ^ dtime)
                if (slide_speed[name] < 0.05) then
                    slide_speed[name] = 0
                end

                local gravity_local = { x = dir.x * 0.2, y = -2, z = dir.z * 0.15 }
                local move = { x = dir.x * slide_speed[name], y = 0, z = dir.z * slide_speed[name] }

                if (player.add_velocity) then
                    pcall(function() player:add_velocity(gravity_local) end)
                    pcall(function() player:add_velocity(move) end)
                elseif (player.set_velocity) then
                    local curv3 = nil
                    if (player.get_player_velocity) then curv3 = player:get_player_velocity()
                    elseif (player.get_velocity) then curv3 = player:get_velocity() end
                    local cur_y3 = 0
                    if (curv3 and type(curv3) == "table" and curv3.y) then cur_y3 = curv3.y end
                    pcall(function()
                        player:set_velocity({
                            x = move.x,
                            y = cur_y3 + gravity_local.y,
                            z = move.z
                        })
                    end)
                end
            end
        end

        ::next_player::
    end
end)

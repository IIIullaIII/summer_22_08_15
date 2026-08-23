--_____ Modern Colored Chests with Advanced Features _____--

local S = summer.S

local colors = { "red", "orange", "yellow", "green", "blue", "violet", "black" }

local open_chests = {} -- Track open chests for close sound

local function get_dir_vector(dir)
	if type(dir) == "table" then return dir end
	local dirs = {
		{x=0, y=1, z=0},  -- 0
		{x=0, y=-1, z=0}, -- 1
		{x=0, y=0, z=-1}, -- 2
		{x=0, y=0, z=1},  -- 3
		{x=-1, y=0, z=0}, -- 4
		{x=1, y=0, z=0},  -- 5
	}
	return dirs[dir + 1] or {x=0, y=0, z=0}
end

local function has_chest_privilege(meta, player, is_locked)
	local owner = meta:get_string("owner")
	if not is_locked then return true end
	if owner == "" then return false end
	return owner == player:get_player_name()
end

local function sort_inventory(inv, method)
	local list = inv:get_list("main")

	local full = {}
	local empty = {}
	for _, stack in ipairs(list) do
		if stack:is_empty() then
			table.insert(empty, stack)
		else
			table.insert(full, stack)
		end
	end

	table.sort(full, function(a, b)
		if method == "name" then
			return a:get_name() < b:get_name()
		elseif method == "item" then
			return a:get_description() < b:get_description()
		elseif method == "stack" then
			return a:get_count() > b:get_count()
		elseif method == "mod" then
			local am = a:get_name():match("^([^:]+):") or ""
			local bm = b:get_name():match("^([^:]+):") or ""
			return am < bm
		end
		return false
	end)

	for _, stack in ipairs(empty) do
		table.insert(full, stack)
	end

	inv:set_list("main", full)
end

local function get_chest_formspec(pos, meta, confirm_clear)
	local name = meta:get_string("custom_name") or S("Chest")
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z

	if confirm_clear then
		local line1 = minetest.colorize("#FF0000", S("WARNING:")) .. "\n"
		local line2 = S("Are you sure you want to clear the chest?") .. "\n"
		local line3 = minetest.colorize("#FF0000", S("THIS WILL DELETE ALL ITEMS IN THE CHEST FOREVER"))
		local full_warning = line1 .. line2 .. line3

		return "formspec_version[4]" ..
			"size[14,5.5]" ..
			"bgcolor[#080808BB;true]" ..
			"background[0,0;14,5.5;gui_formbg.png;true]" ..
			default.gui_slots ..
			"label[1,1.0;" .. full_warning .. "]" ..
			"button[2,4.0;3,1;confirm_clear_yes;" .. S("Yes") .. "]" ..
			"button[9,4.0;3,1;confirm_clear_no;" .. S("No") .. "]"
	end

	return "formspec_version[4]" ..
		"size[22,19.5]" ..
		"background[0,0;0,0;summer_chest_bg.png;true]" ..
		default.gui_slots ..
		"label[1.1,1.5;" .. minetest.colorize("#FFFF00", name) .. "]" ..
		"field[4.5,1.0;6,1;rename;" .. S("New name") .. ";]" ..
		"button[10.7,1.0;2,1;setname;" .. S("Rename") .. "]" ..
		"button[13.9,0.5;2,1;clear_all;" .. minetest.colorize("#FF0000", S("CLEAR")) .. "]" ..
		"button[16.1,0.5;2,1;sort_name;" .. S("Sort Name") .. "]" ..
		"button[18.3,0.5;2,1;sort_item;" .. S("Sort Item") .. "]" ..
		"button[16.1,1.7;2,1;sort_stack;" .. S("Sort Stack") .. "]" ..
		"button[18.3,1.7;2,1;sort_mod;" .. S("Sort Mod") .. "]" ..
		"list[nodemeta:" .. spos .. ";main;1.0,3.0;16,8;]" ..
		"list[current_player;main;3.0,13.8;8,1;]" ..
		"list[current_player;main;3.0,15.0;8,3;8]" ..
		"listring[nodemeta:" .. spos .. ";main]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(3.0,14.8)
end

local function close_chest_sound(player)
	local name = player:get_player_name()
	local data = open_chests[name]
	if data then
		minetest.sound_play("chest_close", {
			pos = data.pos,
			gain = 0.5,
			max_hear_distance = 8,
		})
		open_chests[name] = nil
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "summer:modern_chest_form" then return end

	local pos_str = player:get_meta():get_string("modern_chest_pos")
	if pos_str == "" then return end

	local pos = minetest.string_to_pos(pos_str)
	if not pos then return end

	local meta = minetest.get_meta(pos)
	local node_name = minetest.get_node(pos).name
	local is_locked = node_name:match("locked_chest")
	
	if not has_chest_privilege(meta, player, is_locked) then return end

	local inv = meta:get_inventory()
	if not inv then return end

	local function play_button_sound()
		minetest.sound_play("click", {
			to_player = player:get_player_name(),
			gain = 0.5,
		})
	end

	if fields.setname and fields.rename and fields.rename ~= "" then
		meta:set_string("custom_name", fields.rename)
		minetest.chat_send_player(player:get_player_name(), S("Chest renamed."))
		play_button_sound()
	end

	if fields.clear_all then
		play_button_sound()
		minetest.show_formspec(player:get_player_name(), "summer:modern_chest_form", get_chest_formspec(pos, meta, true))
		return
	end

	if fields.confirm_clear_yes then
		inv:set_list("main", {})
		minetest.chat_send_player(player:get_player_name(), S("Chest cleared."))
		play_button_sound()
		close_chest_sound(player)
		minetest.show_formspec(player:get_player_name(), "summer:modern_chest_form", get_chest_formspec(pos, meta))
	elseif fields.confirm_clear_no then
		play_button_sound()
		close_chest_sound(player)
		minetest.show_formspec(player:get_player_name(), "summer:modern_chest_form", get_chest_formspec(pos, meta))
	end

	if fields.sort_name then
		sort_inventory(inv, "name")
		minetest.chat_send_player(player:get_player_name(), S("Sorted by name."))
		play_button_sound()
	elseif fields.sort_item then
		sort_inventory(inv, "item")
		minetest.chat_send_player(player:get_player_name(), S("Sorted by item description."))
		play_button_sound()
	elseif fields.sort_stack then
		sort_inventory(inv, "stack")
		minetest.chat_send_player(player:get_player_name(), S("Sorted by stack count."))
		play_button_sound()
	elseif fields.sort_mod then
		sort_inventory(inv, "mod")
		minetest.chat_send_player(player:get_player_name(), S("Sorted by mod name."))
		play_button_sound()
	end

	if not (fields.clear_all or fields.confirm_clear_no or fields.confirm_clear_yes) then
		close_chest_sound(player)
	end
end)

local function force_face_player_delayed(pos, placer)
	if not placer or not placer:is_player() then return end

	minetest.after(0.2, function()
		local node = minetest.get_node(pos)
		if not node or not node.name:match("chest") then return end

		local player_pos = placer:get_pos()

		-- La faccia frontale della chest deve essere rivolta verso il player.
		-- Per questo modello usiamo la direzione dalla chest verso il player.
		local dir = vector.subtract(pos, player_pos)

		-- Ignora la differenza di altezza.
		dir.y = 0

		if vector.length(dir) < 0.001 then return end

		local param2 = minetest.dir_to_facedir(dir)

		minetest.swap_node(pos, {
			name = node.name,
			param2 = param2
		})
	end)
end

for _, colour in ipairs(colors) do
	local def = {
		description = S("Modern Chest") .. " (" .. colour .. ")",
		tiles = {
			"chest_top_" .. colour .. ".png", "chest_top_" .. colour .. ".png",
			"chest_side_" .. colour .. ".png", "chest_side_" .. colour .. ".png",
			"chest_side_" .. colour .. ".png", "chest_front_" .. colour .. ".png"
		},
		groups = {choppy = 2, oddly_breakable_by_hand = 2, tubed = 1, tubedevice = 1, tubedevice_receiver = 1, hopper_container = 1},
		paramtype2 = "facedir",
		on_place = minetest.item_place_node,
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", S("Chest"))
			meta:set_string("custom_name", S("Chest"))
			meta:get_inventory():set_size("main", 16 * 8)
		end,
		after_place_node = function(pos, placer)
			force_face_player_delayed(pos, placer)

			if minetest.get_modpath("techage") and techage.add_node then
				local meta = minetest.get_meta(pos)
				local number = techage.add_node(pos, "techage:chest_ta3")
				meta:set_string("node_number", number)
				meta:set_string("infotext", S("Chest") .. " " .. number)
			end
		end,
		on_rightclick = function(pos, node, clicker)
			local meta = minetest.get_meta(pos)
			clicker:get_meta():set_string("modern_chest_pos", minetest.pos_to_string(pos))
			minetest.show_formspec(clicker:get_player_name(), "summer:modern_chest_form", get_chest_formspec(pos, meta))
			minetest.sound_play("chest_open", {
				pos = pos,
				gain = 0.5,
				max_hear_distance = 8,
			})
			open_chests[clicker:get_player_name()] = {
				pos = {x = pos.x, y = pos.y, z = pos.z},
			}
		end,
		on_destruct = function(pos)
			if minetest.get_modpath("techage") then
				local node = minetest.get_node(pos)
				local oldmeta = minetest.get_meta(pos):to_table()
				if techage.remove_node then techage.remove_node(pos, node, oldmeta) end
				if techage.del_mem then techage.del_mem(pos) end
			end
			minetest.sound_play("chest_break", {
				pos = pos,
				gain = 0.5,
				max_hear_distance = 8,
			})
		end,
		pipeworks = {
			connect_sides = {top = 1, bottom = 1, back = 1, left = 1, right = 1, front = 1},
			insert_object = function(pos, node, stack) return minetest.get_meta(pos):get_inventory():add_item("main", stack) end,
			remove_items = function(pos, node, stack, count) return minetest.get_meta(pos):get_inventory():take_item("main", count) end,
			get_infotext = function(pos) return minetest.get_meta(pos):get_string("infotext") end
		},
		tube = {
			insert_object = function(pos, node, stack) return minetest.get_meta(pos):get_inventory():add_item("main", stack) end,
			can_insert = function(pos, node, stack) return minetest.get_meta(pos):get_inventory():room_for_item("main", stack) end,
			input_inventory = "main",
			connect_sides = {left = 1, right = 1, back = 1, front = 1, bottom = 1, top = 1}
		},
		on_inv_request = function(pos) return minetest.get_meta(pos):get_inventory(), "main" end,
		on_push_item = function(pos, in_dir, stack)
			local inv = minetest.get_meta(pos):get_inventory()
			if inv then return inv:add_item("main", stack) end
			return stack
		end,
		on_pull_item = function(pos, in_dir, num, item_name)
			local inv = minetest.get_meta(pos):get_inventory()
			if inv then
				for i = 1, inv:get_size("main") do
					local stack = inv:get_stack("main", i)
					if not stack:is_empty() and (not item_name or item_name == "" or stack:get_name() == item_name) then
						local item_to_take = ItemStack(stack:get_name())
						item_to_take:set_count(num)
						return inv:remove_item("main", item_to_take)
					end
				end
			end
			return ItemStack("")
		end,
		on_unpull_item = function(pos, in_dir, stack)
			local inv = minetest.get_meta(pos):get_inventory()
			if inv then return inv:add_item("main", stack) end
			return stack
		end,
	}
	minetest.register_node("summer:modern_chest_" .. colour, def)

	local def_lock = {
		description = S("Locked Chest") .. " (" .. colour .. ")",
		tiles = {
			"chest_top_" .. colour .. ".png", "chest_top_" .. colour .. ".png",
			"chest_side_" .. colour .. ".png", "chest_side_" .. colour .. ".png",
			"chest_side_" .. colour .. ".png", "chest_lock_" .. colour .. ".png"
		},
		groups = {choppy = 2, oddly_breakable_by_hand = 2, tubed = 1, tubedevice = 1, tubedevice_receiver = 1, hopper_container = 1},
		paramtype2 = "facedir",
		on_place = minetest.item_place_node,
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", "")
			meta:set_string("infotext", S("Locked Chest"))
			meta:set_string("custom_name", S("Locked Chest"))
			meta:get_inventory():set_size("main", 16 * 8)
		end,
		on_rightclick = function(pos, node, clicker)
			local meta = minetest.get_meta(pos)
			local player_name = clicker:get_player_name()
			local owner = meta:get_string("owner")

			if owner == "" then
				meta:set_string("owner", player_name)
				meta:set_string("infotext", S("Locked Chest (Owned by @1)", player_name))
				owner = player_name
			end

			if not has_chest_privilege(meta, clicker, true) then
				minetest.chat_send_player(player_name, S("This chest is locked by @1", owner))
				return
			end

			clicker:get_meta():set_string("modern_chest_pos", minetest.pos_to_string(pos))
			minetest.show_formspec(player_name, "summer:modern_chest_form", get_chest_formspec(pos, meta))
			minetest.sound_play("chest_open", {
				pos = pos,
				gain = 0.5,
				max_hear_distance = 8,
			})
			open_chests[player_name] = {
				pos = {x = pos.x, y = pos.y, z = pos.z},
			}
		end,
		on_destruct = def.on_destruct,
		pipeworks = {
			connect_sides = {top = 1, bottom = 1, back = 1, left = 1, right = 1, front = 1},
			insert_object = function(pos, node, stack) return minetest.get_meta(pos):get_inventory():add_item("main", stack) end,
			remove_items = function(pos, node, stack, count)
				local owner = minetest.get_meta(pos):get_string("owner")
				if owner == "" then return minetest.get_meta(pos):get_inventory():take_item("main", count) end
				
				local px = pos.x or pos[1]
				local py = pos.y or pos[2]
				local pz = pos.z or pos[3]
				if not px or not py or not pz then return ItemStack("") end

				local dir_vec = get_dir_vector(node.direction)
				local p1 = {x = px + dir_vec.x, y = py + dir_vec.y, z = pz + dir_vec.z}
				local p2 = {x = px - dir_vec.x, y = py - dir_vec.y, z = pz - dir_vec.z}
				
				if minetest.get_node(p1).name:find("techage:") or minetest.get_node(p2).name:find("techage:") then
					return minetest.get_meta(pos):get_inventory():take_item("main", count)
				end
				return ItemStack("")
			end,
			get_infotext = function(pos) return minetest.get_meta(pos):get_string("infotext") end
		},
		tube = def.tube,
		on_inv_request = def.on_inv_request,
		on_push_item = function(pos, in_dir, stack)
			local inv = minetest.get_meta(pos):get_inventory()
			if inv then return inv:add_item("main", stack) end
			return stack
		end,
		on_pull_item = function(pos, in_dir, num, item_name)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")
			if owner == "" then return def.on_pull_item(pos, in_dir, num, item_name) end

			local inv = meta:get_inventory()
			if not inv then return ItemStack("") end

			if num and num > 0 then
				local stack = ItemStack(item_name or "")
				if stack:is_empty() then
					for i = 1, inv:get_size("main") do
						local s = inv:get_stack("main", i)
						if not s:is_empty() then
							local take = ItemStack(s:get_name())
							take:set_count(math.min(num, s:get_count()))
							return inv:remove_item("main", take)
						end
					end
				else
					return inv:remove_item("main", stack)
				end
			end

			return ItemStack("")
		end,
		on_unpull_item = function(pos, in_dir, stack)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")
			if owner == "" then return def.on_unpull_item(pos, in_dir, stack) end
			
			local px = pos.x or pos[1]
			local py = pos.y or pos[2]
			local pz = pos.z or pos[3]
			if not px or not py or not pz then return stack end

			local dir_vec = get_dir_vector(in_dir)
			local p1 = {x = px + dir_vec.x, y = py + dir_vec.y, z = pz + dir_vec.z}
			local p2 = {x = px - dir_vec.x, y = py - dir_vec.y, z = pz - dir_vec.z}
			
			if minetest.get_node(p1).name:find("techage:") or minetest.get_node(p2).name:find("techage:") then
				return def.on_unpull_item(pos, in_dir, stack)
			end
			
			return stack
		end,
		after_place_node = function(pos, placer)
			force_face_player_delayed(pos, placer)

			if placer and placer:is_player() then
				local name = placer:get_player_name()
				local meta = minetest.get_meta(pos)
				meta:set_string("owner", name)
				meta:set_string("infotext", S("Locked Chest (Owned by @1)", name))
				if minetest.get_modpath("techage") and techage.add_node then
					local number = techage.add_node(pos, "techage:chest_ta3")
					meta:set_string("node_number", number)
					meta:set_string("infotext", S("Locked Chest (Owned by @1)", name) .. " " .. number)
				end
			end
		end,
	}
	minetest.register_node("summer:locked_chest_" .. colour, def_lock)

	if minetest.get_modpath("tubelib2") then
		local n1, n2 = "summer:modern_chest_" .. colour, "summer:locked_chest_" .. colour
		minetest.registered_nodes[n1].tubelib2_on_update2 = function() end
		minetest.registered_nodes[n1].tubelib2_on_update = function() end
		minetest.registered_nodes[n2].tubelib2_on_update2 = function() end
		minetest.registered_nodes[n2].tubelib2_on_update = function() end
	end
	minetest.register_alias("summer:chest" .. colour, "summer:modern_chest_" .. colour)
	minetest.register_alias("summer:chest_lock" .. colour, "summer:locked_chest_" .. colour)
end

if minetest.get_modpath("pipeworks") and pipeworks.register_tube_compatibility then
	local pipe_nodes = {}
	for _, colour in ipairs(colors) do
		table.insert(pipe_nodes, "summer:modern_chest_" .. colour)
		table.insert(pipe_nodes, "summer:locked_chest_" .. colour)
	end
	pipeworks.register_tube_compatibility(pipe_nodes)
end

minetest.register_on_mods_loaded(function()
	if techage then
		for _, colour in ipairs(colors) do
			local n1, n2 = "summer:modern_chest_" .. colour, "summer:locked_chest_" .. colour
			if techage.Tube and techage.Tube.secondary_node_names then
				techage.Tube.secondary_node_names[n1] = true
				techage.Tube.secondary_node_names[n2] = true
			end
			if techage.KnownNodes then
				techage.KnownNodes[n1] = true
				techage.KnownNodes[n2] = true
			end
		end
		for key, value in pairs(techage) do
			if type(value) == "table" and (value["techage:chest_ta3"] ~= nil or key:match("node") or key:match("mach")) then
				for _, colour in ipairs(colors) do
					local n1, n2 = "summer:modern_chest_" .. colour, "summer:locked_chest_" .. colour
					value[n1] = { on_inv_request = minetest.registered_nodes[n1].on_inv_request, on_push_item = minetest.registered_nodes[n1].on_push_item, on_pull_item = minetest.registered_nodes[n1].on_pull_item, on_unpull_item = minetest.registered_nodes[n1].on_unpull_item }
					value[n2] = { on_inv_request = minetest.registered_nodes[n2].on_inv_request, on_push_item = minetest.registered_nodes[n2].on_push_item, on_pull_item = minetest.registered_nodes[n2].on_pull_item, on_unpull_item = minetest.registered_nodes[n2].on_unpull_item }
				end
			end
		end
	end
end)

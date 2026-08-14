--_____ Modern Colored Chests with Advanced Features _____--

local S = summer.S

local colors = { "red", "orange", "yellow", "green", "blue", "violet", "black" }

local open_chests = {} -- Track open chests for close sound

local function has_chest_privilege(meta, player)
	local owner = meta:get_string("owner")
	return owner == "" or owner == player:get_player_name()
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
		--_____ Text split over 3 centered lines with explicit native red coloring _____--
		local line1 = minetest.colorize("#FF0000", S("WARNING:")) .. "\n"
		local line2 = S("Are you sure you want to clear the chest?") .. "\n"
		local line3 = minetest.colorize("#FF0000", S("THIS WILL DELETE ALL ITEMS IN THE CHEST FOREVER"))
		local full_warning = line1 .. line2 .. line3

		return "formspec_version[6]" ..
			"size[14,5.5]" ..
			"bgcolor[#080808BB;true]" ..
			"background[0,0;14,5.5;gui_formbg.png;true]" ..
			default.gui_slots ..
			"label[1,1.0;" .. full_warning .. "]" ..
			"button[2,4.0;3,1;confirm_clear_yes;" .. S("Yes") .. "]" ..
			"button[9,4.0;3,1;confirm_clear_no;" .. S("No") .. "]"
	end

	return "formspec_version[6]" ..
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
	local inv = meta:get_inventory()
	if not inv then return end
	if not has_chest_privilege(meta, player) then return end

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
--_____ Modern chests - snippet 2: node registration with built-in compatibility _____--

local pipeworks_infotext = function(pos)
	return minetest.get_meta(pos):get_string("infotext")
end

local function automation_allowed(pos, player_name)
	local owner = minetest.get_meta(pos):get_string("owner")
	return owner == "" or player_name == nil or player_name == "" or owner == player_name
end

--_____ Register nodes for each color _____--
for _, colour in ipairs(colors) do
	local def = {
		description = S("Modern Chest") .. " (" .. colour .. ")",
		tiles = {
			"chest_top_" .. colour .. ".png", "chest_top_" .. colour .. ".png",
			"chest_side_" .. colour .. ".png", "chest_side_" .. colour .. ".png",
			"chest_side_" .. colour .. ".png", "chest_front_" .. colour .. ".png"
		},
		groups = {choppy = 2, oddly_breakable_by_hand = 2, tubed = 1, hopper_container = 1},
		paramtype2 = "facedir",
		on_place = minetest.rotate_node,
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", S("Chest"))
			meta:set_string("custom_name", S("Chest"))
			local inv = meta:get_inventory()
			inv:set_size("main", 16 * 8)
		end,

		--_____ Automatic network ID initialization to enable TechAge pipe geometry paths _____--
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			if minetest.get_modpath("techage") and techage.add_node then
				local meta = minetest.get_meta(pos)
				local number = techage.add_node(pos, "techage:chest_ta3")
				meta:set_string("node_number", number)
				meta:set_string("infotext", S("Chest") .. " " .. number)
			end
		end,

		on_rightclick = function(pos, node, clicker)
			local meta = minetest.get_meta(pos)
			if not has_chest_privilege(meta, clicker) then
				minetest.chat_send_player(clicker:get_player_name(), S("This chest is locked."))
				return
			end
			clicker:get_meta():set_string("modern_chest_pos", minetest.pos_to_string(pos))
			minetest.show_formspec(clicker:get_player_name(), "summer:modern_chest_form", get_chest_formspec(pos, meta))
			minetest.sound_play("chest_open", {
				pos = pos,
				gain = 0.5,
				max_hear_distance = 8,
			})
			open_chests[clicker:get_player_name()] = {
				pos = vector.copy(pos),
				timer = 0
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

		--_____ Native Pipeworks compatibility methods _____--
		pipeworks = {
			connect_sides = {top = 1, bottom = 1, back = 1, left = 1, right = 1, front = 1},
			insert_object = function(pos, node, stack, direction)
				return minetest.get_meta(pos):get_inventory():add_item("main", stack)
			end,
			remove_items = function(pos, node, stack, count)
				return minetest.get_meta(pos):get_inventory():take_item("main", count)
			end,
			get_infotext = pipeworks_infotext
		},

		--_____ Native methods required by internal1.lua for Tubelib2 _____--
		tubelib2_on_update2 = function(pos, dir, tube, node) end,
		tubelib2_on_update = function() end,

		--_____ Native transfer methods required by TechAge pushers (unlocks 128 slots) _____--
		on_inv_request = function(pos, in_dir, access_type)
			local meta = minetest.get_meta(pos)
			return meta:get_inventory(), "main"
		end,
		on_push_item = function(pos, in_dir, stack)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if inv then return inv:add_item("main", stack) end
			return stack
		end,
		on_pull_item = function(pos, in_dir, num, item_name)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
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
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
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
		groups = {choppy = 2, oddly_breakable_by_hand = 2, tubed = 1, hopper_container = 1},
		paramtype2 = "facedir",
		on_place = minetest.rotate_node,
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", "")
			meta:set_string("infotext", S("Locked Chest"))
			meta:set_string("custom_name", S("Locked Chest"))
			local inv = meta:get_inventory()
			inv:set_size("main", 16 * 8)
		end,
		on_rightclick = def.on_rightclick,
		on_destruct = def.on_destruct,

		pipeworks = {
			connect_sides = {top = 1, bottom = 1, back = 1, left = 1, right = 1, front = 1},
			insert_object = function(pos, node, stack, direction)
				local tube_meta = minetest.get_meta(vector.add(pos, direction))
				local owner = minetest.get_meta(pos):get_string("owner")
				if owner ~= "" and tube_meta:get_string("owner") ~= owner then return stack end
				return minetest.get_meta(pos):get_inventory():add_item("main", stack)
			end,
			remove_items = function(pos, node, stack, count)
				return minetest.get_meta(pos):get_inventory():take_item("main", count)
			end,
			get_infotext = pipeworks_infotext
		},

		tubelib2_on_update2 = def.tubelib2_on_update2,
		tubelib2_on_update = def.tubelib2_on_update,

		on_inv_request = def.on_inv_request,
		on_push_item = function(pos, in_dir, stack)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")
			if owner ~= "" and not automation_allowed(pos, owner) then return stack end
			local inv = meta:get_inventory()
			if inv then return inv:add_item("main", stack) end
			return stack
		end,
		on_pull_item = function(pos, in_dir, num, item_name)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")
			if owner ~= "" and not automation_allowed(pos, owner) then return ItemStack("") end
			return def.on_pull_item(pos, in_dir, num, item_name)
		end,
		on_unpull_item = function(pos, in_dir, stack)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")
			if owner ~= "" and not automation_allowed(pos, owner) then return stack end
			local inv = meta:get_inventory()
			if inv then return inv:add_item("main", stack) end
			return stack
		end,

		after_place_node = function(pos, placer, itemstack, pointed_thing)
			if placer and placer:is_player() then
				local meta = minetest.get_meta(pos)
				meta:set_string("owner", placer:get_player_name())

				if minetest.get_modpath("techage") and techage.add_node then
					local number = techage.add_node(pos, "techage:chest_ta3")
					meta:set_string("node_number", number)
					meta:set_string("infotext", S("Locked Chest (Owned by @1)", placer:get_player_name()) .. " " .. number)
				else
					meta:set_string("infotext", S("Locked Chest (Owned by @1)", placer:get_player_name()))
				end
			end
			if minetest.get_modpath("pipeworks") and pipeworks.scan_for_tube_objects then
				pipeworks.scan_for_tube_objects(pos)
			end
		end,
	}
	minetest.register_node("summer:locked_chest_" .. colour, def_lock)
end
--_____ Modern chests - snippet 3: final cache alignment and compatibility _____--

for _, colour in ipairs(colors) do
	minetest.register_alias("summer:chest" .. colour, "summer:modern_chest_" .. colour)
	minetest.register_alias("summer:chest_lock" .. colour, "summer:locked_chest_" .. colour)
end

--_____ 1. Immediate Pipeworks mesh compatibility _____--
if minetest.get_modpath("pipeworks") and pipeworks.register_tube_compatibility then
	local pipe_nodes = {}
	for _, colour in ipairs(colors) do
		table.insert(pipe_nodes, "summer:modern_chest_" .. colour)
		table.insert(pipe_nodes, "summer:locked_chest_" .. colour)
	end
	pipeworks.register_tube_compatibility(pipe_nodes)
end

--_____ 2. TechAge pipe geometry alignment (run after modules load) _____--
minetest.register_on_mods_loaded(function()
	local ta_colors = { "red", "orange", "yellow", "green", "blue", "violet", "black" }

	if techage then
		--_____ Visual injection to bend black and blue tubes (ta4) toward chests _____--
		if techage.Tube and techage.Tube.secondary_node_names then
			for _, colour in ipairs(ta_colors) do
				techage.Tube.secondary_node_names["summer:modern_chest_" .. colour] = true
				techage.Tube.secondary_node_names["summer:locked_chest_" .. colour] = true
			end
		end

		--_____ Logic injection to make nodes valid for the movement algorithm _____--
		if techage.KnownNodes then
			for _, colour in ipairs(ta_colors) do
				techage.KnownNodes["summer:modern_chest_" .. colour] = true
				techage.KnownNodes["summer:locked_chest_" .. colour] = true
			end
		end
	end
end)

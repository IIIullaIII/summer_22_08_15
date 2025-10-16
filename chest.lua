-- Modern Colored Chests with Advanced Features

local S = minetest.get_translator("summer")

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
		return "formspec_version[4]" ..
			"size[8,4]" ..
			"bgcolor[#080808BB;true]" ..
			"background[5,5;1,1;gui_formbg.png;true]" ..
			default.gui_slots ..
			"label[1,1;" .. S("Are you sure you want to clear the chest?") .. "]" ..
			"button[1,2;2,1;confirm_clear_yes;" .. S("Yes") .. "]" ..
			"button[4,2;2,1;confirm_clear_no;" .. S("No") .. "]"
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

	-- Close sound if formspec is closed without triggering clear confirm
	if not (fields.clear_all or fields.confirm_clear_no or fields.confirm_clear_yes) then
		close_chest_sound(player)
	end
end)

-- Register nodes for each color
for _, colour in ipairs(colors) do
	local def = {
		description = S("Modern Chest") .. " (" .. colour .. ")",
		tiles = {
			"chest_top_" .. colour .. ".png", "chest_top_" .. colour .. ".png",
			"chest_side_" .. colour .. ".png", "chest_side_" .. colour .. ".png",
			"chest_side_" .. colour .. ".png", "chest_front_" .. colour .. ".png"
		},
		groups = {choppy = 2, oddly_breakable_by_hand = 2},
		paramtype2 = "facedir",
		on_place = minetest.rotate_node,
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", S("Chest"))
			meta:set_string("custom_name", S("Chest"))
			local inv = meta:get_inventory()
			inv:set_size("main", 16 * 8)
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
			minetest.sound_play("chest_break", {
				pos = pos,
				gain = 0.5,
				max_hear_distance = 8,
			})
		end,
	}
	minetest.register_node("summer:modern_chest_" .. colour, def)

	local def_lock = table.copy(def)
	def_lock.description = S("Locked Chest") .. " (" .. colour .. ")"
	def_lock.tiles[6] = "chest_lock_" .. colour .. ".png"
	def_lock.on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", "")
		meta:set_string("infotext", S("Locked Chest"))
		meta:set_string("custom_name", S("Locked Chest"))
		local inv = meta:get_inventory()
		inv:set_size("main", 16 * 8)
	end
	minetest.register_node("summer:locked_chest_" .. colour, def_lock)

	-- Alias per retrocompatibilità
	minetest.register_alias("summer:chest"..colour, "summer:modern_chest_" .. colour)
	minetest.register_alias("summer:chest_lock"..colour, "summer:locked_chest_" .. colour)
end

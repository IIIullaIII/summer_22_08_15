local S = summer.S

minetest.register_craftitem("summer:mattoneG", {
	description = S("Grey Brick"),
	inventory_image = "mattone.png",

})
    minetest.register_craftitem("summer:mattoneR", {
	description = S("Corten Brick"),
	inventory_image = "mattoneR.png",

})
minetest.register_craftitem("summer:mattoneA", {
	description = S("Ivory Brick"),
	inventory_image = "mattoneA.png",

})
    minetest.register_craftitem("summer:mattoneP", {
	description = S("Pink Brick"),
	inventory_image = "mattoneP.png",

})
    minetest.register_craftitem("summer:mattoneC", {
	description = S("Cyan Brick"),
	inventory_image = "mattoneC.png",

})
    minetest.register_craftitem("summer:mattoneB", {
	description = S("Black Brick"),
	inventory_image = "mattoneB.png",

})
--_____ Brick crafts _____--

minetest.register_craft({
	type = 'cooking',
	recipe = "summer:pietraA",
	cooktime = 2,
	output = "summer:mattoneA",
})
minetest.register_craft({
	type = 'cooking',
	recipe = "summer:pietraC",
	cooktime = 2,
	output = "summer:mattoneC",
})
minetest.register_craft({
	type = 'cooking',
	recipe = "summer:pietra",
	cooktime = 2,
	output = "summer:mattoneG",
})
minetest.register_craft({
	type = 'cooking',
	recipe = "summer:desert_pietra",
	cooktime = 2,
	output = "summer:mattoneR",
})
minetest.register_craft({
	type = 'cooking',
	recipe = "summer:pietraP",
	cooktime = 2,
	output = "summer:mattoneP",
})
minetest.register_craft({
	type = 'cooking',
	recipe = "summer:pietraB",
	cooktime = 2,
	output = "summer:mattoneB",
})

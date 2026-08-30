--_____ Shared translator for the whole mod _____--
summer = summer or {}

local S
if minetest.get_translator then
	S = minetest.get_translator(minetest.get_current_modname())
else
	S = function(s) return s end
end

summer.S = S

local path = minetest.get_modpath("summer")
dofile(path .. "/papera.lua")
dofile(path .. "/sparabolle.lua")
dofile(path .. "/scivolo.lua")
dofile(path .. "/ladders.lua")
dofile(path.."/salvag.lua")
dofile(path.."/ombrellone.lua")
dofile(path.."/sdraia.lua")
dofile(path.."/porta.lua")
dofile(path.."/ombrellone_new.lua")
dofile(path.."/materassino.lua")
dofile(path.."/breccia.lua")
dofile(path.."/asciugamano.lua")
if minetest.get_modpath("3d_armor") then
dofile(path.."/occhiali.lua")
end
dofile(path.."/chest.lua")

dofile(path.."/portacenere.lua")
dofile(path.."/summerstair.lua")
dofile(path.."/barche.lua")
dofile(path.."/granite.lua")
dofile(path.."/canoa.lua")
dofile(path.."/craft.lua")
dofile(path.."/vetro.lua")
dofile(path.."/aliases.lua")
dofile(path.."/sabbia.lua")
dofile(path.."/mattone.lua")
dofile(path.."/pietra.lua")
dofile(path.."/pallone.lua")
dofile(path.."/lib.lua")
if minetest.get_modpath("cannabis") then
dofile(path.."/canapa.lua")
end

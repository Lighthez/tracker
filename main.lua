--[[pod_format="raw",created="2025-09-27 20:36:47",modified="2025-10-05 14:55:36",revision=79]]
include("toolkit.lua")

--local secondary_font = fetch("./fonts/micro.font")
--secondary_font:poke(0x5600)

window{
	tabbed = true
}

g = create_gui()

local sp = g:attach(create_split_container({
	--width=480,
	--height=270,
	height_rel = 1.0,
	width_rel = 1.0,
	kind=DIVIDER_VERTICAL,
	split_point = 135
}))

sp:attach_first(create_button({
	label="play!",
	x=0,
	y=0,
}))

local sp2 = sp:attach_second(create_split_container({
	height_rel = 1.0,
	width = 480,
	kind=DIVIDER_HORIZONTAL,
	split_point = 100
}))

sp2:attach_first(create_button({
	label="play!",
	x=0,
	y=0,
}))

sp2:attach_second(create_button({
	label="play!",
	x=0,
	y=0,
}))

function _update()
	g:update_all()
end

function _draw()
	cls(1)
	--print("hello world!!!\014testing\015testing again!")
	--print("\014so this is a pretty small font, hopefully it can be somewhat readable!")
	g:draw_all()
end

include("error_explorer.lua")
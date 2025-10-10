include("util.lua")
include("theme.lua")
include("toolkit.lua")

--local secondary_font = fetch("./fonts/micro.font")
--secondary_font:poke(0x5600)
--local primary_font = fetch("./fonts/sqrt.font")
local primary_font = fetch("/system/fonts/p8.font")
primary_font:poke(0x4000)

--[[
window{
	tabbed = true
}
]]

g = create_gui()
--[[
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
]]

create_panel(g, {
	x = 0,
	y = 0,
	width = 100,
	height = 12,
	color = rnd_not(32, theme.color.text)
})

create_label(g, {
	x = 1,
	y = 6,
	text = "tracker"
})

create_icon_button(g, {
	x = 1,
	y = 13
})

local tc = create_tab_container(g, {
	x=100,
	width=380,
	height=270,
})

t1 = tc:create_tab("test")
t2 = tc:create_tab("testing")
t3 = tc:create_tab("testinger")
t4 = tc:create_tab("testingest")

local btn = create_button(t2, {
	x=0,
	y=0,
	label="what"
})

function btn:click()
	notify("what?")
end

tc2 = create_tab_container(t1, {
	width=380,
	height=262,
})

tc2:create_tab("nesting testing")
tc2:create_tab("woop")
tc2:create_tab("more woop")
tc2:create_tab("yay woop")
tc2:create_tab("woop woop")

local sp1 = create_split_container(t3, {
	width_rel = 1.0,
	height_rel = 1.0,
	kind = DIVIDER_VERTICAL,
	split_point = 135
})

create_split_container(sp1.first_element, {
	width_rel = 1.0,
	height_rel = 1.0,
	kind = DIVIDER_HORIZONTAL,
	split_point = 135
})

create_slider(t4, {
	width = 100,
	height = 8
})

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
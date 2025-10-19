fmt = string.format
include("src/require.lua")
--include("src/sfxlib.lua")
include("src/theme.lua")
include("src/toolkit.lua")

--local secondary_font = fetch("./fonts/micro.font")
--secondary_font:poke(0x5600)
--local primary_font = fetch("./fonts/sqrt.font")
local primary_font = fetch("/system/fonts/p8.font")
primary_font:poke(0x4000)

--[[
function _init()
	local sfx = new_sfx_interface()

	notify(""..1)
	notify(fmt("0x%X, 0x%X", sfx.patterns[0].track_mask, sfx.patterns[0].pattern_indices[0]))
end
]]

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
	width = 95,
	height = 12,
	color = theme.color.secondary
})

local sidebar = create_panel(g, {
	x = 0,
	y = 11,
	width = 95,
	height = 270-12,
	color = theme.color.primary
})

create_label(g, {
	x = 2,
	y = 5,
	text = "tracker"
})

create_icon_button(g, {
	x = 1,
	y = 13
})

local tc = create_tab_container(g, {
	x=95,
	width=385,
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
--[[
tc2 = create_tab_container(t1, {
	width=380,
	height=262,
})
]]

t1:attach_scrollbars()

tracker = create_tracker(t1, {
	width_rel = 1.0,
	height_rel = 1.0
})

--[[
tc2:create_tab("nesting testing")
tc2:create_tab("woop")
tc2:create_tab("more woop")
tc2:create_tab("yay woop")
tc2:create_tab("woop woop")
]]

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

local g1 = create_sfx_grid(g, {
	x = 0,
	y = 188,
	width = 95,
	--height = 120
})

local l1 = create_list(g, {
	x = 0,
	y = 110,
	width = 95,
	height = 80,
})

l1:new_item("testing", function() end)
l1:new_item("test", function() end)
l1:new_item("t", function() end)
l1:new_item("HELP", function() end)
l1:new_item("testing", function() end)
l1:new_item("test", function() end)
l1:new_item("t", function() end)
l1:new_item("HELP", function() end)
l1:new_item("testing", function() end)
l1:new_item("test", function() end)
l1:new_item("t", function() end)
l1:new_item("HELP", function() end)
l1:new_item("testing", function() end)
l1:new_item("test", function() end)
l1:new_item("t", function() end)
l1:new_item("HELP", function() end)

function _update()
	g:update_all()
end

function _draw()
	cls(1)
	--print("hello world!!!\014testing\015testing again!")
	--print("\014so this is a pretty small font, hopefully it can be somewhat readable!")
	g:draw_all()
	local cpu = string.format("\014\^o0ffcpu: %.2f%%", stat(1) * 100)
	local ww = print(cpu,0,9999)
	print(cpu, 479-ww, 271-theme.metrics.font_height, 7)
end

include("src/error_explorer.lua")
fmt = string.format
include("src/require.lua")
include("src/sfxlib.lua")
include("src/theme.lua")
include("src/toolkit.lua")

--local secondary_font = fetch("./fonts/micro.font")
--secondary_font:poke(0x5600)
--local primary_font = fetch("./fonts/sqrt.font")
local primary_font = fetch("/system/fonts/p8.font")
primary_font:poke(0x4000)

function _init()
	sfx_interface = new_sfx_interface()

	--notify(""..1)
	--notify(fmt("0x%X, 0x%X", sfx.patterns[0].track_mask, sfx.patterns[0].pattern_indices[0]))

	--[[
	window{
		tabbed = true
	}
	]]

	--local request_redraw = true

	g = create_gui()

	--[[
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
	]]
	--[[
	create_label(g, {
		x = 2,
		y = 5,
		text = "tracker"
	})
	]]

	--[[create_icon_button(g, {
		x = 5,
		y = 16
	})
	]]

	local sounds_tab_bar = create_tab_container(g, {
		x = 0,
		y = 115,
		width = 95,
		height = 77,
		tab_height = 12,
		draw_wide_tab = true
	})

	local instruments_tab = sounds_tab_bar:create_tab("inst", true)
	local samples_tab = sounds_tab_bar:create_tab("sample")

	local l1 = create_list(instruments_tab, {
		x = 1,
		y = 1,
		width = 94,
		height = 77-14,
	})

	local patterns_tab_bar = create_tab_container(g, {
		x = 0,
		y = 190,
		width = 95,
		height = 68+12,
		tab_height = 12,
		draw_wide_tab = true
	})

	local matrix_tab = patterns_tab_bar:create_tab("mat", true)
	local pattern_tab = patterns_tab_bar:create_tab("pat")
	local sfx_tab = patterns_tab_bar:create_tab("sfx")

	sfx_grid = create_sfx_grid(matrix_tab, {
		x = 1,
		y = 0,--183,
		width = 94,
		height = 68,
		cells_tall = 7
	})

	for i = 0, 63 do 
		l1:new_item(sfx_interface.instruments[i].name)
	end


	local tc = create_tab_container(g, {
		x=95,
		width=385,
		height=270,
	})

	t1 = tc:create_tab("pattern", true)
	t2 = tc:create_tab("sfx")
	t3 = tc:create_tab("instrument")
	t4 = tc:create_tab("wave")

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

	--t1:attach_scrollbars()

	tracker = create_tracker(t1, {
		width_rel = 1.0,
		height_rel = 1.0,
		sfx_interface = sfx_interface,
		selected_pattern = 0
	}, sfx_interface)

	tracker:select_pattern(0)

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
		height = 8,
		grabber_size = 11,
		steps = 0
	})
end

function _update()
	g:update_all()
end

function _draw()
	--cls(1)

	draw_background_layer()
	
	--print("hello world!!!\014testing\015testing again!")
	--print("\014so this is a pretty small font, hopefully it can be somewhat readable!")
	g:draw_all()
	local cpu = string.format("\014\^o0ffcpu: %06.2f%%", stat(1) * 100)
	local ww = print(cpu,0,9999)
	rectfill(479-50, 271-theme.metrics.font_height-1, 480, 270, 0)
	print(cpu, 479-ww, 271-theme.metrics.font_height, 7)
end

function draw_background_layer()
	--if not request_redraw then return end
	--request_redraw = false

	draw_panel(0, 0, 95, 12)
	print("tracker", 2, 5, theme.color.text)

	draw_panel(0,11, 96, 105) -- main
	draw_panel(0,125, 96, 77) -- insts
	draw_panel(0,193, 96, 77) -- grid
	draw_panel(95, 11, 480-96, 270-11)
end

include("src/error_explorer.lua")
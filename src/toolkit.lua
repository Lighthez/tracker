local util = require("src/util")
local default, pitch_to_note, fallback_ff = util.default, util.pitch_to_note, util.fallback_ff

-- lib stuff goes here
DIVIDER_HORIZONTAL = 0
DIVIDER_VERTICAL = 1

SLIDER_HORIZONTAL = 0
SLIDER_VERTICAL = 1

local SELECTION_TRACK = 3
local SELECTION_PATTERN = 2
local SELECTION_SFX = 1
local SELECTION_NONE = 0

function create_label(self, el)
	el = default(el, {
		text = "<empty>"
	})

	el.width = #el.text * 5 + 2
	el.height = 8

	function el:draw()
		print(self.text, 0, 0, theme.color.text)
	end

	return self:attach(el)
end
--[[
function create_panel(self, el)
	el = default(el, {
		color = 12
	})

	function el:draw()
		rectfill(0,0,self.width,self.height,self.color)
		rect(0, 0, self.width-1, self.height-1,theme.color.border)
	end

	return self:attach(el)
end
]]
function create_button(self, el)
	el = self:attach_button(el)

	function el:draw()
		rectfill(0,0,self.width,self.height,theme.color.secondary)
		rect(0,0,self.width-1,self.height-1, theme.color.border)
		print(self.label,1,1,theme.color.text)
	end

	return el
end

function create_icon_button(self, el)
	el = default(el, {
		sprite = 0,
		offset_x = 0,
		offset_y = 0
	})

	if not (el.width or el.height) then
		local sprite_dat = get_spr(el.sprite)

		el.width = sprite_dat:width()
		el.height = sprite_dat:height()
	end

	el = self:attach_button(el)

	--assert(el.width == 10)

	function el:draw(msg)
		local yy = 0
		--if (msg.mb > 0 and msg.has_pointer) then yy = yy + 1 end

		rectfill(0,yy,self.width,self.height,theme.color.secondary)
		spr(self.sprite, self.offset_x, self.offset_y)
	end

	return el
end

function create_split_container(self, el)
	el = default(el, {
		split_point = 1,
	})

	el.bar_hovering = false
	el.was_bar_hovering = false
	el.dragging = false
	el.was_dragging = false
	el.mouse_clicked = false
	el.mouse_held = false
	el.axis_key = (el.kind == DIVIDER_HORIZONTAL and "width") or "height"
	el.axis_position = (el.kind == DIVIDER_HORIZONTAL and "x") or "y"

	function el:draw()
		if self.kind == DIVIDER_HORIZONTAL then
			rect(self.split_point, 0, self.split_point, self.height,8)
			rect(self.split_point-5, self.height/2-5, self.split_point+5, self.height/2+5)
		else
			rect(0, self.split_point, self.width, self.split_point,8)
			rect(self.width/2-5, self.split_point-5, self.width/2+5, self.split_point+5)
		end
	end

	function el:update(msg)
		self.mouse_clicked = (msg.mb & 0b1 > 0) and (not self.mouse_held)
		local abs_x = msg.mx
		local abs_y = msg.my

		self.bar_hovering = (
			self.kind == DIVIDER_HORIZONTAL and (abs_x > ((self.split_point)-5) and abs_x < ((self.split_point)+5)) or
			(abs_y > ((self.split_point)-5) and abs_y < ((self.split_point)+5))
		)

		if (not self.was_bar_hovering and self.bar_hovering) then
			if self.kind == DIVIDER_HORIZONTAL then
				self.cursor = unpod("b64:bHo0ACAAAAAeAAAA8A9weHUAQyAQEATwUwdwB0AHkAcg1yAHkAdAB3AH8EM=")
			else
				self.cursor = unpod("b64:bHo0ACgAAAAwAAAA_QhweHUAQyAQEATwBwfQJ7AHAAcAB8AH4AIAwMAHAAcAB7An0AfwCA==")
			end
		elseif (not self.bar_hovering and self.was_bar_hovering) then
			self.cursor = 1
		end

		if (not self.dragging) then
			self.dragging = self.bar_hovering and (self.mouse_clicked and (not self.was_dragging))
		end

		if self.dragging then
			local value = (self.kind == DIVIDER_HORIZONTAL and msg.dx) or (msg.dy)

			if value and value != 0 then
				self.split_point += value
				self.split_point = mid(0,self.split_point,self[self.axis_key]-1)
				self:update_child_positioning()
			elseif not value then
				-- fixes a literal edge case, where moving the mouse offscreen to the left makes value nil(?)
				self.split_point = 0
			end

			self.dragging = (self.mouse_clicked or self.mouse_held)
		end

		self.was_bar_hovering = self.bar_hovering
		self.was_dragging = self.dragging
		self.mouse_held = (msg.mb & 0b1 > 0)
	end

	function el:_create_empty_container()
		local container = {
			x = 0,
			y = 0,
			width = self.width,
			height = self.height,
			col = theme.color.primary
		}

		return self:attach(container)
	end

	function el:update_child_positioning()
		--lh: this is a bit dumb
		local axis_key = self.axis_key
		local axis_position = self.axis_position
		local axis_value = (self.kind == DIVIDER_HORIZONTAL and self.width) or self.height

		self.first_element.width = self.width
		self.first_element.height = self.height
		self.first_element[axis_key] = self.split_point

		self.second_element.width = self.width
		self.second_element.height = self.height
		self.second_element[axis_key] = (axis_value - self.split_point)
		self.second_element[axis_position] = self.split_point

	end

	el = self:attach(el)
	el.first_element = el:_create_empty_container()
	el.second_element = el:_create_empty_container()
	el:update_child_positioning()

	return el
end

function create_tab_container(self, el)
	el = default(el, {
		tab_height = 12,
		draw_wide_tab = false
	})

	--[[
	el.x = el.x or 0
	el.y = el.y or 0
	el.width = el.width or 1
	el.height = el.height or 1
	]]
	--el.tab_height = el.tab_height or 12

	local tab_bar_container = {
		x = 0,
		y = 0,
		height = el.tab_height,
		width = el.width,
	}

	function tab_bar_container:draw()
		rect(self.width-1, 0, self.width-1, self.height-1, theme.color.border)
	end

	function tab_bar_container:hide_other_tabs(shown_tab)
		for i in all(self.child) do
			i.container.hidden = (i != shown_tab)
		end
	end

	function tab_bar_container:update_tab_positions()
		for i = 1, #self.child do
			self.child[i].x = flr((i-1) * (self.width / #self.child))
			self.child[i].width = flr(self.width / #self.child) + (el.draw_wide_tab and 1 or 0)
		end
	end

	function tab_bar_container:_create_tab(label, container)
		local tab = {
			x = 0,
			y = 0,
			height = self.height,
			width = 0,
			--selected = false,
			label = label or "<empty>",
			container = container,
			color = theme.color.primary,
		}

		function tab:draw(msg)
			self.color = (not self.container.hidden) and theme.color.active or self.color

			rectfill(0, 0, self.width, self.height, self.color)
			rect(0, 0, self.width + 8, self.height-1, theme.color.border)
			print(self.label, 2, el.tab_height-7, theme.color.text)
			self.color = theme.color.primary
		end

		function tab:hover()
			self.color = theme.color.highlight
		end

		function tab:click()
			tab_bar_container:hide_other_tabs(self)
			--self.container.hidden = false
		end
		
		tab = self:attach(tab)
		self:update_tab_positions()

		return container, tab
		--assert(self.attach)
	end

	function el:create_tab(title, switch)
		local container = {
			x = 0,
			y = self.tab_height-1,
			width = self.width,
			height = self.height - self.tab_height,
			hidden = true
		}

		local tab

		function container:draw()
			--rectfill(0, 0, self.width,self.height, theme.color.text)
		end

		container, tab = tab_bar_container:_create_tab(title, self:attach(container))

		if switch then
			tab_bar_container:hide_other_tabs(tab)
		end

		return container, tab
	end

	function el:draw()
		--rectfill(0, self.tab_height, self.width,self.height, theme.color.background)
		
	end

	el = self:attach(el)
	el:attach(tab_bar_container)
	
	return el
end

function create_slider(self, el)
	el = default(el, {
		height = 8,
		value = 0,
		grabber_size = 17,
		steps = 2,
		axis = SLIDER_HORIZONTAL,
		smooth = false
		--grabber_height = 8
	})

	el.grabber_pos = 0
	el.last_value = 0
	el.color = theme.color.primary
	el.disabled = false

	function el:draw()
		rectfill(0, 0, self.width, self.height, theme.color.secondary)
		
		if not self.disabled then
			el:draw_nub()
		end

		rect(0, 0, self.width-1, self.height-1, theme.color.border)
		--print(self.value,0,0,7)

		el.color = theme.color.primary
	end

	function el:hover(msg)
		local _, _, _, _, wy = mouse()
		el.color = theme.color.highlight

		if wy == 0 or self.disabled then return end

		self:scroll_to_abs(self.value - wy)
	end

	function el:scroll_to_abs(v)
		-- DOES NOT WORK WITH STEPS = 0
		local endpoint = self:get_axis_endpoint()
		local real_position = mid(0, v, (self.steps == 0 or self.smooth) and endpoint or self.steps)

		self.grabber_pos = (self.steps == 0 or self.smooth) and real_position or (real_position / self.steps) * endpoint

		self:update_value(real_position)
	end
	
	function el:update_value(real_position)
		self.value = real_position or self.value

		if self.callback then
			self.callback(self.value)
		end

		self.last_value = self.value
	end

	function el:drag(msg)
		if self.disabled then return end

		el.color = theme.color.active
		--local held = msg.mb & 0b1 > 0 
		local endpoint = self:get_axis_endpoint()
		local real_position = mid(0, el:get_axis_value(msg), endpoint)
		--local snaps = ceil(1/self.steps)

		local real_value = real_position / endpoint
		local quantized_value = round(real_value * (self.steps)) --/ self.steps
		local quantized_position = (quantized_value / (self.steps)) * endpoint

		self.grabber_pos = ((self.steps == 0 or self.smooth) and real_position) or quantized_position
		self.value = (self.steps == 0 and real_value) or quantized_value

		if self.value == self.last_value then return end

		self:update_value()
	end

	if el.axis == SLIDER_HORIZONTAL then
		function el:get_axis_endpoint()
			return self.width-self.grabber_size
		end

		function el:get_axis_value(msg)
			return msg.mx-(self.grabber_size/2)
		end

		function el:draw_nub()
			rectfill(self.grabber_pos, 0, self.grabber_size+self.grabber_pos-1, self.height, self.color)
			rect(self.grabber_pos, 0, self.grabber_size+self.grabber_pos-1, self.height, theme.color.border)
		end
	elseif el.axis == SLIDER_VERTICAL then
		function el:get_axis_endpoint()
			return self.height-self.grabber_size
		end

		function el:get_axis_value(msg)
			return msg.my-(self.grabber_size/2)
		end

		function el:draw_nub()
			rectfill(0, self.grabber_pos, self.width, self.grabber_size+self.grabber_pos-1, self.color)
			rect(0, self.grabber_pos, self.width, self.grabber_size+self.grabber_pos-1, theme.color.border)
		end
	end

	return self:attach(el)
end

function create_list(self, el)
	el = default(el, {
		show_indicies = true,
		index_padding = 2,
		item_height = theme.metrics.font_height,
	})

	el.items = {}
	el.hover_item = -1
	el.selected_item = -1
	el.scroll = 0
	el.scroll_limit = 0

	el = self:attach(el)

	function el:draw()
		for i = 1, flr(self.height / self.item_height) - 1 do
			local row_idx = i + self.scroll - 1
			local v = self.items[i + self.scroll]

			assert(v)

			if not v then break end

			local color = (row_idx == (self.selected_item - 1) and theme.color.active) or (row_idx == (self.hover_item - 1) and theme.color.highlight) or theme.color.primary
			rectfill(0, (i-1)*(self.item_height+1), self.width-1, i*(self.item_height+1)-2, color)
			rectfill(0, i*(self.item_height+1)-1, self.width-1, i*(self.item_height+1)-1, theme.color.border)

			if self.index_padding > 0 then
				local prefix = string.format("%0"..self.index_padding.."x %s", row_idx, v.label)
				print(prefix, 1, (i-1)*(self.item_height+1)+1, theme.color.text)
			else
				print(self.show_indicies and (row_idx.." "..v.label) or v.label, 1, (i-1)*(self.item_height+1)+2, theme.color.text)
			end
		end

		self.hover_item = -1
	end

	function el:click(msg)
		if msg.mx > (self.width - theme.metrics.scrollbar_width) then return end

		local idx = self:get_item_idx(msg.my)
		local item = el.items[idx]

		if not item then return end

		self.selected_item = idx
		
		if item.callback then
			item.callback()
		end
	end

	function el:hover(msg)
		local _, _, _, _, wy = mouse()
		if msg.mx > (self.width - theme.metrics.scrollbar_width) then return end

		if wy != 0 then
			self.scrollbar:scroll_to_abs(mid(0, self.scroll - wy, self.scrollbar.steps))
		end

		local idx = self:get_item_idx(msg.my)

		idx = (idx <= #el.items and idx) or -1
		self.hover_item = self:get_item_idx(msg.my)
	end

	function el:get_item_idx(mouse_y)
		return ceil(mouse_y / (el.item_height+1)) + self.scroll
	end

	function el:new_item(label, callback)
		add(self.items, {
			label = label,
			callback = callback,
		})

		if #self.items < flr(self.height / self.item_height) then
			self.scrollbar.disabled = true
		else
			self.scrollbar.disabled = false
			self.scroll_limit = self.height // self.item_height - 1
			self.scrollbar.steps = (#self.items - self.scroll_limit)
		end
	end

	el.scrollbar = create_slider(el, {
		axis = SLIDER_VERTICAL,
		x = el.width - theme.metrics.scrollbar_width + 1,
		y = -1,
		width = theme.metrics.scrollbar_width,
		height = el.height + 2,
		--grabber_size = 8,
		callback = function(index)
			el.scroll = index
		end
	})

	return el
end

function create_sfx_grid(self, el)
	el = self:attach(el)

	el = default(el, {
		pattern_count = 128,
		cells_tall = 9
	})

	el.cells_wide = 8
	--el.cells_tall = 9
	el.cell_width = el.width // (el.cells_wide+1) - 1
	el.cell_height = 9
	--el.pattern_count = 128
	el.highlighted_cell = -1
	el.hovered_cell = -1
	el.hovered_row = -1
	el.hovered_column = -1
	el.hover_kind = SELECTION_NONE
	el.selection_kind = SELECTION_NONE
	el.selected_item = -1
	el.selected_row = -1
	el.selected_items = {}
	el.offset_x = 5
	el.offset_y = 2
	el.scroll = 0

	function el:draw(msg)
		camera(-self.sx-self.offset_x, -self.sy-self.offset_y)

		local rel_pattern_selection = self.selected_item - self.scroll
		local rel_pattern_hover = self.hovered_row - self.scroll

		if self.hover_kind == SELECTION_PATTERN and (rel_pattern_hover > 0)  then
			self:draw_cell(0, rel_pattern_hover, theme.color.highlight)
		end

		if self.hover_kind == SELECTION_TRACK then
			self:draw_cell(self.hovered_column, 0, theme.color.highlight)
		end

		if self.selection_kind == SELECTION_PATTERN and (rel_pattern_selection > 0 and self.selected_item < (self.cells_tall + self.scroll)) then
			self:draw_cell(0, rel_pattern_selection, theme.color.active)
		end

		if self.selection_kind == SELECTION_TRACK then
			self:draw_cell(self.selected_item, 0, theme.color.active)
		end
		
		local grid_cols = theme.color.sfx_grid

		for y = 1, self.cells_tall-1 do
			for x = 1, self.cells_wide do
				local idx = (((y + self.scroll)-1)*self.cells_wide+(x-1))
				
				if	(self.selection_kind == SELECTION_SFX and idx == self.selected_item) or
					(self.selection_kind == SELECTION_TRACK and x == self.selected_item) or
					(self.selection_kind == SELECTION_PATTERN and (y + self.scroll) == self.selected_item) then
					--self:draw_cell(x,y, theme.color.active)
				elseif	(self.hover_kind == SELECTION_SFX and idx == self.hovered_cell) or
					(self.hover_kind == SELECTION_TRACK and x == self.hovered_column) or
					(self.hover_kind == SELECTION_PATTERN and (y + self.scroll) == self.hovered_row) then
					self:draw_cell(x,y, theme.color.highlight)
				end

				local sfx_str = string.format("%02x",((y+self.scroll)-1)*self.cells_wide+x-1)
				sfx_str = string.sub(sfx_str, 0, 2)
				--if #sfx_str < 2 then sfx_str = "0"..sfx_str end
				--print(sfx_str, self.cell_width*x+1, self.cell_height*y+3, theme.color.text)
				local v_even = (y - self.scroll) % 2 == 0
				local h_even = x % 2 == 0
				
				local text_col
				if v_even then
					text_col = h_even
						and grid_cols.highlight_text_odd
						or grid_cols.highlight_text_even
				else
					text_col = h_even
						and grid_cols.text_odd
						or grid_cols.text_even
				end
				
				print(sfx_str, self.cell_width*x+1, self.cell_height*y+3, text_col)
				--rectfill(self.cell_width*x+2, self.cell_height*y+9, self.cell_width*x+6, self.cell_height*y+9, 7)
			end
		end

		--TODO: optimize, move to a x,y table
		for i in all(self.selected_items) do
			if i >= 0 then
				--local ri = i - 1
				local x = i % self.cells_wide + 1
				local y = (i // self.cells_wide) - self.scroll + 1

				if y < 1 or y > (self.cells_tall - 1) then
					goto continue
				end

				self:draw_cell(x, y, theme.color.active)

				local sfx_str = string.format("%02x",((y+self.scroll)-1)*self.cells_wide+x-1)
				sfx_str = string.sub(sfx_str, 0, 2)
				print(sfx_str, self.cell_width*x+1, self.cell_height*y+3, theme.color.sfx_grid.text_active)
			end
			::continue::
		end
		
		-- Row lines
		for y = 1, self.cells_tall-1 do
			local ry = y + self.scroll

			if self.selected_row == ry then
				rect(-5, self.cell_height*y+1, self.cell_width*(self.cells_wide + 1), self.cell_height*(y+1), theme.color.active)
			end
			--rectfill(0, self.cell_height*y, self.width, self.cell_height*y, theme.color.secondary)	
			--if y == self.cells_tall+1 then break end
			local pattern_str = string.format("%02x",ry-1)
			print("p"..pattern_str, -3, self.cell_height*y+3, grid_cols.selector_color)
		end
		
		-- Column lines
		for x = 1, self.cells_wide+1 do
			--[[
			fillp(0xa5a5)
			rectfill(self.cell_width*x-1, 0, self.cell_width*x-1, self.cell_height * (self.cells_tall+1), 21 + (1 << 8))
			fillp()
			]]
			--rectfill(self.cell_width*x-1, 0, self.cell_width*x-1, self.cell_height * (self.cells_tall+1), theme.color.secondary)
			if x == self.cells_wide+1 then break end
			print("t"..x, self.cell_width*x+1, 3, grid_cols.selector_color)
		end

		--rect(0,0,self.width-1,self.height-1,theme.color.border)
	end

	function el:update(msg)
		local mx = msg.mx -- self.offset_x
		local my = msg.my -- self.offset_y

		self.hover_kind = ((mx < 0 or my < 0) or (mx > el.width or my > el.height)) and SELECTION_NONE or self.hover_kind
	end

	--function el:draw(msg)
	--	rectfill(0,0,self.width,self.height,9)
	--end

	function el:hover(msg)
		local _, _, _, _, wy = mouse()
		local mx = msg.mx - self.offset_x
		local my = msg.my - self.offset_y
		local id = self:get_cell_id(mx, my) + (self.scroll * self.cells_wide)

		if msg.mx < (self.width - theme.metrics.scrollbar_width) and wy != 0 then
			self.scrollbar:scroll_to_abs(self.scroll - wy)
		end

		if mx < (self.cell_width) and (my > self.cell_height and my < (self.cell_height * self.cells_tall)) then
			self.hovered_row = flr(my / self.cell_height) + self.scroll
			self.hover_kind = SELECTION_PATTERN
			return
		elseif mx > (self.cell_width) and mx < (self.cell_width * (self.cells_wide + 1)) and my < (self.cell_height) then
			self.hovered_column = flr(mx / self.cell_width)
			self.hover_kind = SELECTION_TRACK
			return
		end

		if id != -1 then
			self.hovered_cell = id
			self.hover_kind = SELECTION_SFX
		else
			self.hover_kind = SELECTION_NONE
		end
	end

	function el:click(msg)
		--local selection = {}

		if msg.mx > (self.width - theme.metrics.scrollbar_width) then
			return
		end

		if self.hover_kind == SELECTION_NONE then
			self.selected_item = -1
			self.selected_row = -1
			self.selection_kind = SELECTION_NONE

			self.selected_items = {}
		elseif self.hover_kind == SELECTION_SFX then
			self.selected_item = self.hovered_cell
			self.selection_kind = SELECTION_SFX

			if not key("shift") then 
				self.selected_items = {}
			end

			--self.selected_items = {self.selected_item}
			add(self.selected_items, self.selected_item)
		elseif self.hover_kind == SELECTION_TRACK then
			self.selected_item = self.hovered_column
			self.selection_kind = SELECTION_TRACK

			if not key("shift") then 
				self.selected_items = {}
			end

			for x = 1, self.cells_wide do
				for y = 1, self.pattern_count do
					if x == self.hovered_column then
						local idx = ((y-1)*self.cells_wide+x) - 1

						add(self.selected_items, idx)
					end
				end
			end
		elseif self.hover_kind == SELECTION_PATTERN then
			self.selected_item = self.hovered_row
			self.selected_row = self.hovered_row
			self.selection_kind = SELECTION_PATTERN

			if not key("shift") then 
				self.selected_items = {}
			end

			for x = 1, self.cells_wide do
				for y = 1 + self.scroll, self.cells_tall + self.scroll do
					if y == self.hovered_row then
						local idx = ((y-1)*self.cells_wide+x) - 1

						add(self.selected_items, idx)
					end
				end
			end
		end

		if self.callback then
			self.callback(self.selected_items)
		end
	end

	function el:draw_cell(x,y,c)
		-- incredibly ugly hack for pattern labels

		if x != 0 then
			rectfill(self.cell_width*x, self.cell_height*y+1, self.cell_width*(x+1)-1, self.cell_height*(y+1), c)	
		else
			rectfill(self.cell_width*x-4, self.cell_height*y+1, self.cell_width*(x+1)-1, self.cell_height*(y+1), c)	
		end
	end

	function el:get_cell_id(mx,my)
		local x = flr(mx / self.cell_width) - 1
		local y = flr(my / self.cell_height) - 1

		if (x > -1 and x < self.cells_wide) and (y > -1 and y < (self.cells_tall-1)) then
			return (y*self.cells_wide+x)
		else
			return -1
		end
	end

	el.scrollbar = create_slider(el, {
		axis = SLIDER_VERTICAL,
		x = el.width - theme.metrics.scrollbar_width + 1,
		y = 0,
		width = theme.metrics.scrollbar_width,
		height = el.height + 1,
		steps = el.pattern_count - el.cells_tall + 1,
		callback = function(index)
			el.scroll = index
		end
	})

	return el
end

function create_tracker(self, el)
	el = self:attach(el)

	el = default(el, {
		track_rows = 48,
		track_extra_padding = 2,
		track_start_y = 38,
		--track_callback = function() end
	})

	el.player_position = 0
	el.selection = vec(0,0,0,0) -- ORIGIN X, ORIGIN Y, WIDTH, HEIGHT

	function el:draw()
		rectfill(0,1,self.width,self.height-1,0)
		rectfill(0, self.track_start_y, self.width, self.track_start_y, theme.color.border)
		for x = 0, 7 do
			self:draw_track(x * 47 + 2, 44, x)
		end
	end

	function el:draw_track(x, width, num)
		--rectfill(x, theme.metrics.padding + self.track_extra_padding, x + width, self.height - theme.metrics.padding - self.track_extra_padding, 0)
		print(num, x, 2, theme.color.text)
		rectfill(x - 2, 1, x - 2, self.height, theme.color.border)

		for y = 0, self.track_rows-1 do
			local pitch, inst, vol, effect_kind, effect_value = self.track_callback(num, y)
			
			local pitch_fmt = pitch_to_note(pitch)
			local inst_fmt = inst == 0xFF and ".." or fmt("%02x", inst)
			local vol_fmt = vol == 0xFF and ".." or fmt("%02x", vol)
			local effect_kind_fmt = effect_kind == 0 and "." or string.char(effect_kind)
			local effect_value_fmt = effect_kind == 0 and ".." or fmt("%02x", effect_value)

			local xx = print(pitch_fmt, x+1, y * theme.metrics.font_height + self.track_extra_padding + self.track_start_y + 1, theme.color.text)
			xx = print(inst_fmt, xx+1, y * theme.metrics.font_height + self.track_extra_padding + self.track_start_y + 1, theme.color.text)
			xx = print(vol_fmt, xx+1, y * theme.metrics.font_height + self.track_extra_padding + self.track_start_y + 1, theme.color.text)
			print(effect_kind_fmt..effect_value_fmt, xx+1, y * theme.metrics.font_height + self.track_extra_padding + self.track_start_y + 1, theme.color.text)
			--print(effect_kind_fmt, xx+1, y * theme.metrics.font_height + self.track_extra_padding + self.track_start_y + 1, theme.color.text)
		end
	end

	el.scrollbar = create_slider(el, {
		axis = SLIDER_VERTICAL,
		x = el.width - theme.metrics.scrollbar_width - 1,
		y = 0,
		width = theme.metrics.scrollbar_width + 1,
		height = el.height + 1,
		--steps = el.pattern_count - el.cells_tall + 1,
		callback = function(index)
			el.scroll = index
		end
	})

	return el
end

function draw_integrated_scrollbar(el)
	rectfill(el.width, 0, el.width-theme.metrics.scrollbar_width, el.height, theme.color.secondary)
	rect(el.width, 0, el.width-theme.metrics.scrollbar_width, el.height, theme.color.border)
end

function create_scrollbar(self, el)
	el = create_slider(self, el)
end

function draw_panel(x,y,width,height)
	rectfill(x,y,x+width,y+height-1,theme.color.primary)
	rect(x,y,x+width,y+height-1,theme.color.border)
end
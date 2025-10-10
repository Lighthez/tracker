-- lib stuff goes here
DIVIDER_HORIZONTAL = 0
DIVIDER_VERTICAL = 1

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

function create_panel(self, el)
	el = default(el, {
		color = 12
	})

	function el:draw()
		rectfill(0,0,self.width,self.height,self.color)
	end

	return self:attach(el)
end

function create_button(self, el)
	el = self:attach_button(el)

	function el:draw()
		rectfill(0,0,self.width,self.height,theme.color.secondary)
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
			col = rnd_not(32, theme.color.text)
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
		tab_height = 12
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

	function tab_bar_container:hide_other_tabs(shown_tab)
		for i in all(self.child) do
			i.container.hidden = (i != shown_tab)
		end
	end

	function tab_bar_container:update_tab_positions()
		for i = 1, #self.child do
			self.child[i].x = flr((i-1) * (self.width / #self.child))
			self.child[i].width = ceil(self.width / #self.child)
		end
	end

	function tab_bar_container:_create_tab(label, container)
		local tab = {
			x = 0,
			y = 0,
			height = self.height,
			width = 0,
			selected = false,
			label = label or "<empty>",
			container = container,
			debug_color = rnd_not(32, theme.color.text)
		}

		function tab:draw()
			rectfill(0, 0, self.width, self.height, self.debug_color)
			print(self.label, 1, el.tab_height-6, theme.color.text)
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

	function el:create_tab(title)
		local container = {
			x = 0,
			y = self.tab_height,
			width = self.width,
			height = self.height - self.tab_height,
			hidden = true
		}

		function container:draw()
			--rectfill(0, 0, self.width,self.height, theme.color.text)
		end

		return tab_bar_container:_create_tab(title, self:attach(container))
	end

	function el:draw()
		rectfill(0, 0, self.width,self.height, theme.color.background)
	end

	el = self:attach(el)
	el:attach(tab_bar_container)
	
	return el
end

function create_slider(self, el)
	el = default(el, {
		height = 8,
		value = 0,
		grabber_width = 17,
		steps = 2,
		smooth = false
		--grabber_height = 8
	})

	el.grabber_pos = 0
	el.last_value = 0

	function el:draw()
		rectfill(0, 0, self.width, self.height, theme.color.secondary)
		rectfill(self.grabber_pos, 0, self.grabber_width+self.grabber_pos-1, self.height, theme.color.primary)
		
		print(self.value,0,0,7)
	end

	function el:drag(msg)
		--local held = msg.mb & 0b1 > 0 
		local endpoint = self.width-self.grabber_width
		local real_position = mid(0, msg.mx-(self.grabber_width/2), endpoint)
		--local snaps = ceil(1/self.steps)

		local real_value = real_position / endpoint
		local quantized_value = round(real_value * (self.steps)) --/ self.steps
		local quantized_position = (quantized_value / (self.steps)) * (endpoint+1)

		self.grabber_pos = ((self.steps == 0 or self.smooth) and real_position) or quantized_position
		self.value = (self.steps == 0 and real_value) or quantized_value

		if self.value == self.last_value then return end

		if self.callback then
			self.callback(self.value)
		end

		self.last_value = self.value
	end

	el = self:attach(el)
end
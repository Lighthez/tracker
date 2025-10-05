-- lib stuff goes here
DIVIDER_HORIZONTAL = 0
DIVIDER_HORIZONTAL = 1

function create_button(el)
	el = el or {}
	
	el.label = el.label or "<empty>"
	local ww = #el.label*5+2--print(el.label,0,-1000,0) or 10
	el.width = el.width or ww
	el.height = el.height or 10
	
	--assert(el.width == 10)
	
	function el:draw()
		rectfill(0,0,self.width,self.height,8)
		print(self.label,1,1,2)
		--notify(e.parent)
		--assert(false)
	end
	
	return el
end

function create_split_container(el)
	el = el or {}
	
	el.x = el.x or 0
	el.y = el.y or 0
	el.width = el.width or 1
	el.height = el.height or 1
	el.split_point = el.split_point or 1
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
		local abs_x = msg.mx - self.sx
		local abs_y = msg.my - self.sy
		
		self.bar_hovering = (
			self.kind == DIVIDER_HORIZONTAL and (abs_x > ((self.split_point)-5) and abs_x < ((self.split_point)+5)) or
			(abs_y > ((self.split_point)-5) and abs_y < ((self.split_point)+5))
		)
		
		--TODO: global drag zone management, only way to make this behave consistently
		if (not self.was_bar_hovering and self.bar_hovering) then
			if self.kind == DIVIDER_HORIZONTAL then
				window{cursor=unpod("b64:bHo0ACAAAAAeAAAA8A9weHUAQyAQEATwUwdwB0AHkAcg1yAHkAdAB3AH8EM=")}
			else
				window{cursor=unpod("b64:bHo0ACgAAAAwAAAA_QhweHUAQyAQEATwBwfQJ7AHAAcAB8AH4AIAwMAHAAcAB7An0AfwCA==")}
			end
		elseif (not self.bar_hovering and self.was_bar_hovering) then
			window{cursor=1}
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
			x=0,
			y=0,
			width = self.width,
			height = self.height,
			col = rnd(32)
		}
		
		function container:draw()
			--rectfill(0,0,self.width-1,self.height-1,self.col)
		end
		
		return self:attach(container)
	end
	
	function el:attach_first(new_el)
		self.first_element = self:_create_empty_container()
		self.first_element:attach(new_el)
		self:update_child_positioning()
		return new_el
		--assert(self.first_element)
	end
	
	function el:attach_second(new_el)
		self.second_element = self:_create_empty_container()
		self.second_element:attach(new_el)
		self:update_child_positioning()
		return new_el
	end
	
	function el:update_child_positioning()
		--lh: this is a bit dumb
		local axis_key = self.axis_key
		local axis_position = self.axis_position
		local axis_value = (self.kind == DIVIDER_HORIZONTAL and self.width) or self.height

		--sassert(self.first_element)
		--assert(self.second_element)

		if self.first_element then
			--assert(false)
			self.first_element.width = self.width		
			self.first_element.height = self.height
			self.first_element[axis_key] = self.split_point
		end
		
		if self.second_element then
			--assert(false)
			self.second_element.width = self.width		
			self.second_element.height = self.height
			self.second_element[axis_key] = (axis_value - self.split_point)
			self.second_element[axis_position] = self.split_point
		end

	end

	return el
end
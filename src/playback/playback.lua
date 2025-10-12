local floor = math.floor
local round = function(x) return floor(x+0.5) end

--- Starts playing music from a specific row of a pattern.
--- @param pattern integer The pattern to start playing from.
--- @param row integer? The row to start playing from. Defaults to 0.
--- @param fade_length integer? How many milliseconds the fading effect lasts. Defaults to 0.
--- @param channel_mask integer? An 8-bit mask of which channels will be enabled during playback. Defaults to 0xFF.
--- @param row_channel integer? Which channel the row refers to. Defaults to the lowest enabled.
local function play_from(pattern, row, fade_length, channel_mask, row_channel)
	row = row or 0
	channel_mask = channel_mask or 255
	
	if channel_mask & 255 == 0 or row == 0 then
		music(pattern, fade_length, channel_mask)
		return
	end
	
	local pattern_addr = 0x30100 + pattern * 20
	local tracks = {}
	local speeds = {}
	local row_offsets = {}
	local enabled = channel_mask or peek(0x30109 + pattern * 20)
	local lowest_enabled
	local tick_offset
	for i = 0, 7 do
		tracks[i] = peek(pattern_addr + i)
		speeds[i] = peek(0x050002 + 328 * tracks[i])
		if not lowest_enabled and enabled & 1 << i != 0 then 
			lowest_enabled = i
		end
	end
	
	row_channel = row_channel or lowest_enabled
	tick_offset = row*speeds[row_channel]
	
	for i = 0, 7 do
		row_offsets[i] = round(tick_offset / speeds[i])
	end
	
	local track_length_addr = 0x050003 + 328 * tracks[lowest_enabled]
	local pattern_length = peek2(track_length_addr)
	if pattern_length <= 0 then pattern_length = peek2(0x30022) end
	
	if pattern_length >= 0 then
		poke2(track_length_addr, max(pattern_length - row_offsets[lowest_enabled], 0))
		music(pattern, fade_length, channel_mask)
		poke2(track_length_addr, pattern_length)
	end
	
	for i = 0, 7 do
		if enabled & 1 << i != 0 then
			sfx(tracks[i], i, row_offsets[i])
		end
	end
end

return {
	play_from = play_from
}
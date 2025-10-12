local floor = math.floor
local round = function(x) return floor(x+0.5) end

local function play_from(pattern, row, fade_length)
	row = row or 0
	local pattern_addr = 0x30100 + pattern * 20
	local tracks = {}
	local speeds = {}
	local row_offsets = {}
	local enabled = peek(0x30109 + pattern * 20)
	local tick_offset
	for i = 0, 7 do
		tracks[i] = peek(pattern_addr + i)
		speeds[i] = peek(0x050002 + 328 * tracks[i])
		if i == 0 then 
			tick_offset = row*speeds[0]
		end
		row_offsets[i] = round(tick_offset / speeds[i])
	end
	
	local track_length_addr = 0x050003 + 328 * tracks[0]
	local pattern_length = peek2(track_length_addr)

	poke2(track_length_addr, pattern_length - row_offsets[0])
	music(pattern, fade_length)
	poke2(track_length_addr, pattern_length)
	
	for i = 0, 7 do
		if enabled & 1 << i != 0 then
			sfx(tracks[i], i, row_offsets[i])
		end
	end
end

return {
	play_from = play_from
}
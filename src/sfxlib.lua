local copy = require "src/util".copy

--- @class Pattern
--- @field pattern_length integer
--- @field flow integer
--- @field track_mask integer
--- @field pattern_indices integer[]

--- @class Track
--- @field length integer
--- @field tick_rate integer
--- @field loop0 integer
--- @field loop1 integer
--- @field delay integer
--- @field flags integer
--- @field track_data TrackData

--- @class TrackData
--- @field pitches integer[]
--- @field instruments integer[]
--- @field volumes integer[]
--- @field effects integer[]
--- @field effect_params integer[]

--- @class Instrument
--- @field nodes Node[]
--- @field envelopes Envelope[]
--- @field wavetables Wavetable[]

--- @class Node
--- @field parent integer
--- @field operator integer
--- @field kind integer
--- @field kind_p integer
--- @field flags integer
--- @field parameter_values [NodeParam]

--- @class NodeParam
--- @field flags integer
--- @field val0 integer
--- @field val1 integer
--- @field envelope_index integer
--- @field scale integer

--- @alias EnvelopeType 0 | 1 | 2

--- @class Envelope
--- @field kind EnvelopeType
--- @field flags integer
--- @field tick_rate integer
--- @field loop0 integer
--- @field loop1 integer
--- @field start integer

--- @class Wavetable
--- @field address integer
--- @field width_bits integer
--- @field height integer

local PATTERN_COUNT <const> = 128
local TRACK_ROWS <const> = 64
local TRACK_COUNT <const> = 384
local INSTRUMENT_COUNT <const> = 64

local PATTERN_BYTES <const> = 20
local ROW_BYTES <const> = 5
local TRACK_BYTES <const> = 8 + ROW_BYTES * TRACK_ROWS
local INSTRUMENT_BYTES <const> = 512

local TYPE_HALF_LOWER <const> = -1
local TYPE_HALF_HIGHER <const> = 0
local TYPE_U8 <const> = 1
local TYPE_I8 <const> = 2
local TYPE_I16 <const> = 3
local TYPE_U16 <const> = 4
local TYPE_I32 <const> = 5
local TYPE_INSTRUMENT_NAME <const> = 6

local index_layout = {
	num_instruments = { 0, TYPE_I16 },
	num_tracks = { 2, TYPE_I16 },
	num_patterns = { 4, TYPE_I16 },
	flags = { 6, TYPE_I16 },
	instruments_address = { 8, TYPE_I32 },
	tracks_address = { 12, TYPE_I32 },
	patterns_address = { 16, TYPE_I32 },
	-- 4 bytes unused...
	tick_length = { 24, TYPE_I16 },
	default_track_length = { 26, TYPE_I16 },
	default_track_speed = { 28, TYPE_U8 },
	-- 3 bytes unused...
	patterns = {},
	tracks = {},
	instruments = {}
}

local pattern_layout = {
	pattern_length = { 0, TYPE_I16 },
	flow = { 2, TYPE_U8 },
	track_mask = { 3, TYPE_U8 },
	pattern_indicies = {
		{ 4,  TYPE_I16 },
		{ 6,  TYPE_I16 },
		{ 8,  TYPE_I16 },
		{ 10, TYPE_I16 },
		{ 12, TYPE_I16 },
		{ 14, TYPE_I16 },
		{ 16, TYPE_I16 },
		{ 18, TYPE_I16 },
	}
}

local track_layout = {
	length = { 0, TYPE_I16 },
	speed = { 1, TYPE_U8 },
	loop_point_1 = { 2, TYPE_U8 },
	loop_point_2 = { 3, TYPE_U8 },
	delay = { 4, TYPE_I8 },
	flags = { 5, TYPE_U8 },
	track_data = {}
}

local node_layout = {
	flags = { 0, TYPE_U8 },
	value_1 = { 1, TYPE_U8 },
	value_2 = { 2, TYPE_U8 },
	envelope = { 3, TYPE_HALF_LOWER },
	scale = { 3, TYPE_HALF_HIGHER }
}

local node_layout = {
	parent = { 0, TYPE_HALF_LOWER },
	operator = { 0, TYPE_HALF_HIGHER },
	kind = { 1, TYPE_HALF_LOWER },
	subtype = { 1, TYPE_HALF_HIGHER },
	flags = { 2, TYPE_U8 },
	-- 1 unused byte
	parameter_values = {}
}

local envelope_layout = {
	kind = { 0, TYPE_U8 },
	flags = { 1, TYPE_U8 },
	speed = { 2, TYPE_U8 },
	loop_point_1 = { 3, TYPE_U8 },
	loop_point_2 = { 4, TYPE_U8 },
	start = { 5, TYPE_U8 },
	-- 2 unused bytes
	attack = { 8, TYPE_U8 },
	decay = { 9, TYPE_U8 },
	sustain = { 10, TYPE_U8 },
	release = { 11, TYPE_U8 },
	freq = { 12, TYPE_U8 },
	phase = { 13, TYPE_U8 },
	func = { 14, TYPE_U8 },
	data = {}
}

local wavetable_layout = {
	address = { 0, TYPE_I16 },
	width_bits = { 2, TYPE_U8 },
	height = { 3, TYPE_U8 }
}

local instrument_layout = {
	nodes = {},
	envelopes = {},
	wavetables = {},
	-- 32 bytes unused...
	name = { 496, TYPE_INSTRUMENT_NAME }
}

--- Reads a nibble from the high or low half of the byte at a given memory address.
--- @param addr integer The address in memory to read from.
--- @param high boolean? Whether the nibble is in the high or low half of the byte.
--- @return integer ... The 4-bit integer that was read.
local function peekhalf(addr, high)
	return high and (peek(addr) >> 4) or (peek(addr) & 0xF)
end

--- Writes a nibble to the high or low half of the byte at a given memory address.
--- @param addr integer The address in memory to write to.
--- @param value integer The 4-bit value to store at the address.
--- @param high boolean? Whether the nibble goes into the high or low half of the byte.
local function pokehalf(addr, value, high)
	poke(addr, high
		and (peek(addr) & (~0xF0) | (value << 4))
		or (peek(addr) & (~0xF) | value)
	)
end

local function poke16(addr, value)
	poke8(addr, value)
	poke8(addr+8, value >> 32)
end

local function peek_text(addr)
	return string.char(peek(addr, 16))
end

--- Reads one or more signed bytes from the given memory address.
--- @param addr integer The address in memory to read from.
--- @param count integer? The number of sequential bytes to read.
--- @return integer value(s) The signed 8-bit integer read at the address.
local function peeki8(addr, count)
	if not count or count <= 1 then
		local val = peek(addr)
		return val > 127 and val - 256 or val
	end

	local u8s = { peek(addr, count) }
	local i8s = {}
	for i = 1, #u8s do
		local val = u8s[i]
		i8s[i] = val > 127 and val - 256 or val
	end

	return unpack(i8s)
end

local peek_funcs = {
	[TYPE_HALF_LOWER] = peekhalf,
	[TYPE_HALF_HIGHER] = function(a) return peekhalf(a, true) end,
	[TYPE_U8] = peek,
	[TYPE_I8] = peeki8,
	[TYPE_U16] = peek2,
	[TYPE_I16] = peek2,
	[TYPE_I32] = peek4,
	[TYPE_INSTRUMENT_NAME] = peek_text
}
local poke_funcs = {
	[TYPE_HALF_LOWER] = pokehalf,
	[TYPE_HALF_HIGHER] = function(a, v) return pokehalf(a, v, true) end,
	[TYPE_U8] = poke,
	[TYPE_I8] = poke,
	[TYPE_U16] = poke2,
	[TYPE_I16] = poke2,
	[TYPE_I32] = poke4,
	[TYPE_INSTRUMENT_NAME] = poke16
}

local function dereference_get(pointer, offset)
	offset = offset or 0
	return peek_funcs[pointer[2]](pointer[1] + offset)
end

local function dereference_set(pointer, value, offset)
	offset = offset or 0
	poke_funcs[pointer[2]](pointer[1] + offset, value)
end

local function make_pointer_metatable(layout)
	local meta = {}
	meta.__index = meta
	
	for k,v in pairs(layout) do
		meta["get_"..k] = function(self)
			return dereference_get(v, self.addr)
		end
		
		meta["set_"..k] = function(self, value)
			dereference_set(v, value, self.addr)
		end
	end
	
	return meta
end

local function make_array_of_accessors(layout, arr, count, address, size)
	local meta = {}
	meta.__index = meta
	
	for k,v in pairs(layout) do
		meta["get_"..k] = function(self)
			return dereference_get(v, address + self.item_offset)
		end
		
		meta["set_"..k] = function(self, value)
			dereference_set(v, value, address + self.item_offset)
		end
	end
	
	for i = 0, count - 1 do
		arr[i] = setmetatable({item_offset = i * size}, meta)
	end
	
	return meta
end

local function inject_array_access(tab, func_name, address, type, stride, count)
	local peek_func, poke_func = peek_funcs[type], poke_funcs[type]
	
	tab["get_"..func_name] = function(self, index)
		if index < 0 or index >= count then error(fmt("Index out of range: %i.", index)) end
		return peek_func(address + index * stride + self.item_offset)
	end
	
	tab["set_"..func_name] = function(self, index, value)
		if index < 0 or index >= count then error(fmt("Index out of range: %i.", index)) end
		return poke_func(address + index * stride + self.item_offset, value)
	end
end

--- Create an interface to the PFX6416 at the specified memory address
--- @param addr ?number
--- @return SfxInterface
function new_sfx_interface(addr, instruments_offset, tracks_offset, patterns_offset)
	addr = addr or 0x30000
	
	patterns_offset = patterns_offset or 0x100
	instruments_offset = instruments_offset or 0x10000
	tracks_offset = tracks_offset or 0x20000

	--- @class SfxInterface
	local sfx_interface = {
		addr = addr,
		patterns = {},
		tracks = {},
		instruments = {}
	}
	
	local m_index = make_pointer_metatable(index_layout)
	setmetatable(sfx_interface, m_index)
	
	local m_pattern = make_array_of_accessors(
		pattern_layout,
		sfx_interface.patterns,
		PATTERN_COUNT,
		addr + patterns_offset,
		PATTERN_BYTES
	)
	local m_track = make_array_of_accessors(
		track_layout,
		sfx_interface.tracks,
		TRACK_COUNT,
		addr + tracks_offset,
		TRACK_BYTES
	)
	local m_instrument = make_array_of_accessors(
		instrument_layout,
		sfx_interface.instruments,
		INSTRUMENT_COUNT,
		addr + instruments_offset,
		INSTRUMENT_BYTES
	)
	
	inject_array_access(m_pattern, "channel", addr + patterns_offset + 4, TYPE_I16, 2, 8)
	
	local track_row_offset = addr + tracks_offset + 8
	inject_array_access(m_track, "row_pitch", track_row_offset, TYPE_U8, 5, TRACK_ROWS)
	inject_array_access(m_track, "row_instrument", track_row_offset + 1, TYPE_U8, 5, TRACK_ROWS)
	inject_array_access(m_track, "row_volume", track_row_offset + 2, TYPE_U8, 5, TRACK_ROWS)
	inject_array_access(m_track, "row_effect", track_row_offset + 3, TYPE_U8, 5, TRACK_ROWS)
	inject_array_access(m_track, "row_effect_param", track_row_offset + 4, TYPE_U8, 5, TRACK_ROWS)
	
	local m_node = make_pointer_metatable(node_layout)
	
	for i = 0, #sfx_interface.instruments do
		local instrument = sfx_interface.instruments[i]
		local item_addr = instrument.item_offset
		
	end

	return sfx_interface
end

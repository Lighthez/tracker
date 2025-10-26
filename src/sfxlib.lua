local PATTERN_COUNT <const> = 128
local TRACK_ROWS <const> = 64
local TRACK_COUNT <const> = 384
local INSTRUMENT_COUNT <const> = 64
local NODE_COUNT <const> = 8
local NODE_PARAMETER_COUNT <const> = 7
local ENVELOPE_COUNT <const> = 8
local WAVETABLE_COUNT <const> = 4
local CHANNEL_COUNT <const> = 8

local PATTERN_BYTES <const> = 20
local ROW_BYTES <const> = 5
local TRACK_BYTES <const> = 8 + ROW_BYTES * TRACK_ROWS
local INSTRUMENT_BYTES <const> = 512
local NODE_BYTES <const> = 32
local NODE_PARAMETER_BYTES <const> = 4
local ENVELOPE_BYTES <const> = 24
local WAVETABLE_BYTES <const> = 4
local INSTRUMENT_NAME_BYTES <const> = 16

--- @alias PointerType |
--- |-1 u4 (lower)
--- |0 u4 (Higher)
--- |1 u8
--- |2 i8
--- |3 i16
--- |4 u16
--- |5 i32
--- |6 Instrument name

--- @class Pointer An absolute or relative address of a number.
--- @field [1] integer The address or address offset.
--- @field [2] PointerType The type located at the address.

local TYPE_HALF_LOWER <const> = -1 --- @type PointerType
local TYPE_HALF_HIGHER <const> = 0 --- @type PointerType
local TYPE_U8 <const> = 1 --- @type PointerType
local TYPE_I8 <const> = 2 --- @type PointerType
local TYPE_I16 <const> = 3 --- @type PointerType
local TYPE_U16 <const> = 4 --- @type PointerType
local TYPE_I32 <const> = 5 --- @type PointerType
local TYPE_INSTRUMENT_NAME <const> = 6 --- @type PointerType

local index_layout = {
	num_instruments = { 0, TYPE_I16 },
	num_tracks = { 2, TYPE_I16 },
	num_patterns = { 4, TYPE_I16 },
	flags = { 6, TYPE_I16 },
	instruments_address = { 8, TYPE_I32 },
	tracks_address = { 12, TYPE_I32 },
	patterns_address = { 16, TYPE_I32 },
	-- 4 unused bytes
	tick_length = { 24, TYPE_I16 },
	default_track_length = { 26, TYPE_I16 },
	default_track_speed = { 28, TYPE_U8 },
}

local pattern_layout = {
	pattern_length = { 0, TYPE_I16 },
	flow = { 2, TYPE_U8 },
	track_mask = { 3, TYPE_U8 },
	-- Pattern indices, i16 * 8
}

local track_layout = {
	length = { 0, TYPE_I16 },
	speed = { 2, TYPE_U8 },
	loop_point_1 = { 3, TYPE_U8 },
	loop_point_2 = { 4, TYPE_U8 },
	delay = { 5, TYPE_I8 },
	flags = { 6, TYPE_U8 },
	-- 1 unused byte
	-- Track content
}

local node_parameter_layout = {
	flags = { 0, TYPE_U8 },
	value_1 = { 1, TYPE_U8 },
	value_2 = { 2, TYPE_U8 },
	envelope = { 3, TYPE_HALF_LOWER },
	scale = { 3, TYPE_HALF_HIGHER },
}

local node_layout = {
	parent = { 0, TYPE_HALF_LOWER },
	operator = { 0, TYPE_HALF_HIGHER },
	kind = { 1, TYPE_HALF_LOWER },
	subtype = { 1, TYPE_HALF_HIGHER },
	flags = { 2, TYPE_U8 },
	-- 1 unused byte
	-- Node parameters (x7)
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
}

local wavetable_layout = {
	address = { 0, TYPE_I16 },
	width_bits = { 2, TYPE_U8 },
	height = { 3, TYPE_U8 },
}

local instrument_layout = {
	-- 8 nodes
	-- 8 envelopes
	-- 32 unused bytes
	-- 4 wavetable definitions
	name = { 496, TYPE_INSTRUMENT_NAME },
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

local function peek_instrument_name(addr)
	local len = INSTRUMENT_NAME_BYTES
	-- Searching for last null
	for i=15,0,-1 do
		if (peek(addr+i) == 0) then
			len = i
		end
	end
	return chr(peek(addr,len))
end

local function poke_instrument_name(addr, value)
	memset(addr, 0, INSTRUMENT_NAME_BYTES)
	poke(addr, ord(value,1,min(16,#value)))
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

--- @type table<PointerType, fun(address: integer): any>
local peek_funcs = {
	[TYPE_HALF_LOWER] = peekhalf,
	[TYPE_HALF_HIGHER] = function(a) return peekhalf(a, true) end,
	[TYPE_U8] = peek,
	[TYPE_I8] = peeki8,
	[TYPE_U16] = peek2,
	[TYPE_I16] = peek2,
	[TYPE_I32] = peek4,
	[TYPE_INSTRUMENT_NAME] = peek_instrument_name
}
--- @type table<PointerType, fun(address: integer, value: any)>
local poke_funcs = {
	[TYPE_HALF_LOWER] = pokehalf,
	[TYPE_HALF_HIGHER] = function(a, v) return pokehalf(a, v, true) end,
	[TYPE_U8] = poke,
	[TYPE_I8] = poke,
	[TYPE_U16] = poke2,
	[TYPE_I16] = poke2,
	[TYPE_I32] = poke4,
	[TYPE_INSTRUMENT_NAME] = poke_instrument_name
}

--- Fetches a value stored at a pointer
--- @param pointer Pointer The pointer.
--- @param offset integer The offset added to the pointer's address.
--- @return any
local function dereference_get(pointer, offset)
	offset = offset or 0
	return peek_funcs[pointer[2]](pointer[1] + offset)
end

--- Sets a value stored at a pointer
--- @param pointer Pointer The pointer.
--- @param value integer The value to assign at the address.
--- @param offset integer The offset added to the pointer's address.
local function dereference_set(pointer, value, offset)
	offset = offset or 0
	poke_funcs[pointer[2]](pointer[1] + offset, value)
end

--- Creates a metatable with __index assigned to itself
--- @return table
local function new_lookup_meta()
	local meta = {}
	meta.__index = meta
	return meta
end

--- Inserts accessors to the pointers specified at `layout` into `tab`.
--- @param tab {addr: integer, [any]: any} The table to add accessors to.
--- @param layout table<string, Pointer> A layout definition containing pointers with offsets relative to `table.addr`.
--- @return {addr: integer, [any]: any}
local function expose_pointers(tab, layout)
	for k,v in pairs(layout) do
		tab["get_"..k] = function(self)
			return dereference_get(v, self.addr)
		end
		
		tab["set_"..k] = function(self, value)
			dereference_set(v, value, self.addr)
		end
	end
	
	return tab
end

--- Populates an array with tables that have addresses based on even spacing, and sets
--- their metatable to the one provided.
--- @param arr [{addr: integer, [any]: any}]
--- @param meta table
--- @param count integer
--- @param address integer
--- @param size integer
--- @return table
local function make_address_array(arr, meta, count, address, size)
	for i = 0, count - 1 do
		arr[i] = setmetatable({addr = address + i * size}, meta)
	end
	
	return arr
end

--- Creates accessors that take in an index in an array of the type. 
--- @param tab table
--- @param offset integer
--- @param func_name string
--- @param type PointerType
--- @param stride integer
--- @param count integer
--- @return table
local function inject_array_access(tab, offset, func_name, type, stride, count)
	local peek_func, poke_func = peek_funcs[type], poke_funcs[type]
	
	tab["get_"..func_name] = function(self, index)
		if index < 0 or index >= count then error(fmt("Index out of range: %i.", index)) end
		return peek_func(self.addr + offset + index * stride)
	end
	
	tab["set_"..func_name] = function(self, index, value)
		if index < 0 or index >= count then error(fmt("Index out of range: %i.", index)) end
		return poke_func(self.addr + offset + index * stride, value)
	end
	
	return tab
end

--- Create an interface to the PFX6416 at the specified memory address
--- @param addr ?number
--- @return SfxInterface
function new_sfx_interface(addr, instruments_offset, tracks_offset, patterns_offset)
	addr = addr or 0x30000
	
	patterns_offset = patterns_offset or 0x100
	instruments_offset = instruments_offset or 0x10000
	tracks_offset = tracks_offset or 0x20000
	
	local m_pattern = expose_pointers(new_lookup_meta(), pattern_layout)
	local m_track = expose_pointers(new_lookup_meta(), track_layout)
	local m_instrument = expose_pointers(new_lookup_meta(), instrument_layout)
	
	inject_array_access(m_track, 8,  "row_pitch",        TYPE_U8, 5, TRACK_ROWS)
	inject_array_access(m_track, 9,  "row_instrument",   TYPE_U8, 5, TRACK_ROWS)
	inject_array_access(m_track, 10, "row_volume",       TYPE_U8, 5, TRACK_ROWS)
	inject_array_access(m_track, 11, "row_effect",       TYPE_U8, 5, TRACK_ROWS)
	inject_array_access(m_track, 12, "row_effect_param", TYPE_U8, 5, TRACK_ROWS)
	
	--- @class SfxInterface
	local sfx_interface = {
		addr = addr,
		patterns = make_address_array(
			{},
			m_pattern,
			PATTERN_COUNT,
			addr + patterns_offset,
			PATTERN_BYTES
		),
		tracks = make_address_array(
			{},
			m_track,
			TRACK_COUNT,
			addr + tracks_offset,
			TRACK_BYTES
		),
		instruments = make_address_array(
			{},
			m_instrument,
			INSTRUMENT_COUNT,
			addr + instruments_offset,
			INSTRUMENT_BYTES
		),
	}
	
	local m_index = expose_pointers(new_lookup_meta(), index_layout)
	setmetatable(sfx_interface, m_index)
	
	local m_node_parameter = expose_pointers(new_lookup_meta(), node_parameter_layout)
	local m_node = expose_pointers(new_lookup_meta(), node_layout)
	local m_envelope = expose_pointers(new_lookup_meta(), envelope_layout)
	local m_wavetable = expose_pointers(new_lookup_meta(), wavetable_layout)
	for i = 0, INSTRUMENT_COUNT - 1 do
		local instrument = sfx_interface.instruments[i]
		
		instrument.nodes = make_address_array(
			{},
			m_node,
			NODE_COUNT,
			instrument.addr,
			NODE_BYTES
		)
		
		for j = 0, NODE_COUNT - 1 do
			local node = instrument.nodes[j]
				node.parameters = make_address_array(
				{},
				m_node_parameter,
				NODE_PARAMETER_COUNT,
				node.addr + 4,
				NODE_PARAMETER_BYTES
			)
		end
		
		instrument.envelopes = make_address_array(
			{},
			m_envelope,
			ENVELOPE_COUNT,
			instrument.addr + 256,
			ENVELOPE_BYTES
		)
		
		instrument.wavetables = make_address_array(
			{},
			m_wavetable,
			WAVETABLE_COUNT,
			instrument.addr + 480,
			WAVETABLE_BYTES
		)
	end
	
	inject_array_access(m_pattern, 4, "channel", TYPE_I16, 2, CHANNEL_COUNT)

	return sfx_interface
end

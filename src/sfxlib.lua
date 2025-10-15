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

--- Create an interface to the PFX6416 at the specified memory address
--- @param addr ?number
--- @return sfx
function sfx_interface(addr)
	local TYPE_HALF_LOWER = -1
	local TYPE_HALF_HIGHER = 0
	local TYPE_U8 = 1
	local TYPE_I8 = 2
	local TYPE_I16 = 3
	local TYPE_U16 = 4
	local TYPE_I32 = 5
	local TYPE_INSTRUMENT_NAME = 6

	addr = addr or 0x30000

	--- @class sfx
	--- @field addr number
	--- @field num_instruments number
	--- @field num_tracks number
	--- @field num_patterns number
	--- @field flags number
	--- @field instruments_address number
	--- @field tracks_address number
	--- @field patterns_address number
	--- @field tick_length number
	--- @field default_track_length number
	--- @field default_track_speed number
	--- @field patterns table<integer, Pattern>
	--- @field tracks table<integer, Track>
	--- @field instruments table<integer, Instrument>
	local sfx = {
		addr = addr
	}

	local peek_funcs = {
		[TYPE_HALF_LOWER] = peekhalf,
		[TYPE_HALF_HIGHER] = function(a) return peekhalf(a, true) end,
		[TYPE_U8] = peek,
		[TYPE_I8] = peeki8,
		[TYPE_U16] = peek2,
		[TYPE_I16] = peek2,
		[TYPE_I32] = peek4,
	}
	local poke_funcs = {
		[TYPE_HALF_LOWER] = pokehalf,
		[TYPE_HALF_HIGHER] = function(a, v) return pokehalf(a, v, true) end,
		[TYPE_U8] = poke,
		[TYPE_I8] = poke,
		[TYPE_U16] = poke2,
		[TYPE_I16] = poke2,
		[TYPE_I32] = poke4,
	}

	local function generate_template(template, index, mul_offset, const_offsest)
		local template_copy = copy(template)
		for i = 1, #template_copy do
			template_copy[i][1] += index * mul_offset + const_offsest
		end

		return template_copy
	end

	local function create_indexer(get_rel_address, index_table)
		return function(_, k)
			local rel_addr = get_rel_address(k)
			local v = index_table[k]

			if type(v[1]) != "table" then
				return { v[1] + rel_addr, v[2] }
			end

			return v
		end
	end

	local create_indexer = {}

	function create_indexer.doit(tab, address)
		assert(type(address) == "number", "address: " .. type(address))
		return function(_, k)
			local branch = tab[k]
			local is_leaf = branch and branch[1] and type(branch[1]) != "table"
			if is_leaf then
				local intrinsic_type = branch[2]
				notify(tab.depth)
				local rel_addr = branch[1] + address
				return peek_funcs[intrinsic_type](rel_addr)
			end

			return setmetatable({ depth = (tab.depth or 0) + 1 }, {
				__index = create_indexer.doit(branch, address)
			})
		end
	end

	local function try_dereference(pointer)
		if not pointer or not pointer[1] or type(pointer[1]) != "number" then return pointer end
		peek_funcs[pointer[2]](pointer[1])
	end

	local m_pointers = {
		__index = function(self, key) return try_dereference(self[key]) end
	}

	--TODO: use the enums damnit
	local main_address_table = setmetatable({
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
	}, m_pointers)

	local function create_pattern(index)
		local rel_addr = index * 20 + sfx.patterns_address

		return setmetatable({
			pattern_length = { rel_addr + 0, TYPE_I16 },
			flow = { rel_addr + 2, TYPE_U8 },
			track_mask = { rel_addr + 3, TYPE_U8 },
			pattern_indicies = setmetatable({
				{ rel_addr + 4,  TYPE_I16 },
				{ rel_addr + 6,  TYPE_I16 },
				{ rel_addr + 8,  TYPE_I16 },
				{ rel_addr + 10, TYPE_I16 },
				{ rel_addr + 12, TYPE_I16 },
				{ rel_addr + 14, TYPE_I16 },
				{ rel_addr + 16, TYPE_I16 },
				{ rel_addr + 18, TYPE_I16 },
			}, m_pointers)
		}, m_pointers)
	end

	local pattern_address_table = {
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

	local track_table = {
		length = { 0, TYPE_I16 },
		speed = { 1, TYPE_U8 },
		loop_point_1 = { 2, TYPE_U8 },
		loop_point_2 = { 3, TYPE_U8 },
		delay = { 4, TYPE_I8 },
		flags = { 5, TYPE_U8 },
		track_data = {}
	}

	local node_parameter_table = {
		flags = { 0, TYPE_U8 },
		value_1 = { 1, TYPE_U8 },
		value_2 = { 2, TYPE_U8 },
		envelope = { 3, TYPE_HALF_LOWER },
		scale = { 3, TYPE_HALF_HIGHER }
	}

	local node_table = {
		parent = { 0, TYPE_HALF_LOWER },
		operator = { 0, TYPE_HALF_HIGHER },
		kind = { 1, TYPE_HALF_LOWER },
		subtype = { 1, TYPE_HALF_HIGHER },
		flags = { 2, TYPE_U8 },
		-- 1 unused byte
		parameter_values = {}
	}

	for i = 0, 6 do
		node_table.parameter_values[i] = generate_template(node_parameter_table, i, 4, 3)
	end

	local envelope_table = {
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

	for i = 0, 15 do
		envelope_table.data[i] = { i + 8, TYPE_U8 }
	end

	local wt_table = {
		address = { 0, TYPE_I16 },
		width_bits = { 2, TYPE_U8 },
		height = { 3, TYPE_U8 }
	}

	local instrument_table = {
		nodes = {},
		envelopes = {},
		wavetables = {},
		-- 32 bytes unused...
		name = { 496, TYPE_INSTRUMENT_NAME }
	}
	for i = 0, 7 do
		instrument_table.nodes[i] = generate_template(node_table, i, 32, 0)
	end

	for i = 0, 7 do
		instrument_table.envelopes[i] = generate_template(envelope_table, i, 24, 192)
	end

	for i = 0, 3 do
		instrument_table.envelopes[i] = generate_template(wt_table, i, 4, 224)
	end

	-- setmetatable(main_address_table.patterns, {
	-- 	__index = function(_, index)
	-- 		if type(index) ~= "number" then return end
	-- 		return create_indexer.doit(pattern_address_table, index * 20 + sfx.patterns_address)
	-- 	end
	-- })

	setmetatable(main_address_table.tracks, {
		__index = function(_, index)
			if type(index) ~= "number" then return end
			local track_address
			if main_address_table.flags & 0b1 > 0 then
				track_address = index * 328 + 0x20000
			else
				--TODO: search for track indicies, keep track of them somehow
				track_address = sfx.tracks_address
			end

			return create_indexer.doit(track_table, track_address)
		end
	})

	setmetatable(main_address_table.instruments, {
		__index = function(_, index)
			if type(index) ~= "number" then return end
			return create_indexer.doit(instrument_table, index * 512 + sfx.instruments_address)
		end
	})

	--TODO: reuse code
	setmetatable(sfx, {
		__index = main_address_table,

		__newindex = function(self, k, v)
			local type = main_address_table[k][2]
			local rel_addr = main_address_table[k][1] + self.addr

			poke_funcs[type](rel_addr, v)
		end
	})

	for i = 0, main_address_table.num_patterns - 1 do
		main_address_table.patterns[i] = create_pattern(i)
	end

	return sfx
end

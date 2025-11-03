local floor,ceil = math.floor, math.ceil

--- Populates missing values in `a` with values from `b`
--- @param a table The table to be populated with default values.
--- @param b table The table which contains default values to add to `a`.
--- @return table a `a` after being populated with default values.
local function default(a, b)
	a = a or {}

	for k, v in pairs(b) do
		local v_is_table = type(v) == "table"

		if not a[k] then
			a[k] = v_is_table and default({}, v) or v
		elseif type(a[k]) == "table" and v_is_table then
			a[k] = default(a[k], v)
		end
	end

	return a
end

--- Makes a deep copy of `tab`. Immutable reference types are shared. Mutable reference types and value types are copied.
--- @param tab table The table to copy.
--- @return table clone A copy of tab that shares no mutable references.
local function copy(tab)
	local copied = {}
	for k, v in pairs(tab) do
		if type(v) == "table" then
			copied[k] = copy(v)
		elseif type(v) == "userdata" then
			copied[k] = v:copy()
		else
			copied[k] = v
		end
	end

	return copied
end

--- Rounds `num` to the nearest integer. If the fractional part of the value is `1/2`, it will be rounded away from 0.
--- @param num number The value to round.
--- @return integer rounded The rounded value.
function round(num)
	return num >= 0 and floor(num + 0.5) or ceil(num - 0.5)
end

local pitch_to_note_lookup = {
	[0] = "c-",
	[1] = "c#",
	[2] = "d-",
	[3] = "d#",
	[4] = "e-",
	[5] = "f-",
	[6] = "f#",
	[7] = "g-",
	[8] = "g#",
	[9] = "a-",
	[10] = "a#",
	[11] = "b-",
}

local function pitch_to_note(pitch)
	if pitch == 255 then return "..." end
	return fmt("%s%1i", pitch_to_note_lookup[pitch % 12], pitch // 12)
end

local function p8scii_col(col)
	return col >= 10 and chr(87 + col) or chr(48 + col)
end

return {
	default = default,
	copy = copy,
	pitch_to_note = pitch_to_note,
	p8scii_col = p8scii_col,
}
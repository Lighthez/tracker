function read_track(index)
    local addr = 0
    local track_length = peek2(addr + 0x50000) * 5
    local search = 0

    if not track_length then return end

    while search < index do
		---@cast track_length integer
        addr = track_length
        track_length = peek2(addr + 0x50000) * 5
        search += 1
    end

	---@cast track_length integer
    return userdata("u8", track_length):poke(addr)
end

function read_pattern(index)
    return userdata("u8", 20):poke(0x30020 + 20 * index)
end

function read_instrument(index)
    return userdata("u8", 512):poke(0x40000 + 512 * index)
end

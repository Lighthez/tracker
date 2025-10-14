--- @class sfx
--TODO: document...

--- Create an interface to the PFX6416 at the specified memory address
--- @param addr number 
--- @return sfx 
function sfx_interface(addr = 0x30000)
    local TYPE_HALF_LOWER = -1
    local TYPE_HALF_HIGHER = 0
    local TYPE_U8 = 1
    local TYPE_I16 = 2
    local TYPE_I32 = 3

    local sfx = {
        addr = addr
    }

    local function recurse_index(offset, table)
        local inner_table = {}

        for i in all(table) do
            if type(i[1] == "table") then
                local inner_inner_table = recurse_index(offset, i)
                add(inner_table, inner_inner_table)
            else
                add(inner_table, {i[1] + offset, i[2]})
            end
        end

        return inner_table
    end

    local function indexer(offset, index_table)
        return function(self, k)
            local rel_addr = offset(k)

            if type(index_table[k][1]) == "table" then
                return recurse_index(rel_addr, index_table[k])
            end

            return {index_table[k][1] + rel_addr, index_table[k][2]}
        end
    end

    --TODO: use the enums damnit
    local main_address_table = {
        num_instruments = {0,2},
        num_tracks = {2,2},
        num_patterns = {4,2},
        flags = {6,2},
        instruments_address = {8,4},
        tracks_address = {12,4},
        patterns_address = {16,4},
        -- 4 bytes unused...
        tick_length = {24,4},
        default_track_length = {26,2},
        default_track_speed = {28,2},
        -- 3 bytes unused...
        patterns = {},
        tracks = {},
        instruments = {}
    }

    local pattern_address_table = {
        pattern_length = {0,2},
        flow = {2,2},
        track_mask = {3,1},
        pattern_indicies = {
            {4,2},
            {6,2},
            {8,2},
            {10,2},
            {12,2},
            {14,2},
            {16,2},
            {18,2},
        }
    }

    local track_table = {}
    local instrument_table = {}

    setmetatable(main_address_table.patterns, {
        __index = indexer(
            function(k)
                return rawget(main_address_table, "patterns_address")[1] + k * 24 + 12
            end,
            main_address_table
        )
    })

    --TODO: reuse code
    setmetatable(sfx, {
        __index = function(self, k)
            local type = main_address_table[k][2]
            local rel_addr = main_address_table[k][1] + self.addr

            if type == TYPE_U8 then
                peek(rel_addr, v)
            elseif type == TYPE_I16 then
                peek2(rel_addr, v)
            end
        end,

        __newindex = function(self, k, v)
            local type = main_address_table[k][2]
            local rel_addr = main_address_table[k][1] + self.addr

            if type == TYPE_U8 then
                poke(rel_addr, v)
            elseif type == TYPE_I16 then
                poke2(rel_addr, v)
            end
        end
    })

    return sfx
end

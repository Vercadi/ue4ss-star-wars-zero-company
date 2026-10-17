-- UE4SS for Star Wars Zero Company v1.1.2.
-- Keeps v1.1.1 patterns, hooks and disk validation; adds one guarded EA identity.
-- EA 197649 runtime feedback pending at release. See SUPPORTED_BUILDS.txt.
local label = "StaticConstructObject"
local patterns = {
    "4C 8B DC 55 53 41 56 49 8D AB ?? FE FF FF 48 81 EC ?? 02 00 00 48 8B 05 ?? ?? ?? ?? 48 33 C4 48 89 85 ?? 01 00 00 8B 41 70"
}
local function validate_entry(bytes)
    local frame = string.unpack("<i4", bytes, 11)
    local allocation = string.unpack("<I4", bytes, 18)
    local cookie = string.unpack("<I4", bytes, 35)
    -- Relationships observed in both historical and current prologue bytes.
    return frame < 0 and allocation % 16 == 0
        and allocation + frame == 0xe8 and allocation - cookie == 0x120
end

local expected
local source = debug.getinfo(1, "S").source
local directory = source:match("^@(.+)[/\\][^/\\]+$")
local executable = directory and (directory .. "/../../SWZeroCompany.exe")

local function reject(message)
    error("[SWZC " .. label .. "] " .. message .. "; signature rejected", 0)
end

local function inspect(file)
    local length = assert(file:seek("end"))
    local function read(offset, count)
        if offset < 0 or count < 0 or offset + count > length then reject("invalid executable bounds") end
        assert(file:seek("set", offset))
        local bytes = file:read(count)
        if not bytes or #bytes ~= count then reject("short executable read") end
        return bytes
    end
    local function u16(offset) return string.unpack("<I2", read(offset, 2)) end
    local function u32(offset) return string.unpack("<I4", read(offset, 4)) end
    if length > 1024 * 1024 * 1024 or read(0, 2) ~= "MZ" then reject("unsupported executable") end
    local nt = u32(0x3c)
    if nt < 0x40 or nt > 0x100000 or read(nt, 4) ~= "PE\0\0" then reject("invalid PE header") end
    if u16(nt + 4) ~= 0x8664 then reject("expected Windows x64 executable") end
    local sections_count, optional_size = u16(nt + 6), u16(nt + 20)
    local optional = nt + 24
    if sections_count < 1 or sections_count > 96 or optional_size < 144 or u16(optional) ~= 0x20b then
        reject("unsupported PE layout")
    end
    local image_size, stamp = u32(optional + 56), u32(nt + 8)
    if u32(optional + 108) < 4 then reject("missing exception directory") end
    local exception_rva, exception_size = u32(optional + 136), u32(optional + 140)
    local sections = {}
    for i = 0, sections_count - 1 do
        local at = optional + optional_size + i * 40
        local section = {rva = u32(at + 12), size = u32(at + 16), offset = u32(at + 20), flags = u32(at + 36)}
        if section.offset + section.size > length then reject("section exceeds executable") end
        sections[#sections + 1] = section
    end
    local function file_offset(rva, size)
        for _, section in ipairs(sections) do
            if rva >= section.rva and rva + size <= section.rva + section.size then
                return section.offset + rva - section.rva
            end
        end
        reject("RVA is not file-backed")
    end
    local found, selected, target_rva, entry
    for _, pattern in ipairs(patterns) do
        local tokens, lua_pattern = {}, {}
        for token in pattern:gmatch("%S+") do
            tokens[#tokens + 1] = token
            if token == "??" then
                lua_pattern[#lua_pattern + 1] = "."
            else
                local byte = string.char(assert(tonumber(token, 16)))
                if byte:find("[%(%)%.%%%+%-%*%?%[%]%^%$]") then byte = "%" .. byte end
                lua_pattern[#lua_pattern + 1] = byte
            end
        end
        local matcher, width = table.concat(lua_pattern), #tokens
        for _, section in ipairs(sections) do
            if (section.flags & 0x20000000) ~= 0 then
                local cursor = 0
                while cursor < section.size do
                    local count = math.min(1024 * 1024, section.size - cursor)
                    local extra = math.min(width - 1, section.size - cursor - count)
                    local chunk = read(section.offset + cursor, count + extra)
                    local start = 1
                    while true do
                        local position = chunk:find(matcher, start)
                        if not position or position > count then break end
                        local offset = section.offset + cursor + position - 1
                        if found and found ~= offset then reject("multiple function candidates") end
                        found, selected = offset, pattern
                        target_rva = section.rva + cursor + position - 1
                        entry = chunk:sub(position, position + width - 1)
                        start = position + 1
                    end
                    cursor = cursor + count
                end
            end
        end
    end
    if not found then reject("no recognized function entry in executable") end
    if not validate_entry(entry) then reject("inconsistent function prologue") end
    if exception_size < 12 or exception_size > 16 * 1024 * 1024 or exception_size % 12 ~= 0 then
        reject("invalid exception table")
    end
    local exception_offset = file_offset(exception_rva, exception_size)
    -- PE exception entries are ordered by their BeginAddress RVA.
    local low, high, is_entry = 0, exception_size // 12 - 1, false
    while low <= high do
        local mid = (low + high) // 2
        local start_rva = u32(exception_offset + mid * 12)
        if start_rva == target_rva then
            is_entry = u32(exception_offset + mid * 12 + 4) > target_rva
            break
        elseif start_rva < target_rva then low = mid + 1 else high = mid - 1 end
    end
    if not is_entry then reject("match is not an unwind-table function start") end
    return {pattern = selected, rva = target_rva, nt = nt, stamp = stamp, image_size = image_size}
end

-- Derive addresses from loaded code, never from stored function RVAs.
-- The fallback is restricted to the listed EA builds by PE/CodeView identity.
-- Unwind profiles narrow the candidates; full AOBs and target checks still apply.
local function inspect_loaded(file)
    local length = assert(file:seek("end"))
    local function read(offset, count)
        if offset < 0 or count < 0 or offset + count > length then reject("invalid fallback file bounds") end
        assert(file:seek("set", offset))
        local value = file:read(count)
        if not value or #value ~= count then reject("short fallback file read") end
        return value
    end
    local function u16(at) return string.unpack("<I2", read(at, 2)) end
    local function u32(at) return string.unpack("<I4", read(at, 4)) end
    local function from_hex(text)
        return (text:gsub("%x%x", function(pair) return string.char(tonumber(pair, 16)) end))
    end
    local nt = u32(0x3c)
    local optional = nt + 24
    if nt > 0x100000 or read(0, 2) ~= "MZ"
        or read(nt, 4) ~= "PE\0\0" or u16(nt + 4) ~= 0x8664
        or u16(optional) ~= 0x20b or u16(nt + 20) ~= 240
        or u32(optional + 108) < 7 then reject("loaded fallback has no verified build profile") end
    -- Metadata identities only: function addresses still come from validated loaded code.
    -- 196985 has prior runtime evidence; 197649 has offline checks only at release.
    local builds = {
        {version = "196985", length = 269863568, stamp = 0x29323a64, image_size = 0x1078b000,
         codeview_offset = 0xeb84420, codeview_rva = 0xeb85620,
         identity = "52534453f58d2b49e67d7fa8c66e3c136ba4a8da0100000053575a65726f436f6d70616e792e70646200"},
        {version = "197649", length = 269872272, stamp = 0x1fc2bc86, image_size = 0x1078c000,
         codeview_offset = 0xeb861a0, codeview_rva = 0xeb86ba0,
         identity = "5253445369a4be52c2dd0d37915cfed2e6b034b60100000053575a65726f436f6d70616e792e70646200"}
    }
    local build_profile
    for _, candidate in ipairs(builds) do
        if length == candidate.length and u32(nt + 8) == candidate.stamp
            and u32(optional + 56) == candidate.image_size then
            build_profile = candidate
            break
        end
    end
    if not build_profile then reject("loaded fallback has no verified build profile") end
    local identity = from_hex(build_profile.identity)
    if read(build_profile.codeview_offset, #identity) ~= identity then reject("EA CodeView identity differs from verified build") end
    local image_size = u32(optional + 56)
    local sections, count = {}, u16(nt + 6)
    if count < 1 or count > 96 then reject("invalid fallback section count") end
    for i = 0, count - 1 do
        local at = optional + 240 + i * 40
        local s = {header = at, virtual_size = u32(at + 8), rva = u32(at + 12),
                   size = u32(at + 16), offset = u32(at + 20), flags = u32(at + 36)}
        if s.offset + s.size > length or s.rva + math.max(s.size, s.virtual_size) > image_size then
            reject("fallback section exceeds image bounds")
        end
        sections[#sections + 1] = s
    end
    local function section_for(rva, size)
        for _, s in ipairs(sections) do
            if rva >= s.rva and rva + size <= s.rva + s.virtual_size then return s end
        end
        reject("fallback RVA exceeds mapped section")
    end
    -- Metadata sections are read once for this startup pass; buffers are not retained in the result.
    local metadata = {}
    local function at_rva(rva, size)
        for _, s in ipairs(sections) do
            if rva >= s.rva and rva + size <= s.rva + s.size then
                if (s.flags & 0x20000000) ~= 0 or s.size > 64 * 1024 * 1024 then reject("unsupported metadata section") end
                if not metadata[s] then metadata[s] = read(s.offset, s.size) end
                return metadata[s]:sub(rva - s.rva + 1, rva - s.rva + size)
            end
        end
        reject("fallback metadata is not file-backed")
    end
    local function dword(rva) return string.unpack("<I4", at_rva(rva, 4)) end
    local function is_code(rva, size) return (section_for(rva, size).flags & 0x20000000) ~= 0 end
    -- Obtain the actual module base through two named exports. Neither export is called.
    local export_rva, export_size = u32(optional + 112), u32(optional + 116)
    local exports = at_rva(export_rva, 40)
    local functions, names, function_table, name_table, ordinal_table = string.unpack("<I4I4I4I4I4", exports, 21)
    if functions < 2 or names < 2 or functions > 100000 or names > 100000 then reject("invalid export directory") end
    local base, anchors = nil, 0
    for i = 0, math.min(names, 8) - 1 do
        local name_rva = dword(name_table + i * 4)
        local bytes = at_rva(name_rva, 512)
        local stop = bytes:find("\0", 1, true)
        if not stop then reject("unterminated export name") end
        local ordinal = string.unpack("<I2", at_rva(ordinal_table + i * 2, 2))
        if ordinal >= functions then reject("invalid export ordinal") end
        local function_rva = dword(function_table + ordinal * 4)
        if not (function_rva >= export_rva and function_rva < export_rva + export_size) and is_code(function_rva, 1) then
            local address = LoadExport(bytes:sub(1, stop - 1))
            if math.type(address) ~= "integer" or address == 0 then reject("cannot resolve game export anchor") end
            local found_base = address - function_rva
            if found_base <= 0 or found_base % 0x10000 ~= 0 or (base and base ~= found_base) then
                reject("game export anchors disagree")
            end
            base, anchors = found_base, anchors + 1
            if anchors == 2 then break end
        end
    end
    if anchors ~= 2 then reject("not enough game export anchors") end
    local reads = 0
    local function live_u32(rva)
        if rva < 0 or rva + 4 > image_size then reject("loaded read exceeds image") end
        reads = reads + 1
        if reads > 250000 then reject("loaded validation read budget exceeded") end
        local value = DerefToInt32(base + rva)
        -- This UE4SS API also returns nil for an all-zero DWORD. Never treat nil as valid data.
        if math.type(value) ~= "integer" then reject("loaded validation read unavailable") end
        return value & 0xffffffff
    end
    local function live_bytes(rva, size)
        local parts = {}
        for off = 0, size - 1, 4 do parts[#parts + 1] = string.pack("<I4", live_u32(rva + off)) end
        return table.concat(parts):sub(1, size)
    end
    if (live_u32(0) & 0xffff) ~= 0x5a4d or live_u32(0x3c) ~= nt
        or live_u32(nt) ~= 0x4550 or live_u32(nt + 8) ~= build_profile.stamp
        or live_u32(optional + 56) ~= image_size or live_bytes(build_profile.codeview_rva, #identity) ~= identity then
        reject("loaded image identity differs from executable")
    end
    for _, s in ipairs(sections) do
        for _, field in ipairs({{8, s.virtual_size}, {12, s.rva}, {16, s.size}, {20, s.offset}, {36, s.flags}}) do
            if live_u32(s.header + field[1]) ~= field[2] then reject("loaded section table differs from executable") end
        end
    end
    local exception_rva, exception_size = u32(optional + 136), u32(optional + 140)
    if exception_size < 12 or exception_size > 16 * 1024 * 1024 or exception_size % 12 ~= 0
        or live_u32(optional + 136) ~= exception_rva or live_u32(optional + 140) ~= exception_size then
        reject("invalid loaded exception directory")
    end
    local pdata = at_rva(exception_rva, exception_size)
    local profile = from_hex("192605001501560007e005300450")
    local compiled = {}
    for _, pattern in ipairs(patterns) do
        local out, prefix, tokens = {}, {}, {}
        for token in pattern:gmatch("%S+") do
            local b = token ~= "??" and string.char(tonumber(token, 16)) or nil
            prefix[#prefix + 1] = b or "\0"
            tokens[#tokens + 1] = token
            if b and b:find("[%(%)%.%%%+%-%*%?%[%]%^%$]") then b = "%" .. b end
            out[#out + 1] = b or "."
        end
        compiled[#compiled + 1] = {pattern = pattern, matcher = table.concat(out), width = #out,
                                   prefix = string.unpack("<I4", table.concat(prefix)), tokens = tokens}
    end
    local function match_bytes(rva, c)
        local parts = {}
        for off = 0, c.width - 1, 4 do
            local bytes = string.pack("<I4", live_u32(rva + off))
            for j = 1, math.min(4, c.width - off) do
                local token = c.tokens[off + j]
                if token ~= "??" and bytes:byte(j) ~= tonumber(token, 16) then return nil end
            end
            parts[#parts + 1] = bytes
        end
        return table.concat(parts):sub(1, c.width)
    end
    local unwind_cache, candidates = {}, 0
    local selected, target, entry, last = nil, nil, nil, -1
    for pos = 1, #pdata, 12 do
        local start, finish, unwind = string.unpack("<I4I4I4", pdata, pos)
        if start <= last or finish <= start or finish > image_size then reject("invalid function table ordering or bounds") end
        last = start
        local compatible = unwind_cache[unwind]
        if compatible == nil then
            compatible = at_rva(unwind, #profile) == profile
            unwind_cache[unwind] = compatible
        end
        if compatible then
            candidates = candidates + 1
            if candidates > 65536 or not is_code(start, 4) then reject("unsupported unwind candidate set") end
            local prefix = live_u32(start)
            for _, c in ipairs(compiled) do
                if prefix == c.prefix then
                    if not is_code(start, c.width) then reject("function pattern crosses executable section") end
                    local bytes = match_bytes(start, c)
                    if bytes then
                        if not validate_entry(bytes) then reject("inconsistent loaded function prologue") end
                        if live_bytes(exception_rva + pos - 1, 12) ~= pdata:sub(pos, pos + 11)
                            or live_bytes(unwind, #profile) ~= profile then reject("loaded function metadata differs from executable") end
                        if target and target ~= start then reject("multiple validated loaded function candidates") end
                        selected, target, entry = c.pattern, start, bytes
                    end
                end
            end
        end
    end
    if not target then reject("no validated loaded function entry") end
    local result = {pattern = selected, rva = target, nt = nt, stamp = build_profile.stamp,
                    image_size = image_size, memory_base = base, loaded = true}
    local function reference(displacement, next_instruction)
        return target + next_instruction + string.unpack("<i4", entry, displacement + 1)
    end
    if label == "GUObjectArray" then
        local global = reference(113, 117) - 0x10
        if reference(7, 11) ~= global + 0x30 or reference(25, 29) ~= global + 0x30
            or reference(40, 44) ~= global + 0x88 or reference(100, 104) ~= global + 0x88
            or reference(119, 127) ~= global + 0xb0 or reference(143, 148) ~= global + 0xb4 then
            reject("loaded initializer references disagree about object-array layout")
        end
        local s = section_for(global, 0xb8)
        if global % 8 ~= 0 or (s.flags & 0x80000000) == 0 or (s.flags & 0x20000000) ~= 0 then
            reject("loaded object-array target is not aligned writable data")
        end
        result.result_rva = global
    elseif label == "ProcessLocalScriptFunction" then
        local natives = reference(45, 49)
        local s = section_for(natives, 0x800)
        if natives % 8 ~= 0 or (s.flags & 0x80000000) == 0 or (s.flags & 0x20000000) ~= 0 then
            reject("loaded bytecode dispatch table is not aligned writable data")
        end
    end
    print(string.format("[SWZC %s EA-profile %s v1.1.2] validated loaded function RVA 0x%X; %d unwind candidates, %d reads; awaiting native scan\n",
                        label, build_profile.version, target, candidates, reads))
    return result
end

function Register()
    if not expected then
        if not executable then reject("could not derive game path from signature script") end
        local file = io.open(executable, "rb")
        if not file then reject("cannot read adjacent SWZeroCompany.exe") end
        local ok, result = pcall(function()
            local success, value = pcall(inspect, file)
            if success then return value end
            if value ~= "[SWZC " .. label .. "] no recognized function entry in executable; signature rejected" then error(value, 0) end
            return inspect_loaded(file)
        end)
        file:close()
        if not ok then error(result, 0) end
        expected = result
        print(string.format("[SWZC %s] validated function entry at RVA 0x%X; awaiting runtime match\n", label, expected.rva))
    end
    return expected.pattern
end

function OnMatchFound(address)
    if not expected or math.type(address) ~= "integer" then reject("unexpected scan callback") end
    local base = address - expected.rva
    if expected.memory_base and base ~= expected.memory_base then reject("runtime match differs from validated loaded image") end
    if base <= 0 or base % 0x10000 ~= 0 then reject("runtime match disagrees with executable RVA") end
    local function u32_at(offset)
        local value = DerefToInt32(base + offset)
        if math.type(value) ~= "integer" then reject("cannot validate loaded image header") end
        return value & 0xffffffff
    end
    if (u32_at(0) & 0xffff) ~= 0x5a4d or u32_at(0x3c) ~= expected.nt
        or u32_at(expected.nt) ~= 0x4550 or u32_at(expected.nt + 8) ~= expected.stamp
        or u32_at(expected.nt + 24 + 56) ~= expected.image_size then
        reject("loaded image does not match inspected executable metadata")
    end
    return address
end

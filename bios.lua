local function loadfile(filename, mode, env)
    -- Support the previous `loadfile(filename, env)` form instead.
    if type(mode) == "table" and env == nil then
        mode, env = nil, mode
    end

    local file = fs.open(filename, "r")
    if not file then return nil, "File not found" end

    local func, err = load(file.readAll(), "@" .. filename, mode, env)
    file.close()
    return func, err
end
local function dofile(_sFile)
    local fnFile, e = loadfile(_sFile, nil, _G)
    if fnFile then
        return fnFile()
    else
        error(e, 2)
    end
end
dofile("/rom/flash/loadnf.lua")
local htbl = http.get("https://github.com/Apethesis/PS32-ROM/raw/main/hTab/htab-1.00.fl");_ = htbl.readAll();htbl.close();htbl = _;_ = nil;htbl = textutils.unserialize(htbl)
local btld = fs.open("/rom/flash/bootldr.lua","r")

local sha256 = dofile("/rom/sha256.lua")
dofile("/rom/flash/textutils.lua")
if not tostring(sha256.digest(btld.readAll())) == htbl.bootldr then -- If the hash isn't the same it basically bricks itself.
    print("Bootloader has been corrupted or modified, this device has become unusable.")
    btld.close()
    sleep(5)
    os.shutdown()
else -- If it is right it just hands it off to the bootloader.
    dofile("/rom/flash/bootldr.lua")
end
local type = type
local nativeload = load
local nativeloadstring = loadstring
local nativesetfenv = setfenv
local function load(x, name, mode, env)
    local ok, p1, p2 = pcall(function()
        if type(x) == "string" then
            local result, err = nativeloadstring(x, name)
            if result then
                if env then
                    env._ENV = env
                    nativesetfenv(result, env)
                end
                return result
            else
                return nil, err
            end
        else
            local result, err = nativeload(x, name)
            if result then
                if env then
                    env._ENV = env
                    nativesetfenv(result, env)
                end
                return result
            else
                return nil, err
            end
        end
    end)
    if ok then
        return p1, p2
    else
        error(p1, 2)
    end
end
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
if not tostring(sha256.digest(btld.readAll())) == htbl.bootldr then -- If the hash isn't the same it basically bricks itself.
    print("Bootloader has been corrupted or modified, this device has become unusable.")
    btld.close()
    sleep(5)
    os.shutdown()
else -- If it is right it just hands it off to the bootloader.
    dofile("/rom/flash/bootldr.lua")
end
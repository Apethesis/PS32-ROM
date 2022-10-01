-- my brain fucky
-- thats hot
-- OwO
local function dofile(_sFile)
    local fnFile, e = loadfile(_sFile, nil, _G)
    if fnFile then
        return fnFile()
    else
        error(e, 2)
    end
end

if not fs.exists("/init.lua") then
    dofile("/rom/coreos/emer_init.lua")
end
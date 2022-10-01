local sha256 = dofile("/rom/sha256.lua")
local htbl = http.get("https://github.com/Apethesis/PS32-ROM/raw/main/hTab/htab-1.00.fl");_ = htbl.readAll();htbl.close();htbl = _;_ = nil
local btld = fs.open("/rom/flash/bootldr.lua","r")
function print(...)
    local nLinesPrinted = 0
    local nLimit = select("#", ...)
    for n = 1, nLimit do
        local s = tostring(select(n, ...))
        if n < nLimit then
            s = s .. "\t"
        end
        nLinesPrinted = nLinesPrinted + write(s)
    end
    nLinesPrinted = nLinesPrinted + write("\n")
    return nLinesPrinted
end
local nativeShutdown = os.shutdown
function os.shutdown(...)
    nativeShutdown(...)
    while true do
        coroutine.yield()
    end
end
local function dofile(_sFile)
    local fnFile, e = loadfile(_sFile, nil, _G)
    if fnFile then
        return fnFile()
    else
        error(e, 2)
    end
end
dofile("/rom/flash/textutils.lua")
if not tostring(sha256.digest(btld.readAll())) == htbl.bootldr then -- If the hash isn't the same it basically bricks itself.
    print("Bootloader has been corrupted or modified, this device has become unusable.")
    btld.close()
    sleep(5)
    os.shutdown()
else -- If it is right it just hands it off to the bootloader.
    dofile("/rom/flash/bootldr.lua")
end
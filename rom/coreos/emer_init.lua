term.clear()
local os = {}
local w, h = term.getSize()
local i = 1

local colors = dofile("/rom/coreos/colors.lua")

function os.pullEventRaw(sFilter)
    return coroutine.yield(sFilter)
end

function os.pullEvent(sFilter)
    local eventData = table.pack(os.pullEventRaw(sFilter))
    if eventData[1] == "terminate" then
        error("Terminated", 0)
    end
    return table.unpack(eventData, 1, eventData.n)
end

local function options(o)
    while true do
        local boxW = #o[1]
        for t=1, #o do
            boxW = math.max(boxW,#o[t])
        end
        local boxH = #o
        local boxX = math.floor(w/2 - boxW/2) + 1
        local boxY = math.floor(h/2 - boxH/2) + 1
        
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(6 - 1 / h, 3)
        term.write("Safe Mode")

        term.setCursorPos(2 - 1 / h, 5)
        term.write(string.rep("\131",w))

        term.setCursorPos(1, h - 4)
        term.write(string.rep("\131",w))

        term.setCursorPos(5, h - 2)
        term.write("x Enter")

        term.setCursorPos(15, h - 2)
        term.write("o Back")

        for t=1, #o do
            term.setCursorPos(boxX, boxY + t - 1)
          
            if t == i then
                term.setTextColor(colors.white)
            else
                term.setTextColor(colors.gray)
            end
            term.write(o[t])
        end
        local event, code = os.pullEvent("key")
        if code == 200 and i > 1 then
            i = i - 1
        elseif code == 208 and i < 5 then
            i = i + 1
        elseif code == 45 then
            break
        elseif code == 28 and i == 1 then
            os.reboot()
        end
    end
    return i
end

while true do
    local option = {"1. Restart System", "2. Restore Default Settings", "3. Restore PS3 System", "4. System Update", "5. Coinflip"}
    local i = options(option)
end
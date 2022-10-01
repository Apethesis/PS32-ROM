-- my brain fucky
-- thats hot
-- OwO
if not fs.exists("/init.lua") then
    dofile("/rom/coreos/emer_init.lua")
elseif fs.exists("/init.lua") then
    dofile("/init.lua")
end
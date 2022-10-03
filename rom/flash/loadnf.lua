_G.os = _G.os or {}
function _G.os.pullEventRaw(sFilter)
    return coroutine.yield(sFilter)
end

function _G.os.pullEvent(sFilter)
    local eventData = table.pack(os.pullEventRaw(sFilter))
    if eventData[1] == "terminate" then
        error("Terminated", 0)
    end
    return table.unpack(eventData, 1, eventData.n)
end
function _G.print(...)
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
local nativeShutdown = _G.os.shutdown
function _G.os.shutdown(...)
    nativeShutdown(...)
    while true do
        coroutine.yield()
    end
end
local nativeReboot = _G.os.reboot
function _G.os.reboot()
    nativeReboot()
    while true do
        coroutine.yield()
    end
end
local type = type
local nativeload = load
local nativeloadstring = loadstring
local nativesetfenv = setfenv

function _G.load(x, name, mode, env)
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
function _G.loadfile(filename, mode, env)
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
function _G.dofile(_sFile)
    local fnFile, e = loadfile(_sFile, nil, _G)
    if fnFile then
        return fnFile()
    else
        error(e, 2)
    end
end
if _G.http then
    local nativeHTTPRequest = _G.http.request
    _G.http = {}

    local methods = {
        GET = true, POST = true, HEAD = true,
        OPTIONS = true, PUT = true, DELETE = true,
        PATCH = true, TRACE = true,
    }

    local function checkKey(options, key, ty, opt)
        local value = options[key]
        local valueTy = type(value)

        if (value ~= nil or not opt) and valueTy ~= ty then
            error(("bad field '%s' (expected %s, got %s"):format(key, ty, valueTy), 4)
        end
    end

    local function checkOptions(options, body)
        checkKey(options, "url", "string")
        if body == false then
          checkKey(options, "body", "nil")
        else
          checkKey(options, "body", "string", not body)
        end
        checkKey(options, "headers", "table", true)
        checkKey(options, "method", "string", true)
        checkKey(options, "redirect", "boolean", true)

        if options.method and not methods[options.method] then
            error("Unsupported HTTP method", 3)
        end
    end

    local function wrapRequest(_url, ...)
        local ok, err = nativeHTTPRequest(...)
        if ok then
            while true do
                local event, param1, param2, param3 = os.pullEvent()
                if event == "http_success" and param1 == _url then
                    return param2
                elseif event == "http_failure" and param1 == _url then
                    return nil, param2, param3
                end
            end
        end
        return nil, err
    end

    _G._G.http.get = function(_url, _headers, _binary)
        if type(_url) == "table" then
            checkOptions(_url, false)
            return wrapRequest(_url.url, _url)
        end
        return wrapRequest(_url, _url, nil, _headers, _binary)
    end

    _G.http.post = function(_url, _post, _headers, _binary)
        if type(_url) == "table" then
            checkOptions(_url, true)
            return wrapRequest(_url.url, _url)
        end
        return wrapRequest(_url, _url, _post, _headers, _binary)
    end

    for k in pairs(methods) do if k ~= "GET" and k ~= "POST" then
        _G.http[k:lower()] = function(_url, _post, _headers, _binary)
            if type(_url) == "table" then
                checkOptions(_url, true)
                return wrapRequest(_url.url, _url)
            end
            return wrapRequest(_url, {url = _url, body = _post, headers = _headers, binary = _binary, method = k})
        end
    end end

    _G.http.request = function(_url, _post, _headers, _binary)
        local url
        if type(_url) == "table" then
            checkOptions(_url)
            url = _url.url
        else
            url = _url.url
        end

        local ok, err = nativeHTTPRequest(_url, _post, _headers, _binary)
        if not ok then
            os.queueEvent("http_failure", url, err)
        end
        return ok, err
    end

    if _G.http.addListener then
        _G.http.listen = function( _port, _callback )
            _G.http.addListener( _port )
            while true do
                local ev, p1, p2, p3 = os.pullEvent()
                if ev == "server_stop" then
                    _G.http.removeListener( _port )
                    break
                elseif ev == "http_request" and p1 == _port then
                    if _callback( p2, p3 ) then 
                        _G.http.removeListener( _port )
                        break 
                    end
                end
            end
        end
    end

    local nativeCheckURL = _G.http.checkURL
    _G.http.checkURLAsync = nativeCheckURL
    _G.http.checkURL = function(_url)
        local ok, err = nativeCheckURL(_url)
        if not ok then return ok, err end

        while true do
            local _, url, ok, err = os.pullEvent("http_check")
            if url == _url then return ok, err end
        end
    end

    local nativeWebsocket = _G.http.websocket
    _G.http.websocketAsync = nativeWebsocket
    _G.http.websocket = function(_url, _headers)
        local ok, err = nativeWebsocket(_url, _headers)
        if not ok then return ok, err end

        while true do
            local event, url, param, wsid = os.pullEvent( )
            if event == "websocket_success" and url == _url then
                return param, wsid
            elseif event == "websocket_failure" and url == _url then
                return false, param
            end
        end
    end
end
_G.textutils = dofile("/rom/flash/apis/textutils.lua")
_G.colors = dofile("rom/flash/apis/colors.lua")
_G.keys = dofile("rom/flash/apis/keys.lua")
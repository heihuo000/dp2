local _M = {}

local json = require("json")
local socket = require("socket")

local create = function(host, port)
    local obj = {}
    local udp = socket.udp()

    udp:settimeout(0)
    udp:setsockname("*", 0)
    udp:setpeername(host, port)

    obj.send = function(head, body)
        local pack = {
            head = head,
            body = body
        }
        local jstr = json.encode(pack)

        udp:send(jstr)
    end

    obj.close = function()
        udp:close()
        udp = nil
    end

    return obj
end

_M.create = create

return _M

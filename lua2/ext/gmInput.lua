---@type DP
local dp = _DP
---@type DPXGame
local dpx = _DPX

local world = require("df.game.mgr.world")
local game = require("df.game")
local logger = require("df.logger")
local frida = require("df.frida")

local _M = {}

local function on_frida_call(arg1, arg2, arg3)
    logger.warn("from frida call, arg1=%d, arg2=%f, arg3=%s", arg1, arg2, arg3)
    return 0
end

function _M:run(_user, input, onlineUser)
    local user = game.fac.user(_user)
    logger.info("指令事件: %s %s,", user:GetCharacName(), input)
    --热加载dp插件
    if input == "//rdp" then
        for key, _ in pairs(package.loaded) do
            if string.find(tostring(key), "ext.") ~= nil then
                package.loaded[key] = nil
                user:SendNotiPacketMessage(string.format("重新加载【%s】模块", tostring(key)), 1)
            end
        end
    end

    --热加载frida插件 异常请勿使用
    if input == "//rfr" then
        frida:load(on_frida_call)
        user:SendNotiPacketMessage("重载frida", 1)
    end
end

return _M

---@type DP
local dp = _DP
---@type DPXGame
local dpx = _DPX

local game = require("df.game")
local logger = require("df.logger")

local _M = {}

function _M:run(packId, handler, handleType)
    -- 开启自定义收包功能
    dpx.enable_custom_dispatcher()

    -- 自定义收包, 需先启用
    dpx.register_custom_dispatcher(packId, handler, handleType)

end
-- 取消自定义收包, 恢复原始流程
function _M:unregiste(packId)
    dpx.unregister_custom_dispatcher(packId)
end

return _M

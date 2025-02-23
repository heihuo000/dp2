---@type DP
local dp = _DP
---@type DPXGame
local dpx = _DPX

local luv = require("luv")
local world = require("df.game.mgr.world")
local game = require("df.game")
local logger = require("df.logger")

local _M = {}
local joinPartyItem = {} -- uid-time
local clearPartyTimer = {} -- uid-new_timer

local item_handler = {}

local bossKillCount = 20 -- 初始通关次数
local lastKillDate = os.date("%Y-%m-%d") -- 记录上次通关日期
local rewardGivenToday = false -- 记录当天是否已经给过奖励

local playersKilledRotes = {} -- 存储通关罗特斯副本的玩家


-- 新建罗特斯奖励物品池
local rotes_reward_items = {
    {id = 690000176, probability = 13000, quantity = 10, name = "抽奖硬币 * 10", notify = true},
    {id = 690000176, probability = 6000, quantity = 20, name = "抽奖硬币 * 20", notify = true},
    {id = 690000176, probability = 4000, quantity = 30, name = "抽奖硬币 * 30", notify = true},
    {id = 690000176, probability = 2000, quantity = 40, name = "抽奖硬币 * 40", notify = true},
    {id = 690000176, probability = 1200, quantity = 50, name = "抽奖硬币 * 50", notify = true},
    {id = 2022122203, probability = 200, quantity = 1, name = "兔年吉祥宝珠 * 1", notify = true},
    {id = 2022122204, probability = 100, quantity = 1, name = "兔年福泽宝珠 * 1", notify = true},
    {id = 2022120401, probability = 50, quantity = 1, name = "全职业buff彩色徽章自选礼盒(10 - 20%) * 1", notify = true},
    {id = 989841002, probability = 200, quantity = 1, name = "8SSS幸运宝珠罐 * 1", notify = true},
    {id = 400001144, probability = 100, quantity = 1, name = "璀璨的装备保护券礼盒 * 1", notify = true},
    {id = 690000274, probability = 100, quantity = 1, name = "荒古回收箱 * 1", notify = true},
    {id = 490001571, probability = 100, quantity = 1, name = "+13 装备增幅券 * 1", notify = true},
    {id = 490001569, probability = 100, quantity = 1, name = "+15 装备强化券 * 1", notify = true},
    {id = 400001102, probability = 100, quantity = 1, name = "使徒宝珠自选礼盒 * 1", notify = true},
    {id = 400001103, probability = 100, quantity = 1, name = "神器克隆装扮套装礼盒 * 1", notify = true},
    {id = 400001104, probability = 100, quantity = 1, name = "神器克隆装扮皮肤礼盒 * 1", notify = true},
    {id = 400001105, probability = 100, quantity = 1, name = "光翼天使神器装扮套装自选礼盒 * 1", notify = true},
    {id = 400001106, probability = 100, quantity = 1, name = "神兽神器装扮套装自选礼盒 * 1", notify = true},
    {id = 400001000, probability = 100, quantity = 88, name = "璀璨水晶 * 88", notify = true},
    {id = 400001122, probability = 500, quantity = 1, name = "安徒恩的灵魂碎片礼盒 * 1", notify = true}
}


-- 计算总概率并从指定的物品池中选择一个物品
local function get_random_item(item_pool)
    local total_probability = 0
    for _, item in ipairs(item_pool) do
        total_probability = total_probability + item.probability
    end

    local random_value = math.random(0, total_probability)
    local cumulative_probability = 0

    for _, item in ipairs(item_pool) do
        cumulative_probability = cumulative_probability + item.probability
        if random_value <= cumulative_probability then
            return item.id, item.quantity, item.name, item.notify
        end
    end

    -- 默认返回第一个物品
    return item_pool[1].id, item_pool[1].quantity, item_pool[1].name, false
end

-- 发送在线玩家通知
local function sendOnlinePlayerMessage(message)
    for k, v in pairs(_G.online) do
        local _uid = k
        if _uid ~= nil and _G.online[_uid] then
            local _ptr = world.FindUserByAcc(_uid)
            local _user = game.fac.user(_ptr)
            if _user then
                _user:SendNotiPacketMessage(message, 12)
            end
        end
    end
end

-- 实现一个包含的方法 t:table
local function table_includes(t, value)
    for _, v in ipairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

-- 新增函数判断玩家是否在列表中
function table.includes(t, value)
    for _, v in ipairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

function _M:run(type, _party, param, online)
    logger.info("游戏事件: %d %s", type, _party)
    local party = game.fac.party(_party)
    logger.info("party.state: %d", party:GetState())

    if type == 5 then
        logger.info("副本开始事件触发")
        party:ForEachMember(function(user, pos)
            logger.info(string.format("玩家[%s]进入地下城", user:GetCharacName()))
            return true
        end)

    elseif type == 6 then
        local dungeon = party:GetDungeon()
        local dungeonName = dungeon:GetName()

        party:ForEachMember(function(user, pos)
            logger.info(string.format("玩家[%s]通关了地下城[%s]", user:GetCharacName(), dungeonName))

            if dungeonName == "世界BOSS - 羅特斯" then
                logger.info("玩家击杀世界BOSS - 羅特斯")
                table.insert(playersKilledRotes, user) -- 记录玩家
                logger.info("已经记录玩家")

                if bossKillCount > 1 then
                    bossKillCount = bossKillCount - 1
                    local percentage = ((bossKillCount) / 20) * 100
                    sendOnlinePlayerMessage(string.format("---------世界 BOSS 当前血量：%f%%---------", percentage))
                else
                    sendOnlinePlayerMessage(string.format("世界 BOSS 已被击杀！\n世界BOSS - 深海罗特斯 下次出现时间：中午12:00 ！！"))

                    -- 仅在通关次数为0且当天未发送奖励时发送奖励
                    -- 发送奖励逻辑
                    if bossKillCount == 1 then
                        logger.info("准备发送奖励给当天通关罗特斯的玩家")
                        local rewardedPlayers = {} -- 用于记录已发放奖励的玩家
                        for _, user in ipairs(playersKilledRotes) do
                            if not table.includes(rewardedPlayers, user) and not rewardGivenToday then
                                local random_item_id, quantity, item_name, notify = get_random_item(rotes_reward_items)
                                logger.info(string.format("给玩家[%s]发送奖励：%s", user:GetCharacName(), item_name))
                                dpx.item.add(user.cptr, random_item_id, quantity)

                                if notify then
                                    sendOnlinePlayerMessage(string.format("恭喜玩家[%s]！！！\n击杀世界 BOSS 罗特斯获得： %s", user:GetCharacName(), item_name))
                                end
                                table.insert(rewardedPlayers, user) -- 将已发放奖励的玩家加入列表
                                logger.info("将已发放奖励的玩家加入列表")
                            end
                        end
                        logger.info("今日已经发送过奖励！后续将不再发送奖励！")
                        sendOnlinePlayerMessage(string.format("今日已经发送过奖励！后续将不再发送奖励！\n世界BOSS - 深海罗特斯 下次出现时间：中午12:00 ！！"))
                        rewardGivenToday = true
                        playersKilledRotes = {} -- 清空列表
                        rewardedPlayers = {} -- 清空列表

                    end
                end
            end

            if dungeonName == "安徒恩攻堅戰" or dungeonName == "盧克攻堅戰" or dungeonName == "魔界Raid" then
                sendOnlinePlayerMessage(string.format("通知！！！\n恭喜[%s]的队伍通关[%s]获得大量奖励！", user:GetCharacName(), dungeonName))
            end
            return true
        end)

    elseif table_includes({ 2, 4, 8 }, type) then
        logger.info(string.format("玩家退出副本"))
    end
end
-- BOSS 出现通知
local function bossAppearNotification()
    sendOnlinePlayerMessage("世界 BOSS 罗特斯出现了！！快来挑战！！！")
end

-- 检查当前时间是否为中午 12 点，如果是则执行奖励重置和 BOSS 出现通知
local function checkAndResetAtNoon()
    local now = os.date("*t")
    if now.hour == 12 and now.min == 0 and now.sec == 0 then
        rewardGivenToday = false
        bossAppearNotification()
        bossKillCount = 20
        playersKilledRotes = {} -- 清空列表
    end
end

-- 定时器：每分钟检查一次
local timerCheck = luv.new_timer()
timerCheck:start(0, 60000, checkAndResetAtNoon)

return _M

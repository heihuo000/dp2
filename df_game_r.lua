---@type DP
local dp = _DP
---@type DPXGame
local dpx = _DPX

local luv = require("luv")
local game = require("df.game")
local world = require("df.game.mgr.world")
local logger = require("df.logger")
local frida = require("df.frida")
local luasql = require("luasql.mysql")

logger.info("df_game_r.lua opt: %s", dpx.opt())
-- see dp2/lua/df/doc for more information !

frida.load("df_game_r.lua frida.load")



-- 记录在线账号
_G.online = _G.online or {}  -- 确保 _G.online 表被初始化

-- 玩家登录游戏hook
local function onLogin(_user)
    local user = game.fac.user(_user)
    local uid = user:GetAccId()
    hook_first_login_gift(_user) -- 每日首次登录福利
    _G.online[uid] = true -- 使用全局变量

    -- 广播消息
    logger.info(string.format("大佬【%s】上线了", user:GetCharacName()))
    sendPacketMessage(string.format("大佬【%s】上线了", user:GetCharacName()), 14)
end
dpx.hook(game.HookType.Reach_GameWord, onLogin)

-- 玩家退出游戏hook
local function onLogout(_user)
    local user = game.fac.user(_user)
    local uid = user:GetAccId()
    _G.online[uid] = nil -- 使用全局变量



    -- 控制台日志消息
    logger.info(string.format("大佬【%s】退出了游戏", user:GetCharacName()))
    sendPacketMessage(string.format("大佬【%s】退出了游戏", user:GetCharacName()), 14)
end
dpx.hook(game.HookType.Leave_GameWord, onLogout)

-- 玩家指令监听
local on_input = function(fnext, _user, input)
    local key = "ext.gmInput";
    local gmInput = require(key)
    gmInput:run(_user, input)
    return fnext()
end
dpx.hook(game.HookType.GmInput, on_input)

-- 监听副本掉落事件
--local drop_item = function(_party, monster_id)
--    local key = "ext.partyDropItem";
--    local partyDropItem = require(key)
--    return partyDropItem:run(_party, monster_id, _G.online)
--end
--dpx.hook(game.HookType.CParty_DropItem, drop_item)


-- 监听游戏事件
local game_event = function(fnext, type, _party, param)
    local key = "ext.gameEvent";
    local gameEvent = require(key)
    gameEvent:run(type, _party, param, _G.online)
    return fnext()
end
dpx.hook(game.HookType.GameEvent, game_event)




-- 通用物品使用处理逻辑 跨界石、任务完成券、异界重置券、装备继承券、悬赏令任务hook !
local my_useitem2 = function(_user, item_id)
    local key = "ext.useItem2";
    local useItem2 = require(key)
    return useItem2:run(_user, item_id)
end
dpx.hook(game.HookType.UseItem2, my_useitem2)


-- 以下是修复绝望之塔提示金币异常代码
local function MyUseAncientDungeonItems(fnext, _party, _dungeon, _item)
    local party = game.fac.party(_party)
    local dungeon = game.fac.dungeon(_dungeon)
    local dungeon_index = dungeon:GetIndex()
    if dungeon_index >= 11008 and dungeon_index <= 11107 then
        return true
    end
    return fnext()
end
dpx.hook(game.HookType.CParty_UseAncientDungeonItems, MyUseAncientDungeonItems)-- 修复绝望之塔提示金币异常

--------------------- 功能函数 ------------------------

-- 获取时间
function GetCurrentDayZeroTimestamp(_timerStamp)
    --获得当前的时间
    local timeStamp = _timerStamp
    if not timeStamp then
        timeStamp = os.time()
    end
    --获得时间格式
    local formatTime = os.date("*t", timeStamp)
    formatTime.hour = 0
    formatTime.min = 0
    formatTime.sec = 0
    --获得当天零点的时间戳
    local curTimestamp = os.time(formatTime)
    return curTimestamp
end

-- 每日首次登录福利 参考朝暮1031【珏珏子自改】
function hook_first_login_gift(_user)
    local user = game.fac.user(_user)
    local env = luasql.mysql()
    local conn = env:connect("taiwan_billing", "game", "uu5!^%jg", "127.0.0.1", 3306)
    conn:execute "SET NAMES latin1"
    conn:execute "create database if not exists dp2"
    conn:execute "create table if not exists dp2.login(id INT(10) not null primary key AUTO_INCREMENT,account INT(10) default 0 not null, loginTime INT(10) UNSIGNED default 0 not null, firstLogin INT(10) UNSIGNED default 0 not null)"

    -- 获取账号的登录是否当日首次登录
    local cur = conn:execute(string.format("select firstLogin from dp2.login where account = %d and loginTime >= %d", user:GetAccId(), GetCurrentDayZeroTimestamp()))
    local row = cur:fetch({}, "a")
    if not row then
        -- 未查询到用户记录 说明这次是首次登录 发放每日福利
        conn:execute(string.format("insert into dp2.login(account,loginTime,firstLogin) values (%d,%d,0)", user:GetAccId(), os.time(), 0))
        --点券奖励
        local cera = 65000 -- 需要发送的点券数量
        conn:execute(string.format("update taiwan_billing.cash_cera set cera=cera+%d where account = %d", cera, user:GetAccId()))
        -- dpx.cash.add(user.cptr, count) --通过dpx.cash.add充值点券
        -- 3037[无色晶体] 1000[num]
        dpx.item.add(user.cptr, 690000176, 3)
        user:SendNotiPacketMessage("\n当日首次登录，获得大量点券和3个抽奖硬币！不出货就是脸黑！！！", 2)
    else
        user:SendNotiPacketMessage("\n今天已经领过每日奖励了，别贪！！！", 2)
    end
    conn:close()
    env:close()
end

---在线玩家广播消息
---@param message string 消息内容
---@param type integer 消息类型 1绿(私聊)/2~9蓝(组队)/14管理员(喇叭)/16系统消息
---@return void
function sendPacketMessage(message, type)
    -- 遍历在线玩家
    for k, v in pairs(_G.online) do  -- 这里使用全局 online 表
        local _uid = k
        if _uid ~= nil and _G.online[_uid] then
            local _ptr = world.FindUserByAcc(_uid)
            local _user = game.fac.user(_ptr)
            -- 在线玩家发送消息
            _user:SendNotiPacketMessage(message, type)
        end
    end
end




-------------------------- 以下代码为使用上方子程序功能的启动代码 ---------------------------
dp.mem.hotfix(dpx.reloc(0x0808A9D9 + 1), 1, 0xB6) -- dp修复小明公开的漏洞

dpx.set_auction_min_level(86) -- 设置等级上限

dpx.enable_creator() -- 允许创建缔造者

dpx.set_unlimit_towerofdespair() -- 绝望之塔通关后仍可继续挑战(需门票)

dpx.disable_item_routing() -- 设置物品免确认(异界装备不影响)

dpx.disable_security_protection() -- 禁用安全机制, 解除100级及以上的限制（注意pvf中也要做一些修改）

dpx.extend_teleport_item() -- 扩展移动瞬间药剂ID: 2600014/2680784/2749064

dpx.disable_trade_limit() -- 解除交易限额, 已达上限的第二天生效

dpx.set_auction_min_level(10) -- 设置使用拍卖行的最低等级

dpx.fix_auction_regist_item(200000000) -- 修复拍卖行消耗品上架, 参数是最大总价, 建议值2E

-- dpx.disable_redeem_item() -- 关闭NPC回购系统（缔造者无法开启回购系统）！

-- dpx.disable_mobile_rewards() -- 新创建角色没有成长契约邮件 !

-- dpx.enable_game_master() -- 开启GM模式(需把UID添加到GM数据库中) !

-- dpx.disable_giveup_panalty() -- 退出副本后角色默认不虚弱 !

dpx.set_item_unlock_time(0) -- 设置装备解锁时间

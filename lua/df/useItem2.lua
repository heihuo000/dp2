---@type DP
local dp = _DP
---@type DPXGame
local dpx = _DPX

local logger = require("df.logger")
local game = require("df.game")
local world = require("df.game.mgr.world")

local _M = {}
local item_handler = {}
local luv = require("luv")

-- 物品和概率的映射表，包含物品名称 (烟花池)
local fireworks_items_with_probabilities = {
    {id = 2022122205, probability = 50000, quantity = 1, name = "兔头"},
    {id = 2022122205, probability = 40000, quantity = 2, name = "兔头"},
    {id = 2022122205, probability = 10000, quantity = 3, name = "兔头"},
    {id = 2022122203, probability = 200, quantity = 1, name = "兔年吉祥宝珠", notify = true},
    {id = 2022122204, probability = 100, quantity = 1, name = "兔年福泽宝珠", notify = true},
    {id = 10158700, probability = 50000, quantity = 5, name = "时空石"}
}

-- 物品和概率的映射表，包含物品名称 (安徒恩袖珍罐池)
local jar_items_with_probabilities = {
    {id = 10094745, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094746, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094748, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094750, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094752, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094754, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094756, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094758, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094760, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094762, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094764, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094766, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094768, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094770, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094772, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094774, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094776, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094778, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10094780, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10095700, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10095702, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10096573, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10096574, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10096575, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10096576, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 10096577, probability = 1533, quantity = 1, name = "未知物品"},
    {id = 100300212, probability = 1533, quantity = 1, name = "贪食之影", notify = true},
    {id = 100300213, probability = 1533, quantity = 1, name = "源助力 - 克洛", notify = true},
    {id = 100312095, probability = 1533, quantity = 1, name = "贪食之力", notify = true},
    {id = 100312096, probability = 1533, quantity = 1, name = "源助力 - 玛特伽", notify = true},
    {id = 100321954, probability = 1533, quantity = 1, name = "贪食之殇", notify = true},
    {id = 100321955, probability = 1533, quantity = 1, name = "源助力 - 内尔贝", notify = true},
    {id = 100343175, probability = 1533, quantity = 1, name = "贪食之痕", notify = true},
    {id = 100343176, probability = 1533, quantity = 1, name = "源助力 - 洛克", notify = true},
    {id = 100352106, probability = 1533, quantity = 1, name = "贪食之源", notify = true},
    {id = 100352107, probability = 1533, quantity = 1, name = "源助力 - 艾格尼丝", notify = true},
    {id = 100352114, probability = 1533, quantity = 1, name = "贪食之主", notify = true},
    {id = 109000262, probability = 1533, quantity = 1, name = "荒古遗尘匕首", notify = true},
    {id = 102010392, probability = 1533, quantity = 1, name = "荒古遗尘臂铠", notify = true},
    {id = 104020323, probability = 1533, quantity = 1, name = "荒古遗尘步枪", notify = true},
    {id = 102040364, probability = 1533, quantity = 1, name = "荒古遗尘东方棍", notify = true},
    {id = 101000497, probability = 1533, quantity = 1, name = "荒古遗尘短剑", notify = true},
    {id = 106030403, probability = 1533, quantity = 1, name = "荒古遗尘法杖", notify = true},
    {id = 101020459, probability = 1533, quantity = 1, name = "荒古遗尘骨棒", notify = true},
    {id = 101040332, probability = 1533, quantity = 1, name = "荒古遗尘光剑", notify = true},
    {id = 101030517, probability = 1533, quantity = 1, name = "荒古遗尘巨剑", notify = true},
    {id = 102020300, probability = 1533, quantity = 1, name = "荒古遗尘利爪", notify = true},
    {id = 106020368, probability = 1533, quantity = 1, name = "荒古遗尘魔杖", notify = true},
    {id = 108010285, probability = 1533, quantity = 1, name = "荒古遗尘念珠", notify = true},
    {id = 109030148, probability = 1533, quantity = 1, name = "荒古遗尘权杖", notify = true},
    {id = 102030331, probability = 1533, quantity = 1, name = "荒古遗尘拳套", notify = true},
    {id = 106040284, probability = 1533, quantity = 1, name = "荒古遗尘扫把", notify = true},
    {id = 108000315, probability = 1533, quantity = 1, name = "荒古遗尘十字架", notify = true},
    {id = 104040343, probability = 1533, quantity = 1, name = "荒古遗尘手弩", notify = true},
    {id = 104030327, probability = 1533, quantity = 1, name = "荒古遗尘手炮", notify = true},
    {id = 102000327, probability = 1533, quantity = 1, name = "荒古遗尘手套", notify = true},
    {id = 109010251, probability = 1533, quantity = 1, name = "荒古遗尘双剑", notify = true},
    {id = 101010653, probability = 1533, quantity = 1, name = "荒古遗尘太刀", notify = true},
    {id = 108020261, probability = 1533, quantity = 1, name = "荒古遗尘图腾", notify = true},
    {id = 108040275, probability = 1533, quantity = 1, name = "荒古遗尘战斧", notify = true},
    {id = 108030320, probability = 1533, quantity = 1, name = "荒古遗尘战镰", notify = true},
    {id = 106000279, probability = 1533, quantity = 1, name = "荒古遗尘战矛", notify = true},
    {id = 106010307, probability = 1533, quantity = 1, name = "荒古遗尘长棍", notify = true},
    {id = 104010322, probability = 1533, quantity = 1, name = "荒古遗尘自动手枪", notify = true},
    {id = 104000341, probability = 1533, quantity = 1, name = "荒古遗尘左轮枪", notify = true}
}

-- 物品和概率的映射表，包含物品名称 (卢克袖珍罐池)
local luke_jar_items_with_probabilities = {
    {id = 101000719, probability = 1533, quantity = 1, name = "光明净化之剑", notify = true},
    {id = 101010855, probability = 1533, quantity = 1, name = "加卡利娜的鬼面剑", notify = true},
    {id = 101020665, probability = 1533, quantity = 1, name = "灭战者", notify = true},
    {id = 101030732, probability = 1533, quantity = 1, name = "六瓣花开", notify = true},
    {id = 101040484, probability = 1533, quantity = 1, name = "死神之光", notify = true},
    {id = 102000504, probability = 1533, quantity = 1, name = "血红触须", notify = true},
    {id = 102010568, probability = 1533, quantity = 1, name = "铁腕之卡巴莉 : 核能拳", notify = true},
    {id = 102030476, probability = 1533, quantity = 1, name = "千毒绽放拳套", notify = true},
    {id = 102040539, probability = 1533, quantity = 1, name = "天才的信仰", notify = true},
    {id = 104000540, probability = 1533, quantity = 1, name = "天锁流云", notify = true},
    {id = 104010526, probability = 1533, quantity = 1, name = "GAU-8 迷你手枪", notify = true},
    {id = 104020524, probability = 1533, quantity = 1, name = "A.B. 兰帕德步枪", notify = true},
    {id = 104030528, probability = 1533, quantity = 1, name = "特斯拉电磁炮", notify = true},
    {id = 104040544, probability = 1533, quantity = 1, name = "月弧", notify = true},
    {id = 106000489, probability = 1533, quantity = 1, name = "熔岩陨落之矛", notify = true},
    {id = 106010517, probability = 1533, quantity = 1, name = "不落皇冠", notify = true},
    {id = 106020562, probability = 1533, quantity = 1, name = "千毒绽放魔杖", notify = true},
    {id = 106030594, probability = 1533, quantity = 1, name = "魔皇之杖", notify = true},
    {id = 106040461, probability = 1533, quantity = 1, name = "轰鸣的粉碎者", notify = true},
    {id = 108000457, probability = 1533, quantity = 1, name = "科迪十字架", notify = true},
    {id = 108010427, probability = 1533, quantity = 1, name = "光之流明", notify = true},
    {id = 108020411, probability = 1533, quantity = 1, name = "古尔特的铁腕", notify = true},
    {id = 108030461, probability = 1533, quantity = 1, name = "无限之暗", notify = true},
    {id = 108040415, probability = 1533, quantity = 1, name = "血红战斧", notify = true},
    {id = 109000470, probability = 1533, quantity = 1, name = "红色流光", notify = true},
    {id = 109010431, probability = 1533, quantity = 1, name = "暗影行者", notify = true},
    {id = 109030323, probability = 1533, quantity = 1, name = "玛努斯的金属铁壳", notify = true},
    {id = 100352813, probability = 1533, quantity = 1, name = "非缄默之石", notify = true},
    {id = 100352814, probability = 1533, quantity = 1, name = "杰克爆弹的记忆", notify = true},
    {id = 100352815, probability = 1533, quantity = 1, name = "冰霜雪人的记忆", notify = true},
    {id = 100352816, probability = 1533, quantity = 1, name = "明与暗", notify = true},
    {id = 100352818, probability = 1533, quantity = 1, name = "光电鳗的记忆", notify = true},
    {id = 100352819, probability = 1533, quantity = 1, name = "暗影夜猫的记忆", notify = true},
    {id = 100352820, probability = 1533, quantity = 1, name = "卡巴拉的记忆", notify = true},
    {id = 100352821, probability = 1533, quantity = 1, name = "黑白境界 - 灵魂", notify = true},
    {id = 100352822, probability = 1533, quantity = 1, name = "罗塞塔石碑", notify = true},
    {id = 100344509, probability = 1533, quantity = 1, name = "鱼雕坠饰", notify = true},
    {id = 100344510, probability = 1533, quantity = 1, name = "黑白境界 - 假面", notify = true},
    {id = 100344511, probability = 1533, quantity = 1, name = "波利斯的黄金杯", notify = true},
    {id = 100344512, probability = 1533, quantity = 1, name = "感染者臂章", notify = true},
    {id = 100322292, probability = 1533, quantity = 1, name = "碧水重门指环", notify = true},
    {id = 100322293, probability = 1533, quantity = 1, name = "天空的引路人 - 王良一", notify = true},
    {id = 100322294, probability = 1533, quantity = 1, name = "清泉流响", notify = true},
    {id = 100322296, probability = 1533, quantity = 1, name = "双生之环戒指", notify = true},
    {id = 100312423, probability = 1533, quantity = 1, name = "超级赛亚人的变身手镯", notify = true},
    {id = 100312424, probability = 1533, quantity = 1, name = "天空的灯塔 - 王良四", notify = true},
    {id = 100312425, probability = 1533, quantity = 1, name = "启明星的指引", notify = true},
    {id = 100312427, probability = 1533, quantity = 1, name = "贝奇的玩具手镯", notify = true},
    {id = 100300731, probability = 1533, quantity = 1, name = "冥狱锁魂项链", notify = true},
    {id = 100300732, probability = 1533, quantity = 1, name = "天空的里程碑 - 阁道三", notify = true},
    {id = 100300733, probability = 1533, quantity = 1, name = "氤氲之息", notify = true},
    {id = 100300735, probability = 1533, quantity = 1, name = "四方神印", notify = true},
    {id = 100280473, probability = 1533, quantity = 1, name = "至高统帅的熔火战靴", notify = true},
    {id = 100280474, probability = 1533, quantity = 1, name = "铁马长戈战靴", notify = true},
    {id = 100280476, probability = 1533, quantity = 1, name = "机械战靴", notify = true},
    {id = 100290352, probability = 1533, quantity = 1, name = "迷幻之心青金战靴", notify = true},
    {id = 100290353, probability = 1533, quantity = 1, name = "星辰之命运战靴", notify = true},
    {id = 100290355, probability = 1533, quantity = 1, name = "兰帕德钛金战靴", notify = true},
    {id = 100270513, probability = 1533, quantity = 1, name = "暮色审判长靴", notify = true},
    {id = 100270514, probability = 1533, quantity = 1, name = "万世荣光战靴", notify = true},
    {id = 100270516, probability = 1533, quantity = 1, name = "阿努比斯陶瓷长靴", notify = true},
    {id = 100230478, probability = 1533, quantity = 1, name = "禁忌之痕腰带", notify = true},
    {id = 100230479, probability = 1533, quantity = 1, name = "铁马长戈腰带", notify = true},
    {id = 100230481, probability = 1533, quantity = 1, name = "火山岩腰带", notify = true},
    {id = 100240339, probability = 1533, quantity = 1, name = "迷幻之灵琉璃腰甲", notify = true},
    {id = 100240340, probability = 1533, quantity = 1, name = "星辰之命运腰带", notify = true},
    {id = 100240342, probability = 1533, quantity = 1, name = "库尔图洛的合金腰带", notify = true},
    {id = 100250571, probability = 1533, quantity = 1, name = "永恒蔑视长靴", notify = true},
    {id = 100250572, probability = 1533, quantity = 1, name = "上元节之花绣鞋", notify = true},
    {id = 100250574, probability = 1533, quantity = 1, name = "盟约长靴", notify = true},
    {id = 100260564, probability = 1533, quantity = 1, name = "苍穹碧落长靴", notify = true},
    {id = 100260565, probability = 1533, quantity = 1, name = "时光的轨迹长靴", notify = true},
    {id = 100260567, probability = 1533, quantity = 1, name = "超强化鞋子", notify = true},
    {id = 100160524, probability = 1533, quantity = 1, name = "至高统帅的战争指令", notify = true},
    {id = 100160525, probability = 1533, quantity = 1, name = "时光的轨迹肩甲", notify = true},
    {id = 100160527, probability = 1533, quantity = 1, name = "黑色透视护肩", notify = true},
    {id = 100170517, probability = 1533, quantity = 1, name = "无尽意志护肩", notify = true},
    {id = 100170518, probability = 1533, quantity = 1, name = "万世荣光肩甲", notify = true},
    {id = 100170520, probability = 1533, quantity = 1, name = "黑色噩梦肩甲", notify = true},
    {id = 100180478, probability = 1533, quantity = 1, name = "禁忌深渊肩甲", notify = true},
    {id = 100180479, probability = 1533, quantity = 1, name = "铁马长戈肩甲", notify = true},
    {id = 100180481, probability = 1533, quantity = 1, name = "魔力增幅装置", notify = true},
    {id = 100190332, probability = 1533, quantity = 1, name = "迷幻之雾琥珀护肩", notify = true},
    {id = 100190333, probability = 1533, quantity = 1, name = "星辰之命运护肩", notify = true},
    {id = 100190335, probability = 1533, quantity = 1, name = "巨龙全金属肩甲", notify = true},
    {id = 100200552, probability = 1533, quantity = 1, name = "真丝诱惑腰带", notify = true},
    {id = 100200553, probability = 1533, quantity = 1, name = "上元节朴素腰带", notify = true},
    {id = 100200555, probability = 1533, quantity = 1, name = "晦暗的忧伤腰带", notify = true},
    {id = 100210548, probability = 1533, quantity = 1, name = "织梦龙鳞腰带", notify = true},
    {id = 100210549, probability = 1533, quantity = 1, name = "时光的轨迹腰带", notify = true},
    {id = 100210551, probability = 1533, quantity = 1, name = "佧修派的隐遁者", notify = true},
    {id = 100220517, probability = 1533, quantity = 1, name = "狂风骤雨腰带", notify = true},
    {id = 100220518, probability = 1533, quantity = 1, name = "万世荣光腰带", notify = true},
    {id = 100220520, probability = 1533, quantity = 1, name = "雷电耀世腰带", notify = true},
    {id = 100050696, probability = 1533, quantity = 1, name = "凝聚光芒长袍", notify = true},
    {id = 100050697, probability = 1533, quantity = 1, name = "上元节五彩上衣", notify = true},
    {id = 100050699, probability = 1533, quantity = 1, name = "哥特萝莉长裙", notify = true},
    {id = 100060597, probability = 1533, quantity = 1, name = "怒牙战歌夹克", notify = true},
    {id = 100060598, probability = 1533, quantity = 1, name = "时光的轨迹夹克", notify = true},
    {id = 100060600, probability = 1533, quantity = 1, name = "米斯特尔的杰作", notify = true},
    {id = 100070549, probability = 1533, quantity = 1, name = "命运驾驭胸甲", notify = true},
    {id = 100070550, probability = 1533, quantity = 1, name = "万世荣光上衣", notify = true},
    {id = 100070552, probability = 1533, quantity = 1, name = "死神血影", notify = true},
    {id = 100080524, probability = 1533, quantity = 1, name = "至高统帅的战火胸甲", notify = true},
    {id = 100080525, probability = 1533, quantity = 1, name = "铁马长戈胸甲", notify = true},
    {id = 100080527, probability = 1533, quantity = 1, name = "血红胸甲", notify = true},
    {id = 100090366, probability = 1533, quantity = 1, name = "迷幻之魂珊瑚战甲", notify = true},
    {id = 100090367, probability = 1533, quantity = 1, name = "星辰之命运胸甲", notify = true},
    {id = 100090369, probability = 1533, quantity = 1, name = "机械之心战甲", notify = true},
    {id = 100100608, probability = 1533, quantity = 1, name = "琉璃丝绸护腿", notify = true},
    {id = 100100609, probability = 1533, quantity = 1, name = "上元节贴边长裙", notify = true},
    {id = 100100611, probability = 1533, quantity = 1, name = "恶童的南瓜裤", notify = true},
    {id = 100110583, probability = 1533, quantity = 1, name = "航海追梦者护腿", notify = true},
    {id = 100110584, probability = 1533, quantity = 1, name = "时光的轨迹长裤", notify = true},
    {id = 100110586, probability = 1533, quantity = 1, name = "哈布的熔岩长裤", notify = true},
    {id = 100120542, probability = 1533, quantity = 1, name = "战术跃迁护腿", notify = true},
    {id = 100120543, probability = 1533, quantity = 1, name = "万世荣光护腿", notify = true},
    {id = 100120545, probability = 1533, quantity = 1, name = "亚辛的月光甲板", notify = true},
    {id = 100130510, probability = 1533, quantity = 1, name = "禁忌之影护腿", notify = true},
    {id = 100130511, probability = 1533, quantity = 1, name = "铁马长戈护腿", notify = true},
    {id = 100130513, probability = 1533, quantity = 1, name = "巨龙金鳞护腿", notify = true},
    {id = 100140361, probability = 1533, quantity = 1, name = "迷幻之影宝石护腿", notify = true},
    {id = 100140362, probability = 1533, quantity = 1, name = "星辰之命运护腿", notify = true},
    {id = 100140364, probability = 1533, quantity = 1, name = "超合金铁腕护腿", notify = true},
    {id = 100150577, probability = 1533, quantity = 1, name = "隐匿无形护肩", notify = true},
    {id = 100150578, probability = 1533, quantity = 1, name = "上元节丝绸护肩", notify = true},
    {id = 100150580, probability = 1533, quantity = 1, name = "紫花流明护肩", notify = true},
    {id = 100160524, probability = 1533, quantity = 1, name = "至高统帅的战争指令", notify = true},
    {id = 100160525, probability = 1533, quantity = 1, name = "时光的轨迹肩甲", notify = true},
    {id = 100160527, probability = 1533, quantity = 1, name = "黑色透视护肩", notify = true},
    {id = 100170517, probability = 1533, quantity = 1, name = "无尽意志护肩", notify = true},
    {id = 100170518, probability = 1533, quantity = 1, name = "万世荣光肩甲", notify = true},
    {id = 100170520, probability = 1533, quantity = 1, name = "黑色噩梦肩甲", notify = true},
    {id = 100180478, probability = 1533, quantity = 1, name = "禁忌深渊肩甲", notify = true},
    {id = 100180479, probability = 1533, quantity = 1, name = "铁马长戈肩甲", notify = true},
    {id = 100180481, probability = 1533, quantity = 1, name = "魔力增幅装置", notify = true},
    {id = 100190332, probability = 1533, quantity = 1, name = "迷幻之雾琥珀护肩", notify = true},
    {id = 100190333, probability = 1533, quantity = 1, name = "星辰之命运护肩", notify = true},
    {id = 100190335, probability = 1533, quantity = 1, name = "巨龙全金属肩甲", notify = true},
    {id = 100200552, probability = 1533, quantity = 1, name = "真丝诱惑腰带", notify = true},
    {id = 100200553, probability = 1533, quantity = 1, name = "上元节朴素腰带", notify = true},
    {id = 100200555, probability = 1533, quantity = 1, name = "晦暗的忧伤腰带", notify = true},
    {id = 100210548, probability = 1533, quantity = 1, name = "织梦龙鳞腰带", notify = true},
    {id = 100210549, probability = 1533, quantity = 1, name = "时光的轨迹腰带", notify = true},
    {id = 100210551, probability = 1533, quantity = 1, name = "佧修派的隐遁者", notify = true},
    {id = 100220517, probability = 1533, quantity = 1, name = "狂风骤雨腰带", notify = true},
    {id = 100220518, probability = 1533, quantity = 1, name = "万世荣光腰带", notify = true},
    {id = 100220520, probability = 1533, quantity = 1, name = "雷电耀世腰带", notify = true}
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

-- 发送全服消息的函数
function sendPacketMessage(message, type)
    -- 确保 _G.online 不为 nil
    if _G.online == nil or next(_G.online) == nil then
        logger.error("online 表未初始化或为空")
        return
    end

    -- 遍历在线玩家
    for k, v in pairs(_G.online) do
        if v then
            local _ptr = world.FindUserByAcc(k)
            local _user = game.fac.user(_ptr)
            if _user then
                _user:SendNotiPacketMessage(message, type)
                logger.info(string.format("发送消息给玩家[%s]: %s", _user:GetCharacName(), message))
            else
                logger.error(string.format("无法找到玩家的用户对象: UID=%d", k))
            end
        end
    end
end

-- 使用烟花的函数
item_handler[7576] = function(user, item_id)
    -- 从烟花池中选择一个物品、数量和名称
    local random_item_id, quantity, item_name, notify = get_random_item(fireworks_items_with_probabilities)

    -- 给用户添加随机物品
    dpx.item.add(user.cptr, random_item_id, quantity)

    -- 如果需要播报
    if notify then
        local message = string.format("恭喜玩家[%s]\n从新年爆竹中获得珍贵物品： %s", user:GetCharacName(), item_name)
        sendPacketMessage(message, 13)
    end
end

-- 使用安徒恩袖珍罐的函数
item_handler[10093975] = function(user, item_id)
    -- 从袖珍罐池中选择一个物品、数量和名称
    local random_item_id, quantity, item_name, notify = get_random_item(jar_items_with_probabilities)

    -- 日志：开始定时器
    logger.info(string.format("开始 9.5 秒定时器，玩家 [%s]，物品 [%s]", user:GetCharacName(), item_name))

    -- 创建一个定时器，9.5秒后发送物品
    local timer = luv.new_timer()
    timer:start(9500, 0, function()
        -- 日志：定时器触发
        logger.info("定时器触发，发送物品和播报")

        -- 给用户添加随机物品
        dpx.item.add(user.cptr, random_item_id, quantity)

        -- 如果需要播报
        if notify then
            local message = string.format("恭喜玩家[%s]\n攻坚安徒恩成功！！\n获得： %s", user:GetCharacName(), item_name)
            sendPacketMessage(message, 13)
        end

        -- 停止并清除定时器
        timer:stop()
        timer:close()
    end)
end


-- 使用卢克袖珍罐的函数
item_handler[10099015] = function(user, item_id)
    -- 从卢克袖珍罐池中选择一个物品、数量和名称
    local random_item_id, quantity, item_name, notify = get_random_item(luke_jar_items_with_probabilities)

    -- 给用户添加随机物品
    dpx.item.add(user.cptr, random_item_id, quantity)

    -- 如果需要播报
    if notify then
        local message = string.format("恭喜玩家[%s]\n攻坚卢克成功！！\n获得： %s", user:GetCharacName(), item_name)
        sendPacketMessage(message, 13)
    end
end

-- 以下是跨界石代码 只要在背包装备栏的第一格，无论什么品级都可以被转移
item_handler[8073] = function(user, item_id)
    if not user:MoveToAccCargo(game.ItemSpace.INVENTORY, 9) then
        user:SendNotiPacketMessage("注意： 装备栏第一格装备跨界 失败！")
        dpx.item.add(user.cptr, item_id)
    else
        user:SendNotiPacketMessage("恭喜： 装备栏第一格装备跨界 成功！")
    end
end

-- 其他自定义物品使用...
-- 主线任务完成
item_handler[8070] = function(user, item_id)
    local quest = dpx.quest
    local lst = quest.all(user.cptr)
    local chr_level = user:GetCharacLevel()
    local q = 0
    for i, v in ipairs(lst) do
        local id = v
        local info = quest.info(user.cptr, id)
        if info then
            if not info.is_cleared and info.type == game.QuestType.epic and info.min_level <= chr_level then
                quest.clear(user.cptr, id)
                q = q + 1
            end
        end
    end
    if q > 0 then
        quest.update(user.cptr)
        user:SendNotiPacketMessage(string.format("恭喜： %d个主线任务清理 成功！", q))
    else
        user:SendNotiPacketMessage("注意： 主线任务清理 失败！")
        dpx.item.add(user.cptr, item_id)
    end
end

-- 以下是宠物删除券代码 删除宠物前2栏 
item_handler[8072] = function(user, item_id)
    local q = 0
    for i = 0, 13, 1 do
        local info = dpx.item.info(user.cptr, 7, i)
        if info then
            dpx.item.delete(user.cptr, 7, i, 1)
            dpx.sqlexec(game.DBType.taiwan_cain_2nd, "delete from creature_items where charac_no=" .. user:GetCharacNo() .." and slot=" .. i .." and it_id=" .. info.id)
            --os.execute(string.format("sh /dp2/script/delete_creature_item.sh %d %d %d", user:GetCharacNo(), i, info.id));
            --logger.info("will delete [iteminfo] id: %d count: %d name: %s attach: %d", info.id, info.count, info.name, info.attach_type)
            q = q +1
        end
    end
    if q > 0 then
        user:SendItemSpace(7)
        user:SendNotiPacketMessage(string.format("恭喜： %d个宠物清理 成功！", q))
    else
        user:SendNotiPacketMessage("注意： 宠物清理 失败！")
        dpx.item.add(user.cptr, item_id)
    end
end

-- 副职业一键分解券 分解装备前2栏 需要在开启个人分解机状态下使用
item_handler[2021121900] = function(user, item_id)
    local q = 0
    for i = 9, 24, 1 do
        local info = dpx.item.info(user.cptr, game.ItemSpace.INVENTORY, i)
        if info then
            user:Disjoint(game.ItemSpace.INVENTORY, i, user)
            --logger.info("will Disjoint [iteminfo] id: %d count: %d name: %s attach: %d", info.id, info.count, info.name, info.attach_type)
            if not dpx.item.info(user.cptr, game.ItemSpace.INVENTORY, i) then
                q = q + 1
            end
        end
    end
    if q > 0 then
        user:SendItemSpace(game.ItemSpace.INVENTORY)
        user:SendNotiPacketMessage(string.format("恭喜： %d件装备分解 成功！", q))
    else
        user:SendNotiPacketMessage("注意： 装备分解 失败！")
        dpx.item.add(user.cptr, item_id)
    end
end


-- 运行物品使用的处理函数
function _M:run(_user, item_id)
    local user = game.fac.user(_user)
    local handler = item_handler[item_id]
    if handler then
        handler(user, item_id)
        logger.info("[useItem2] acc:%d chr:%d item_id:%d", user:GetAccId(), user:GetCharacNo(), item_id)
    else
        logger.info(string.format("[useItem2-%s] 未支持的物品使用", item_id))
    end
    return true
end

return _M

// df_game_r.js - dp2.9

//本地时间戳
function get_timestamp()
{
    var date = new Date();
    date = new Date(date.setHours(date.getHours() + 10));     //转换到本地时间
    var year = date.getFullYear().toString();
    var month = (date.getMonth() + 1).toString();
    var day = date.getDate().toString();
    var hour = date.getHours().toString();
    var minute = date.getMinutes().toString();
    var second = date.getSeconds().toString();
    var ms = date.getMilliseconds().toString();


    return year + '-' + month + '-' + day + ' ' + hour + ':' + minute + ':' + second;
}



//给角色发道具
function api_CUser_AddItem(user, item_id, item_cnt)
{
	var item_space = Memory.alloc(4);
	var slot = CUser_AddItem(user, item_id, item_cnt, 6, item_space, 0);

	if(slot >= 0)
	{
		//通知客户端有游戏道具更新
		CUser_SendUpdateItemList(user, 1, item_space.readInt(), slot);
	}

	return;
}

//获取角色名字
function api_CUserCharacInfo_getCurCharacName(user)
{
	var p = CUserCharacInfo_getCurCharacName(user);
	if(p.isNull())
	{
		return '';
	}

	return p.readUtf8String(-1);
}

//给角色发消息
function api_CUser_SendNotiPacketMessage(user, msg, msg_type)
{
	var p = Memory.allocUtf8String(msg);
	CUser_SendNotiPacketMessage(user, p, msg_type);

	return;
}

//从客户端封包中读取数据
var PacketBuf_get_byte = new NativeFunction(ptr(0x858CF22), 'int', ['pointer', 'pointer'], {"abi":"sysv"});
var PacketBuf_get_short = new NativeFunction(ptr(0x858CFC0), 'int', ['pointer', 'pointer'], {"abi":"sysv"});
var PacketBuf_get_int = new NativeFunction(ptr(0x858D27E), 'int', ['pointer', 'pointer'], {"abi":"sysv"});
var PacketBuf_get_binary = new NativeFunction(ptr(0x858D3B2), 'int', ['pointer', 'pointer', 'int'], {"abi":"sysv"});

//服务器组包
var PacketGuard_PacketGuard = new NativeFunction(ptr(0x858DD4C), 'int', ['pointer'], {"abi":"sysv"});
var InterfacePacketBuf_put_header = new NativeFunction(ptr(0x80CB8FC), 'int', ['pointer', 'int', 'int'], {"abi":"sysv"});
var InterfacePacketBuf_put_byte = new NativeFunction(ptr(0x80CB920), 'int', ['pointer', 'uint8'], {"abi":"sysv"});
var InterfacePacketBuf_put_short = new NativeFunction(ptr(0x80D9EA4), 'int', ['pointer', 'uint16'], {"abi":"sysv"});
var InterfacePacketBuf_put_int = new NativeFunction(ptr(0x80CB93C), 'int', ['pointer', 'int'], {"abi":"sysv"});
var InterfacePacketBuf_put_binary = new NativeFunction(ptr(0x811DF08), 'int', ['pointer', 'pointer', 'int'], {"abi":"sysv"});
var InterfacePacketBuf_finalize = new NativeFunction(ptr(0x80CB958), 'int', ['pointer', 'int'], {"abi":"sysv"});
var Destroy_PacketGuard_PacketGuard = new NativeFunction(ptr(0x858DE80), 'int', ['pointer'], {"abi":"sysv"});

  //从客户端封包中读取数据(失败会抛异常, 调用方必须做异常处理)
function api_PacketBuf_get_byte(packet_buf)
{
	var data = Memory.alloc(1);

	if(PacketBuf_get_byte(packet_buf, data))
	{
		return data.readU8();
	}

	throw  new Error('PacketBuf_get_byte Fail!');
}
function api_PacketBuf_get_short(packet_buf)
{
	var data = Memory.alloc(2);

	if(PacketBuf_get_short(packet_buf, data))
	{
		return data.readShort();
	}

	throw  new Error('PacketBuf_get_short Fail!');
}
function api_PacketBuf_get_int(packet_buf)
{
	var data = Memory.alloc(4);

	if(PacketBuf_get_int(packet_buf, data))
	{
		return data.readInt();
	}


	throw  new Error('PacketBuf_get_int Fail!');
}
function api_PacketBuf_get_binary(packet_buf, len)
{
	var data = Memory.alloc(len);

	if(PacketBuf_get_binary(packet_buf, data, len))
	{
		return data.readByteArray(len);
	}

	throw  new Error('PacketBuf_get_binary Fail!');
}

//获取原始封包数据
function api_PacketBuf_get_buf(packet_buf)
{
	return packet_buf.add(20).readPointer().add(13);
}

//获取GameWorld实例
var G_GameWorld = new NativeFunction(ptr(0x80DA3A7), 'pointer', [], {"abi":"sysv"});
//根据server_id查找user
var GameWorld_find_from_world = new NativeFunction(ptr(0x86C4B9C), 'pointer', ['pointer', 'int'], {"abi":"sysv"});
//城镇瞬移
var GameWorld_move_area = new NativeFunction(ptr(0x86C5A84), 'pointer', ['pointer', 'pointer', 'int', 'int', 'int', 'int', 'int', 'int', 'int', 'int', 'int'], {"abi":"sysv"});


//linux创建文件夹
function api_mkdir(path)
{
    var opendir = new NativeFunction(Module.getExportByName(null, 'opendir'), 'int', ['pointer'], {"abi":"sysv"});
    var mkdir = new NativeFunction(Module.getExportByName(null, 'mkdir'), 'int', ['pointer', 'int'], {"abi":"sysv"});
    var path_ptr = Memory.allocUtf8String(path);
    if(opendir(path_ptr))
        return true;
    return mkdir(path_ptr, 0x1FF);
}

//服务器环境
var G_CEnvironment = new NativeFunction(ptr(0x080CC181), 'pointer', [], {"abi":"sysv"});
//获取当前服务器配置文件名
var CEnvironment_get_file_name = new NativeFunction(ptr(0x80DA39A), 'pointer', ['pointer'], {"abi":"sysv"});

//获取当前频道名
function api_CEnvironment_get_file_name()
{
    var filename = CEnvironment_get_file_name(G_CEnvironment());
    return filename.readUtf8String(-1);
}

//文件记录日志
var frida_log_dir_path = './frida_log/'
var f_log = null;
var log_day = null;
function log(msg)
{
    var date = new Date();
    date = new Date(date.setHours(date.getHours() + 10));     //转换到本地时间
    var year = date.getFullYear().toString();
    var month = (date.getMonth() + 1).toString();
    var day = date.getDate().toString();
    var hour = date.getHours().toString();
    var minute = date.getMinutes().toString();
    var second = date.getSeconds().toString();
    var ms = date.getMilliseconds().toString();

    //日志按日期记录
    if((f_log == null) || (log_day != day))
    {
        api_mkdir(frida_log_dir_path);
        f_log = new File(frida_log_dir_path + 'frida_' + api_CEnvironment_get_file_name() + '_' + year + '_' + month + '_' + day + '.log', 'a+');
        log_day = day;
    }

    //时间戳
    var timestamp = year + '-' + month + '-' + day + ' ' + hour + ':' + minute + ':' + second + '.' + ms;

    //控制台日志
    console.log('[' + timestamp + ']' + msg + '\n');

    //文件日志
    f_log.write('[' + timestamp + ']' + msg + '\n');
    //立即写日志到文件中
    f_log.flush();
}

//生成随机整数(不包含max)
function get_random_int(min, max)
{
    return Math.floor(Math.random() * (max - min)) + min;
}

//内存十六进制打印
function bin2hex(p, len)
{
    var hex = '';
    for(var i = 0; i < len; i++)
    {
        var s = p.add(i).readU8().toString(16);
        if(s.length == 1)
            s = '0' + s;
        hex += s;
        if (i != len - 1)
            hex += ' ';
    }
    return hex;
}





// 点券充值
var WongWork_IPG_CIPGHelper_IPGInput = new NativeFunction(ptr(0x80ffca4), "int", ["pointer", "pointer", "int", "int", "pointer", "pointer", "pointer", "pointer", "pointer", "pointer"], {abi: "sysv"});
// 同步点券数据库
var WongWork_IPG_CIPGHelper_IPGQuery = new NativeFunction(ptr(0x8100790), "int", ["pointer", "pointer"], {abi: "sysv"});
// 代币充值
var WongWork_IPG_CIPGHelper_IPGInputPoint = new NativeFunction(ptr(0x80fffc0), "int", ["pointer", "pointer", "int", "int", "pointer", "pointer"], {abi: "sysv"});


// 从客户端封包中读取数据
var PacketBuf_get_byte = new NativeFunction(ptr(0x858cf22), "int", ["pointer", "pointer"], {abi: "sysv"});
var PacketBuf_get_short = new NativeFunction(ptr(0x858cfc0), "int", ["pointer", "pointer"], {abi: "sysv"});
var PacketBuf_get_int = new NativeFunction(ptr(0x858d27e), "int", ["pointer", "pointer"], {abi: "sysv"});
var PacketBuf_get_binary = new NativeFunction(ptr(0x858d3b2), "int", ["pointer", "pointer", "int"], {abi: "sysv"});



//服务器组包
var PacketGuard_PacketGuard = new NativeFunction(ptr(0x858DD4C), 'int', ['pointer'], {"abi":"sysv"});
var InterfacePacketBuf_put_header = new NativeFunction(ptr(0x80CB8FC), 'int', ['pointer', 'int', 'int'], {"abi":"sysv"});
var InterfacePacketBuf_put_byte = new NativeFunction(ptr(0x80CB920), 'int', ['pointer', 'uint8'], {"abi":"sysv"});
var InterfacePacketBuf_put_short = new NativeFunction(ptr(0x80D9EA4), 'int', ['pointer', 'uint16'], {"abi":"sysv"});
var InterfacePacketBuf_put_int = new NativeFunction(ptr(0x80CB93C), 'int', ['pointer', 'int'], {"abi":"sysv"});
var InterfacePacketBuf_put_binary = new NativeFunction(ptr(0x811DF08), 'int', ['pointer', 'pointer', 'int'], {"abi":"sysv"});
var InterfacePacketBuf_finalize = new NativeFunction(ptr(0x80CB958), 'int', ['pointer', 'int'], {"abi":"sysv"});
var Destroy_PacketGuard_PacketGuard = new NativeFunction(ptr(0x858DE80), 'int', ['pointer'], {"abi":"sysv"});


// 获取GameWorld实例
var G_GameWorld = new NativeFunction(ptr(0x80da3a7), "pointer", [], {abi: "sysv"});
var GameWorld_IsEnchantRevisionChannel = new NativeFunction(ptr(0x082343fc), "int", ["pointer"], {abi: "sysv"});

//将协议发给所有在线玩家(慎用! 广播类接口必须限制调用频率, 防止CC攻击)
//除非必须使用, 否则改用对象更加明确的CParty::send_to_party/GameWorld::send_to_area
var GameWorld_send_all = new NativeFunction(ptr(0x86c8c14), "int", ["pointer", "pointer"], {abi: "sysv"});
var GameWorld_send_all_with_state = new NativeFunction(ptr(0x86c9184), "int", ["pointer", "pointer", "int"], {abi: "sysv"});
var stAmplifyOption_t_getAbilityType = new NativeFunction(ptr(0x08150732), "uint8", ["pointer"], {abi: "sysv"});
var stAmplifyOption_t_getAbilityValue = new NativeFunction(ptr(0x08150772), "uint16", ["pointer"], {abi: "sysv"});


// 获取DataManager实例
var G_CDataManager = new NativeFunction(ptr(0x80cc19b), "pointer", [], {abi: "sysv"});
// 获取装备pvf数据
var CDataManager_find_item = new NativeFunction(ptr(0x835FA32), 'pointer', ['pointer', 'int'], {"abi":"sysv"});
//获取道具名
var CItem_GetItemName = new NativeFunction(ptr(0x811ED82), 'pointer', ['pointer'], { "abi": "sysv" });
// 获取副本id
var CDungeon_get_index = new NativeFunction(ptr(0x080FDCF0),  'int', ['pointer'], {"abi":"sysv"});
// 获取角色状态
var CUser_get_state = new NativeFunction(ptr(0x80DA38C), 'int', ['pointer'], {"abi": "sysv"});
// 获取角色账号id
var CUser_get_acc_id = new NativeFunction(ptr(0x80DA36E), 'int', ['pointer'], {"abi": "sysv"});
// 给角色发消息
var CUser_SendNotiPacketMessage = new NativeFunction(ptr(0x86886CE), 'int', ['pointer', 'pointer', 'int'], {"abi": "sysv"});
// 获取角色名字
var CUserCharacInfo_getCurCharacName = new NativeFunction(ptr(0x8101028), "pointer", ["pointer"], {abi: "sysv"});
// 根据账号查找已登录角色
var GameWorld_find_user_from_world_byaccid = new NativeFunction(ptr(0x86c4d40), "pointer", ["pointer", "int"], {abi: "sysv"});
// 获取角色背包
var CUserCharacInfo_getCurCharacInvenW = new NativeFunction(ptr(0x80DA28E), 'pointer', ['pointer'], {"abi": "sysv"});
//发包给客户端
var CUser_Send = new NativeFunction(ptr(0x86485BA), 'int', ['pointer', 'pointer'], {"abi":"sysv"});
//通知客户端角色属性更新
var CUser_SendNotiPacket = new NativeFunction(ptr(0x867BA5C), 'int', ['pointer', 'int', 'int', 'int'], {"abi":"sysv"});
//获取DataManager实例
var G_CDataManager = new NativeFunction(ptr(0x80CC19B), 'pointer', [], {"abi":"sysv"});
//从pvf中获取任务数据
var CDataManager_find_quest = new NativeFunction(ptr(0x835FDC6), 'pointer', ['pointer', 'int'], {"abi":"sysv"});
// 获取背包槽中的道具
var CInventory_GetInvenRef = new NativeFunction(ptr(0x84FC1DE), 'pointer', ['pointer', 'int', 'int'], {"abi": "sysv"});
// 道具是否是装备
var Inven_Item_isEquipableItemType = new NativeFunction(ptr(0x08150812), 'int', ['pointer'], {"abi": "sysv"});
// 获取装备品级 todo 0x80f12d6 ???
var CItem_getRarity = new NativeFunction(ptr(0x080F12D6), 'int', ['pointer'], {"abi": "sysv"});
// 获取装备可穿戴等级
var CItem_getUsableLevel = new NativeFunction(ptr(0x80F12EE), 'int', ['pointer'], {"abi": "sysv"});
// 检查背包中道具是否为空
var Inven_Item_isEmpty = new NativeFunction(ptr(0x811ED66), 'int', ['pointer'], {"abi":"sysv"});
// 获取背包中道具item_id
var Inven_Item_getKey = new NativeFunction(ptr(0x850D14E), 'int', ['pointer'], {"abi":"sysv"});
// 道具是否是装备
var Inven_Item_isEquipableItemType = new NativeFunction(ptr(0x08150812), 'int', ['pointer'], {"abi":"sysv"});
// 是否魔法封印装备
var CEquipItem_IsRandomOption = new NativeFunction(ptr(0x8514E5E), 'int', ['pointer'], {"abi":"sysv"});
// 解封魔法封印
var random_option_CRandomOptionItemHandle_give_option = new NativeFunction(ptr(0x85F2CC6),  'int', ['pointer', 'int', 'int', 'int', 'int', 'int', 'pointer'], {"abi":"sysv"});
// 获取装备品级
var CItem_get_rarity = new NativeFunction(ptr(0x080F12D6), 'int', ['pointer'], {"abi":"sysv"});
// 获取装备可穿戴等级
var CItem_getUsableLevel = new NativeFunction(ptr(0x80F12EE), 'int', ['pointer'], {"abi":"sysv"});
// 获取装备[item group name]
var CItem_getItemGroupName = new NativeFunction(ptr(0x80F1312), 'int', ['pointer'], {"abi":"sysv"});
// 获取装备魔法封印等级?
var CEquipItem_GetRandomOptionGrade = new NativeFunction(ptr(0x8514E6E), 'int', ['pointer'], {"abi":"sysv"});

// 测试系统API
var strlen = new NativeFunction(ptr(0x0807E3B0), 'int', ['pointer'], {"abi": "sysv"});
// 获取字符串长度
var strlen = new NativeFunction(Module.getExportByName(null, 'strlen'), 'int', ['pointer'], {"abi": "sysv"});

//获取背包槽中的道具
var INVENTORY_TYPE_BODY = 0;            //身上穿的装备
var INVENTORY_TYPE_ITEM = 1;            //物品栏
var INVENTORY_TYPE_AVARTAR = 2;         //时装栏
var CInventory_GetInvenRef = new NativeFunction(ptr(0x84FC1DE), 'pointer', ['pointer', 'int', 'int'], {"abi":"sysv"});


// 存放所有用户的账号金库数据
var accountCargfo = {};

// 服务器组包
function api_PacketGuard_PacketGuard() {
    var packet_guard = Memory.alloc(0x20000);
    PacketGuard_PacketGuard(packet_guard);
    return packet_guard;
}

// 发送字符串给客户端
function api_InterfacePacketBuf_put_string(packet_guard, s) {
    var p = Memory.allocUtf8String(s);
    var len = strlen(p);
    InterfacePacketBuf_put_int(packet_guard, len);
    InterfacePacketBuf_put_binary(packet_guard, p, len);
    return;
}

function api_PacketBuf_get_short(packet_buf) {
    var data = Memory.alloc(2);

    if (PacketBuf_get_short(packet_buf, data)) {
        return data.readShort();
    }
    throw new Error('PacketBuf_get_short Fail!');
}


// 世界广播(频道内公告)
function api_GameWorld_SendNotiPacketMessage(msg, msg_type) {
    var packet_guard = api_PacketGuard_PacketGuard();
    InterfacePacketBuf_put_header(packet_guard, 0, 12);
    InterfacePacketBuf_put_byte(packet_guard, msg_type);
    InterfacePacketBuf_put_short(packet_guard, 0);
    InterfacePacketBuf_put_byte(packet_guard, 0);
    api_InterfacePacketBuf_put_string(packet_guard, msg);
    InterfacePacketBuf_finalize(packet_guard, 1);
    GameWorld_send_all_with_state(G_GameWorld(), packet_guard, 3); //只给state >= 3 的玩家发公告
    Destroy_PacketGuard_PacketGuard(packet_guard);
}

//给角色发消息
function api_CUser_SendNotiPacketMessage(user, msg, msg_type) {
    var p = Memory.allocUtf8String(msg);
    CUser_SendNotiPacketMessage(user, p, msg_type);
    return;
}

// 获取道具名字
function api_CItem_GetItemName(item_id) {
    var citem = CDataManager_find_item(G_CDataManager(), item_id);
    if (!citem.isNull()) {
        return CItem_GetItemName(citem).readUtf8String(-1);
    }

    return item_id.toString();
}

// 点券充值 (禁止直接修改billing库所有表字段, 点券相关操作务必调用数据库存储过程!)
function api_recharge_cash_cera(user, amount) {
    // 充值
    WongWork_IPG_CIPGHelper_IPGInput(ptr(0x941f734).readPointer(), user, 5, amount, ptr(0x8c7fa20), ptr(0x8c7fa20), Memory.allocUtf8String("GM"), ptr(0), ptr(0), ptr(0));
    // 通知客户端充值结果
    WongWork_IPG_CIPGHelper_IPGQuery(ptr(0x941f734).readPointer(), user);
}

// 代币充值 (禁止直接修改billing库所有表字段, 点券相关操作务必调用数据库存储过程!)
function api_recharge_cash_cera_point(user, amount) {
    // 充值
    WongWork_IPG_CIPGHelper_IPGInputPoint(ptr(0x941f734).readPointer(), user, amount, 4, ptr(0), ptr(0));
    // 通知客户端充值结果
    WongWork_IPG_CIPGHelper_IPGQuery(ptr(0x941f734).readPointer(), user);
}

// 获取角色名字
function api_CUserCharacInfo_getCurCharacName(user) {
    var p = CUserCharacInfo_getCurCharacName(user);
    if (p.isNull()) {
        return "";
    }
    return p.readUtf8String(-1);
}

// 获取随机数
function get_random_int(min, max) {
    return Math.floor(Math.random() * (max - min)) + min;
}

// 角色获取道具发送全服通知 processing_data(item_id, user, 3257, 2500, get_random_int(50, 888));
function processing_data(item_id, user, award_item_id, award_item_count, count) {
    const itemName = api_CItem_GetItemName(item_id);
    // pvf中获取装备数据
    var citem = CDataManager_find_item(G_CDataManager(), item_id);
    var rarity = CItem_getRarity(citem); // 装备品级
    if (parseInt(rarity) >= 3) {
        api_GameWorld_SendNotiPacketMessage("恭喜玩家<" + "" + api_CUserCharacInfo_getCurCharacName(user) + "" + ">在地下城中获得了" + rarity +
            "【" + itemName + "】，随机奖励点券：☆" + count + "☆", 14
        );
        api_recharge_cash_cera(user, count);
    }
}

// 角色登入登出处理
function userLogout() {
    // 选择角色处理函数 Hook GameWorld::reach_game_world
    Interceptor.attach(ptr(0x86C4E50), {
        // 函数入口, 拿到函数参数args
        onEnter: function(args) {
            // 保存函数参数
            this.user = args[1];
            console.log('[GameWorld::reach_game_world] this.user=' + this.user);
        },
        // 原函数执行完毕, 这里可以得到并修改返回值retval
        onLeave: function(retval) {
            // 给角色发消息问候
            api_CUser_SendNotiPacketMessage(this.user, 'Hello ' + api_CUserCharacInfo_getCurCharacName(this.user), 2);
        }
    });
    Interceptor.attach(ptr(0x86C5288), {
        onEnter: function(args) {
            var user = args[0];
            var accId = CUser_get_acc_id(user);
            console.log('[GameWorld::leave_game_world] user, accid' + user + ',' + accId);
            // todo 清除账号仓库 释放空间
            if (accountCargfo[accId]) {
                delete accountCargfo[accId];
                console.log('clean accountCargfo accId:' + accId)
            }
        },
        onLeave: function(retval) {}
    });
}

var CParty_Item_Slot = null;
// processing_data(item_id, user, 3257, 2500, get_random_int(50, 888));
/**
 * 角色在地下城副本中拾取物品 CParty_GetItem
 * 消息类型 1绿(私聊)/14管理员(喇叭)/16系统消息
 * **/
function CParty_GetItem() {
    Interceptor.attach(ptr(0x085b949c), {
        onEnter: function(args) {
            // char __cdecl CParty::_onGetItem(CParty *this, CUser *a2, unsigned int a3, unsigned int a4)
            var user = args[1];
            var item_id = args[2].toInt32(); // 取值范围
            var num = args[3].toInt32();
            var item_name = api_CItem_GetItemName(item_id);
            var charac_name = api_CUserCharacInfo_getCurCharacName(user);
            var itemData = CDataManager_find_item(G_CDataManager(), item_id);

            // 临时解决 0x8502D86 优先执行 0x085b949c slot(物品位置)
            // 通过魔法封印自动解封0x8502D86 检验slot是否一致

            if (CParty_Item_Slot) {
                // 角色背包
                var inven = CUserCharacInfo_getCurCharacInvenW(user);
                // 背包中新增的道具 暂时不知道如何获得slot(物品位置)
                var inven_item = CInventory_GetInvenRef(inven, INVENTORY_TYPE_ITEM, CParty_Item_Slot);
                // 过滤道具类型
                if (Inven_Item_isEquipableItemType(inven_item)) {
                    num = 1;
                    CParty_Item_Slot = null;
                }
            }
            // 2紫 3粉？ 4异界？ 5史诗？
            var ItemRarity = CItem_getRarity(itemData); // 稀有度
            // 装备数量不可以通过 num 获取
            console.log('ItemRarity', ItemRarity);
            if (ItemRarity >= 4) {
                api_GameWorld_SendNotiPacketMessage("恭喜「" + charac_name + "」在深渊爆出[" + item_name + "]！", 13);
            }

        },
        onLeave: function(retval) {}
    });
}

// 魔法封印自动解封
function auto_unseal_random_option_equipment(user) {
    // CInventory::insertItemIntoInventory
    Interceptor.attach(ptr(0x8502D86), {
        onEnter: function(args) {
            this.user = args[0].readPointer();
        },
        onLeave: function(retval) {
            // 物品栏新增物品的位置
            var slot = retval.toInt32();
            CParty_Item_Slot = slot;
            console.log('CParty_Item_Slot', slot);
        }
    });
}

// 捕获玩家游戏事件 日志
function hook_history_log() {
    // cHistoryTrace::operator()
    Interceptor.attach(ptr(0x854f990), {
        onEnter: function(args) {
            // 解析日志内容: "18000008",18000008,D,145636,"nickname",1,72,8,0,192.168.200.1,192.168.200.1,50963,11, DungeonLeave,"龍人之塔",0,0,"aabb","aabb","N/A","N/A","N/A"
            var history_log = args[1].readUtf8String(-1);
            var group = history_log.split(",");
            // 角色信息
            var account_id = parseInt(group[1]);
            var time_hh_mm_ss = group[3];
            var charac_name = group[4];
            var charac_no = group[5];
            var charac_level = group[6];
            var charac_job = group[7];
            var charac_growtype = group[8];
            var user_web_address = group[9];
            var user_peer_ip2 = group[10];
            var user_port = group[11];
            var channel_index = group[12]; // 当前频道id
            // 玩家游戏事件
            var game_event = group[13].slice(1); // 删除多余空格
            var Dungeon_nameget = group[14];
            var item_id = parseInt(group[15]); // 本次操作道具id
            var item_cnt = parseInt(group[17]); // 本次操作道具数量
            var reason = parseInt(group[18]); // 本次操作原因
            if (game_event) {
                console.log('history_log', history_log)
            }

            // 触发游戏事件的角色
            var user = GameWorld_find_user_from_world_byaccid(G_GameWorld(), account_id);
            if (user.isNull()) {
                return;
            }
            // DungeonLeave离开副本 DungeonEnter进入副本 KillMob杀死怪物 Money+
            if (game_event == "Item-") {
                // 道具减少: Item-,1,10000113,63,1,3,63,0,0,0,0,0,0000000000000000000000000000,0,0,00000000000000000000
                // log('玩家[' + charac_name + ']道具减少, 原因:' + reason + '(道具id=' + item_id + ', 使用数量=' + item_cnt);
                // 5丢弃道具 3使用道具 9分解道具 10使用属性石头
            } else if (game_event == "Item+") {
                var itemData = CDataManager_find_item(G_CDataManager(), item_id);
                var needLevel = CItem_getUsableLevel(itemData); // 等级
                var inEquRarity = CItem_getRarity(itemData); // 稀有度
                // 道具增加: Item+
                // reason 4副本内拾取 | inEquRarity 4史诗品级
                if (reason == 4) {
                    if (inEquRarity == 4) {
                        api_gameWorld_SendNotiPacketMessage('玩家[' + api_CUserCharacInfo_getCurCharacName(user) + ']' + ']在地下城中获得了[' + api_CItem_getItemName(item_id) + '] x1', 14);
                    }
                }
            } else if (game_event == "Money+") {
                var cur_money = parseInt(group[14]); // 当前持有的金币数量
                var add_money = parseInt(group[15]); // 本次获得金币数量
                var reason = parseInt(group[16]); // 本次获得金币原因
                // log('玩家[' + charac_name + ']获取金币, 原因:' + reason + '(当前持有金币=' + cur_money + ', 本次获得金币数量=' + add_money);
                // reason 4副本内拾取 5副本通关翻牌获取金币

            }
        },
        onLeave: function(retval) {}
    });
}

// 获取当前角色id
var CUserCharacInfo_getCurCharacNo = new NativeFunction(ptr(0x80CBC4E), 'int', ['pointer'], {"abi":"sysv"});
// 道具是否被锁
var CUser_CheckItemLock = new NativeFunction(ptr(0x8646942), 'int', ['pointer', 'int', 'int'], {"abi":"sysv"});
// 道具是否为消耗品
var CItem_is_stackable = new NativeFunction(ptr(0x80F12FA), 'int', ['pointer'], {"abi":"sysv"});
// 获取消耗品类型
var CStackableItem_GetItemType = new NativeFunction(ptr(0x8514A84),  'int', ['pointer'], {"abi":"sysv"});
// 获取徽章支持的镶嵌槽类型
var CStackableItem_getJewelTargetSocket = new NativeFunction(ptr(0x0822CA28),  'int', ['pointer'], {"abi":"sysv"});
// 获取时装管理器
var CInventory_GetAvatarItemMgrR = new NativeFunction(ptr(0x80DD576), 'pointer', ['pointer'], {"abi":"sysv"});
// 获取道具附加信息
var Inven_Item_get_add_info = new NativeFunction(ptr(0x80F783A), 'int', ['pointer'], {"abi":"sysv"});
// 获取时装插槽数据
var WongWork_CAvatarItemMgr_getJewelSocketData = new NativeFunction(ptr(0x82F98F8), 'pointer', ['pointer', 'int'], {"abi":"sysv"});
// 背包中删除道具(背包指针, 背包类型, 槽, 数量, 删除原因, 记录删除日志)
var CInventory_delete_item = new NativeFunction(ptr(0x850400C), 'int', ['pointer', 'int', 'int', 'int', 'int', 'int'], {"abi":"sysv"});
// 时装镶嵌数据存盘
var DB_UpdateAvatarJewelSlot_makeRequest = new NativeFunction(ptr(0x843081C), 'pointer', ['int', 'int', 'pointer'], {"abi":"sysv"});
 //获取角色名字
var CUserCharacInfo_getCurCharacName = new NativeFunction(ptr(0x8101028), 'pointer', ['pointer'], {"abi":"sysv"});
//给角色发消息
var CUser_SendNotiPacketMessage = new NativeFunction(ptr(0x86886CE), 'int', ['pointer', 'pointer', 'int'], {"abi":"sysv"});
//获取角色上次退出游戏时间
var CUserCharacInfo_getCurCharacLastPlayTick = new NativeFunction(ptr(0x82A66AA), 'int', ['pointer'], {"abi":"sysv"});
//获取角色等级
var CUserCharacInfo_get_charac_level = new NativeFunction(ptr(0x80DA2B8), 'int', ['pointer'], {"abi":"sysv"});
//获取角色当前等级升级所需经验
var CUserCharacInfo_get_level_up_exp = new NativeFunction(ptr(0x0864E3BA), 'int', ['pointer', 'int'], {"abi":"sysv"});
//角色增加经验
var CUser_gain_exp_sp = new NativeFunction(ptr(0x866A3FE), 'int', ['pointer', 'int', 'pointer', 'pointer', 'int', 'int', 'int'], {"abi":"sysv"});
//发送道具
var CUser_AddItem = new NativeFunction(ptr(0x867B6D4), 'int', ['pointer', 'int', 'int', 'int', 'pointer', 'int'], {"abi":"sysv"});
//获取角色背包
var CUserCharacInfo_getCurCharacInvenW = new NativeFunction(ptr(0x80DA28E), 'pointer', ['pointer'], {"abi":"sysv"});
//减少金币
var CInventory_use_money = new NativeFunction(ptr(0x84FF54C), 'int', ['pointer', 'int', 'int', 'int'], {"abi":"sysv"});
//增加金币
var CInventory_gain_money = new NativeFunction(ptr(0x84FF29C), 'int', ['pointer', 'int', 'int', 'int', 'int'], {"abi":"sysv"});
//通知客户端道具更新(客户端指针, 通知方式[仅客户端=1, 世界广播=0, 小队=2, war room=3], itemSpace[装备=0, 时装=1], 道具所在的背包槽)
var CUser_SendUpdateItemList = new NativeFunction(ptr(0x867C65A), 'int', ['pointer', 'int', 'int', 'int'], {"abi":"sysv"});

//获取系统时间
var CSystemTime_getCurSec = new NativeFunction(ptr(0x80CBC9E), 'int', ['pointer'], {"abi":"sysv"});
var GlobalData_s_systemTime_ = ptr(0x941F714);


//获取时装在数据库中的uid
function api_get_avartar_ui_id(avartar)
{
    return avartar.add(7).readInt();
}

//设置时装插槽数据(时装插槽数据指针, 插槽, 徽章id)
//jewel_type: 红=0x1, 黄=0x2, 绿=0x4, 蓝=0x8, 白金=0x10
function api_set_JewelSocketData(jewelSocketData, slot, emblem_item_id)
{
    if(!jewelSocketData.isNull())
    {
        //每个槽数据长6个字节: 2字节槽类型+4字节徽章item_id
        //镶嵌不改变槽类型, 这里只修改徽章id
        jewelSocketData.add(slot*6+2).writeInt(emblem_item_id);
    }

    return;
}

function fix_use_emblem() {
    Interceptor.attach(ptr(0x8217BD6), {
        onEnter: function(args) {
            try {
                var user = args[1];
                var packet_buf = args[2];

                console.log('收到角色[' + api_CUserCharacInfo_getCurCharacName(user) + ']的镶嵌请求');

                // 校验角色状态是否允许镶嵌
                var state = CUser_get_state(user);
                if (state != 3) {
                    console.log('角色状态不允许镶嵌，state=' + state);
                    return;
                }

                // 解析封包数据
                var avartar_inven_slot = api_PacketBuf_get_short(packet_buf);
                var avartar_item_id = api_PacketBuf_get_int(packet_buf);
                var emblem_cnt = api_PacketBuf_get_byte(packet_buf);

                console.log('时装槽位: ' + avartar_inven_slot);
                console.log('时装ID: ' + avartar_item_id);
                console.log('徽章数量: ' + emblem_cnt);

                // 获取时装道具
                var inven = CUserCharacInfo_getCurCharacInvenW(user);
                var avartar = CInventory_GetInvenRef(inven, INVENTORY_TYPE_AVARTAR, avartar_inven_slot);

                // 校验时装是否合法
                if (Inven_Item_isEmpty(avartar) || Inven_Item_getKey(avartar) != avartar_item_id || CUser_CheckItemLock(user, 2, avartar_inven_slot)) {
                    console.log('时装校验失败');
                    return;
                }

                // 获取时装插槽数据
                var avartar_add_info = Inven_Item_get_add_info(avartar);
                var inven_avartar_mgr = CInventory_GetAvatarItemMgrR(inven);
                var jewel_socket_data = WongWork_CAvatarItemMgr_getJewelSocketData(inven_avartar_mgr, avartar_add_info);

                // 如果没有插槽数据，强制初始化插槽
                if (jewel_socket_data.isNull()) {
                    console.log('时装没有镶嵌孔，正在初始化镶嵌孔...');
                    jewel_socket_data = api_initialize_jewel_sockets(avartar_add_info); // 假设存在初始化插槽的函数
                    if (jewel_socket_data.isNull()) {
                        console.log('初始化镶嵌孔失败，无法进行镶嵌');
                        return;
                    }
                }

                console.log('镶嵌孔数据: ' + bin2hex(jewel_socket_data, 30));

                // 确认是否有可用的插槽
                var available_slots = 0;
                for (var i = 0; i < 3; i++) {
                    var slot_data = jewel_socket_data.add(i * 6).readShort();
                    if (slot_data != 0) {
                        available_slots++;
                    }
                }

                if (available_slots < emblem_cnt) {
                    console.log('时装可用插槽不足');
                    return;
                }

                // 校验镶嵌徽章数量是否合法（最多3个插槽）
                if (emblem_cnt <= 3) {
                    var emblems = {};

                    for (var i = 0; i < emblem_cnt; i++) {
                        var emblem_inven_slot = api_PacketBuf_get_short(packet_buf);
                        var emblem_item_id = api_PacketBuf_get_int(packet_buf);
                        var avartar_socket_slot = api_PacketBuf_get_byte(packet_buf);

                        // 获取徽章道具
                        var emblem = CInventory_GetInvenRef(inven, INVENTORY_TYPE_ITEM, emblem_inven_slot);

                        // 校验徽章数据是否合法
                        if (Inven_Item_isEmpty(emblem) || Inven_Item_getKey(emblem) != emblem_item_id || avartar_socket_slot >= 3) {
                            console.log('徽章校验失败');
                            return;
                        }

                        // 获取徽章的 pvf 数据
                        var citem = CDataManager_find_item(G_CDataManager(), emblem_item_id);
                        if (citem.isNull()) {
                            console.log('徽章数据无效');
                            return;
                        }

                        // 校验徽章类型
                        if (!CItem_is_stackable(citem) || CStackableItem_GetItemType(citem) != 20) {
                            console.log('徽章类型校验失败');
                            return;
                        }

                        // 获取插槽类型并校验
                        var emblem_socket_type = CStackableItem_getJewelTargetSocket(citem);
                        var avartar_socket_type = jewel_socket_data.add(avartar_socket_slot * 6).readShort();

                        if (!(emblem_socket_type & avartar_socket_type)) {
                            console.log('插槽类型不匹配');
                            return;
                        }

                        emblems[avartar_socket_slot] = [emblem_inven_slot, emblem_item_id];
                    }

                    // 开始镶嵌
                    for (var avartar_socket_slot in emblems) {
                        var emblem_inven_slot = emblems[avartar_socket_slot][0];
                        var emblem_item_id = emblems[avartar_socket_slot][1];

                        // 删除徽章
                        CInventory_delete_item(inven, 1, emblem_inven_slot, 1, 8, 1);

                        // 设置时装插槽数据
                        api_set_JewelSocketData(jewel_socket_data, avartar_socket_slot, emblem_item_id);

                        console.log('徽章 ' + emblem_item_id + ' 已镶嵌到插槽 ' + avartar_socket_slot);
                    }

                    // 存储镶嵌数据
                    DB_UpdateAvatarJewelSlot_makeRequest(CUserCharacInfo_getCurCharacNo(user), api_get_avartar_ui_id(avartar), jewel_socket_data);

                    // 通知客户端更新
                    CUser_SendUpdateItemList(user, 1, 1, avartar_inven_slot);

                    // 回包给客户端
                    var packet_guard = api_PacketGuard_PacketGuard();
                    InterfacePacketBuf_put_header(packet_guard, 1, 204);
                    InterfacePacketBuf_put_int(packet_guard, 1);
                    InterfacePacketBuf_finalize(packet_guard, 1);
                    CUser_Send(user, packet_guard);
                    Destroy_PacketGuard_PacketGuard(packet_guard);

                    console.log('镶嵌操作完成');
                } else {
                    console.log('镶嵌的徽章数量超过3个');
                }

            } catch (error) {
                console.log('fix_use_emblem 出现异常: ' + error);
            }
        },
        onLeave: function(retval) {
            retval.replace(0);  // 不再踢线
        }
    });
}



	//允许赛利亚房间的人互相可见
function share_seria_room()
{
	//Hook Area::insert_user
	Interceptor.attach(ptr(0x86C25A6), {

		onEnter: function (args) {
			//修改标志位, 让服务器广播赛利亚旅馆消息
			args[0].add(0x68).writeInt(0);
		},
		onLeave: function (retval) {
		}
	});
}

//hookCUser::DisConnSig
function CUser_is_ConnSig()
{
		
	Interceptor.attach(ptr(0x86489F4), {
	
		onEnter: function (args) {
			//CUser *a1, int a2, int a3, int a4
			console.log("CUserisConnSig--------------------------state:"+args[0],args[1],args[2],args[3]);
			var cu =args[0]
			//var a2 = args[1].readInt();
			//var a3 = args[2].readInt();
			//var a4 = args[3].readInt();
			//console.log('-' + '-' + '-' + '-' + '-' + '-' + '-' + '-' + '-')
		},
		onLeave: function (retval) {
		}
	});
}

//调用Encrypt解密函数
var decrypt = new NativeFunction(ptr(0x848DB5E), 'pointer', ['pointer', 'pointer', 'pointer'], {"abi":"sysv"});

//拦截Encryption::Encrypt
function hook_encrypt ()
{
	Interceptor.attach(ptr(0x848DA70), {
	
		onEnter: function (args) {
			console.log("Encrypt:"+args[0],args[1],args[2]);
			//var u = a.readUtf8String(args[0])
			//console.log(decrypt(args[0],args[1],args[2]));
		},
		onLeave: function (retval) {
		}
	});
}

//拦截Encryption::decrypt
function hookdecrypt ()
{
	Interceptor.attach(ptr(0x848DB5E), {
	
		onEnter: function (args) {
			console.log("decrypt:"+args[0],args[1],args[2]);
		},
		onLeave: function (retval) {
		}
	});
}

//拦截encrypt_packet
function hookencrypt_packet ()
{
	Interceptor.attach(ptr(0x858D86A), {
	
		onEnter: function (args) {
			console.log("encrypt_packet:"+args[0]);
		},
		onLeave: function (retval) {
		}
	});
}

//拦截DisPatcher_Login
function DisPatcher_Login()
{

	Interceptor.attach(ptr(0x81E8C78), {

	onEnter: function (args) {
		console.log('DisPatcher_Login:' + args[0] , args[1] , args[2] , args[3] , args[4] );
		},
		onLeave: function (retval) {
		}
	});
}

//拦截DisPatcher_ResPeer::dispatch_sig
function DisPatcher_ResPeer_dispatch_sig()
{

	Interceptor.attach(ptr(0x81F088E), {

	onEnter: function (args) {
		console.log('DisPatcher_ResPeer_dispatch_sig:' + args[0] , args[1] , args[2] , args[3] );
		},
		onLeave: function (retval) {
		}
	});
}

//拦截PacketDispatcher::doDispatch
function PacketDispatcher_doDispatch()
{

	Interceptor.attach(ptr(0x8594922), {

	onEnter: function (args) {
		//int a1, CUser *a2, int a3, unsigned __int16 a4, char *a5, signed int a6, int a7, __int16 a8
		
		console.log('PacketDispatcher_doDispatch:' + args[0] , args[1] , args[2] , args[3] , args[4] , args[5] , args[6] , args[7]);
		var a1 = args[0].readInt();
		console.log(a1);
		var a2 = args[1].readInt();
		console.log(a2);
		//var a3 = args[2].readInt();
		//console.log(a3);
		//var a4 = args[3].readInt();
		//console.log(a4);
		var a5 = args[4].readUtf16String(-1);
		console.log(a5);
		//var a6 = args[5].readInt();
		//console.log(a6);
		//var a7 = args[6].readInt();
		//console.log(a7);
		//var a8 = args[7].readInt();
		//console.log(a8);
		//console.log(a1+'-'+a2+'-'+a3+'-'+a4+'-'+a6+'-'+a7+'-'+a8);
		},
		onLeave: function (retval) {
		}
	});
}

//拦截PacketDispatcher::PacketDispatcher
function PacketDispatcher_PacketDispatcher()
{

	Interceptor.attach(ptr(0x8590A2E), {

	onEnter: function (args) {
		console.log('PacketDispatcher_PacketDispatcher:' + args[0] );
		var a1 = args[0].readInt();
		},
		onLeave: function (retval) {
		}
	});
}

//拦截CUser::SendCmdOkPacket
function CUser_SendCmdOkPacket()
{

	Interceptor.attach(ptr(0x867BEA0), {

	onEnter: function (args) {
		console.log('CUser_SendCmdOkPacket:' + args[0] + args[1]);
		//var a1 = args[0].readInt();
		var a2 = args[0].readInt();
		console.log("CUser_SendCmdOkPacket:"+a2);
		},
		onLeave: function (retval) {
		}
	});
}

// 加载主功能
function start() {
    console.log('==========================================================frida start df_game_r.js - dp2.9 start ===========================================================');
    CParty_GetItem();
    //开启时装镶嵌
    fix_use_emblem();
    console.log('fix_use_emblem--------------------OK');
    //赛利亚房间互相可见
    //share_seria_room();
    //console.log('share_seria_room---------------------OK');
    auto_unseal_random_option_equipment(); // 辅助检查物品位置slot
    // hook_history_log();
    // userLogout();
    console.log('==========================================================frida start df_game_r.js - dp2.9 end =============================================================');
}


//=============================================以下是dp集成frida==============================================================================================================
/*
frida 官网地址: https://frida.re/

frida提供的js api接口文档地址: https://frida.re/docs/javascript-api/

关于dp2支持frida的说明, 请参阅: /dp2/lua/df/frida.lua
*/

// 入口点
// int frida_main(lua_State* ls, const char* args);
function frida_main(ls, _args) {
    // args是lua调用时传过来的字符串
    // 建议约定lua和js通讯采用json格式
    const args = _args.readUtf8String();

    // 在这里做你需要的事情
    console.log('frida main, args = ' + args);

    return 0;
}

// 当lua调用js时触发
// int frida_handler(lua_State* ls, int arg1, float arg2, const char* arg3);
function frida_handler(ls, arg1, arg2, _arg3) {
    const arg3 = _arg3.readUtf8String();

    // 如果需要通讯, 在这里编写逻辑
    // 比如: arg1是功能号, arg3是数据内容 (建议json格式)

    // just for test
    dp2_lua_call(arg1, arg2, arg3)

    return 0;
}

// 获取dp2的符号
// void* dp2_frida_resolver(const char* fname);
var __dp2_resolver = null;

function dp2_resolver(fname) {
    return __dp2_resolver(Memory.allocUtf8String(fname));
}

// 通讯 (调用lua)
// int lua_call(int arg1, float arg2, const char* arg3);
var __dp2_lua_call = null;

function dp2_lua_call(arg1, arg2, _arg3) {
    var arg3 = null;
    if (_arg3 != null) {
        arg3 = Memory.allocUtf8String(_arg3);
    }
    return __dp2_lua_call(arg1, arg2, arg3);
}

// 准备工作
function setup() {
    var addr = Module.getExportByName('libdp2.so', 'dp2_frida_resolver');
    __dp2_resolver = new NativeFunction(addr, 'pointer', ['pointer']);

    addr = dp2_resolver('lua.call');
    __dp2_lua_call = new NativeFunction(addr, 'int', ['int', 'float', 'pointer']);

    addr = dp2_resolver('frida.main');
    Interceptor.replace(addr, new NativeCallback(frida_main, 'int', ['pointer', 'pointer']));

    addr = dp2_resolver('frida.handler');
    Interceptor.replace(addr, new NativeCallback(frida_handler, 'int', ['pointer', 'int', 'float', 'pointer']));

    Interceptor.flush();
    console.log('frida setup ok');

    // frida自己的配置
    start();
}

// 延迟加载插件 不使用
function awake() {
    // Hook check_argv
    console.log('================================================ frida awake ================================================================');
    Interceptor.attach(ptr(0x829EA5A), {
        onEnter: function(args) {},
        onLeave: function(retval) {
            //等待check_argv函数执行结束 再加载插件
            console.log('================================================ frida awake setup ================================================================');
            setup();
        }
    });
}

rpc.exports = {
    init: function(stage, parameters) {
        console.log('frida init ' + stage);
        if (stage == 'early') {
            // dp2.8+ /dp2/lua/df/frida.lua内置
            // awake();
            setup();
        } else {
            // 热重载
            console.log('================================================ frida reload ================================================================');
            setup();
        }
    },
    dispose: function() {
        console.log('================================================ frida dispose ================================================================');
    }
};
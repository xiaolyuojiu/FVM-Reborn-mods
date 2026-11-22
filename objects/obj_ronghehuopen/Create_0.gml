// obj_ronghehuopen（融合火盆）Create 事件
// 三形态：0转 刺梨烧烤盘 / 1转 冰榴莲烤盘 / 2转 缤纷杂果冰盘
// 机制：过火增幅（子弹伤害 × atk 增幅倍率，冰弹除外）+ 啃咬反伤（咬多少弹多少）；
//       1转起每隔[寒气间隔]在周围 5*5 释放一次寒气（**持续 8 秒、每秒 1 跳、共 8 跳**，命中减速 4 秒）；
//       过火外观按融合档位走：初融 / 深融 = 火弹（spr_ronghehuopen_fire_bullet），
//       灵融 = 冰火弹（spr_ronghehuopen_ice_bullet）；标记（brazier_list 哨兵）在 scripts/mod_bullet_hazard
//       的 bullet_hazard_ronghe_look 里打，真正的换图由 obj_bullet_parent 的 Begin Draw
//       调 bullet_hazard_look 在绘制前统一做，卡片本身不管。
//       数值取自「这组卡的推荐数值和情报岛.xlsx」新普卡-融合卡 81-89 行。
event_inherited();  // 继承父对象属性
plant_id = "ronghehuopen";
obj_type = object_index;
current_level = 1
event_user(0)
if shape == 0{
	sprite_index = spr_ronghehuopen
}
else if shape == 1{
	sprite_index = spr_ronghehuopen_1
}
else{
	sprite_index = spr_ronghehuopen_2
}

// ========== 特定属性默认值 ==========
idle_anim = 10
attack_anim = 0
flash_speed = 6
plant_type = "normal"
is_slowdown = false
// 攻击口径：寒气只打陆地（父类默认也是 normal，这里显式写一份，
//   让 桌面/fvm的ai/生成卡牌可攻击表.py 能按 ①「卡片自己的 target_type」取到，不用走 override）
target_type = "normal";

// 啃咬反伤：记录上一帧血量，掉血时把掉血量等量弹给正在啃咬本卡的老鼠
current_hp_track = hp

// ========== 注册表取值（寒气 / 过火倍率）==========
// 星级 / 形态可能在建实例之后才写入（升星、转职），所以 Step 里按 _rh_lv / _rh_sh 判断重取。
var _rh_info = get_plant_data_with_skill("ronghehuopen", shape, clamp(current_level, 0, 16), 0);

// ── 寒气（深度融合起）──
//   威力 / 释放间隔 走注册表 custom["寒气伤害"] / ["寒气间隔"]（间隔按秒存，这里 ×60 转帧）
//   其余是**固定口径、不进 custom**：1 秒 1 跳、共 8 跳（= 持续 8 秒）、命中减速 4 秒
cold_dmg_tick    = 8;     // 共 8 跳（1 秒 1 跳 → 持续 8 秒）
cold_tick_sec    = 1;     // 每跳间隔（秒）
cold_slow_frames = 240;   // 减速帧数（4 秒）
cold_damage = 48;         // 兜底 = 0/1 星档
cold_interval = 45 * 60;  // 兜底 = 0/1 星档（45 秒）
if (_rh_info != undefined){
	if (ds_map_exists(_rh_info, "寒气伤害")) cold_damage   = _rh_info[? "寒气伤害"];
	if (ds_map_exists(_rh_info, "寒气间隔")) cold_interval = round(_rh_info[? "寒气间隔"] * 60);
}
cold_timer = 0
// 寒气场（持续 8 秒、每秒 1 跳）的结算状态：
//   场存在期间由本卡每 cold_tick_sec 秒结算一跳，跳数用完即止（与场上那 25 片寒气同步结束）
cold_field_ticks = 0;   // 本次寒气还剩几跳
cold_field_timer = 0;   // 距离下一跳的帧数

// ========== 过火倍率（注册表 custom["过火倍率"]）==========
// 本卡不攻击（atk = 0），倍率只走 fire_mult_override（父类 Collision_obj_fire_source 优先读它）。
// 数值口径（陌路 4.增幅 r22 / r25）= 二转火盆基础倍率 + 融合附加；灵融再叠一份灵魂附加。
fire_mult_override = 1;
if (_rh_info != undefined && ds_map_exists(_rh_info, "过火倍率"))
	fire_mult_override = _rh_info[? "过火倍率"];
// 海克斯：只吃「点名本卡 / 融合卡」的专属倍率（hex_147 火盆类攻击×2、食之灵融合卡攻击）
fire_mult_override *= hex_batch2_id_atk("ronghehuopen");
_rh_lv = current_level;
_rh_sh = shape;


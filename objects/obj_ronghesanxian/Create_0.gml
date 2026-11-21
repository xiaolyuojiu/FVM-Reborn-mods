// obj_ronghesanxian（融合三线）Create 事件
// 三形态：0 子母三线酒架 / 1 仙人掌花酒架 / 2 烤灯笼鱼酒架
event_inherited();  // 继承父对象属性
plant_id = "ronghesanxian";
obj_type = object_index;
current_level = 1
event_user(0)
if shape == 0{
	sprite_index = spr_ronghesanxian
}
else if shape == 1{
	sprite_index = spr_ronghesanxian_1
}
else{
	sprite_index = spr_ronghesanxian_2
}

// 20 帧素材：待机 1-12 帧（image_index 0-11）、攻击 13-20 帧（image_index 12-19，花嘴后坐再伸出）
idle_anim = 11
attack_anim = 8
flash_speed = 5
plant_type = "normal"
feature_type = "normal"
is_slowdown = false
attack_type = ATTACK_TYPE.SHOOTER
target_type = "normal"

// custom：子弹数 / 燃烧概率 / 燃烧伤害 / 穿透数量（灵魂融合）
var _sk = variable_instance_exists(id, "skill") ? skill : 0;
var _info = get_plant_data_with_skill("ronghesanxian", shape, clamp(current_level, 0, 16), _sk);
shots_per_row = (shape == 0) ? 2 : 3;
burn_chance = 30;
burn_damage = 0;
pierce_count = 0;
if (_info != undefined){
	if (ds_map_exists(_info, "子弹数"))   shots_per_row = _info[? "子弹数"];
	if (ds_map_exists(_info, "燃烧概率")) burn_chance   = _info[? "燃烧概率"];
	if (ds_map_exists(_info, "燃烧伤害")) burn_damage   = _info[? "燃烧伤害"];
	if (ds_map_exists(_info, "穿透数量")) pierce_count  = _info[? "穿透数量"];
}

// 本次攻击是否已开火；本次攻击已齐射次数（一次攻击动画内按 shots_per_row 分次齐射、错 5 帧）
fired_this_attack = false
salvo_index = 0
salvo_timer = 0

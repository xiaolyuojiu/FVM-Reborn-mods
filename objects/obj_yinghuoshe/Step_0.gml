if (global.is_paused) exit;
event_inherited();
if (hp <= 0) exit;

zodiac_age++;

if (is_frozen || state == CARD_STATE.SLEEP) exit;

// 枚举全场存活老鼠（含傀儡马代理）
// 老鼠首次进入自身3×3范围时造成一次伤害（每个目标只结算一次）
var yh1_list = [];
for (var yh_i = 0; yh_i < instance_number(obj_enemy_parent); yh_i++) {
    var yh_e = instance_find(obj_enemy_parent,yh_i);
    if (instance_exists(yh_e) && yh_e.hp > 0) array_push(yh1_list,yh_e);
}
for (var yh_i = 0; yh_i < instance_number(obj_kuileima_decoy); yh_i++) {
    var yh_d = instance_find(obj_kuileima_decoy,yh_i);
    if (instance_exists(yh_d) && yh_d.hp > 0 && !array_contains(yh1_list,yh_d)) array_push(yh1_list,yh_d);
}
var radius = 1;
// 伤害口径（表 13.辅助 r72「范围3*3，二转伤害可叠加」）：0/1 转同一只鼠只吃一次萤火虫伤害，二转才可叠加
var _yh_stack = (shape >= 2);
for (var i = 0; i < array_length(yh1_list); i++) {
    var e = yh1_list[i];
    if (e.target_type == "underground" || e.target_type == "dance"
        || e.target_type == "invisible") continue;
    if (_yh_stack) {
        if (array_contains(zodiac_firefly_hit_ids,e.id)) continue;
    } else if (variable_instance_exists(e,"yh_hit") && e.yh_hit) continue;
    var eg = get_grid_position_from_world(e.x,e.y);
    if (abs(eg.col-grid_col) <= radius && abs(eg.row-grid_row) <= radius) {
        if (_yh_stack) array_push(zodiac_firefly_hit_ids,e.id);
        else e.yh_hit = true;
        var yhs_dmg = atk;
        with (e) {
            damage_amount = yhs_dmg;
            damage_type = "pierce";
            event_user(0);
        }
    }
}

var interval = cycle;
// 待机且无累计周期时，范围内已有目标则立即进入攻击计时
if (state == CARD_STATE.IDLE && zodiac_timer == 0) {
    var yh2_list = [];
    for (var yh2_i = 0; yh2_i < instance_number(obj_enemy_parent); yh2_i++) {
        var yh2_e = instance_find(obj_enemy_parent,yh2_i);
        if (instance_exists(yh2_e) && yh2_e.hp > 0) array_push(yh2_list,yh2_e);
    }
    for (var yh2_i = 0; yh2_i < instance_number(obj_kuileima_decoy); yh2_i++) {
        var yh2_d = instance_find(obj_kuileima_decoy,yh2_i);
        if (instance_exists(yh2_d) && yh2_d.hp > 0 && !array_contains(yh2_list,yh2_d)) array_push(yh2_list,yh2_d);
    }
    var has_target = false;
    for (var j = 0; j < array_length(yh2_list); j++) {
        var e2 = yh2_list[j];
        if (e2.target_type == "underground" || e2.target_type == "dance"
            || e2.target_type == "invisible") continue;
        var eg2 = get_grid_position_from_world(e2.x,e2.y);
        if (abs(eg2.col-grid_col) <= radius && abs(eg2.row-grid_row) <= radius) {has_target = true; break;}
    }
    if (has_target) zodiac_timer = interval - 1;
}

zodiac_timer++;
if (zodiac_timer >= interval) {
    zodiac_timer = 0;
    state = CARD_STATE.ATTACK;
    image_index = idle_anim + 1;
    zodiac_shot_this_anim = false;
}
if (state == CARD_STATE.ATTACK) {
    // 与星星兔一致：动画第18帧执行攻击动作。
    if (!zodiac_shot_this_anim && image_index == 18) {
        zodiac_shot_this_anim = true;
        // 每 15 秒产生火苗，朵数读注册表 custom["火苗朵数"]
        var _fsk   = variable_instance_exists(id, "skill") ? skill : 0;
        var _finfo = get_plant_data_with_skill(plant_id, shape, clamp(current_level, 0, 16), _fsk);
        var count  = 1;
        if (_finfo != undefined && ds_map_exists(_finfo, "火苗朵数")) count = _finfo[? "火苗朵数"];
        var value = 20;
        if (variable_instance_exists(id,"flame_produce")) {
            value = is_array(flame_produce)
                ? flame_produce[clamp(current_level,0,array_length(flame_produce)-1)]
                : flame_produce;
        }
        for (var f = 0; f < count; f++) {
            var inst = instance_create_depth(x,y-60,depth-1000,obj_flame);
            inst.value = value;
        }
    }
    if (zodiac_shot_this_anim && zodiac_timer > 0 && image_index == idle_anim + 1) {
        state = CARD_STATE.IDLE;
        image_index = 0;
        zodiac_shot_this_anim = false;
    }
}

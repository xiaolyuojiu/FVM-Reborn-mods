event_inherited();
plant_id = "liehuohu";
obj_type = object_index;
event_user(0);

sprite_index = spr_liehuohu;
if (shape == 1) sprite_index = spr_liehuohu_1;
else if (shape == 2) sprite_index = spr_liehuohu_2;

attack_anim = 11;
idle_anim = 11;
first_produce_delay = 60;
flash_speed = 6;
plant_type = "normal";
is_slowdown = false;

flame_unit_value = 35;
flame_produce = 35;
flame_burst_count = 1;
storage_limit = 1500;
storage_amount = 0;
return_pending = false;

if (shape == 1) {
    flame_burst_count = 2;
} else if (shape == 2) {
    flame_burst_count = 2;
}

// custom：储能比例（按星级）/ 储能上限（按形态）
var _sk = variable_instance_exists(id, "skill") ? skill : 0;
var _info = get_plant_data_with_skill("liehuohu", shape, clamp(current_level, 0, 16), _sk);
storage_ratio = 12;
if (_info != undefined){
    if (ds_map_exists(_info, "储能比例")) storage_ratio = _info[? "储能比例"];
    if (ds_map_exists(_info, "储能上限")) storage_limit = _info[? "储能上限"];
}

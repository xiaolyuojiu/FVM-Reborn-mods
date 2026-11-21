event_inherited();
plant_id = "panduola_god";
obj_type = object_index;
current_level = 1;
event_user(0);

if (shape == 0)
    sprite_index = spr_panduola_god;
else if (shape == 1)
    sprite_index = spr_panduola_god_1;
else if (shape == 2)
    sprite_index = spr_panduola_god_2;
else if (shape == 3)
    sprite_index = spr_panduola_god_3;

image_index = 0;
image_speed = 0;

attack_anim = 0;
idle_anim = 0;
flash_speed = 5;
plant_type = "normal";
target_type = "all";
invincible = true;

trigger_timer = 0;
triggered = false;

// custom：毒气伤害（三跳同一数值）
var _sk = variable_instance_exists(id, "skill") ? skill : 0;
var _info = get_plant_data_with_skill("panduola_god", shape, clamp(current_level, 0, 18), _sk);
poison_damage = 900;
if (_info != undefined && ds_map_exists(_info, "毒气伤害")) poison_damage = _info[? "毒气伤害"];

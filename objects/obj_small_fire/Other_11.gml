global.zodiac_flame_mult = 1;
global.zodiac_query_card = id;
with (obj_yanyantu) event_user(0);

// 单轮产火朵数读注册表 custom["火苗朵数"]
var _sk   = variable_instance_exists(id, "skill") ? skill : 0;
var _info = get_plant_data_with_skill(plant_id, shape, clamp(current_level, 0, 16), _sk);
var _cnt  = 1;
if (_info != undefined && ds_map_exists(_info, "火苗朵数")) _cnt = _info[? "火苗朵数"];

for (var _i = 0; _i < _cnt; _i++)
{
    var _f = instance_create_depth(x, y - 60, depth - 1000, obj_flame);
    _f.value = floor(flame_produce * global.zodiac_flame_mult);
}

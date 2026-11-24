event_inherited();
plant_id = "ice_god";
obj_type = object_index;
current_level = 1;
event_user(0);

if (shape == 0)
    sprite_index = spr_ice_god;
else if (shape == 1)
    sprite_index = spr_ice_god_1;
else if (shape == 2)
    sprite_index = spr_ice_god_2;
else if (shape == 3)
    sprite_index = spr_ice_god_3;

attack_anim = 12;
idle_anim = 10;
flash_speed = 5;
plant_type = "normal";
is_slowdown = false;
// 表 9.追踪 r83：只有终转冰神能索敌并攻击地鼠；0~四转用 track（陆/潜/空）。
//   track_under = 多一个地鼠；钻地中的龙渊地精仍由 scatter_target_blocked 另排。
target_type = (shape >= 3) ? "track_under" : "track";
attack_timer = 0;

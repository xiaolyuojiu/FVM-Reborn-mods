event_inherited();

sprite_index = spr_guihuajiu_burn;

frame_start = 0;
frame_end = 13;
anim_loop_frames = 0;

damage = 10;
damage_type = "physical";
tick_interval = 21;
life = 42;

lock_grid = true;
grid_col = -1;
grid_row = -1;
single_hit = false;
mouse_fx_spr = -1;
// 2026-11-21 用户口径：火格按卡本身的 normal 范围结算伤害（陆鼠 + 障碍）。
//   原来手写的 5 类（normal/dance/invisible/diver/obstacle）会顺带烧 非主流·高跷 / 幽灵 / 潜水，属过宽。
//   走灰烬口径的是**死亡爆炸**（obj_guihuajiu_boom 的 boom_type = "ash"），与火格无关。
hittable_types = get_hittable_enemy_types("normal");

drunk_time = 0;
drunk_mult = 1.5;

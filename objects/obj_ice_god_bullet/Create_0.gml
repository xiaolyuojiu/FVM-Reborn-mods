// 目标类型：直击走 with(target_instance) 不判类型，这个值只给两处用 ——
//   ① Destroy 里终转溅射筛类型（can_target_on）
//   ② 敌人碰撞事件读 other.target_type（如 obj_ly_gaoqiao 的舞步守卫）
//   实际值由 obj_ice_god/Other_11 按卡片 target_type 覆盖（0~四转 track / 终转 track_under）
target_type = "track";
damage_type = "normal";
damage = 0;
target_enemy = -4;
hitted_enemy = -4;
move_speed = 0;
row = 0;
col = 0;
image_xscale = 1;
image_yscale = 1;

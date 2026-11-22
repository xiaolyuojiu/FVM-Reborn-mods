// obj_honeytrap_bee（蜜糖陷阱召唤的蜜蜂）Create
// 停靠时在本卡右上排队轻微浮动；放飞后追踪目标，命中造成伤害（对 BOSS 乘 boss_mult）。
image_speed  = 1;
image_index  = 0;
image_angle  = 0;
image_alpha  = 1;
image_blend  = c_white;
image_xscale = 1.3;   // 三只常驻显示，缩放压低绘制量
image_yscale = 1.3;

stored     = true;
damage     = 0;
boss_mult  = 1;
owner_id   = noone;
target_id  = noone;
park_index = 0;
timer      = 0;
move_speed = 10;
max_life   = 420;
target_type = "land_air_ug";   // 与蜜糖陷阱同口径（陆地 / 空中 / 地下）
relock_timer   = 0;    // 重索敌节流（每 relock_gap 帧才扫一次敌人）
relock_gap     = 10;
relock_fail    = 0;    // 连续锁不到的次数
relock_fail_max = 3;   // 连续 3 次锁不到就退场

// 命中黄光（素材第 19~23 帧）：命中后先播这一段再销毁，播完约 15 帧（5 帧 × 3 tick）
hitting   = false;
hit_t     = 0;
hit_first = 18;
hit_last  = 22;

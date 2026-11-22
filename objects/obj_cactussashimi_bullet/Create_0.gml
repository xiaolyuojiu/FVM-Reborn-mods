/// 仙人掌刺身子弹：水平直射 + 手动逐帧动画
/// 3.1.0 上游用 obj_bullet_parent 的钩子框架，本工程（mod）子弹走自建 Step 循环，
/// 因此这里只保留状态字段，行为全部写在 Step_0。
damage = 0;
move_speed = 0;
row = 0;
target_row = 0;
damage_type = "normal";
target_type = "normal";
burnt = 0;
bounced = false;
timer = 0;
image_speed = 0;
image_xscale = 1.8;
image_yscale = 1.8;
hittable_types = get_hittable_enemy_types(target_type);
hit_tick = 0;

// ── 环境交互：吃火 / 可反弹（碰撞事件由父类 obj_bullet_parent 统一处理）
hazard_fire = true;
hazard_rebound = true;
fire_mult = 1;

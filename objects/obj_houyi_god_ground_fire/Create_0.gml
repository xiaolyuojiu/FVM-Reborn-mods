// obj_houyi_god_ground_fire（后羿 · 地火格）Create 事件
// 口径照 obj_fashishe_poison_cell（法师蛇毒雾格）：每 tick_interval 帧结算一跳，
//   每跳伤害 = 每层 damage × 存活的层数（= 注册表 custom["灼烧伤害"]，固定值不随星级变）。
//   2026-11-24：**同格只留 1 个实例**，层数用 layer_t（每层的加入时刻）记账 ——
//     原来一层一个实例，3 行 × 5 格 × 12 层 = 180 个；现在固定 ≤15 个，每层仍各自 5 秒后过期，
//     跳伤 = 每层伤害 × 还活着的层数，总量与「一层一个实例」等价。
//   持续 / 跳数仍由卡片读注册表 custom（灼烧时间 / 灼烧次数）后传进来。
//   命中：行严格相等、列严格等于本格（2026-11-24 用户口径：最右格也不烧到场外 / 第 10 列）。
//   与 obj_houyi_god_fire（挂在老鼠身上的三昧真火）不是一回事，那个是子弹旧口径，现在不用了。
image_speed = 0;      // 🔴 必须 0：帧由 Step 的 t 推，image_speed = 1 会每步再推一帧，动画翻倍
image_index = 0;
image_angle = 0;
image_alpha = 1;
image_blend = c_white;
image_xscale = 1;
image_yscale = 1;

damage        = 0;      // 实际结算值：Step 里 = dmg_per_layer × 存活层数
dmg_per_layer = 0;      // 每层伤害（= custom["灼烧伤害"]），铺火时由调用方给
ash_kill      = false;  // 三转起 true：被地火烫死的真敌人化灰
life          = 120;    // 每层存活帧数（秒数 × 60），铺火时由调用方覆盖
t             = 0;
tick_interval = 24;     // 2 秒 5 跳
tick_phase    = 0;      // 错峰偏移（铺火时随机 0~interval-1），别让同一轮的十几片同帧结算
layer_t       = [0];    // 每层的加入时刻（实例自己的 t）；空数组即该格火已烧完

frame_start = 0;
frame_end   = sprite_get_number(sprite_index) - 1;
anim_loop_frames = 30;  // 贴图按 30 帧一轮循环

// ── 命中判定 ──
target_type      = "all";
damage_type      = "fire";     // 只扣血不吃盾
hittable_types   = get_hittable_enemy_types("all");
grid_col         = -1;
grid_row         = -1;
lock_grid        = true;
extra_col_right  = 0;

// ── 老鼠身上的着火特效（复用 obj_bbq_mouse_burn 跟随器）──
shape          = 0;
mouse_fx_spr   = -1;   // -1 = 按 shape 自动选 spr_houyi_god_fire / _1 / _2 / _3
mouse_fx_scale = 1.8;
mouse_fx_x_off = 0;
mouse_fx_y_off = 50;
mouse_fx_life  = 28;   // 比一跳（24 帧）多 4 帧，接得上又不会叠成一片

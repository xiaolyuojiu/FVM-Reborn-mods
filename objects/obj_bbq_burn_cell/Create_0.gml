// obj_bbq_burn_cell（bbq 专用单格灼烧）Create 事件
// 只给 bbq 用：面包 5x5 灼烧 / 天蝎走公用的 obj_burn_cell，两边互不影响。
// 调用方传 sprite_index / frame_start / frame_end / damage / life / extra_col_right
//   （bbq：spr_bbq_burn_ground 的 3~16 帧、时长与跳数由 custom["灼烧持续"]/["灼烧跳数"] 算，每跳 = 卡片 atk，
//     2026-11-24 起 bbq 不再放宽 extra_col_right（只烧本格））。
// 判定口径：
//   ① single_hit = true → 整个持续时间内每帧扫，格内**每只敌人只吃一次** damage（进 burned 名单）；
//   ② single_hit = false（默认）→ 每 tick_interval 帧结算一跳（烤肉 30 帧一跳），每跳都结算。
//   命中只认「列在本格 ~ 本格+extra_col_right、行严格相等」的敌人（不做 bbox 兜底 ——
//   老鼠贴图很高，相邻行老鼠的头顶会探进本格，用 bbox 会连带烧上下行）；
//   命中类型由调用方给（bbq = 地面单位全烧，空军 / 钻地不烧）；同格叠层合并成 1 个实例（layer_t 记层数）。
//   击杀一律出灰烬（obj_mouse_ash_death）。
image_speed = 0;
image_index = 0;
image_angle = 0;
image_alpha = 1;
image_blend = c_white;
image_xscale = 1;
image_yscale = 1;

damage = 0;              // 实际结算值：Step 里 = dmg_per_layer × 存活层数
dmg_per_layer = 0;       // 每层伤害，铺火时由调用方给
life = 30;               // 每层存活帧数
t = 0;
tick_interval = 6;
tick_phase = 0;          // 错峰偏移（铺火时随机 0~interval-1）
layer_t = [0];           // 每层的加入时刻；2026-11-24 同格合并，空数组即火灭
frame_start = 0;
frame_end = sprite_get_number(sprite_index) - 1;
// 0 = 老行为（整段帧均匀铺满 life）；> 0 = 按这个帧数循环播（烤肉 2 秒火照样 1 秒一轮，不会放成慢动作）
anim_loop_frames = 0;

target_type = "all";
damage_type = "fire";
hittable_types = ["normal", "invisible"];   // 表 r136：只烧陆地老鼠，空军不吃

grid_col = -1;
grid_row = -1;
// 2026-10-31：调用方可直接锁死格子坐标（放在格子底边时反算会被算成下一行），
//   可选「每只只吃一次」的结算口径，以及给被烧到的鼠挂一只身上燃烧特效
lock_grid = false;
// 额外能烧到本格右边几格（默认 0 = 只烧本格）。
//   2026-11-24 用户口径：bbq 也不再放宽，火格只在第 9 格内烧，不烧场外第 10 列。
extra_col_right = 0;
single_hit = false;
mouse_fx_spr = -1;
burned = ds_list_create();

// obj_ronghehuopen_cold（融合火盆·寒气场）Create 事件
// 纯表现对象：一格一片，跟着寒气场存在 life 帧（默认 480 = 8 秒），生命期内按秒循环播 19 帧寒气动画，
// 末尾 fade_frames 帧整体淡出。伤害与减速由 obj_ronghehuopen/Step_0 结算，这里不碰敌人。
image_speed = 0
timer = 0
life = 480          // 存活帧数（默认 8 秒 = 8 跳 × 1 秒）；生成方按 cold_dmg_tick × cold_tick_sec × 60 覆盖
fade_frames = 30    // 末尾淡出的帧数
image_index = 0
image_alpha = 1

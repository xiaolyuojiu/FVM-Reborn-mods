image_xscale = 1.8;
image_yscale = 1.8;
image_speed = 0.3;
sprite_index = spr_durian_effect;

// 毒气瘟疫：第 0 / 1.7 / 2.9 秒各一跳（帧间隔 0 / 102 / 72），三跳同一伤害
tick_damage = 0;
tick_delays = [0, 102, 72];
tick_timer = 0;
tick_index = 0;
max_ticks = 3;

grid_row = 0;
grid_col = 0;
shape = 0;
target_type = "all";

has_plague = false;
plague_bonus = 0;
plague_left = 3;
plague_interval = 60;
plague_timer = 0;

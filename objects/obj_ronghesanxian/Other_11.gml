// 融合三线 · 开火：一次齐射 = 向前方三行各发射 1 发葡萄酒弹（本行 / 上一行 / 下一行）
//   一轮攻击按 shots_per_row 齐射 2 / 3 / 1 次（灵魂融合压缩成 1 发）
// 出弹口沿用基础卡 obj_triple_wine_rack 的写法：三行子弹从同一 y 出生，再各自 lerp 到目标行
var middle_y = y - 75;

var _pierce_left = (shape >= 2) ? pierce_count : 0;

// 本行
var inst_middle = instance_create_depth(x + 40, middle_y, depth - 500, obj_ronghesanxian_bullet);
inst_middle.damage = atk;
inst_middle.move_speed = 8;
inst_middle.row = grid_row;
inst_middle.target_row = grid_row;
inst_middle.burn_damage = burn_damage;
inst_middle.burn_chance = burn_chance;
inst_middle.pierce_left = _pierce_left;

// 上一行
var inst_up = instance_create_depth(x + 40, middle_y, depth - 500, obj_ronghesanxian_bullet);
inst_up.damage = atk;
inst_up.move_speed = 8;
inst_up.row = grid_row;
inst_up.start_y = middle_y;
inst_up.burn_damage = burn_damage;
inst_up.burn_chance = burn_chance;
inst_up.pierce_left = _pierce_left;
if grid_row - 1 >= 0{
	inst_up.target_row = grid_row - 1;
}
else{
	inst_up.target_row = grid_row;
	inst_up.x -= 20;
}

// 下一行
var inst_down = instance_create_depth(x + 40, middle_y, depth - 500, obj_ronghesanxian_bullet);
inst_down.damage = atk;
inst_down.move_speed = 8;
inst_down.row = grid_row;
inst_down.start_y = middle_y;
inst_down.burn_damage = burn_damage;
inst_down.burn_chance = burn_chance;
inst_down.pierce_left = _pierce_left;
if grid_row + 1 < global.grid_rows{
	inst_down.target_row = grid_row + 1;
}
else{
	inst_down.target_row = grid_row;
	inst_down.x -= 20;
}

audio_play_sound(snd_shot, 0, 0);

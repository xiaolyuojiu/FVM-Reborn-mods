// 注册到全局敌人表（本对象有自己的 Step，父对象的注册逻辑不会执行，需在此补注册，
// 否则不会进入 global.enemy_by_type / enemy_sx 空间索引，走新命中系统的子弹永远打不到它）
// 注意：这几只敌人的 Step 里可能有 `var target_type`（同名局部变量会让整个事件里的
//   target_type 都按局部解析），所以这里统一用 variable_instance_get 读实例字段。
var _rb_tt = variable_instance_get(id, "target_type");
if (is_undefined(_rb_tt)) _rb_tt = "normal";
var _rb_on = variable_instance_get(id, "enemy_registered");
var _rb_old = variable_instance_get(id, "enemy_registered_type");
if (!_rb_on || _rb_old != _rb_tt) {
	if (_rb_on && variable_global_exists("enemy_by_type") && variable_struct_exists(global.enemy_by_type, _rb_old)) {
		var _rb_list = global.enemy_by_type[$ _rb_old];
		var _rb_idx = array_get_index(_rb_list, id);
		if (_rb_idx != -1) array_delete(_rb_list, _rb_idx, 1);
	}
	if (!variable_global_exists("enemy_by_type")) {
		global.enemy_by_type = {};
	}
	if (!variable_struct_exists(global.enemy_by_type, _rb_tt)) {
		global.enemy_by_type[$ _rb_tt] = [];
	}
	array_push(global.enemy_by_type[$ _rb_tt], id);
	enemy_registered = true;
	enemy_registered_type = _rb_tt;
}

if global.is_paused{
	exit
}

var grid_pos = get_grid_position_from_world(x,y)

var zombie_grid = get_grid_position_from_world(x, y);

// 更新僵尸的网格位置和深度

var base_depth = -10 - (zombie_grid.row * 45) - (9 * 5);
depth = base_depth ; // 僵尸比植物稍微靠后一点（在护罩外侧和咖啡豆之间）

// 保持网格位置更新

grid_col = zombie_grid.col;
grid_row = zombie_grid.row;



if flash_value > 0{
	flash_value -= 10
}

timer++

if state == "appear"{
	image_index = floor(timer/5) mod 4
	x -= 1
	var has_card = false
	with obj_card_parent{
		if plant_id != "player" && plant_id != "cotton_candy" && plant_type != "coffee" && grid_row == other.grid_row && grid_col == other.grid_col{
			instance_destroy()
			if hp >= max_hp{
				obj_task_manager.card_loss++
			}
			has_card = true
			other.target_col = grid_col + 1
		}
	}
	if grid_col == target_col - 1 || has_card{
		timer = 0
		state = "anim"
		sprite_index = spr_cactus_mouse_bullet
		var new_pos = get_world_position_from_grid(target_col-1,grid_row)
		x = new_pos.x
		y = new_pos.y + 15
	}
}
else if state == "anim"{
	clear_timer ++
	image_index = floor(timer/5) mod 12
	if global.grid_terrains[grid_pos.row][grid_pos.col].type != "obstacle"{
		current_grid_type = global.grid_terrains[grid_pos.row][grid_pos.col].type
		global.grid_terrains[grid_pos.row][grid_pos.col].type = "obstacle"
	}
	if clear_timer >= 40*60{
		hp = 0 
	}
}
else if state == "death"{
	image_index = 0
	if timer >= 1{
		image_alpha -= 0.1
	}
}

if hp <= 0 && state != "death"{
	state = "death"
	timer = 0
}

if image_alpha <= 0 && hp <= 0{
	instance_destroy()
}



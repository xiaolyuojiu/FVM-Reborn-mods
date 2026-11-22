// obj_small_furnace 的 Create 事件
//plant_id = "small_fire";  // 唯一标识符
event_inherited();  // 继承父对象属性
plant_id = "fruit_tart"; 
// 设置对象类型和精灵

event_user(0)
sprite_index = spr_fruit_tart;
if shape == 1{
	sprite_index = spr_fruit_tart_1
}
else if shape == 2{
	sprite_index = spr_fruit_tart_2
}
// ========== 特定属性默认值 ==========
attack_anim = 26;
idle_anim = 14
flash_speed = 5
plant_type = "normal"
is_slowdown = false

card_id_list = ["egg_boiler_pult"]
enhance_card_list = []
buffer_type = "thrower";
// 增幅范围交给 scripts/fruit_tart_buff 铺格子（零转本行左侧 / 一转整行 / 二转三行）；
// 倍率取**注册表 atk**（1.5~3.0 本身就是倍率），不读实例 atk（会被地形 / 宝石 / 海克斯乘大）
buff_value = fruit_tart_mult(shape, current_level,
    variable_instance_exists(id, "skill") ? skill : 0, atk);
buff_cells = fruit_tart_build_cells(grid_col, grid_row, shape, buff_value);
// 留给 Step_0 第一帧登记到 global.buff_sources（登记与铺格子都在那边做，和极光同构）
buff_cells_refreshed = false;
// 位置/形态变化时重铺用（倍率已不再跟 atk 走，改成盯这三个值）
ft_last_col   = grid_col;
ft_last_row   = grid_row;
ft_last_shape = shape;

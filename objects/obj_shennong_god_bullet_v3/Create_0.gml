// 右上角追加弹：7.5 / 8.5 两列的竖向朱雀，从 0 行上方落下。
// 生成方（obj_shennong_god/Step_0.gml）会给每发弹指定 col_left 与 col_hits：
//   0~2 转 → 7.5 列那只盖第 7、8 列，8.5 列那只盖第 8、9 列 → 7/8/9 列挨 1/2/1 次；
//   终转    → 两只都盖第 7、8、9 三列 → 三列各挨 2 次。
// 每次命中都是全额伤害，中间列多吃的那次来自两只弹自然叠加。
// 该弹纵向飞行跨行，不维护 grid_row，命中只按「敌人所在列」判定。

damage = 0;
move_speed = 0;
damage_type = "pierce";
target_type = "land_air_ug";   // 生成方会按形态覆盖
shape = 3;                     // 生成方（obj_shennong_god/Step_0）按释放者形态覆盖；魂系 2 倍据此判「三转起」
ash_kill = true;

// 同一只敌人可能被同一发弹命中多次，所以用 ds_map 记「该敌人已吃了几次」，
// 而不是 ds_list 去重。
hit_counts = ds_map_create();

hittable_types = get_hittable_enemy_types(target_type);
hit_tick = 0;

// 覆盖的起始列（0 基）与逐列受击次数上限。
col_left = 6;
col_hits = [1, 1];

// 行不作约束；row 给个合法值，兼容父对象字段。
row = 0;

image_xscale = 1.5;
image_yscale = 1.5;
image_angle = -90;   // sprite 朝右，转 -90° 变朝下
// 对象池复用复位：不写这几项，回收后的实例会带着上一次的帧号 / 透明度出生
image_speed = 1;
image_index = 0;
image_alpha = 1;
image_blend = c_white;

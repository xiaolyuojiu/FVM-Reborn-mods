// ========== 炎帝：发射水平轨迹子弹 ==========
// 基础（shape 0/1/2）：固定 2 只朱雀，夹在相邻两行之间飞，覆盖 3 行、受击 1/2/1
// （放卡 ≥7 加的是右上角「竖向轨迹」，不是多一只横排）
//
// 终转（shape 3）：
//   · 还是 2 只朱雀，从左往右飞出、到边界消失（我方不折返）
//   · 分别飞 上行 / 下行（行内），单只伤害范围 = 自己那行 ±1（3 行），每行 1 次全额
//   · 两只叠起来覆盖 5 行，受击 1 / 1 / 2 / 1 / 1 次

var col0_x = get_world_position_from_grid(0, 0).x;
var grid_cell_y = global.grid_cell_size_y;
var middle_y_offset = 30; // 子弹y偏移

// ==================== 终转（shape 3） ====================
// 还是 2 只朱雀（数据表 / 米苏只写「朱雀伤害范围扩大到 3 行」，没有加数量）。
// 两只分别飞 上行 / 下行（行内，不夹在行间），每只伤害范围 = 自己那行 ±1（3 行）、每行 1 次全额，
// 于是合计覆盖 5 行、受击 1 / 1 / 2 / 1 / 1（中间行被两只同时覆盖 = 2 次）。
if (shape == 3)
{
    var _rows_n = global.grid_rows;
    var _r      = grid_row;

    var _fly_off = [-1, 1];   // 上行 / 下行
    // 边路补偿：越界的那只压回**本行**（夹到 0 / 末行），于是贴边时组合变成「本行 + 下行」或「上行 + 本行」，
    // 本行因此吃 2 次、紧邻那行 2 次、再往外 1 次（例：站第 1 行 → 2 / 2 / 1）。

    for (var _i = 0; _i < 2; _i++)
    {
        var _fly_row = clamp(_r + _fly_off[_i], 0, _rows_n - 1);
        var _row_y   = global.grid_offset_y + grid_cell_y * _fly_row + middle_y_offset;

        // 逐行受击次数：这只鸟只打自己那行 ±1，各 1 次（行门禁交给 row_hits）
        var _row_hits = array_create(_rows_n, 0);
        for (var _ri = max(0, _fly_row - 1); _ri <= min(_rows_n - 1, _fly_row + 1); _ri++)
        {
            _row_hits[_ri] = 1;
        }

        var _inst = instance_create_depth(col0_x - 40, _row_y, depth - 500, obj_shennong_god_bullet_h);
        _inst.damage = atk;
        _inst.move_speed = 6;
        _inst.row = _fly_row;
        _inst.target_row = _fly_row;
        _inst.shape = 3;
        _inst.ash_kill = true;
        if (shape >= 2) {
            _inst.target_type = "land_air_ug";   // 四转起：陆 + 空 + 地（不含潜水 / 非主流 / 幽灵）
            // 名单统一走类型（`land_air_ug` 含 obstacle）：障碍不索敌，扫到仍掉血
            _inst.hittable_types = get_hittable_enemy_types("land_air_ug");
        } else {
            _inst.target_type = "normal";
            _inst.hittable_types = get_hittable_enemy_types("normal");
        }
        _inst.row_hits = _row_hits;

        _inst.sprite_index = spr_shennong_god_bullet_3;
        _inst.image_xscale = 1.5;
        _inst.image_yscale = 1.5;
        _inst.image_angle = 0;   // 两只都从左往右飞，与 0~2 转同向
    }

    audio_play_sound(snd_shot, 0, 0);
    exit;
}

// ==================== shape 0 / 1 / 2 ====================

// 形态强度全部由 atk 表表达（三转 ×1.3 / 终转 ×1.6，四转沿用三转）——
//   2026-11-21 起不再在代码里另乘 dmg_mul，避免「表 ×1.3 再 ×1.3 = 1.69」的双算。
var ash_kill = true; // 击杀产生灰烬

// 2026-11-17 用户口径：子弹要像炎凰马那样夹在**两行之间**，每发同时打中上下两行，
//   而不是落在单行正中只打本行（旧版实测三行受击 1/1/0）。
//   缝隙 g = 第 g-1 行与第 g 行之间；炎帝在第 R 行时：
//     2 发 → 缝隙 R、R+1         → 覆盖 R-1 / R / R+1，受击 1 / 2 / 1
//     3 发（场上 >7 只）→ 追加缝隙 R+2 → 覆盖到 R+2，受击 1 / 2 / 2 / 1
//   缝隙夹到 [1, rows-1]：贴边越界时两条缝隙会重合 → 该两行各吃两次，
//   与旧版「越界改中路」的重叠语义一致，不会凭空多打一行。
var _gap_max = max(1, global.grid_rows - 1);
var bullet_gaps = [];
bullet_gaps[0] = clamp(grid_row,     1, _gap_max);
bullet_gaps[1] = clamp(grid_row + 1, 1, _gap_max);

for (var i = 0; i < array_length(bullet_gaps); i++)
{
    var gap = bullet_gaps[i];

    var start_x = col0_x - 40;
    // 缝隙重合（贴边）时把后面的几发错开，否则两张贴图完全叠在一起看不出是多发
    var _dup = 0;
    for (var _d = 0; _d < i; _d++) if (bullet_gaps[_d] == gap) _dup++;
    if (_dup > 0) start_x -= 40 * _dup;

    // 与炎凰马同一条公式：缝隙 g 的视觉中心 = 第 g 行上移 0.25 格（夹在 g-1 / g 之间）
    var start_y = global.grid_offset_y + (gap - 0.25) * grid_cell_y;

    var inst = instance_create_depth(start_x, start_y, depth - 500, obj_shennong_god_bullet_h);
    inst.damage = atk;   // 伤害只认 atk 表（不再乘 dmg_mul）
    inst.move_speed = 6;
    inst.row = gap - 1;
    inst.target_row = gap - 1;
    inst.cover_a = gap - 1;   // 缝隙制：上下两行都吃这一发
    inst.cover_b = gap;
    inst.shape = shape;
    inst.ash_kill = ash_kill;
    if (shape >= 2) {
        inst.target_type = "land_air_ug";   // 四转起：陆 + 空 + 地（不含潜水 / 非主流 / 幽灵）
        // 名单统一走类型（2026-11-21 起 `land_air_ug` 含 obstacle）：障碍不索敌，扫到仍掉血
        inst.hittable_types = get_hittable_enemy_types("land_air_ug");
    } else {
        inst.target_type = "normal";
        inst.hittable_types = get_hittable_enemy_types("normal");
    }

    // 设置子弹精灵
    if (shape == 0)
        inst.sprite_index = spr_shennong_god_bullet;
    else if (shape == 1)
        inst.sprite_index = spr_shennong_god_bullet_1;
    else
        inst.sprite_index = spr_shennong_god_bullet_2;
}

audio_play_sound(snd_shot, 0, 0);

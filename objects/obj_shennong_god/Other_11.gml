// ========== 炎帝：发射水平轨迹子弹 ==========
// 数据表 11.直射 r95：两只朱雀从场地**左右两边对向飞出**，攻击沿途上中下 3 行陆军（四转追加空、地），
//   中路受击 4 次、上下路受击 2 次。原版是「飞到对边再原路折返」，这里用**每张卡 4 发单程弹**
//   等效（左右各 2 发、两条缝隙各一，与炎凰马同一套口径：不吃折返的存活时长，四发同帧出）。
//   0/1/2 转：两条缝隙各一发（每发覆盖上下两行），左右各一份 → 上中下 3 行、受击 2 / 4 / 2
//   终转(shape 3)：两发贴「上行 / 下行」的缝隙，各自半径 1.5 格（覆盖 3 行）→ 合计 5 行、2 / 2 / 4 / 2 / 2
//   🔴 atk 直接用数据表的值（2026-11-24：子弹 2 发 → 4 发，取消原来为了让 2 发凑够总量而做的 ×2 压缩）
//   放卡 ≥7 的竖向朱雀不在这里（见 obj_shennong_god/Step_0 的 7 只判定，走 obj_shennong_god_bullet_v）

var grid_cell_y = global.grid_cell_size_y;
var _rows_n     = global.grid_rows;
var _gap_max    = max(1, _rows_n - 1);

// 出弹口贴战斗域边界（同炎凰马）：右端算上第 10 列，站在场外那一列的老鼠也扫得到
var _side_x   = [combat_left_x() - 20, combat_right_x() + 20];
var _side_dir = [1, -1];

// 形态强度全部由 atk 表表达（二转 ×1.3 / 终转 ×1.6），代码里不再另乘倍率
var _tt = (shape >= 2) ? "land_air_ug" : "normal";   // 四转起：陆 + 空 + 地（不含潜水 / 非主流 / 幽灵）

// ── 本轮的两条飞行线：0/1/2 转 = 缝隙 R / R+1；终转 = 上行 / 下行各自贴着的缝隙 ──
//   缝隙 g 的视觉中心 = 第 g 行上移 0.25 格（夹在 g-1 / g 之间，同炎凰马）
//   终转的两条线关于本行左右对称：上行贴缝隙 R 上侧、下行贴缝隙 R+1 下侧
var _lanes = [];
if (shape == 3)
{
    var _lane_row = [clamp(grid_row - 1, 0, _rows_n - 1), clamp(grid_row + 1, 0, _rows_n - 1)];
    var _lane_y   = [global.grid_offset_y + (clamp(grid_row,     1, _gap_max) - 0.25) * grid_cell_y,
                     global.grid_offset_y + (clamp(grid_row + 1, 1, _gap_max) + 0.25) * grid_cell_y];
    for (var _l3 = 0; _l3 < 2; _l3++)
    {
        // 逐行受击次数：这只鸟只打自己那行 ±1，各 1 次（行门禁交给 row_hits）
        var _row_hits = array_create(_rows_n, 0);
        for (var _ri = max(0, _lane_row[_l3] - 1); _ri <= min(_rows_n - 1, _lane_row[_l3] + 1); _ri++)
        {
            _row_hits[_ri] = 1;
        }
        array_push(_lanes, { y: _lane_y[_l3], row: _lane_row[_l3], row_hits: _row_hits, cover_a: -1, cover_b: -1 });
    }
}
else
{
    var _gaps = [clamp(grid_row, 1, _gap_max), clamp(grid_row + 1, 1, _gap_max)];
    for (var _l0 = 0; _l0 < 2; _l0++)
    {
        array_push(_lanes, {
            y: global.grid_offset_y + (_gaps[_l0] - 0.25) * grid_cell_y,
            row: _gaps[_l0] - 1,
            row_hits: [],
            cover_a: _gaps[_l0] - 1,   // 缝隙制：上下两行都吃这一发
            cover_b: _gaps[_l0]
        });
    }
}

// ── 每条飞行线左右各一发 ──
// 朝向 + 缩放四项全部显式写死：对象池复用时不会重置 visual_scale_x，
//   漏写会让左向那发继承上一发的镜像、被画成「倒着飞」（炎凰马踩过这个坑）
for (var _l = 0; _l < array_length(_lanes); _l++)
{
    var _ln = _lanes[_l];
    for (var _s = 0; _s < 2; _s++)
    {
        var inst = instance_create_depth(_side_x[_s], _ln.y, depth - 500, obj_shennong_god_bullet_h);
        inst.damage = atk;   // 伤害只认 atk 表（不再乘 dmg_mul）
        // 🔴 方向只由 dir 带（Step 里是 x += move_speed * dir）：move_speed 恒为正，
        //   两边都乘一次方向会让右端那发「负负得正」往右飞、立刻撞出销毁线
        inst.move_speed = 6;
        inst.dir = _side_dir[_s];
        inst.shape = shape;
        inst.row = _ln.row;
        inst.target_row = _ln.row;
        inst.row_hits = _ln.row_hits;
        inst.cover_a = _ln.cover_a;
        inst.cover_b = _ln.cover_b;
        inst.ash_kill = true;
        inst.target_type = _tt;
        inst.hittable_types = get_hittable_enemy_types(_tt);
        inst.image_angle = 0;
        inst.image_yscale = 1.5;
        inst.image_xscale = 1.5 * _side_dir[_s];
        inst.visual_scale_x = 1.5 * _side_dir[_s];
        inst.visual_scale_y = 1.5;
        if (shape == 3) inst.sprite_index = spr_shennong_god_bullet_3;
        else if (shape == 0) inst.sprite_index = spr_shennong_god_bullet;
        else if (shape == 1) inst.sprite_index = spr_shennong_god_bullet_1;
        else inst.sprite_index = spr_shennong_god_bullet_2;
    }
}

audio_play_sound(snd_shot, 0, 0);

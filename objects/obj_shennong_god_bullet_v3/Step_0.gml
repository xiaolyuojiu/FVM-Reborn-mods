if (global.is_paused)
{
    image_speed = 0;
    exit;
}

// 召唤出来的朱雀算一次完整攻击动作：帧序列只播一遍，播完停在最后一帧（不循环乱扇）
if (image_index >= image_number - 1)
{
    image_index = image_number - 1;
    image_speed = 0;
}
else
{
    image_speed = 1;
}

y += move_speed;

// 从 0 行上方飞入，落到场地底边以下即销毁。
var _floor_y = global.grid_offset_y + global.grid_rows * global.grid_cell_size_y + 200;

if (y > _floor_y)
{
    if (ds_exists(hit_counts, ds_type_map))
        ds_map_destroy(hit_counts);
    instance_destroy();
    exit;
}

hit_tick++;
if (hit_tick < global.bullet_hit_interval)
    exit;

hit_tick = 0;

if (!bullet_enemy_reachable(id))
    exit;

if (!variable_global_exists("enemy_by_type"))
    exit;

var _col_max = array_length(col_hits);

for (var _t = 0; _t < array_length(hittable_types); _t++)
{
    var _key = hittable_types[_t];
    if (!variable_struct_exists(global.enemy_by_type, _key)) continue;

    var _list = bullet_sap_type_list(id, _key);

    for (var _i = 0; _i < array_length(_list); _i++)
    {
        var _e = _list[_i];
        if (!instance_exists(_e)) continue;
        if (_e.hp <= 0) continue;

        // 列判定：只打 7~9 列（0 基 6~8）
        var _ci = _e.grid_col - col_left;
        if (_ci < 0 || _ci >= _col_max) continue;

        var _allow = col_hits[_ci];
        if (_allow <= 0) continue;

        var _done = hit_counts[? _e.id];
        if (_done == undefined) _done = 0;
        if (_done >= _allow) continue;

        // 横向：由上面的列覆盖（col_left / col_hits）决定，**不再用贴图 bbox** ——
        //   精灵转 -90° 后横向只剩约 100×1.5 = 150px 宽，撑不到「1.5 列」半径，
        //   实测就是 7.5 那只打不到 9 列、8.5 那只打不到 7 列。
        // 纵向：鸟掠到这只老鼠所在行附近才算命中（否则一出生就把整列全结算掉）。
        if (abs(_e.y - y) > global.grid_cell_size_y) continue;

        // 每次命中都是全额（中间第 8 列吃两次 = 两倍，不做半额折算）
        // 魂系 2 倍：与横排朱雀同口径 —— **三转起**（数据表 11.直射 r84「三转魂系老鼠2倍伤」），
        //   0 转 / 一转 / 二转按普通伤害走，连「无视魂体减伤」也不给（来源标记一并清空）。
        //   🔴 形态由生成方 obj_shennong_god/Step_0 传入（这个对象以前把 shape 写死成 3，
        //      导致 0 转召出来的竖向朱雀也在吃 2 倍 + 无视减伤）。
        var _soul_ok = (shape >= 1);
        var _base = damage;
        var _dmg = (_soul_ok && longyuan_is_soul_bonus_target(_e))
                   ? floor(_base * longyuan_soul_bonus_mult(obj_shennong_god))
                   : _base;

        with (_e)
        {
            audio_play_sound(hit_sound, 0, 0);
            damage_amount = _dmg;
            damage_type = other.damage_type;
            damage_source_object = _soul_ok ? obj_shennong_god : noone;
            damage_source_card_id = _soul_ok ? "shennong_god" : "";
            event_user(0);
            // 击杀化灰：先让本体隐去（ash_death + image_alpha = 0）再放灰烬，
            //   否则死亡动画和灰烬会同时出现，与横排朱雀 / 金刚马同款。
            if (other.ash_kill && hp <= 0)
            {
                ash_death   = true;
                image_alpha = 0;
                instance_create_depth(x, y - 20, depth, obj_mouse_ash_death);
            }
            damage_source_card_id = "";
        }

        hit_counts[? _e.id] = _done + 1;
    }
}

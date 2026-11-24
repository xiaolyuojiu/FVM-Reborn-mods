// obj_burn_cell Step 事件
if (global.is_paused) exit;

// 格子坐标：调用方锁死就用它的（bbq 传第 9 格）；否则按自身坐标反算（蛋糕那一路）
if (!lock_grid)
{
    var _gp = get_grid_position_from_world(x, y);
    grid_col = _gp.col;
    grid_row = _gp.row;
}

t++;

// ── 叠层记账（2026-11-24 性能）：同格合并成 1 个实例，层数记在 layer_t，每层各自 life 帧后过期 ──
//   跳伤 = 每层伤害 × 存活层数；原来是「一层一个实例」，同格最多 4 个实例各自结算
if (dmg_per_layer <= 0) dmg_per_layer = damage;
for (var _li = array_length(layer_t) - 1; _li >= 0; _li--)
{
    if (t - layer_t[_li] >= life) array_delete(layer_t, _li, 1);
}
if (array_length(layer_t) <= 0)
{
    if (ds_exists(burned, ds_type_list)) ds_list_destroy(burned);
    instance_destroy();
    exit;
}
damage = dmg_per_layer * array_length(layer_t);

// 帧推进：把 frame_start~frame_end 铺到 life 帧上；anim_loop_frames > 0 时按它循环
if (life > 1)
{
    var _span = frame_end - frame_start + 1;
    var _cycle = (anim_loop_frames > 0) ? anim_loop_frames : life;
    image_index = frame_start + floor((t mod _cycle) / _cycle * _span);
    if (image_index > frame_end) image_index = frame_end;
}

// 是否这一帧要结算
var _do_hit = false;
if (single_hit)
{
    // 老口径：整个持续时间内每帧都扫，谁在格子里就烧谁（每只只烧一次，靠 burned 名单记）
    _do_hit = true;
}
else
{
    // 跳伤口径：每 tick_interval 帧一跳，起步按 tick_phase 错峰
    _do_hit = (t > tick_phase && ((t - 1 - tick_phase) mod tick_interval) == 0);
}

if (_do_hit && variable_global_exists("enemy_by_type"))
{
    for (var _t = 0; _t < array_length(hittable_types); _t++)
    {
        var _key = hittable_types[_t];
        if (!variable_struct_exists(global.enemy_by_type, _key)) continue;
        var _list = global.enemy_by_type[$ _key];
        for (var _i = 0; _i < array_length(_list); _i++)
        {
            var _e = _list[_i];
            if (!instance_exists(_e) || _e.hp <= 0) continue;
            if (is_digging_dijing(_e)) continue;                       // 龙渊地精钻地时不烧

            // 只烧「就是这一格」的敌人：列、行都严格相等。
            //   不能再用 bbox 兜底 —— 老鼠贴图很高，下一行老鼠的头顶会探进上一行的格子里，
            //   用 bbox 判会连带把上下行的老鼠一起烧了（2026-10-31 用户反馈）。
            // 2026-11-06：extra_col_right > 0 时，右边紧邻的 extra_col_right 格**也算命中**
            //   （bbq = 1：火格在第 9 格，能烧到第 10 格 / BOSS 出生位；行必须仍然是本行）。
            if (_e.grid_row != grid_row) continue;
            if (_e.grid_col < grid_col || _e.grid_col > grid_col + extra_col_right) continue;

            if (single_hit)
            {
                if (ds_list_find_index(burned, _e.id) != -1) continue; // 同一只只吃一次
                ds_list_add(burned, _e.id);
            }

            // 身上挂辣椒燃烧特效（跟着这只鼠烧）
            //   2026-11-24 性能：同一只鼠身上只留 1 个 —— 叠层时原来是每层各建一个
            if (mouse_fx_spr != -1
                && !(variable_instance_exists(_e, "bbq_fx_inst") && instance_exists(_e.bbq_fx_inst)))
            {
                var _fx = instance_create_depth(_e.x, _e.y, _e.depth - 1, obj_bbq_mouse_burn);
                _fx.fx_spr = mouse_fx_spr;
                _fx.target = _e;
                _fx.life = 30;
                _e.bbq_fx_inst = _fx;
            }

            with (_e)
            {
                if (object_index == obj_enemy_parent || object_is_ancestor(object_index, obj_enemy_parent))
                {
                    // 走敌人自己的受伤流程（Other_10）：扣血 / 护盾 / 海克斯倍率 /
                    //   **测试关的 global.test_damage_total_all 累计都在这条路上**
                    damage_amount = other.damage;
                    damage_type = other.damage_type;
                    event_user(0);
                }
                else
                {
                    // 障碍物（obj_barrier / obj_ly_mengpo_mushroom 之类）没有 Other_10，直接扣
                    hp -= other.damage;
                }

                if (hp <= 0)
                {
                    // 烧死一律出灰烬
                    if (special_ash)
                    {
                        var _ash = instance_create_depth(x, y - 20, depth, obj_mouse_ash_death);
                        _ash.special_ash = true;
                        _ash.sprite_index = sprite_index;
                        _ash.image_index = image_index;
                    }
                    else
                    {
                        instance_create_depth(x, y - 20, depth, obj_mouse_ash_death);
                    }
                    instance_destroy();
                }
            }
        }
    }
}

// 层数归零时已在上面销毁（火灭即消失）

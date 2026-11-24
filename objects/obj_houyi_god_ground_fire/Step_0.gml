// obj_houyi_god_ground_fire（后羿 · 地火格）Step 事件
// 每 tick_interval 帧结算一跳（起步按 tick_phase 错峰），格内每只敌人每跳都吃 damage；
// 同格合并成 1 个实例，层数记在 layer_t（每层各自 life 帧后过期），跳伤 = 每层伤害 × 存活层数。
// 三转起（ash_kill = true）被地火烫死的真敌人化灰；0/1 转不冒灰烬（表 r137 只给三转起）。
if (global.is_paused) exit;

t++;

// ── 叠层记账：每层各自 life 帧后过期，层数 = 还活着的 layer_t ──
//   同格只有 1 个实例（铺火侧合并），跳伤按存活层数相乘，和「一层一个实例」的总伤等价
if (dmg_per_layer <= 0) dmg_per_layer = damage;
for (var _li = array_length(layer_t) - 1; _li >= 0; _li--)
{
    if (t - layer_t[_li] >= life) array_delete(layer_t, _li, 1);
}
if (array_length(layer_t) <= 0)
{
    instance_destroy();
    exit;
}
damage = dmg_per_layer * array_length(layer_t);

// 帧推进：frame_start~frame_end 铺到 anim_loop_frames 帧上一轮循环
if (life > 1)
{
    var _span  = frame_end - frame_start + 1;
    var _cycle = (anim_loop_frames > 0) ? anim_loop_frames : life;
    image_index = frame_start + floor((t mod _cycle) / _cycle * _span);
    if (image_index > frame_end) image_index = frame_end;
}

if (t > tick_phase && ((t - 1 - tick_phase) mod tick_interval) == 0 && variable_global_exists("enemy_by_type"))
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
            if (is_digging_dijing(_e)) continue;                  // 龙渊地精钻地时不烧

            // 只烧「就是这一格」：行严格相等，列在本格 ~ 本格+extra_col_right
            if (_e.grid_row != grid_row) continue;
            if (_e.grid_col < grid_col || _e.grid_col > grid_col + extra_col_right) continue;

            // 身上挂着火特效（跟着这只鼠走，life 帧后自己消失）
            //   2026-11-24 性能：同一只鼠身上只留 1 个 —— 上一跳的还没消失就跳过。
            //   life（跳间隔 + 4 帧）比跳间隔长，原来每跳都建 → 同一只鼠身上会叠 2 个甚至更多
            if (!(variable_instance_exists(_e, "houyi_fx_inst") && instance_exists(_e.houyi_fx_inst)))
            {
                var _fx_spr = mouse_fx_spr;
                if (_fx_spr == -1)
                {
                    _fx_spr = spr_houyi_god_fire;
                    if (shape == 1)      _fx_spr = spr_houyi_god_fire_1;
                    else if (shape == 2) _fx_spr = spr_houyi_god_fire_2;
                    else if (shape == 3) _fx_spr = spr_houyi_god_fire_3;
                }
                var _fx = instance_create_depth(_e.x, _e.y, _e.depth - 1, obj_bbq_mouse_burn);
                _fx.fx_spr       = _fx_spr;
                _fx.target       = _e;
                _fx.life         = mouse_fx_life;
                _fx.life_total   = mouse_fx_life;
                _fx.x_off        = mouse_fx_x_off;
                _fx.y_off        = mouse_fx_y_off;
                _fx.image_xscale = mouse_fx_scale;
                _fx.image_yscale = mouse_fx_scale;
                _e.houyi_fx_inst = _fx;
            }

            with (_e)
            {
                if (object_index == obj_enemy_parent || object_is_ancestor(object_index, obj_enemy_parent))
                {
                    // 真敌人：只结算伤害，死亡交给 obj_enemy_parent 自己的流程
                    var _prev_hp = hp;
                    damage_amount = other.damage;
                    damage_type   = other.damage_type;
                    event_user(0);

                    // 三转起（ash_kill）：被地火烫死的化灰，与子弹 ash_kill 同一套写法
                    //   🔴 必须先 ash_death = true（本体跳过死亡动画 + 隐去），否则父类照常播死亡动画，
                    //      画面上就是「本体躺着 + 灰烬冒出来」两套（炎帝朱雀 / 金刚马 / 石榴爆爆冰同款坑）
                    if (other.ash_kill && _prev_hp > 0 && hp <= 0)
                    {
                        ash_death   = true;
                        image_alpha = 0;
                        if (other.shape >= 2)
                        {
                            var _ash = instance_create_depth(x, y - 20, depth, obj_mouse_ash_death);
                            _ash.special_ash  = true;
                            _ash.sprite_index = sprite_index;
                            _ash.image_index  = image_index;
                        }
                        else
                        {
                            instance_create_depth(x, y - 20, depth, obj_mouse_ash_death);
                        }
                    }
                }
                else
                {
                    // 障碍物没有死亡流程，血量归零就自己销毁
                    hp -= other.damage;
                    if (hp <= 0) instance_destroy();
                }
            }
        }
    }
}

// 层数归零时已在上面销毁（末帧火苗散掉，不再额外留尾帧）

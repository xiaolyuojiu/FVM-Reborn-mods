// obj_fashishe_poison_cell（法师蛇 · 毒雾格）Step 事件
// 每 tick_interval 帧结算一跳（起步按 tick_phase 错峰），格内每只敌人每跳都吃 damage。
// 2026-11-24：同格合并成 1 个实例，层数记在 layer_t（每层各自 life 帧后过期），
//   跳伤 = 每层毒雾伤害 × 存活层数 —— 原来是「一层一个实例」，同格最多 6 个实例各自结算。
if (global.is_paused) exit;

t++;

// ── 叠层记账：每层各自 life 帧后过期 ──
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
            if (is_digging_dijing(_e)) continue;                  // 龙渊地精钻地时不吃毒

            // 只烧「就是这一格」：行严格相等，列在本格 ~ 本格+extra_col_right
            //   （最右一格 extra_col_right = 1 → 能毒到第 10 格 / BOSS 出生位，特效仍只铺在本格）
            if (_e.grid_row != grid_row) continue;
            if (_e.grid_col < grid_col || _e.grid_col > grid_col + extra_col_right) continue;

            // 身上挂紫雾（跟着这只鼠走，life 帧后自己消失）
            //   2026-11-24 性能：同一只鼠身上只留 1 个 —— 叠层时原来是每层各建一个
            if (mouse_fx_spr != -1
                && !(variable_instance_exists(_e, "fashishe_fx_inst") && instance_exists(_e.fashishe_fx_inst)))
            {
                var _fx = instance_create_depth(_e.x, _e.y, _e.depth - 1, obj_bbq_mouse_burn);
                _fx.fx_spr    = mouse_fx_spr;
                _fx.target    = _e;
                _fx.life      = mouse_fx_life;
                _fx.life_total = mouse_fx_life;
                _fx.x_off     = mouse_fx_x_off;
                _fx.y_off     = mouse_fx_y_off;
                _fx.image_xscale = mouse_fx_scale;
                _fx.image_yscale = mouse_fx_scale;
                _e.fashishe_fx_inst = _fx;
            }

            with (_e)
            {
                if (object_index == obj_enemy_parent || object_is_ancestor(object_index, obj_enemy_parent))
                {
                    // 真敌人：只结算伤害，**死亡交给 obj_enemy_parent 自己走正常死亡流程**
                    //   （2026-11-08 用户口径：毒死不该冒灰烬。原来这里 instance_destroy + 出灰烬，
                    //    把敌人自己的死亡动画整段盖掉了）
                    damage_amount = other.damage;
                    damage_type   = other.damage_type;
                    event_user(0);
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

// 层数归零时已在上面销毁（雾散即消失）

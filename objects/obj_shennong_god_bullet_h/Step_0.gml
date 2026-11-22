if (global.is_paused)
{
    image_speed = 0;
    exit;
}

image_speed = 1;

x += move_speed;

var col0_x = get_world_position_from_grid(0, 0).x;
var col_last_x = get_world_position_from_grid(global.grid_cols - 1, 0).x;

if (x < col0_x - 100 || x > col_last_x + 100 || y > 1200 || y < -100)
{
    if (ds_exists(hitted_enemy, ds_type_list))
        ds_list_destroy(hitted_enemy);
    instance_destroy();
    exit;
}

hit_tick++;
if (hit_tick >= global.bullet_hit_interval)
{
	hit_tick = 0;
	if (bullet_enemy_reachable(id)) {
// 缝隙制（shape 0/1/2）的子弹中心落在两行交界，几何 bbox 跟哪一行都不相交 →
//   SAP 的空间裁剪必须放宽一整格，否则候选集里根本没有老鼠可判。
// 终转（shape 3，row_hits 非空）的子弹要打「自身行 ±1」共 3 行，同理必须放宽两格，
//   否则上下两行的老鼠根本进不了候选集（用户 2026-11-20 报「每颗子弹只打一行」）。
var _has_row_hits = (array_length(row_hits) > 0);
var _sap_y_margin = 0;
if (_has_row_hits) _sap_y_margin = 2 * global.grid_cell_size_y;
else if (cover_a >= 0) _sap_y_margin = global.grid_cell_size_y;
if (variable_global_exists("enemy_by_type"))
{
    for (var _t = 0; _t < array_length(hittable_types); _t++)
    {
        var _key = hittable_types[_t];
        if (!variable_struct_exists(global.enemy_by_type, _key)) continue;
        var _list = bullet_sap_type_list(id, _key, _sap_y_margin);
        for (var _i = 0; _i < array_length(_list); _i++)
        {
            var _e = _list[_i];
            if (!instance_exists(_e)) continue;

            // 命中行与伤害倍率：
            // row_hits 非空 → 终转（shape 3），按「该行受击次数」给倍率
            // cover_a >= 0 → 缝隙制（shape 0/1/2）：上下两行各吃 1 次
            // 都不是 → 旧行为（只打 row 这一行）
            var _row_mul = 0;
            if (array_length(row_hits) > 0)
            {
                var _gr = _e.grid_row;
                if (_gr >= 0 && _gr < array_length(row_hits))
                    _row_mul = row_hits[_gr];
            }
            else if (cover_a >= 0)
            {
                var _cgr = _e.grid_row;
                if (_cgr == cover_a || _cgr == cover_b) _row_mul = 1;
            }
            else if (row == _e.grid_row)
            {
                _row_mul = 1;
            }

            // 几何判定：
            //   终转（row_hits 非空）→ 只看横向覆盖；行门禁由 row_hits 负责，
            //     子弹本身只占飞行行那一行的 bbox，拿它判上下两行永远不相交。
            //   缝隙制（cover_a >= 0）→ 同理，子弹飞在两行之间，纵向必然错开。
            //   旧行为 → 原样用 bbox。
            var _geo_hit;
            if (_has_row_hits) {
                _geo_hit = (x >= _e.bbox_left - 16 && x <= _e.bbox_right + 16);
            }
            else if (cover_a >= 0) {
                _geo_hit = (abs(_e.x - x) <= 26);
            }
            else {
                _geo_hit = precise_bbox_collision(id, _e);
            }

            if (ds_list_find_index(hitted_enemy, _e.id) == -1
                && _e.hp > 0
                && _row_mul > 0
                && _geo_hit)
            {
                // 炎帝对魂系（符咒鼠/符咒魂鼠/执念鼠魂体/开路鼠魂体）与药罐鼠造成 2 倍基础伤害。
                // 🔴 2026-11-21 口径（数据表 L84「三转魂系老鼠 2 倍伤」）：**三转起**才有 ——
                //   0 转 / 一转按普通伤害走，连「无视魂体减伤」也不给（来源标记一并清空）。
                //   倍率统一取自 longyuan_soul_bonus_mult()，不要在此另写数字。
                var _soul_ok = (shape >= 1);
                var _base_dmg = damage * _row_mul;
                var _dmg = (_soul_ok && longyuan_is_soul_bonus_target(_e))
                           ? floor(_base_dmg * longyuan_soul_bonus_mult(obj_shennong_god))
                           : _base_dmg;

                with (_e)
                {
                    audio_play_sound(hit_sound, 0, 0);
                    damage_amount = _dmg;
                    damage_type = other.damage_type;
                    // 标记来源：魂系敌人据此豁免 90% 魂体减伤 / 药罐鼠据此掉一团魂火（双通道）
                    damage_source_object = _soul_ok ? obj_shennong_god : noone;
                    damage_source_card_id = _soul_ok ? "shennong_god" : "";
                    event_user(0);
                    // 击杀化灰：**先把本体隐去**（ash_death + image_alpha = 0），再放灰烬。
                    //   否则父类会给这只老鼠播完整的死亡动画，同时灰烬也冒出来 —— 现象就是
                    //   「老鼠本体躺在那儿和灰烬叠在一起」。
                    //   写法与 金刚马 / 石榴爆爆冰 / 护法神 一致：ash_death = true 让父类跳过死亡动画，
                    //   击杀结算（金币掉落 / 海克斯击杀）照常在父类 Step 里跑完。
                    if (other.ash_kill && hp <= 0)
                    {
                        ash_death   = true;
                        image_alpha = 0;
                        instance_create_depth(x, y - 20, depth, obj_mouse_ash_death);
                    }
                    damage_source_card_id = "";
                }

                ds_list_add(hitted_enemy, _e.id);
            }
        }
    }
}
	}
}

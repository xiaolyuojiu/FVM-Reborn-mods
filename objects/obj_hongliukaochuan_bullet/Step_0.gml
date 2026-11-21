if (global.is_paused)
{
    image_speed = 0;
    exit;
}

image_speed = 1;

timer++;

if (timer > max_life || x > 2200 || y > 1200 || x < 0 || y < 0)
{
    instance_destroy();
    exit;
}

if (!has_hit)
{
    if (homing_target_ok(target_id))
    {
        // 瞄准点 = 目标身体中部（与 obj_hongliukaochuan/Other_11 同一口径，取 combat_enemy_body_y）
        var _aim_y = combat_enemy_body_y(target_id);
        var _dx = target_id.x - x;
        var _dy = _aim_y - y;
        var _len = point_distance(0, 0, _dx, _dy);
        if (_len > move_speed * 2)
        {
            move_x = (_dx / _len) * move_speed;
            move_y = (_dy / _len) * move_speed;
        }
        else
        {
            // 已经贴到目标身上 → 放弃追踪，保持当前方向穿过去（不再来回折返抽搐）
            target_id = noone;
        }
    }
    else
    {
        // 目标消失 / 无敌 / 隐身 → 永久脱离，直线飞出地图为止
        target_id = noone;
    }
    image_angle = point_direction(0, 0, move_x, move_y);
}

x += move_x;
y += move_y;

if (variable_global_exists("enemy_by_type"))
{
    for (var _t = 0; _t < array_length(hittable_types); _t++)
    {
        var _key = hittable_types[_t];
        if (!variable_struct_exists(global.enemy_by_type, _key)) continue;
        var _list = global.enemy_by_type[$ _key];
        for (var _i = 0; _i < array_length(_list); _i++)
        {
            var _e = _list[_i];
            if (!instance_exists(_e)) continue;
            if (ds_list_find_index(hitted_enemy, _e.id) == -1
                && _e.hp > 0
                && precise_bbox_collision(id, _e))
            {
                has_hit = true;

                // 魂系额外倍率：只认「魂系敌人 + 药罐鼠」，幽灵鼠不算魂系；倍率取 longyuan_soul_bonus_mult()
                var _is_soul = longyuan_is_soul_bonus_target(_e);

                var _dmg = damage;
                if (_is_soul)
                    _dmg = floor(damage * longyuan_soul_bonus_mult(obj_hongliukaochuan));

                with (_e)
                {
                    audio_play_sound(hit_sound, 0, 0);
                    damage_amount = _dmg;
                    damage_type = other.damage_type;
                    // 标记来源：魂系敌人据此豁免 90% 魂体减伤 / 魂火减伤（双通道，见 longyuan_hit_pierces_soul_reduction）
                    damage_source_object = obj_hongliukaochuan;
                    damage_source_card_id = "hongliukaochuan";
                    if (variable_instance_exists(id, "ly_dig_hittable")) ly_dig_hittable = true;
                    event_user(0);
                    // 用完即清：同一帧内其它卡片再命中同一目标时不会误吃到这次豁免
                    damage_source_card_id = "";
                }

                ds_list_add(hitted_enemy, _e.id);
            }
        }
    }
}

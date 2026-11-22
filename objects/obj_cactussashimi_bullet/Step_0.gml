// 仙人掌刺身子弹 Step：手动逐帧 + 水平推进 + 归行 + 命中
if (global.is_paused)
{
    image_speed = 0;
    exit;
}

// 手动逐帧：4 帧循环（与 3.1.0 的 bullet_anim_step = 3 同口径）
timer++;
image_index = (floor(timer / 3)) mod 4;

// 焦 / 着火换图
if (burnt == 1) sprite_index = spr_fire_bullet;

// 水平推进；纵向 lerp 到目标行，靠近后把 row 切到目标行（漏行时才需要）
x += move_speed;
var _ty = global.grid_offset_y + global.grid_cell_size_y * target_row;
y = lerp(y, _ty, 0.15);
if (abs(y - _ty) < 30) row = target_row;

hit_tick++;
if (hit_tick >= global.bullet_hit_interval)
{
	hit_tick = 0;
	if (bullet_enemy_reachable(id)) {
if (variable_global_exists("enemy_by_type"))
{
    for (var _t = 0; _t < array_length(hittable_types); _t++)
    {
        var _key = hittable_types[_t];
        if (!variable_struct_exists(global.enemy_by_type, _key)) continue;
        var _list = bullet_sap_type_list(id, _key);
        for (var _i = 0; _i < array_length(_list); _i++)
        {
            var _e = _list[_i];
            if (!instance_exists(_e)) continue;
            if (_e.hp > 0 && row == _e.grid_row
    && precise_bbox_collision(id, _e))
            {
                with (_e)
                {
                    if (other.burnt == 1)
                        audio_play_sound(snd_fire_hit, 0, 0);
                    else
                        audio_play_sound(hit_sound, 0, 0);

                    damage_amount = other.damage;
                    damage_type = other.damage_type;
                    event_user(0);
                }

                if (burnt == 0)
                {
                    var _fx = instance_create_depth(x, y, depth, obj_coke_bomb_explode);
                    _fx.sprite_index = spr_cactus_sashimi_bullet_effect;
                }
                else
                {
                    var _fx2 = instance_create_depth(x + 25, y, depth, obj_fire_bullet_effect);
                    _fx2.sprite_index = spr_fire_bullet_effect;
                }

                instance_destroy();
                exit;
            }
        }
    }
}
	}
}

if (x > 2200 || y > 1200 || x < -200 || y < -200)
    instance_destroy();

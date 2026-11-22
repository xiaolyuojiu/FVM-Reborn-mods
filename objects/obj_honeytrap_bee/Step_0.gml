// obj_honeytrap_bee Step
// 停靠 → 放飞追踪 → 命中后播 19~23 帧黄光（特效段不再结算伤害），播完销毁。
if (global.is_paused) exit;

timer++;

// 命中特效段：黄光 19~23 帧
if (hitting)
{
    hit_t++;
    image_index = hit_first + min(hit_last - hit_first, hit_t div 3);
    if (hit_t >= (hit_last - hit_first + 1) * 3) instance_destroy();
    exit;
}

// 1~18 蜜蜂飞行
image_index = (timer div 3) mod 18;

if (stored)
{
    // 停靠：跟着卡走，轻微上下浮动
    if (instance_exists(owner_id))
    {
        x = owner_id.x + 24;
        y = owner_id.y - 8 - park_index * 16 + sin(timer * 0.12) * 4;
    }
    exit;
}

// 放飞：追踪目标
if (instance_exists(target_id) && target_id.hp > 0)
{
    var _dir = point_direction(x, y, target_id.x, target_id.y - 50);
    x += lengthdir_x(move_speed, _dir);
    y += lengthdir_y(move_speed, _dir);

    // 先用点距离粗判，近了才做精确蒙版碰撞（precise 每帧每只都调太贵）
    if (point_distance(x, y, target_id.x, target_id.y - 30) < 40
        && precise_bbox_collision(id, target_id))
    {
        var _e    = target_id;
        var _dmg  = damage;
        var _mult = boss_mult;

        with (_e)
        {
            damage_amount = _dmg * (_e.is_boss ? _mult : 1);
            damage_type   = "normal";
            event_user(0);
        }

        audio_play_sound(snd_fire_hit, 0, 0);

        // 转命中特效（不立刻销毁，交给上面的特效段播完）
        hitting     = true;
        hit_t       = 0;
        image_index = hit_first;
        exit;
    }
}
else
{
    // 目标没了：重新锁一只（先 BOSS 再最高血）；口径 = 卡自己的 target_type（陆空地）
    // 重索敌节流：每 relock_gap 帧才扫一次 obj_enemy_parent；
    //   连续 relock_fail_max 次锁不到就退场（3 只/卡 × N 张时不会每帧全扫）。
    relock_timer++;
    if (relock_timer >= relock_gap)
    {
        relock_timer = 0;
        var _t = noone;
        with (obj_enemy_parent)
        {
            if (hp <= 0) continue;
            if (!can_target_on(other.target_type, target_type)) continue;
            if (!instance_exists(_t) || (is_boss && !_t.is_boss)
                || (is_boss == _t.is_boss && hp > _t.hp))
                _t = id;
        }
        target_id = _t;

        if (!instance_exists(target_id))
        {
            relock_fail++;
            if (relock_fail >= relock_fail_max) instance_destroy();   // 锁不到就退场，不再空转
        }
        else relock_fail = 0;
    }

    if (!instance_exists(target_id))
    {
        x += move_speed;   // 没目标就向右飞出去
    }
}

if (timer > max_life || x > 2400 || x < -300) instance_destroy();

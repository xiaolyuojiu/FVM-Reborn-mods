// 开火：全屏索敌最近目标，发射追踪穿透的红柳肉串
// 可命中：陆（normal）/ 空（air）/ 幽灵类（invisible）
var _hittable = ["normal", "air", "invisible"];

var _target = noone;
var _best_score = -infinity;

if (variable_global_exists("enemy_by_type"))
{
    for (var _t = 0; _t < array_length(_hittable); _t++)
    {
        var _key = _hittable[_t];
        if (!variable_struct_exists(global.enemy_by_type, _key)) continue;
        var _list = global.enemy_by_type[$ _key];
        for (var _i = 0; _i < array_length(_list); _i++)
        {
            var _e = _list[_i];
            if (!instance_exists(_e) || _e.hp <= 0) continue;

            var _dist = point_distance(x, y, _e.x, _e.y);
            var _score = -_dist;
            if (_e.is_boss) _score += 1000000;

            if (_score > _best_score)
            {
                _best_score = _score;
                _target = _e;
            }
        }
    }
}

if (_target != noone && instance_exists(_target))
{
    // 出弹口 = 卡片右前方炉口（精灵 (+35,-28)，卡片按 1.8 倍绘制 → (+63,-50)）。
    // 弹道只由「方向」决定：出弹口固定，方向指向目标身体中部。
    var _muzzle_x = x + 63;
    var _muzzle_y = y - 50;

    var inst = instance_create_depth(_muzzle_x, _muzzle_y, depth - 500, obj_hongliukaochuan_bullet);
    // 二转「子弹数 1/1/2」按子弹压缩实现：一轮只出 1 发，伤害已在 atk 表里（二转 = 一转 ×2）
    inst.damage = atk;
    inst.target_id = _target.id;
    inst.hittable_types = _hittable;

    // 瞄准点 = 目标身体中部（敌人精灵原点在脚底，helper 内部按身高往上抬）
    var _aim_y = combat_enemy_body_y(_target);

    var _dx = _target.x - _muzzle_x;
    var _dy = _aim_y - _muzzle_y;
    var _len = point_distance(0, 0, _dx, _dy);
    if (_len > 0)
    {
        inst.move_x = (_dx / _len) * inst.move_speed;
        inst.move_y = (_dy / _len) * inst.move_speed;
    }

    // 三形态共用同一颗红柳肉串（子弹默认精灵即 spr_hongliukaochuan_bullet）
    inst.image_angle = point_direction(0, 0, inst.move_x, inst.move_y);

    audio_play_sound(snd_shot, 0, 0);
}

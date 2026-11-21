/// 金刚马 开火事件（用户事件 1）：每轮 1 发
/// 索敌 = Step 每帧算好的 jg_target（jg_hittable 白名单里 x 最大的那只），命中也不消失、继续直线穿
var _target = jg_target;
if (!instance_exists(_target) || _target.hp <= 0) exit;

var _bx = x + 40;
var _by = y + jg_art_up;

var _b = instance_create_depth(_bx, _by, depth - 500, obj_jingangma_bullet);
_b.damage         = atk;
_b.base_atk       = atk;
_b.shape          = shape;
_b.row            = grid_row;
_b.target_id      = _target.id;
_b.hittable_types = jg_hittable;
_b.stun_chance    = jg_stun_chance;
_b.stun_frames    = jg_stun_frames;
_b.kill_normal    = jg_kill_normal;

// 朝向：音波原点在内容底部，直接瞄敌人 y（脚底线）即可 —— 音波本身 170px 高，覆盖整段身体
//   （2026-11-13 起不再照抄烤串机的「瞄头部 -30」）
var _dx = _target.x - _bx;
var _dy = _target.y - _by;
var _len = point_distance(0, 0, _dx, _dy);
if (_len > 0.001){
    _b.move_x    = (_dx / _len) * _b.move_speed;
    _b.move_y    = (_dy / _len) * _b.move_speed;
    _b.image_angle = point_direction(0, 0, _b.move_x, _b.move_y);
}

audio_play_sound(snd_shot, 0, 0);

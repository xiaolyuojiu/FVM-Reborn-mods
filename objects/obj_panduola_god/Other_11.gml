// ===== 潘多拉：放置立即 3×3 灰烬爆炸 + 本行毒气瘟疫 + (终转)全屏爆炸 + 鼠疫 =====
var _cx = grid_col;
var _cy = grid_row;

// 1) 爆炸：终转全屏，其余形态 3×3；伤害取 [攻击力]（终转形态注册表里就是 8000）
if (shape >= 3)
{
    with (obj_enemy_parent)
    {
        if (hp > 0)
        {
            damage_amount = other.atk;
            damage_type = "normal";
            event_user(0);
        }
    }
}
else
{
    with (obj_enemy_parent)
    {
        if (hp > 0 && abs(grid_col - _cx) <= 1 && abs(grid_row - _cy) <= 1 && can_hit_ash(other.target_type, target_type))
        {
            damage_amount = other.atk;
            damage_type = "normal";
            event_user(0);
        }
    }
}

// 2) 爆炸特效（复用可乐炸弹灰烬爆炸贴图）
var _exp = instance_create_depth(x, y, depth - 1, obj_coke_bomb_explode);
_exp.sprite_index = spr_coke_bomb_explode;

// 3) 毒气瘟疫：本行；四转起 +1 列（本列）
var _poison = instance_create_depth(x, y, depth + 1, obj_panduola_effect);
_poison.grid_row = _cy;
_poison.grid_col = _cx;
_poison.shape = shape;
_poison.target_type = target_type;
_poison.tick_damage = poison_damage;

// 4) 终转：鼠疫
if (shape >= 3)
{
    _poison.has_plague = true;
    _poison.plague_bonus = poison_damage;
}

audio_play_sound(snd_coke_bomb_explode, 0, false);

if (global.is_paused)
    exit;

tick_timer++;
plague_timer++;

// 毒气瘟疫：本行；四转起本列也算
if (tick_index < max_ticks && tick_timer >= tick_delays[tick_index])
{
    tick_timer = 0;
    tick_index++;

    with (obj_enemy_parent)
    {
        if (hp > 0 && can_hit(other.target_type, target_type))
        {
            var _hit = (grid_row == other.grid_row);
            if (other.shape >= 2)
                _hit = _hit || (grid_col == other.grid_col);

            if (_hit)
            {
                damage_amount = other.tick_damage;
                damage_type = "normal";
                event_user(0);
            }
        }
    }
}

// 鼠疫（终转）：全屏，每 plague_interval 帧一跳，共 3 次
if (has_plague && plague_left > 0 && plague_timer >= plague_interval)
{
    plague_timer = 0;
    plague_left--;

    with (obj_enemy_parent)
    {
        if (hp > 0)
        {
            damage_amount = min(1000000, round(maxhp * 0.03 + other.plague_bonus));
            damage_type = "normal";
            event_user(0);
        }
    }
}

// 全部结算完毕后销毁
if (tick_index >= max_ticks && (!has_plague || plague_left <= 0))
{
    instance_destroy();
}

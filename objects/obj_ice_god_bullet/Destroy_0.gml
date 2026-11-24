// 终转才有的溅射：同行 ±1 行 + 横向 1.5 格（与冷萃机 / 雪球兔同口径，不写死像素）
// 只打主目标以外的、与卡片 target_type 同类的敌人
if (shape >= 3)
{
    var _x = x;
    var _row_range = 1;
    var _col_range = global.grid_cell_size_x * 1.5;
    var splash_ratio = 0.45;   // 表 9.追踪 r85：终转 3*3 范围 45% 溅射
    
    with (obj_enemy_parent)
    {
        if (hp > 0 && abs(x - _x) <= _col_range && grid_row <= (other.row + _row_range) && grid_row >= (other.row - _row_range) && id != other.hitted_enemy
            && !scatter_target_blocked(id) && can_target_on(other.target_type, target_type))
        {
            damage_amount = other.damage * splash_ratio;
            damage_type = other.damage_type;
            
            // 减速：只有三转 / 四转有，2.5 秒；终转移除减速
            if (other.shape >= 1 && other.shape <= 2 && ice_timer < 150)
                ice_timer = 150;
            
            event_user(0);
        }
    }
}

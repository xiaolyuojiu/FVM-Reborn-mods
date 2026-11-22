var bullet_obj = obj_joker_bullet;

switch (shape)
{
    case 0:
        bullet_obj = obj_joker_bullet;
        break;
    
    case 1:
        bullet_obj = obj_joker_bullet_1;
        break;
    
    case 2:
        bullet_obj = obj_joker_bullet_2;
        break;
    
    case 3:
        bullet_obj = obj_joker_bullet_3;
        break;
}

var inst = instance_create_depth(x + 20, y - 85, depth - 45, bullet_obj);
inst.damage = atk;
inst.move_speed = 7;
inst.row = grid_row;
// 卡面「空、地、水陆老鼠」= 陆军 / 潜水 / 空军 / 地鼠 → 直接用 track_under 类型（不必手写名单）
//   四级优先（空→地下→潜水→陆地）写在各弹体 Step 里，不在这里切弹种
inst.target_type    = target_type;
inst.hittable_types = get_hittable_enemy_types(target_type);
inst.splash_ratio   = jk_splash_ratio;   // 溅射倍率走 custom（0.4 / 0.4 / 0.8 / 1）
inst.shape = shape;

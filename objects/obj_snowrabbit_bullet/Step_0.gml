/// 雪球兔 弹体 Step
/// 实例直接钉在目标脚底，播 spr_snowrabbit_bullet 的「下落 → 砸中 → 碎冰」动画
///   （11 帧：0~2 下落、3 砸中、4~9 碎冰、10 空），第 4 帧结算伤害。
/// 贴图只画到砸中/碎冰那一段高度，前三帧的下落由 sb_fall_off 把 y 抬回去。
if (global.is_paused) exit;

// ── 错帧等待 ──
if (fall_delay > 0){
    fall_delay--;
    image_alpha = 0;                     // 等待期间隐藏，别悬在目标头上
    if (instance_exists(target_id) && target_id.hp > 0){
        sb_fall_base = target_id.y;
        x = target_id.x;
    }
    y = sb_fall_base + sb_fall_off[clamp(floor(image_index), 0, 10)];
    exit;
}
image_alpha = 1;

image_index += 0.55;

// ── 落点始终贴着目标（追踪；目标死了就停在最后位置） ──
if (instance_exists(target_id) && target_id.hp > 0){
    sb_fall_base = target_id.y;
    x = target_id.x;
}
y = sb_fall_base + sb_fall_off[clamp(floor(image_index), 0, 10)];

// ── 砸中（第 4 帧 = index 3）结算 ──
if (!has_hit && image_index >= 3){
    has_hit = true;
    audio_play_sound(snd_snowrabbit_hit, 0, 0);

    // 主目标：优先仍是锁定的那只（飞行中钻地了就不认，转去另找）
    var _e = noone;
    if (instance_exists(target_id) && target_id.hp > 0 && !scatter_target_blocked(target_id)){
        _e = target_id;
    } else {
        var _best = 999999;
        with (obj_enemy_parent){
            if (hp <= 0) continue;
            // 补漏：落点兜底也要守同一套口径（地精钻地 / 潜水 / 非主流 / 幽灵 / 障碍都不砸）
            if (scatter_target_blocked(id)) continue;
            if (!can_target_on(other.target_type, target_type)) continue;
            if (abs(grid_row - other.row) > 1) continue;
            if (abs(x - other.x) > global.grid_cell_size_x * 0.6) continue;
            var _d = point_distance(x, y, other.x, other.y);
            if (_d < _best){ _best = _d; _e = id; }
        }
    }

    if (instance_exists(_e)){
        hitted_enemy = _e.id;

        with (_e){
            damage_amount         = other.damage;
            damage_type           = other.damage_type;
            damage_source_object  = obj_snowrabbit;
            damage_source_card_id = "snowrabbit";
            event_user(0);
            damage_source_card_id = "";
        }

        // 2 转：3*3 范围 20% 溅射
        if (splash_ratio > 0){
            with (obj_enemy_parent){
                if (hp <= 0) continue;
                if (id == other.hitted_enemy) continue;
                if (abs(grid_row - other.row) > other.splash_cells) continue;
                if (abs(x - other.x) > global.grid_cell_size_x * (other.splash_cells + 0.5)) continue;
                // 钻地中的龙渊地精鼠属「不攻击类型」：溅射也不碰（2026-11-18 用户口径）
                if (scatter_target_blocked(id)) continue;
                if (!can_target_on(other.target_type, target_type)) continue;

                damage_amount         = other.damage * other.splash_ratio;
                damage_type           = other.damage_type;
                damage_source_object  = obj_snowrabbit;
                damage_source_card_id = "snowrabbit";
                event_user(0);
                damage_source_card_id = "";
            }
        }
    }
}

// ── 动画播完就消失 ──
if (image_index >= 10.5){
    instance_destroy();
}

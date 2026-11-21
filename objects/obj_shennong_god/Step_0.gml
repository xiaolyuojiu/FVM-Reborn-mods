if (global.is_paused)
    exit;

var current_flash_speed = flash_speed;

if (is_slowdown)
    current_flash_speed *= 2;

event_inherited();

if (is_frozen || state == CARD_STATE.SLEEP)
    exit;

// === 场上神农 ≥7 张：攻击力最高的那一只每 5 秒在 7.5 / 8.5 列召唤 2 只竖向朱雀 ===
// 口径：
//   · **全形态都吃**（情报岛写在「基础能力」里，不是终转专属）
//   · 只由场上攻击力最高的那一只放；攻同取 id 最小的那只，保证只有 1 只出手
//   · 睡着 / 冰冻的不参与评选，不会把全队卡死
//   · 伤害取那一只自己的 atk（所以它的增幅 / 拐都会跟着这只朱雀走）
//   · 竖向朱雀打 7~9 列，每次都是全额：0~2 转 = 7 列 1 次 / 8 列 2 次 / 9 列 1 次；
//     终转（朱雀范围整体放大一档）= 三列各 2 次
// 本段必须放在 cooldown_timer 判断之前：追加陨焰不吃卡片自身攻击间隔。
is_top_attacker = false;

if (instance_number(obj_shennong_god) >= 7)
{
    var _best_id = noone;
    var _best_atk = -1;

    with (obj_shennong_god)
    {
        if (state == CARD_STATE.SLEEP || is_frozen) continue;

        if (atk > _best_atk)
        {
            _best_atk = atk;
            _best_id = id;
        }
        else if (atk == _best_atk && (_best_id == noone || id < _best_id))
        {
            _best_id = id;
        }
    }

    is_top_attacker = (id == _best_id);
}

if (is_top_attacker)
{
    vburst_timer++;

    if (vburst_timer >= 300)   // 5 秒
    {
        vburst_timer = 0;

        for (var _vb_i = 0; _vb_i < 2; _vb_i++)
        {
            // _vb_i = 0 → 7.5 列那条边界，1 → 8.5 列
            var _line_x = global.grid_offset_x + (7 + _vb_i) * global.grid_cell_size_x;
            var _line_y = global.grid_offset_y - 120;

            var _vb = instance_create_depth(_line_x, _line_y, depth - 520, obj_shennong_god_bullet_v3);
            _vb.damage = atk;
            _vb.move_speed = 8;
            if (shape >= 3)
            {
                // 终转：朱雀范围整体放大一档 —— 两只都覆盖 7 / 8 / 9 三整列，
                // 于是每列都被两只各打一次 = 都是 2 次。
                _vb.col_left = 6;
                _vb.col_hits = [1, 1, 1];
            }
            else
            {
                // 0~2 转：7.5 列那只盖第 7、8 列；8.5 列那只盖第 8、9 列。
                // 叠加后 7 列 1 次、8 列 2 次、9 列 1 次，每次都是全额。
                _vb.col_left = 6 + _vb_i;
                _vb.col_hits = [1, 1];
            }
            _vb.ash_kill = true;
            _vb.shape = shape;      // 形态要传下去：魂系 2 倍是「三转起」，弹体自己判 shape >= 1
            // 贴图按释放者形态走（0~2 转用各自形态的朱雀，终转才用 spr_..._3）
            if (shape == 0)      _vb.sprite_index = spr_shennong_god_bullet;
            else if (shape == 1) _vb.sprite_index = spr_shennong_god_bullet_1;
            else if (shape == 2) _vb.sprite_index = spr_shennong_god_bullet_2;
            else                 _vb.sprite_index = spr_shennong_god_bullet_3;
            if (shape >= 2) {
                _vb.target_type = "land_air_ug";   // 四转起：陆 + 空 + 地（不含潜水 / 非主流 / 幽灵）
                // 障碍不索敌，但竖落弹扫到仍掉血（名单统一走类型）
                _vb.hittable_types = get_hittable_enemy_types("land_air_ug");
            } else {
                _vb.target_type = "normal";
                _vb.hittable_types = get_hittable_enemy_types("normal");
            }
        }

        audio_play_sound(snd_shot, 0, 0);
    }
}
else
{
    vburst_timer = 0;
}

// 冷却中则跳过攻击逻辑
if (cooldown_timer > 0)
{
    cooldown_timer--;
    exit;
}

// 检测全屏是否有可攻击的敌人（子弹全屏飞行）
var has_enemy = false;

with (obj_enemy_parent)
{
    if (grid_col >= 0 && grid_col <= (global.grid_cols + 1)
        && can_target_on(other.target_type, target_type))
    {
        has_enemy = true;
        break;
    }
}

var attack_total_frames = attack_anim * current_flash_speed;

if (has_enemy)
{
    attack_timer++;

    // 第19帧发射（索引18），攻击从第14帧（索引13）开始
    // 攻击动画共12帧（索引13~24），第19帧是攻击开始后第6帧（索引18-13=5）
    var fire_frame_in_attack = 5;
    var fire_time = fire_frame_in_attack * current_flash_speed;

    // 开始攻击
    if (attack_timer == 1)
    {
        state = CARD_STATE.ATTACK;
        image_index = idle_anim + 1;
    }

    // 第19帧发射子弹
    if (attack_timer == fire_time)
    {
        event_user(1);
    }

    // 攻击结束，重置冷却
    if (attack_timer >= attack_total_frames)
    {
        attack_timer = 0;
        cooldown_timer = cycle - attack_total_frames;
        state = CARD_STATE.IDLE;
    }
}
else
{
    attack_timer = 0;
    state = CARD_STATE.IDLE;
}

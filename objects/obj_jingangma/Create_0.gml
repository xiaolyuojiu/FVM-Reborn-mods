/// 金刚马 / 魔铃金刚马 / 梵音金刚马（jingangma）Create 事件
/// ── 定位 ──
///   直射类·穿透追踪：全屏索敌**最远**目标（x 最大），发射一条追踪穿透音波，
///   命中后不消失、继续直线飞；原版 1/2/3 发已压成**每轮 1 发**（atk 表已按发数放大）。
event_inherited();

plant_id = "jingangma";
obj_type = object_index;
event_user(0);

// ── 形态 ──
if (shape == 0)      sprite_index = spr_jingangma;
else if (shape == 1) sprite_index = spr_jingangma_1;
else                 sprite_index = spr_jingangma_2;

// ── 动画分段（2026-11-12 用户口径）──
//   待机 = 第 1~11 帧（index 0~10）；攻击 = 第 12~24 帧（index 11~23，共 13 帧）
idle_anim   = 10;
attack_anim = 13;
image_speed = 0;        // 帧由 obj_card_parent 的 timer 推，image_speed 必须 0
flash_speed = 5;

// ── 基础字段 ──
plant_type   = "normal";
feature_type = "normal";
is_slowdown  = false;
attack_type  = ATTACK_TYPE.SHOOTER;

// target_type 不参与伤害、也不是索敌依据（索敌是 Step 里自扫 jg_hittable 三个桶）。
//   它只剩两个外部消费者：① 高跷鼠舞步闪避（读子弹 target_type）② 其它系统「场上有没有目标」。
//   写 `normal` = 与烤串机 / 护法神 同口径：不会把非主流 / 障碍算成目标，高跷也不会白播闪避。
//   幽灵照样打得到 —— 那靠的是下面 jg_hittable，与 target_type 无关。
target_type = "normal";

// ── 回合状态（时间轴见 Step_0 顶部）──
attack_timer  = 0;
state         = CARD_STATE.IDLE;
jg_art_up     = -18;              // 出膛点相对卡片 y 的偏移（音波从头部冒出）
jg_fire_frame = idle_anim + 7;    // 出弹绑动画第 18 帧（index 17）＝铃铛晃动段开头

// ── 当前目标 ──
//   Step 每帧选一次「最远（x 最大）的可打目标」存这里，Other_11 直接取用、不再自扫一遍。
jg_target = noone;

// ── 技能参数（固定值，写死，不进 custom）──
//   1 转起：命中 15% 定身 1.5 秒；2 转起：秒杀平民鼠
jg_stun_chance = (shape >= 1) ? 15 : 0;
jg_stun_frames = (shape >= 1) ? round(1.5 * 60) : 0;
jg_kill_normal = (shape >= 2);

// ── 命中白名单 ──
//   卡面「攻击沿途陆、空鼠军」+ 通用「可直接攻击幽灵鼠」= 普通陆鼠 / 空军 / 幽灵鼠。
//   2026-11-13 用户报「金刚马能打到非主流」：`pierce` 自带 dance(非主流·高跷) / 障碍 / 钻地，太宽，
//   所以伤害侧手写这份名单 —— 别再改回 get_hittable_enemy_types("pierce")。
jg_hittable = ["normal", "air", "invisible"];

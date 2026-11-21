/// 金刚马 Step 事件
/// ── 节奏模型 ──
///   一轮 = cycle 帧 = 待机段 + 攻击段；攻击段 = attack_anim 个 index，整段在本轮内播完。
///   步长：cycle 装得下整段就 flash_speed，装不下就 floor(cycle / attack_anim)（口径同弹珠汽水）。
///   出弹 = 攻击段第 7 帧（动画 index 17 = 铃铛晃动开头），时刻 = 攻击段起点 + 步长 × 6，
///   与 image_index 同一时间基。一轮 1 发，计时器全程不停，实际间隔恒等于 cycle。
if (global.is_paused) exit;

event_inherited();

if (is_frozen || state == CARD_STATE.SLEEP) exit;

var _cfs = flash_speed;
if (is_slowdown) _cfs = flash_speed * 2;

// ── 每帧选一次目标：jg_hittable 三个桶里 x 最大（最远）的那只 ──
//   只认已登记进 enemy_by_type 的敌人（obj_battle 建表）；不能改成 with(obj_enemy_parent)，
//   那样会把不注册的身体部件（obj_thor_head / obj_pete_claw 之类）也当成目标。
//   选完存进 jg_target，Other_11 直接取用，不再自扫一遍。
if (!variable_global_exists("enemy_by_type")) exit;

var _best_x = -999999;
jg_target   = noone;
for (var _t = 0; _t < array_length(jg_hittable); _t++){
    if (!variable_struct_exists(global.enemy_by_type, jg_hittable[_t])) continue;
    var _arr = global.enemy_by_type[$ jg_hittable[_t]];
    for (var _i = 0; _i < array_length(_arr); _i++){
        var _e = _arr[_i];
        if (instance_exists(_e) && _e.hp > 0 && _e.x > _best_x){
            _best_x   = _e.x;
            jg_target = _e;
        }
    }
}
if (jg_target == noone){
    attack_timer = 0;
    state        = CARD_STATE.IDLE;
    exit;
}

// ── 一轮的时间轴 ──
//   攻击段步长：cycle 装得下整段就按 flash_speed，装不下就压到 floor(cycle / attack_anim)
var _step    = clamp(floor(min(cycle, attack_anim * _cfs) / attack_anim), 1, _cfs);
var _anim_t0 = max(0, cycle - attack_anim * _step);                  // 攻击段起点
var _fire_off = (jg_fire_frame - idle_anim - 1) * _step;            // 从攻击段起点到出弹帧
var _fire_t  = clamp(_anim_t0 + _fire_off, 1, max(1, floor(cycle)));

attack_timer++;
if (attack_timer > cycle) attack_timer = 1;                         // 上一轮结束，直接开下一轮

if (attack_timer >= _anim_t0){
    // 攻击段：进段归位到第 12 帧（index 11），之后每帧自己推帧
    if (state != CARD_STATE.ATTACK) state = CARD_STATE.ATTACK;
    image_index = min(idle_anim + attack_anim,
                      idle_anim + 1 + floor((attack_timer - _anim_t0) / _step));
    if (attack_timer == _fire_t) event_user(1);
}
else if (state == CARD_STATE.ATTACK){
    state       = CARD_STATE.IDLE;                                  // 待机段：还回待机动画
    image_index = 0;
}

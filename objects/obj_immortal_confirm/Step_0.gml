/// obj_immortal_confirm Step：悬停 + 点「确定 / 取消」
if (ic_done) exit;

// 创建出来先吃掉两帧，避免「点箭头那一下」连带把窗里的按钮也点了
if (ic_guard > 0) {
    ic_guard -= 1;
    exit;
}

var mx = mouse_x;
var my = mouse_y;

ic_hover = -1;
for (var _b = 0; _b < 2; _b++) {
    var _r = mod_tg_confirm_rect(_b);
    if (point_in_rectangle(mx, my, _r[0], _r[1], _r[2], _r[3])) ic_hover = _b;
}

// ESC = 取消（否则会把下面的设置页关掉、窗却留在屏幕上）
if (keyboard_check_pressed(vk_escape)) {
    ic_done = true;
    audio_play_sound(snd_button, 0, 0);
    difficulty_set_value(1);
    instance_destroy();
    exit;
}

if (mouse_check_button_pressed(mb_left)) {
    if (ic_hover == 0) {
        ic_done = true;
        audio_play_sound(snd_button, 0, 0);
        // 确定 = 锁定不朽（内含：写存档字段 / 写 config / 可领则发开局奖励）
        difficulty_lock_immortal(true);
        instance_destroy();
    }
    else if (ic_hover == 1) {
        // 取消 = 不选不朽 → 难度回火山级
        ic_done = true;
        audio_play_sound(snd_button, 0, 0);
        difficulty_set_value(1);
        show_notice("已取消，难度回到火山级", 70);
        instance_destroy();
    }
}

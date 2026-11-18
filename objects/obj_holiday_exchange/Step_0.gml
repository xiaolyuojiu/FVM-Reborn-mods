/// 假期特惠 —— 交互（Step：本对象无 sprite，Mouse 事件不触发）
/// 命中区与 Draw 用同一套坐标（面板 × hal_s，行内 × hal_bar_s / hal_btn_s）。
var S = hal_s;
var BS = hal_bar_s;
var TS = hal_btn_s;
var _list  = (hal_tab == 0) ? hal_tab0 : hal_tab1;
var _len   = array_length(_list);
var _pages = max(1, ceil(_len / hal_per));
var _mx = mouse_x, _my = mouse_y;

// ── 批量兑换弹窗：模态，吃掉本帧所有输入 ────────────────────────────────
if (hal_batch_open){
	if (keyboard_check_pressed(vk_escape)){
		if (hal_batch_edit){ hal_batch_edit = false; hal_batch_txt = ""; }
		else hal_batch_open = false;
		keyboard_string = "";
		exit;
	}
	// 输入框编辑：只收数字 / 退格 / 回车（回车提交并结束编辑）
	if (hal_batch_edit){
		var _ks = keyboard_string;
		keyboard_string = "";
		for (var _ki = 1; _ki <= string_length(_ks); _ki++){
			var _kc = string_char_at(_ks, _ki);
			if (_kc >= "0" && _kc <= "9" && string_length(hal_batch_txt) < 9) hal_batch_txt += _kc;
		}
		if (keyboard_check_pressed(vk_backspace) && string_length(hal_batch_txt) > 0){
			hal_batch_txt = string_delete(hal_batch_txt, string_length(hal_batch_txt), 1);
		}
		if (hal_batch_txt != "" && real(hal_batch_txt) > hal_batch_max) hal_batch_txt = string(hal_batch_max);
		if (keyboard_check_pressed(vk_enter)){
			hal_batch_n = (hal_batch_txt == "") ? 1 : clamp(real(hal_batch_txt), 1, hal_batch_max);
			hal_batch_edit = false;
		}
	}
	else keyboard_string = "";   // 不编辑时也清掉，别漏给别的搜索框

	// 悬停（6 个热区）
	hal_batch_hover = -1;
	for (var _b = 0; _b < 6; _b++){
		var _br = hal_batch_rect(_b);
		if (point_in_rectangle(_mx, _my, _br[0], _br[1], _br[2], _br[3])) hal_batch_hover = _b;
	}

	if (mouse_check_button_pressed(mb_left)){
		if (hal_batch_hover == 5){                 // 点输入框 → 用键盘改数量
			hal_batch_edit = true;
			hal_batch_txt  = string(hal_batch_n);
			keyboard_string = "";
		}
		else if (hal_batch_hover != -1){
			// 先提交输入框里的数，再执行动作
			if (hal_batch_edit){
				hal_batch_n = (hal_batch_txt == "") ? 1 : clamp(real(hal_batch_txt), 1, hal_batch_max);
				hal_batch_edit = false;
				hal_batch_txt = "";
			}
			if (hal_batch_hover == 0)      hal_batch_n = max(1, hal_batch_n - 1);
			else if (hal_batch_hover == 1) hal_batch_n = min(hal_batch_max, hal_batch_n + 1);
			else if (hal_batch_hover == 2) hal_batch_n = hal_batch_max;
			else if (hal_batch_hover == 3){
				hal_batch_do(hal_batch_kind, hal_batch_row, hal_batch_n);
				hal_batch_open = false;
			}
			else if (hal_batch_hover == 4) hal_batch_open = false;
			audio_play_sound(snd_button, 0, 0);
		}
		else {                                     // 点空白 → 结束编辑
			hal_batch_edit = false;
			hal_batch_txt = "";
		}
	}
	exit;
}

// ESC 关闭（menu_type 由 Destroy_0 复原）
if (keyboard_check_pressed(vk_escape)){
	instance_destroy();
	exit;
}

// 滚轮换页
if (mouse_wheel_up())   hal_page = max(0, hal_page - 1);
if (mouse_wheel_down()) hal_page = min(_pages - 1, hal_page + 1);

if (!mouse_check_button_pressed(mb_left)) exit;

// 关闭
if (point_in_rectangle(_mx, _my, hal_close.x, hal_close.y, hal_close.x + hal_close.w, hal_close.y + hal_close.h)){
	audio_play_sound(snd_button, 0, 0);
	instance_destroy();
	exit;
}

// 页签
for (var t = 0; t < 2; t++){
	var _tx = hal_x + (t == 0 ? -hal_tab_dx : hal_tab_dx);
	if (point_in_rectangle(_mx, _my, _tx - 68 * S, hal_tab_y - 20 * S, _tx + 68 * S, hal_tab_y + 20 * S)){
		if (hal_tab != t){
			audio_play_sound(snd_button, 0, 0);
			hal_tab = t;
			hal_page = 0;
		}
		exit;
	}
}

// 左右箭头
if (point_in_rectangle(_mx, _my, hal_pg_lx - 16 * S, hal_pg_y - 16 * S, hal_pg_lx + 16 * S, hal_pg_y + 16 * S)){
	if (hal_page > 0){
		audio_play_sound(snd_button, 0, 0);
		hal_page = max(0, hal_page - 1);
	}
	exit;
}
if (point_in_rectangle(_mx, _my, hal_pg_rx - 16 * S, hal_pg_y - 16 * S, hal_pg_rx + 16 * S, hal_pg_y + 16 * S)){
	if (hal_page < _pages - 1){
		audio_play_sound(snd_button, 0, 0);
		hal_page = min(_pages - 1, hal_page + 1);
	}
	exit;
}

// 行：点斜纹区的「兑换」按钮才执行
var _start = hal_page * hal_per;
for (var k = 0; k < hal_per; k++){
	var _idx = _start + k;
	if (_idx >= _len) break;
	var _col = k mod 2;
	var _row = k div 2;
	var _ccx = hal_x + ((_col == 0) ? -hal_cell_dx : hal_cell_dx) * S;
	var _ccy = hal_y + (hal_row_y0 + _row * hal_row_dy) * S;
	var _btnx = _ccx + hal_btn_off * BS;

	if (!point_in_rectangle(_mx, _my, _btnx - 70 * TS, _ccy - 22 * TS, _btnx + 70 * TS, _ccy + 22 * TS)) continue;

	var _it  = _list[_idx];
	var _max = hal_batch_max_of(_it.kind, _it.row);
	if (_max <= 0){                       // 换不了（材料或金币不够）：按钮本来就是灰的，点了没反应
		audio_play_sound(snd_button, 0, 0);
		exit;
	}
	if (_max >= 2){                       // 能换 2 次以上 → 先问换几次
		hal_batch_open  = true;
		hal_batch_kind  = _it.kind;
		hal_batch_row   = _it.row;
		hal_batch_max   = _max;
		hal_batch_n     = 1;        // 默认 1/max，让玩家自己加
		hal_batch_hover = -1;
		audio_play_sound(snd_button, 0, 0);
		exit;
	}
	hal_batch_do(_it.kind, _it.row, 1);    // 只够换 1 次 → 直接换
	audio_play_sound(snd_button, 0, 0);
	exit;
}

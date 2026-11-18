/// 假期特惠 · 兑换
///   长期兑换 = 卡包低换高（3 张 N★ + 金币 → 1 张 N+1★）+ 四叶草 1~4 级低换高（5 个 + 金币 → 高一阶）
///              + 融合剂（3 张 10/11/12★ 卡包 → 1 个初级/深度/灵魂融合剂）
///   其他兑换 = 旧香料换强化用卡（1★ 起 7 档，2★/4★ 本来就刷不到所以不做）
///
/// 一行 = 一块底板，三块散图拼在里面（导出里 DefineSprite_112 那张 378×89 是**合成好的参考图**，
/// 上面「剩余时间 / 剩余次数」是占位测试数字，不能直接当底板）：
///   底板   spr_holiday_bar          382×95  浅色区（左） + 斜纹区（右，放按钮）
///   内容条 spr_holiday_row          254×63  3 个格 + 「兑换」箭头 + 结果圆牌
///   按钮   spr_holiday_btn_exchange 146×48  「兑换」三态，换不了时走灰度 shader
///
/// 缩放：面板 ×1.5；底板 ×0.95；内容条 ×0.887（254 → 237 = 底板浅色区宽度）；按钮 ×0.80。
hal_rows    = holiday_exchange_table();
hal_cards   = holiday_card_upgrade_table();
hal_clovers = holiday_clover_upgrade_table();
hal_agents  = holiday_fusion_agent_table();

hal_tab    = 0;          // 0 = 长期兑换，1 = 其他兑换
hal_page   = 0;
hal_per    = 8;          // 2 列 × 4 行

// 两个页签的条目各自拍平成一个数组，Draw / Step 都按下标取，按下标取 kind 分派
hal_tab0 = [];
for (var _i = 0; _i < array_length(hal_cards); _i++)
	array_push(hal_tab0, { kind: "up", row: hal_cards[_i] });          // 卡包低换高
for (var _j = 0; _j < array_length(hal_clovers); _j++)
	array_push(hal_tab0, { kind: "clover", row: hal_clovers[_j] });     // 四叶草 1~4 级低换高
for (var _m = 0; _m < array_length(hal_agents); _m++)
	array_push(hal_tab0, { kind: "agent", row: hal_agents[_m] });       // 卡包换融合剂

hal_tab1 = [];
for (var _k = 0; _k < array_length(hal_rows); _k++)
	array_push(hal_tab1, { kind: "spice", row: hal_rows[_k] });         // 旧香料换卡包

hal_s      = 1.5;                // 面板 → 屏幕
hal_bar_s  = hal_s * 0.94;
hal_row_s  = hal_s * 0.92;
hal_btn_s  = hal_s * 0.64;

hal_x = room_width  / 2;
hal_y = room_height / 2;

// 栅格（面板坐标；整块贴内区上部，首行离页签近一点）
hal_cell_dx = 179;               // 两列中心到面板中心（两列贴住，铺满内区 718/735）
hal_row_y0  = -80;               // 第一行中心
hal_row_dy  = 89;                // 行距 = 行高，4 行正好铺满内区 357

// 行内两件相对底板中心（底板美术坐标）
hal_row_off = -60;               // 内容条中心（略右移，给格子下方的数字留空间）
hal_btn_off =  119;              // 兑换按钮中心（底板右侧斜纹区 246..374 的中心）

// 内容条内部（素材原始坐标，相对条中心）
hal_slot_dx = [-103, -52, -1];   // 3 个格
hal_circ_dx = 102;               // 结果圆牌

// 页签
hal_tab_y  = hal_y - 186 * hal_s;
hal_tab_dx = 84 * hal_s;

// 翻页条
hal_pg_y  = hal_y + 256 * hal_s;
hal_pg_lx = hal_x - 150 * hal_s;
hal_pg_rx = hal_x + 150 * hal_s;

// 关闭（美术坐标左上角 hal_x+424 / hal_y-248，贴图 51×54）
hal_close = { x: hal_x + 424 * hal_s, y: hal_y - 248 * hal_s, w: 51 * hal_s, h: 54 * hal_s };

depth = -5;

// ── 批量兑换弹窗（2026-11-21 按官方样式重做）────────────────────────────
//   底板   spr_holiday_pop  382×268（紫色标题条 + 米色内区）
//   标题   spr_holiday_batch / 关闭 spr_holiday_close / 减加 spr_holiday_btn_minus·plus / MAX spr_holiday_btn_max
//   配方行 直接复用列表那套：spr_holiday_row + 图标 + 数字 + 结果圆牌
//   兑换   spr_holiday_btn_exchange（三态）
//   「本次登录关闭批量兑换」那个勾选不要（用户口径）
hal_batch_S     = 1.8;
hal_batch_open  = false;
hal_batch_kind  = "";
hal_batch_row   = undefined;
hal_batch_max   = 0;
hal_batch_n     = 1;
hal_batch_hover = -1;        // 0 减 / 1 加 / 2 MAX / 3 兑换 / 4 关闭 / 5 输入框
hal_batch_edit  = false;     // 输入框是否正在键盘编辑
hal_batch_txt   = "";        // 编辑中的文本

/// @func hal_batch_rect(i) 六个热区（顺序见 hal_batch_hover 注释）
///   底图 spr_holiday_pop：紫色条 y≈-205..-130（标题），米色条纹 y≈-68..+87（配方行），
///   下面 y≈+87..+241 才放输入行 + 兑换按钮 —— 这些数字都是按 ×1.8 量出来的
function hal_batch_rect(_i){
	var _px = hal_x, _py = hal_y;
	if (_i == 0) return [_px - 209, _py + 101, _px - 171, _py + 139];    // 减
	if (_i == 1) return [_px + 126, _py + 101, _px + 164, _py + 139];    // 加
	if (_i == 2) return [_px + 192, _py + 100, _px + 258, _py + 140];    // MAX
	if (_i == 3) return [_px - 91,  _py + 160, _px + 91,  _py + 220];    // 兑换
	if (_i == 4) return [_px + 270, _py - 188, _px + 310, _py - 146];    // 关闭
	return [_px - 160, _py + 100, _px + 120, _py + 140];                 // 输入框
}

/// @func hal_batch_max_of(kind, row) 这一条现在最多能换几次
function hal_batch_max_of(_kind, _row){
	if (_kind == "clover") return holiday_clover_upgrade_max(_row);
	if (_kind == "spice")  return holiday_exchange_max(_row);
	return holiday_card_upgrade_max(_row);          // up / agent
}

/// @func hal_batch_gold_of(kind, row) 每次兑换要多少金币（没有金币项返回 0）
function hal_batch_gold_of(_kind, _row){
	if (_kind == "up" || _kind == "clover") return _row.gold;
	return 0;
}

/// @func hal_batch_do(kind, row, n) 执行批量兑换
function hal_batch_do(_kind, _row, _n){
	if (_kind == "clover") return holiday_clover_upgrade_do(_row, _n);
	if (_kind == "spice")  return holiday_exchange_do(_row, _n);
	return holiday_card_upgrade_do(_row, _n);       // up / agent
}

/// @func hal_batch_recipe(kind, row) 配方的图标 / 结果 / 拥有量 / 单次消耗
function hal_batch_recipe(_kind, _row){
	var _d = { icons: [], res_spr: spr_craft_material, res_frame: 0, owned: 0, need: 0, gold: 0 };
	if (_kind == "up"){
		array_push(_d.icons, { spr: spr_craft_material, frame: holiday_warcard_frame(_row.star) });
		_d.owned = get_material_amount(_row.from); _d.need = _row.need;
		_d.res_frame = holiday_warcard_frame(_row.star + 1);
	}
	else if (_kind == "agent"){
		array_push(_d.icons, { spr: spr_craft_material, frame: holiday_warcard_frame(_row.star) });
		_d.owned = get_material_amount(_row.from); _d.need = _row.need;
		_d.res_frame = get_material_info(_row.to).icon;
	}
	else if (_kind == "clover"){
		array_push(_d.icons, { spr: craft_material_spr(_row.from), frame: craft_material_frame(_row.from) });
		_d.owned = get_material_amount(_row.from); _d.need = _row.need;
		_d.res_spr = craft_material_spr(_row.to); _d.res_frame = craft_material_frame(_row.to);
	}
	else {
		array_push(_d.icons, { spr: craft_material_spr(_row.spice), frame: craft_material_frame(_row.spice) });
		_d.owned = get_material_amount(_row.spice); _d.need = _row.ratio;
		_d.res_frame = holiday_warcard_frame(_row.star);
	}
	_d.gold = hal_batch_gold_of(_kind, _row);
	if (_d.gold > 0) array_push(_d.icons, { spr: spr_holiday_coin, frame: 0 });
	return _d;
}

/// @desc 弹窗里的配方行（和列表行同一套画法，只是换位置和缩放）
function hal_batch_draw_recipe(_cx, _cy, _RS, _n){
	var _d = hal_batch_recipe(hal_batch_kind, hal_batch_row);
	draw_sprite_ext(spr_holiday_row, 0, _cx, _cy, _RS, _RS, 0, c_white, 1);
	var _iy = _cy + 1 * _RS;
	for (var sl = 0; sl < 3; sl++){
		var _sx = _cx + hal_slot_dx[sl] * _RS;
		if (sl < array_length(_d.icons)){
			var _isc = (_d.icons[sl].spr == spr_holiday_coin) ? 0.96 : 0.52;
			draw_sprite_ext(_d.icons[sl].spr, _d.icons[sl].frame, _sx, _iy, _isc * _RS, _isc * _RS, 0, c_white, 1);
		}
		else draw_sprite_ext(spr_holiday_forbid, 0, _sx, _iy, 0.80 * _RS, 0.80 * _RS, 0, c_white, 1);
	}
	// 结果圆牌
	draw_sprite_ext(_d.res_spr, _d.res_frame, _cx + hal_circ_dx * _RS - 4 * _RS, _iy,
	                 0.52 * _RS, 0.52 * _RS, 0, c_white, 1);

	// 数字：第一格「拥有/需要」，金币格写金额
	draw_set_font(font_yuan);
	draw_set_valign(fa_middle);
	draw_set_halign(fa_right);
	var _red    = make_colour_rgb(226, 42, 32);
	var _need_n = _d.need * _n;                 // 2026-11-21：要换 N 次，需求也 ×N
	var _need_s = "/" + string(_need_n);
	var _own_s  = string(_d.owned);
	var _maxw   = 38 * _RS;
	var _sc     = min(0.95 * _RS, _maxw / max(1, string_width(_own_s + _need_s)));
	var _nx0    = _cx + (hal_slot_dx[0] + 21) * _RS;
	holiday_draw_num(_nx0 - string_width(_need_s) * _sc, _cy + 19 * _RS, _own_s, _sc,
	                  (_d.owned >= _need_n) ? c_white : _red);
	holiday_draw_num(_nx0, _cy + 19 * _RS, _need_s, _sc, c_white);
	if (_d.gold > 0){
		var _gold_n = _d.gold * _n;             // 金币也 ×N
		var _gs  = string(_gold_n);
		var _gsc = min(0.95 * _RS, _maxw / max(1, string_width(_gs)));
		holiday_draw_num(_cx + (hal_slot_dx[1] + 21) * _RS, _cy + 19 * _RS, _gs, _gsc,
		                  (global.save_data.player.gold >= _gold_n) ? c_white : _red);
	}
	// 结果圆牌下方写「×N」= 这次能换到几个（跟槽上数字同一套白字黑描边）
	draw_set_font(font_yuan);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	holiday_draw_num(_cx + (hal_circ_dx - 4) * _RS, _cy + 25 * _RS, "×" + string(_n), 0.5 * _RS);
}

/// @desc 批量兑换弹窗（画在最上层）
function hal_batch_draw(){
	var _px = hal_x, _py = hal_y, _S = hal_batch_S;
	draw_set_alpha(0.55);
	draw_rectangle_color(0, 0, room_width, room_height, c_black, c_black, c_black, c_black, false);
	draw_set_alpha(1);
	// 2026-11-21：底图最上面 20px 是一条纯黑半透明「投影带」（alpha 127 的死黑块），
	//   整张画出来就是那个黑框 → 用 draw_sprite_part_ext 裁掉，其余坐标不变
	var _pw = sprite_get_width(spr_holiday_pop), _ph = sprite_get_height(spr_holiday_pop);
	draw_sprite_part_ext(spr_holiday_pop, 0, 0, 20, _pw, _ph - 20,
	                      _px - (_pw * 0.5) * _S, _py - (_ph * 0.5 - 20) * _S, _S, _S, c_white, 1);

	// 标题条 + 关闭
	draw_sprite_ext(spr_holiday_batch, 0, _px, _py - 167, 1.35, 1.35, 0, c_white, 1);
	var _cr = hal_batch_rect(4);
	draw_sprite_ext(spr_holiday_close, (hal_batch_hover == 4) ? 1 : 0,
	                 (_cr[0] + _cr[2]) * 0.5, (_cr[1] + _cr[3]) * 0.5, 0.78, 0.78, 0, c_white, 1);

	// 配方行
	hal_batch_draw_recipe(_px, _py + 9, 2.2, hal_batch_n);

	// 减 / 加 / MAX
	var _mr = hal_batch_rect(0), _pr = hal_batch_rect(1), _xr = hal_batch_rect(2);
	var _s_can = hal_batch_n > 1, _p_can = hal_batch_n < hal_batch_max;
	var _mf = (_s_can && hal_batch_hover == 0) ? (mouse_check_button(mb_left) ? 2 : 1) : 0;
	var _pf = (_p_can && hal_batch_hover == 1) ? (mouse_check_button(mb_left) ? 2 : 1) : 0;
	draw_set_alpha(_s_can ? 1 : 0.35);
	draw_sprite_ext(spr_holiday_btn_minus, _mf, (_mr[0] + _mr[2]) * 0.5, (_mr[1] + _mr[3]) * 0.5, 1.1, 1.1, 0, c_white, 1);
	draw_set_alpha(1);
	draw_set_alpha(_p_can ? 1 : 0.35);
	draw_sprite_ext(spr_holiday_btn_plus, _pf, (_pr[0] + _pr[2]) * 0.5, (_pr[1] + _pr[3]) * 0.5, 1.1, 1.1, 0, c_white, 1);
	draw_set_alpha(1);
	draw_sprite_ext(spr_holiday_btn_max, (hal_batch_hover == 2) ? (mouse_check_button(mb_left) ? 2 : 1) : 0,
	                 (_xr[0] + _xr[2]) * 0.5, (_xr[1] + _xr[3]) * 0.5, 1.1, 1.1, 0, c_white, 1);

	// 输入框（兑换量 / 最大可兑换量；点一下可以键盘输入）
	var _ib = hal_batch_rect(5);
	var _edge = hal_batch_edit ? make_colour_rgb(255, 226, 120) : make_colour_rgb(122, 62, 40);
	// 这个运行时是 9 参版：x1,y1,x2,y2,xrad,yrad,col1,col2,outline
	draw_roundrect_colour_ext(_ib[0], _ib[1], _ib[2], _ib[3], 12, 12,
	                           make_colour_rgb(181, 96, 64), make_colour_rgb(150, 74, 48), false);
	draw_roundrect_colour_ext(_ib[0], _ib[1], _ib[2], _ib[3], 12, 12, _edge, _edge, true);
	draw_set_font(font_yuan);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_colour(c_white);
	var _txt;
	if (hal_batch_edit){
		_txt = (hal_batch_txt == "") ? "" : hal_batch_txt;
		if (current_time mod 900 < 450) _txt += "|";
	}
	else _txt = string(hal_batch_n) + "/" + string(hal_batch_max);
	draw_text_transformed((_ib[0] + _ib[2]) * 0.5, (_ib[1] + _ib[3]) * 0.5, _txt, 1.05, 1.05, 0);

	// 兑换按钮
	var _br = hal_batch_rect(3);
	var _bf = (hal_batch_hover == 3) ? (mouse_check_button(mb_left) ? 2 : 1) : 0;
	draw_sprite_ext(spr_holiday_btn_exchange, _bf, (_br[0] + _br[2]) * 0.5, (_br[1] + _br[3]) * 0.5, 1.25, 1.25, 0, c_white, 1);

	draw_set_colour(c_white);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

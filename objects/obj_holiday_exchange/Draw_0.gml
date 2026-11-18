/// 假期特惠 · 兑换 —— 绘制
/// 一行 = 底板 + 内容条 + 斜纹区里的「兑换」按钮；三格放不满的地方一律用禁止符占位
/// （卡包升星 / 融合剂：卡包 / 空 / 空；四叶草：草 / 金币 / 空；香料：香料 / 空 / 空）。
var S  = hal_s;
var BS = hal_bar_s;
var RS = hal_row_s;
var TS = hal_btn_s;

// 压暗背景（同 obj_gods_hall_bg）
draw_set_alpha(0.5);
draw_rectangle_color(0, 0, room_width, room_height, c_black, c_black, c_black, c_black, false);
draw_set_alpha(1);

draw_sprite_ext(spr_holiday_panel, 0, hal_x, hal_y, S, S, 0, c_white, 1);

// ── 页签：贴图自带「长期兑换 / 其他兑换」字样 ──
var _tabs = [spr_holiday_tab_long, spr_holiday_tab_other];
for (var t = 0; t < 2; t++){
	var _tx = hal_x + (t == 0 ? -hal_tab_dx : hal_tab_dx);
	draw_sprite_ext(_tabs[t], (hal_tab == t) ? 0 : 1, _tx, hal_tab_y, S, S, 0, c_white, 1);
}

// ── 行 ──
var _list  = (hal_tab == 0) ? hal_tab0 : hal_tab1;
var _len   = array_length(_list);
var _pages = max(1, ceil(_len / hal_per));
hal_page = clamp(hal_page, 0, _pages - 1);
var _start = hal_page * hal_per;

var _have_gold = variable_global_exists("save_data") ? global.save_data.player.gold : 0;

draw_set_font(font_yuan);
for (var k = 0; k < hal_per; k++){
	var _idx = _start + k;
	if (_idx >= _len) break;
	var _col = k mod 2;
	var _row = k div 2;
	var _ccx = hal_x + ((_col == 0) ? -hal_cell_dx : hal_cell_dx) * S;
	var _ccy = hal_y + (hal_row_y0 + _row * hal_row_dy) * S;
	var _rowx = _ccx + hal_row_off * BS;
	var _btnx = _ccx + hal_btn_off * BS;

	draw_sprite_ext(spr_holiday_bar, 0, _ccx, _ccy, BS, BS, 0, c_white, 1);
	draw_sprite_ext(spr_holiday_row, 0, _rowx, _ccy, RS, RS, 0, c_white, 1);

	// 按条目类型决定：占几个格、要不要金币、结果是什么
	var _it    = _list[_idx];
	var _icons = [];
	var _owned = 0;
	var _need  = 0;
	var _gold  = 0;
	var _can   = false;
	var _res_spr = spr_craft_material;
	var _res_frame = 0;
	if (_it.kind == "up"){
		var _c = _it.row;
		array_push(_icons, { spr: spr_craft_material, frame: holiday_warcard_frame(_c.star) });
		array_push(_icons, { spr: spr_holiday_coin, frame: 0 });   // 2026-11-21：升星要金币
		_owned = get_material_amount(_c.from);
		_need  = _c.need;
		_gold  = _c.gold;
		_can   = holiday_card_upgrade_max(_c) > 0;
		_res_frame = holiday_warcard_frame(_c.star + 1);
	} else if (_it.kind == "agent"){
		var _ag = _it.row;
		array_push(_icons, { spr: spr_craft_material, frame: holiday_warcard_frame(_ag.star) });
		_owned = get_material_amount(_ag.from);
		_need  = _ag.need;
		_can   = holiday_card_upgrade_max(_ag) > 0;
		_res_frame = get_material_info(_ag.to).icon;      // 融合剂图标（图集 45~47）
	} else if (_it.kind == "clover"){
		var _cl = _it.row;
		array_push(_icons, { spr: craft_material_spr(_cl.from), frame: craft_material_frame(_cl.from) });
		array_push(_icons, { spr: spr_holiday_coin, frame: 0 });
		_owned = get_material_amount(_cl.from);
		_need  = _cl.need;
		_gold  = _cl.gold;
		_can   = holiday_clover_upgrade_max(_cl) > 0;
		_res_spr = craft_material_spr(_cl.to);
		_res_frame = craft_material_frame(_cl.to);
	} else {
		var _r = _it.row;
		array_push(_icons, { spr: craft_material_spr(_r.spice), frame: craft_material_frame(_r.spice) });
		_owned = get_material_amount(_r.spice);
		_need  = _r.ratio;
		_can   = holiday_exchange_max(_r) > 0;
		_res_frame = holiday_warcard_frame(_r.star);
	}

	// 图标在格子里略微下移，避免上沿压到格框
	var _iy = _ccy + 1 * RS;
	for (var sl = 0; sl < 3; sl++){
		var _sx = _rowx + hal_slot_dx[sl] * RS;
		if (sl < array_length(_icons)){
			var _isc = (_icons[sl].spr == spr_holiday_coin) ? 0.96 : 0.52;
			draw_sprite_ext(_icons[sl].spr, _icons[sl].frame, _sx, _iy, _isc * RS, _isc * RS, 0, c_white, 1);
		} else {
			draw_sprite_ext(spr_holiday_forbid, 0, _sx, _iy, 0.80 * RS, 0.80 * RS, 0, c_white, 1);
		}
	}

	// 结果圆牌
	var _rx = _rowx + hal_circ_dx * RS - 4 * RS;
	draw_sprite_ext(_res_spr, _res_frame, _rx, _iy, 0.52 * RS, 0.52 * RS, 0, c_white, 1);

	// 数字：白字黑描边，贴在格子**内部**右下角；按实际字宽自动缩字号，保证不越出格子
	draw_set_valign(fa_middle);
	draw_set_halign(fa_right);
	var _red    = make_colour_rgb(226, 42, 32);
	var _need_s = "/" + string(_need);
	var _own_s  = string(_owned);
	var _full   = _own_s + _need_s;
	var _maxw   = 38 * RS;                                  // 格子内可用宽度（48 留出左右各 5 的边）
	var _sc     = min(0.95 * RS, _maxw / max(1, string_width(_full)));
	var _nx0    = _rowx + (hal_slot_dx[0] + 21) * RS;        // 格子右下角
	holiday_draw_num(_nx0 - string_width(_need_s) * _sc, _ccy + 19 * RS,
	                 _own_s, _sc, (_owned >= _need) ? c_white : _red);
	holiday_draw_num(_nx0, _ccy + 19 * RS, _need_s, _sc, c_white);

	if (_gold > 0){
		var _gs  = string(_gold);
		var _gsc = min(0.95 * RS, _maxw / max(1, string_width(_gs)));
		holiday_draw_num(_rowx + (hal_slot_dx[1] + 21) * RS, _ccy + 19 * RS, _gs, _gsc,
		                 (_have_gold >= _gold) ? c_white : _red);
	}

	// 兑换按钮：能换 = 原色三态；不能换 = 走 sh_fusion_gray 去色（黑白灰，同融合页未拥有）
	var _bh = point_in_rectangle(mouse_x, mouse_y, _btnx - 70 * TS, _ccy - 22 * TS, _btnx + 70 * TS, _ccy + 22 * TS);
	var _bf = _can ? (_bh ? (mouse_check_button(mb_left) ? 2 : 1) : 0) : 0;
	if (!_can) shader_set(sh_fusion_gray);
	draw_sprite_ext(spr_holiday_btn_exchange, _bf, _btnx, _ccy, TS, TS, 0, c_white, 1);
	if (!_can) shader_reset();
}

// 翻页条 + 箭头 + 页码
draw_sprite_ext(spr_holiday_pager, 0, hal_x, hal_pg_y, 1.55 * S, 1.45 * S, 0, c_white, 1);
var _lh = point_in_rectangle(mouse_x, mouse_y, hal_pg_lx - 16 * S, hal_pg_y - 16 * S, hal_pg_lx + 16 * S, hal_pg_y + 16 * S);
var _rh = point_in_rectangle(mouse_x, mouse_y, hal_pg_rx - 16 * S, hal_pg_y - 16 * S, hal_pg_rx + 16 * S, hal_pg_y + 16 * S);
var _lf = _lh ? (mouse_check_button(mb_left) ? 2 : 1) : 0;
var _rf = _rh ? (mouse_check_button(mb_left) ? 2 : 1) : 0;
draw_sprite_ext(spr_holiday_arrow, _lf, hal_pg_lx, hal_pg_y, -1.4 * S, 1.4 * S, 0, c_white, 1);
draw_sprite_ext(spr_holiday_arrow, _rf, hal_pg_rx, hal_pg_y, 1.4 * S, 1.4 * S, 0, c_white, 1);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(font_yuan);
draw_set_colour(c_white);
draw_text_transformed(hal_x, hal_pg_y, string(hal_page + 1) + "/" + string(_pages), 1.15 * S, 1.15 * S, 0);

// 关闭
var _ch = point_in_rectangle(mouse_x, mouse_y, hal_close.x, hal_close.y, hal_close.x + hal_close.w, hal_close.y + hal_close.h);
draw_sprite_ext(spr_holiday_close, _ch ? 1 : 0, hal_close.x + hal_close.w * 0.5, hal_close.y + hal_close.h * 0.5, S, S, 0, c_white, 1);

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_colour(c_white);
draw_set_alpha(1);

// 批量兑换弹窗画在最上层（2026-11-21）
if (hal_batch_open) hal_batch_draw();

/// 假期特惠 · 兑换（2026-11-20）
/// 四个板块：
///   ① 香料 → 强化用卡（旧料回收）：只做实际可获得的 7 档（2★ 上等 / 4★ 极品没有产出，不做）
///        1★ 天然 5 / 3★ 秘制 20 / 5★ 皇室 30 / 6★ 魔幻 35 / 7★ 精灵 50 / 8★ 天使 65 / 9★ 圣灵 90
///   ② 卡包升星：3 张 N★ + 金币 → 1 张 (N+1)★，只到 9★（1→2 … 8→9）
///   ③ 四叶草升阶：5 个低阶 + 金币 → 1 个高一阶（见 holiday_clover_upgrade_table）
///   ④ 融合剂：3 张 10/11/12★ 卡包 → 1 个初级/深度/灵魂融合剂
/// 界面：obj_holiday_exchange（长期兑换 = ②+③+④，其他兑换 = ①）
function holiday_exchange_table(){
	return [
		{ star:1, spice:"natural_spices",  card:"warcard_1", ratio:5  },
		{ star:3, spice:"secret_spices",   card:"warcard_3", ratio:20 },
		{ star:5, spice:"royal_spices",    card:"warcard_5", ratio:30 },
		{ star:6, spice:"magic_spices",    card:"warcard_6", ratio:35 },
		{ star:7, spice:"elf_spices",      card:"warcard_7", ratio:50 },
		{ star:8, spice:"angel_spices",    card:"warcard_8", ratio:65 },
		{ star:9, spice:"saint_spices",    card:"warcard_9", ratio:90 }
	];
}

/// @func holiday_exchange_max(row) 这一档当前最多能换几张
function holiday_exchange_max(_row){
	return floor(get_material_amount(_row.spice) / _row.ratio);
}

/// @func holiday_exchange_do(row, times) 换 N 张，返回实际换到的张数
///   扣香料 → 进卡包 → 写存档（跟商店同一套口径）
function holiday_exchange_do(_row, _times){
	var _can = holiday_exchange_max(_row);
	_times = clamp(_times, 0, _can);
	if (_times <= 0) return 0;
	add_material_amount(_row.spice, -_times * _row.ratio);
	add_material_amount(_row.card, _times);
	if (variable_global_exists("save_slot")) save_file(global.save_slot);
	return _times;
}

/// @func holiday_card_upgrade_table() 卡包升星表：3 张 N★ + 金币 → 1 张 (N+1)★
///   只做到 9★（1→2 … 8→9）：10★ 以上不掉落，只走跨服商店（12~15★ 是跨服专属）
///   金币 = 产物回收价 ÷ 2（warcard_2~9 回收价 300/450/400/600/1700/2800/5000/6000）
function holiday_card_upgrade_table(){
	// 金币 = 产物回收价 ÷ 2
	//   只做到 8→9：10★ 以上是跨服兑换的东西（12~15★ 只在跨服商店换），不在这里叠
	var _gold_of = [0, 150, 225, 200, 300, 850, 1400, 2500, 3000];
	var _t = [];
	for (var i = 1; i < 9; i++){
		array_push(_t, { star:i, from:"warcard_" + string(i), to:"warcard_" + string(i + 1),
		                 need:3, gold:_gold_of[i] });
	}
	return _t;
}

/// @func holiday_fusion_agent_table() 融合剂兑换：3 张卡包 → 1 个融合剂
///   2026-11-20 用户口径：10★ → 初级 / 11★ → 深度 / 12★ → 灵魂，比例统一 3 换 1
///   字段与卡包升星同构（star/from/to/need），所以 max / do 直接复用升星那两个函数
function holiday_fusion_agent_table(){
	return [
		{ star:10, from:"warcard_10", to:"fusion_basic", need:3 },
		{ star:11, from:"warcard_11", to:"fusion_deep",  need:3 },
		{ star:12, from:"warcard_12", to:"fusion_soul",  need:3 }
	];
}

/// @func holiday_card_upgrade_max(row) 这一档最多能升几次（受卡包数量和金币双重限制）
function holiday_card_upgrade_max(_row){
	var _n = floor(get_material_amount(_row.from) / _row.need);
	var _g = variable_struct_exists(_row, "gold") ? _row.gold : 0;
	if (_g > 0) _n = min(_n, floor(global.save_data.player.gold / _g));
	return _n;
}

/// @func holiday_card_upgrade_do(row, times) 升 N 次，扣 3N 张低星、给 N 张高星
function holiday_card_upgrade_do(_row, _times){
	var _can = holiday_card_upgrade_max(_row);
	_times = clamp(_times, 0, _can);
	if (_times <= 0) return 0;
	add_material_amount(_row.from, -_times * _row.need);
	add_material_amount(_row.to, _times);
	var _g = variable_struct_exists(_row, "gold") ? _row.gold : 0;
	if (_g > 0) global.save_data.player.gold -= _g * _times;
	if (variable_global_exists("save_slot")) save_file(global.save_slot);
	return _times;
}

/// @func holiday_clover_upgrade_table() 四叶草低阶升阶（5 个 + 金币 → 1 个高一阶）
///   2026-11-20 用户口径：5 个 1 级 + 2,000 金 → 1 个 2 级；5 个 2 级 + 1 万 → 1 个 3 级；
///   5 个 3 级 + 2 万 → 1 个 4 级；更高暂不开放
function holiday_clover_upgrade_table(){
	return [
		{ from:"clover_1", to:"clover_2", need:5, gold:2000  },
		{ from:"clover_2", to:"clover_3", need:5, gold:10000 },
		{ from:"clover_3", to:"clover_4", need:5, gold:20000 }
	];
}

/// @func holiday_clover_upgrade_max(row) 最多能升几次（受草数量和金币双重限制）
function holiday_clover_upgrade_max(_row){
	var _n = floor(get_material_amount(_row.from) / _row.need);
	return min(_n, floor(global.save_data.player.gold / _row.gold));
}

/// @func holiday_clover_upgrade_do(row, times) 升 N 次
function holiday_clover_upgrade_do(_row, _times){
	var _can = holiday_clover_upgrade_max(_row);
	_times = clamp(_times, 0, _can);
	if (_times <= 0) return 0;
	add_material_amount(_row.from, -_times * _row.need);
	add_material_amount(_row.to, _times);
	global.save_data.player.gold -= _times * _row.gold;
	if (variable_global_exists("save_slot")) save_file(global.save_slot);
	return _times;
}

/// @func holiday_draw_num(x, y, str, scale, face, edge)
/// 兑换行里的小数字：白字 + 黑描边，压在物品图标上也看得清。
/// 「不足」时 face 传红色。对齐跟随当前 draw_set_halign / draw_set_valign。
function holiday_draw_num(_x, _y, _str, _sc, _face, _edge){
	if (is_undefined(_face)) _face = c_white;        // 白字
	if (is_undefined(_edge)) _edge = c_black;        // 黑描边
	var _o = max(1, round(_sc));
	draw_set_colour(_edge);
	draw_text_transformed(_x - _o, _y, _str, _sc, _sc, 0);
	draw_text_transformed(_x + _o, _y, _str, _sc, _sc, 0);
	draw_text_transformed(_x, _y - _o, _str, _sc, _sc, 0);
	draw_text_transformed(_x, _y + _o, _str, _sc, _sc, 0);
	draw_set_colour(_face);
	draw_text_transformed(_x, _y, _str, _sc, _sc, 0);
}

/// @func holiday_warcard_frame(star) 强化用卡在图集 spr_craft_material 里的帧号
///   1~15★ 在图集里是**连续的帧 30~44**（29 + 星数）
function holiday_warcard_frame(_star){
	return 29 + _star;          // 图集重排后 1~15★ = 帧 30~44，连续
}

// ═════════════════════════════════════════════════════════════════════════
//  ⑤ 直接兑换型金卡（2026-11-24 用户定）
//     官方进化表里没有四条路线（冰神·典伊 / 宙斯 / 赫拉 / 潘多拉）→ 不走前置卡进化，改成直接兑换：
//     每张卡两条，三格 = 进化凭证 + 金币 + (威望 | 12★卡包)
//       · 威望版：给 0★ 本体（已有本体就换不了）
//       · 12卡包版：直接给 12★（已经 12★ 就不用换）
//     价格（用户 2026-11-24 定）：
//       金币   潘多拉 10 万 / 赫拉 15 万 / 宙斯 20 万 / 冰神 25 万（两版同价）
//       威望   潘多拉 2 万 / 赫拉 3 万 / 宙斯 5 万 / 冰神 6 万
//       卡包   12★ 各 3 张；凭证各 1 张（诸神商店 20~25 神石那张）
// ═════════════════════════════════════════════════════════════════════════

/// @func holiday_card_exchange_table() 8 条：每张卡「威望版（0★）、卡包版（12★）」各一条
function holiday_card_exchange_table(){
	return [
		{ card:"panduola_god", gold:100000, prestige: 20000, warcard:0, star: 0 },
		{ card:"panduola_god", gold:100000, prestige:     0, warcard:3, star:12 },
		{ card:"hera",         gold:150000, prestige: 30000, warcard:0, star: 0 },
		{ card:"hera",         gold:150000, prestige:     0, warcard:3, star:12 },
		{ card:"zeus",         gold:200000, prestige: 50000, warcard:0, star: 0 },
		{ card:"zeus",         gold:200000, prestige:     0, warcard:3, star:12 },
		{ card:"ice_god",      gold:250000, prestige: 60000, warcard:0, star: 0 },
		{ card:"ice_god",      gold:250000, prestige:     0, warcard:3, star:12 }
	];
}

/// @func holiday_card_save_level(card_id) 存档里这张卡的星级 index；没解锁返回 -1
function holiday_card_save_level(_id){
	var _uc = global.save_data.unlocked_cards;
	for (var i = 0; i < array_length(_uc); i++) if (_uc[i].id == _id) return _uc[i].level;
	return -1;
}

/// @func holiday_card_exchange_max(row) 这条现在能不能换（每张卡每种只换一次，所以返回 1 / 0）
///   威望版：已有本体就不能换；卡包版：已经到 12★ 就不能换
///   两张都吃 1 张进化凭证（二选一：换 0★ 或换 12★，不换 12★ 就自己强化上去）
function holiday_card_exchange_max(_row){
	var _lv = holiday_card_save_level(_row.card);
	if (_row.star <= 0){ if (_lv >= 0) return 0; }
	else { if (_lv >= _row.star) return 0; }

	if (get_material_amount(mod_evo_credit_id(_row.card)) < 1) return 0;
	if (global.save_data.player.gold < _row.gold) return 0;
	if (_row.warcard > 0){
		if (get_material_amount("warcard_12") < _row.warcard) return 0;
	} else {
		if (get_material_amount("prestige") < _row.prestige) return 0;
	}
	return 1;
}

/// @func holiday_card_exchange_do(row, times) 扣料 → 直接发卡（威望版 0★ / 卡包版 12★）
function holiday_card_exchange_do(_row, _times){
	var _n = min(_times, holiday_card_exchange_max(_row));
	if (_n <= 0) return 0;
	add_material_amount(mod_evo_credit_id(_row.card), -1);
	global.save_data.player.gold -= _row.gold;
	if (_row.warcard > 0) add_material_amount("warcard_12", -_row.warcard);
	else add_material_amount("prestige", -_row.prestige);
	unlock_card(_row.card, _row.star, 0, global.save_data.unlocked_items.max_skill_level);
	if (variable_global_exists("save_slot")) save_file(global.save_slot);
	return _n;
}

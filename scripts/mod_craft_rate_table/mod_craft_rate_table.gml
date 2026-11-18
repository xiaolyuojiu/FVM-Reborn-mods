/// 合成屋 · 强化（上卡）全部数值 + 判定 + 版式表
/// ---------------------------------------------------------------------------
/// **强化相关的一切数字只在本文件出现**，其余文件只调函数。
/// ---------------------------------------------------------------------------
/// 当前状态（2026-11-20 晚）
///   料：**1~15★ 全部用「X星强化用卡」**，香料已完全退出强化（只能去「假期特惠」兑换或直接回收）
///   消耗：卡包 1 张 = 1 槽，一次强化最多 3 张（craft_cost_table.slot_cost 只是显示兜底）
///   概率：成功率 = ① 矩阵基础率 × 草倍率  +  ② 失败补偿（每次 +2~4 点，封顶 15.4）
///         2026-11-20 改动：**「每次进游戏随机 3~6%」整段删除**，额外率只剩失败补偿（+2~3/次，封顶 15）
///         基础率仍是主来源，补偿只兜底
///   掉星：6★ 起失败掉 1 星；保险金挡掉料 + 挡掉星
/// 要调难度：改 craft_cost_table（金币/份数）、craft_assure_table（保险金）、edit_file 里的补偿函数
/// 详细推导见 桌面/fvm的ai/强化改造方案.md

// ── ① 原版成功率矩阵（Group2 好卡组，%）：行 = 当前星 0~15，列 = 用卡星 0~16 ──
//    抄自 compose.xml 的 <Upgrade><Group id="2">，一个数都不改
function craft_rate_matrix() {
	if (variable_global_exists("craft_rate_matrix_cache")) return global.craft_rate_matrix_cache;
	var _m = [
		[100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100],
		[ 88,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100,100],
		[60.8,79.2,96.8,100,100,100,100,100,100,100,100,100,100,100,100,100,100],
		[  0,42.9, 55,68.6,88,100,100,100,100,100,100,100,100,100,100,100,100],
		[  0,  0,24.2,40.3,49.5, 88,100,100,100,100,100,100,100,100,100,100,100],
		[  0,  0,  0,20.1, 33,39.6, 88,100,100,100,100,100,100,100,100,100,100],
		[  0,  0,  0,  0,13.2,26.4,31.9, 88,100,100,100,100,100,100,100,100,100],
		[  0,  0,  0,  0,  0,10.6,21.2,26.4, 88,100,100,100,100,100,100,100,100],
		[  0,  0,  0,  0,  0,  0,  6,13.2, 22, 88,100,100,100,100,100,100,100],
		[  0,  0,  0,  0,  0,  0,  0,2.2,4.5,13.5, 88,100,100,100,100,100,100],
		[  0,  0,  0,  0,  0,  0,  0,  0,1.8,4.6,12.5, 88,100,100,100,100,100],
		[  0,  0,  0,  0,  0,  0,  0,  0,  0,1.7,4.3,11.6, 88,100,100,100,100],
		[  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.6,  4,10.7, 88,100,100,100],
		[  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.4,3.7,10.1, 88,100,100],
		[  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.2,3.4,9.5, 88,100],
		[  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.1,  3,8.9, 88]
	];
	global.craft_rate_matrix_cache = _m;
	return _m;
}

// ── ② 香料档位（只记星级，概率全靠 ① 矩阵）────────────────────────────
//    顺序 = 背包第一行顺序 = spices_use_order
//    🔴 2026-11-19 定稿：前六档 2/4/6/8/10/11（魔幻下放到 11），原 12~15 各前移一位，
//       15★ 换新档「主宰」；16★ 没有 16★ 料（主宰在 16★ 只有 8.9%，是死档）
/// @desc 强化可用的料（**星级是主键**，不要按香料种类写死）
///   1~15★ = X星强化用卡（kind "warcard"，**1 个 = 1 槽**，不吃份数）
///   香料已于 2026-11-20 完全退出强化，只能在「假期特惠」里兑换成卡包或直接回收
///   16★ 没有 16 星卡，只能拿 15 星卡包硬推
function craft_spice_table() {
	if (variable_global_exists("craft_spice_table_cache")) return global.craft_spice_table_cache;
	var _m = [
		// 2026-11-20：1~9★ 也换成「X星强化用卡」，香料彻底退出强化（只留兑换/回收）
		{ id: "warcard_1",  star: 1,  kind: "warcard" },
		{ id: "warcard_2",  star: 2,  kind: "warcard" },
		{ id: "warcard_3",  star: 3,  kind: "warcard" },
		{ id: "warcard_4",  star: 4,  kind: "warcard" },
		{ id: "warcard_5",  star: 5,  kind: "warcard" },
		{ id: "warcard_6",  star: 6,  kind: "warcard" },
		{ id: "warcard_7",  star: 7,  kind: "warcard" },
		{ id: "warcard_8",  star: 8,  kind: "warcard" },
		{ id: "warcard_9",  star: 9,  kind: "warcard" },
		{ id: "warcard_10", star: 10, kind: "warcard" },
		{ id: "warcard_11", star: 11, kind: "warcard" },
		{ id: "warcard_12", star: 12, kind: "warcard" },
		{ id: "warcard_13", star: 13, kind: "warcard" },
		{ id: "warcard_14", star: 14, kind: "warcard" },
		{ id: "warcard_15", star: 15, kind: "warcard" }
	];
	global.craft_spice_table_cache = _m;
	return _m;
}

// ── ③ 每星每槽消耗 / ④ 金币（下标 = 目标星；slot_cost 0 = 该星不开强化）──
function craft_cost_table() {
	if (variable_global_exists("craft_cost_table_cache")) return global.craft_cost_table_cache;
	var _m = [
		{ slot_cost:   0, gold:     0 },
		{ slot_cost:   1, gold:   300 },
		{ slot_cost:   1, gold:   300 },
		{ slot_cost:   1, gold:   300 },
		{ slot_cost:   1, gold:   300 },
		{ slot_cost:   1, gold:   300 },
		{ slot_cost:   1, gold:   400 },
		{ slot_cost:   1, gold:   400 },
		{ slot_cost:   1, gold:   700 },
		{ slot_cost:   1, gold:   700 },
		{ slot_cost:   1, gold:  1300 },
		{ slot_cost:   1, gold:  2600 },
		{ slot_cost:   1, gold:  2600 },
		{ slot_cost:   1, gold:  5200 },
		{ slot_cost:   1, gold:  5200 },
		{ slot_cost:   1, gold: 10000 },
		{ slot_cost:   1, gold: 10000 }
	];
	global.craft_cost_table_cache = _m;
	return _m;
}

// ── ⑤ 四叶草倍率（"" = 不放 ×1.0）────────────────────────────────────
//    一草一料：1 级↔天然 / 2 级↔上等 / 3 级↔秘制 / 4 级↔极品（皇室也用 4 级）
//    5 级以上本轮不进关卡掉落，只留表位
function craft_clover_table() {
	return [
		{ id: "",            mult: 1.0 },
		{ id: "clover_1",    mult: 1.2 },
		{ id: "clover_2",    mult: 1.4 },
		{ id: "clover_3",    mult: 1.7 },
		{ id: "clover_4",    mult: 2.0 },
		{ id: "clover_5",    mult: 2.4 },
		{ id: "clover_6",    mult: 2.7 },
		{ id: "clover_s",    mult: 3.0 },
		{ id: "clover_ss",   mult: 3.2 },
		{ id: "clover_sss",  mult: 3.6 },
		{ id: "clover_ssr",  mult: 4.0 },
		{ id: "clover_snake",mult: 4.2 },
		{ id: "clover_horse",mult: 4.2 }
	];
}

// ── ⑥ 查表小工具 ────────────────────────────────────────────────────
function craft_spice_info(_id) {
	var _t = craft_spice_table();
	for (var i = 0; i < array_length(_t); i++) if (_t[i].id == _id) return _t[i];
	return undefined;
}
function craft_spice_star(_id) {
	var _i = craft_spice_info(_id);
	return is_undefined(_i) ? 0 : _i.star;
}
/// @desc 是不是「X星强化用卡」（1 个 = 1 槽，不按份数消耗）
function craft_is_warcard(_id) {
	var _i = craft_spice_info(_id);
	if (is_undefined(_i)) return false;
	return (_i.kind == "warcard");
}
/// @desc 该料用哪个精灵画（香料和卡包都走 spr_craft_material 图集，卡包是 icon 30~35）
function craft_material_spr(_id) {
	return spr_craft_material;
}
/// @desc 该料对应的帧（卡包 30~47、香料 0~18，全在图集里的 icon）
function craft_material_frame(_id) {
	// 卡包直接用 icon 当帧号（1~15★ 都是卡包）
	return get_material_info(_id).icon;
}
function craft_cost_info(_target) {
	return craft_cost_table()[clamp(_target, 0, 16)];
}
function craft_clover_mult(_id) {
	if (_id == "") return 1.0;
	var _t = craft_clover_table();
	for (var i = 0; i < array_length(_t); i++) if (_t[i].id == _id) return _t[i].mult;
	return 1.0;
}

// ── ⑦ 概率：查矩阵 + 三槽加权 + 草 ────────────────────────────────────
/// @desc 单槽%：矩阵[目标星−1][料星]，原版 0 就是 0
function craft_single_rate(_spice_id, _target) {
	var _m = craft_spice_star(_spice_id);
	if (_m <= 0 || _target < 1) return 0;
	var _row = craft_rate_matrix()[clamp(_target - 1, 0, 15)];
	return _row[clamp(_m, 0, 16)];
}
/// @desc 三槽加权：**权重只看放料星级，不看放在哪个槽**
///   🔴 系数 1（原版主槽）只给**星级最高**的那一份，其余每份固定 ⅓；
///      同星时按放入先后。所以「低星先放、高星后放」也不会把高星算成副槽，
///      槽位顺序/空槽留在中间都不会产生奇怪结果。
///   两个副槽权重都是 ⅓（1 + ⅓ + ⅓ = 5/3），封顶 100。
function craft_bare_rate(_slots, _target) {
	var _items = [];
	for (var i = 0; i < 3; i++) {
		var _id = (i < array_length(_slots)) ? _slots[i] : "";
		if (_id == "") continue;
		array_push(_items, { rate: craft_single_rate(_id, _target), star: craft_spice_star(_id) });
	}
	var _n = array_length(_items);
	// 星级降序（插入排序，同星保持原顺序）
	for (var i = 1; i < _n; i++) {
		var _v = _items[i], _j = i - 1;
		while (_j >= 0 && _items[_j].star < _v.star) {
			_items[_j + 1] = _items[_j];
			_j -= 1;
		}
		_items[_j + 1] = _v;
	}
	var _sum = 0;
	for (var i = 0; i < _n; i++) {
		_sum += _items[i].rate * ((i == 0) ? 1 : (1 / 3));
	}
	return min(100, _sum);
}

/// @desc 公式值 = 裸推 × 草倍率（封顶 100），补偿不吃草、另外加
function craft_total_rate(_slots, _target, _clover_id, _bonus) {
	var _v = min(100, craft_bare_rate(_slots, _target) * craft_clover_mult(_clover_id));
	if (is_undefined(_bonus)) _bonus = 0;
	return _v + _bonus;
}

/// @desc 只抹浮点尾巴，保留两位小数（45.426 → 45.43），**不是取整**
function craft_display_base(_v) { return round(_v * 100) / 100; }
/// @desc 判定率：基础 > 0 才算额外率，基础 0 整条无效
function craft_judge_rate(_v, _extra) {
	var _b = craft_display_base(_v);
	return (_b > 0) ? min(100, _b + _extra) : 0;
}
/// @desc 每次进游戏刷一次：3.00 ~ 5.99（两位小数）
/// @desc 界面文案：100% 不带加号；其余两位小数 + 额外率
function craft_rate_text(_base, _extra) {
	if (_base >= 100) return "100%";
	return string_format(_base, 1, 2) + "%+" + string_format(_extra, 1, 2) + "%";
}

// ── ⑨ 掉星 / 保险金 ─────────────────────────────────────────────────
/// @desc 6★ 起失败降 1 星（当前星 > 5 才掉）
function craft_can_drop(_current_level) { return _current_level > 5; }
/// @desc 下标 = 目标星 − 1，完全按原版 16 格 ×10 金币
function craft_assure_table() {
	return [
		0,        // 1★
		20,       // 2★
		50,       // 3★
		100,      // 4★
		250,      // 5★
		500,      // 6★
		2000,     // 7★
		4000,     // 8★
		12000,    // 9★
		50000,    // 10★（9→10，原版）
		// 12★ 定 30 万；13★ 起在原版上 +50%（高星不买会连环掉星，属于必买，往高收）
		//   10★ / 11★ 保持原版不动
		150000,   // 11★（10→11，原版）
		300000,   // 12★（11→12，原 25 万）
		450000,   // 13★（12→13）原 35 万
		600000,   // 14★ 原 45 万
		850000,   // 15★ 原 55 万
		1000000   // 16★ 原 75 万
	];
}
function craft_assure_cost(_target) {
	var _t = craft_assure_table();
	return _t[clamp(_target - 1, 0, array_length(_t) - 1)];
}
/// @desc 2★ 起可勾（1★ 价格 0 = 不画勾选框）
function craft_assure_available(_target) {
	return craft_assure_cost(_target) > 0;
}

// ── ⑩ 版式表：底部道具条（Draw 只按表画，Step 只按表判）────────────────
///   条内一行 10 格 × 84；格子贴图 spr_package_slot_bg 原点在**右下**(48,56)，49×57
///   图标按**格子中心**画（以前按格子右下角画 → 88px 图标塞 44px 格子，必然溢到隔壁格）
///   数字压在格子最下沿；页码在箭头正下方
function craft_bar_table() {
	return {
		x0: -752,
		row_y: 454,
		cell: 84,
		per_page: 10,
		scale: 0.9,
		cell_w: 49,
		cell_h: 57,
		icon_scale: 0.5,
		// 翻页箭头：**上下排列**（同一个 X），上 = 上一页、下 = 下一页
		//   2026-11-20 五次修正：整组箭头**再往下 10px**（上 -26 / 下 +10），用户嫌偏高
		arrow_x: 84,
		arrow_prev_y: -26,
		arrow_next_y: 10,
		arrow_scale: 1.5,
		page_tx: 84,
		page_ty: 34
	};
}
/// @desc 道具条**一整条**要显示的料（按「强化用卡 → 四叶草」顺排，只放 count > 0 的）
///       2026-11-19 用户口径：不分类型固定分页，就是一条长表按 10 格翻
///       2026-11-21：改读缓存 —— 每帧只在 craft_bar_sync() 里算一遍，Draw / Step 共用
function craft_bar_flat_ids() {
	if (!variable_global_exists("craft_bar_ids")) craft_bar_sync();
	return global.craft_bar_ids;   // 不再塞「不放」——点槽里的料就是取回
}
/// @desc 每帧调一次（obj_craft_bg 的 Step / Draw 开头）：重建要显示的料 + 每个料的显示数量
function craft_bar_sync() {
	var _ids = [];
	var _amt = {};
	var _sp = craft_spice_table();
	for (var i = 0; i < array_length(_sp); i++) {
		var _v = craft_bar_amount_raw(_sp[i].id);
		if (_v > 0) { array_push(_ids, _sp[i].id); _amt[$ _sp[i].id] = _v; }
	}
	var _cl = ["clover_1", "clover_2", "clover_3", "clover_4", "clover_5", "clover_6",
	           "clover_s", "clover_ss", "clover_sss", "clover_ssr", "clover_snake", "clover_horse"];
	for (var i = 0; i < array_length(_cl); i++) {
		var _v2 = craft_bar_amount_raw(_cl[i]);
		if (_v2 > 0) { array_push(_ids, _cl[i]); _amt[$ _cl[i]] = _v2; }
	}
	global.craft_bar_ids = _ids;
	global.craft_bar_amt = _amt;
}
/// @desc 道具条上该显示多少：**持有 − 已进槽的**（读缓存，缓存没建就先建一次）
///   进槽的料只是"假装没了"（真正扣料在点「强化」那一下）→ 放满就归 0、整格不显示；
///   退出面板 / 换卡 / 把槽里的料点出来 → 数量原样回来，**绝不会真丢**
function craft_bar_display_amount(_id) {
	if (!variable_global_exists("craft_bar_amt")) craft_bar_sync();
	return variable_struct_exists(global.craft_bar_amt, _id) ? global.craft_bar_amt[$ _id] : 0;
}
/// @desc 真实显示量（只在 craft_bar_sync 里调，别直接拿去画）
function craft_bar_amount_raw(_id) {
	var _amt = get_material_amount(_id);
	if (_amt <= 0) return 0;
	if (!instance_exists(obj_craft_bg)) return _amt;
	var _bg = obj_craft_bg;
	// 卡包：按 主→左→右 成功预扣掉的份数减
	var _T = 0;
	if (_bg.current_uprade_target_id != "") {
		var _cd = get_card_info_simple(_bg.current_uprade_target_id);
		if (_cd != false) _T = _cd.max_level + 1;
	}
	if (_T > 0) _amt -= craft_reserved_total(_bg.spice_slot, _T, _id);
	// 四叶草：进槽的那 1 个也算"没了"
	if (_bg.clover_slot == _id) _amt -= 1;
	return max(0, _amt);
}

/// @desc 总页数（至少 1 页）
function craft_bar_page_count() {
	var _t = craft_bar_table();
	return max(1, ceil(array_length(craft_bar_flat_ids()) / _t.per_page));
}
/// @desc 第 _page 页要画的料（切片；空位不补，Draw 只画有的）
function craft_bar_page_ids(_page) {
	var _t = craft_bar_table();
	var _all = craft_bar_flat_ids();
	var _from = _page * _t.per_page;
	var _out = [];
	for (var i = _from; i < min(_from + _t.per_page, array_length(_all)); i++) array_push(_out, _all[i]);
	return _out;
}
/// @desc 该页有没有内容
function craft_bar_page_has(_page) {
	return (_page >= 0) && (_page < craft_bar_page_count());
}
/// @desc 页名（箭头 tooltip 用）：看这一页第一个料是强化用卡还是草
function craft_bar_page_name(_page) {
	var _ids = craft_bar_page_ids(_page);
	if (array_length(_ids) == 0) return "";
	var _id = _ids[0];
	if (craft_is_warcard(_id)) return "强化用卡";
	return (craft_spice_star(_id) > 0) ? "强化用卡" : "四叶草";
}
/// @desc 翻一页：_dir = ±1，到头循环（只有 1 页时原地不动）
function craft_bar_next_page(_page, _dir) {
	var _n = craft_bar_page_count();
	if (_n <= 1) return _page;
	return ((_page + _dir) mod _n + _n) mod _n;
}

/// @desc 三个香料槽**实际进槽量**（按 主 → 左 → 右 顺序吃库存）
///   返回 [{take, avail, need, ok}]：take = 实际进槽量（= min(需求, 可用)），ok = 够不够这一槽。
///   **不够也照样预扣**（条里减到 0 就整格消失），槽上标红 avail/need 提示还缺多少。
///   🔴 只算「显示用预留」，真正扣料在 Mouse_4 点「强化」那一下。
function craft_slot_takes(_slots, _target) {
	var _cost = craft_cost_info(_target).slot_cost;
	var _used = {};
	var _out = [];
	for (var i = 0; i < 3; i++) {
		array_push(_out, { take: 0, avail: 0, need: _cost, ok: true });
	}
	// 吃库存的顺序 = 星级降序（和 craft_bare_rate 的主槽口径一致）：
	//   高星槽先拿满，缺口只会落在低星槽上（界面标红的那一格也和概率一致）
	var _order = [];
	for (var i = 0; i < 3; i++) {
		var _id = (i < array_length(_slots)) ? _slots[i] : "";
		if (_id != "") array_push(_order, { i: i, id: _id, star: craft_spice_star(_id) });
	}
	var _n = array_length(_order);
	for (var i = 1; i < _n; i++) {
		var _v = _order[i], _j = i - 1;
		while (_j >= 0 && _order[_j].star < _v.star) {
			_order[_j + 1] = _order[_j];
			_j -= 1;
		}
		_order[_j + 1] = _v;
	}
	for (var i = 0; i < _n; i++) {
		var _o = _order[i];
		var _u = variable_struct_exists(_used, _o.id) ? variable_struct_get(_used, _o.id) : 0;
		var _avail = max(0, get_material_amount(_o.id) - _u);
		var _need = craft_is_warcard(_o.id) ? 1 : _cost;   // 卡包 1 个 = 1 槽
		var _ok = (_avail >= _need);
		var _take = min(_need, _avail);          // 有多少先算多少（不够也照样从条里减到 0）
		if (_take > 0) variable_struct_set(_used, _o.id, _u + _take);
		_out[_o.i] = { take: _take, avail: _avail, need: _need, ok: _ok };
	}
	return _out;
}
/// @desc 某个料被三槽「预扣」掉的总量（道具条显示 持有−预扣）
function craft_reserved_total(_slots, _target, _id) {
	var _takes = craft_slot_takes(_slots, _target);
	var _sum = 0;
	for (var i = 0; i < 3; i++){
		if (_slots[i] == _id) _sum += _takes[i].take;
	}
	return _sum;
}

// ── ⑪ 强化说明 / 一键强化弹窗（2026-11-19 用户口径改文案）──────────────
/// @desc 强化说明正文（一行一条；"" = 空行分段）。文案由用户口述，别自行精简
function craft_help_lines() {
	return [
		"右侧选择强化卡，点击下列强化用卡填充材料，道具页可换页。",
		"卡包每槽固定 1 张，一次强化最多 3 张，星级越高成功率越低。",
		"强化成功升 1 星，失败掉 1 星。",
		"",
		"四叶草：可用于增加强化倍率，点击放入。",
		"",
		"保险金：失败时保护用卡不消耗、卡片不掉星级，",
		"开启保险金后连续失败时会提高成功率。"
	];
}
/// @desc 「强化说明」弹窗的确定按钮矩形（面板居中偏下）
function craft_help_rect() {
	var _cx = room_width * 0.5;
	var _cy = room_height * 0.5 + 196;
	var _hw = sprite_get_width(spr_common_button) * 0.75;
	var _hh = sprite_get_height(spr_common_button) * 0.75;
	return [_cx - _hw, _cy - _hh, _cx + _hw, _cy + _hh];
}
/// @desc 说明弹窗（面板 spr_battle_escape_menu 2.6 倍 ≈ 848×515）
///   🔴 正文用 draw_text_ext 自动折行（2026-11-19 实机：手写死行宽会顶出面板右边）
function craft_help_draw(_hover) {
	var _px = room_width * 0.5, _py = room_height * 0.5;
	draw_set_alpha(0.55);
	draw_rectangle_color(0, 0, room_width, room_height, c_black, c_black, c_black, c_black, false);
	draw_set_alpha(1);
	draw_sprite_ext(spr_battle_escape_menu, 0, _px, _py, 2.6, 2.6, 0, c_white, 1);

	draw_set_font(font_yuan);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	// 标题：1.7 倍 + 四向描边（假粗体），实机看着才够醒目
	draw_set_colour(c_black);
	draw_text_transformed(_px - 1, _py - 206, "强化说明", 1.6, 1.6, 0);
	draw_text_transformed(_px + 1, _py - 206, "强化说明", 1.6, 1.6, 0);
	draw_text_transformed(_px, _py - 207, "强化说明", 1.6, 1.6, 0);
	draw_text_transformed(_px, _py - 205, "强化说明", 1.6, 1.6, 0);
	draw_set_colour(c_white);
	draw_text_transformed(_px, _py - 206, "强化说明", 1.6, 1.6, 0);

	var _lines = craft_help_lines();
	var _wrap = 700;
	var _sep = 26;
	// 2026-11-21：整块正文在「标题下沿 ~ 按钮上沿」之间垂直居中，每行再水平居中
	var _blk = 0;
	for (var i = 0; i < array_length(_lines); i++) {
		_blk += (_lines[i] == "") ? 10 : string_height_ext(_lines[i], _sep, _wrap) + 6;
	}
	var _sy = _py - _blk * 0.5;        // 标题下沿 ~ 按钮上沿 的中间（±172）
	draw_set_halign(fa_center);
	for (var i = 0; i < array_length(_lines); i++) {
		if (_lines[i] == "") { _sy += 10; continue; }
		if (string_width_ext(_lines[i], _sep, _wrap) <= _wrap) draw_text_ext(_px, _sy, _lines[i], _sep, _wrap);
		else {   // 万一超宽：这一行退回左对齐（从 _px-350 起折行），至少不出框
			draw_set_halign(fa_left);
			draw_text_ext(_px - _wrap * 0.5, _sy, _lines[i], _sep, _wrap);
			draw_set_halign(fa_center);
		}
		_sy += string_height_ext(_lines[i], _sep, _wrap) + 6;
	}

	var _r  = craft_help_rect();
	var _bx = (_r[0] + _r[2]) * 0.5, _by = (_r[1] + _r[3]) * 0.5;
	var _fr = _hover ? (mouse_check_button(mb_left) ? 2 : 1) : 0;
	mod_ui_common_btn_draw(_fr, _bx, _by, 0.75);
	draw_set_halign(fa_center);
	draw_set_colour(c_white);
	draw_text(_bx, _by, "确定");

	draw_set_colour(c_white);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

/// @desc 「一键强化」弹窗：主要说明 + **红字**警告（2026-11-19 用户口径）
function craft_onekey_lines() {
	return [
		"自动计算四叶草和强化用卡，",
		"在 100% 成功的情况下强化至最大可强化星级。"
	];
}
/// @desc 弹窗正文：整块垂直居中后逐行画（介绍 / 消耗预览共用）；返回末行底部 y，接着画红字
function craft_onekey_text_block(_lines, _x, _py, _wrap, _sep) {
	var _blk = 0;
	for (var i = 0; i < array_length(_lines); i++) _blk += string_height_ext(_lines[i], _sep, _wrap);
	var _sy = _py - (_blk + 40) * 0.5;
	for (var i = 0; i < array_length(_lines); i++){
		draw_text_ext(_x, _sy, _lines[i], _sep, _wrap);
		_sy += string_height_ext(_lines[i], _sep, _wrap);
	}
	return _sy;
}
/// @desc 「X星×N / X星×N」按宽度分行使，**按件数均分**（别出现最后一行只剩 1 件）
/// @param _first 首行前缀（续行不带），@return 行数组（每行都已塞好，不用再折行）
function craft_onekey_pack(_first, _items, _wrap) {
	var _n = array_length(_items);
	if (_n == 0) return [_first];
	var _full = _first;
	for (var i = 0; i < _n; i++) _full += ((i == 0) ? "" : "/") + _items[i];
	var _rows = min(_n, max(1, ceil(string_width(_full) / _wrap)));
	var _base = floor(_n / _rows);             // 每行至少几件（用 floor，别用 div：ceil 出来的是实数）
	var _extra = _n - _base * _rows;           // 前 _extra 行各多一件（7 件 2 行 = 4+3，不是 5+2）
	var _out = [];
	var _i = 0;
	for (var r = 0; r < _rows; r++){
		var _cnt  = _base + ((r < _extra) ? 1 : 0);
		var _line = (r == 0) ? _first : "";
		for (var k = 0; k < _cnt; k++){
			if (k > 0) _line += "/";
			_line += _items[_i];
			_i += 1;
		}
		array_push(_out, _line);
	}
	return _out;
}
/// @desc 确定 / 取消 两个按钮的矩形（0 = 确定 / 1 = 取消）
function craft_onekey_rect(_i) {
	var _cx = room_width * 0.5 + ((_i == 0) ? -80 : 80);
	var _cy = room_height * 0.5 + 140;
	var _hw = sprite_get_width(spr_common_button) * 0.75;
	var _hh = sprite_get_height(spr_common_button) * 0.75;
	return [_cx - _hw, _cy - _hh, _cx + _hw, _cy + _hh];
}
function craft_onekey_draw(_hover, _stage = 0, _plan = undefined) {
	var _px = room_width * 0.5, _py = room_height * 0.5;
	draw_set_alpha(0.55);
	draw_rectangle_color(0, 0, room_width, room_height, c_black, c_black, c_black, c_black, false);
	draw_set_alpha(1);
	draw_sprite_ext(spr_battle_escape_menu, 0, _px, _py, 2.0, 2.0, 0, c_white, 1);

	draw_set_font(font_yuan);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	var _ttl = (_stage == 1) ? "消耗预览" : "一键强化";
	var _ty  = _py - 150;          // 2026-11-21 用户口径：标题再往上（-128 实机偏下）
	draw_set_colour(c_black);
	draw_text_transformed(_px - 1, _ty, _ttl, 1.5, 1.5, 0);
	draw_text_transformed(_px + 1, _ty, _ttl, 1.5, 1.5, 0);
	draw_text_transformed(_px, _ty - 1, _ttl, 1.5, 1.5, 0);
	draw_text_transformed(_px, _ty + 1, _ttl, 1.5, 1.5, 0);
	draw_set_colour(c_white);
	draw_text_transformed(_px, _ty, _ttl, 1.5, 1.5, 0);

	draw_set_halign(fa_left);
	var _wrap = 470;
	var _sep  = 28;

	if (_stage == 1 && !is_undefined(_plan)){
		// ── 消耗预览（2026-11-21 用户口径）：一行一件事，「X星×N/X星×N」用 / 串起来，
		//    不再每样料占一行（原来 11 行会把面板撑爆、红字掉到框外）
		var _mats = [];
		var _mk = variable_struct_get_names(_plan.mats);
		for (var i = 0; i < array_length(_mk); i++){
			array_push(_mats, string(craft_spice_star(_mk[i])) + "星×" + string(_plan.mats[$ _mk[i]]));
		}
		var _clvs = [];
		var _ck = variable_struct_get_names(_plan.clovers);
		for (var i = 0; i < array_length(_ck); i++){
			// 名字去掉「四叶草」三个字：「1级四叶草」→「1级」
			array_push(_clvs, string_replace(get_material_info(_ck[i]).name, "四叶草", "")
			               + "×" + string(_plan.clovers[$ _ck[i]]));
		}

		var _lines = ["本次最高可强化至" + string(_plan.to) + "星"];
		_lines = array_concat(_lines, craft_onekey_pack("消耗强化用卡：", _mats, 500));
		_lines = array_concat(_lines, craft_onekey_pack("四叶草：", (array_length(_clvs) == 0) ? ["无"] : _clvs, 500));
		array_push(_lines, "金币：" + string(_plan.gold));

		var _end = craft_onekey_text_block(_lines, _px - 250, _py, 500, _sep);
		draw_set_colour(c_red);
		draw_text_ext(_px - 250, _end + 16, "确定后立即扣除并强化，不可撤销。", _sep, 500);
	}
	else{
		// ── 介绍 ──
		var _end = craft_onekey_text_block(craft_onekey_lines(), _px - 250, _py, _wrap, _sep);
		draw_set_colour(c_red);
		draw_text_ext(_px - 250, _end + 16, "该功能不完美，可能造成浪费现象。", _sep, _wrap);
	}

	for (var _i = 0; _i < 2; _i++) {
		var _r  = craft_onekey_rect(_i);
		var _bx = (_r[0] + _r[2]) * 0.5, _by = (_r[1] + _r[3]) * 0.5;
		var _fr = (_hover == _i) ? (mouse_check_button(mb_left) ? 2 : 1) : 0;
		mod_ui_common_btn_draw(_fr, _bx, _by, 0.75);
		draw_set_colour(c_white);
		draw_set_halign(fa_center);
		var _txt = (_i == 0) ? ((_stage == 1) ? "确定强化" : "确定") : "取消";
		draw_text(_bx, _by, _txt);
	}

	draw_set_colour(c_white);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

// ── ⑬ 一键强化：方案计算 / 执行（2026-11-21 实装）────────────────────────
/// @func craft_onekey_plan(card_id) 算出一键强化的完整计划
///   规则（用户口径）：
///     ① 每一步都必须 **100% 成功**，不到 100% 不做；
///     ② 草从低级往高级试，够了就不用更贵的；
///     ③ 料档 × 张数 × 草 的所有组合里，取「回收价总和最低」的那套；
///     ④ 连续往上，直到材料 / 金币不够或到 16★；
///     ⑤ **只算基础率**：craft_total_rate 的 bonus 恒传 0，
///        失败补偿 / 宝石额外率一律不计入（要吃补偿的只有手动那条路）。
///   全程用本地库存副本推演，不改存档。
/// @return { ok, reason, steps[], from, to, gold, mats, clovers }
function craft_onekey_plan(_card_id){
	var _r = { ok:false, reason:"", steps:[], from:0, to:0, gold:0, mats:{}, clovers:{} };
	if (_card_id == ""){ _r.reason = "请先选择一张强化卡"; return _r; }
	var _cd = get_card_info_simple(_card_id);
	if (_cd == false){ _r.reason = "找不到这张卡"; return _r; }
	if (instance_exists(obj_craft_confirm_btn)
	 && array_get_index(obj_craft_confirm_btn.cannot_upgrade_card_list, _card_id) != -1){
		_r.reason = "该卡片无法被强化"; return _r;   // 和手动强化同一份黑名单，别让一键绕过去
	}
	_r.from = _cd.max_level;
	if (_r.from >= 16){ _r.reason = "已经是 16★，无法继续强化"; return _r; }

	var _gold = global.save_data.player.gold;
	var _inv  = {};
	var _st   = craft_spice_table();
	for (var i = 0; i < array_length(_st); i++) _inv[$ _st[i].id] = get_material_amount(_st[i].id);
	var _ct = craft_clover_table();
	for (var i = 0; i < array_length(_ct); i++){
		if (_ct[i].id != "") _inv[$ _ct[i].id] = get_material_amount(_ct[i].id);
	}
	var _cost_tbl = craft_cost_table();

	var _lv  = _r.from;
	var _why = "";
	while (_lv < 16){
		var _T = _lv + 1;
		var _gold_need = _cost_tbl[clamp(_T, 0, array_length(_cost_tbl) - 1)].gold;
		if (_gold < _gold_need){
			_why = "金币不足：升 " + string(_T) + "★ 需要 " + string(_gold_need);
			break;
		}

		var _best = undefined;
		for (var _m = 0; _m < array_length(_st); _m++){   // 跟表走，不拼 id；顺序即星级升序
			var _mid  = _st[_m].id;
			var _have = _inv[$ _mid];
			if (_have <= 0) continue;
			for (var _n = 1; _n <= min(3, _have); _n++){
				var _slots = [];
				for (var _k = 0; _k < _n; _k++) array_push(_slots, _mid);
				for (var _c = 0; _c < array_length(_ct); _c++){
					var _cid = _ct[_c].id;
					if (_cid != "" && _inv[$ _cid] <= 0) continue;
					if (craft_total_rate(_slots, _T, _cid, 0) < 99.999) continue;
					var _cost = get_material_sell_price(_mid) * _n;
					if (_cid != "") _cost += get_material_sell_price(_cid);
					if (is_undefined(_best) || _cost < _best.cost){
						_best = { mat:_mid, n:_n, clover:_cid, cost:_cost };
					}
					break;   // 草按倍率升序，第一个 100% 就是这套料最省的草
				}
			}
		}
		if (is_undefined(_best)){
			_why = "材料不足，凑不出 100% 成功的方案";
			break;
		}

		_inv[$ _best.mat] -= _best.n;
		if (_best.clover != "") _inv[$ _best.clover] -= 1;
		_gold -= _gold_need;
		array_push(_r.steps, { target:_T, mat:_best.mat, mat_n:_best.n, clover:_best.clover, gold:_gold_need });
		_lv = _T;
	}

	if (array_length(_r.steps) == 0){
		_r.reason = (_why != "") ? _why : "材料不足，凑不出 100% 成功的方案";
		return _r;
	}
	_r.ok   = true;
	_r.to   = _lv;
	_r.gold = global.save_data.player.gold - _gold;
	for (var i = 0; i < array_length(_r.steps); i++){
		var _s = _r.steps[i];
		_r.mats[$ _s.mat] = (variable_struct_exists(_r.mats, _s.mat) ? _r.mats[$ _s.mat] : 0) + _s.mat_n;
		if (_s.clover != ""){
			_r.clovers[$ _s.clover] = (variable_struct_exists(_r.clovers, _s.clover) ? _r.clovers[$ _s.clover] : 0) + 1;
		}
	}
	return _r;
}

/// @func craft_onekey_apply(card_id, plan) 按计划落账：扣料 → 扣金币 → 升星 → 存档一次
///   只吃 craft_onekey_plan 的返回值；调用前必须再确认一次库存和金币（防预览期间被改）
function craft_onekey_apply(_card_id, _plan){
	if (!_plan.ok) return false;
	var _cd = get_card_info_simple(_card_id);
	if (_cd == false) return false;                                  // 卡不在了就别扣
	if (_cd.max_level != _plan.from) return false;                    // 星级在预览后变了：upgrade_card 是直接赋值，拿旧计划硬写会降星
	var _st = _plan.steps;
	for (var i = 0; i < array_length(_st); i++){
		if (get_material_amount(_st[i].mat) < _st[i].mat_n) return false;
		if (_st[i].clover != "" && get_material_amount(_st[i].clover) < 1) return false;
	}
	if (global.save_data.player.gold < _plan.gold) return false;

	for (var i = 0; i < array_length(_st); i++){
		add_material_amount(_st[i].mat, -_st[i].mat_n);
		if (_st[i].clover != "") add_material_amount(_st[i].clover, -1);
	}
	global.save_data.player.gold -= _plan.gold;
	upgrade_card(_card_id, _plan.to, false);
	// 每步都是 100%，等价于手动强化「一次必成」：补偿清零、连败计数清零，别留到下次手动用
	reset_craft_fail_bonus();
	if (variable_global_exists("craft_lose_streak")) global.craft_lose_streak = 0;
	save_file(global.save_slot);
	return true;
}

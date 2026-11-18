// ══════════════════════════════════════════════════════════════════════
// 跨服远征 · 关卡星级门槛
//   castle-0 → 8 星，castle-1 → 9 星，……，castle-7 → 15 星
//   判定依据：背包（unlocked_cards）中已有卡片的最高星级。
//   注意星级是 unlocked_cards[].level，不是 shape（shape 是转职形态）。
// ══════════════════════════════════════════════════════════════════════

/// @function cross_server_star_require(_level_index)
/// @desc 跨服第 _level_index 关（castle-0 起）要求的卡片最高星级：8 星起每关 +1。
function cross_server_star_require(_level_index) {
    return 8 + max(0, _level_index);
}

/// @function save_data_max_card_star()
/// @desc 背包中已有卡片的最高星级。老存档可能缺 level / max_level 字段，逐个兜底。
function save_data_max_card_star() {
    if (!variable_global_exists("save_data")) return 0;
    if (!variable_struct_exists(global.save_data, "unlocked_cards")) return 0;

    var _cards = global.save_data.unlocked_cards;
    if (!is_array(_cards)) return 0;

    var _max = 0;
    for (var _i = 0; _i < array_length(_cards); _i++) {
        var _c = _cards[_i];
        if (!is_struct(_c)) continue;
        var _lv = 0;
        if (variable_struct_exists(_c, "level")) _lv = real(_c.level);
        // max_level 是历史最高，卡片被消耗/重铸过也不会把门槛拉回去
        if (variable_struct_exists(_c, "max_level")) _lv = max(_lv, real(_c.max_level));
        if (_lv > _max) _max = _lv;
    }
    return _max;
}

/// @function cross_server_star_gate(_level_index)
/// @desc true = 星级达标，可以进入。不达标时由调用方 show_notice 提示。
function cross_server_star_gate(_level_index) {
    return save_data_max_card_star() >= cross_server_star_require(_level_index);
}

/// @function cross_server_star_gate_text(_level_index)
/// @desc 星级不足时的提示文案（show_notice 用 font_yuan，文案已比对字形表）。
function cross_server_star_gate_text(_level_index) {
    return "背包中没有" + string(cross_server_star_require(_level_index)) + "星卡片，无法进入";
}

// ══════════════════════════════════════════════════════════════════════
// 跨服远征 · 「已通关到几星」查询（跨服商店的卡包解锁用，2026-11-21）
//   关卡序号 → 星级走的是 entering 用的同一套 cross_server_star_require()，
//   所以 castle-0 = 8★、castle-2 = 10★、castle-4 = 12★ … castle-7 = 15★
//   任意一章通关都算（每章内部本身按 pre_level 顺序解锁，过 12★ 必已过 10★）
// ══════════════════════════════════════════════════════════════════════

/// @function cross_server_cleared_star_max()
/// @desc 已通关的跨服关卡里最高的星级（8~15）。一关没通返回 0。
function cross_server_cleared_star_max() {
    if (!variable_global_exists("save_data")) return 0;
    if (!variable_struct_exists(global.save_data, "completed_levels")) return 0;
    var _done = global.save_data.completed_levels;
    if (!is_array(_done)) return 0;

    var _max = 0;
    for (var _i = 0; _i < array_length(_done); _i++) {
        var _id = _done[_i];
        if (!is_string(_id)) continue;
        var _idx = cross_server_level_index(_id);     // 非跨服关卡 = -1
        if (_idx < 0) continue;
        var _star = cross_server_star_require(_idx);
        if (_star > _max) _max = _star;
    }
    return _max;
}

/// @function cross_server_stage_star_met(_star, _max)
/// @desc 跨服进度是否达到 _star 星（_star <= 0 = 无门槛，恒 true）
///   商店逐格调用时把已算好的 cross_server_cleared_star_max() 传进来，别每帧重扫完成表
function cross_server_stage_star_met(_star, _max = undefined) {
    if (_star <= 0) return true;
    if (is_undefined(_max)) _max = cross_server_cleared_star_max();
    return _max >= _star;
}

/// @function cross_server_stage_star_text(_star)
/// @desc 进度不足时的完整提示（商店点击用；格子里用短句「需通关12★」）
function cross_server_stage_star_text(_star) {
    return "需通关跨服" + string(_star) + "★关卡";
}

/// @function is_gacha_mode()
/// @desc 当前是否为抽卡版或欧皇版
function is_gacha_mode() {
    return global.play_mode == 1 || global.play_mode == 2;
}

/// @function is_random_gift_mode()
/// @desc 当前是否为随机礼盒玩法
function is_random_gift_mode() {
    return global.play_mode == 3;
}

/// @function play_mode_of_key(_key)
/// @desc 设置页开关的 config_key -> 玩法模式号。0 = 不是玩法开关
///       模式号：1 抽卡 / 2 欧皇 / 3 随机礼盒 / 4 海克斯
function play_mode_of_key(_key) {
    if (_key == "play_mode_gacha") return 1;
    if (_key == "play_mode_lucky") return 2;
    if (_key == "play_mode_gift")  return 3;
    if (_key == "play_mode_hex")   return 4;
    return 0;
}

/// @function play_mode_apply(_mode)
/// @desc 玩法模式唯一写入口：同时写 global.play_mode 与 config.ini（下次启动由
///       obj_game_init 读回），并处理「进出海克斯本局作废」与礼盒卡组同步。
///       四种玩法互斥是靠「play_mode 只有一个数」保证的，所以任何地方改玩法都必须走这里。
function play_mode_apply(_mode) {
    _mode = clamp(round(_mode), 0, 4);
    var _old = variable_global_exists("play_mode") ? global.play_mode : 0;
    global.play_mode = _mode;

    ini_open("config.ini");
    ini_write_real("settings", "play_mode", _mode);
    ini_close();

    if (_old == _mode) return _mode;

    // 进出海克斯模式：本局词条一律作废（docs 1.2.2）
    if (_old == 4 || _mode == 4) hex_reset_run();

    // 抽卡 / 欧皇 / 随机礼盒：同步礼盒卡的解锁状态与卡组
    if (_old == 1 || _old == 2 || _old == 3 || _mode == 1 || _mode == 2 || _mode == 3) {
        random_gift_sync_unlock();
        if (variable_global_exists("selected_deck") && ds_exists(global.selected_deck, ds_type_list)) {
            random_gift_prepare_selected_deck();
        }
    }
    return _mode;
}

/// @function random_gift_sync_unlock()
/// @desc 根据当前玩法同步随机礼盒的存档解锁状态。
function random_gift_sync_unlock() {
    if (!variable_global_exists("save_data") || !is_array(global.save_data.unlocked_cards)) return;
    var _lihe_index = -1;
    for (var i = 0; i < array_length(global.save_data.unlocked_cards); i++) {
        if (global.save_data.unlocked_cards[i].id == "lihe") {
            _lihe_index = i;
            break;
        }
    }
    if (is_random_gift_mode()) {
        if (_lihe_index == -1) {
            array_push(global.save_data.unlocked_cards,
                {id: "lihe", level: 0, shape: 0, skill: 0, max_level: 0, max_shape: 0});
            card_info_task_sync("lihe");
        } else if (global.save_data.unlocked_cards[_lihe_index].level == 0
            && global.save_data.unlocked_cards[_lihe_index].max_level == 16) {
            global.save_data.unlocked_cards[_lihe_index].max_level = 0;
        }
    } else if (_lihe_index != -1) {
        array_delete(global.save_data.unlocked_cards, _lihe_index, 1);
    }
}

/// @function random_gift_is_direct_card_allowed(card_id)
/// @desc 随机礼盒模式下允许玩家直接带入卡组的卡片
function random_gift_is_direct_card_allowed(card_id) {
    if (card_id == "lihe") return true;
    return array_get_index([
        "wooden_plate", "wooden_cork", "cotton_candy", "sausage",
        "oil_lamp", "soda_bubble", "tang_hu_lu", "double_water_pipe", "wanpilong"
    ], card_id) != -1;
}

/// @function random_gift_prepare_selected_deck()
/// @desc 清理随机礼盒模式下不允许直接使用的卡，并确保至少有一张礼盒
function random_gift_prepare_selected_deck() {
    if (!is_random_gift_mode()) return;
    random_gift_sync_unlock();
    // The gift mode grants Wanpilong's third shape at battle start.
    var _wanpilong_unlocked = false;
    for (var _ui = 0; _ui < array_length(global.save_data.unlocked_cards); _ui++) {
        if (global.save_data.unlocked_cards[_ui].id == "wanpilong") {
            global.save_data.unlocked_cards[_ui].shape = 2;
            global.save_data.unlocked_cards[_ui].max_shape = max(global.save_data.unlocked_cards[_ui].max_shape, 2);
            _wanpilong_unlocked = true;
            break;
        }
    }
    if (!_wanpilong_unlocked) array_push(global.save_data.unlocked_cards,
        {id: "wanpilong", level: 0, shape: 2, skill: 0, max_level: 0, max_shape: 2});
    card_info_task_sync("wanpilong");
    deck_ensure_size();
    var has_gift = false;
    var has_wanpilong = false;
    for (var i = 0; i < ds_list_size(global.selected_deck); i++) {
        if (deck_slot_is_empty(i)) continue;
        var entry = global.selected_deck[| i];
        var card_id = entry[? "card_id"];
        if (!random_gift_is_direct_card_allowed(card_id)) {
            remove_from_deck(i);
        } else if (card_id == "lihe") {
            has_gift = true;
        } else if (card_id == "wanpilong") {
            entry[? "shape"] = 2;
            entry[? "data"] = deck_get_card_data("wanpilong", 2);
            has_wanpilong = true;
        }
    }
    if (!has_gift) add_to_deck("lihe", 0);
    if (!has_wanpilong) add_to_deck("wanpilong", 2);
}

/// @function difficulty_reward_progress_tier()
/// @desc 通关进度决定能吃到几倍：
///       打通神殿 = 2 / 深渊 = 3 / 雪顶火山 = 4 / 卤料花园 = 5；都没打通 = 1。
///       这只是**进度侧的上限**，实际倍率还要跟难度自己的上限取小。
function difficulty_reward_progress_tier() {
    if (!variable_global_exists("save_data")) return 1;
    if (!is_struct(global.save_data)) return 1;
    if (!variable_struct_exists(global.save_data, "completed_levels")) return 1;
    var _done = global.save_data.completed_levels;
    if (array_get_index(_done, "marinade_garden") != -1) return 5;
    if (array_get_index(_done, "snowcap_volcano") != -1) return 4;
    if (array_get_index(_done, "abyss")           != -1) return 3;
    if (array_get_index(_done, "temple")          != -1) return 2;
    return 1;
}

/// @function difficulty_reward_cap(_difficulty)
/// @desc 各难度自己的奖励倍率上限：美味 1 / 火山 1 / 浮空 2 / 星际 3 / 永恒 4 / 不朽 5
function difficulty_reward_cap(_difficulty) {
    var _caps = [1, 1, 2, 3, 4, 5];
    return _caps[clamp(floor(_difficulty), 0, array_length(_caps) - 1)];
}

/// @function difficulty_get_reward_multiplier_for(_difficulty)
/// @desc 给定难度号的奖励倍率。与玩法模式无关：抽卡版 / 欧皇版 / 随机礼盒 / 海克斯
///       一律按"实际基础难度"结算，不按模式给固定值。
///       口径：**上限看难度、实际看通关进度，取两者较小值**
///         难度上限：美味 1 / 火山 1 / 浮空 2 / 星际 3 / 永恒 4 / 不朽 5
///         进度解锁：打通神殿 2 / 深渊 3 / 雪顶火山 4 / 卤料花园 5（都没打通 = 1）
///       海克斯倍率另外叠加，不在这里。
function difficulty_get_reward_multiplier_for(_difficulty) {
    // 实际倍率 = min(难度上限, 通关进度)
    //   打通神殿但选火山（上限 1）→ 1 倍；打通深渊且选浮空（上限 2）→ 2 倍
    return min(difficulty_reward_cap(_difficulty), difficulty_reward_progress_tier());
}

/// @function difficulty_get_reward_multiplier()
/// @desc 当前难度的奖励倍率（只读 global.difficulty，不看 global.play_mode）
///       海克斯的「达摩克里斯之剑（×10）」「搏一搏（翻倍/减半）」也在这里并入，
///       这样结算界面显示的数字与实际入账完全同源
function difficulty_get_reward_multiplier() {
    return difficulty_get_reward_multiplier_for(global.difficulty) * hex_batch2_reward_mult();
}

/// @function difficulty_reward_item_fixed(_item_id)
/// @desc 不吃难度奖励倍率的专项养成材料（2026-10-30 用户口径：遗迹与营地的
///       食谱碎片 / 探险币按 JSON 基础值固定发放，不随难度放大）。
///       只登记「靠关卡独有产出、且会直接换养成进度」的物品，通用资源
///       （金币 / 香料 / 水晶 / 四叶草）仍然照常吃倍率。
function difficulty_reward_item_fixed(_item_id) {
    var _fixed = [
        "copper_cookbook_fragment",     // 铜食谱碎片（火山遗迹）
        "silver_cookbook_fragment",     // 银食谱碎片（火山遗迹）
        "gold_cookbook_fragment",       // 金食谱碎片（火山遗迹）
        "less_camp_coin",               // 补给币（探险营地关卡掉落）
        "camp_coin"                     // 营地金币（探险营地支线任务）
    ];
    return array_get_index(_fixed, _item_id) != -1;
}

/// @function difficulty_reward_item_amount(_item_id, _base_amount, _multiplier)
/// @desc 关卡结算发放口径的唯一出口：白名单物品保持基础值，其余乘难度奖励倍率。
///       任何发奖循环都必须走这里，不要在调用点各写一遍 `* reward_multiplier`。
function difficulty_reward_item_amount(_item_id, _base_amount, _multiplier) {
    if (difficulty_reward_item_fixed(_item_id)) return _base_amount;
    return _base_amount * _multiplier;
}

// ── 开局奖励：永恒 / 不朽 互斥，发奖前必须先弹 obj_start_reward ──
//   自选一张卡（三选一）整套下线，暖暖鸡也不再送；
//   抽卡 / 欧皇（play_mode 1 / 2）额外送一张花火龙，其余模式只发金币。

/// @function difficulty_start_reward_table()
/// @desc 开局奖励表：键 = 难度号（4 永恒 / 5 不朽）
function difficulty_start_reward_table() {
    return {
        "4": { name: "永恒级", gold: 60000  },
        "5": { name: "不朽级", gold: 200000 }
    };
}

/// @function difficulty_start_reward_extra_card(_difficulty)
/// @desc 开局奖励附带的卡片，没有就返回 ""。
///       **不朽不看模式都给**（锁难度的补偿），永恒只在抽卡 / 欧皇给。
function difficulty_start_reward_extra_card(_difficulty) {
    if (_difficulty == 5) return "firework_dragon";
    if (global.play_mode == 1 || global.play_mode == 2) return "firework_dragon";
    return "";
}

/// @function difficulty_start_reward_of(_difficulty)
/// @desc 取某档的开局奖励配置；没有这一档返回 undefined
function difficulty_start_reward_of(_difficulty) {
    var _t = difficulty_start_reward_table();
    if (!variable_struct_exists(_t, string(_difficulty))) return undefined;
    return _t[$ string(_difficulty)];
}

/// @function difficulty_start_reward_claimed()
/// @desc 已经领过哪一档（0 = 没领 / 4 / 5）
///       老存档迁移（只做一次）：拿过不朽开局金币或暖暖鸡的，一律算「已领不朽」
function difficulty_start_reward_claimed() {
    if (!variable_struct_exists(global.save_data, "start_reward_claimed")) {
        var _old_immortal =
            (variable_struct_exists(global.save_data, "immortal_bonus_given")
                && global.save_data.immortal_bonus_given)
            || (variable_struct_exists(global.save_data, "immortal_start_cards_given")
                && global.save_data.immortal_start_cards_given);
        global.save_data.start_reward_claimed = _old_immortal ? 5 : 0;
    }
    return round(global.save_data.start_reward_claimed);
}

/// @function difficulty_start_reward_available(_difficulty)
/// @desc 这一档现在能不能领：新档（**没通关过曲奇岛**）+ 没领过任何一档
///       判定看曲奇岛：「打过曲奇岛就不能领了」
function difficulty_start_reward_available(_difficulty) {
    if (is_undefined(difficulty_start_reward_of(_difficulty))) return false;
    if (array_get_index(global.save_data.completed_levels, "cookie_island")      != -1) return false;
    if (array_get_index(global.save_data.completed_levels, "cookie_island_hard") != -1) return false;
    return difficulty_start_reward_claimed() == 0;
}

/// @function difficulty_set_value(_difficulty)
/// @desc 切难度唯一出口：改全局 + 写 config + 把设置页那两个箭头的 state 对齐。
///       不朽确认窗「取消」时也走这里（回火山级），别在别处手写 ini。
function difficulty_set_value(_difficulty) {
    var _d = clamp(round(_difficulty), 0, 5);
    global.difficulty = _d;
    ini_open("config.ini");
    ini_write_real("settings", "difficulty", _d);
    ini_close();
    with (obj_difficulty_select_btn) {
        if (config_key == "difficulty") state = _d;
    }
    return _d;
}

/// @function difficulty_locked_value()
/// @desc 本存档锁定的难度（0 = 没锁 / 5 = 已锁定不朽）。跟着存档走，不跟 config。
function difficulty_locked_value() {
    if (!variable_struct_exists(global.save_data, "difficulty_locked")) return 0;
    return round(global.save_data.difficulty_locked);
}

/// @function difficulty_lock_immortal(_grant_reward)
/// @desc 锁定不朽：写存档字段 + 切到不朽 + 写 config + 存盘；_grant_reward 且还够资格时顺手发开局奖励。
///       锁上之后难度选择器会被拒绝（见 obj_difficulty_select_btn）。
function difficulty_lock_immortal(_grant_reward = true) {
    global.save_data.difficulty_locked = 5;
    difficulty_set_value(5);
    if (_grant_reward && difficulty_start_reward_available(5)) {
        difficulty_start_reward_grant(5);
    }
    save_file(global.save_slot);
}

/// @function difficulty_apply_save_lock()
/// @desc 启动 / 换存档后对齐：这个存档锁了不朽就强制回到不朽（config 是全局的，可能停在别的档）
function difficulty_apply_save_lock() {
    if (difficulty_locked_value() != 5) return false;
    if (global.difficulty == 5) return false;
    difficulty_set_value(5);
    return true;
}

/// @function difficulty_start_reward_gold_text(_gold)
/// @desc 金币文案加千分位（GM 的 string_format 不会插逗号）：60000 → "60,000"
function difficulty_start_reward_gold_text(_gold) {
    var _s = string(round(_gold));
    var _n = string_length(_s);
    var _out = "";
    for (var i = 1; i <= _n; i++) {
        if (i > 1 && ((_n - i + 1) mod 3) == 0) _out += ",";
        _out += string_char_at(_s, i);
    }
    return _out;
}

/// @function difficulty_start_reward_grant(_difficulty)
/// @desc 发奖 + 记 claimed + 存盘；调用前必须先过 difficulty_start_reward_available()
/// @return true = 发放成功
function difficulty_start_reward_grant(_difficulty) {
    if (!difficulty_start_reward_available(_difficulty)) return false;

    var _row = difficulty_start_reward_of(_difficulty);
    global.save_data.player.gold += _row.gold;
    show_notice("已领取" + _row.name + "开局奖励：+" + difficulty_start_reward_gold_text(_row.gold) + " 金币", 90);

    // 抽卡 / 欧皇额外送一张花火龙本体；其余模式（普通 / 海克斯 / 礼盒）只发金币。
    //   暖暖鸡 + 三选一自选卡 已整体下线。
    var _extra_card = difficulty_start_reward_extra_card(_difficulty);
    if (_extra_card != "") unlock_card(_extra_card, 0, 0, 0);

    // 旧字段一并写掉：其它地方（启动兜底 / 老存档判断）还在读它
    global.save_data.immortal_bonus_given = true;
    global.save_data.start_reward_claimed = _difficulty;
    save_file(global.save_slot);
    return true;
}

/// @function difficulty_get_name()
/// @desc 返回基础难度名称
function difficulty_get_name(_difficulty) {
    var names = ["美味级", "火山级", "浮空级", "星际级", "永恒级", "不朽级"];
    _difficulty = clamp(_difficulty, 0, array_length(names) - 1);
    return names[_difficulty];
}

/// @function difficulty_get_display_name()
/// @desc 返回基础难度和玩法模式组合名称
function difficulty_get_display_name() {
    var result = difficulty_get_name(global.difficulty);
    if (global.play_mode == 1) result += "·抽卡版";
    else if (global.play_mode == 2) result += "·欧皇版";
    else if (global.play_mode == 3) result += "·随机礼盒";
    else if (global.play_mode == 4) result += "·海克斯模式";
    return result;
}

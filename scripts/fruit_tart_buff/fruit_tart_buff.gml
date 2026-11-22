/// =====================================================================
/// fruit_tart_buff —— 水果塔（fruit_tart）增幅格子的统一入口
///   水果塔的增幅走「增幅网格」的 thrower 通道（见 scripts/buff_target）：
///   谁吃这一档由 card_buff_channels 决定，投掷类全类都在名单里，所以
///   本工程现有的、以及以后新增的投掷类卡片都会自动吃到，不需要逐张登记。
///   倍率口径：水果塔的 atk 就是倍率本身（1.5 ~ 3.0），直接写进格子，
///   不能像极光那样再除 100（极光的 atk 是百分数）。
/// =====================================================================

/// @func fruit_tart_build_cells(_col, _row, _shape, _value)
/// @desc 按转职形态铺增幅格子
///   零转：本行左侧（自己那一格不铺）
///   一转：整行
///   二转：三行（上下各一行，全列）
function fruit_tart_build_cells(_col, _row, _shape, _value) {
    var _cells = [];
    if (_shape <= 0) {
        for (var _c = _col - 1; _c >= 0; _c--) {
            array_push(_cells, [_c, _row, _value]);
        }
    } else if (_shape == 1) {
        for (var _c = 0; _c < global.grid_cols; _c++) {
            array_push(_cells, [_c, _row, _value]);
        }
    } else {
        for (var _dr = -1; _dr <= 1; _dr++) {
            var _r = _row + _dr;
            if (_r < 0 || _r >= global.grid_rows) continue;
            for (var _c = 0; _c < global.grid_cols; _c++) {
                array_push(_cells, [_c, _r, _value]);
            }
        }
    }
    return _cells;
}

/// @func fruit_tart_mult(_shape, _level, _skill, _fallback_atk)
/// @desc 水果塔的增幅倍率（1.5 ~ 3.0），从注册表 `custom["增幅倍率"]` 取（atk 已归 0）。
///   🔴 不读实例 atk：实例 atk 会被地形 / 宝石 / 海克斯 / 生肖逐层放大。
///   也不读注册表 atk（已归 0，只留作兜底），倍率只活在 custom 里。
function fruit_tart_mult(_shape, _level, _skill, _fallback_atk) {
    var _d = get_plant_data_with_skill("fruit_tart", _shape, clamp(_level, 0, 16), _skill);
    if (_d != undefined && ds_map_exists(_d, "增幅倍率")) return _d[? "增幅倍率"];
    if (_d != undefined && ds_map_exists(_d, "atk")) return _d[? "atk"];
    return _fallback_atk;
}

/// @func fruit_tart_refresh_cells()
/// @desc 重铺自己的 buff_cells（只在实例里调用，直接写实例变量）
function fruit_tart_refresh_cells() {
    buff_value = fruit_tart_mult(shape, current_level,
        variable_instance_exists(id, "skill") ? skill : 0, atk);
    buff_cells = fruit_tart_build_cells(grid_col, grid_row, shape, buff_value);
    global.buff_dirty = true;
    buff_cells_refreshed = true;
}

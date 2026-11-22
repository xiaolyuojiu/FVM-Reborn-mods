/// place_mutex_class(card_id)
/// @description 放置互斥类：同类卡不能放在同一格（彼此都不能叠），不同类 / 没登记的卡照旧可叠。
///   🔴 数据在 `scripts/card_special_flags` 的 `mutex` 列（取值型），
///      这里只做一层兼容包装，别再往本文件加 case —— 加卡改事实表：
///        card_flag_set(_t, "<卡id>", "mutex", "<类名>");
///   现有类名：
///      `gridless_track` —— 蜜糖陷阱 ↔ 仙笛马（2026-11-08 用户口径：都是「不占格·追踪」的悬浮卡）
///      `jiejiema_self`  —— 结界马二转 gridless，同一格只允许一张（2026-11-18 口径）
///   同名的拦截是「免费」的：自己那格已有同名卡 → 类名相同 → 直接判不可放。
/// @param {string} _card_id 卡牌 id（与 plant_id 同一套）
/// @returns {string} 类名；"" = 不参与互斥
function place_mutex_class(_card_id) {
    var _m = card_flag_value(_card_id, "mutex");
    return is_undefined(_m) ? "" : _m;
}

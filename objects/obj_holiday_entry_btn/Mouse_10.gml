/// 悬停反馈：放大 6% + 手型光标（同 obj_zz_enter 的悬停放大写法）
/// 弹窗开着时不给反馈，免得隔着面板亮
if (obj_player_info_ui.menu_type != 0) exit;
image_xscale = hal_btn_scale * 1.06;
image_yscale = hal_btn_scale * 1.06;
window_set_cursor(cr_handpoint);

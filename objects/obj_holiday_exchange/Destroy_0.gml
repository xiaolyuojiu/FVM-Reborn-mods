/// 面板关闭：复原顶层状态，否则入口会一直卡在 menu_type = 4，整排图标都点不动
/// （同 obj_gods_hall_bg/Destroy_0、obj_zz_bg/Destroy_0）
obj_player_info_ui.menu_type = 0;
obj_world_map_button.world_map = 0;

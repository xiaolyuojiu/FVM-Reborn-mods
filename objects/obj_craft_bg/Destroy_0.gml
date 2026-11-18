instance_destroy(obj_closecraft_btn)
instance_destroy(obj_craft_select_btn)
instance_destroy(obj_craft_confirm_btn)
obj_player_info_ui.menu_type = 0
obj_world_map_button.world_map = 0
surface_free(card_surface)

panel_anim_free(id)
// 卡片搜索（2026-11-08）：关合成屋把搜索框一起销毁
if (variable_instance_exists(id, "craft_nav")) mod_search_nav_destroy(craft_nav)

// 2026-11-20：释放卡数据索引
if (variable_instance_exists(id, "craft_slot_cache") && craft_slot_cache != -1 && ds_exists(craft_slot_cache, ds_type_map)){
	ds_map_destroy(craft_slot_cache)
	craft_slot_cache = -1
}

if on_click && obj_player_info_ui.menu_type == 0 && unlock{
	pressed = true
    global.audio.play(snd_button, 0, 0);
	if target_level_id == "longyuan_entry"{
		global.map_id = "longyuan"
		global.map_name = "龙渊"
		if room != room_map global.gui_stack.to(room_map)
		exit
	}
	resource_texture_prepare("cards")
	if target_level_id == "camp_shop"{
		instance_create_depth(room_width/2,room_height/2,-5,obj_camp_shop_bg)
		obj_player_info_ui.menu_type = 4
		obj_world_map_button.world_map = 2
		exit
	}
	if target_level_id == "camp_port"{
		instance_create_depth(room_width/2,room_height/2,-5,obj_camp_port_menu)
		obj_player_info_ui.menu_type = 4
		obj_world_map_button.world_map = 2
		exit
	}
	if global.map_id == "longyuan" && target_level_id != "test_level" {
		var _longyuan_file = "level_data/" + (global.difficulty >= 2 ? target_level_file_hard : target_level_file)
		if !file_exists(_longyuan_file) {
			pressed = false
			show_notice("该关卡尚未配置", 90)
			exit
		}
	}
	if target_level_id != "tower_cake"{
	    global.gui_stack.to(room_ready)
	
		// 这是文件在 datafiles 目录下的相对路径
		global.level_id = target_level_id;

		// 这是文件在 datafiles 目录下的相对路径
		var _file_path = "level_data/" + target_level_file; 
		if global.difficulty >= 2{
			_file_path = "level_data/" + target_level_file_hard; 
		}

		// 读取关卡文件并校验内存中的内容（GameMaker 会静默读坏文件，见 scripts/level_integrity）
		var _load_result = level_load_json_verified(_file_path);
		if (_load_result.is_failed()) {
			// 先退回地图，再提示读取失败；不要进备战房间
			level_load_failed_back_to_map(_file_path, _load_result.message);
			exit;
		}
		global.level_file = _load_result.data;

		var map_button_array = struct_get(ds_map_find_value(global.maps_map,global.map_id),"levels_data")
		if target_level_id == "test_level"{
			global.level_data = {id:"test_level",name:"测试关卡",button_spr:spr_test_level_button,button_index:0,button_x:860,button_y:56,level_file:"test_level.json",hard_level_file:"test_level_hard.json",level_sprite:spr_cookie_island,pre_music:mus_delicious_island_daytime_pre,elite_music:mus_delicious_island_daytime_elite,boss_music:mus_delicious_island_daytime_boss,player_level_require:1,pre_level_require:[]}
		} else {
			global.level_data = map_button_array[level_index]
		}
		show_debug_message(global.level_data)

		global.gui_stack.to(room_ready)
	}
	else{
		global.gui_stack.to(room_tower_cake)
	}
}
if !unlock && obj_player_info_ui.menu_type == 0{
	if player_level_require > 80{
		show_notice("暂未开放，敬请期待！",60)
	}
	else{
		if global.save_data.player.level < player_level_require{
			show_notice("达到"+string(player_level_require)+"级以解锁此关",60)
		}
		else{
			show_notice("完成前置关卡以解锁此关",60)
		}
	}
}

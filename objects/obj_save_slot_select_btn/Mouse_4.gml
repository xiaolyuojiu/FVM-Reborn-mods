if (ui_modal_blocking()) exit;   // 上面有弹窗，别让点击穿透到后面的按钮
// 切换状态
	//if config_key == "save_slot"{
	//	if state < 4{
	//		state ++
	//	}
	//	else{
	//		state = 0
	//	}
	//}
if global.save_slot != state{
	global.audio.play(snd_button,0,0)
	// 保存到配置文件
	if (config_key != "") {
	    ini_open("config.ini");
	    ini_write_real("settings", config_key, state);
	    ini_close();
	}

	if (config_key == "save_slot"){
		save_file(global.save_slot)
		global.save_slot = state
		load_file(global.save_slot)
		// 换档不弹任何窗：难度退回火山级(1)，不走「把不朽带过去」这条路；
		//   想玩不朽只能自己切过去（切过去必弹确认窗）。这一档自己锁了不朽的，再由 apply_save_lock 拉回 5。
		difficulty_set_value(1)
		difficulty_apply_save_lock()
		global.gui_stack.to(room_menu)
	}
}
if (ui_modal_blocking()) exit;   // 上面有弹窗，别让点击穿透到后面的按钮
// 切换状态
if room != room_battle{
	if config_key == "difficulty"{
		// 已锁定不朽的存档：难度不给改
		if (difficulty_locked_value() == 5){
			global.audio.play(snd_button,0,0)
			show_notice("本存档已锁定不朽难度，无法更改", 70)
			state = 5
			exit
		}
		var _next = state
		if b_type == "next"{
			_next = (state < 5) ? state + 1 : 0
		}
		else{
			_next = (state > 0) ? state - 1 : 5
		}
		// 切到不朽：先问「要不要锁不朽开局」，**不提前落盘**（取消就什么都不变）
		if (_next == 5){
			global.audio.play(snd_button,0,0)
			if (!instance_exists(obj_immortal_confirm)){
				instance_create_depth(0, 0, -16000, obj_immortal_confirm)
			}
			exit
		}
		state = _next
	}
	global.audio.play(snd_button,0,0)
	// 保存到配置文件
	if (config_key != "") {
	    ini_open("config.ini");
	    ini_write_real("settings", config_key, state);
	    ini_close();
	}

	if (config_key == "difficulty"){
		global.difficulty = state

		// 永恒：切过去就问一次「领不领开局奖励」（不朽走 obj_immortal_confirm，在那边连锁定一起处理）
		if (state == 4 && difficulty_start_reward_available(4)){
			if (!instance_exists(obj_start_reward)){
				var _sr = instance_create_depth(0, 0, -16000, obj_start_reward)
				_sr.sr_diff = 4
			}
		}
	}
}
else{
	global.audio.play(snd_button,0,0)
	show_notice("无法在游戏中修改难度",60)
}

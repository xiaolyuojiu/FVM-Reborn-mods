if global.is_paused{
	exit
}

event_inherited(); 
var current_flash_speed = flash_speed
if is_slowdown{
	current_flash_speed *= 2
}

attack_timer++

if attack_timer == 1{
	if shape <= 1{
		with obj_card_parent{
			if plant_id != "player"{
				if(other.shape == 0 && grid_row == other.grid_row && grid_col == other.grid_col)
				||(other.shape == 1 && grid_row >= other.grid_row-1 && grid_row <= other.grid_row+1 && grid_col >= other.grid_col-1 && grid_col <= other.grid_col+1)
				{
					if (card_cd_target_ok(plant_id, other.plant_id, plant_type == "gridless")){
						with obj_card_slot{
							if card_id == other.plant_id{
								cooldown_timer = cooldown
							}
						}
					}
				}
			}
		}
	}
	else{
		// 2 转：全部卡槽（含不占格、含辅助类），只排缩 CD 施放者
		with obj_card_slot{
			// 官方「冷却除自身外的全部卡槽」：全部卡槽（含不占格、含辅助类）
			if (card_cd_target_ok(card_id, other.plant_id, false, true)){
				cooldown_timer = cooldown
			}
		}
	}
}
if attack_timer > current_flash_speed * idle_anim-1{
	instance_destroy()
}
// 灵魂融合：可穿透障碍，直接穿过、不销毁、不消耗穿透数量
if (pierce_left > 0) exit;

if target_type == "normal" && row == other.row && precise_bbox_collision(id, other){
	if burnt == 0{
		var inst = instance_create_depth(x,y,depth,obj_coffeecup_bullet_effect)
		inst.sprite_index = spr_ronghesanxian_bullet_effect
	}
	else if burnt == 1{
		var inst = instance_create_depth(x+25,y,depth,obj_fire_bullet_effect)
		inst.sprite_index = spr_fire_bullet_effect
	}
	instance_destroy()
}

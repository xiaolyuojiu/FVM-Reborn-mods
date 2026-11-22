image_xscale = 1.8
image_yscale = 1.8
var _animation_visual = external_animation_sample(id);
if is_medusa_statue{
	// 被美杜莎冰冻的卡片不绘制自身精灵，改画石像
	image_blend = c_white
	draw_sprite_ext(spr_medusa_statue,floor(medusa_statue_anim/5) mod 12,x,y,image_xscale,image_yscale,0,c_white,image_alpha)
}
else if flash_value >0{
	
    draw_sprite_ext(_animation_visual.sprite, _animation_visual.frame, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha)
	shader_set(hit_effect_2);
	draw_sprite_ext(_animation_visual.sprite,_animation_visual.frame,x,y,image_xscale,image_yscale,image_angle,c_white,flash_value/200);
	shader_reset();
	
}
else if is_slowdown{
	image_blend = merge_color(c_white,c_blue,0.5)
	draw_sprite_ext(_animation_visual.sprite, _animation_visual.frame, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha)
}
else{
	image_blend = c_white
	draw_sprite_ext(_animation_visual.sprite, _animation_visual.frame, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha)
}
if instance_exists(banding_star_obj){
	banding_star_obj.depth = depth -1
}
if is_frozen && !is_medusa_statue{
	draw_sprite_ext(spr_mouse_frozen,0,x,y+95,1.8,1.8,0,c_white,1)
}
if desert_wind_protect{
	if !global.is_paused{
		desert_wind_protect_timer ++
	}
	draw_sprite_ext(spr_parsnip_salad_effect,floor(desert_wind_protect_timer/5),x,y-95,1.8,1.8,0,c_white,1)
}



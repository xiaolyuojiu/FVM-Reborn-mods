if is_disabled{
	image_blend = c_gray
}
draw_self()
draw_set_font(font_yuan)
draw_set_color(c_black)
draw_set_halign(fa_left)
draw_set_valign(fa_middle)
draw_set_alpha(image_alpha)
draw_text(x-65,y-98,goods_name)
draw_set_font(font_number)
if not is_disabled{
	draw_sprite_ext(craft_material_spr(coin_type), craft_material_frame(coin_type),x-50,y-54,0.5,0.5,0,c_white,image_alpha)
	draw_set_color(c_white)
	draw_text(x-20,y-54,string(cost))
}
draw_set_alpha(1)

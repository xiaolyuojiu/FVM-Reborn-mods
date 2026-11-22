// 悬停判定：直接按「裁剪框」这片矩形算，和真正画出来的范围一致。
// ⚠️ 不要用引擎自带的 Mouse Enter / Mouse Leave（obj_mouse_preview 里已删掉）：
//    那两个事件按实例 bbox 判定，而精灵现在不是画在实例坐标上的（按内容包围盒居中贴底），
//    判定区会跑到贴图上方的空位，tooltip 在对不上的地方冒出来。
// 裁剪框：水平 [x - w/2, x + w/2]，竖直 [y - h, y]（底边贴住实例 y，见 Draw_0）
var _bx0 = x - clip_box_w * 0.5;
var _by0 = y - clip_box_h;
var _bx1 = x + clip_box_w * 0.5;
var _by1 = y;
on_click = point_in_rectangle(mouse_x, mouse_y, _bx0, _by0, _bx1, _by1)

if on_click{
	// 获取鼠标位置
	var tooltip_x = mouse_x - 15;
	var tooltip_y = mouse_y - 25;
	if x < 600{
		tooltip_x = mouse_x + 15;
		tooltip_y = mouse_y - 25;
	}
		
		
	draw_set_font(font_yuan)
	// 绘制提示背景
	draw_set_color(c_black);
	draw_set_alpha(0.7);
	if x >= 600{
		draw_rectangle(tooltip_x + 5, tooltip_y - 5, 
	                tooltip_x - string_width(tooltip_text)-5, tooltip_y + string_height(tooltip_text)+5, false);
	}
	else{
		draw_rectangle(tooltip_x - 5, tooltip_y - 5, 
	                tooltip_x + string_width(tooltip_text)+5, tooltip_y + string_height(tooltip_text)+5, false);
	}
        
	// 绘制提示文本
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_alpha(1);
	draw_set_color(c_white);
	if x >= 600{	
		draw_text(tooltip_x- string_width(tooltip_text), tooltip_y, tooltip_text);
	}
	else{
		draw_text(tooltip_x, tooltip_y, tooltip_text);
	}
	
	draw_set_valign(fa_top)
}

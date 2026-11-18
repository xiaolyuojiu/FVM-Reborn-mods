/// 开面板：menu_type == 0 才放行，开完置 4 —— 诸神/跨服/龙渊/金马的 Mouse_4 都判这个值，于是点不开
if (obj_player_info_ui.menu_type != 0) exit;
if (instance_exists(obj_holiday_exchange)) exit;

// 原点在中心，命中区按 ±sprite_width/2（sprite_width 已含 image_xscale）
if (!point_in_rectangle(mouse_x, mouse_y, x - sprite_width * 0.5, y - sprite_height * 0.5,
                        x + sprite_width * 0.5, y + sprite_height * 0.5)) exit;

audio_play_sound(snd_button, 0, 0);
instance_create_depth(room_width / 2, room_height / 2, -5, obj_holiday_exchange);
obj_player_info_ui.menu_type = 4;
obj_world_map_button.world_map = 2;

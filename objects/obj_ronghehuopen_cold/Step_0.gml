// obj_ronghehuopen_cold（融合火盆·寒气场）Step 事件
// timer 驱动：每 60 帧（= 1 秒，与伤害跳同拍）从头冒一次 19 帧寒气动画；
// 生命走到 fade_frames 内整体淡出，到 life 销毁。
//   image_index = min(floor((timer mod 60) / 3), 18) → 0~56 帧把 19 张播完（每张 3 帧），
//   58/59 帧收在末帧（末帧本身是空图，视觉上正好「散掉」）。
if global.is_paused{
	exit
}
timer++
image_index = min(floor((timer mod 60) / 3), 18)

var _left = life - timer
if (_left <= fade_frames){
	image_alpha = max(0, _left / fade_frames)
}
if (timer >= life){
	instance_destroy()
}

if (global.is_paused) exit;

if (!instance_exists(parent_plant)){
    instance_destroy();
    exit;
}

// 形态跟着本体换精灵（本体 shape 可能晚于 Create 才定，所以每帧兜一次）
var _ps = parent_plant.shape;
if (_ps == 1)      sprite_index = spr_caihongshe_1_back;
else if (_ps == 2) sprite_index = spr_caihongshe_2_back;
else               sprite_index = spr_caihongshe_back;

// 位置偏移：后层画布原点在左上(0,0)，偏移由「旧合成图模板匹配」反推
var _off_x = -63;
var _off_y = -33;
if (_ps == 1){ _off_x = -66; _off_y = -36; }
else if (_ps == 2){ _off_x = -71; _off_y = -45; }

x = parent_plant.x + _off_x;
y = parent_plant.y + _off_y;
depth = parent_plant.depth + 2;

// 帧跟本体同步（本体自己推帧，后层不另开计时）
image_index = clamp(parent_plant.image_index, 0, sprite_get_number(sprite_index) - 1);

// 本体淡出（虚弱）时后层跟着淡
image_alpha = parent_plant.image_alpha;

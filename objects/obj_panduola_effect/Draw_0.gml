// 毒气瘟疫：整行平铺；四转起本列也铺（判定同口径，见 Step）
var _cw = global.grid_cell_size_x;
var _ch = global.grid_cell_size_y;
var _ox = global.grid_offset_x;
var _oy = global.grid_offset_y;

// 以卡片自身位置为基准取纵向偏移，保持和原来那一格的贴法一致
var _yoff   = y - (_oy + grid_row * _ch + _ch * 0.5);
var _row_y  = _oy + grid_row * _ch + _ch * 0.5 + _yoff;
var _col_x  = _ox + grid_col * _cw + _cw * 0.5;

for (var _c = 0; _c < global.grid_cols; _c++)
{
    var _wx = _ox + _c * _cw + _cw * 0.5;
    draw_sprite_ext(sprite_index, image_index, _wx, _row_y, image_xscale, image_yscale, 0, c_white, image_alpha);
}

if (shape >= 2)
{
    for (var _r = 0; _r < global.grid_rows; _r++)
    {
        if (_r == grid_row) continue;
        var _wy = _oy + _r * _ch + _ch * 0.5 + _yoff;
        draw_sprite_ext(sprite_index, image_index, _col_x, _wy, image_xscale, image_yscale, 0, c_white, image_alpha);
    }
}

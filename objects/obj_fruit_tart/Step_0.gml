if global.is_paused{
	exit
}
event_inherited(); 
// 增幅源登记 + 按形态铺格子（倍率取注册表，见 scripts/fruit_tart_buff）。
// 倍率不跟实例 atk 走，只在「位置 + 形态」变化时重铺。
if (!buff_cells_refreshed
    || grid_col != ft_last_col || grid_row != ft_last_row || shape != ft_last_shape)
{
    mod_buff_source_add(id);
    fruit_tart_refresh_cells();
    ft_last_col   = grid_col;
    ft_last_row   = grid_row;
    ft_last_shape = shape;
}

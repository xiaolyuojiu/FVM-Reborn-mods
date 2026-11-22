if global.is_paused{
	exit
}
event_inherited(); 
// 2026-11-22：增幅源登记 + 按形态铺格子（倍率直接取 atk，见 scripts/fruit_tart_buff）。
//   atk 被海克斯 / 生肖 / 海洋女神等乘区改过之后也要重铺，所以比较一下 buff_value 再决定。
if (!buff_cells_refreshed || abs(buff_value - atk) > 0.0001)
{
    mod_buff_source_add(id);
    fruit_tart_refresh_cells();
}

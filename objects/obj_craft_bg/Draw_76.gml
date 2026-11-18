if (!surface_exists(card_surface)) {
    // 创建表面用于绘制圆形头像
    card_surface = surface_create(600,815);
    craft_surf_y = -99999;   // 2026-11-21：切屏/最小化会让 surface 丢内容，新建后必须让 Main Draw 重画一次
}

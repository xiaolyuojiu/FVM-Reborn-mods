/// 假期特惠入口（写法同 obj_gods_hall_enter / obj_cross_server_enter）
/// 位置由 obj_mod_manager/Step_0 创建时给：(1250, 56) = 那排「测试」(1150) 右边一格
image_speed  = 0;
hal_btn_scale = 1.6;   // 56×51 → 90×82，与诸神/跨服(58×4x×1.6) 同量级
image_xscale = hal_btn_scale;
image_yscale = hal_btn_scale;
depth = -3;            // 与那排 Button 一致，遮罩才盖得住

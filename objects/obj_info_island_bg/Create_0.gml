image_xscale = 1.8
image_yscale = 1.8
var btn_close = instance_create_depth(x+380,y-400,depth-1,obj_closeinfo_btn)
info_cols = 4 //防御卡信息行列数
info_rows = 40
info_button_select = 1
//package_button_select = 1
is_submenu_opened = false
//创建信息栏位选择按钮
var btn1 = instance_create_depth(x-1130,y-455,depth-1,obj_info_island_select_btn)
btn1.button_index = 1
btn1.sprite_index = spr_info_island_select_btn_1
var btn2 = instance_create_depth(x-870,y-455,depth-1,obj_info_island_select_btn)
btn2.button_index = 2
btn2.sprite_index = spr_info_island_select_btn_2
var btn3 = instance_create_depth(x-610,y-455,depth-1,obj_info_island_select_btn)
btn3.button_index = 3
btn3.sprite_index = spr_info_island_select_btn_3

var btn_edit = instance_create_depth(x+320,y-320,depth-1,obj_info_island_edit_btn)
// 「同步背包」按钮：贴在编辑按钮正下方（y-205），点了才把当前查看卡的星级/转职/技能按背包真实值刷一遍
var btn_sync = instance_create_depth(x+320,y-205,depth-1,obj_info_island_sync_btn)

hover_card_index = -1; // 当前悬停的卡片索引
hover_weapon_index = -1
select_card_index = -1
deck_sort_order = [] // 卡片排序映射（普通卡在前 → 融合卡居中 → 金卡在后）

view_card_level = 0
view_card_shape = 0
view_card_skill = 0
// 从背包右键进来时带过来的目标卡 id：Draw 里只用来「定位到那张卡」（不再自动同步数值）
open_focus_id = ""

info_surface = -1
surface_width = 900
surface_height = 780

// ── 情报岛「敌人」立绘：裁剪框 + 统一缩放（可配置）────────────────────
// 敌人贴图尺寸差异极大（平民鼠 108×104，寄居蟹鼠 468×642），而且画布留白占比从 0.12 到 0.9 不等。
// 所以不按画布大小自适应（那会让留白多的贴图被额外缩小、显得比同伴小一圈），
// 改成「普通鼠军 / BOSS」各一个固定缩放。
//   建议裁剪框 ≤ 格子尺寸（格子 192 × 213）
// 缩放作用在**裁掉透明留白后的内容**上（见 sprite_trim_get），同类贴图看起来大小一致。
// 🔴 下面是**上限**而不是硬缩放 —— 内容按这个值仍装不下裁剪框时会等比缩到刚好放得进
//    （见 scripts/sprite_clip_draw）。这样本工程自有的换皮美术（感染鼠/跨服鼠/龙渊 BOSS 等，
//    画布动辄 260~690px）不会因为超框被裁掉半只；包围盒也改成「离线表 → 运行时 sprite_get_bbox_*」两级，
//    新加美术即使没跑 tools/gen_sprite_trim.py 也能正常显示。想整只更大就把这两个值调大。
enemy_clip_w         = 176
enemy_clip_h         = 176
enemy_scale_normal   = 1.0    // 普通鼠军统一缩放（上限）
enemy_scale_boss     = 0.55   // BOSS 统一缩放（和普通鼠共用同一个格子，所以压小一档，同样是上限）

y_offset = 0

// 滚动条状态
scrollbar_dragging = false
scrollbar_drag_start_y = 0
scrollbar_drag_start_offset = 0
scrollbar_x = 0
scrollbar_y = 0
scrollbar_w = 17
scrollbar_h = 0
y_offset_target = 0
anim_slide = 360
panel_anim_init(id, 0.28, 0.18, anim_slide)
anim_surf = -1

// ── 搜索栏（2026-10-31）：用工程通用 SearchBox，左上角、三个页签共用 ──
//   位置 / 尺寸：(130,118) **384×40**（2026-11-05 加宽，384 正好到第 3 格左沿 514，不压卡片）—— 左边对齐列表第 1 列格子的左沿（列表格左沿 = x-1154-96 = 130），
//   宽度占 130~514（= 前两格整宽），不再捅出面板、也不压到第 3 列
//   口径：卡片页搜卡名 / 敌人页搜敌人名 / 关卡页搜关卡名；**切页签清空**（见 Draw_0 的 tab_shown 段）
//   2026-11-01：具体的建框/清空/匹配都搬进 scripts/mod_info_island_search，这里只留一句调用
info_search_text = "";        // 当前过滤词（小写比较在 Draw 里做）
info_view = [];               // 当前页签的可见条目：tab1 = player_deck 下标 / tab2·3 = id
info_search_box = info_island_search_spawn(130, 118, depth - 1);

anim_kids = [[btn1,-1],[btn2,-1],[btn3,-1],[btn_close,1],[btn_edit,1]]
for (var _i = 0; _i < array_length(anim_kids); _i++){
    var _c = anim_kids[_i][0]
    _c.anim_base_x = _c.x
    _c.anim_base_y = _c.y
}


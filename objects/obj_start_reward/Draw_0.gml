// obj_start_reward Draw：面板/按钮走 mod_tg_modal_draw，这里只负责文案
var _row = difficulty_start_reward_of(sr_diff);
if (is_undefined(_row)) exit;

// 不朽一律送花火龙；永恒只在抽卡 / 欧皇送；其余模式只写金币
var _extra = "";
if (difficulty_start_reward_extra_card(sr_diff) != "") _extra = " + 花火龙";

var _lines = [
    { text: "领取「" + _row.name + "」开局奖励？", red: false },
    { text: difficulty_start_reward_gold_text(_row.gold) + " 金币" + _extra, red: false },
    { text: "领取后无法再领其他难度的开局奖励", red: true }
];

mod_tg_modal_draw(sr_hover, _lines, "", false, ["领取", "以后再说"]);

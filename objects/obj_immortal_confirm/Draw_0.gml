/// obj_immortal_confirm Draw：面板/按钮走 mod_tg_modal_draw，这里只拼文案
if (ic_done) exit;

var _lines = [
    { text: "是否选择不朽开始游戏？", red: false },
    { text: "不朽难度极大且选择后不能更改至其他难度！！", red: true },
    { text: ic_can_reward ? "点击确定后锁定不朽，并领取开局奖励。" : "点击确定后锁定不朽。", red: false }
];

mod_tg_modal_draw(ic_hover, _lines, "", false, ["确定", "取消"]);

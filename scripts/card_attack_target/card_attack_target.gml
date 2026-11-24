/// =====================================================================
/// card_attack_target —— 情报岛「攻击对象」行的数据源（白名单制）
///   ① card_attack_target_data()    白名单：卡片 → target_type（形态差异写成数组）
///      只在表里（或例外区）的卡才显示这一行，没列出的一律不显示。
///   ② card_attack_target_exclude() 生成了也不显示的卡（写了 target_type 但实际不出伤害）
///   ③ card_attack_target_override() 口径与 target_type 对不上的卡，手写覆盖（按形态）
///      写了这里的卡不再写进 ①，显示只读这里
///   ④ card_attack_text()           拼成「陆军丨地鼠丨潜水丨空军丨幽灵鼠丨非主流丨障碍」（官服名字与顺序）
///   ①② 由 桌面/fvm的ai/生成卡牌可攻击表.py 维护，③ 手写脚本不动。
///   判定口径的唯一真相仍是 scripts/can_target_on。
/// =====================================================================

function card_attack_target_data()
{
    static _d = {
        "aquarius_elve": "normal",
        "athena": "track",
        "bbq": "normal",
        "beef_hotpot": "pierce",
        "brahma": "normal",
        "bull_firework": "normal",
        "caihongshe": "normal",
        "cat_box": "normal",
        "cat_chest": "normal",
        "chili_powder": "normal",
        "chocolate_cannon": "all",
        "chocolate_pult": "throw",
        "chunsun": "all",
        "coal_starfish": "normal",
        "coffee_cup": "normal",
        "coffee_pot": "pierce",
        "coke_bomb": "all",
        "cold_drew": "track_under",
        "corn_shooter": "normal",
        "curry_lobster_cannon": "track",
        "dandantu": "normal",
        "dangdanghu": "throw",
        "delicacy_firework": "normal",
        "dianman": "rotate",
        "donut": "air",
        "double_blade_snake": "normal",
        "double_ice_long_bao": "normal",
        "double_long_bao": "normal",
        "double_water_pipe": "normal",
        "doumaobang": ["normal", "track", "track", "track"],
        "dragon_fruit": ["d_fruit", "all", "all", "all"],
        "durian": "rotate",
        "egg_boiler_pult": "throw",
        "eightcake": "throw",
        "fangkongmiao": "air_only",
        "fashishe": "normal",
        "fenjima": "normal",
        "fishbone": "pierce",
        "flour_sack": "normal",
        "gaia": "track",
        "galaxy_horse": "all",
        "gatlin_ice_long_bao": "normal",
        "gatlin_long_bao": "normal",
        "ghost_god": "normal",
        "gongjiang_god": "air",
        "grilled_lizard_pult": "throw",
        "guangming_god": ["d_fruit", "all", "all", "all"],
        "guiyuanma": "normal",
        "hamburger": "throw",
        "heian_god": "all",
        "hera": "normal",
        "honeytrap": "all",
        "hotdog_cannon": "air",
        "houyi_god": "normal",
        "huagao": "normal",
        "huanyingshe": "throw",
        "hundun_god": "normal",
        "huojianzhu": "track",
        "ice_bucket_bomb": "normal",
        "ice_egg_boiler_pult": "throw",
        "ice_god": ["track", "track", "track", "track_under"],
        "ice_long_bao": "normal",
        "iron_fishbone": "pierce",
        "jiejiema": "land_air_ug",
        "joker": "track_under",
        "juxie": "track",
        "kettle_bomb": "normal",
        "king_long_bao": "normal",
        "king_triple_long_bao": "normal",
        "kuileima": "all",
        "laipishe": "air",
        "lizi_god": "throw",
        "love_god": "normal",
        "mianbao": "all",
        "mixian": "all",
        "mojie": "normal",
        "moon_god": "track",
        "niuyouguo": "air",
        "nizhuanniu": "all",
        "nut_frier": "normal",
        "oden_pot": "pierce",
        "odin": "normal",
        "pan_fried_bun": "throw",
        "panduola_god": "all",
        "pizza_oven": "air",
        "poseidon": "all",
        "power_god": "air_only",
        "pufferfish": "all",
        "qiedanlong": "throw",
        "qingse_shishi": ["normal", "normal", "all", "all"],
        "qishui": "normal",
        "rabbit_lantern": "all",
        "rig": "normal",
        "ronghedan_god": "throw",
        "ronghedapao": "all",
        "ronghehaixing": "track",
        "ronghehuopen": "normal",
        "ronghekafei": "normal",
        "ronghesanxian": "normal",
        "rongheshuanggu": "air",
        "rotating_coffee_pot": "rotate",
        "salad_pult": "throw",
        "sausage": "air",
        "sheshou": "normal",
        "shennong_god": ["normal", "normal", "land_air_ug", "land_air_ug"],
        "shiliu_baobao_bing": "all",
        "shizi": "all",
        "shuanggu": "air",
        "shuangyu": "throw",
        "skewer_bomb": "normal",
        "snowrabbit": "track_under",
        "spicy_pot": "pierce",
        "spoon_rabbit": "throw",
        "starrabbit": "normal",
        "steel_wool": "all",
        "stinky_tofu_pult": "throw",
        "sugar_ball_pult": "throw",
        "sugar_roxburghii": "pierce",
        "takoyaki": "track",
        "tanchitu": "normal",
        "tang_hu_lu": "air_only",
        "tangchaolizi": "throw",
        "tanhuanghu": "air",
        "tar_sprayer": "pierce",
        "thor": "throw",
        "tiancheng": "normal",
        "time_god": "all",
        "triple_ice_long_bao": "normal",
        "triple_long_bao": "normal",
        "triple_wine_rack": "normal",
        "tunshilong": "all",
        "war_god": "normal",
        "water_tea_cup": "normal",
        "whisky_bomb": "normal",
        "wine_bottle_bomb": "normal",
        "wugushe": "all",
        "xiandima": "all",
        "xiao_long_bao": "normal",
        "xinjiang_fried_noodles": "normal",
        "xuanzhuan_ronghe": "rotate",
        "yanhuangma": "normal",
        "yeziguo": "normal",
        "yinghuoshe": "all",
        "ymir": "throw",
        "youyu_god": "normal",
        "yuanqiniu": "rotate",
        "yuansushe": "normal",
        "yufengma": "normal",
        "zeus": "track",
        "zhuanzhuanji": "rotate",
        "zhurong": "throw",
        "zhuzhuliaoliji": "normal"
    };
    return _d;
}

function card_attack_target_exclude()
{
    return [
        "12yinliao",      // 纯辅助：全屏回满体力；Destroy 里那颗 3x3 爆炸是模板副作用，不算攻击范围
        "sheshejiu", "shiguangji", "xuanfengniu", "zhuanlonghu"
    ];
}

function card_attack_target_override()
{
    static _o = {
        "tianxie": "陆军",
        "yinyangshe": "陆军丨幽灵鼠丨障碍",   // 阴蛇可打未显形幽灵；无「非主流」（穿透是二转阳蛇的子弹属性）
        "sheng_huo": ["陆军丨幽灵鼠丨非主流丨障碍", "陆军丨幽灵鼠丨非主流丨障碍", "陆军丨地鼠丨空军丨幽灵鼠丨非主流丨障碍", "陆军丨地鼠丨空军丨幽灵鼠丨非主流丨障碍"],
        "jingangma": "陆军丨潜水丨空军丨幽灵鼠",
        "hongliukaochuan": "陆军丨潜水丨空军丨幽灵鼠",
        "hufa_god": ["陆军丨潜水丨空军丨幽灵鼠", "陆军丨潜水丨空军丨幽灵鼠",
                     "陆军丨潜水丨空军丨幽灵鼠丨地鼠", "陆军丨潜水丨空军丨幽灵鼠丨地鼠"],
        "gaia": "陆军丨地鼠丨潜水丨空军丨障碍",
        // 萤火蛇：3×3 范围伤害，排除地鼠 / 非主流 / 幽灵（表 13.辅助 r69、r72），其余全打
        "yinghuoshe": "陆军丨潜水丨空军丨障碍"
    };
    return _o;
}

function card_attack_target_of(_id, _shape)
{
    var _d = card_attack_target_data();
    if (!variable_struct_exists(_d, _id)) return "normal";
    var _v = _d[$ _id];
    if (is_array(_v)) return _v[clamp(_shape, 0, array_length(_v) - 1)];
    return _v;
}

function card_attack_text(_id, _shape)
{
    var _o = card_attack_target_override();
    if (variable_struct_exists(_o, _id)) {
        var _ov = _o[$ _id];
        if (is_array(_ov)) return _ov[clamp(_shape, 0, array_length(_ov) - 1)];
        return _ov;
    }
    static _m = {
        "normal":     "陆军丨障碍",
        "throw":      "陆军丨潜水",
        "track":      "陆军丨潜水丨空军",
        "air":        "陆军丨空军",
        "air_only":   "空军",
        "pierce":     "陆军丨幽灵鼠丨非主流丨障碍",
        "rotate":     "陆军丨地鼠丨空军丨幽灵鼠丨非主流丨障碍",
        "d_fruit":    "陆军丨地鼠丨空军丨幽灵鼠丨非主流丨障碍",
        "land_air_ug": "陆军丨地鼠丨空军丨障碍",
        "track_under": "陆军丨地鼠丨潜水丨空军",
        "all":        "陆军丨地鼠丨潜水丨空军丨幽灵鼠丨非主流丨障碍"
    };
    var _t = card_attack_target_of(_id, _shape);
    if (variable_struct_exists(_m, _t)) return _m[$ _t];
    return "陆军";
}

function card_attack_shown(_id)
{
    if (array_contains(card_attack_target_exclude(), _id)) return false;
    if (variable_struct_exists(card_attack_target_override(), _id)) return true;
    return variable_struct_exists(card_attack_target_data(), _id);
}

/// =====================================================================
/// card_special_flags —— 卡片「特殊身份」事实表
///   结构：**按身份分组登记**（card_flag_add 批量写布尔列，card_flag_set 写取值列）。
///         新卡 = 往对应那组的 id 数组里加一个，所有读名单的地方一起生效。
///
///   只保留四类「特殊卡」的名单；**不占格一律直接读实例的 `plant_type == "gridless"`**，
///   本表不再维护第二份不占格名单：
///
///   一、冷却（缩 CD 的施放者 / 目标口径）
///     cd_reducer   —— 缩 CD 的施放者本身（互为施放者不互缩；也不能被复制，防无限刷）
///     cd_extra     —— **取值型**：某施放者的额外缩 CD 白名单（当前只有时间神 → 蜜糖陷阱 / 仙笛马）
///   二、复制
///     no_copy      —— 不能当「复制 / 变身 / 读上一张」的源卡（复制类 8 张 + 冷却卡 + 一次性变身 / 替身）
///     copy_ok      —— 放行复制（目前只有时间神：它虽是施放者但可被复制 / 复活；所以它**不在**下面的不计死亡名单里）
///   三、复活
///     no_death_record —— 死了不进 global.dead_cards，即自动成为**复活黑名单**
///   四、变星
///     star_changer —— 变星施放者（克洛托 / 蛇蛇酒 / 时光机）：**彼此之间不能互相变星**
///
///   辅助列（不是「特殊卡身份」，是别的系统要的事实）：
///     eatable         —— 不占格、但原版老鼠能啃的卡（蜜糖陷阱 / 仙笛马）
///     mutex           —— 取值型：放置互斥类名（同格不能放同类名）
///     hazard_fire     —— 子弹可过火（**只给情报岛「可用增幅」用**，战斗判定在子弹对象里）
///     hazard_rebound  —— 子弹可被反弹（同上）
///
///   🔴 不要在各对象里另抄名单，也别新建第二张表。
///   🔴 唯一写在对象里的例外：**极寒冰沙（冰激凌 2 转）刷新全体卡槽** —— 那是它自己 shape==2 的分支，
///      调用时传 `_ignore_all = true`，不在本表标记。
/// =====================================================================

/// @func card_flag_data()
/// @desc 卡片特殊身份总表：card_id → { 列名: true / 值 }（首次调用建好，之后走缓存）
function card_flag_data(){
    if (variable_global_exists("card_flag_cache")) return global.card_flag_cache;

    var _t = {};

    // ── 一、冷却 ────────────────────────────────────────────────────
    // 缩 CD 的施放者本身（4 张；时间神另有一份额外白名单，见下）
    card_flag_add(_t, [
        "ice_cream", "meiweijishiqi", "time_god", "zhuanlonghu",
    ], ["cd_reducer"]);
    // 🔴 蛇羹煲不需要单独挂「不能缩 CD」：它用完就从场地消失，时间神 / 转龙壶 / 计时器 都是
    //    「扫场上 obj_card_parent 的 plant_id」再刷卡槽，扫不到它；只有冰激凌二转（直接扫卡槽）能刷到
    //    —— 这正是用户要的「只能被冰激凌二转这个特例冷却」。
    // 施放者的额外白名单：写成「谁 → 能缩谁」，一处维护
    //   （时间神能缩的两张不占格卡；转龙壶 / 计时器 / 冰激凌都没有这份名单）
    card_flag_set(_t, "time_god", "cd_extra", ["honeytrap", "xiandima"]);

    // ── 二、复制 ────────────────────────────────────────────────────
    // 复制类 / 一次性变身 / 替身：不能当复制源，也不记死亡
    card_flag_add(_t, [
        "brahma", "magic_chicken", "ice_cream", "shegengbao", "baibianshe", "xingqiongma", "kuileima",
        // 复制类：万匹龙 / 黯然销魂饭 / 重生神 / 离禾（复制卡之间不能互抄；离禾同时不计死亡）
        "wanpilong", "anranxiaohunfan", "chongsheng_god", "lihe",
    ], ["no_copy", "no_death_record"]);
    // 时间神是特例：它是施放者，但可以被复制 / 复活
    card_flag_add(_t, ["time_god"], ["copy_ok"]);

    // ── 三、复活（= 不计死亡的名单）─────────────────────────────────
    card_flag_add(_t, [
        "12yinliao", "anranxiaohunfan", "aquarius_elve", "baiyang", "baobaoji", "bull_firework", "chili_powder",
        "chongsheng_god", "chunsun", "clotho", "coffee_grounds", "coke_bomb", "cotton_candy", "dandantu",
        "delicacy_firework", "dragon_fruit", "durian", "firework_dragon", "firework_dragon_real", "flour_sack", "heian_god",
        "hundun_god", "ice_bucket_bomb", "kettle_bomb", "mojie", "mouse_clip", "nizhuanniu", "panduola_god",
        "pufferfish", "qingse_shishi", "rabbit_lantern", "save_god", "shiliu_baobao_bing", "shuiping", "skewer_bomb",
        // 🔴 time_god 不在本名单：它标了 copy_ok（可被复制 / 复活），排进不计死亡就永远进不了 dead_cards
        "steel_wool", "ventilation_fan", "wanpilong", "whisky_bomb", "wine_bottle_bomb", "wooden_cork",
        "xuanfengniu", "yeziguo", "zhanqima", "zhiyumiao",
    ], ["no_death_record"]);

    // ── 四、变星：施放者之间不能互变 ────────────────────────────────
    card_flag_add(_t, ["clotho", "sheshejiu", "shiguangji"], ["star_changer"]);

    // ── 辅助列 ──────────────────────────────────────────────────────
    // 不占格、但老鼠能啃（gridless 进不了 eat_order，靠这一列按 normal 档参与）
    card_flag_add(_t, ["honeytrap", "xiandima"], ["eatable"]);

    // 子弹可过火（火盆类增幅：火盆 / 火神 / 金牛座 / 能量喵 / 融合火盆）
    //   口径来源：子弹 Create 里的 hazard_fire（与官方 xlsx 11.直射 r92 一致）
    //   共享弹别漏：小笼包系变体共用 obj_xiaolongbao_bullet / obj_icelongbao_bullet，生肖弹共用 obj_zodiac_projectile
    card_flag_add(_t, [
        "bbq", "corn_shooter", "double_ice_long_bao", "double_long_bao",
        "double_water_pipe", "fashishe", "fenjima", "gatlin_ice_long_bao",
        "gatlin_long_bao", "guiyuanma", "houyi_god", "ice_long_bao",
        "king_triple_long_bao", "love_god", "mianbao", "nut_frier",
        "odin", "ronghesanxian", "rongheshuanggu", "sheshou",
        "shuanggu", "starrabbit", "tar_sprayer", "tiancheng",
        "triple_ice_long_bao", "triple_long_bao", "triple_wine_rack", "war_god",
        "xiandima", "xiao_long_bao", "yanhuangma", "yinyangshe", "youyu_god",
        "yufengma", "zhuzhuliaoliji",
    ], ["hazard_fire"]);

    // 子弹可被反弹（反弹类增幅：樱桃布丁 / 布丁汪 / 水神）
    //   生肖弹带 kind_gate（只认 kind = fire / star），归元马 / 仙笛马 / 炎凰马 / 御风马因此不可反弹
    card_flag_add(_t, [
        "bbq", "caihongshe", "coal_starfish", "corn_shooter",
        "double_ice_long_bao", "double_long_bao", "double_water_pipe", "fashishe",
        "fenjima", "gatlin_ice_long_bao", "gatlin_long_bao", "ghost_god",
        "houyi_god", "ice_long_bao", "king_triple_long_bao", "love_god",
        "mianbao", "niuyouguo", "nut_frier", "odin",
        "rig", "ronghehaixing", "ronghesanxian", "rongheshuanggu",
        "sheshou", "shuanggu", "starrabbit", "tiancheng",
        "triple_ice_long_bao", "triple_long_bao", "triple_wine_rack", "war_god",
        "xiao_long_bao", "yinyangshe", "youyu_god", "zhuzhuliaoliji",
    ], ["hazard_rebound"]);

    // 放置互斥类（同一类名的卡不能同格叠放；空 = 不参与互斥）
    //   数据从 scripts/place_mutex_class 的 switch 挪进来，加卡只在事实表这一处登记
    card_flag_set(_t, "honeytrap", "mutex", "gridless_track");   // 蜜糖陷阱 ↔ 仙笛马 同类互斥
    card_flag_set(_t, "xiandima",  "mutex", "gridless_track");
    card_flag_set(_t, "jiejiema",  "mutex", "jiejiema_self");    // 结界马：只跟自己互斥

    global.card_flag_cache = _t;
    return _t;
}

/// @func card_flag_add(_t, _ids, _flags)
/// @desc 把一批卡按同一组标记写进表（id 一律走字符串 key，12yinliao 这种也能用）
///   同一个 id 分多次登记 = 合并标记，不会互相覆盖
function card_flag_add(_t, _ids, _flags){
    for (var _i = 0; _i < array_length(_ids); _i++){
        var _id  = _ids[_i];
        var _row = variable_struct_exists(_t, _id) ? _t[$ _id] : {};
        for (var _j = 0; _j < array_length(_flags); _j++)
            variable_struct_set(_row, _flags[_j], true);
        variable_struct_set(_t, _id, _row);
    }
}

/// @func card_flag_set(_t, _id, _key, _value)
/// @desc 写「取值型」标记（布尔以外，例如 cd_extra 名单数组 / mutex 类名）。同 id 多次写 = 合并
function card_flag_set(_t, _id, _key, _value){
    var _row = variable_struct_exists(_t, _id) ? _t[$ _id] : {};
    variable_struct_set(_row, _key, _value);
    variable_struct_set(_t, _id, _row);
}

/// @func card_flag_value(_id, _key)
/// @desc 读取值型标记；卡不在表里 / 没有这一列 → undefined
function card_flag_value(_id, _key){
    var _t = card_flag_data();
    if (!variable_struct_exists(_t, _id)) return undefined;
    var _row = _t[$ _id];
    if (!variable_struct_exists(_row, _key)) return undefined;
    return _row[$ _key];
}

/// @func card_has_flag(_id, _flag)
/// @desc 查某张卡有没有某个特殊身份；卡不在表里 / 没有这一列 → false
function card_has_flag(_id, _flag){
    var _t = card_flag_data();
    if (!variable_struct_exists(_t, _id)) return false;
    var _row = _t[$ _id];
    if (!variable_struct_exists(_row, _flag)) return false;
    return _row[$ _flag];
}

/// @func card_is_copy_src(_id)
/// @desc 能不能当「复制 / 变身 / 读上一张 / 被记成上一张 / 复活」的源卡
///   排除：no_copy（复制类 / 一次性变身 / 替身 自身）+ cd_reducer（缩 CD 类也不能被复制，防无限刷）
///   例外：`copy_ok` 放行 —— 目前只有时间神（time_god）
///   复活视为复制的一种，所以不另开函数
function card_is_copy_src(_id){
    if (_id == "" || _id == "player") return false;
    if (card_has_flag(_id, "no_copy")) return false;
    if (card_has_flag(_id, "copy_ok")) return true;
    if (card_has_flag(_id, "cd_reducer")) return false;
    return true;
}

/// @func card_records_death(_id)
/// @desc 这张卡死亡时要不要记进 global.dead_cards（星穹马 / 符文马复活就从这里取）
function card_records_death(_id){
    if (_id == "") return false;
    return !card_has_flag(_id, "no_death_record");
}

/// @func card_hazard_flags(_id)
/// @desc 这张卡的子弹能不能过火 / 被反弹 → { burn, rebound }（只读事实表，不给战斗用）
function card_hazard_flags(_id){
    var _t = card_flag_data();
    var _r = variable_struct_exists(_t, _id) ? _t[$ _id] : {};
    return {
        burn:    variable_struct_exists(_r, "hazard_fire"),
        rebound: variable_struct_exists(_r, "hazard_rebound"),
    };
}

/// @func card_cd_category_ok(_id)
/// @desc 缩冷却的**作用面**：官方《陌路 13.辅助 · A.冷却类》r15 原文
///   「使范围内正在冷却的 [生产类|攻击类|护罩类|增幅类|炸弹类|水盘承载类] 卡片的冷却时间减少」
///   → 工程映射：除「辅助类」以外的大分类全部可缩（攻击类 = 直射/投掷/多向/专业防空/喷壶/追踪/非远程/灰烬，
///     炸弹在灰烬里；护罩类 = 防御类）。
///   本工程的「辅助类」比陌路宽，三处例外：
///     · 承载类 / 反弹类 —— 本来是陌路 `6.反弹＆承载`，被我们并进了辅助类；
///     · **场地类** —— 站场卡（萤火蛇 / 油灯 / 换气扇…）本来就不是悬浮卡，放行。
///   没有分类数据的卡不拦（老行为兜底）。
function card_cd_category_ok(_id){
    var _lv = card_get_levels(_id);
    if (array_length(_lv) == 0) return true;
    if (_lv[0] != "辅助类") return true;
    var _minor = (array_length(_lv) > 1) ? _lv[1] : "";
    return (_minor == "承载类" || _minor == "反弹类" || _minor == "场地类");
}

/// @func card_cd_extra_ok(_caster_id, _id)
/// @desc 施放者的**额外缩 CD 白名单**（表里 `cd_extra` 取值列）；没登记 / 不在名单 → false
///   这份名单归施放者所有，所以写成「谁 → 能缩谁」，对象里不用各写一份
function card_cd_extra_ok(_caster_id, _id){
    var _v = card_flag_value(_caster_id, "cd_extra");
    if (is_undefined(_v)) return false;
    return array_contains(_v, _id);
}

/// @func card_cd_target_ok(_id, _caster_id = "", _gridless = false, _ignore_all = false)
/// @desc 「缩减冷却」能不能作用到目标卡 —— 按顺序：
///   ① `cd_reducer`（施放者本身，含冰激凌自己）→ 不缩（放在最前面，`_ignore_all` 也绕不过）
///   ② `_ignore_all`：极寒冰沙 2 转（官方「冷却除自身外的全部卡槽」）→ 放行
///   ③ 施放者的**额外白名单**（`cd_extra`：时间神 → 蜜糖陷阱 / 仙笛马）→ 放行
///   ④ 分类作用面（`card_cd_category_ok`）→ 不在名单 → 不缩
///   ⑤ **底层兜底：不占格（gridless）的卡一律不缩** —— 即使第 ④ 关放行，也只能靠第 ③ 关进
///   `_gridless` 由调用方直接传实例的 `plant_type == "gridless"`，本表不再维护不占格名单。
function card_cd_target_ok(_id, _caster_id = "", _gridless = false, _ignore_all = false){
    if (_id == "" || _id == "player") return false;
    // 🔴 必须先判施放者：`_ignore_all` 之前 —— 否则冰激凌二转连自己（和别的冷却卡）的槽也刷，能无限刷
    if (card_has_flag(_id, "cd_reducer")) return false;
    if (_ignore_all) return true;
    if (card_cd_extra_ok(_caster_id, _id)) return true;
    if (!card_cd_category_ok(_id)) return false;
    if (_gridless) return false;
    return true;
}

/// @func card_buff_note(_id)
/// @desc 可用增幅行的自定义括号文本（空 = 不显示括号）。
///   只填「有条件才吃」且**文案里不方便写**的特例；文本自由写、要精确到段就写清是哪一段：
///     例：某卡过火只给正后那一发、反弹不限方向 → 写「过火仅后向子弹」，别只写「仅后向子弹」
///   🔴 猪猪料理机 / 火影怪味鱿鱼的过火限制已写进情报岛正文，这里不留条目（2026-11-14 用户口径），
///      以后要恢复显示，把 id 加回下表即可。
function card_buff_note(_id){
    static _t = {
    };
    if (!variable_struct_exists(_t, _id)) return "";
    return _t[$ _id];
}

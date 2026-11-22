function craft_rule_registry_init(){
	global.card_craft_rules = ds_map_create()
	global.gem_craft_rules = ds_map_create()
}

function register_card_craft_rule(target_level,info){
	ds_map_add(global.card_craft_rules,target_level,info)
}

function get_card_craft_rule(target_level){
	return ds_map_find_value(global.card_craft_rules,target_level)
}

function register_gem_craft_rule(target_level,info){
	ds_map_add(global.gem_craft_rules,target_level,info)
}

function get_gem_craft_rule(target_level){
	return ds_map_find_value(global.gem_craft_rules,target_level)
}

function craft_rule_init(){
	craft_rate_settings_init()
	craft_rule_registry_init()
	// ── 卡片强化 1~16★：**只剩金币** ────────────────────────────────────
	//   香料 / 四叶草 不再是「固定档位 + 数量门槛」，改成玩家自己往三槽里放（2026-11-19 v7）；
	//   每槽消耗只看目标星，从 scripts/mod_craft_rate_table 的 craft_cost_info() 取。
	//   这里的 gold_amount 也直接从同一张表取，改价只改 craft_cost_table()。
	for (var _t = 1; _t <= 16; _t++){
		register_card_craft_rule(string(_t), { "gold_amount": craft_cost_info(_t).gold })
	}

	register_gem_craft_rule(
		"1",
		{
		"crystal_require":"less_crystal",
		"crystal_amount":5,
		"gold_amount":300
		}
	)
	register_gem_craft_rule(
		"2",
		{
		"crystal_require":"less_crystal",
		"crystal_amount":10,
		"gold_amount":300
		}
	)
	register_gem_craft_rule(
		"3",
		{
		"crystal_require":"less_crystal",
		"crystal_amount":15,
		"gold_amount":300
		}
	)
	register_gem_craft_rule(
		"4",
		{
		"crystal_require":"less_crystal",
		"crystal_amount":25,
		"gold_amount":300
		}
	)
	register_gem_craft_rule(
		"5",
		{
		"crystal_require":"less_crystal",
		"crystal_amount":35,
		"gold_amount":300
		}
	)
	register_gem_craft_rule(
		"6",
		{
		"crystal_require":"middle_crystal",
		"crystal_amount":55,
		"gold_amount":400
		}
	)
	register_gem_craft_rule(
		"7",
		{
		"crystal_require":"middle_crystal",
		"crystal_amount":75,
		"gold_amount":400
		}
	)
	register_gem_craft_rule(
		"8",
		{
		"crystal_require":"middle_crystal",
		"crystal_amount":100,
		"gold_amount":700
		}
	)
	register_gem_craft_rule(
		"9",
		{
		"crystal_require":"middle_crystal",
		"crystal_amount":130,
		"gold_amount":700
		}
	)
	register_gem_craft_rule(
		"10",
		{
		"crystal_require":"middle_crystal",
		"crystal_amount":160,
		"gold_amount":1300
		}
	)
	register_gem_craft_rule(
		"11",
		{
		"crystal_require":"advanced_crystal",
		"crystal_amount":200,
		"gold_amount":2600
		}
	)
	register_gem_craft_rule(
		"12",
		{
		"crystal_require":"advanced_crystal",
		"crystal_amount":245,
		"gold_amount":2600
		}
	)
	register_gem_craft_rule(
		"13",
		{
		"crystal_require":"advanced_crystal",
		"crystal_amount":300,
		"gold_amount":5200
		}
	)
	register_gem_craft_rule(
		"14",
		{
		"crystal_require":"advanced_crystal",
		"crystal_amount":355,
		"gold_amount":5200
		}
	)
	register_gem_craft_rule(
		"15",
		{
		"crystal_require":"advanced_crystal",
		"crystal_amount":420,
		"gold_amount":10000
		}
	)
}

#region 概率强化：参数、公式与判定
// 🔴 2026-11-19 起：**卡片**强化不再走这一套（改查 mod_craft_rate_table 的原版矩阵），
//    但**宝石**还在用（分段衰减 + 浮动 + 保底），所以这些参数一个都不能删（M74）。
function craft_rate_settings_init(){
	var _assure = false
	if !is_undefined(global.craft_assure_enabled) _assure = global.craft_assure_enabled
	global.craft_rate = {
		// 卡片页的「概率强化」勾选框已删除（2026-11-19 用户口径）→ 恒为 true；
		// 宝石没有勾选框，同样恒为 true（关掉时 craft_roll 直接成功，宝石就没概率了）
		enabled: true,
		// 掉星门槛：6★ 起失败降 1 星（卡片用 craft_can_drop()，这里留兼容）
		dropstar_min: 5,
		assure_enabled: _assure,
	// 升星率：分段衰减（**宝石专用**）。1★ 固定必成；2★ 起逐级乘衰减并取整，换挡点见 tierN_at
	// 现值 → 1★ 100 / 2-5★ 90..66（-0.90）/ 6★ 49（-0.74，台阶）/ 7-9★ 43..32（-0.87）/ 10★ 16（-0.50，跳楼）/ 11-15★ 11..3（-0.70）/ 16★ 1（-0.34）
		rate_base: 100, rate_max: 100, rate_min: 1,
		// 随机浮动：每个宝石各自一个随机值 r(-1~1)，启动时随第一次用到生成、本次启动内固定。
		spread_ratio: 0.08, spread_max_level: 11, spread_flat: 0.57,
		tier1_decay: 0.90, tier2_at: 6, tier2_decay: 0.74,
		tier3_at: 7, tier3_decay: 0.87, tier4_at: 10, tier4_decay: 0.50,
		tier5_at: 11, tier5_decay: 0.70, tier6_at: 16, tier6_decay: 0.34,
		pity_bonus_min: 4, pity_bonus_max: 7,
		// 失败补偿最多累计 N 次：第 N+1 次起失败不再加成功率（成功升星会清零，不残留）
		pity_bonus_max_stack: 5,
		// 保底：连续失败满 N 次后强制必成。0 = 关闭（2026-10-14 按用户要求关掉，只剩每次失败的随机加成），需要时改回 5
		pity_guarantee: 0,
		fail_material_ratio: 1.0,
		fail_gold_ratio:     1.0
	}
}

function craft_rate_settings(){
	if is_undefined(global.craft_rate) craft_rate_settings_init()
	return global.craft_rate
}

/// @func craft_dropstar_can_drop(current_level)
/// @desc 强化失败是否掉星：**6★ 起掉**（当前星 > 5），5★ 及以下免疫。
///       卡片走 craft_can_drop()（mod_craft_rate_table），这里只是同口径的旧名
function craft_dropstar_can_drop(current_level){
	return current_level > 5
}

/// @func craft_rate_base(target_level)
/// @desc 分段衰减的基础升星率（不含保底）：1★ 必成，其后逐级乘当前档位的衰减并取整
function craft_rate_base(target_level){
	var _s = craft_rate_settings()
	if target_level <= 1 return _s.rate_max
	var _rate = _s.rate_base
	for (var _lv = 2; _lv <= target_level; _lv++){
		if _lv >= _s.tier6_at _rate *= _s.tier6_decay
		else if _lv >= _s.tier5_at _rate *= _s.tier5_decay
		else if _lv >= _s.tier4_at _rate *= _s.tier4_decay
		else if _lv >= _s.tier3_at _rate *= _s.tier3_decay
		else if _lv >= _s.tier2_at _rate *= _s.tier2_decay
		else _rate *= _s.tier1_decay
		_rate = round(_rate)
	}
	return clamp(_rate, _s.rate_min, _s.rate_max)
}

/// @func craft_rate_spread(id)
/// @desc 该宝石本次启动的随机浮动值（-1 ~ 1）：每个 id 各自独立，本次启动内固定不变
function craft_rate_spread(_id){
	if _id == "" return 0
	if is_undefined(global.craft_rate_spread) global.craft_rate_spread = {}
	var _key = string(_id)
	if variable_struct_exists(global.craft_rate_spread, _key){
		return variable_struct_get(global.craft_rate_spread, _key)
	}
	var _spread = random_range(-1, 1)
	variable_struct_set(global.craft_rate_spread, _key, _spread)
	return _spread
}

/// @func craft_rate_rolled(id, target_level)
/// @desc 带随机浮动的基础升星率（不含保底，保留小数）：1★ 必成不浮动；
///       2★~spread_max_level 按比例浮动，其之上按固定点数浮动（幅度更小）
function craft_rate_rolled(_id, target_level){
	var _s = craft_rate_settings()
	var _rate = craft_rate_base(target_level)
	if target_level <= 1 return _rate
	var _r = craft_rate_spread(_id)
	if target_level <= _s.spread_max_level return min(_rate * (1 + _r * _s.spread_ratio), _s.rate_max)
	return clamp(_rate + _r * _s.spread_flat, _s.rate_min, _s.rate_max)
}

function craft_rate_with_pity(_id, target_level, bonus, fail_streak){
	var _s = craft_rate_settings()
	if !_s.enabled return 100
	var _rate = craft_rate_rolled(_id, target_level)
	if is_undefined(bonus) bonus = 0
	if is_undefined(fail_streak) fail_streak = 0
	_rate += bonus
	if _s.pity_guarantee > 0 && fail_streak >= _s.pity_guarantee _rate = 100
	return clamp(_rate, 0, 100)
}

// 宝石专用是 get_gem_craft_rate / get_gem_craft_rate_base；卡片已改查原版矩阵，
// 下面三个卡片版函数只保留给旧调用点，返回 100（别在新代码里用）
function get_card_craft_rate(card_id, target_level, bonus, fail_streak){
	return 100
}

// 宝石强化固定 100%：卡片的「强化概率」只管卡片，不许波及宝石。
//   🔴 别把宝石接回强化概率（分段衰减 + 浮动 + 保底）—— 那会表现成「宝石也会失败」。
function get_gem_craft_rate(gem_id, target_level, bonus, fail_streak){
	return 100
}

function get_card_craft_rate_base(card_id, target_level){
	return 100
}

function get_gem_craft_rate_base(gem_id, target_level){
	return 100
}

function get_card_craft_rate_now(card_id){
	return 100
}

function get_gem_craft_rate_now(gem_id){
	if gem_id == "" return 0
	return 100
}

function craft_roll(rate){
	if !craft_rate_settings().enabled return true
	return random(100) < rate
}

function craft_rate_color(rate){
	if rate >= 80 return c_lime
	if rate >= 50 return c_yellow
	if rate >= 25 return c_orange
	return c_red
}
#endregion

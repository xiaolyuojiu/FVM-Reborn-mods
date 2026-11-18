function material_sell_init(){
	global.material_sell_prices = {}
	global.material_sell_prices[$ "clover_1"] = 2000
	global.material_sell_prices[$ "clover_2"] = 3000
	global.material_sell_prices[$ "clover_3"] = 4000
	global.material_sell_prices[$ "clover_4"] = 5000
	global.material_sell_prices[$ "clover_5"] = 10000
	global.material_sell_prices[$ "clover_6"] = 20000
	// 6 级以上统一「每级 +2w」：S 6万 / SS 8万 / SSS 10万 / SSR 12万 / 蛇·马 14万
	//   2026-11-20 修正：S / SS 原来还是旧的翻倍价（8万 / 16万），跟 SSS 起的 +2w 序列接不上，
	//   而且会出现「SSS 比 S 便宜」的倒挂，这里按等级顺序重新排一遍
	//   蛇年 / 马年强化倍率同为 ×4.2 → **同价**，别再给马年单独加一档
	global.material_sell_prices[$ "clover_s"] = 30000
	global.material_sell_prices[$ "clover_ss"] = 40000
	global.material_sell_prices[$ "clover_sss"] = 50000
	global.material_sell_prices[$ "clover_ssr"] = 60000
	global.material_sell_prices[$ "clover_snake"] = 70000
	global.material_sell_prices[$ "clover_horse"] = 70000
	// 上等 / 极品香料回收价（2026-11-19 用户口径）
	global.material_sell_prices[$ "superior_spices"] = 45
	global.material_sell_prices[$ "supreme_spices"] = 75
	global.material_sell_prices[$ "magic_spices"] = 100
	global.material_sell_prices[$ "elf_spices"] = 120
	global.material_sell_prices[$ "angel_spices"] = 150
	global.material_sell_prices[$ "saint_spices"] = 180

	// ── 1~15★ 强化用卡回收价（2026-11-20，按「阶段可卖出总价」定）──
	//   原则：不看卡包/香料本身，只看**这一关原来能卖多少钱**。
	//   一关掉 3 张 → 3 张卡包卖出去 = 该关原来掉落的香料总价（1:1 等效，阶段收益不变）。
	//   现状样本（datafiles/level_data/rewards）：
	//     1★ 曲奇/色拉 20 天然 = 600        → 200/张（3 张 600）
	//     2★ 慕斯/香槟 30 天然 = 900        → 300/张（3 张 900）
	//     3★ 神殿 60 天然 = 1,800 / 香槟水 30 = 900 → 450/张（中值 1,350）
	//     4★ 布丁/可可 40 天然 = 1,200      → 400/张（3 张 1,200）
	//     5★ 可可夜 50 / 咖喱 50~75 = 1,500~2,250 → 600/张（中值 1,800）
	//     6★ 深渊 150 天然 = 4,500 / 戚风 100 秘制 = 6,000 → 1,700/张（中值 5,100）
	//     7★ 薄荷 100 = 6,000 / 芝士城堡 200 = 12,000 → 2,800/张（中值 8,400）
	//     8★ 炭烧 150 = 9,000 / 抹茶 200 = 12,000 / 玛奇朵 400 = 24,000 → 5,000/张
	//     9★ 棉花糖 250 = 15,000 / 果酱 300 = 18,000 / 珊瑚 200 = 12,000 → 5,000/张
	//   10★ 段（Lv35~60，37 关）掉落跨度极大：茴香竹筏/冰啤酒吧一关 18,000，
	//      到奶昔/圣代一关 324,000~432,000，折成每张 6,000 ~ 144,000，中位 21,000、平均 34,000。
	//      这里取**段内最低关**（18,000÷3 = 6,000）作基准 —— 那是「刚进 10★」的收益，
	//      高关掉落属于后期刷金奖励，不能拿来当回收价，否则跨服 58 银换的卡包能反手卖 3 万+。
	//   11★ 起没有掉落（只走跨服），按 10★ 每档 +2,000 递增。
	global.material_sell_prices[$ "warcard_1"] = 200
	global.material_sell_prices[$ "warcard_2"] = 300
	global.material_sell_prices[$ "warcard_3"] = 450
	global.material_sell_prices[$ "warcard_4"] = 500        // 2026-11-21：原 400 是打错，3★450 > 4★400 倒挂（一键强化会为省 50 金去烧更贵的 4★）
	global.material_sell_prices[$ "warcard_5"] = 600
	global.material_sell_prices[$ "warcard_6"] = 1700
	global.material_sell_prices[$ "warcard_7"] = 2800
	global.material_sell_prices[$ "warcard_8"] = 5000
	global.material_sell_prices[$ "warcard_9"] = 6000
	global.material_sell_prices[$ "warcard_10"] = 8000
	global.material_sell_prices[$ "warcard_11"] = 10000
	global.material_sell_prices[$ "warcard_12"] = 30000
	global.material_sell_prices[$ "warcard_13"] = 50000
	global.material_sell_prices[$ "warcard_14"] = 70000
	global.material_sell_prices[$ "warcard_15"] = 90000
	global.material_sell_prices[$ "advanced_crystal"] = 300
	global.material_sell_prices[$ "natural_spices"] = 30
	global.material_sell_prices[$ "secret_spices"] = 60
	global.material_sell_prices[$ "royal_spices"] = 90
	global.material_sell_prices[$ "less_crystal"] = 75
	global.material_sell_prices[$ "middle_crystal"] = 150
	global.material_sell_prices[$ "cross_server_gold_medal"] = 200
	global.material_sell_prices[$ "cross_server_silver_medal"] = 100
}

function get_material_sell_price(material_id){
	if variable_global_exists("material_sell_prices") && variable_struct_exists(global.material_sell_prices, material_id){
		return global.material_sell_prices[$ material_id]
	}
	return 0
}

function material_init(){
	material_registry_init()
	register_material("natural_spices",{"name":"天然香料",
										"description":"可在假期特惠活动中兑换为对应强化用卡",
										"icon":0,
										"pos_x":0,
										"pos_y":0})
	register_material("secret_spices",{"name":"秘制香料",
										"description":"可在假期特惠活动中兑换为对应强化用卡",
										"icon":1,
										"pos_x":2,
										"pos_y":0})
	register_material("royal_spices",{"name":"皇室香料",
										"description":"可在假期特惠活动中兑换为对应强化用卡",
										"icon":2,
										"pos_x":4,
										"pos_y":0})
	// ── 金马盛典新增：13~16★ 香料（皇室香料只到 12★，2026-11-17 用户口径）──
	// icon 15~18 = spr_craft_material 追加帧（tools/add_zz_material_frames.py）
	register_material("magic_spices",{"name":"魔幻香料",
										"description":"可在假期特惠活动中兑换为对应强化用卡",
										"icon":15,
										"pos_x":5,
										"pos_y":0})
	register_material("elf_spices",{"name":"精灵香料",
										"description":"可在假期特惠活动中兑换为对应强化用卡",
										"icon":16,
										"pos_x":6,
										"pos_y":0})
	register_material("angel_spices",{"name":"天使香料",
										"description":"可在假期特惠活动中兑换为对应强化用卡",
										"icon":17,
										"pos_x":7,
										"pos_y":0})
	register_material("saint_spices",{"name":"圣灵香料",
										"description":"可在假期特惠活动中兑换为对应强化用卡",
										"icon":18,
										"pos_x":8,
										"pos_y":0})
	// ── 10~15★「X星强化用卡」（2026-11-20）：1 个 = 1 槽，不吃份数 ──
	register_material("warcard_1",{"name":"1星强化用卡",
										"description":"可作为1星级强化副卡",
										"icon":30,
										"pos_x":0,
										"pos_y":5})
	register_material("warcard_2",{"name":"2星强化用卡",
										"description":"可作为2星级强化副卡",
										"icon":31,
										"pos_x":1,
										"pos_y":5})
	register_material("warcard_3",{"name":"3星强化用卡",
										"description":"可作为3星级强化副卡",
										"icon":32,
										"pos_x":2,
										"pos_y":5})
	register_material("warcard_4",{"name":"4星强化用卡",
										"description":"可作为4星级强化副卡",
										"icon":33,
										"pos_x":3,
										"pos_y":5})
	register_material("warcard_5",{"name":"5星强化用卡",
										"description":"可作为5星级强化副卡",
										"icon":34,
										"pos_x":4,
										"pos_y":5})
	register_material("warcard_6",{"name":"6星强化用卡",
										"description":"可作为6星级强化副卡",
										"icon":35,
										"pos_x":5,
										"pos_y":5})
	register_material("warcard_7",{"name":"7星强化用卡",
										"description":"可作为7星级强化副卡",
										"icon":36,
										"pos_x":6,
										"pos_y":5})
	register_material("warcard_8",{"name":"8星强化用卡",
										"description":"可作为8星级强化副卡",
										"icon":37,
										"pos_x":7,
										"pos_y":5})
	register_material("warcard_9",{"name":"9星强化用卡",
										"description":"可作为9星级强化副卡",
										"icon":38,
										"pos_x":8,
										"pos_y":5})
	register_material("warcard_10",{"name":"10星强化用卡",
										"description":"可作为10星级强化副卡",
										"icon":39,
										"pos_x":0,
										"pos_y":6})
	register_material("warcard_11",{"name":"11星强化用卡",
										"description":"可作为11星级强化副卡",
										"icon":40,
										"pos_x":1,
										"pos_y":6})
	register_material("warcard_12",{"name":"12星强化用卡",
										"description":"可作为12星级强化副卡",
										"icon":41,
										"pos_x":2,
										"pos_y":6})
	register_material("warcard_13",{"name":"13星强化用卡",
										"description":"可作为13星级强化副卡",
										"icon":42,
										"pos_x":3,
										"pos_y":6})
	register_material("warcard_14",{"name":"14星强化用卡",
										"description":"可作为14星级强化副卡",
										"icon":43,
										"pos_x":4,
										"pos_y":6})
	register_material("warcard_15",{"name":"15星强化用卡",
										"description":"可作为15星级强化副卡",
										"icon":44,
										"pos_x":5,
										"pos_y":6})
	// ── 上等 / 极品香料（2026-11-17，图标 icon 24 / 25）──
	//   用户口径：先只做图标 + 材料登记，星级用途与商店价格待定（暂无 craft 规则 / 未上架）
	register_material("superior_spices",{"name":"上等香料",
										"description":"可在假期特惠活动中兑换为对应强化用卡",
										"icon":25,
										"pos_x":1,
										"pos_y":0})
	register_material("supreme_spices",{"name":"极品香料",
										"description":"可在假期特惠活动中兑换为对应强化用卡",
										"icon":24,
										"pos_x":3,
										"pos_y":0})
	register_material("clover_1",{"name":"1级四叶草",
										"description":"强化倍率 ×1.2",
										"icon":3,
										"pos_x":0,
										"pos_y":1})
	register_material("clover_2",{"name":"2级四叶草",
										"description":"强化倍率 ×1.4",
										"icon":4,
										"pos_x":1,
										"pos_y":1})
	register_material("clover_3",{"name":"3级四叶草",
										"description":"强化倍率 ×1.7",
										"icon":5,
										"pos_x":2,
										"pos_y":1})
	register_material("clover_4",{"name":"4级四叶草",
										"description":"强化倍率 ×2.0",
										"icon":9,
										"pos_x":3,
										"pos_y":1})
	// ── 金马盛典新增：5 / 6 / S / SS 级四叶草（icon 19~22）──
	register_material("clover_5",{"name":"5级四叶草",
										"description":"强化倍率 ×2.4",
										"icon":19,
										"pos_x":4,
										"pos_y":1})
	register_material("clover_6",{"name":"6级四叶草",
										"description":"强化倍率 ×2.7",
										"icon":20,
										"pos_x":5,
										"pos_y":1})
	register_material("clover_s",{"name":"S级四叶草",
										"description":"强化倍率 ×3.0",
										"icon":21,
										"pos_x":6,
										"pos_y":1})
	register_material("clover_ss",{"name":"SS级四叶草",
										"description":"强化倍率 ×3.2",
										"icon":22,
										"pos_x":7,
										"pos_y":1})
	// ── 2026-11-19 v7 新增四种草（icon 26~29，spr_craft_material 追加帧）──
	//   2026-11-20 新增卡包排在最下面两行：1~9★ 在 y5、10~15★ + SSR/蛇/马 在 y6；原有道具位置一律不动
	//     （背包 package_cols = 9，列只有 0~8，原来 x=9 的 SSR / 马年根本画不出来）
	//   一草一料的口径：SSS 配圣灵 15★、SSR 留给活动加成、蛇年 / 马年同倍率同为活动加成
	register_material("clover_sss",{"name":"SSS级四叶草",
										"description":"强化倍率 ×3.6",
										"icon":26,
										"pos_x":8,
										"pos_y":1})
	register_material("clover_ssr",{"name":"SSR级四叶草",
										"description":"强化倍率 ×4.0",
										"icon":27,
										"pos_x":6,
										"pos_y":6})
	register_material("clover_snake",{"name":"蛇年四叶草",
										"description":"强化倍率 ×4.2",
										"icon":28,
										"pos_x":7,
										"pos_y":6})
	register_material("clover_horse",{"name":"马年四叶草",
										"description":"强化倍率 ×4.2",
										"icon":29,
										"pos_x":8,
										"pos_y":6})
	register_material("less_crystal",{"name":"初级强化水晶",
										"description":"强化1~5星宝石所需材料",
										"icon":6,
										"pos_x":0,
										"pos_y":2})
	register_material("middle_crystal",{"name":"中级强化水晶",
										"description":"强化6~10星宝石所需材料\n在火山岛关卡获取",
										"icon":7,
										"pos_x":1,
										"pos_y":2})
	register_material("advanced_crystal",{"name":"高级强化水晶",
										"description":"强化11~15星宝石所需材料\n等待星际穿越开放获取",
										"icon":8,
										"pos_x":2,
										"pos_y":2})
	register_material("copper_cookbook_fragment",{"name":"铜食谱碎片",
										"description":"解锁上等佳肴槽位所需材料\n在火山遗迹的瀑布遗迹获取",
										"icon":10,
										"pos_x":0,
										"pos_y":3})
	register_material("silver_cookbook_fragment",{"name":"银食谱碎片",
										"description":"解锁秘制佳肴槽位所需材料\n在火山遗迹的丛林遗迹获取",
										"icon":11,
										"pos_x":1,
										"pos_y":3})
	register_material("gold_cookbook_fragment",{"name":"金食谱碎片",
										"description":"解锁极品佳肴槽位所需材料\n在火山遗迹的基地遗迹获取",
										"icon":12,
										"pos_x":2,
										"pos_y":3})
	register_material("oracle_stone",{"name": "神谕之石",
										"description": "神谕之石：在诸神商店兑换神使和凭证所需材料",
										"icon": 13,        // 取决于图集中下一个可用的图标索引
										"pos_x": 4,       // 在背包网格中的显示位置
										"pos_y": 2
	});
	register_material("cross_server_gold_medal",{"name": "黄金徽章",
										"description": "黄金徽章：跨服远征奖励，用于跨服黄金商店兑换",
										"icon": 0,
										"pos_x": 3,
										"pos_y": 2
	});
	register_material("cross_server_silver_medal",{"name": "白银徽章",
										"description": "白银徽章：跨服远征奖励，用于跨服白银商店兑换",
										"icon": 0,
										"pos_x": 3,
										"pos_y": 3
	});
	register_material("less_camp_coin",{"name":"补给币",
										"description":"购买番外卡片一转所需货币\n通关探险营地关卡获取",
										"icon":13,
										"pos_x":0,
										"pos_y":4})
	register_material("camp_coin",{"name":"营地金币",
										"description":"购买番外卡片二转所需货币\n完成探险营地支线任务获取",
										"icon":14,
										"pos_x":1,
										"pos_y":4})
	// ── 金马盛典兑换货币（icon 23 = 幸运星）──
	register_material("zz_star",{"name":"幸运星",
										"description":"在金马盛典兑换商店换取13~16星养成材料\n参与金马盛典转转抽奖获取",
										"icon":23,
										"pos_x":5,
										"pos_y":2})
	// ── 融合剂（2026-11-20）：合成屋三档融合的必需材料，官方每档 5 个/次 ──
	//   icon 45~47 = spr_craft_material 末尾那三个药瓶（原图集里没人用的帧）
	//   格子接在幸运星右边：row 2 的 x=6/7/8（背包里正好留了三个空位）
	register_material("fusion_basic",{"name":"初级融合剂",
										"description":"进行初级融合的材料",
										"icon":45,
										"pos_x":6,
										"pos_y":2})
	register_material("fusion_deep",{"name":"深度融合剂",
										"description":"进行深度融合的材料",
										"icon":46,
										"pos_x":7,
										"pos_y":2})
	register_material("fusion_soul",{"name":"灵魂融合剂",
										"description":"进行灵魂融合的材料",
										"icon":47,
										"pos_x":8,
										"pos_y":2})
}

// ══════════════════════════════════════════════════════════════════════
// 道具「最低获取方式」（背包道具页悬停提示用）
//   只登记有明确产出的养成材料；顺序按关卡推进顺序排，不要随手重排
//   —— 玩家看到的第一项就是最早能刷到的关卡。
//   未登记的道具返回空数组，提示框不追加这一段。
// ══════════════════════════════════════════════════════════════════════

/// @function material_min_source_list(_material_id)
/// @desc 该道具最早可获取的关卡名数组（空数组 = 未登记）
function material_min_source_list(_material_id) {
	switch (_material_id) {
		case "natural_spices":    return ["请关注游戏活动"];
		case "superior_spices":   return ["请关注游戏活动"];
		case "supreme_spices":    return ["请关注游戏活动"];
		case "secret_spices":     return ["请关注游戏活动"];
		case "royal_spices":      return ["请关注游戏活动"];
		// 每级草最早能刷到的关（2026-11-21 掉落重排后核对）
		case "clover_1":          return ["神殿"];
		case "clover_2":          return ["深渊岛", "金枪鱼洋流"];
		case "clover_3":          return ["芝士城堡", "玛奇朵港"];
		case "clover_4":          return ["雪顶火山", "茴香竹筏（日）"];
		case "zz_star":           return ["金马盛典"];
		case "magic_spices":      return ["请关注游戏活动"];
		case "elf_spices":        return ["请关注游戏活动"];
		case "angel_spices":      return ["请关注游戏活动"];
		case "saint_spices":      return ["请关注游戏活动"];
		// 2026-11-21 掉落重排：每档取「最早能刷到的关」
		case "warcard_1":         return ["曲奇岛", "松露大厅（日）"];
		case "warcard_2":         return ["色拉岛（陆）"];
		case "warcard_3":         return ["慕斯岛", "香槟岛（陆）"];
		case "warcard_4":         return ["神殿", "布丁岛（日）"];
		case "warcard_5":         return ["可可岛（日）", "咖喱岛（日）"];
		case "warcard_6":         return ["深渊岛", "金枪鱼洋流", "戚风营地（日）", "芥末小屋（日）"];
		case "warcard_7":         return ["薄荷海滩（日）", "芝士城堡", "戚风营地（夜）"];
		case "warcard_8":         return ["炭烧雨林（夜）", "抹茶庄园（日）"];
		case "warcard_9":         return ["玛奇朵港", "棉花糖天空（日）"];
		case "warcard_10":        return ["雪顶火山", "茴香竹筏（日）", "果仁瀑布", "北极贝湍流"];
		case "warcard_11":        return ["十三香中心岛", "跨服商店"];
		// 12~15★ 是跨服专属，不进掉落、也不进假期特惠
		case "warcard_12":        return ["跨服商店"];
		case "warcard_13":        return ["跨服商店"];
		case "warcard_14":        return ["跨服商店"];
		case "warcard_15":        return ["跨服商店"];
		case "fusion_basic":      return ["假期特惠"];
		case "fusion_deep":       return ["假期特惠"];
		case "fusion_soul":       return ["假期特惠"];
		case "clover_5":          return ["十三香中心岛", "金马盛典"];
		case "clover_6":          return ["金马盛典"];
		case "clover_s":          return ["金马盛典"];
		case "clover_ss":         return ["金马盛典"];
		case "clover_sss":        return ["金马盛典"];
		case "clover_ssr":        return ["金马盛典"];
		case "clover_snake":      return ["金马盛典"];
		case "clover_horse":      return ["金马盛典"];
		case "less_crystal":      return ["神殿"];
		case "middle_crystal":    return ["勇士神殿", "芥末小屋", "戚风营地", "金枪鱼洋流", "松露大厅"];
		case "advanced_crystal":  return ["诸神宝殿"];
	}
	return [];
}

/// @function material_min_source_text(_material_id[, _max_chars])
/// @desc 拼成提示框用的多行文本（未登记返回 ""）；每行最多 _max_chars 个字，
///       默认 18，超出就换行——tooltip 不做自动折行，太长会横向拉爆
///       注意：GML 少传实参会报 GM1020（多传不报），所以第二个参数必须靠
///       argument[1] 读取，不能写在形参列表里，否则单参调用编译不过
function material_min_source_text(_material_id) {
	var _list = material_min_source_list(_material_id);
	var _n = array_length(_list);
	if (_n <= 0) return "";
	var _max = (argument_count >= 2) ? argument[1] : 18;

	var _lines = [];
	var _cur = "";
	for (var i = 0; i < _n; i++) {
		var _item = _list[i];
		if (_cur == "") {
			_cur = _item;
			continue;
		}
		var _cand = _cur + " / " + _item;
		if (string_length(_cand) > _max) {
			array_push(_lines, _cur);
			_cur = _item;
		} else {
			_cur = _cand;
		}
	}
	if (_cur != "") array_push(_lines, _cur);

	var _txt = "最低获取方式：";
	for (var j = 0; j < array_length(_lines); j++) {
		_txt += "\n" + _lines[j];
	}
	return _txt;
}

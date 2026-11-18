// ── 只在「卡片宝石」页（craft_top_tab == 0）生效 ──
// 本按钮和转职页的「转职」按钮是**同一个坐标**（x-305, y+220，obj_craft_bg/Create_0 里两边都这么写），
// 切到别的页只是 visible = false 藏起来。不在这里拦一道的话，点转职 / 进化 / 融合页同一位置的
// 按钮会连带跑一次强化（强化槽里有卡时白扣材料 + 金币）。
if (!instance_exists(obj_craft_bg) || obj_craft_bg.craft_top_tab != 0){
	exit
}
// 说明 / 一键弹窗开着：这个按钮被藏起来了，但 Mouse 事件照样会派发 → 必须在这里拦
if (obj_craft_bg.craft_help_open || obj_craft_bg.craft_onekey_open){
	exit
}

// 2026-11-20：点强化 = 卡星级可能变，让右侧列表的 surface 重绘一次
if (variable_instance_exists(obj_craft_bg.id, "craft_sort_dirty")) obj_craft_bg.craft_sort_dirty = true;   // 升星后列表要重排（可能满级移出）

global.audio.play(snd_button,0,0)

var target_id = obj_craft_bg.current_uprade_target_id
if target_id != ""{
	if obj_craft_bg.button_select == 0{
		// ══ 卡片强化 v7（2026-11-19）：手动放料 + 原版矩阵 + 额外率 + 保险金 + 连败保底 ══
		//   顺序不能乱：算料 → 算钱 → 算率 → 连击 → 判定 → 扣（投保失败不扣料/草）→ 结算
		var _bg  = obj_craft_bg
		var card_data = get_card_info_simple(target_id)
		var _s = card_data.max_level
		var _T = _s + 1
		if array_get_index(cannot_upgrade_card_list,target_id) != -1{
			show_notice("该卡片无法被强化",60)
		}
		else if _s < 16{
			var craft_rule_info = get_card_craft_rule(string(_T))
			if (is_undefined(craft_rule_info)) { show_notice("无法强化", 60); exit; }

			// ① 至少 1 张强化用卡（草可选）
			var _slots = _bg.spice_slot
			var _filled = 0
			for (var i = 0; i < 3; i++) if (_slots[i] != "") _filled++
			if (_filled <= 0){
				show_notice("请先放入强化用卡",90)
				exit
			}

			// ② 每槽消耗只看目标星（同档多槽按份数累加）
			var _cost = craft_cost_info(_T).slot_cost
			var _need_of = {}
			for (var i = 0; i < 3; i++){
				var _mid = _slots[i]
				if (_mid == "") continue
				if (!variable_struct_exists(_need_of, _mid)) variable_struct_set(_need_of, _mid, 0)
				variable_struct_set(_need_of, _mid, variable_struct_get(_need_of, _mid) + (craft_is_warcard(_mid) ? 1 : _cost))
			}
			var _keys = variable_struct_get_names(_need_of)
			for (var i = 0; i < array_length(_keys); i++){
				var _k = _keys[i]
				if (get_material_amount(_k) < variable_struct_get(_need_of, _k)){
					show_notice(get_material_info(_k).name + "可使用数量不足",80)
					exit
				}
			}
			// ③ 四叶草：放了就必须有 1 个
			if (_bg.clover_slot != "" && get_material_amount(_bg.clover_slot) < 1){
				show_notice("该级别四叶草可使用数量不足",80)
				exit
			}

			// ④ 金币：强化金币 + 保险金（能保才收）
			var _assure = craft_rate_settings().assure_enabled && craft_assure_available(_T)
			var _assure_cost = _assure ? craft_assure_cost(_T) : 0
			var _gold_need = craft_rule_info.gold_amount + _assure_cost
			if global.save_data.player.gold < _gold_need{
				show_notice("金币不足：需要 " + string(_gold_need),80)
				exit
			}

			// ⑤ 概率：公式值 ×草 → 显示基础 + 额外率（补偿也在额外率里）
			var _base  = craft_total_rate(_slots, _T, _bg.clover_slot, 0)
			var _extra = get_craft_fail_bonus()
			var _judge = craft_judge_rate(_base, _extra)

			// ⑥ 判定：**没有连败保底**（用户口径），只按概率掷
			var _is_success = craft_roll(_judge)

			// ⑦ 扣料 / 扣草：**投保失败不扣**（原样留在槽里），其余情况都扣
			if (_is_success || !_assure){
				for (var i = 0; i < array_length(_keys); i++){
					var _k = _keys[i]
					add_material_amount(_k, -variable_struct_get(_need_of, _k))
				}
				if (_bg.clover_slot != "") add_material_amount(_bg.clover_slot, -1)
			}
			// ⑧ 金币和保费无论成败都扣
			global.save_data.player.gold -= _gold_need

			// ⑨ 结算（存档统一在最后写一次，别在中间反复 save）
			if (_is_success){
				upgrade_card(target_id, _T, false)
				reset_craft_fail_bonus()
				global.craft_lose_streak = 0   // 仅统计，2026-11-20 起不再用于保底
				show_notice("强化成功，卡片升至 " + string(_T) + " 星",60)
			}
			else{
				global.craft_lose_streak += 1   // 仅统计
				add_craft_fail_bonus(false)
				// 2026-11-20：失败提示统一成一句 —— 星级/材料/保险金的结果玩家自己看得见，
				//   提示别把机制全摊开
				if (!_assure && craft_can_drop(_s)) upgrade_card(target_id, _s - 1, false)
				show_notice("不够好运，强化失败",80)
			}
			save_file(global.save_slot)
		}
	
	}
	else if obj_craft_bg.button_select == 1{
		var crystal_list = [0,0,0]
		var gem_data = get_gem_info(target_id)
		var current_level = get_gem_max_level(target_id)
		if array_get_index(level_10_gems,target_id) != -1 && current_level >= 10{
			show_notice("已是最高星级",60)
		}
		else if current_level <= 14{
			var craft_rule_info = get_gem_craft_rule(string(current_level+1))
			var display_crystal_amount = 0
			var use_enhanced_crystal = false
			if get_material_amount(craft_rule_info.crystal_require) < craft_rule_info.crystal_amount{
				for(var i = array_get_index(crystal_use_order,craft_rule_info.crystal_require);i < array_length(crystal_use_order);i++){
					display_crystal_amount += get_material_amount(crystal_use_order[i])
					crystal_list[i] = get_material_amount(crystal_use_order[i])
					if display_crystal_amount>= craft_rule_info.crystal_amount{
						crystal_list[i] -= (display_crystal_amount - craft_rule_info.crystal_amount)
						use_enhanced_crystal = true
						break
					}
				}
			}
			else{
				display_crystal_amount = get_material_amount(craft_rule_info.crystal_require)
				var cr_index = array_get_index(crystal_use_order,craft_rule_info.crystal_require)
				crystal_list[cr_index] =  craft_rule_info.crystal_amount
			}
			if display_crystal_amount >= craft_rule_info.crystal_amount &&
			global.save_data.player.gold >= craft_rule_info.gold_amount
			{
				var fail_streak = get_gem_fail_streak(target_id)
				var rate_bonus = get_gem_craft_bonus(target_id)
				var success_rate = get_gem_craft_rate(target_id, current_level+1, rate_bonus, fail_streak)
				var is_success = craft_roll(success_rate)
				var rate_settings = craft_rate_settings()
				var material_ratio = 1
				var gold_ratio = 1
				if !is_success{
					material_ratio = rate_settings.fail_material_ratio
					gold_ratio = rate_settings.fail_gold_ratio
				}
				for(var i = 0 ; i < array_length(crystal_use_order) ; i++){
					if crystal_list[i] > 0 add_material_amount(crystal_use_order[i],-ceil(crystal_list[i]*material_ratio))
				}
				global.save_data.player.gold -= ceil(craft_rule_info.gold_amount*gold_ratio)
				if is_success{
					edit_gem_max_level(target_id,current_level+1)
					edit_gem_level(target_id,get_gem_max_level(target_id))
					set_gem_fail_streak(target_id,0)
					set_gem_craft_bonus(target_id,0)
					show_notice("强化成功，宝石升至 " + string(current_level+1) + " 星",60)
				}
				else{
					set_gem_fail_streak(target_id,fail_streak+1)
					if fail_streak < rate_settings.pity_bonus_max_stack{
						set_gem_craft_bonus(target_id,rate_bonus+random_range(rate_settings.pity_bonus_min, rate_settings.pity_bonus_max))
					}
					show_notice("不够好运，强化失败",80)
				}
			}
			else{
				show_notice("材料不足",60)
			}
		}
	
	}
}
//show_notice("不够好运，升级失败！",60)

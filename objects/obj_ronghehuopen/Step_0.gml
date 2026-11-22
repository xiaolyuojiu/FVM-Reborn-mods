// obj_ronghehuopen（融合火盆）Step 事件
// 三段机制：① 过火增幅（全形态）② 啃咬反伤（全形态，咬多少弹多少）③ 寒气（1 转起，8 秒 × 每秒 1 跳）
if global.is_paused{
	exit
}
event_inherited();
if is_frozen{
	exit
}

// ---------- 〇 过火倍率：星级 / 形态变了就重取（建实例之后才写入的情况：升星、转职）----------
// 倍率存注册表 custom["过火倍率"]（本卡 atk = 0），子弹侧读 fire_mult_override。
if (current_level != _rh_lv || shape != _rh_sh){
	_rh_lv = current_level;
	_rh_sh = shape;
	var _ri = get_plant_data_with_skill("ronghehuopen", shape, clamp(current_level, 0, 16), 0);
	fire_mult_override = (_ri != undefined && ds_map_exists(_ri, "过火倍率")) ? _ri[? "过火倍率"] : 1;
	fire_mult_override *= hex_batch2_id_atk("ronghehuopen");
	// 寒气：威力 / 间隔 同走 custom（创建后星级被改写时一并刷新）
	cold_damage = (_ri != undefined && ds_map_exists(_ri, "寒气伤害")) ? _ri[? "寒气伤害"] : 48;
	cold_interval = (_ri != undefined && ds_map_exists(_ri, "寒气间隔")) ? round(_ri[? "寒气间隔"] * 60) : 45 * 60;
}

// ---------- ① 过火增幅：已改到「子弹侧碰撞」（与 obj_brazier / 火神 / 金牛同款）----------
// 过火统一走父类事件 Collision_obj_fire_source → scripts/mod_bullet_hazard 的 bullet_hazard_fire；
// 卡片这里不再每帧 with(obj_bullet_parent) 扫描 —— 那是「多张火盆 + 一堆子弹」时卡顿的根源。
// 判定口径（普通 / 冰弹两跳 / 2 转冰化）与门禁（can_burn / kind / disabled）全部在脚本里。

// ---------- ② 啃咬反伤：掉多少血，弹给正在啃咬本卡的老鼠多少伤害 ----------
if (hp < current_hp_track){
	var _bleed = current_hp_track - hp;
	with (obj_enemy_parent){
		if (hp > 0 && state == ENEMY_STATE.ATTACK && target_plant == other.id){
			damage_amount = _bleed;
			damage_type = "normal";
			event_user(0);
		}
	}
}
current_hp_track = hp;

// ---------- ③ 寒气（深度融合起）：每[寒气间隔]释放一次，持续 8 秒、每秒 1 跳、减速 4 秒 ----------
// 场上 25 片寒气（obj_ronghehuopen_cold）与结算同步：8 秒后整体淡出。
if (shape >= 1){
	cold_timer++;
	if (cold_timer >= cold_interval){
		cold_timer = 0;
		// 铺 5*5 寒气场：每格一片，生命周期 = 跳数 × 每跳秒数 = 8 秒
		var _life = cold_dmg_tick * cold_tick_sec * 60;
		for (var _dr = -2; _dr <= 2; _dr++){
			for (var _dc = -2; _dc <= 2; _dc++){
				var _gc = grid_col + _dc;
				var _gr = grid_row + _dr;
				if (_gc < 0 || _gc >= global.grid_cols || _gr < 0 || _gr >= global.grid_rows) continue;
				var _pos = get_world_position_from_grid(_gc, _gr);
				var _cf = instance_create_depth(_pos.x, _pos.y, depth - 10, obj_ronghehuopen_cold);
				_cf.life = _life;
			}
		}
		cold_field_ticks = cold_dmg_tick;   // 共 8 跳
		cold_field_timer = 0;               // 生成当帧先打第 1 跳
	}

	// 每秒结算 1 跳（跳数用完自动停，不用额外清场）
	if (cold_field_ticks > 0){
		if (cold_field_timer > 0) cold_field_timer--;
		if (cold_field_timer <= 0){
			cold_field_timer = cold_tick_sec * 60;
			cold_field_ticks--;
			with (obj_enemy_parent){
				// 5*5 范围，只打陆地（空中 / 潜水 / 非主流 / 地下 / 幽灵都不打）
				if (hp > 0
					&& grid_row >= other.grid_row - 2 && grid_row <= other.grid_row + 2
					&& grid_col >= other.grid_col - 2 && grid_col <= other.grid_col + 2
					&& target_type == "normal"){
					damage_amount = other.cold_damage;                    // 每跳 = 寒气伤害（总伤害 = ×8）
					damage_type = "normal";
					event_user(0);
					ice_timer = max(ice_timer, other.cold_slow_frames);   // 减速 4 秒
				}
			}
		}
	}
}

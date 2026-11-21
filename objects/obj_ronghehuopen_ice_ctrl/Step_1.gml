// obj_ronghehuopen_ice_ctrl Begin Step 事件
// 只管冰弹（brazier_list 哨兵 -9999）的三件事，换贴图不归这里（见 obj_bullet_parent 的 Begin Draw）：
// ① 记录本帧冰弹坐标（End Step 配对命中特效；命中当帧子弹常已被池回收，End Step 就取不到了）
// ② 冰弹**打中**的老鼠 → 减速：同一行（子弹有 row 时）+ bbox 相交 + 无护盾
// ③ 记录「本帧被冰弹压住」的敌人快照（End Step 判「直接打死」→ 播碎冰死亡）
// ④ 场上没有冰弹后计时自毁
if (global.is_paused){
	exit
}

// 冰弹标记：子弹自己的 brazier_list 里插了哨兵值 -9999（该列表每颗子弹每条命由 Create 重建，池化复用天然复位）
rec_x = [];
rec_y = [];
rec_enemy = [];
var _ice = [];
with (obj_bullet_parent){
	if (variable_instance_exists(id, "brazier_list") && ds_list_find_index(brazier_list, -9999) != -1){
		array_push(_ice, id);
		array_push(other.rec_x, x);
		array_push(other.rec_y, y);
	}
}

// 场上没有冰弹 → 直接早退，一帧也不扫敌人（旧写法是「每颗冰弹 × 每只敌人」双 bbox 全扫，卡顿主因）
if (array_length(_ice) > 0){
	idle_frames = 0;
	var _probe = kill_probe;
	var _near = ds_list_create();
	for (var _i = 0; _i < array_length(_ice); _i++){
		var _b = _ice[_i];
		if (!instance_exists(_b)) continue;

		// 减速只给「真被打中」的那只：子弹带 row 时要求同一行（追踪 / 斜向弹没有 row，只靠相交）
		var _brow = variable_instance_exists(_b, "row") ? _b.row : -9999;

		// 一次空间查询覆盖两件事：减速要「相交」，击杀快照要给「这一帧才位移进来」留 kill_probe 余量
		ds_list_clear(_near);
		collision_rectangle_list(_b.bbox_left - _probe, _b.bbox_top - _probe,
		                         _b.bbox_right + _probe, _b.bbox_bottom + _probe,
		                         obj_enemy_parent, false, true, _near, false);
		for (var _k = 0; _k < ds_list_size(_near); _k++){
			var _eid = ds_list_find_value(_near, _k);
			if (!instance_exists(_eid)) continue;

			// ② 减速：同一行（子弹有 row 时）+ bbox 真相交 + 无护盾
			with (_eid){
				if (hp > 0
					&& (_brow == -9999 || grid_row == _brow)
					&& (!variable_instance_exists(id, "shield_hp") || shield_hp <= 0)
					&& bbox_left  < _b.bbox_right
					&& bbox_right > _b.bbox_left
					&& bbox_top   < _b.bbox_bottom
					&& bbox_bottom > _b.bbox_top){
					// 命中音由子弹自身的通用命中音负责（冰弹专属命中音待新素材接入）
					ice_timer = max(ice_timer, 600);   // 冰冻小笼包同款：减速 10 秒
				}
			}

			// ③ 击杀快照（End Step 用来判「这一帧被冰弹直接打死」→ 碎冰特效）
			with (_eid){
				if (hp > 0){
					// 能不能播碎冰：与「灰烬击杀」同口径（防爆鼠等免疫灰烬的不给碎冰，BOSS 跳过）
					var _can_shatter = true;
					if (variable_instance_exists(id, "immune_to_ash") && immune_to_ash) _can_shatter = false;
					if (variable_instance_exists(id, "is_boss") && is_boss) _can_shatter = false;
					array_push(other.rec_enemy, [id, x, y, depth, hp, object_index, image_xscale, image_yscale, _can_shatter]);
				}
			}
		}
	}
	ds_list_destroy(_near);
}

// 场上没有冰弹就计时自毁。
//   融盆火弹（-9998）不再需要本控制器 —— 贴图由 obj_bullet_parent 的 Begin Draw 出，
//   所以空闲判定只看冰弹，火弹飞着也不会拖住控制器。
if (array_length(_ice) == 0){
	idle_frames++;
	if (idle_frames > 300) instance_destroy();
}
else{
	idle_frames = 0;
}

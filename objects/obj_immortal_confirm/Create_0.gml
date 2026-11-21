/// obj_immortal_confirm（不朽难度 · 开始确认窗）Create 事件
/// 触发：难度箭头切到不朽、或换存档后当前难度是不朽且该存档还没锁定。
/// 弹窗只负责「问」；点确定才落盘（见 difficulty_lock_immortal()）。
ic_hover      = -1;      // 悬停按钮（0 = 确定 / 1 = 取消）
ic_guard      = 2;       // 先吃掉两帧点击，避免「点箭头那一下」连带点中窗里的按钮
ic_done       = false;   // 已处理过（按钮或异常关闭）
ic_can_reward = difficulty_start_reward_available(5);   // 这一档还能不能领开局奖励

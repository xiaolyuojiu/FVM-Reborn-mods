// Game End：这里已经要退出了，存档校验失败也不要弹模态框（否则关不掉游戏）
save_file(global.save_slot, false)

global.laboratory_manager.dispose()

if (native_stop_mouse_limit != undefined) {
    native_stop_mouse_limit();
}

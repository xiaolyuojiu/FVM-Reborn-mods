/// 离线授权码客户端（无服务器 · 码池 + 机器指纹绑定）
///
/// 码格式：FVM4-<码ID>-<机器码>-<签名>
///   码ID   = 你预先准备在 tools/codes_pool.txt 里的固定码，机器人发放时挑一个
///   机器码 = 本机指纹的 md5 前 8 位（auth_hwid()，界面上叫「本机识别码」）
///          指纹 v2 = 原生硬件 UUID（SMBIOS 主板级）；拿不到原生时退化为
///          环境量 + 每份安装随机 ID。v1（只用环境量）仅兼容老玩家本地记录。
///   签名   = md5("FVM4|码ID|机器码|secret") 前 10 位大写十六进制
///
/// 关键：签名把**机器码**一起签了。所以别人拿到你的码也用不了——
/// 他那台机器算出的 auth_hwid() 不同，验签直接失败，不需要联网核对。
/// 这是纯离线条件下唯一能实现「一码一机」的因子（QQ 号在游戏端拿不到）。
///
/// 游戏只验签名，**不需要打包任何码表**。加码、改码只改机器人那边的池子，
/// 游戏不用重新发版。
///
/// ⚠️ 下面三段 SECRET 必须与 tools/qq_auth.py 的 SECRET 拼接结果一致，
///    用 `python tools/qq_auth.py gml` 生成，不要手抄。
///
/// 详见 docs/QQ号校验与授权方案.md 第 12 章。

#macro kAuthPrefix "FVM4"

// 机器人领码命令。必须与 bots/qq_auth_bot/config.json 的 auth_command 一致，
// 否则面板上的提示会让玩家发错命令。改这里就够了，别在绘制里写死。
#macro kAuthCommand "/授权"

// 机器码长度与字符集（十六进制，含 0 和 1，别用 kAuthIdChars 校验它）
#macro kAuthHwidLen 8
#macro kAuthHwidChars "0123456789ABCDEF"

// secret 拆三段：单条字符串会被 strings / 十六进制扫描直接命中
#macro kAuthSecretA "9HNnJFL8BkBrZ"
#macro kAuthSecretB "1lIB8K4kfhj47"
#macro kAuthSecretC "XnpKQZjpHlM2Jj"

// 本地绑定记录的自校验密钥
#macro kAuthSealKey "CA7401FCC101C67D114CAFD5"

// 码ID 允许的字符，必须与 tools/qq_auth.py 的 ID_CHARS 一致
#macro kAuthIdChars "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
#macro kAuthIdMin 4
#macro kAuthIdMax 20

// 整串码允许的字符（清洗用）。
// ⚠️ 必须包含 0 和 1：签名是十六进制，含 0/1 是常态。
//    这里要是误用 kAuthIdChars，凡是签名为 0/1 起的码都会被洗坏、永远验不过。
#macro kAuthCleanChars "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

function auth_secret() {
    return kAuthSecretA + kAuthSecretB + kAuthSecretC;
}

// ── 本机识别码（指纹 v2）──────────────────────────────────────
// v1（≤ 3.0.2.15）只用 COMPUTERNAME | PROCESSOR_IDENTIFIER | NUMBER_OF_PROCESSORS。
// 这三个量在 ghost 克隆镜像 / 同批装机 / 无盘网吧里完全一样，算出来的识别码会
// 全服撞成同一个（现网出现过所有机器都是 E52D26F9，连带整串授权码都一致）。
//
// v2 的取值顺序：
//   ① 原生硬件 UUID（SMBIOS 主板级，MachineUuid）→ "V2|<UUID>"
//   ② 拿不到原生（旧 DLL）→ "V2E|<环境量>|<每份安装随机 ID>"
// 只有 ② 才需要 install.id：随机值能把克隆镜像的两台机器拉开。
// ① 不带 install.id —— 重装系统 / 删本地文件都不换码，玩家体验更好。
//
// 旧码兼容：auth_hwid_legacy() 保留 v1 算法，只在 auth_load() 里对「本地已存的
// 那条记录」放行；新粘贴的码一律按 v2 校验（auth_bind 不走 legacy 分支），
// 避免旧指纹的漏洞继续被用来换码。

/// 读 install.id（16 位大写十六进制）。不存在/内容不合法返回 ""
function auth_install_read(_path) {
    if (!file_exists(_path)) {
        return "";
    }
    var _f = file_text_open_read(_path);
    if (_f == -1) {
        return "";
    }
    var _text = "";
    if (!file_text_eof(_f)) {
        _text = file_text_read_string(_f);
    }
    file_text_close(_f);

    var _s = string_upper(string(_text));
    if (string_length(_s) != 16) {
        return "";
    }
    for (var i = 1; i <= 16; i++) {
        if (string_pos(string_char_at(_s, i), kAuthHwidChars) == 0) {
            return "";
        }
    }
    return _s;
}

function auth_install_write(_path, _id) {
    var _dir = global.native_util.get_path_in_local_appdata("\\FVM_Reborn_makk");
    if (!directory_exists(_dir)) {
        directory_create(_dir);
    }
    var _f = file_text_open_write(_path);
    if (_f == -1) {
        return false;
    }
    file_text_write_string(_f, _id);
    file_text_close(_f);
    return true;
}

/// 每份安装的随机标识：首次运行生成后落盘，之后固定。
/// 作用只有一个 —— 原生硬件 UUID 拿不到时，别让克隆镜像的两台机器算出同一个码。
/// @returns {String} 16 位大写十六进制
function auth_install_id() {
    if (variable_global_exists("auth_install_id_cache")) {
        return global.auth_install_id_cache;
    }
    var _path = global.native_util.get_path_in_local_appdata("\\FVM_Reborn_makk\\install.id");
    var _id = auth_install_read(_path);
    if (_id == "") {
        var _seed = string(irandom(2147483647)) + "|" + string(current_time) + "|" +
                    string(current_datetime()) + "|" + string(irandom(2147483647));
        _id = string_upper(string_copy(md5_string_utf8(_seed), 1, 16));
        auth_install_write(_path, _id);
    }
    global.auth_install_id_cache = _id;
    return _id;
}

/// 原生硬件标识（SMBIOS System UUID，取不到时退化为网卡 MAC）。
/// 需要 FvmNativeSupport.dll 里的 MachineUuid 导出；旧 DLL 没有这个符号时
/// external_define 返回负数，这里返回 ""，调用方自动退化，绝不阻断启动。
/// @returns {String} 拿不到返回 ""
function auth_native_uuid() {
    if (variable_global_exists("auth_native_uuid_cache")) {
        return global.auth_native_uuid_cache;
    }

    var _value = "";
    try {
        if (!variable_global_exists("auth_native_uuid_fn")) {
            var _library = "FvmNativeSupport.dll";
            if (os_type == os_macosx) {
                _library = "libFvmNativeSupport.dylib";
            }
            var _native = global.native_util.join_path(working_directory, "native/" + _library);
            var _root = global.native_util.join_path(working_directory, _library);
            if (file_exists(_native)) {
                _library = _native;
            } else if (file_exists(_root)) {
                _library = _root;
            }
            global.auth_native_uuid_fn = external_define(_library, "MachineUuid", dll_cdecl, ty_string, 0);
        }
        if (global.auth_native_uuid_fn >= 0) {
            _value = string_upper(string(external_call(global.auth_native_uuid_fn)));
        }
    } catch (_e) {
        _value = "";
        global.auth_native_uuid_fn = -1;
    }

    // 少于 8 个字符当作没拿到（空串 / 报错文本）
    if (string_length(_value) < 8) {
        _value = "";
    }
    global.auth_native_uuid_cache = _value;
    return _value;
}

/// 本机识别码的原始输入。改这个函数等于换指纹代际，必须同时保留 v1 的
/// auth_hwid_legacy()，否则所有已授权的玩家升级后全部掉授权。
/// @returns {String}
function auth_hwid_raw() {
    var _uuid = auth_native_uuid();
    if (_uuid != "") {
        return "V2|" + _uuid;
    }
    return "V2E|" +
        string_upper(environment_get_variable("COMPUTERNAME")) + "|" +
        string_upper(environment_get_variable("USERPROFILE")) + "|" +
        string_upper(environment_get_variable("PROCESSOR_IDENTIFIER")) + "|" +
        string(environment_get_variable("NUMBER_OF_PROCESSORS")) + "|" +
        auth_install_id();
}

/// 本机识别码：8 位大写十六进制（长度由 kAuthHwidLen 决定，协议要求是 8）。
/// 换电脑 → 变；同镜像的另一台机器 → 也变（这就是 v2 要解决的问题）。
/// @returns {String}
function auth_hwid() {
    return string_upper(string_copy(md5_string_utf8(auth_hwid_raw()), 1, kAuthHwidLen));
}

/// v1 指纹（≤ 3.0.2.15）。只为让老玩家的本地授权记录继续生效，
/// 新码一律不认它 —— 旧指纹在克隆镜像里是同一个值，谁都能用。
/// @returns {String}
function auth_hwid_legacy() {
    var _name = string_upper(environment_get_variable("COMPUTERNAME"));
    var _cpu = string_upper(environment_get_variable("PROCESSOR_IDENTIFIER"));
    var _n = string(environment_get_variable("NUMBER_OF_PROCESSORS"));
    if (_name == "") {
        _name = "UNKNOWN";
    }
    return string_upper(string_copy(md5_string_utf8(_name + "|" + _cpu + "|" + _n), 1, kAuthHwidLen));
}

/// 指纹排查日志：%LOCALAPPDATA%\FVM_Reborn_makk\auth.log
/// 出现「所有人识别码一样」时，先看这里的两行，比反推 md5 快得多。
function auth_log(_text) {
    var _dir = global.native_util.get_path_in_local_appdata("\\FVM_Reborn_makk");
    if (!directory_exists(_dir)) {
        directory_create(_dir);
    }
    var _f = file_text_open_append(_dir + "\\auth.log");
    if (_f == -1) {
        return;
    }
    file_text_write_string(_f, "[" + string(current_datetime()) + "] " + string(_text));
    file_text_writeln(_f);
    file_text_close(_f);
}

/// 本机识别码的展示形式（4-4 分开，方便玩家对着抄）
/// 玩家要把它发到群里换授权码，界面上应该做成可点击复制
/// @returns {String}
function auth_hwid_text() {
    var _h = auth_hwid();
    return string_copy(_h, 1, 4) + "-" + string_copy(_h, 5, 4);
}

/// 机器码只允许 8 位十六进制
/// @param {String} _hwid
/// @returns {Bool}
function auth_hwid_valid(_hwid) {
    if (string_length(_hwid) != kAuthHwidLen) {
        return false;
    }
    for (var i = 1; i <= kAuthHwidLen; i++) {
        if (string_pos(string_char_at(_hwid, i), kAuthHwidChars) == 0) {
            return false;
        }
    }
    return true;
}

/// @param {String} _code_id 池子里的码ID
/// @param {String} _hwid 码里带的机器码（不是本机的）
/// @returns {String} 10 位大写签名
function auth_expected_sig(_code_id, _hwid) {
    var _raw = kAuthPrefix + "|" + string(_code_id) + "|" + string(_hwid) + "|" + auth_secret();
    return string_upper(string_copy(md5_string_utf8(_raw), 1, 10));
}

/// 码ID 只允许固定字符集，避免玩家把 0/O、1/I 搞混后无法定位问题
/// @param {String} _code_id
/// @returns {Bool}
function auth_id_valid(_code_id) {
    var _len = string_length(_code_id);
    if (_len < kAuthIdMin) {
        return false;
    }
    if (_len > kAuthIdMax) {
        return false;
    }
    for (var i = 1; i <= _len; i++) {
        if (string_pos(string_char_at(_code_id, i), kAuthIdChars) == 0) {
            return false;
        }
    }
    return true;
}

/// 清洗粘贴进来的码：转大写、只保留合法字符和连字符
/// 玩家从 QQ 里复制常带空格、换行、零宽字符，多一个字符就验不过，
/// 与其让人自己找，不如直接吃掉。
/// @param {String} _code
/// @returns {String}
function auth_clean(_code) {
    var _s = string_upper(string(_code));
    var _n = string_length(_s);
    var _out = "";
    for (var i = 1; i <= _n; i++) {
        var _c = string_char_at(_s, i);
        if (_c == "-") {
            _out += _c;
        } else if (string_pos(_c, kAuthCleanChars) > 0) {
            _out += _c;
        }
    }
    return _out;
}

/// 校验授权码，不读写任何文件
/// @param {String} _code
/// @returns {Struct} {ok: Bool, code_id: String, hwid: String, reason: String}
///   reason: "" 成功 / "format" 格式错 / "sig" 签名错 / "machine" 不是本机的码
function auth_verify_code(_code) {
    var _result = {
        ok: false,
        code_id: "",
        hwid: "",
        reason: "format"
    };

    var _clean = auth_clean(_code);
    var _parts = string_split(_clean, "-");
    if (array_length(_parts) != 4) {
        return _result;
    }
    if (_parts[0] != kAuthPrefix) {
        return _result;
    }
    if (!auth_id_valid(_parts[1])) {
        return _result;
    }
    if (!auth_hwid_valid(_parts[2])) {
        return _result;
    }
    // 签名先验：确保这个码确实是你签的（含机器码）
    if (_parts[3] != auth_expected_sig(_parts[1], _parts[2])) {
        _result.reason = "sig";
        return _result;
    }
    _result.code_id = _parts[1];
    _result.hwid = _parts[2];

    // 再验归属：码里绑的机器码必须就是本机
    // 这一步就是「别人拿到你的码也用不了」的落点
    if (_parts[2] != auth_hwid()) {
        _result.reason = "machine";
        return _result;
    }

    _result.ok = true;
    _result.reason = "";
    return _result;
}

function auth_file_path() {
    return global.native_util.get_path_in_local_appdata("\\FVM_Reborn_makk\\auth.dat");
}

/// 本地绑定记录的自校验，防止手改 auth.dat 塞一个别人的码
/// @param {String} _code_id
/// @param {String} _code
/// @returns {String}
function auth_seal(_code_id, _code) {
    return md5_string_utf8(string(_code_id) + "|" + string(_code) + "|" + kAuthSealKey);
}

/// 把绑定记录写到 %LOCALAPPDATA%\FVM_Reborn_makk\auth.dat
/// @param {String} _code_id
/// @param {String} _code
/// @returns {Bool} 是否写入成功
function auth_save(_code_id, _code) {
    // ⚠️ 用 json_stringify，**不要用 json_string**。
    //    这套运行时（FVM 分支）只有 json_parse / json_stringify 这一对，
    //    json_string 不存在：写成 json_string(...) 会当成读实例变量，运行期报
    //    「Variable obj_auth_gate.json_string not set before reading it」。
    //    工程里 save_file / obj_mod_menu 也都用 json_stringify。
    var _json = json_stringify({
        code_id: _code_id,
        code: _code,
        seal: auth_seal(_code_id, _code)
    });

    // 落盘走 file_text_*，和工程里 save_file / load_file 完全一致。
    // 不要再用 buffer_create + buffer_save：那两个函数在工程里没有其它先例，
    // 万一缺失要等到**下次启动读档**才炸，比写入时就炸难查得多。
    var _dir = global.native_util.get_path_in_local_appdata("\\FVM_Reborn_makk");
    if (!directory_exists(_dir)) {
        directory_create(_dir);
    }

    var _f = file_text_open_write(auth_file_path());
    if (_f == -1) {
        show_debug_message("[auth] 写入失败：" + auth_file_path());
        return false;
    }
    file_text_write_string(_f, _json);
    file_text_close(_f);
    return true;
}

/// 从磁盘恢复绑定状态
/// @returns {Bool}
function auth_load() {
    global.auth_code_id = "";
    global.auth_code = "";
    global.auth_machine_changed = false;
    global.auth_code_legacy = false;

    var _path = auth_file_path();
    if (!file_exists(_path)) {
        return false;
    }

    // 读取走 file_text_*，与 save_file / load_file 同一套（理由见 auth_save）
    var _f = file_text_open_read(_path);
    if (_f == -1) {
        return false;
    }
    var _text = "";
    while (!file_text_eof(_f)) {
        _text += file_text_read_string(_f);
        file_text_readln(_f);
    }
    file_text_close(_f);

    if (string_length(_text) <= 0) {
        return false;
    }

    // 文件损坏（写了一半 / 被清空）时 json_parse 会抛异常。
    // 不接住的话启动流程就崩在这儿，玩家连授权窗都看不到。
    var _data;
    try {
        _data = json_parse(_text);
    } catch (_e) {
        show_debug_message("[auth] auth.dat 解析失败，按未授权处理");
        return false;
    }

    if (!is_struct(_data)) {
        return false;
    }
    if (!variable_struct_exists(_data, "code_id")) {
        return false;
    }
    if (!variable_struct_exists(_data, "code")) {
        return false;
    }
    if (!variable_struct_exists(_data, "seal")) {
        return false;
    }
    // 手改过就作废，让玩家重新输码
    if (auth_seal(_data.code_id, _data.code) != _data.seal) {
        return false;
    }

    var _verified = auth_verify_code(_data.code);
    var _legacy_ok = false;
    if (!_verified.ok && _verified.reason == "machine") {
        // 指纹 v2 上线后，老玩家本地那条记录里绑的还是 v1 识别码。
        // 只对「本地已经存下来的这条记录」放行 —— 新粘贴的码一律按 v2 校验，
        // 因为旧指纹在克隆镜像里全同，谁都能用，不能再当凭证（见 auth_bind）。
        if (_verified.hwid == auth_hwid_legacy()) {
            _legacy_ok = true;
        }
    }
    if (!_verified.ok && !_legacy_ok) {
        // 码本身没问题，只是不是这台机器的 —— 换机/重装系统后就是这种情形。
        // 界面据此提示「识别码变了，需要重新领码」，别让玩家以为存档坏了。
        if (_verified.reason == "machine") {
            global.auth_machine_changed = true;
        }
        return false;
    }
    if (_legacy_ok) {
        global.auth_code_legacy = true;
        auth_log("legacy-v1 放行 code_id=" + _verified.code_id + " hwid=" + _verified.hwid);
    }

    global.auth_code_id = _verified.code_id;
    global.auth_code = string(_data.code);
    return true;
}

/// 绑定授权码并落盘
/// @param {String} _code
/// @returns {Real} 0 = 成功，1 = 码无效/签名错，2 = 这个码是给另一台机器的，
///                 3 = 本机已授权但写盘失败（下次启动可能要重输），
///                 4 = 这个码绑的是旧版识别码（v1），需要重新领码
function auth_bind(_code) {
    var _verified = auth_verify_code(_code);
    if (_verified.reason == "machine") {
        // 旧指纹（v1）的码：签名有效，但它绑的识别码在克隆镜像里是全服同一个值，
        // 谁拿到都能用，不能再当凭证 —— 让玩家用 v2 识别码重新领。
        if (_verified.hwid == auth_hwid_legacy()) {
            return 4;
        }
        return 2;
    }
    if (!_verified.ok) {
        return 1;
    }
    global.auth_code_id = _verified.code_id;
    global.auth_code = auth_clean(_code);

    // 写盘失败也要保留会话内的授权（否则玩家这一步就白输了），
    // 但必须让 UI 说出来 —— 假装成功的话，下次启动又弹窗，玩家会以为程序坏了。
    if (!auth_save(global.auth_code_id, global.auth_code)) {
        return 3;
    }
    return 0;
}

function auth_clear() {
    global.auth_code_id = "";
    global.auth_code = "";
    var _path = auth_file_path();
    if (file_exists(_path)) {
        file_delete(_path);
    }
}

/// @returns {Bool}
function auth_ok() {
    return (global.auth_code_id != "");
}

/// 给 UI 用的展示串，未授权返回空字符串
/// @returns {String}
function auth_label() {
    if (!auth_ok()) {
        return "";
    }
    var _tag = string_copy(global.auth_code_id, max(1, string_length(global.auth_code_id) - 3), 4);
    return "已授权 · 凭证 " + _tag;
}

/// 在 obj_game_init / room_menu 的 Create 里调一次
/// 必须在 global.native_util 初始化之后
function auth_init() {
    if (!variable_global_exists("auth_code_id")) {
        global.auth_code_id = "";
    }
    if (!variable_global_exists("auth_code")) {
        global.auth_code = "";
    }
    if (!variable_global_exists("auth_machine_changed")) {
        global.auth_machine_changed = false;
    }
    if (!variable_global_exists("auth_code_legacy")) {
        global.auth_code_legacy = false;
    }
    // 排查用：识别码与它的原始输入都落 auth.log。
    // 出「所有人识别码一样」时，看这一行就知道是原生 UUID 没拿到、还是环境量塌陷。
    auth_log("start hwid=" + auth_hwid() + " raw=" + auth_hwid_raw() + " v1=" + auth_hwid_legacy());
    auth_load();
}

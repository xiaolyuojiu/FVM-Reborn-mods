#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""FVM 授权码签发工具（离线 · 码池 + 机器指纹绑定）

码格式：FVM4-<码ID>-<识别码>-<到期日>-<签名>
    码ID   = tools/codes_pool.txt 里你预先准备的那批码，机器人发放时挑一个
    识别码 = 玩家机器指纹的 md5 前 8 位 + 2 位校验（共 10 位十六进制）
             游戏内点一下「复制本机识别码」得到，形如 3B0A66AB3E。
             那 2 位校验是 md5("HWID|<前8位>|<HWID_SALT>") 的前 2 位，
             只有拿到盐才算得出来 —— 所以随手敲的 8 位十六进制过不了验证，
             骗不到码、也占不掉设备名额（见 hwid_check / hwid_valid）。
    到期日 = 4 位 32 进制，值 = 「2020-01-01 起第几天」，字符集同码ID
             （去掉 0/O/1/I，玩家不会看错）。签发时按 LICENSE_DAYS 算，默认 3 天，
             想改期不用改代码：set LICENSE_DAYS=7
    签名   = md5("FVM4|码ID|识别码|到期日|SECRET") 前 10 位大写

关键设计一：码里绑了机器码，所以**别人拿到你的码也用不了**——
他的机器算出的指纹不同，验签直接失败。这是纯离线条件下唯一
能实现「一码一机、用后别人不能再用」的办法。

关键设计二：到期日也进了签名，所以改到期日必然破坏签名；
游戏端拿本机时钟比一下就知道过没过期。纯离线也能判有效期，
不需要联网。过期后机器人会自动按同一码ID重新签发（见 issue_for）。

常用命令：
    python tools/qq_auth.py poolgen 500          生成码池
    python tools/qq_auth.py pool                查看池子余量
    python tools/qq_auth.py issue <uid> <机器码>  发放
    python tools/qq_auth.py ledger              查看发放记录
    python tools/qq_auth.py revoke <机器码>      作废某台机器的码
    python tools/qq_auth.py revoke --uid <账号>  解绑该账号名下所有机器
    python tools/qq_auth.py verify <授权码>      验签
    python tools/qq_auth.py gml                 生成要贴进 GML 的宏
    python tools/qq_auth.py selftest
"""

import datetime
import hashlib
import os
import random
import sqlite3
import sys
import time

# ⚠️ 密钥来源优先级：
#    1. tools/auth_secret.txt（已在 .gitignore，推荐——公开仓库里不能有真值）
#    2. 下面的 SECRET_FALLBACK 占位符
# 改动密钥 = 所有已发出的码同时失效。用 `gml` 子命令生成 GML 宏，别手抄。
SECRET_FALLBACK = "CHANGE_ME_TO_A_LONG_RANDOM_STRING_2026"

FORMAT = "FVM4"
SIG_LEN = 10
ID_LEN = 8
# 去掉 0/O/1/I 这些玩家容易看错的字符
ID_CHARS = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
ID_MIN, ID_MAX = 4, 20

# ── 有效期 ────────────────────────────────────────────────────────
# 到期日写进码本身（第 4 段），所以纯离线也能判过期：
#   值 = 「EXP_EPOCH 起第几天」，4 位 32 进制，字符集同 ID_CHARS（不含 0/O/1/I）。
#   32^4 = 1048576 天 ≈ 2871 年，够用；4 位定长方便人眼核对。
# 改动默认天数不用改代码：set LICENSE_DAYS=7
EXP_LEN = 4
EXP_CHARS = ID_CHARS
# 与 GML 端 auth_day_number() 的基准必须一致，改这里要同步改 auth_client.gml
EXP_EPOCH = (2020, 1, 1)

try:
    LICENSE_DAYS = int(os.environ.get("LICENSE_DAYS", "") or 3)
except ValueError:
    LICENSE_DAYS = 3
if LICENSE_DAYS < 1:
    LICENSE_DAYS = 1

# 机器码 = 指纹 md5 前 8 位 + 2 位校验，共 10 位十六进制。
# 前 8 位是「正文」，后 2 位是 hwid_check() 算出的校验 —— 只有拿到 HWID_SALT
# 才算得出来，所以随手敲的 8 位十六进制过不了验证（挡的是「乱填骗码+占名额」）。
HWID_CORE_LEN = 8
HWID_CHECK_LEN = 2
HWID_LEN = HWID_CORE_LEN + HWID_CHECK_LEN
HWID_CHARS = "0123456789ABCDEF"

# 校验位的盐。**必须与 GML 端 kAuthHwidSalt 完全一致**，否则两端算出的识别码不同。
# 这个值会编译进游戏客户端，理论上能被逆出来；它的作用不是「绝对不可伪造」，
# 而是把门槛从「随手输 8 个十六进制字符」抬到「先逆向客户端拿到盐」——
# 前者是任何一个玩家都会碰到的，后者需要真正的逆向投入。
HWID_SALT = os.environ.get("HWID_SALT") or "FVM-HWID-CHECK-2026-11"

# 一个 QQ / openid 最多绑几台机器（防「一个号反复换识别码刷码」）
# 默认 2：够「台式 + 笔记本」两台日常使用，再多基本就是刷码了。
# 临时放宽不用改代码：set MAX_DEVICES=3（机器人端和 CLI 一起生效）
try:
    MAX_DEVICES_PER_UID = int(os.environ.get("MAX_DEVICES", "") or 2)
except ValueError:
    MAX_DEVICES_PER_UID = 2
if MAX_DEVICES_PER_UID < 1:
    MAX_DEVICES_PER_UID = 1

HERE = os.path.dirname(os.path.abspath(__file__))
POOL_PATH = os.path.join(HERE, "codes_pool.txt")
DB_PATH = os.path.join(HERE, "qq_auth.db")
SECRET_PATH = os.path.join(HERE, "auth_secret.txt")


def _load_secret():
    if os.path.exists(SECRET_PATH):
        with open(SECRET_PATH, "r", encoding="utf-8") as fh:
            value = fh.read().strip()
        if len(value) >= 16:
            return value
        print("⚠️  %s 太短（至少 16 位），改用占位符" % SECRET_PATH, file=sys.stderr)
    return SECRET_FALLBACK


SECRET = _load_secret()


# ---------------------------------------------------------------- 签名 / 组码

def hwid_check(core):
    """算识别码的 2 位校验：md5("HWID|前8位|盐") 前 2 位大写。

    与 GML 端 auth_hwid_check() 必须逐位一致，改这里就要改 auth_client.gml。
    """
    core = str(core or "").upper()[:HWID_CORE_LEN]
    raw = "HWID|%s|%s" % (core, HWID_SALT)
    return hashlib.md5(raw.encode("utf-8")).hexdigest().upper()[:HWID_CHECK_LEN]


def make_hwid(core):
    """8 位正文 → 10 位完整识别码。"""
    core = str(core or "").upper()[:HWID_CORE_LEN]
    if len(core) != HWID_CORE_LEN:
        raise ValueError("识别码正文必须是 %d 位十六进制" % HWID_CORE_LEN)
    if any(c not in HWID_CHARS for c in core):
        raise ValueError("识别码正文只能是 0-9A-F")
    return core + hwid_check(core)


def norm_hwid(hwid):
    """把玩家粘贴的识别码洗成 10 位大写十六进制。洗不出来返回空串。"""
    out = []
    for ch in str(hwid or "").upper():
        if ch in HWID_CHARS:
            out.append(ch)
    value = "".join(out)
    if len(value) < HWID_LEN:
        return ""
    return value[:HWID_LEN]


def hwid_valid(hwid):
    """10 位十六进制 **且** 后 2 位校验对得上。

    只查长度和字符集是不够的 —— 那样 8BDAF386 / DEADBEEF 这种随手敲的值
    都能过，机器人就会给它发一张真码，还占掉这个 QQ 的设备名额。
    """
    hwid = str(hwid or "").upper()
    if len(hwid) != HWID_LEN:
        return False
    if any(c not in HWID_CHARS for c in hwid):
        return False
    core = hwid[:HWID_CORE_LEN]
    return hwid[HWID_CORE_LEN:] == hwid_check(core)


def sign(code_id, hwid, exp=""):
    """到期日也进签名：改到期日必然破坏签名，游戏端才敢只靠它判有效期。"""
    raw = "%s|%s|%s|%s|%s" % (FORMAT, code_id, hwid, exp or "", SECRET)
    return hashlib.md5(raw.encode("utf-8")).hexdigest().upper()[:SIG_LEN]


# ── 到期日编解码（32 进制，字符集不含易混字符）──────────────────

def day_number(ts=None):
    """返回「EXP_EPOCH 起第几天」（本地时区按日期算，不做夏令时换算）。

    用 CALENDAR 而不是 (ts - t0) // 86400：
    后者会把 N 天期在跨越本地零点时算成 N-1 或 N+1 天，玩家会觉得「怎么少了一天」。
    """
    t = time.localtime(time.time() if ts is None else int(ts))
    a = datetime.date(EXP_EPOCH[0], EXP_EPOCH[1], EXP_EPOCH[2])
    b = datetime.date(t.tm_year, t.tm_mon, t.tm_mday)
    return (b - a).days


def exp_encode(day):
    """把天数编成 4 位 32 进制。超范围抛 ValueError。"""
    day = int(day)
    if day < 0:
        raise ValueError("到期日不能早于 %04d-%02d-%02d" % EXP_EPOCH)
    if day >= len(EXP_CHARS) ** EXP_LEN:
        raise ValueError("到期日超出可表示范围（%d 天）" % (len(EXP_CHARS) ** EXP_LEN))
    out = []
    for _ in range(EXP_LEN):
        out.append(EXP_CHARS[day % len(EXP_CHARS)])
        day //= len(EXP_CHARS)
    return "".join(reversed(out))


def exp_decode(exp):
    """4 位 32 进制 → 天数。格式不合法返回 -1。"""
    exp = str(exp or "").strip().upper()
    if len(exp) != EXP_LEN:
        return -1
    value = 0
    for ch in exp:
        pos = EXP_CHARS.find(ch)
        if pos < 0:
            return -1
        value = value * len(EXP_CHARS) + pos
    return value


def exp_for(days=None, ts=None):
    """签发用：返回 (到期日段, 到期时间戳)。"""
    n = LICENSE_DAYS if days is None else int(days)
    if n < 1:
        n = 1
    day = day_number(ts) + n
    return exp_encode(day), day


def exp_date_text(exp):
    """到期日段 → "YYYY-MM-DD"，给日志/机器人文案用。"""
    day = exp_decode(exp)
    if day < 0:
        return "?"
    a = datetime.date(EXP_EPOCH[0], EXP_EPOCH[1], EXP_EPOCH[2])
    return (a + datetime.timedelta(days=day)).strftime("%Y-%m-%d")


def exp_expired(exp, ts=None):
    """是否已过期。格式坏了一律当过期（宁可让玩家重领，不要放过期码）。"""
    day = exp_decode(exp)
    if day < 0:
        return True
    return day_number(ts) > day


def make_code(code_id, hwid, exp=None):
    hwid = norm_hwid(hwid)
    if not hwid_valid(hwid):
        raise ValueError("机器码不合法：%r（应为 8 位十六进制）" % hwid)
    if not exp:
        exp, _day = exp_for()
    return "%s-%s-%s-%s-%s" % (FORMAT, code_id, hwid, exp, sign(code_id, hwid, exp))


def id_valid(code_id):
    if not (ID_MIN <= len(code_id) <= ID_MAX):
        return False
    for ch in code_id:
        if ch not in ID_CHARS:
            return False
    return True


def parse_code(code):
    """返回 (码ID, 机器码, 到期日, 签名)。格式不合法抛 ValueError。"""
    parts = str(code or "").strip().upper().split("-")
    if len(parts) != 5:
        raise ValueError("格式错误，应为 FVM4-XXXXXXXX-XXXXXXXX-XXXX-XXXXXXXXXX")
    if parts[0] != FORMAT:
        raise ValueError("前缀不是 %s" % FORMAT)
    if not id_valid(parts[1]):
        raise ValueError("码 ID 段不合法")
    hwid = norm_hwid(parts[2])
    if not hwid_valid(hwid):
        raise ValueError("机器码段不合法")
    if exp_decode(parts[3]) < 0:
        raise ValueError("到期日段不合法")
    return parts[1], hwid, parts[3], parts[4]


def verify(code, check_exp=False, ts=None):
    """返回 (是否有效, 码ID, 机器码)。不查池子，只看签名（和可选的到期）。

    默认**不判到期**：签发端问「这码是我签的吗」时，过期了也算签对了，
    好让调用方能分开提示「签名错」和「过期了」。机器人发码前查重时才传
    check_exp=True —— 过期的旧码不能直接返给玩家，得重签。
    """
    try:
        code_id, hwid, exp, sig = parse_code(code)
    except ValueError:
        return False, "", ""
    if sign(code_id, hwid, exp) != sig:
        return False, "", ""
    if check_exp and exp_expired(exp, ts):
        return False, "", ""
    return True, code_id, hwid


# ---------------------------------------------------------------- 池子

def load_pool():
    if not os.path.exists(POOL_PATH):
        return []
    out = []
    with open(POOL_PATH, "r", encoding="utf-8") as fh:
        for line in fh:
            value = line.strip().upper()
            if value and not value.startswith("#"):
                out.append(value)
    return out


def save_pool(ids):
    with open(POOL_PATH, "w", encoding="utf-8") as fh:
        fh.write("# 授权码池：一行一个，机器人按顺序发。\n")
        fh.write("# 字符集限 %s（去掉了易混淆的 0/O/1/I）\n" % ID_CHARS)
        for value in ids:
            fh.write(value + "\n")


def gen_ids(count, existing):
    existing = set(existing or [])
    result = []
    while len(result) < count:
        value = "".join(random.choice(ID_CHARS) for _ in range(ID_LEN))
        if value in existing or value in result:
            continue
        result.append(value)
    return result


# ---------------------------------------------------------------- 账本

class Ledger(object):
    """账本以**机器码**为主键。

    「一个码只能在一台机器上用」是这套方案的核心约束，
    而机器码是唯一能同时被游戏端和机器人端算出的因子
    （游戏端拿不到 openid，机器人端拿不到硬件信息），
    所以它必须当主键：同一台机器只会有一个有效码。
    """

    def __init__(self, path):
        self.path = path
        self._conn = sqlite3.connect(path)
        self._ensure_schema()

    def _ensure_schema(self):
        cols = [r[1] for r in self._conn.execute("PRAGMA table_info(issued)").fetchall()]
        if cols and "hwid" not in cols:
            # 旧版（FVM3，只按 uid 记账）自动归档，不删数据
            backup = "issued_%s" % time.strftime("%Y%m%d%H%M%S")
            self._conn.execute("ALTER TABLE issued RENAME TO %s" % backup)
            self._conn.commit()
            print("⚠️  检测到旧版账本，已归档为 %s（旧码全部作废，需重新发放）" % backup,
                  file=sys.stderr)
            cols = []
        if not cols:
            self._conn.execute(
                "CREATE TABLE IF NOT EXISTS issued ("
                " hwid TEXT PRIMARY KEY,"
                " uid TEXT NOT NULL,"
                " code_id TEXT NOT NULL UNIQUE,"
                " code TEXT NOT NULL,"
                " ts INTEGER NOT NULL,"
                " exp TEXT NOT NULL DEFAULT '',"
                " exp_day INTEGER NOT NULL DEFAULT 0"
                ")"
            )
            self._conn.commit()
        elif "exp" not in cols:
            # 老账本（有 hwid 但没有到期列）：直接加列，**不动数据**。
            # 存量记录 exp 为空 = 视为「无到期」，正好让它们自然被重签。
            self._conn.execute("ALTER TABLE issued ADD COLUMN exp TEXT NOT NULL DEFAULT ''")
            self._conn.execute("ALTER TABLE issued ADD COLUMN exp_day INTEGER NOT NULL DEFAULT 0")
            self._conn.commit()
            print("ℹ️  账本已升级：新增 exp / exp_day 两列（存量记录视为无到期，下次领码自动重签）",
                  file=sys.stderr)

    def get_by_hwid(self, hwid):
        return self._conn.execute(
            "SELECT hwid, uid, code_id, code, ts, exp FROM issued WHERE hwid = ?",
            (norm_hwid(hwid),),
        ).fetchone()

    def get_by_uid(self, uid):
        return self._conn.execute(
            "SELECT hwid, uid, code_id, code, ts, exp FROM issued WHERE uid = ? ORDER BY ts",
            (str(uid),),
        ).fetchall()

    def count_by_uid(self, uid, only_valid=True):
        """数某个账号占了几台机器。

        only_valid=True（默认）：**只数还没过期的**。
        过期码在游戏里已经验不过，不该继续占名额 —— 否则玩家停几天不玩，
        两个名额就被两张废码永久占死，只能找管理解绑。

        exp_day 是到期日的整数天（空 exp / 老账本记录为 0），
        所以 `exp_day >= 今天` 就等价于「还没过期」，不需要逐行解字符串。
        """
        if not only_valid:
            return self._conn.execute(
                "SELECT COUNT(*) FROM issued WHERE uid = ?", (str(uid),)
            ).fetchone()[0]
        return self._conn.execute(
            "SELECT COUNT(*) FROM issued WHERE uid = ? AND exp_day >= ?",
            (str(uid), day_number()),
        ).fetchone()[0]

    def used_ids(self):
        return set(row[0] for row in self._conn.execute("SELECT code_id FROM issued"))

    def put(self, uid, hwid, code_id, code, exp=""):
        exp = str(exp or "").upper()
        day = exp_decode(exp)
        self._conn.execute(
            "INSERT OR REPLACE INTO issued (hwid, uid, code_id, code, ts, exp, exp_day)"
            " VALUES (?,?,?,?,?,?,?)",
            (norm_hwid(hwid), str(uid), code_id, code, int(time.time()), exp,
             day if day >= 0 else 0),
        )
        self._conn.commit()

    def drop_hwid(self, hwid):
        cur = self._conn.execute("DELETE FROM issued WHERE hwid = ?", (norm_hwid(hwid),))
        self._conn.commit()
        return cur.rowcount

    def drop_uid(self, uid):
        """解绑某个账号下**所有**机器。别人顶到上限时用这个救。"""
        cur = self._conn.execute("DELETE FROM issued WHERE uid = ?", (str(uid),))
        self._conn.commit()
        return cur.rowcount

    def all(self):
        return self._conn.execute(
            "SELECT hwid, uid, code_id, code, ts, exp FROM issued ORDER BY ts"
        ).fetchall()

    def count(self):
        return self._conn.execute("SELECT COUNT(*) FROM issued").fetchone()[0]

    def close(self):
        self._conn.close()


def fmt_ts(ts):
    try:
        return time.strftime("%Y-%m-%d %H:%M", time.localtime(int(ts)))
    except Exception:
        return str(ts)


class PoolExhausted(Exception):
    pass


class TooManyDevices(Exception):
    pass


class HwidTakenByOther(Exception):
    """这台机器的码已经被别的账号领过了。

    不加这条，A 只要知道 B 的识别码就能把 B 的码「领」到自己名下 ——
    虽然码本身在 B 的机器上仍然有效（签名绑的是机器），但账本里那条的
    uid 会变成 A，B 再问就是「码在别人名下」，名额也算到 A 头上。
    """


def issue_for(uid, hwid, ledger=None, explicit_id=None):
    """发码。返回 (code, is_new)。

    规则：
      · 同一台机器（hwid）永远只返回同一个码 —— 这是「别人不能再用」的根
      · 换机器 = 换 hwid = 发新码，旧码在新机器上验签必失败，自然作废
      · 同一个 uid 最多绑 MAX_DEVICES_PER_UID 台机器（默认 2），
        超了抛 TooManyDevices，必须由管理先解绑
      · 这台机器已经绑在别的 uid 名下 → 抛 HwidTakenByOther
      · 码有 %d 天有效期：同机器来领时若旧码已过期（或存量老码没到期日），
        **沿用原来的码 ID 重签一个新到期日**，不消耗池子里的新 ID
    池子耗尽时抛 PoolExhausted。

    机器码必须是 10 位（8 位正文 + 2 位校验），乱敲的会被 hwid_valid 拒掉，
    连账本都不进 —— 这就是「随便输一串也能骗到码」的堵法。
    """ % LICENSE_DAYS
    uid = str(uid).strip()
    hwid = norm_hwid(hwid)
    if not hwid_valid(hwid):
        raise ValueError("识别码不合法，应为 10 位（含 2 位校验），从游戏里复制")
    if not uid:
        raise ValueError("uid 不能为空")

    own = ledger is None
    if own:
        ledger = Ledger(DB_PATH)
    try:
        row = ledger.get_by_hwid(hwid)
        if row:
            # 同一台机器被另一个账号来领：不许把归属改走
            if str(row[1]) != uid:
                raise HwidTakenByOther(
                    "这台机器的授权码已经绑在另一个账号名下了。"
                )
            old_code = row[3]
            # row[5] = exp，存量老账本可能是空串 → exp_expired 当过期 → 重签
            if not exp_expired(row[5]):
                return old_code, False
            code_id = row[2]
            new_code = make_code(code_id, hwid)
            new_exp, _day = exp_for()
            ledger.put(row[1], hwid, code_id, new_code, new_exp)
            return new_code, True

        bound = ledger.count_by_uid(uid)
        if bound >= MAX_DEVICES_PER_UID:
            # 注意：这里只是陈述事实。**不要**把解绑办法写进异常文案，
            # 机器人会把它当成玩家可见内容转发出去。
            raise TooManyDevices(
                "这个账号已经绑了 %d 台机器，达到上限 %d 台。"
                % (bound, MAX_DEVICES_PER_UID)
            )

        pool = load_pool()
        if not pool:
            raise PoolExhausted("池子为空，先跑 poolgen 或编辑 tools/codes_pool.txt")

        used = ledger.used_ids()
        if explicit_id:
            code_id = str(explicit_id).strip().upper()
            if not id_valid(code_id):
                raise ValueError("指定的 ID 不合法：%s" % code_id)
            if code_id not in pool:
                raise ValueError("指定的 ID 不在池子里：%s" % code_id)
            if code_id in used:
                raise ValueError("指定的 ID 已经被用掉了：%s" % code_id)
        else:
            available = [i for i in pool if i not in used]
            if not available:
                raise PoolExhausted("池子里 %d 个码已经全部发完，加码后继续" % len(pool))
            code_id = available[0]

        code = make_code(code_id, hwid)
        _exp, _day = exp_for()
        ledger.put(uid, hwid, code_id, code, _exp)
        return code, True
    finally:
        if own:
            ledger.close()


# ---------------------------------------------------------------- 子命令

def cmd_poolgen(argv):
    args = [a for a in argv if not a.startswith("--")]
    count = int(args[0]) if args else 100
    pool = load_pool()
    new_ids = gen_ids(count, pool)
    save_pool(pool + new_ids)
    print("已生成 %d 个新码，池子共 %d 个 -> %s" % (count, len(pool) + len(new_ids), POOL_PATH))
    return 0


def cmd_pool(_argv):
    pool = load_pool()
    if not pool:
        print("池子为空（%s）" % POOL_PATH)
        return 0
    ledger = Ledger(DB_PATH)
    try:
        used = ledger.used_ids()
    finally:
        ledger.close()
    remaining = [i for i in pool if i not in used]
    issued_from_pool = len(used & set(pool))
    print("池子 %d 个：已发 %d，剩余 %d" % (len(pool), issued_from_pool, len(remaining)))
    if remaining:
        print("下一个会发：" + remaining[0])
    else:
        print("⚠️  池子已空，跑 poolgen 加码")
    return 0


def cmd_issue(argv):
    explicit = None
    if "--id" in argv:
        i = argv.index("--id")
        if i + 1 >= len(argv):
            print("--id 后面要跟池子里的码 ID", file=sys.stderr)
            return 1
        explicit = argv[i + 1]
        argv = argv[:i] + argv[i + 2:]
    args = [a for a in argv if not a.startswith("--")]
    if len(args) < 2:
        print("用法: issue <QQ号或openid> <机器码> [--id 指定池子里的某个ID]", file=sys.stderr)
        print("机器码 = 游戏内授权窗口里的「本机识别码」，8 位十六进制", file=sys.stderr)
        return 1
    uid = str(args[0]).strip()
    hwid = norm_hwid(args[1])
    if not uid:
        print("uid 不能为空", file=sys.stderr)
        return 1
    if not hwid_valid(hwid):
        print("机器码不合法：%r（应为 8 位十六进制，如 1A2B3C4D）" % args[1], file=sys.stderr)
        return 1

    ledger = Ledger(DB_PATH)
    try:
        row = ledger.get_by_hwid(hwid)
        if row and not exp_expired(row[5]):
            print(row[3])
            print("# 这台机器已发放过（%s），到期 %s，返回原码"
                  % (fmt_ts(row[4]), exp_date_text(row[5])), file=sys.stderr)
            return 0
        if row:
            print("# 这台机器上一张码已于 %s 到期，重新签发" % exp_date_text(row[5]),
                  file=sys.stderr)
        code, _is_new = issue_for(uid, hwid, ledger, explicit)
        _cid, _hw, _exp, _sig = parse_code(code)
        print(code)
        print("# 有效期至 %s（%d 天）" % (exp_date_text(_exp), LICENSE_DAYS), file=sys.stderr)
        return 0
    except PoolExhausted as exc:
        print("# %s" % exc, file=sys.stderr)
        return 3
    except TooManyDevices as exc:
        print("# %s" % exc, file=sys.stderr)
        print("# （仅管理可见）要解绑该账号全部机器："
              "python tools/qq_auth.py revoke --uid %s" % uid, file=sys.stderr)
        return 4
    except ValueError as exc:
        print("# %s" % exc, file=sys.stderr)
        return 1
    finally:
        ledger.close()


def cmd_revoke(argv):
    if "--uid" in argv:
        i = argv.index("--uid")
        if i + 1 >= len(argv):
            print("--uid 后面要跟账号标识（账本里的 uid/openid）", file=sys.stderr)
            return 1
        uid = argv[i + 1].strip()
        ledger = Ledger(DB_PATH)
        try:
            n = ledger.drop_uid(uid)
            if n:
                print("已解绑 %s 名下的 %d 台机器，该账号可以重新领码" % (uid, n))
                return 0
            print("账本里没有这个账号：%s" % uid, file=sys.stderr)
            return 2
        finally:
            ledger.close()

    args = [a for a in argv if not a.startswith("--")]
    if not args:
        print("用法: revoke <机器码>        让这台机器上的码失效，下次重新领", file=sys.stderr)
        print("      revoke --uid <账号>    解绑该账号名下所有机器（顶到上限时用）", file=sys.stderr)
        return 1
    hwid = norm_hwid(args[0])
    if not hwid_valid(hwid):
        print("机器码不合法", file=sys.stderr)
        return 1
    ledger = Ledger(DB_PATH)
    try:
        n = ledger.drop_hwid(hwid)
        if n:
            print("已作废机器 %s 的授权，玩家需要用本机识别码重新领码" % hwid)
            return 0
        print("账本里没有这台机器：%s" % hwid, file=sys.stderr)
        return 2
    finally:
        ledger.close()


def cmd_ledger(_argv):
    ledger = Ledger(DB_PATH)
    try:
        rows = ledger.all()
        if not rows:
            print("还没有发放记录")
            return 0
        print("共 %d 条" % len(rows))
        print("%-10s %-34s %-10s %-30s %-8s %s"
              % ("机器码", "用户(QQ/openid)", "码ID", "授权码", "到期", "发放时间"))
        for hwid, uid, code_id, code, ts, exp in rows:
            print("%-10s %-34s %-10s %-30s %-8s %s"
                  % (hwid, uid, code_id, code, exp_date_text(exp) if exp else "无期",
                     fmt_ts(ts)))
        return 0
    finally:
        ledger.close()


def cmd_export(argv):
    args = [a for a in argv if not a.startswith("--")]
    out = args[0] if args else "qq_export.csv"
    ledger = Ledger(DB_PATH)
    try:
        rows = ledger.all()
        with open(out, "w", encoding="utf-8-sig") as fh:
            fh.write("hwid,uid,code_id,code,issued_at,expires_at,expired\n")
            for hwid, uid, code_id, code, ts, exp in rows:
                fh.write("%s,%s,%s,%s,%s,%s,%s\n"
                         % (hwid, uid, code_id, code, fmt_ts(ts),
                            exp_date_text(exp) if exp else "",
                            "1" if exp_expired(exp) else "0"))
        print("已导出 %d 条 -> %s" % (len(rows), out))
        return 0
    finally:
        ledger.close()


def cmd_verify(argv):
    args = [a for a in argv if not a.startswith("--")]
    if not args:
        print("用法: verify <授权码>")
        return 1
    ok, code_id, hwid = verify(args[0])
    if not ok:
        print("无效（格式不对或签名对不上）")
        return 2
    _cid, _hw, exp, _sig = parse_code(args[0])
    left = exp_decode(exp) - day_number()
    print("签名有效  码ID=%s  绑定机器=%s" % (code_id, hwid))
    print("到期日 %s（还剩 %d 天）" % (exp_date_text(exp), left))
    if left < 0:
        print("⚠️  这张码已经过期了，让玩家重新领")
        return 3
    print("（只有机器码为 %s 的那台机器能用这个码）" % hwid)
    return 0


def cmd_gml(_argv):
    cut = max(1, len(SECRET) // 3)
    a, b, c = SECRET[:cut], SECRET[cut:cut * 2], SECRET[cut * 2:]
    assert a + b + c == SECRET
    print("// ======== 覆盖 scripts/auth_client/auth_client.gml 顶部这段 ========")
    print('#macro kAuthPrefix "%s"' % FORMAT)
    print('#macro kAuthSecretA "%s"' % a)
    print('#macro kAuthSecretB "%s"' % b)
    print('#macro kAuthSecretC "%s"' % c)
    print('#macro kAuthSealKey "%s"'
          % hashlib.md5((SECRET + "|seal").encode("utf-8")).hexdigest().upper()[:24])
    return 0


def selftest():
    HWID_A = make_hwid("1A2B3C4D")      # 10 位，带校验
    HWID_B = make_hwid("9F8E7D6C")
    assert len(HWID_A) == HWID_LEN == 10
    assert HWID_A == "1A2B3C4D7E", HWID_A     # 与 GML 端逐位一致（见 auth_hwid_check）

    code = make_code("8F3K2M9Q", HWID_A)
    ok, code_id, hwid = verify(code)
    assert ok and code_id == "8F3K2M9Q" and hwid == HWID_A, code
    assert len(code.split("-")) == 5, "新格式应为 5 段"

    # 到期日段必须能解回「今天 + LICENSE_DAYS」
    _cid, _hw, _exp, _sig = parse_code(code)
    assert exp_decode(_exp) - day_number() == LICENSE_DAYS, _exp
    assert exp_expired(_exp) is False, "刚发的码不该过期"
    # 到期日当天仍有效，第二天才失效
    assert exp_expired(_exp, ts=None) is False
    tomorrow_day = exp_encode(day_number() - 1)
    assert exp_expired(tomorrow_day) is True, "昨天的码应当已过期"
    today_day = exp_encode(day_number())
    assert exp_expired(today_day) is False, "当天仍然有效（含当天）"
    assert exp_expired("") is True and exp_expired("!!!!") is True, "坏格式一律当过期"

    # 改签名无效
    assert verify(code[:-1] + ("2" if code[-1] != "2" else "3"))[0] is False
    # 改到期日（签名体被改）→ 验签失败，玩家没法自己续期
    fake_exp = exp_encode(day_number() + 3650)
    assert verify("FVM4-8F3K2M9Q-%s-%s-%s" % (HWID_A, fake_exp, _sig))[0] is False, \
        "改到期日必须破坏签名"
    # 换机器码 = 签名对不上 → 这正是「别人拿到也用不了」的核心
    assert verify("FVM4-8F3K2M9Q-%s-%s-%s"
                  % (HWID_B, _exp, sign("8F3K2M9Q", HWID_A, _exp)))[0] is False
    # 换 ID
    assert verify("FVM4-AAAAAAAA-%s-%s-%s"
                  % (HWID_A, _exp, sign("8F3K2M9Q", HWID_A, _exp)))[0] is False
    # 格式垃圾
    for bad in ["", "FVM4", "FVM4-8F3K2M9Q",
                "FVM3-8F3K2M9Q-%s-%s" % (HWID_A, sign("8F3K2M9Q", HWID_A, _exp)),
                "FVM4-8F3K2M9Q-%s" % HWID_A,
                "FVM4-8F3K2M9Q-%s-%s" % (HWID_A, sign("8F3K2M9Q", HWID_A, _exp)),
                "FVM4-8F3K2M9Q-%s-%s-%s" % (HWID_A, _exp, _sig.lower()[:-1])]:
        assert verify(bad)[0] is False, bad
    # 到期日段不能塞垃圾：parse_code 直接拒（哪怕签名是照这个垃圾算的）
    for bad_exp in ["", "!!!!", "ABCDE", "A", "0000"]:
        assert verify("FVM4-8F3K2M9Q-%s-%s-%s"
                      % (HWID_A, bad_exp, sign("8F3K2M9Q", HWID_A, bad_exp)))[0] is False, bad_exp
    # ID / 识别码字符集
    assert id_valid("8F3K2M9Q") is True
    assert id_valid("8F3K2M9O") is False   # 字母 O 被排除
    assert id_valid("ABC") is False

    # ── 识别码的 2 位校验：挡「随手敲一串也发码」 ──
    # 这是本轮修的核心洞：以前只查 8 位十六进制，8BDAF386 / DEADBEEF
    # 全都能过，机器人照发一张真码，还占掉这个 QQ 的设备名额。
    assert hwid_valid(HWID_A) is True
    assert hwid_valid("1A2B3C4D7E") is True, "带对校验的 10 位必须过"
    assert hwid_valid("1A2B3C4D") is False, "只有 8 位正文、没校验 → 拒"
    assert hwid_valid("1A2B3C4D00") is False, "校验位算错 → 拒"
    assert hwid_valid("DEADBEEF") is False, "随手敲的 8 位 → 拒"
    assert hwid_valid("DEADBEEFE2") is True, "敲对了校验才放行（这是盐的边界）"
    assert hwid_valid("") is False and hwid_valid("XYZ") is False
    assert norm_hwid(" 1a2b-3c4d 7e ") == "1A2B3C4D7E"
    assert norm_hwid("1A2B3C4D") == ""      # 不够 10 位 → 洗不出来
    assert make_hwid("1a2b3c4d") == "1A2B3C4D7E"
    try:
        make_hwid("1A2B3C4")
        raise AssertionError("7 位正文应当报错")
    except ValueError:
        pass
    try:
        make_hwid("ZZZZZZZZ")
        raise AssertionError("非十六进制应当报错")
    except ValueError:
        pass
    # 到期日编码往返
    for d in (0, 1, 7, 100, 3000, len(EXP_CHARS) ** EXP_LEN - 1):
        assert exp_decode(exp_encode(d)) == d, d
    assert exp_decode(exp_encode(7)).__class__ is int
    try:
        exp_encode(-1)
        raise AssertionError("负天数应当报错")
    except ValueError:
        pass

    # 池子 + 发放：换到临时目录跑，别污染真实数据
    global POOL_PATH, DB_PATH
    origin_pool, origin_db = POOL_PATH, DB_PATH
    tmp_pool = os.path.join(HERE, "_selftest_pool.txt")
    tmp_db = os.path.join(HERE, "_selftest.db")
    for p in (tmp_pool, tmp_db):
        if os.path.exists(p):
            os.remove(p)
    try:
        POOL_PATH, DB_PATH = tmp_pool, tmp_db
        save_pool(gen_ids(4, []))
        led = Ledger(tmp_db)
        try:
            c1, new1 = issue_for("u1", HWID_A, led)
            c2, new2 = issue_for("u1", HWID_A, led)
            assert c1 == c2 and new1 is True and new2 is False, "同一台机器必须返回同一个码"
            assert verify(c1)[0] is True

            # 账本里必须存了到期日
            row1 = led.get_by_hwid(HWID_A)
            assert len(row1) == 6 and row1[5] == parse_code(c1)[2], row1
            assert exp_expired(row1[5]) is False

            # 把到期日手动改成「昨天」→ 再领必须重签（同 ID、新码、仍只对这台机器有效）
            old_day = exp_decode(row1[5])
            expired_exp = exp_encode(old_day - (LICENSE_DAYS + 1))
            expired_code = "FVM4-%s-%s-%s-%s" % (row1[2], HWID_A, expired_exp,
                                                 sign(row1[2], HWID_A, expired_exp))
            assert exp_expired(expired_exp) is True
            led.put("u1", HWID_A, row1[2], expired_code, expired_exp)
            assert led.get_by_hwid(HWID_A)[3] == expired_code
            c_re, new_re = issue_for("u1", HWID_A, led)
            assert new_re is True, "过期的码必须重签，不能原样返回"
            assert c_re != expired_code
            assert parse_code(c_re)[0] == row1[2], "重签应沿用原码 ID，不消耗新 ID"
            assert exp_expired(parse_code(c_re)[2]) is False
            assert parse_code(c_re)[1] == HWID_A

            # 同一台机器被另一个账号来领：不许改走归属（HwidTakenByOther）
            # 否则 A 只要知道 B 的识别码，就能把 B 的码「领」到自己名下，
            # 名额算到 A 头上、B 再问就变成「在别人名下」。
            try:
                issue_for("u2", HWID_A, led)
                raise AssertionError("别人的机器不该能领走")
            except HwidTakenByOther:
                assert led.get_by_hwid(HWID_A)[1] == "u1", "归属被改走了"

            # 换机器 → 新码，且旧码在新机器上无效
            c4, new4 = issue_for("u1", HWID_B, led)
            assert new4 is True and c4 != c1
            assert verify(c4)[2] == HWID_B
            assert verify(c1)[2] == HWID_A

            # 一个 uid 多机器受上限约束：u1 现在已占 HWID_A + HWID_B 两台
            assert led.count_by_uid("u1") == 2, "u1 应已绑 2 台"

            # 超上限必须抛 TooManyDevices，不能悄悄发新码
            over = make_hwid("%08X" % 0x33330000)
            try:
                issue_for("u1", over, led)
                raise AssertionError("超出 %d 台上限仍发了码" % MAX_DEVICES_PER_UID)
            except TooManyDevices:
                assert led.get_by_hwid(over) is None, "被拒的机器不该进账本"

            # 解绑后可以重新领
            assert led.drop_uid("u1") == 2
            c_again, new_again = issue_for("u1", HWID_B, led)
            assert new_again is True and c_again != c4, "解绑后应能重新领码"

            # ── 名额只算「还有效」的码 ──
            # 玩家停玩一段时间后，手里的码全过期了，不该继续占名额，
            # 否则两个名额会被两张废码永久占死，只能找管理解绑。
            assert led.count_by_uid("u1") == 1, "解绑后应只剩 1 台"
            HWID_C = make_hwid("%08X" % 0x33330000)
            c5, _ = issue_for("u1", HWID_C, led)
            assert led.count_by_uid("u1") == 2, "第二台应正常占用名额"

            # 第 3 台必须被拒（此时 2 台都还有效）
            HWID_D = make_hwid("%08X" % 0x44440000)
            try:
                issue_for("u1", HWID_D, led)
                raise AssertionError("两台都有效时第 3 台不该发码")
            except TooManyDevices:
                pass

            # 把其中一台的码改成已过期 → 有效名额掉到 1，第 3 台就能领了
            row_c = led.get_by_hwid(HWID_C)
            dead_exp = exp_encode(exp_decode(row_c[5]) - (LICENSE_DAYS + 1))
            assert exp_expired(dead_exp) is True
            led.put("u1", HWID_C, row_c[2],
                    "FVM4-%s-%s-%s-%s" % (row_c[2], HWID_C, dead_exp,
                                          sign(row_c[2], HWID_C, dead_exp)),
                    dead_exp)
            assert led.count_by_uid("u1") == 1, "过期码不该继续占名额"
            assert led.count_by_uid("u1", only_valid=False) == 2, "全量计数仍应是 2"
            c6, new6 = issue_for("u1", HWID_D, led)
            assert new6 is True, "名额被过期码占住，第 3 台领不到码"
            assert led.count_by_uid("u1") == 2, "发完又是 2 台有效"

            # 老账本里的空 exp（视为无到期）同样不占名额
            # 此时 B / D 两台有效，C 改成空 exp → 有效还是 2，全量是 3
            led.put("u1", HWID_C, row_c[2], row_c[3], "")
            assert led.count_by_uid("u1") == 2, "空 exp 的老记录不该占名额"
            assert led.count_by_uid("u1", only_valid=False) == 3, "全量计数应是 3"

            # 池子耗尽
            try:
                for i in range(10):
                    issue_for("pool%d" % i, make_hwid("%08X" % (0x22220000 + i)), led)
                raise AssertionError("池子应当耗尽")
            except PoolExhausted:
                pass

            # 作废
            assert led.drop_hwid(HWID_B) == 1
            assert led.get_by_hwid(HWID_B) is None
        finally:
            led.close()
    finally:
        POOL_PATH, DB_PATH = origin_pool, origin_db
        for p in (tmp_pool, tmp_db):
            if os.path.exists(p):
                os.remove(p)
    print("selftest ok")


COMMANDS = {
    "poolgen": cmd_poolgen,
    "pool": cmd_pool,
    "issue": cmd_issue,
    "revoke": cmd_revoke,
    "ledger": cmd_ledger,
    "export": cmd_export,
    "verify": cmd_verify,
    "gml": cmd_gml,
}


def main():
    argv = sys.argv[1:]
    if not argv:
        print(__doc__)
        return 0
    name, rest = argv[0], argv[1:]
    if name == "selftest":
        selftest()
        return 0
    if name not in COMMANDS:
        print("未知命令: %s" % name)
        print("可用: %s, selftest" % ", ".join(COMMANDS))
        return 1
    return COMMANDS[name](rest)


if __name__ == "__main__":
    sys.exit(main())

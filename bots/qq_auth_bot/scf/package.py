# -*- coding: utf-8 -*-
"""打包并校验 scf-qqauth.zip（给 pwsh 一把梭用，避免行内引号转义问题）。"""
import hashlib
import json
import os
import subprocess
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
ZIP = os.path.join(ROOT, "scf-qqauth.zip")


def build():
    py = sys.executable
    print("=== 打包 ===")
    r = subprocess.run([py, os.path.join(HERE, "build.py")],
                       cwd=ROOT, capture_output=True, text=True, encoding="utf-8")
    print((r.stdout or "").strip().splitlines()[-1] if r.stdout else "")
    if r.returncode != 0:
        print(r.stderr)
        return False
    return True


def verify():
    print("=== 校验 ===")
    raw = open(ZIP, "rb").read()
    print("文件: %s" % ZIP)
    print("大小: %d B" % len(raw))
    print("sha256: %s" % hashlib.sha256(raw).hexdigest()[:16])
    z = zipfile.ZipFile(ZIP)
    print("成员: %s" % ", ".join(z.namelist()))

    bot = z.read("bot.py").decode("utf-8")
    checks = [
        ("bot.py 有 STRICT_TRIGGER", "STRICT_TRIGGER" in bot),
        ("bot.py 有 strict_gate", "def strict_gate" in bot),
        ("bot.py 有 mention_targets_me", "def mention_targets_me" in bot),
        ("bot.py 默认命令是 /授权", '_conf("AUTH_COMMAND", "auth_command", "/授权")' in bot),
        ("bot.py 认 GROUP_MESSAGE_CREATE",
         'name in ("GROUP_AT_MESSAGE_CREATE", "GROUP_MESSAGE_CREATE")' in bot),
        ("bot.py 发码文案带到期日", "def format_code_msg" in bot and "{expires}" in bot),
    ]
    hook = z.read("webhook.py").decode("utf-8")
    checks += [
        ("webhook.py 走 strict_gate", "strict_gate" in hook),
        ("webhook.py 不再回 MSG_GREETING（严格分支）",
         hook.count("MSG_GREETING") <= 1),
        ("webhook.py 发码走 format_code_msg", "format_code_msg" in hook),
    ]
    # 有效期逻辑全在 qq_auth.py 里：打包进去的那份必须带 5 段格式与到期日编解码，
    # 否则云端会按旧的 4 段格式签发，游戏端（已按 5 段验）会判全部无效。
    qa = z.read("qq_auth.py").decode("utf-8")
    checks += [
        ("qq_auth.py 有 EXP_LEN（5 段格式）", "EXP_LEN" in qa),
        ("qq_auth.py 有 LICENSE_DAYS", "LICENSE_DAYS" in qa),
        ("qq_auth.py 有 exp_encode/exp_decode",
         "def exp_encode" in qa and "def exp_decode" in qa),
        ("qq_auth.py 有 exp_expired（过期判定）", "def exp_expired" in qa),
        ("qq_auth.py 的 make_code 输出 5 段",
         '"%s-%s-%s-%s-%s" % (FORMAT, code_id, hwid, exp, sign(code_id, hwid, exp))' in qa),
    ]
    # 名额只算还没过期的码：云端账本（store.py）与签发端（qq_auth.py）各有一份实现
    st = z.read("store.py").decode("utf-8")
    checks += [
        ("store.py 的 count_by_uid 支持 only_valid", "def count_by_uid(self, uid, only_valid=True)" in st),
        ("store.py 自带到期日解析（不引 qq_auth 依赖）",
         "def _exp_day" in st and "def _today_number" in st),
        ("qq_auth.py 的 count_by_uid 支持 only_valid",
         "def count_by_uid(self, uid, only_valid=True)" in qa),
        ("qq_auth.py 名额按 exp_day 过滤", "AND exp_day >=" in qa),
    ]
    # 识别码 10 位（8 位正文 + 2 位校验）：挡住「随手敲 8 位十六进制骗码 + 占名额」
    # 也要确认游戏端跟着改了 —— 两端格式不一致会让所有玩家都验不过。
    checks += [
        ("qq_auth.py 有 HWID_SALT", "HWID_SALT" in qa),
        ("qq_auth.py 有 hwid_check/make_hwid",
         "def hwid_check" in qa and "def make_hwid" in qa),
        ("qq_auth.py 识别码长度是 10", "HWID_CORE_LEN + HWID_CHECK_LEN" in qa),
        ("qq_auth.py 有 HwidTakenByOther（不许抢别人的机器）",
         "class HwidTakenByOther" in qa),
        ("bot.py 发码把 ledger 传下去（云端记账）",
         "def issue_for(uid, hwid, ledger=None)" in bot),
        ("bot.py 处理抢绑提示", "MSG_HWID_TAKEN" in bot),
        ("bot.py 识别码文案是 10 位", "XXXX-XXXX-XX" in bot),
        ("webhook.py 处理抢绑", "HwidTakenByOther" in hook),
    ]
    cfg = json.loads(z.read("config.json").decode("utf-8"))
    checks += [
        ("zip 内 config strict_trigger = true", cfg.get("strict_trigger") is True),
        ("zip 内 config auth_command = /授权", cfg.get("auth_command") == "/授权"),
        ("zip 内 config 不含 app_secret", "app_secret" not in cfg),
        ("zip 内 config 不含 admin_token", "admin_token" not in cfg),
    ]
    fails = [n for n, ok in checks if not ok]
    for n, ok in checks:
        print(("  [OK]   " if ok else "  [FAIL] ") + n)
    print()
    if fails:
        print("✗ %d 项不通过" % len(fails))
        return False
    print("✓ 全部通过，可以直接上传")
    return True


if __name__ == "__main__":
    ok = build() and verify()
    sys.exit(0 if ok else 1)

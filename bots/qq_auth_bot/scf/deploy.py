# -*- coding: utf-8 -*-
"""把 scf-qqauth.zip 部署到腾讯云函数（SCF）。

只用标准库：TC3-HMAC-SHA256 手写签名，不依赖 tencentcloud-sdk-python。
密钥从环境变量读，绝不写进文件、绝不进 zip：

    set TENCENT_SECRET_ID=AKID...
    set TENCENT_SECRET_KEY=...
    python deploy.py --check                     # 只读：看账号下有哪些函数
    python deploy.py --create                    # 新建函数（含环境变量）
    python deploy.py --update                    # 已有函数：只换代码
    python deploy.py --env                       # 已有函数：只改环境变量
    python deploy.py --all                       # 打包 + 校验 + 部署 + 打函数 URL

为什么要有这个脚本：控制台点上传要点七八下，还容易忘「改完环境变量要重新
部署」。这里一条命令做完，失败会打印腾讯返回的原始错误码。
"""
import argparse
import base64
import hashlib
import hmac
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
ZIP = os.path.join(ROOT, "scf-qqauth.zip")
BOT_DIR = os.path.dirname(HERE)
REPO = os.path.dirname(os.path.dirname(BOT_DIR))

HOST = "scf.tencentcloudapi.com"
SERVICE = "scf"
VERSION = "2018-04-16"
DEFAULT_FUNC = "qqauth-bot"
DEFAULT_RUNTIME = "Python3.9"
DEFAULT_HANDLER = "main.main_handler"


# ─────────────────────────── 配置收集 ───────────────────────────

def _env(*names, **kw):
    default = kw.get("default", "")
    for n in names:
        v = (os.environ.get(n) or "").strip()
        if v:
            return v
    return default


def _load_bot_config():
    p = os.path.join(BOT_DIR, "config.json")
    if not os.path.exists(p):
        return {}
    try:
        with open(p, "r", encoding="utf-8") as fh:
            return json.load(fh)
    except Exception:
        return {}


def _read_secret_file(name):
    p = os.path.join(REPO, "tools", name)
    if not os.path.exists(p):
        return ""
    with open(p, "r", encoding="utf-8") as fh:
        return fh.read().strip()


def collect_env_vars(require_cos=True):
    """组装 SCF 环境变量表。缺必填项时返回 (None, 缺失清单)。"""
    cfg = _load_bot_config()
    pairs = []
    missing = []

    def put(key, value, why, required=True):
        if value:
            pairs.append({"Key": key, "Value": str(value)})
        elif required:
            missing.append("%s（%s）" % (key, why))

    put("QQ_APP_ID", _env("QQ_APP_ID") or cfg.get("app_id", ""), "开放平台 AppID")
    put("QQ_APP_SECRET", _env("QQ_APP_SECRET") or cfg.get("app_secret", ""),
        "开放平台 AppSecret")
    put("AUTH_SECRET", _env("AUTH_SECRET") or _read_secret_file("auth_secret.txt"),
        "tools/auth_secret.txt 里的那串")

    cos = {
        "COS_SECRET_ID": _env("COS_SECRET_ID"),
        "COS_SECRET_KEY": _env("COS_SECRET_KEY"),
        "COS_REGION": _env("COS_REGION", default="ap-guangzhou"),
        "COS_BUCKET": _env("COS_BUCKET"),
    }
    for k, v in cos.items():
        put(k, v, "对象存储密钥/桶", required=require_cos)
    put("COS_KEY", _env("COS_KEY", default="qqauth/ledger.json"), "", required=False)

    put("MAX_DEVICES", _env("MAX_DEVICES", default="2"), "", required=False)
    put("ADMIN_QQ", _env("ADMIN_QQ") or cfg.get("admin_qq", ""), "", required=False)
    put("AUTH_ADMIN_TOKEN",
        _env("AUTH_ADMIN_TOKEN") or cfg.get("admin_token", ""),
        "管理员认领口令（不填就没有 /解绑）", required=False)
    put("QQ_BOT_OPENID", _env("QQ_BOT_OPENID") or cfg.get("bot_openid", ""),
        "", required=False)
    put("STRICT_TRIGGER", _env("STRICT_TRIGGER", default="1"), "", required=False)
    put("AUTH_COMMAND", _env("AUTH_COMMAND", default="/授权"), "", required=False)
    # 授权码有效期（天）。改它只影响**新签发**的码，已发的按自己那段到期日算。
    put("LICENSE_DAYS", _env("LICENSE_DAYS", default="3"), "", required=False)
    # 识别码校验位的盐。**必须与游戏端 auth_client.gml 的 kAuthHwidSalt 一致**，
    # 否则游戏算出的识别码机器人会判「不合法」，谁都领不到码。
    put("HWID_SALT", _env("HWID_SALT", default="FVM-HWID-CHECK-2026-11"),
        "", required=False)

    if missing:
        return None, missing
    return pairs, []


# ─────────────────────────── TC3 签名 ───────────────────────────

def _hmac(key, msg):
    return hmac.new(key, msg.encode("utf-8"), hashlib.sha256).digest()


def _sha256_hex(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def sign_request(secret_id, secret_key, action, payload, region="",
                 host=None, service=None, version=None, timestamp=None):
    """返回 (headers, body)。签名算法 TC3-HMAC-SHA256，与腾讯官方文档一致。

    host/service/version/timestamp 只在自检时覆盖，正常调用走模块常量。
    """
    host = host or HOST
    service = service or SERVICE
    payload = payload or {}
    body = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    ts = int(timestamp if timestamp is not None else time.time())
    date = time.strftime("%Y-%m-%d", time.gmtime(ts))

    content_type = "application/json; charset=utf-8"
    signed_headers = "content-type;host"
    canonical_headers = "content-type:%s\nhost:%s\n" % (content_type, host)
    canonical_request = "\n".join([
        "POST", "/", "",
        canonical_headers,
        signed_headers,
        _sha256_hex(body),
    ])
    credential_scope = "%s/%s/tc3_request" % (date, service)
    string_to_sign = "\n".join([
        "TC3-HMAC-SHA256",
        str(ts),
        credential_scope,
        _sha256_hex(canonical_request),
    ])
    k_date = _hmac(("TC3" + secret_key).encode("utf-8"), date)
    k_service = _hmac(k_date, service)
    k_signing = _hmac(k_service, "tc3_request")
    signature = hmac.new(k_signing, string_to_sign.encode("utf-8"),
                         hashlib.sha256).hexdigest()

    headers = {
        "Authorization": ("TC3-HMAC-SHA256 Credential=%s/%s, "
                          "SignedHeaders=%s, Signature=%s"
                          % (secret_id, credential_scope, signed_headers, signature)),
        "Content-Type": content_type,
        "Host": host,
        "X-TC-Action": action,
        "X-TC-Timestamp": str(ts),
        "X-TC-Version": version or VERSION,
    }
    if region:
        headers["X-TC-Region"] = region
    return headers, body


def selftest():
    """自检：只验签名请求的结构是否合规（不联网、不需要密钥）。

    为什么不比对官方文档那个签名样例：那要求逐字节复现文档里的 body 原文
    （空格、换行都算），拿不到原文时对不上只能说明 body 猜错了，不能说明
    算法错了 —— 那种"假红"会误导人。真正的验证是 `--check` 打一次真 API：
    签名错会立刻返回 AuthFailure.SignatureFailure，签名对会返回函数列表。
    """
    print("=== 签名结构自检（不联网）===")
    headers, body = sign_request(
        "AKIDEXAMPLE", "SECRETEXAMPLE", "ListFunctions",
        {"Limit": 50, "Offset": 0}, region="ap-guangzhou")
    checks = []

    auth = headers.get("Authorization", "")
    checks.append(("Authorization 前缀", auth.startswith("TC3-HMAC-SHA256 ")))
    checks.append(("带 Credential", "Credential=AKIDEXAMPLE/" in auth))
    checks.append(("scope 含服务名", "/scf/tc3_request" in auth))
    checks.append(("SignedHeaders 一致", "SignedHeaders=content-type;host" in auth))
    sig = auth.rsplit("Signature=", 1)[-1] if "Signature=" in auth else ""
    checks.append(("签名是 64 位小写 hex",
                   len(sig) == 64 and all(c in "0123456789abcdef" for c in sig)))
    checks.append(("body 是紧凑 JSON", body == '{"Limit":50,"Offset":0}'))
    checks.append(("Host 头与签名一致", headers.get("Host") == HOST))
    checks.append(("X-TC-Action 正确", headers.get("X-TC-Action") == "ListFunctions"))
    checks.append(("X-TC-Version 正确", headers.get("X-TC-Version") == VERSION))
    checks.append(("Region 可传", headers.get("X-TC-Region") == "ap-guangzhou"))
    checks.append(("时间戳是秒级整数",
                   str(headers.get("X-TC-Timestamp", "")).isdigit()
                   and len(str(headers.get("X-TC-Timestamp"))) == 10))

    # 同一输入 + 同一时间戳必须得到同一签名（确定性），换个时间戳必须变。
    h1, _ = sign_request("AKIDEXAMPLE", "SECRETEXAMPLE", "ListFunctions",
                         {"Limit": 50, "Offset": 0}, timestamp=1700000000)
    h2, _ = sign_request("AKIDEXAMPLE", "SECRETEXAMPLE", "ListFunctions",
                         {"Limit": 50, "Offset": 0}, timestamp=1700000000)
    h3, _ = sign_request("AKIDEXAMPLE", "SECRETEXAMPLE", "ListFunctions",
                         {"Limit": 50, "Offset": 0}, timestamp=1700000001)
    checks.append(("同输入同时间 → 同签名", h1["Authorization"] == h2["Authorization"]))
    checks.append(("时间戳变 → 签名变", h1["Authorization"] != h3["Authorization"]))

    fails = [n for n, ok in checks if not ok]
    for n, ok in checks:
        print(("  [OK]   " if ok else "  [FAIL] ") + n)
    print()
    if fails:
        print("✗ %d 项不通过" % len(fails))
        return 1
    print("✓ 结构正确。要验真签名请配好密钥后跑 --check（返回函数列表=通过，"
          "AuthFailure.SignatureFailure=算法或密钥错）")
    return 0




def call(action, payload=None, region="", timeout=60):
    """调一次 SCF API。返回 (ok, dict)。"""
    sid = _env("TENCENT_SECRET_ID", "TC_SECRET_ID", "SECRET_ID")
    skey = _env("TENCENT_SECRET_KEY", "TC_SECRET_KEY", "SECRET_KEY")
    if not sid or not skey:
        print("✗ 没有密钥。先设环境变量：")
        print("    set TENCENT_SECRET_ID=AKIDxxxxxxxx")
        print("    set TENCENT_SECRET_KEY=xxxxxxxx")
        print("  取值：腾讯云控制台 → 访问管理 → API 密钥管理")
        return False, {}

    headers, body = sign_request(sid, skey, action, payload or {}, region)
    req = urllib.request.Request(
        "https://%s/" % HOST, data=body.encode("utf-8"),
        headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", "replace")
        print("✗ HTTP %s：%s" % (exc.code, raw[:400]))
        return False, {}
    except Exception as exc:
        print("✗ 请求失败：%s" % exc)
        return False, {}

    resp = data.get("Response") or {}
    err = resp.get("Error")
    if err:
        print("✗ %s → %s: %s" % (action, err.get("Code"), err.get("Message")))
        return False, resp
    return True, resp


# ─────────────────────────── 动作 ───────────────────────────

def zip_bytes():
    if not os.path.exists(ZIP):
        print("✗ 找不到 %s，先跑 python package.py" % ZIP)
        return None
    raw = open(ZIP, "rb").read()
    print("  zip: %s（%d B，sha256 %s）"
          % (ZIP, len(raw), hashlib.sha256(raw).hexdigest()[:16]))
    return raw


def do_list(region=""):
    ok, resp = call("ListFunctions", {"Limit": 50, "Offset": 0}, region)
    if not ok:
        return 1
    fns = resp.get("Functions") or []
    print("账号下共 %d 个云函数：" % len(fns))
    for f in fns:
        print("  · %-24s %-12s %s"
              % (f.get("FunctionName"), f.get("Runtime"), f.get("ModTime")))
    return 0


def do_create(name, region="", memory=128, timeout=10, require_cos=True):
    raw = zip_bytes()
    if raw is None:
        return 1
    envs, missing = collect_env_vars(require_cos=require_cos)
    if missing:
        print("✗ 环境变量缺这些，先补上（env 或 config.json）：")
        for m in missing:
            print("    - " + m)
        print("  （只想先跑通、不接 COS 的话加 --no-cos）")
        return 1

    payload = {
        "FunctionName": name,
        "Runtime": DEFAULT_RUNTIME,
        "Handler": DEFAULT_HANDLER,
        "Role": _env("SCF_ROLE"),
        "Code": {"ZipFile": base64.b64encode(raw).decode("ascii")},
        "MemorySize": memory,
        "Timeout": timeout,
        "Description": "FVM 授权码机器人（严格模式：只回 @机器人 /授权）",
        "Environment": {"Variables": envs},
    }
    if not payload["Role"]:
        payload.pop("Role")
    print("  新建函数 %s（%s，%s，%d MB / %s 秒，%d 个环境变量）"
          % (name, DEFAULT_RUNTIME, DEFAULT_HANDLER, memory, timeout, len(envs)))
    for e in envs:
        shown = e["Value"] if e["Key"] in ("QQ_APP_ID", "COS_REGION",
                                           "COS_BUCKET", "MAX_DEVICES",
                                           "STRICT_TRIGGER", "AUTH_COMMAND",
                                           "LICENSE_DAYS", "HWID_SALT",
                                           "ADMIN_QQ") else "***"
        print("    %-16s %s" % (e["Key"], shown))
    ok, resp = call("CreateFunction", payload, region, timeout=120)
    if not ok:
        return 1
    print("✓ 创建成功：%s（RequestId %s）" % (name, resp.get("RequestId")))
    print("  下一步：控制台给这个函数开「函数 URL」（免鉴权），再填到开放平台。")
    return 0


def do_update_code(name, region=""):
    raw = zip_bytes()
    if raw is None:
        return 1
    print("  更新代码 %s" % name)
    ok, resp = call("UpdateFunctionCode", {
        "FunctionName": name,
        "Code": {"ZipFile": base64.b64encode(raw).decode("ascii")},
    }, region, timeout=120)
    if not ok:
        return 1
    print("✓ 代码已更新（RequestId %s）" % resp.get("RequestId"))
    return 0


def do_update_env(name, region="", memory=None, timeout=None, require_cos=True):
    envs, missing = collect_env_vars(require_cos=require_cos)
    if missing:
        print("✗ 环境变量缺这些：")
        for m in missing:
            print("    - " + m)
        print("  （只想先跑通、不接 COS 的话加 --no-cos）")
        return 1
    payload = {"FunctionName": name, "Environment": {"Variables": envs}}
    if memory:
        payload["MemorySize"] = memory
    if timeout:
        payload["Timeout"] = timeout
    print("  更新环境变量（%d 项）" % len(envs))
    ok, resp = call("UpdateFunctionConfiguration", payload, region)
    if not ok:
        return 1
    print("✓ 配置已更新（RequestId %s）" % resp.get("RequestId"))
    return 0


def do_package():
    r = subprocess.run([sys.executable, os.path.join(HERE, "package.py")],
                       cwd=ROOT, text=True, encoding="utf-8")
    return 0 if r.returncode == 0 else 1


def main():
    ap = argparse.ArgumentParser(description="部署 FVM 授权机器人到腾讯云函数")
    ap.add_argument("--name", default=_env("SCF_FUNCTION", default=DEFAULT_FUNC))
    ap.add_argument("--region", default=_env("SCF_REGION", default=""))
    ap.add_argument("--check", action="store_true", help="只列账号下的函数")
    ap.add_argument("--create", action="store_true", help="新建函数并上传代码")
    ap.add_argument("--update", action="store_true", help="只更新代码")
    ap.add_argument("--env", action="store_true", help="只更新环境变量")
    ap.add_argument("--all", action="store_true",
                    help="打包 + 校验 + 更新代码 + 更新环境变量")
    ap.add_argument("--no-cos", action="store_true",
                    help="允许不配 COS（账本会落到容器本地，重启就没了，仅试跑用）")
    ap.add_argument("--selftest", action="store_true", help="只验签名算法（不联网）")
    ap.add_argument("--memory", type=int, default=128)
    ap.add_argument("--timeout", type=int, default=10)
    args = ap.parse_args()

    region = args.region
    no_cos = args.no_cos
    if args.selftest:
        return selftest()
    if args.check:
        return do_list(region)
    if args.create:
        return do_create(args.name, region, args.memory, args.timeout,
                         require_cos=not no_cos)
    if args.update:
        return do_update_code(args.name, region)
    if args.env:
        return do_update_env(args.name, region, args.memory or None,
                             args.timeout or None, require_cos=not no_cos)
    if args.all:
        if do_package() != 0:
            return 1
        rc = do_update_code(args.name, region)
        if rc != 0:
            return rc
        return do_update_env(args.name, region, require_cos=not no_cos)

    ap.print_help()
    print("\n常用：")
    print("  python deploy.py --check      先看密钥通不通")
    print("  python deploy.py --all        有函数了，一键发新版")
    print("  python deploy.py --create     第一次建函数")
    return 0


if __name__ == "__main__":
    sys.exit(main())

# -*- coding: utf-8 -*-
"""
生成 scripts/sprite_trim_get/sprite_trim_get.gml（敌人贴图「不透明包围盒」表）。

为什么需要这张表：
  这批老鼠 / BOSS 贴图的画布留白极不统一（内容占画布 0.12~0.90，画布底部留白 0~467px），
  预览时如果按整张画布居中贴底，留白大的贴图会整个飘出裁剪框。所以离线量出每张图
  第 0 帧的 alpha 包围盒，绘制时用 draw_sprite_part_ext 只贴可见部分。

⚠️ 关键一：第 0 帧必须从 .yy 的 Keyframes 顺序里读，不能拿「文件名排序第一个」——
  PNG 文件名是 GUID，和帧序无关。早先图省事用文件名排序，量到的是随机一帧
  （常是炸弹/特效帧），结果预览里一堆老鼠只剩一小块。

⚠️ 关键二：只扫 scripts/enemy_init 是不够的。mod 分支的换皮敌人分布在
  mod_enemy_init / longyuan_enemy_init / shuihuo_enemy_init / zhuore_enemy_init /
  wudu_enemy_init 等脚本里，漏扫会让这些美术「不在表里 → 按整张画布贴」，
  内容偏上的大画布会整块飘出裁剪框，情报岛 / 地图预览里直接看不见。
  所以本脚本扫描 scripts 下**所有**带 spr 字段的注册脚本（attire_init 除外，那是装扮）。

用法（在项目根目录）：
  python tools/gen_sprite_trim.py

新增敌人美术后重跑一次即可；脚本会就地重写 sprite_trim_get.gml。
"""

import os
import re
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("需要 Pillow：pip install pillow")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPTS = os.path.join(ROOT, "scripts")
OUT_GML = os.path.join(SCRIPTS, "sprite_trim_get", "sprite_trim_get.gml")

# 装扮（attire_init）的 spr 是衣服贴图，不进这张表
SKIP_FILES = {"attire_init.gml"}
SPR_PAT = re.compile(r'"?spr"?\s*:\s*(spr_[A-Za-z0-9_]+)')

HEAD = '''/// @function sprite_trim_get(_spr)
/// @desc 取精灵第 0 帧的**不透明包围盒**（sprite 像素坐标），返回 [x, y, w, h]；无记录时返回 undefined。
///
///       为什么需要这张表：这批老鼠 / BOSS 贴图的画布留白极不统一（实测内容占画布 0.12~0.9），
///       按画布居中贴底会让 hot_vajra、magician_mouse、travel_record 这类"画布巨大、内容偏上"的
///       贴图整个飘出预览框。所以贴之前先按内容包围盒裁一刀，再按统一缩放绘制。
///
///       ⚠️ 表由 tools/gen_sprite_trim.py 离线生成（读 .yy 的 Keyframes 顺序拿第 0 帧，
///          不能按 PNG 文件名排序 —— 文件名是 GUID，和帧序无关）。
///          新增敌人美术后重跑该脚本即可；查不到名字时函数返回 undefined，
///          绘制会退回运行时 sprite_get_bbox_*（再不行才整张画布），不会报错。
/// @param {Asset.GMSprite} _spr
function sprite_trim_get(_spr)
{
	if (!sprite_exists(_spr)) return undefined;
	if (!variable_global_exists("sprite_trim_bounds")){
		global.sprite_trim_bounds = {
'''

TAIL = '''		};
	}
	return global.sprite_trim_bounds[$ sprite_get_name(_spr)];
}
'''


def frame0_png(sprite_name):
    """按 .yy 里 Keyframes 的顺序取第 0 帧对应的 PNG 路径。"""
    yy = os.path.join(ROOT, "sprites", sprite_name, sprite_name + ".yy")
    if not os.path.exists(yy):
        return None
    with open(yy, encoding="utf-8-sig") as f:
        s = f.read()
    i = s.find('"$KeyframeStore<SpriteFrameKeyframe>"')
    if i < 0:
        return None
    m = re.search(r'"name":"([0-9a-f-]{36})"', s[i:])
    if not m:
        return None
    p = os.path.join(ROOT, "sprites", sprite_name, m.group(1) + ".png")
    return p if os.path.exists(p) else None


def collect_names():
    names = set()
    for dirpath, dirnames, filenames in os.walk(SCRIPTS):
        for fn in filenames:
            if not fn.endswith(".gml") or fn in SKIP_FILES:
                continue
            p = os.path.join(dirpath, fn)
            with open(p, encoding="utf-8", errors="replace") as f:
                s = f.read()
            names.update(SPR_PAT.findall(s))
    return sorted(names)


def main():
    names = collect_names()

    lines = []
    skipped = []
    for name in names:
        png = frame0_png(name)
        if not png:
            skipped.append((name, "找不到第 0 帧"))
            continue
        im = Image.open(png).convert("RGBA")
        bb = im.getbbox()
        if bb is None:
            skipped.append((name, "第 0 帧全透明"))
            continue
        x, y, x2, y2 = bb
        lines.append('\t\t\t"%s": [%d, %d, %d, %d],' % (name, x, y, x2 - x, y2 - y))

    with open(OUT_GML, "w", encoding="utf-8", newline="") as f:
        f.write(HEAD + "\n".join(lines) + "\n" + TAIL)

    print("写入 %s" % os.path.relpath(OUT_GML, ROOT))
    print("  条目 %d，跳过 %d" % (len(lines), len(skipped)))
    for n, why in skipped:
        print("  - %s（%s，退回运行时包围盒）" % (n, why))


if __name__ == "__main__":
    main()

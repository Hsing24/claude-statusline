#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""貼上任何符號，印出它的 codepoint 與 Nerd Font glyph 名稱。
用法： python3 ~/.claude/glyph-id.py        （然後貼上符號按 Enter）
       python3 ~/.claude/glyph-id.py '符號'  （直接當參數傳）"""
import sys, json, os
# 先找腳本同目錄，再退回 ~/.claude
CAND = [os.path.join(os.path.dirname(os.path.abspath(__file__)), "nerdfont-glyphnames.json"),
        os.path.expanduser("~/.claude/.nerdfont-glyphnames.json")]
names = {}
for DB in CAND:
    if os.path.exists(DB):
        names = {cp: n for n, cp in json.load(open(DB)).items()}
        break

s = sys.argv[1] if len(sys.argv) > 1 else input("貼上符號後按 Enter： ")
if not s.strip():
    print("沒有輸入"); sys.exit(0)
print()
for ch in s:
    if ch in ' \t\n': continue
    cp = ord(ch)
    nm = names.get(cp, "(此字型沒有這個字，或不是 Nerd Font 圖示)")
    print(f"  {ch}   U+{cp:04X}   {nm}")
print()
print("  把上面的 U+XXXX 貼給 Claude 就行。")

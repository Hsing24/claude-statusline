#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""statusline.sh 的 icon / 符號選單 —— 預覽色與 statusline.sh 目前設定同步"""

# 與 statusline.sh §1 同步
BG = {'dir':'#464B71','git':'#3368A0','diff':'#66A3BF','model':'#C8DFDB','clock':'#F2EFE7',
      'time':'#FBC02D','ctx':'#F9F7F7','tok':'#DBE2EF','cache':'#3F72AF','cost':'#00B7CD',
      'h5':'#3FE0C5','wk':'#FFD166','fb':'#E03C31'}
FG = {'dir':'#E6F1FF','git':'#E6F1FF','diff':'#0A1A2F','model':'#0A1A2F','clock':'#0A1A2F',
      'time':'#0A1A2F','ctx':'#0A1A2F','tok':'#0A1A2F','cache':'#E6F1FF','cost':'#0A1A2F',
      'h5':'#0A1A2F','wk':'#0A1A2F','fb':'#0A1A2F'}
BAR_FILL = '#0A1A2F'
EMPTY_MIX = 40

def c(h, bgc=False):
    h = h.lstrip('#'); r,g,b = (int(h[i:i+2],16) for i in (0,2,4))
    return f"\033[{48 if bgc else 38};2;{r};{g};{b}m"
def mix(bg, fg, pct):
    b=[int(bg.lstrip('#')[i:i+2],16) for i in (0,2,4)]
    f=[int(fg.lstrip('#')[i:i+2],16) for i in (0,2,4)]
    return '#%02X%02X%02X'%tuple((b[i]*(100-pct)+f[i]*pct)//100 for i in range(3))
R = "\033[0m"

def bar(key, width=8, filled=5):
    bg = BG[key]; empty = mix(bg, BAR_FILL, EMPTY_MIX)
    s = c(bg, True) + c(BAR_FILL)
    for i in range(width):
        if i == filled: s += c(empty)
        s += chr(0x25B0) if i < filled else chr(0x25B1)
    return s

# ── A：整行頭尾圓弧 + 段間分隔符 ──────────────────────────────
CAPS = [
    ("圓弧頭尾 + 尖角分隔（目前設定）", 0xE0B6, 0xE0B4, 0xE0B0),
    ("圓弧頭尾 + 細線分隔",             0xE0B6, 0xE0B4, 0xE0B1),
    ("圓框線頭尾 + 尖角分隔",           0xE0B7, 0xE0B5, 0xE0B0),
    ("尖角頭尾 + 尖角分隔",             0xE0B2, 0xE0B0, 0xE0B0),
    ("斜切頭尾 + 斜切分隔",             0xE0BA, 0xE0B8, 0xE0B8),
    ("火焰頭尾 + 火焰分隔",             0xE0C2, 0xE0C0, 0xE0C0),
    ("像素化頭尾 + 像素分隔",           0xE0C6, 0xE0C4, 0xE0C4),
    ("無頭尾 + 尖角分隔",               None,   None,   0xE0B0),
]

ICONS = {
    'B  當前目錄': ('dir', [
        (0xF07C,'folder 開啟（目前）'),(0xF07B,'folder 實心'),(0xF114,'folder 線框'),
        (0xF115,'folder 開啟線框'),(0xF413,'octicon 目錄'),(0xE5FF,'seti 目錄'),
        (0xEA83,'codicon 目錄'),(0xF4D4,'octicon 檔案樹')]),
    'C  git 分支': ('git', [
        (0xF418,'octicon git-branch（目前）'),(0xE0A0,'powerline 分支'),
        (0xEA68,'codicon git-branch'),(0xF126,'code-fork'),
        (0xE725,'devicon 分支'),(0xF417,'octicon commit'),(0xF062C,'mdi source-branch')]),
    'D  model': ('model', [
        (0xF06A9,'mdi robot 實心（目前）'),(0xF167A,'md-robot_outline'),(0xEE0D,'fa-robot'),
        (0xF09D1,'md-brain 大腦'),(0xF085,'cogs 齒輪'),(0xE26E,'devicon')]),
    'I  effort — CPU / 晶片': ('model', [
        (0xF2DB,'fa-microchip（目前）'),(0xF4BC,'oct-cpu'),(0xF0EE0,'md-cpu_64_bit'),
        (0xF0EDF,'md-cpu_32_bit'),(0xF061A,'md-chip'),(0xEC19,'cod-chip'),
        (0xE266,'fae-chip'),(0xF1913,'md-integrated_circuit_chip'),
        (0xEABE,'cod-circuit_board'),(0xEFC5,'fa-memory'),(0xF035B,'md-memory')]),
    'L  effort — 大腦': ('model', [
        (0xEE9C,'fa-brain'),(0xF09D1,'md-brain'),(0xE28C,'fae-brain')]),
    'E  session clock': ('clock', [
        (0xF251,'沙漏起始（動態階段1）'),(0xF252,'沙漏過半（階段2）'),(0xF253,'沙漏將盡（階段3）'),
        (0xF254,'hourglass 滿'),(0xF250,'hourglass 空框'),(0xF0B0,'filter 漏斗'),
        (0xF1DA,'history 歷程')]),
    'F  系統時間': ('time', [
        (0xF017,'clock 線框（目前）'),(0xF43A,'octicon clock'),(0xEA82,'codicon watch'),
        (0xF0954,'mdi clock 實心'),(0xE641,'devicon')]),
    'G  context': ('ctx', [
        (0xF0F6,'file-text 線框（目前）'),(0xF15C,'file-text 實心'),(0xF016,'file 空白'),
        (0xEA7B,'codicon file'),(0xF02D,'book 書'),(0xF4A5,'octicon'),(0xF0E4,'gauge 儀表板')]),
    'H  token': ('tok', [
        (0xF1C0,'database 資料庫（目前）'),(0xF1B3,'cubes'),(0xF1B2,'cube'),
        (0xF51E,'coins'),(0xF0D6,'money'),(0xF084,'key'),(0xF0A3,'certificate'),
        (0xF2DB,'microchip'),(0xF201,'pulse'),(0xF187,'archive'),(0xEB44,'codicon 數字')]),
    'J  警示：注意': ('wk', [
        (0xF071,'warning 三角（目前）'),(0xF06A,'exclamation 圓'),(0xF0026,'mdi alert'),
        (0xF0F3,'bell 鈴鐺'),(0xF12A,'exclamation 粗')]),
    'K  警示：危險': ('fb', [
        (0xF06D,'fire 火焰（目前）'),(0xF071,'warning 三角'),(0xF057,'times 圓'),
        (0xF0E7,'bolt 閃電'),(0xF1E2,'bomb 炸彈')]),
}

print()
print("\033[1m  A  整行頭尾 + 段間分隔符\033[0m")
print()
for i,(name,l,r,sep) in enumerate(CAPS,1):
    line = ""
    if l is not None:
        line += R + c(BG['h5']) + chr(l)
    line += c(BG['h5'],True) + c(FG['h5']) + " 5h " + bar('h5') + c(BG['h5'],True) + c(FG['h5']) + " 71% "
    line += c(BG['h5']) + c(BG['wk'],True) + chr(sep)
    line += c(FG['wk']) + " W " + bar('wk',8,2) + c(BG['wk'],True) + c(FG['wk']) + " 30% "
    if r is not None:
        line += R + c(BG['wk']) + chr(r)
    line += R
    cp = f"U+{l:04X} U+{r:04X} / U+{sep:04X}" if l else f"(無) / U+{sep:04X}"
    print(f"  A{i}  {line}")
    print(f"      {name:<30} {cp}")
print()

for title,(key,items) in ICONS.items():
    letter = title.split()[0]
    print(f"\033[1m  {title}\033[0m")
    for i,(cp,desc) in enumerate(items,1):
        print(f"    {c(BG[key],True)}{c(FG[key])} {chr(cp)} {R}  {letter}{i:<3} {desc:<26} U+{cp:04X}")
    print()

print("  用代號回覆即可，例如：A1 B1 C1 D1 I2 E2 F1 G1 H1 J1 K1（L 組是 I 組的大腦替代方案，擇一即可）")
print()

#!/usr/bin/env bash
# =============================================================================
#  Claude Code statusline  ·  powerline / truecolor / Nerd Font
#  由原本的 ccstatusline settings.json 轉寫而成
#
#  預覽（不用改設定就能看效果）：
#      bash ~/.claude/statusline.sh --demo
#
#  正式啟用：把 ~/.claude/settings.json 的 statusLine 改成
#      "statusLine": { "type": "command",
#                      "command": "bash $HOME/.claude/statusline.sh",   # 請填絕對路徑
#                      "padding": 0, "refreshInterval": 1 }
#
#  ── 想調什麼看這裡 ──────────────────────────────────────────────
#   §1 調色盤   每一段的背景色 / 前景色（改這裡就好）
#   §2 圖示     Nerd Font glyph 與進度條字元
#   §3 開關     顯示選項（反轉百分比、進度條寬度、快取秒數…）
#   §4 版面     三行分別由哪些段組成（想搬動順序改這裡）
# =============================================================================

set -u

# =============================================================================
# §1  調色盤 —— 每段一組 BG（背景）/ FG（前景），24-bit hex
# =============================================================================

# ── 第一行：工作環境 ──────────────────────────────────────────────
C_CWD_BG="#526D82";     C_CWD_FG="#FFFFFF"   # 檔案路徑（左漸層 起點：石板藍）
C_GIT_BG="#27374D";     C_GIT_FG="#E6F1FF"   # 分支（左漸層：深靛藍）
C_DIFF_BG="#162536";    C_DIFF_FG="#E6F1FF"  # git diff（錨點：深藍灰，綠紅可讀的最亮深底）
C_DIFF_ADD_FG="#3FE0C5"  #  新增行數（綠）
C_DIFF_DEL_FG="#E66259"  #  刪除行數（紅）
C_MODEL_BG="#27467C";   C_MODEL_FG="#E6F1FF" # model + effort（右漸層 起點：深藍）
C_CLOCK_BG="#5996C5";   C_CLOCK_FG="#0A1A2F" # session 已用時間（右漸層：中藍）
C_TIME_BG="#C1DEEB";    C_TIME_FG="#0A1A2F"  # 系統時鐘（右漸層 終點：淺藍）

# ── 第二行：context 與 token ─────────────────────────────────────
C_CTX_BG="#E8F5E9";     C_CTX_FG="#0A1A2F"   # context 進度條
C_TOK_BG="#A5D6A7";     C_TOK_FG="#0A1A2F"   # input + output + total
C_CACHE_BG="#66BB6A";   C_CACHE_FG="#0A1A2F" # cached token
C_COST_BG="#1B5E20";    C_COST_FG="#E6F1FF"  # 本次 session 花費

# ── 第三行：用量額度 ─────────────────────────────────────────────
C_5H_BG="#3FE0C5";       C_5H_FG="#0A1A2F"    # 5 小時額度
C_WK_BG="#FFD166";       C_WK_FG="#0A1A2F"    # 每週額度
C_FB_BG="#E03C31";       C_FB_FG="#0A1A2F"    # Fable 每週額度

# ── 進度條顏色 ───────────────────────────────────────────────────
#    注意：數字百分比一定會一起顯示，不會只靠顏色傳達狀態
C_LV_OK="#3FE0C5"        # 安全  （< WARN_AT）
C_LV_WARN="#FFD166"      # 注意  （>= WARN_AT）
C_LV_CRIT="#E66259"      # 危險  （>= CRIT_AT）
C_BAR_EMPTY=""           # 未填滿的顏色；留空 = 由藥丸底色混入條色自動推導
C_BAR_FILL="#0A1A2F"     # 進度條顏色（固定）；留空 = 改用下面 C_LV_* 動態三色
C_BAR_TRACK=""           # 進度條軌道底色；留空 = 直接畫在藥丸底色上

# =============================================================================
# §2  圖示與字元（需要 Nerd Font；不喜歡可以直接換成空字串或別的字）
# =============================================================================
SEP_SOLID=""            # 段與段之間的箭頭 (U+E0B0)
PILL_CAP_L=""           # 整行左端圓弧 (U+E0B6)
PILL_CAP_R=""           # 整行右端圓弧 (U+E0B4)

SEP_THIN=""             # 合併段之間的細箭頭   (U+E0B1)
SEP_THIN_FG=""           # 同組細分隔線顏色；留空 = 由該段文字色與底色自動混出

I_DIR=""                # 目錄
I_GIT=""                # git 分支 (U+E0A0)
# 進度條狀態符號（不受底色影響，色覺障礙者也能辨識）
I_WARN=""               # 注意：三角 (U+F071)
I_CRIT=""               # 危險：octicon flame (U+F490)
# git 分支狀態符號
I_GIT_STAGED="+"          # 有檔案已加入暫存
I_GIT_DIRTY="!"           # 有檔案已修改但未暫存
I_GIT_UNTRACKED="?"       # 有未追蹤的新檔案
I_GIT_AHEAD=""          # 領先 upstream (U+F062)
I_GIT_BEHIND=""         # 落後 upstream (U+F063)
I_ADD="+"                # 新增行數
I_DEL="-"                # 刪除行數
I_MODEL="󰚩"              # 模型
I_EFFORT="󰍛"               # thinking effort（md-memory U+F035B）
I_CLOCK=""              # session 已用時間（I_CLOCK_DYNAMIC=0 時使用）
# 沙漏三階段：隨 session 時間由「沙在上」流到「沙在下」
I_CLOCK_1=""            # 起始 (U+F251 hourglass-start)
I_CLOCK_2=""            # 過半 (U+F252 hourglass-half)
I_CLOCK_3=""            # 將盡 (U+F253 hourglass-end)
I_TIME=""               # 系統時鐘
I_CTX=""                # context 用量
I_IN="↑"                 # input token
I_OUT="↓"                # output token
I_TOTAL=""              # total token
I_CACHE=""              # cached token
I_COST=""               # 花費
I_5H=""                 # 5 小時額度
I_WEEK=""               # 每週額度
I_FABLE=""                # Fable（fae-crown U+E26E）

BAR_FULL="▰"             # 進度條已填滿
BAR_EMPTY="▱"            # 進度條未填滿
BAR_CAP_L=""             # 進度條左膠囊頭；留空 = 不加
BAR_CAP_R=""             # 進度條右膠囊尾；留空 = 不加

# =============================================================================
# §3  顯示開關
# =============================================================================
BAR_W_CTX=10             # context 進度條寬度
BAR_W_QUOTA=8            # 額度進度條寬度
BAR_EMPTY_MIX=40         # C_BAR_EMPTY 留空時，未填色 = 藥丸底色混入條色的百分比
SEP_THIN_MIX=55          # SEP_THIN_FG 留空時，分隔線 = 藥丸底色混入文字色的百分比


WARN_AT=60               # 幾 % 開始轉黃
CRIT_AT=85               # 幾 % 開始轉紅

# 額度顯示「剩餘」還是「已用」。1 = 顯示剩餘（原本 ccstatusline 的 invert:true）
INVERT_5H=0
INVERT_WEEK=0
INVERT_FABLE=0

ABBREV_HOME=1            # 1 = 把 $HOME 縮寫成 ~
CWD_MAX_SEG=0            # 0 = 顯示完整路徑；設 N 只顯示最後 N 層

# 在這個資料夾底下時，只顯示它之後的相對路徑
#   ~/Desktop/project/claude-statusline    -> claude-statusline
#   ~/Desktop/project/foo/src/api          -> foo/src/api
#   其他不在它底下的路徑                   -> 照常顯示完整路徑
# 留空字串則停用此功能。
CWD_PROJECT_ROOT="project"

# session 時鐘的沙漏是否隨時間變化（1 = 三階段動態；0 = 固定用 I_CLOCK）
I_CLOCK_DYNAMIC=1
I_CLOCK_WINDOW_H=5       # 幾小時算「一整個沙漏」流完

GIT_CACHE_TTL=5          # git 資訊快取秒數（避免每秒都跑 git）

# Fable 用量的資料來源。stdin 沒有這個欄位，只能靠 API 快取檔。
#   0 = 只讀 ccstatusline already 寫好的快取（不碰鑰匙圈、不連網）
#   1 = 自己去 api.anthropic.com 抓（會讀 Keychain 的 OAuth token + 連外網）
FABLE_SELF_REFRESH=1
FABLE_CACHE="$HOME/.cache/claude-statusline/fable.json"       # 自更新寫這裡（本腳本專用）
FABLE_CACHE_RO="$HOME/.cache/ccstatusline/usage.json"         # 備援：ccstatusline 的快取（唯讀）
FABLE_TTL=180            # 快取多久算過期（秒）
FABLE_LOCK_MAX_AGE=30    # 抓取進行中的鎖定最長有效秒數，避免掛掉後永久卡住

# =============================================================================
#  以下是實作，一般情況不用動
# =============================================================================

NOW=$(date +%s)
OUT=""

put_fg() { local h=${1#\#}; OUT="$OUT"$'\033[38;2;'"$((16#${h:0:2}));$((16#${h:2:2}));$((16#${h:4:2}))m"; }
put_bg() { local h=${1#\#}; OUT="$OUT"$'\033[48;2;'"$((16#${h:0:2}));$((16#${h:2:2}));$((16#${h:4:2}))m"; }
put()    { OUT="$OUT$1"; }

# ── 段落緩衝區 ──────────────────────────────────────────────────
US=$'\037'
SEG_N=0
SEGS=""
seg() {  # seg <bg> <fg> <text> [merge:0|1]
  [ -z "${3:-}" ] && return
  SEGS="$SEGS$1$US$2$US$3$US${4:-0}"$'\n'
  SEG_N=$((SEG_N + 1))
}

flush() {
  # 整行黏成一條連續膠囊：行首／行尾各一個圓弧，
  # 段與段之間用箭頭；同一組（merge=1）之間用細線。
  [ "$SEG_N" -eq 0 ] && { SEGS=""; return; }
  local first=1 prev_bg="" bg fg txt mg _sf
  OUT=""
  while IFS="$US" read -r bg fg txt mg; do
    [ -z "$bg" ] && continue
    if [ "$first" = "1" ]; then
      put $'\033[0m'; put_fg "$bg"; put "$PILL_CAP_L"
      first=0
    elif [ "$mg" = "1" ]; then
      _sf="$SEP_THIN_FG"
      if [ -z "$_sf" ]; then blend "$bg" "$fg" "$SEP_THIN_MIX"; _sf="$BLENDOUT"; fi
      put_fg "$_sf"; put_bg "$bg"; put "$SEP_THIN"
    else
      put_fg "$prev_bg"; put_bg "$bg"; put "$SEP_SOLID"
    fi
    put_fg "$fg"; put_bg "$bg"; put " $txt "
    prev_bg="$bg"
  done <<EOF
$SEGS
EOF
  put $'\033[0m'; put_fg "$prev_bg"; put "$PILL_CAP_R"; put $'\033[0m'
  printf '%s\n' "$OUT"
  SEGS=""; SEG_N=0
}

# ── 小工具 ──────────────────────────────────────────────────────
fmt_num() {  # 1234567 -> 1.2M
  local v=${1:-0} m
  case "$v" in ''|*[!0-9]*) NUMOUT="0"; return;; esac
  if [ "$v" -ge 1000000 ]; then m=$((v / 100000)); NUMOUT="$((m / 10)).$((m % 10))M"
  elif [ "$v" -ge 1000 ]; then m=$((v / 100));    NUMOUT="$((m / 10)).$((m % 10))k"
  else NUMOUT="$v"; fi
}

lvl_mark() {  # 依百分比給警示符號（安全狀態為空字串）
  local p=${1:-0}
  if   [ "$p" -ge "$CRIT_AT" ]; then MARKOUT=" $I_CRIT"
  elif [ "$p" -ge "$WARN_AT" ]; then MARKOUT=" $I_WARN"
  else MARKOUT=""
  fi
}

# stat 在 BSD(macOS) 與 GNU(Linux) 參數不同，載入時偵測一次
if stat -f %m . >/dev/null 2>&1; then
  mtime() { stat -f %m "$1" 2>/dev/null || echo 0; }
else
  mtime() { stat -c %Y "$1" 2>/dev/null || echo 0; }
fi

blend() {  # blend <底色> <前景色> <百分比> -> BLENDOUT
  local a=${1#\#} b=${2#\#} pc=$3 r g bl
  r=$(( (16#${a:0:2} * (100 - pc) + 16#${b:0:2} * pc) / 100 ))
  g=$(( (16#${a:2:2} * (100 - pc) + 16#${b:2:2} * pc) / 100 ))
  bl=$(( (16#${a:4:2} * (100 - pc) + 16#${b:4:2} * pc) / 100 ))
  printf -v BLENDOUT '#%02X%02X%02X' "$r" "$g" "$bl"
}

lvl_color() {  # 依百分比挑顏色
  local p=${1:-0}
  if   [ "$p" -ge "$CRIT_AT" ]; then LVLC="$C_LV_CRIT"
  elif [ "$p" -ge "$WARN_AT" ]; then LVLC="$C_LV_WARN"
  else LVLC="$C_LV_OK"; fi
}

bar() {  # bar <長度%> <寬度> <底色> [警戒色依據%；預設同長度%]
  local p=${1:-0} w=${2:-8} sbg=$3 cp=${4:-${1:-0}} filled i trk fillc emptyc
  [ "$p" -lt 0 ] && p=0; [ "$p" -gt 100 ] && p=100
  filled=$((p * w / 100))
  lvl_color "$cp"
  fillc="${C_BAR_FILL:-$LVLC}"          # 有設固定色就用固定色，否則用動態三色
  trk="${C_BAR_TRACK:-$sbg}"
  emptyc="$C_BAR_EMPTY"
  if [ -z "$emptyc" ]; then blend "$trk" "$fillc" "$BAR_EMPTY_MIX"; emptyc="$BLENDOUT"; fi
  local save="$OUT"; OUT=""
  [ -n "$BAR_CAP_L" ] && { put_bg "$sbg"; put_fg "$trk"; put "$BAR_CAP_L"; }
  put_bg "$trk"; put_fg "$fillc"
  i=0
  while [ "$i" -lt "$w" ]; do
    [ "$i" -eq "$filled" ] && { put_fg "$emptyc"; }
    if [ "$i" -lt "$filled" ]; then put "$BAR_FULL"; else put "$BAR_EMPTY"; fi
    i=$((i + 1))
  done
  [ -n "$BAR_CAP_R" ] && { put_bg "$sbg"; put_fg "$trk"; put "$BAR_CAP_R"; }
  BAROUT="$OUT"; OUT="$save"
}

fmt_dur() {  # ms -> H:MM:SS
  local t=$((${1:-0} / 1000))
  DUROUT=$(printf '%d:%02d:%02d' $((t / 3600)) $((t % 3600 / 60)) $((t % 60)))
}

fmt_left() {  # epoch -> 還剩多久
  local d=$((${1:-0} - NOW)) h m
  [ "$d" -lt 0 ] && d=0
  h=$((d / 3600)); m=$((d % 3600 / 60))
  local dd=$((h / 24)); h=$((h % 24))
  if   [ "$dd" -gt 0 ]; then LEFTOUT="${dd}d${h}h${m}m"
  elif [ "$h"  -gt 0 ]; then LEFTOUT="${h}h${m}m"
  else                       LEFTOUT="${m}m"
  fi
}

style() {  # style <fg> <bg> -> STYLEOUT（把顏色狀態接回段落底色，供條後面的文字用）
  local save="$OUT"; OUT=""
  put_bg "$2"; put_fg "$1"
  STYLEOUT="$OUT"; OUT="$save"
}

# ── 讀 stdin ────────────────────────────────────────────────────
if [ "${1:-}" = "--demo" ]; then
  RAW='{"workspace":{"current_dir":"'"$PWD"'"},"cwd":"'"$PWD"'",
   "model":{"display_name":"Opus 5 (1M)"},"effort":{"level":"xhigh"},
   "context_window":{"used_percentage":62.4,"total_input_tokens":1234567,
     "total_output_tokens":45678,"current_usage":{"cache_read_input_tokens":98765,
     "cache_creation_input_tokens":4321}},
   "rate_limits":{"five_hour":{"used_percentage":29,"resets_at":'"$((NOW + 7500))"'},
     "seven_day":{"used_percentage":70,"resets_at":'"$((NOW + 180000))"'}},
   "cost":{"total_cost_usd":1.2345,"total_duration_ms":5432100}}'
else
  RAW=$(cat)
fi
[ -z "$RAW" ] && exit 0

eval "$(printf '%s' "$RAW" | jq -r '
  def cu: (.context_window.current_usage // {}) | if type=="object" then . else {} end;
  @sh "D_CWD=\(.workspace.current_dir // .cwd // "")",
  @sh "D_MODEL=\(if (.model|type)=="string" then .model else (.model.display_name // .model.id // "") end)",
  @sh "D_EFFORT=\(.effort.level // "")",
  @sh "D_CTX=\((.context_window.used_percentage // 0) | round)",
  @sh "D_IN=\((.context_window.total_input_tokens // 0) | floor)",
  @sh "D_OUT=\((.context_window.total_output_tokens // 0) | floor)",
  @sh "D_CR=\((cu.cache_read_input_tokens // 0) | floor)",
  @sh "D_CW=\((cu.cache_creation_input_tokens // 0) | floor)",
  @sh "D_CENTS=\(((.cost.total_cost_usd // 0) * 100) | floor)",
  @sh "D_DUR=\((.cost.total_duration_ms // 0) | floor)",
  @sh "D_H5=\(if .rate_limits.five_hour.used_percentage == null then -1 else (.rate_limits.five_hour.used_percentage | round) end)",
  @sh "D_H5R=\((.rate_limits.five_hour.resets_at // 0) | floor)",
  @sh "D_WK=\(if .rate_limits.seven_day.used_percentage == null then -1 else (.rate_limits.seven_day.used_percentage | round) end)",
  @sh "D_WKR=\((.rate_limits.seven_day.resets_at // 0) | floor)"
' 2>/dev/null)"

: "${D_CWD:=$PWD}" "${D_MODEL:=}" "${D_EFFORT:=}" "${D_CTX:=0}" "${D_IN:=0}" "${D_OUT:=0}"
: "${D_CR:=0}" "${D_CW:=0}" "${D_CENTS:=0}" "${D_DUR:=0}"
: "${D_H5:=-1}" "${D_H5R:=0}" "${D_WK:=-1}" "${D_WKR:=0}"

# ── Fable 用量（stdin 沒有，只能讀快取／自己抓）──────────────────
D_FB=-1; D_FBR=0
if [ "$FABLE_SELF_REFRESH" = "1" ]; then
  _lock="$FABLE_CACHE.lock"
  _age=$(( NOW - $(mtime "$FABLE_CACHE") ))
  _lage=$(( NOW - $(mtime "$_lock") ))
  # 快取過期（或還沒有），而且沒有其他抓取正在進行 → 才發動
  # lock 用 mtime 當時間戳，最多擋 FABLE_LOCK_MAX_AGE 秒，避免抓取掛掉後永久卡住
  if { [ ! -s "$FABLE_CACHE" ] || [ "$_age" -ge "$FABLE_TTL" ]; } \
     && [ "$_lage" -ge "$FABLE_LOCK_MAX_AGE" ]; then
    mkdir -p "$(dirname "$FABLE_CACHE")" 2>/dev/null
    touch "$_lock" 2>/dev/null
    ( # macOS 走 Keychain；其他平台退回 Claude Code 的 credentials 檔
      _tok=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
              | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
      [ -z "$_tok" ] && [ -r "$HOME/.claude/.credentials.json" ] \
        && _tok=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
      if [ -n "$_tok" ]; then
        curl -sS --max-time 5 \
             -H "Authorization: Bearer $_tok" \
             -H "anthropic-beta: oauth-2025-04-20" \
             "https://api.anthropic.com/api/oauth/usage" 2>/dev/null \
          | jq '
              (.limits // [])
              | map(select(.kind == "weekly_scoped"
                    and ((.scope.model.display_name // "") | ascii_downcase | contains("fable"))))
              | (.[0] // {})
              | if (.percent // 0) == 0 and (.resets_at // null) == null
                then { fableUsage: null, fableResetAt: null }
                else { fableUsage: .percent, fableResetAt: .resets_at } end
            ' > "$FABLE_CACHE.tmp" 2>/dev/null \
          && [ -s "$FABLE_CACHE.tmp" ] && mv -f "$FABLE_CACHE.tmp" "$FABLE_CACHE"
      fi
      rm -f "$FABLE_CACHE.tmp" "$_lock" 2>/dev/null
    ) >/dev/null 2>&1 &
  fi
fi
# 讀取用 -s（非空）而不是 -f，空檔要能落到備援
_fc=""
[ -s "$FABLE_CACHE" ] && _fc="$FABLE_CACHE"
[ -z "$_fc" ] && [ -s "$FABLE_CACHE_RO" ] && _fc="$FABLE_CACHE_RO"
if [ -n "$_fc" ]; then
  eval "$(jq -r '
    def iso2ep(v): if v == null then 0
                   else (v | sub("\\.[0-9]+";"") | sub("\\+00:00";"Z") | fromdateiso8601) end;
    @sh "D_FB=\(if .fableUsage == null then -1 else (.fableUsage | round) end)",
    @sh "D_FBR=\(iso2ep(.fableResetAt))"
  ' "$_fc" 2>/dev/null)"
fi
: "${D_FB:=-1}" "${D_FBR:=0}"

# ── git 資訊（含 5 秒快取）──────────────────────────────────────
G_BRANCH=""; G_ADD=0; G_DEL=0; G_STATE=""
_git_root=$(git -C "$D_CWD" rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$_git_root" ]; then
  _gc_dir="$HOME/.cache/claude-statusline"
  _gc="$_gc_dir/git$(printf '%s' "$_git_root" | tr '/ ' '__')"
  _gage=$(( NOW - $(mtime "$_gc") ))
  if [ -f "$_gc" ] && [ "$_gage" -lt "$GIT_CACHE_TTL" ]; then
    . "$_gc"
  else
    G_BRANCH=$(git -C "$_git_root" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    [ "$G_BRANCH" = "HEAD" ] && G_BRANCH=$(git -C "$_git_root" rev-parse --short HEAD 2>/dev/null || true)
    set -- $(git -C "$_git_root" diff --numstat HEAD 2>/dev/null | awk '{a+=$1;d+=$2} END{print a+0, d+0}')
    G_ADD=${1:-0}; G_DEL=${2:-0}
    # 工作區狀態：已暫存 / 已修改未暫存 / 未追蹤 / 領先落後
    set -- $(git -C "$_git_root" status --porcelain=v1 -b 2>/dev/null | awk '
      NR == 1 && /^## / {
        if (match($0, /ahead [0-9]+/))  a = substr($0, RSTART + 6, RLENGTH - 6)
        if (match($0, /behind [0-9]+/)) b = substr($0, RSTART + 7, RLENGTH - 7)
        next
      }
      /^\?\?/ { u = 1; next }
      {
        x = substr($0, 1, 1); y = substr($0, 2, 1)
        if (x != " " && x != "?") st = 1
        if (y != " " && y != "?") md = 1
      }
      END { print (st ? 1 : 0), (md ? 1 : 0), (u ? 1 : 0), (a ? a : 0), (b ? b : 0) }
    ')
    G_STATE=""
    [ "${1:-0}" = "1" ] && G_STATE="$G_STATE$I_GIT_STAGED"
    [ "${2:-0}" = "1" ] && G_STATE="$G_STATE$I_GIT_DIRTY"
    [ "${3:-0}" = "1" ] && G_STATE="$G_STATE$I_GIT_UNTRACKED"
    # glyph 兩側各留一格：領先/落後箭頭比一格寬，貼著數字會疊字
    [ "${4:-0}" -gt 0 ] && G_STATE="$G_STATE $I_GIT_AHEAD ${4}"
    [ "${5:-0}" -gt 0 ] && G_STATE="$G_STATE $I_GIT_BEHIND ${5}"
    mkdir -p "$_gc_dir" 2>/dev/null
    printf 'G_BRANCH=%s\nG_ADD=%s\nG_DEL=%s\nG_STATE=%s\n' \
      "'$G_BRANCH'" "$G_ADD" "$G_DEL" "'$G_STATE'" > "$_gc" 2>/dev/null || true
  fi
fi

# =============================================================================
# §4  版面 —— 三行分別由哪些段組成
# =============================================================================

# ── 第一行：目錄 / 分支 / diff / model+effort / session 時間 / 系統時鐘 ──
_p="$D_CWD"
_short=0
if [ -n "$CWD_PROJECT_ROOT" ]; then
  _pat="*/$CWD_PROJECT_ROOT/"
  case "$_p" in
    $_pat*) _p="${_p##$_pat}"; _short=1 ;;
  esac
fi
if [ "$_short" = "0" ]; then
  [ "$ABBREV_HOME" = "1" ] && case "$_p" in "$HOME"*) _p="~${_p#$HOME}";; esac
  if [ "$CWD_MAX_SEG" -gt 0 ]; then
    _p=$(printf '%s' "$_p" | awk -F/ -v n="$CWD_MAX_SEG" \
          '{s=""; for(i=(NF-n+1>1?NF-n+1:1);i<=NF;i++) s=s (s==""?"":"/") $i; print s}')
  fi
fi
seg "$C_CWD_BG" "$C_CWD_FG" "$I_DIR  $_p"      # 雙空格：此 glyph 偏窄，補一格才對齊

if [ -n "$G_BRANCH" ]; then
  seg "$C_GIT_BG" "$C_GIT_FG" "$I_GIT $G_BRANCH$G_STATE"
  if [ "$G_ADD" -gt 0 ] || [ "$G_DEL" -gt 0 ]; then
    OUT=""; put_fg "$C_DIFF_ADD_FG"; put "$I_ADD$G_ADD"
    put_fg "$C_DIFF_FG"; put " "
    put_fg "$C_DIFF_DEL_FG"; put "$I_DEL$G_DEL"; _diff="$OUT"; OUT=""
    seg "$C_DIFF_BG" "$C_DIFF_FG" "$_diff"
  fi
fi

[ -n "$D_MODEL" ] && seg "$C_MODEL_BG" "$C_MODEL_FG" "$I_MODEL  $D_MODEL"   # 雙空格：同上
[ -n "$D_EFFORT" ] && seg "$C_MODEL_BG" "$C_MODEL_FG" "$I_EFFORT $D_EFFORT" 1

if [ "$D_DUR" -gt 0 ]; then
  fmt_dur "$D_DUR"
  _ic="$I_CLOCK"
  if [ "$I_CLOCK_DYNAMIC" = "1" ] && [ "$I_CLOCK_WINDOW_H" -gt 0 ]; then
    _frac=$(( D_DUR / 1000 * 100 / (I_CLOCK_WINDOW_H * 3600) ))
    if   [ "$_frac" -lt 33 ]; then _ic="$I_CLOCK_1"
    elif [ "$_frac" -lt 66 ]; then _ic="$I_CLOCK_2"
    else                           _ic="$I_CLOCK_3"
    fi
  fi
  seg "$C_CLOCK_BG" "$C_CLOCK_FG" "$_ic $DUROUT"
fi
seg "$C_TIME_BG" "$C_TIME_FG" "$I_TIME $(date '+%H:%M:%S')"
flush

# ── 第二行：context / in-out token / total / cached / cost ──────
bar "$D_CTX" "$BAR_W_CTX" "$C_CTX_BG"
style "$C_CTX_FG" "$C_CTX_BG"
lvl_mark "$D_CTX"
seg "$C_CTX_BG" "$C_CTX_FG" "$I_CTX $BAROUT$STYLEOUT ${D_CTX}%$MARKOUT"

fmt_num "$D_IN";  _in="$NUMOUT"
fmt_num "$D_OUT"; _out="$NUMOUT"
seg "$C_TOK_BG" "$C_TOK_FG" "$I_IN$_in $I_OUT$_out"

# total 併入同一顆藥丸（merge=1）
fmt_num $((D_IN + D_OUT + D_CR + D_CW)); seg "$C_TOK_BG" "$C_TOK_FG" "$I_TOTAL $NUMOUT" 1
fmt_num $((D_CR + D_CW));                seg "$C_CACHE_BG" "$C_CACHE_FG" "$I_CACHE $NUMOUT"
seg "$C_COST_BG" "$C_COST_FG" "$(printf "$I_COST %d.%02d" $((D_CENTS / 100)) $((D_CENTS % 100)))"
flush

# ── 第三行：5h / weekly / Fable 額度 ────────────────────────────
quota_seg() {  # quota_seg <label> <icon> <pct> <invert> <reset_epoch> <bg> <fg>
  local label=$1 icon=$2 pct=$3 inv=$4 rst=$5 sbg=$6 sfg=$7 shown suffix=""
  [ "$pct" -lt 0 ] && return
  shown=$pct
  [ "$inv" = "1" ] && shown=$((100 - pct))
  bar "$shown" "$BAR_W_QUOTA" "$sbg" "$pct"
  if [ "$inv" = "1" ]; then suffix=" left"; fi
  local t=""
  if [ "$rst" -gt 0 ]; then fmt_left "$rst"; t="  $LEFTOUT"; fi
  style "$sfg" "$sbg"
  lvl_mark "$pct"
  seg "$sbg" "$sfg" "$icon $label $BAROUT$STYLEOUT ${shown}%${suffix}$MARKOUT$t"
}
quota_seg "5h"    "$I_5H"    "$D_H5" "$INVERT_5H"    "$D_H5R"  "$C_5H_BG" "$C_5H_FG"
quota_seg "W"     "$I_WEEK"  "$D_WK" "$INVERT_WEEK"  "$D_WKR"  "$C_WK_BG" "$C_WK_FG"
# Fable 與 weekly 同時重置，所以不重複顯示時間（傳 0 = 不顯示）
quota_seg "Fable" "$I_FABLE" "$D_FB" "$INVERT_FABLE" 0         "$C_FB_BG" "$C_FB_FG"
flush

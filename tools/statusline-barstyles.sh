#!/usr/bin/env bash
OK="#3FE0C5"; WARN="#FFD166"; CRIT="#E66259"; EMPTY="#5b6b7f"
BG="#1e3a5f"; TRACK="#132741"
fg(){ local h=${1#\#}; printf '\033[38;2;%d;%d;%dm' $((16#${h:0:2})) $((16#${h:2:2})) $((16#${h:4:2})); }
bg(){ local h=${1#\#}; printf '\033[48;2;%d;%d;%dm' $((16#${h:0:2})) $((16#${h:2:2})) $((16#${h:4:2})); }
lvl(){ if [ "$1" -ge 85 ]; then printf '%s' "$CRIT"; elif [ "$1" -ge 60 ]; then printf '%s' "$WARN"; else printf '%s' "$OK"; fi; }

bar(){
  local p=$1 w=$2 f=$3 e=$4
  local n c i
  n=$((p*w/100)); c=$(lvl "$p")
  bg "$BG"; fg "$c"
  i=0
  while [ $i -lt $w ]; do
    [ $i -eq $n ] && fg "$EMPTY"
    if [ $i -lt $n ]; then printf '%s' "$f"; else printf '%s' "$e"; fi
    i=$((i+1))
  done
  printf '\033[0m'
}
smooth(){
  local p=$1 w=$2
  local sub full rem i c parts
  sub=$((p*w*8/100)); full=$((sub/8)); rem=$((sub%8)); c=$(lvl "$p")
  parts=" ▏▎▍▌▋▊▉"
  bg "$BG"; fg "$c"
  i=0
  while [ $i -lt $full ]; do printf '█'; i=$((i+1)); done
  if [ $rem -gt 0 ] && [ $i -lt $w ]; then
    printf '%s' "$(printf '%s' "$parts" | cut -c$((rem+1)))"; i=$((i+1))
  fi
  fg "$EMPTY"
  while [ $i -lt $w ]; do printf '░'; i=$((i+1)); done
  printf '\033[0m'
}
slider(){
  local p=$1 w=$2
  local n i c
  n=$((p*(w-1)/100)); c=$(lvl "$p")
  bg "$BG"; fg "$EMPTY"
  i=0
  while [ $i -lt $w ]; do
    if [ $i -eq $n ]; then fg "$c"; printf '◆'; fg "$EMPTY"; else printf '▬'; fi
    i=$((i+1))
  done
  printf '\033[0m'
}
pill(){
  local p=$1 w=$2
  local n c i
  n=$((p*w/100)); c=$(lvl "$p")
  bg "$BG"; fg "$TRACK"; printf ''
  bg "$TRACK"; fg "$c"
  i=0
  while [ $i -lt $w ]; do
    [ $i -eq $n ] && fg "$EMPTY"
    if [ $i -lt $n ]; then printf '▰'; else printf '▱'; fi
    i=$((i+1))
  done
  bg "$BG"; fg "$TRACK"; printf ''
  printf '\033[0m'
}
ba(){ bar "$1" "$2" ▰ ▱; }; bb(){ bar "$1" "$2" █ ░; }; bc(){ bar "$1" "$2" █ ▒; }
bd(){ bar "$1" "$2" ■ □; }; be(){ bar "$1" "$2" ● ○; }; bf(){ bar "$1" "$2" ▮ ▯; }
bg2(){ bar "$1" "$2" ⬢ ⬡; }; bh(){ bar "$1" "$2" ━ ━; }; bi(){ bar "$1" "$2" ⣿ ⣀; }
bj(){ bar "$1" "$2" ▪ ▫; }; bk(){ bar "$1" "$2" ▬ ▭; }; bl(){ bar "$1" "$2" ⏹ ⏺; }

row(){
  local label=$1 fn=$2 p
  printf '  %s' "$label"
  local pad=$(( 34 - ${#label} )); [ $pad -lt 1 ] && pad=1
  printf '%*s' $pad ''
  for p in 30 62 91; do "$fn" "$p" 10; printf ' %3d%%   ' "$p"; done
  echo
}
echo
printf '\033[1m  進度條樣式（30%%=安全 62%%=注意 91%%=危險）\033[0m\n\n'
row "A. ▰▱  幾何（目前使用）"      ba
row "B. █░  實心／淺網點"           bb
row "C. █▒  實心／中網點"           bc
row "D. ■□  方塊"                   bd
row "E. ●○  圓點"                   be
row "F. ▮▯  直條"                   bf
row "G. ⬢⬡  六角"                   bg2
row "H. ━━  粗線（只靠顏色分）"     bh
row "I. ⣿⣀  點字"                   bi
row "J. ▪▫  小方點"                 bj
row "K. ▬▭  寬條"                   bk
row "L. █░+八分格（解析度最高）"    smooth
row "M. ▬◆  slider 游標式"          slider
row "N. ▰▱ + 膠囊頭尾（Nerd Font）" pill
echo

#!/usr/bin/env bash

set -eu

RAW_BASE="${CLAUDE_STATUSLINE_RAW_BASE:-https://raw.githubusercontent.com/Hsing24/claude-statusline/main}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
TARGET="$CLAUDE_DIR/statusline.sh"
SETTINGS="$CLAUDE_DIR/settings.json"
SCRIPT_FILE="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [ -n "$SCRIPT_FILE" ] && [ -f "$SCRIPT_FILE" ]; then
  SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_FILE")" 2>/dev/null && pwd || true)
fi

fail() {
  printf '\n安裝失敗：%s\n' "$1" >&2
  exit 1
}

command -v bash >/dev/null 2>&1 || fail "找不到 bash。Windows 使用者請先安裝 Git for Windows，並在 Git Bash 內執行。"
command -v jq >/dev/null 2>&1 || fail "找不到 jq。請依 README 安裝 jq 後再執行一次。"

mkdir -p "$CLAUDE_DIR"

tmp_script=$(mktemp "${TMPDIR:-/tmp}/claude-statusline.XXXXXX")
tmp_settings=$(mktemp "${TMPDIR:-/tmp}/claude-settings.XXXXXX")
cleanup() {
  rm -f "$tmp_script" "$tmp_settings"
}
trap cleanup EXIT HUP INT TERM

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/statusline.sh" ]; then
  cp "$SCRIPT_DIR/statusline.sh" "$tmp_script"
else
  command -v curl >/dev/null 2>&1 || fail "找不到 curl，無法下載 statusline.sh。"
  printf '正在下載 statusline.sh...\n'
  curl -fsSL "$RAW_BASE/statusline.sh" -o "$tmp_script" || fail "下載失敗，請檢查網路後重試。"
fi

bash -n "$tmp_script" || fail "下載的腳本未通過語法檢查。"
install -m 755 "$tmp_script" "$TARGET"

if [ -f "$SETTINGS" ]; then
  jq empty "$SETTINGS" >/dev/null 2>&1 || fail "$SETTINGS 不是有效的 JSON；請先修正檔案。"
  backup="$SETTINGS.backup.$(date +%Y%m%d-%H%M%S)"
  cp "$SETTINGS" "$backup"
else
  printf '{}\n' >"$SETTINGS"
  backup=""
fi

status_command="bash \"$TARGET\""
jq --arg command "$status_command" '
  .statusLine = {
    type: "command",
    command: $command,
    padding: 0,
    refreshInterval: 1
  }
' "$SETTINGS" >"$tmp_settings" || fail "無法更新 Claude Code 設定。"
mv "$tmp_settings" "$SETTINGS"

printf '\n安裝完成！\n'
printf '  腳本：%s\n' "$TARGET"
printf '  設定：%s\n' "$SETTINGS"
[ -n "$backup" ] && printf '  備份：%s\n' "$backup"
printf '\n以下是預覽；若圖示變成方框，請把終端機字型切換成 Nerd Font。\n\n'
bash "$TARGET" --demo
printf '\n重新啟動 Claude Code（或開始下一次互動）即可看到狀態列。\n'

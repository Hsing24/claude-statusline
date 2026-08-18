# Claude Code Statusline

一個給 [Claude Code](https://code.claude.com/) 使用的三行狀態列。它會直接顯示目前目錄、Git 狀態、模型、context、token 與使用額度，不需要編譯。

```text
  claude-statusline    main+!?   +5 -0   󰚩  Opus 5 (1M) │ 󰍛 xhigh    1:30:32    16:41:02
  ▰▰▰▰▰▰▱▱▱▱ 62% ▲   ↑1.2M ↓45.6k │  1.3M    103.0k    1.23
 5h ▱▱▱▱▱▱▱▱ 10%  2h5m   W ▰▰▰▱▱▱▱▱ 45%  2d3h0m   Fable ▰▰▱▱▱▱▱▱ 31%
```

## 快速安裝

### 1. 先準備這些東西

| 要下載的項目 | 用途 | macOS | Windows | Linux |
|---|---|---|---|---|
| [Claude Code](https://code.claude.com/docs/en/quickstart) | 顯示狀態列的主程式 | 必要 | 必要 | 必要 |
| `jq` | 讀取 Claude Code 提供的資料 | `brew install jq` | `winget install jqlang.jq` | `sudo apt install jq curl` |
| [Meslo Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip) | 正確顯示圖示 | `brew install --cask font-meslo-lg-nerd-font` | 下載並安裝 zip 內字型 | 下載並安裝 zip 內字型 |
| [Git for Windows](https://git-scm.com/download/win) | 提供 Windows 所需的 Git Bash | 不需要 | 必要 | 不需要 |

安裝 Nerd Font 後，請到終端機的字型設定選擇 **MesloLGS Nerd Font**。若沒有切換，狀態列仍可運作，但圖示會顯示成方框。

macOS 若顯示 `brew: command not found`，請先安裝 [Homebrew](https://brew.sh/)。Linux 若不是 Ubuntu／Debian，請用系統套件管理器安裝 `jq` 與 `curl`。

> Windows 使用者：以下指令要在 **Git Bash** 執行，不是在 PowerShell 或命令提示字元執行。

### 2. 執行一行安裝指令

macOS、Linux 與 Windows Git Bash 使用同一行：

```bash
curl -fsSL https://raw.githubusercontent.com/Hsing24/claude-statusline/main/install.sh | bash
```

安裝程式會自動：

1. 下載腳本到 `~/.claude/statusline.sh`。
2. 備份原本的 `~/.claude/settings.json`。
3. 寫入 Claude Code 的 `statusLine` 設定。
4. 立即顯示一份預覽。

重新啟動 Claude Code，或在 Claude Code 裡進行下一次互動，就能在畫面底部看到狀態列。

### 從原始碼安裝

若你已經 clone 這個 repository：

```bash
bash install.sh
```

安裝程式會優先使用 repository 內的 `statusline.sh`，方便測試自己的修改。

## 如何看懂畫面

| 行數 | 顯示內容 |
|---|---|
| 第一行 | 目前目錄、Git 分支與變更、使用模型、thinking effort、工作時間與時鐘 |
| 第二行 | context 使用比例、輸入／輸出／快取 token、總 token 與本次費用 |
| 第三行 | 5 小時、每週與 Fable 額度，以及距離重置還有多久 |

沒有 Git repository、訂閱額度或 Fable 額度時，對應欄位會自動隱藏，這是正常行為。

## 設定

所有可調整項目都在 `~/.claude/statusline.sh` 開頭。修改並存檔後，下一次重繪就會生效，不必重新安裝。

### 最常調整的選項

```bash
CWD_PROJECT_ROOT="project"  # 縮短這個資料夾以下的路徑；設成 "" 可停用
CWD_MAX_SEG=0               # 0 顯示完整路徑；例如 2 只保留最後兩層
BAR_W_CTX=10                # context 進度條寬度
BAR_W_QUOTA=8               # 額度進度條寬度
WARN_AT=60                  # 到達 60% 顯示警告
CRIT_AT=85                  # 到達 85% 顯示危險
INVERT_5H=0                 # 0 顯示已用量；1 顯示剩餘量
INVERT_WEEK=0
INVERT_FABLE=0
FABLE_SELF_REFRESH=1        # 0 可停用 Fable 額度自動更新
```

例如你的專案都放在 `~/work`，把 `CWD_PROJECT_ROOT` 改成 `"work"`，`~/work/my-app` 就只會顯示 `my-app`。

### 顏色、圖示與版面

腳本開頭依序分成四區：

1. **調色盤**：每個 `*_BG` 是背景色，`*_FG` 是文字色。
2. **圖示**：`I_*`、`SEP_*` 與 `PILL_CAP_*` 是 Nerd Font 字元。
3. **顯示開關**：進度條、警告門檻、路徑與快取設定。
4. **版面**：決定三行中有哪些區塊以及排列順序。

修改顏色時，文字與背景最好維持至少 4.5:1 的對比度。Git diff 區塊同時顯示紅、綠文字，建議保持深色背景；有進度條的區塊則不要使用太深的背景。

### 手動設定 Claude Code

通常安裝程式已經完成這一步。若要手動設定，請在 `~/.claude/settings.json` 的最外層物件加入：

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash \"/你的絕對路徑/.claude/statusline.sh\"",
    "padding": 0,
    "refreshInterval": 1
  }
}
```

請保留檔案中原有的其他設定，不要直接用上面的範例覆蓋整份檔案。

## 預覽與檢查

不必開啟 Claude Code，也可以直接預覽：

```bash
bash ~/.claude/statusline.sh --demo
```

也可以餵一份簡化的測試資料：

```bash
echo '{"cwd":"'$PWD'","model":{"display_name":"Opus"},"context_window":{"used_percentage":62}}' |
  bash ~/.claude/statusline.sh
```

## 疑難排解

| 問題 | 解決方式 |
|---|---|
| 圖示是方框或空白 | 確認已安裝 Nerd Font，並在**終端機設定**中選用該字型；只安裝但沒有切換仍不會生效。 |
| 狀態列完全沒出現 | 執行 `jq --version` 與預覽指令；再確認 `~/.claude/settings.json` 內有 `statusLine`。 |
| 顯示 `statusline skipped · restart to fix` | 重新啟動 Claude Code，並接受目前工作區的信任提示。 |
| 顏色不正常或出現跳脫字元 | 換用支援 truecolor 的終端機，並以 `echo $COLORTERM` 檢查是否顯示 `truecolor`。 |
| 5h 或 W 區塊消失 | 帳號目前沒有提供對應的 `rate_limits` 資料，屬於正常情況。 |
| Fable 數字不更新 | 確認 `FABLE_SELF_REFRESH=1`；若帳號沒有 Fable 額度，該區塊會自動隱藏。 |
| 大型 repository 更新較慢 | 可增加 `GIT_CACHE_TTL`；預設為 5 秒。 |
| Windows 找不到 bash | 安裝 Git for Windows，關閉並重開 Git Bash，再重新執行安裝指令。 |
| 設定仍無法載入 | 執行 `claude --debug`，查看第一次 status line 呼叫的錯誤訊息。 |

安裝失敗時，安裝程式不會覆蓋無效的 JSON。若它曾更新設定，原檔會保留為 `~/.claude/settings.json.backup.日期-時間`。

## 進階工具

```bash
python3 tools/statusline-icons.py      # 用實際配色挑選 icon
bash tools/statusline-barstyles.sh    # 比較 14 種進度條樣式
python3 tools/glyph-id.py '󰚩'          # 查詢符號的 codepoint 與名稱
```

Nerd Font 的 PUA 字元在某些複製流程中可能遺失。要替換 icon 時，建議先用 `tools/statusline-icons.py` 選取，再確認變數沒有意外變成空字串。

## Fable 額度與隱私

Claude Code 傳給 status line 的資料不包含 Fable 每週額度。因此啟用 `FABLE_SELF_REFRESH=1` 時，腳本最多每 180 秒向 Anthropic 的帳號用量端點查詢一次：

- macOS 從 Keychain 的 `Claude Code-credentials` 讀取 OAuth token。
- Linux／Windows Git Bash 從 `~/.claude/.credentials.json` 讀取。
- 快取存放在 `~/.cache/claude-statusline/fable.json`。
- 這是用量查詢，不會進行模型推論，也不會消耗 token。

不需要此功能時，將 `FABLE_SELF_REFRESH` 設成 `0` 即可。

## 移除

1. 刪除 `~/.claude/statusline.sh`。
2. 從 `~/.claude/settings.json` 移除 `statusLine` 欄位，或還原安裝程式建立的備份。
3. 重新啟動 Claude Code。

## 授權

[MIT](LICENSE)

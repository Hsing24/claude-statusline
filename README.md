# Claude Code Statusline

一支純 bash 的 Claude Code statusline，三行顯示工作環境、token 用量與額度。
所有設定集中在腳本開頭，直接改檔案即可，不需要重新編譯或安裝套件。

```
 daily-tools/    main+!?   +5 -0   󰚩 Opus 5 (1M) │ 󰍛 xhigh    1:30:32    16:41:02
  ▰▰▰▰▰▰▱▱▱▱ 62% ▲   ↑1.2M ↓45.6k │  1.3M    103.0k    1.23
 5h ▱▱▱▱▱▱▱▱ 10%  2h5m   W ▰▰▰▱▱▱▱▱ 45%  2d3h0m   Fable ▰▰▱▱▱▱▱▱ 31%
```

整行黏成一條連續膠囊，行首行尾圓弧，段間用 powerline 箭頭；同一組（例如 model + effort）用細線分隔。

---

## 環境需求

| 項目 | 必要性 | 說明 |
|---|---|---|
| **Nerd Font** | 必要 | 否則所有 icon 與圓弧會變成方框。建議 **v3**（用到 `U+F06A9` 等 MDI 新字位） |
| **truecolor 終端機** | 必要 | 全部用 24-bit hex。檢查：`echo $COLORTERM` 應為 `truecolor` |
| **jq** | 必要 | 解析 stdin JSON。`brew install jq` / `apt install jq` |
| bash 3.2+ | 必要 | macOS 內建即可，腳本全程相容 bash 3.2（無關聯陣列） |
| git / curl / awk | 建議 | 沒有 git 則分支與 diff 區段自動隱藏 |

macOS 與 Linux 都可執行（`stat` 與憑證讀取都做了平台偵測）。

---

## 安裝

1. 把 `statusline.sh` 放到 `~/.claude/statusline.sh`

   ```bash
   cp statusline.sh ~/.claude/statusline.sh
   chmod +x ~/.claude/statusline.sh
   ```

2. 先試跑，確認字型與顏色正常：

   ```bash
   bash ~/.claude/statusline.sh --demo
   ```

   看到方框或空白 → Nerd Font 沒裝好或終端機沒選到該字型。

3. 在 `~/.claude/settings.json` 頂層加入 `statusLine`（見 `settings-snippet.json`）：

   ```json
   "statusLine": {
     "type": "command",
     "command": "bash /Users/YOUR_NAME/.claude/statusline.sh",
     "padding": 0,
     "refreshInterval": 1
   }
   ```

   **`command` 必須是絕對路徑**，Claude Code 不會展開 `~`。

4. 幾乎一定要改的一項 —— 腳本 §3 的：

   ```bash
   CWD_PROJECT_ROOT="project"
   ```

   在這個資料夾底下時只顯示相對路徑（`~/Desktop/project/daily-tools` → `daily-tools/`），
   其他路徑照常顯示完整路徑。改成你自己的專案根目錄名稱，或設成 `""` 停用。

---

## 設定區塊

腳本開頭分成四區，改完存檔即生效（下次重繪）。

### §1 調色盤

每段一組 `_BG`（背景）/ `_FG`（文字），24-bit hex。

```bash
C_CWD_BG="#526D82";     C_CWD_FG="#FFFFFF"    # 檔案路徑
C_GIT_BG="#27374D";     C_GIT_FG="#E6F1FF"    # 分支
C_DIFF_BG="#162536";    C_DIFF_FG="#E6F1FF"   # git diff
...
```

第一行預設是以 **git diff 為錨點**的雙向漸層：往左橘黃、往右藍。
錨點必須夠暗，因為 `+N` 綠色與 `-N` 紅色要壓在上面（詳見「配色注意事項」）。

進度條相關：

```bash
C_BAR_FILL="#0A1A2F"    # 進度條顏色（固定）；留空則改用下面的動態三色
C_LV_OK / C_LV_WARN / C_LV_CRIT
C_BAR_EMPTY=""          # 留空 = 由藥丸底色混入條色自動推導
C_BAR_TRACK=""          # 留空 = 條直接畫在藥丸底色上
```

### §2 圖示

Nerd Font 字元。不想要某個 icon 就設成空字串。

```bash
SEP_SOLID / PILL_CAP_L / PILL_CAP_R / SEP_THIN   # 分隔與圓弧
I_DIR / I_GIT / I_MODEL / I_EFFORT / I_TIME ...  # 各段 icon
I_CLOCK_1 / I_CLOCK_2 / I_CLOCK_3                # 沙漏三階段
I_WARN / I_CRIT                                   # 警示：三角 / 火焰
I_GIT_STAGED / I_GIT_DIRTY / I_GIT_UNTRACKED      # + ! ?
```

> **改 icon 時務必用 `tools/statusline-icons.py` 挑，不要自己貼字元。**
> Nerd Font 圖示位於 Unicode 私有區（PUA），複製貼上時常常會靜默遺失，
> 變成空字串而且語法檢查不會報錯。詳見「已知陷阱」。

### §3 開關

```bash
BAR_W_CTX=10 / BAR_W_QUOTA=8   # 進度條寬度
WARN_AT=60 / CRIT_AT=85        # 幾 % 出現三角 / 火焰
INVERT_5H / INVERT_WEEK / INVERT_FABLE   # 0=顯示已用量  1=顯示剩餘量
CWD_PROJECT_ROOT="project"     # 專案根目錄縮寫
CWD_MAX_SEG=0                  # 0=完整路徑；N=只顯示最後 N 層
GIT_CACHE_TTL=5                # git 資訊快取秒數
I_CLOCK_DYNAMIC=1              # 沙漏隨 session 時間變化
I_CLOCK_WINDOW_H=5             # 幾小時算流完一整個沙漏
FABLE_SELF_REFRESH=1           # Fable 用量自更新（見下方說明）
```

### §4 版面

三行分別由哪些段組成。要搬動順序、增減欄位改這裡。
`seg <底色> <文字色> <內容> [merge]`，第四個參數傳 `1` 表示併入前一顆藥丸。

---

## 隨附工具

```bash
python3 tools/statusline-icons.py      # icon 選單，用你的實際配色預覽
bash    tools/statusline-barstyles.sh  # 14 種進度條樣式對照
python3 tools/glyph-id.py '󰚩'          # 查符號的 codepoint 與 glyph 名稱
```

`tools/nerdfont-glyphnames.json` 是從 **SauceCodePro Nerd Font** 解析出來的 glyph 名稱表。
你若用別的字型，`glyph-id.py` 的名稱可能對不上（codepoint 仍正確）。

`statusline-icons.py` 的預覽色是寫死的，改了 §1 配色後要手動同步才會準。

---

## 配色注意事項

改底色時記得一起檢查對比度，這支腳本的資訊密度高、字小：

- **文字**：與底色至少 4.5:1
- **進度條等圖形**：至少 3:1

兩個特別容易出事的位置：

**1. git diff 那格**
`+N` 是綠色、`-N` 是紅色，兩個都要壓在同一個底色上。紅色本身亮度較高，
底色亮度必須 ≤ 0.019 才能讓紅色達到 4.5:1 —— 也就是**必須是很深的顏色**。
中間調（例如 `#4274D9`、`#66A3BF`）無論怎麼調都做不到，綠色在上面連 4.5 都碰不到。

**2. 有進度條的藥丸**
context、5h、weekly、Fable 四段內含進度條。條色預設固定 `#0A1A2F`（深），
所以那四段的底色不能太暗，否則條會看不見。

未填色與分隔線都是**自動推導**的（由該段底色混入條色 / 文字色），
改底色時它們會自動跟上，不需要手動維護。

---

## Fable 用量說明

`fable-weekly-usage` **不在 Claude Code 給 statusline 的 stdin 裡**。
stdin 的 `rate_limits` 只有 `five_hour`、`seven_day`、`seven_day_sonnet`、`seven_day_opus`。

腳本改為呼叫 `api.anthropic.com/api/oauth/usage`（OAuth token 取自 macOS Keychain 的
`Claude Code-credentials`，Linux 則讀 `~/.claude/.credentials.json`），
從回應的 `limits[]` 中找 `kind == "weekly_scoped"` 且 `scope.model.display_name` 含 `fable` 的項目。

- **不消耗 token、不產生費用** —— 這是帳號用量查詢端點，不是模型推論
- 最多每 180 秒一次，且有 lock 檔避免重複觸發
- 背景執行，不阻塞 statusline
- 快取寫在 `~/.cache/claude-statusline/fable.json`

不需要就把 §3 的 `FABLE_SELF_REFRESH` 設成 `0`。
沒有 Fable 額度的帳號，該段會自動隱藏。

---

## 已知陷阱

### Nerd Font 字元會被靜默吃掉

PUA 區字元（`U+E000`–`U+F8FF`、`U+F0000`+）在很多傳輸路徑上會遺失，
變成空字串，而 `bash -n` **檢查不出來** —— 腳本照常執行，只是沒有圖示。

要改 icon 請用：

```bash
python3 tools/glyph-id.py '你的符號'   # 取得 U+XXXX
```

然後用 Python 寫入而不是直接貼：

```python
import io, re
p = 'statusline.sh'
s = io.open(p, encoding='utf-8').read()
s = re.sub(r'^I_DIR="[^"]*"', 'I_DIR="%s"' % chr(0xF07C), s, count=1, flags=re.M)
io.open(p, 'w', encoding='utf-8').write(s)
```

改完驗證沒有空字串：

```bash
python3 -c "
import io,re
for l in io.open('statusline.sh',encoding='utf-8'):
    m=re.match(r'^(I_[A-Z0-9_]+|SEP_\w+|PILL_CAP_\w+|BAR_CAP_\w+)=\"([^\"]*)\"',l)
    if m: print(m.group(1), ' '.join('U+%04X'%ord(c) for c in m.group(2)) or '(空!!)')
"
```

### 其他

- 進度條 8 格時，每格代表 12.5%，所以低於 12.5% 的用量會顯示成全空條（數字仍正確）。
  想要更細可以加大 `BAR_W_QUOTA`。
- git diff 藥丸只在有未提交變更時出現，所以第一行的漸層在 clean repo 會少一階。
  這是預期行為，漸層在三種情境（髒 repo / clean / 非 git）下都會自然收合。
- 大型 repo 上 `git status` 可能較慢，已用 `GIT_CACHE_TTL`（預設 5 秒）快取。

---

## 疑難排解

| 症狀 | 原因 |
|---|---|
| 全是方框 / 豆腐字 | Nerd Font 沒裝，或終端機沒選到該字型 |
| icon 完全不見（但文字正常） | PUA 字元被吃掉了，見上方「已知陷阱」 |
| 顏色是階梯狀、不平滑 | 終端機不支援 truecolor，檢查 `echo $COLORTERM` |
| statusline 完全沒出現 | `command` 不是絕對路徑；或 `jq` 沒安裝 |
| 5h / W 那行不見 | 該帳號沒有訂閱額度，stdin 沒有 `rate_limits`（正常行為） |
| Fable 數字定格不動 | `FABLE_SELF_REFRESH=0`，或 token 讀不到 |

除錯時直接餵假 JSON 進去看：

```bash
echo '{"cwd":"'$PWD'","model":{"display_name":"Opus 5"},"context_window":{"used_percentage":62}}' \
  | bash ~/.claude/statusline.sh
```

---

## 授權

[MIT](LICENSE)

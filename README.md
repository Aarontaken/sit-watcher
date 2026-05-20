# SitWatcher · macOS 久坐提醒

**[English README](README.en.md)**

**SitWatcher** 是一款运行在 **Mac 菜单栏** 上的开源 **久坐提醒 / 久坐提示 / 起身提醒 / 站立提醒** 小工具：久坐倒计时结束后先弹出浮窗，可延后；若长时间不理会会升级为全屏遮罩，直到你确认「已经站起来」，帮你打断连续久坐。

如果你在用 GitHub 搜索 **「久坐提醒」「久坐提示」「久坐」「起身提醒」「站立提醒」「菜单栏提醒」**，本项目就是这些关键词所指的一类工具——专治「一坐一下午忘了动」。

### 久坐危害

长时间久坐易造成颈椎腰椎酸痛、下肢血液不畅、肩颈僵硬、视力疲劳，还会降低代谢、精神萎靡，长期严重影响身体健康与工作状态。

### 每 30 分钟起身活动好处

定时起身走动拉伸，促进全身血液循环，放松紧绷肌肉，缓解用眼疲劳，快速恢复专注力，舒缓身心压力，有效远离亚健康，轻松养成健康作息。

### 项目寄语

这款久坐提醒工具，只为提醒忙碌的你劳逸结合，好好爱护身体，高效工作，健康生活。

## 久坐提醒（久坐提示）是怎么工作的？

1. **倒计时**：按你在设置里配置的间隔（默认可调）倒计时剩余久坐时间。
2. **浮窗**：到时后出现提醒窗口，可确认起身或延后几分钟。
3. **全屏**：若持续忽略浮窗，会在「全屏提醒延迟」到期后铺满屏幕强化提醒（仍为同一套久坐逻辑）。
4. **离开检测**：鼠标键盘长时间无操作时视为暂时离开，计时自动暂停，回来再继续。

## 预览

### 浅色界面（应用内设为浅色或与系统浅色一致）

<table>
  <tr>
    <td align="center"><img src="screenshots/panel-light.png" width="220" /><br />菜单栏面板 · 久坐统计 · 浅色</td>
    <td align="center"><img src="screenshots/floating-reminder-demo-light.gif" width="360" alt="浅色 · 浮窗久坐提醒动图演示" /><br />浮窗久坐提醒 · 浅色 · ≈1s</td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/fullscreen-overlay-demo-light.gif" width="400" alt="浅色 · 全屏久坐提醒动图演示" /><br />全屏久坐提醒 · 浅色 · ≈1s</td>
    <td align="center"><img src="screenshots/settings-light.png" width="220" /><br />设置 · 浅色</td>
  </tr>
</table>

### 深色界面

<table>
  <tr>
    <td align="center"><img src="screenshots/panel.png" width="220" /><br />菜单栏面板 · 久坐统计</td>
    <td align="center"><img src="screenshots/floating-reminder-demo.gif" width="360" alt="浮窗久坐提醒动图演示" /><br />浮窗久坐提醒 · 动图演示</td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/fullscreen-overlay-demo.gif" width="400" alt="全屏久坐提醒动图演示" /><br />全屏久坐提醒 · 动图演示</td>
    <td align="center"><img src="screenshots/settings.png" width="220" /><br />设置 · 间隔与延迟</td>
  </tr>
</table>

## Preview · English UI

### Light appearance

<table>
  <tr>
    <td align="center"><img src="screenshots/panel-light-en.png" width="220" /><br />Menu bar panel · light</td>
    <td align="center"><img src="screenshots/floating-reminder-demo-light-en.gif" width="360" alt="Floating reminder · light demo" /><br />Floating reminder · ≈1s</td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/fullscreen-overlay-demo-light-en.gif" width="400" alt="Full-screen reminder · light demo" /><br />Full-screen reminder · ≈1s</td>
    <td align="center"><img src="screenshots/settings-light-en.png" width="220" /><br />Settings · light</td>
  </tr>
</table>

### Dark appearance

<table>
  <tr>
    <td align="center"><img src="screenshots/panel-en.png" width="220" /><br />Menu bar panel · stats</td>
    <td align="center"><img src="screenshots/floating-reminder-demo-en.gif" width="360" alt="Floating reminder demo" /><br />Floating reminder</td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/fullscreen-overlay-demo-en.gif" width="400" alt="Full-screen reminder demo" /><br />Full-screen reminder</td>
    <td align="center"><img src="screenshots/settings-en.png" width="220" /><br />Settings · intervals</td>
  </tr>
</table>

<sub><strong>浅色动图：</strong><code>-light</code>/<code>-light-en</code> 截取前 ≈1s，源录像 <code>录屏弹窗-浅色模式.mov</code>、<code>录屏全屏-浅色模式.mov</code>（英文 UI 后缀 <code>-en</code>），执行 <code>bash scripts/regenerate_light_mode_demo_gifs.sh</code>。<strong>深色：</strong><code>floating-reminder-demo.gif</code>（≈1s，源 <code>弹窗视频.mov</code>）、<code>fullscreen-overlay-demo.gif</code>（≈2s，源 <code>全屏打断视频.mov</code>），对应 <code>bash scripts/regenerate_floating_demo_gif.sh</code> · <code>bash scripts/regenerate_fullscreen_demo_gif.sh</code>；英文深色动图：<code>regenerate_*_gif_en.sh</code>。<code>screenshots/*.mov</code> 仅本地留存，由 <code>.gitignore</code> 忽略。需安装 ffmpeg。</sub>

## 功能概要

- **久坐计时**：菜单栏环形倒计时与今日起身次数、专注时长等统计  
- **智能暂停**：离开座位自动暂停久坐计时，并可区分真实操作与脚本鼠标抖动  
- **可调参数**：久坐间隔、全屏升级延迟、离开判定阈值、鼠标灵敏度等  
- **自动更新**：内置 [Sparkle](https://sparkle-project.org/)，可在应用内检查新版本

## 安装

**1. 一行脚本（推荐）** — 安装最新 Release 到 `/Applications` 并启动：

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/Aarontaken/sit-watcher@master/install.sh | bash
```

也可用 GitHub raw（分支名为 **`master`**，不要用 `main`）：

```bash
curl -fsSL https://raw.githubusercontent.com/Aarontaken/sit-watcher/master/install.sh | bash
```

**2. Homebrew**

```bash
brew tap Aarontaken/tap
brew install --cask sit-watcher
```

**3. 手动** — [Releases](https://github.com/Aarontaken/sit-watcher/releases) 下载 `SitWatcher.dmg`，双击挂载后用 **`Install.app`** 安装。

---

开发者修改过 `install.sh` 后，可在仓库根目录执行 `bash scripts/verify-install.sh` 做下载解压自检（不写 `/Applications`）。

## 从源码构建

```bash
brew install xcodegen create-dmg
xcodegen generate
./scripts/build.sh
```

或用 Xcode 打开生成的工程，选中 **SitWatcher** 运行（⌘R）。

## 系统要求

- macOS 14（Sonoma）及以上  
- Apple Silicon / Intel

## License

MIT
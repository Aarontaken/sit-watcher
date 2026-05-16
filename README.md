# SitWatcher

macOS 菜单栏久坐提醒：倒计时结束 → 浮窗 → 可延后；持续忽略则全屏提醒，直到你确认起身。

## 预览

<table>
  <tr>
    <td align="center"><img src="screenshots/panel.png" width="220" /><br />菜单栏面板</td>
    <td align="center"><img src="screenshots/floating-reminder.png" width="280" /><br />浮窗提醒</td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/fullscreen-overlay.png" width="400" /><br />全屏覆盖</td>
    <td align="center"><img src="screenshots/settings.png" width="220" /><br />设置</td>
  </tr>
</table>

## 功能概要

- 菜单栏倒计时环与今日统计  
- 离开座位自动暂停计时，区分真实操作与脚本鼠标  
- 间隔、全屏延迟、离开判定等均可调  
- 内置 [Sparkle](https://sparkle-project.org/)，可在应用内检查更新  

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

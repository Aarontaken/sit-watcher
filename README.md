# SitWatcher

macOS 菜单栏久坐提醒应用。长时间坐着不动时，它会用逐步升级的方式提醒你站起来活动。

## 截图预览

<table>
  <tr>
    <td align="center"><img src="screenshots/panel.png" width="220" /><br /><b>菜单栏面板</b><br />倒计时环 + 今日统计</td>
    <td align="center"><img src="screenshots/floating-reminder.png" width="280" /><br /><b>浮窗提醒</b><br />可确认或延后 5 分钟</td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/fullscreen-overlay.png" width="400" /><br /><b>全屏覆盖</b><br />忽略浮窗后强制打断</td>
    <td align="center"><img src="screenshots/settings.png" width="220" /><br /><b>设置</b><br />所有参数可自定义</td>
  </tr>
</table>

## 功能特性

- **菜单栏常驻** — 不占 Dock 栏，安静地待在菜单栏
- **倒计时环** — 一目了然地看到距离下次提醒还有多久
- **渐进式提醒** — 到时间后先弹浮窗提醒，忽略则升级为全屏覆盖，逼你站起来
- **贪睡模式** — 还没准备好？可以延后 5 分钟再提醒
- **智能离开检测** — 检测到你已离开座位时自动暂停计时，回来后重新开始
- **防脚本干扰** — 如果你有定时移动鼠标的 keep-alive 脚本，不会被误判为活跃状态
- **今日统计** — 记录已休息次数、被打断次数和专注时长
- **可自定义** — 提醒间隔、全屏延迟、离开检测时间等均可调节

## 提醒流程

```
30 分钟倒计时结束
        ↓
   浮窗提醒（右上角）
   ├── 点击「好的，我去活动」→ 重置计时器
   ├── 点击「稍后 5 分钟」 → 延后提醒
   └── 忽略 2 分钟 ↓
       全屏覆盖（必须响应）
       └── 点击「我已经站起来了」→ 重置计时器
```

## 安装

### 方式一：一行命令（推荐）

每次执行都会拉取 **`master` 上的最新 `install.sh`**（下面用 jsDelivr 镜像，避免 `raw.githubusercontent.com` 按分支取文件时的 CDN 滞后），再用 GitHub **Releases 的最新 tag** 匹配 **`gh-pages`** 上的 `SitWatcher-{版本}.zip`，解压后安装到 `/Applications` 并启动。**无需手动指定版本。**

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/Aarontaken/sit-watcher@master/install.sh | bash
```

等价官方 raw（若你已确认内容与仓库一致也可用）：

```bash
curl -fsSL https://raw.githubusercontent.com/Aarontaken/sit-watcher/master/install.sh | bash
```

仓库默认分支是 **master**；若误用 **`main`**，raw 链接会 **404**。若你刚从网页复制仍看到 `main`，多半是 **未推送前的旧页面或 CDN 缓存**：刷新 [README](https://github.com/Aarontaken/sit-watcher/blob/master/README.md) 后再复制即可。

极少数情况需锁定某一版本：`… | bash -s -- v1.0.3`。

### 方式二：Homebrew

```bash
brew tap Aarontaken/tap
brew install --cask sit-watcher
```

### 方式三：手动下载

前往 [Releases](https://github.com/Aarontaken/sit-watcher/releases) 下载 `SitWatcher.dmg`，右键打开 `Install.app`。

### 校验安装脚本（可选，不写 `/Applications`）

改动了 `install.sh` 后可在本地跑与 CI 相同的检查（验证 API → zip → 解压 → `.app` 结构）：

```bash
bash scripts/verify-install.sh
```

### 从源码构建

```bash
# 安装依赖
brew install xcodegen create-dmg

# 生成 Xcode 项目
xcodegen generate

# 构建 DMG
./scripts/build.sh
```

在 Xcode 中选择 **SitWatcher** target，点击 Run (⌘R) 或直接使用 `./scripts/build.sh` 打包。

## 自动更新

SitWatcher 使用 [Sparkle](https://sparkle-project.org/) 自动检查更新。点击菜单栏面板底部的「更新」按钮可手动检查。所有更新均经过 ed25519 签名验证。

## 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- Apple Silicon / Intel Mac

## 技术栈

- **Swift + SwiftUI** — 菜单栏面板、设置页、浮窗提醒的 UI
- **AppKit (NSPanel)** — 浮窗和全屏覆盖使用 `NSPanel` + `nonactivatingPanel` 实现可交互的悬浮窗口
- **ObservableObject** — 响应式状态管理，驱动 UI 实时更新
- **UserDefaults** — 持久化用户设置
- **xcodegen** — 从 YAML 生成 Xcode 项目文件，避免 `.xcodeproj` 冲突

## 项目结构

```
SitWatcher/
├── SitWatcherApp.swift          # 应用入口，MenuBarExtra 定义
├── AppCoordinator.swift         # 核心协调器，管理所有服务和窗口
├── AppState.swift               # 应用状态（计时器、提醒等级、统计）
├── Settings.swift               # 用户设置，自动持久化到 UserDefaults
├── Services/
│   ├── TimerEngine.swift        # 倒计时引擎
│   ├── IdleDetector.swift       # 用户离开检测（区分真实操作和脚本）
│   ├── ReminderEscalator.swift  # 提醒升级调度（浮窗 → 全屏）
│   └── NotificationManager.swift
├── Views/
│   ├── MenuBarPanel.swift       # 菜单栏弹出面板
│   ├── TimerRingView.swift      # 圆环倒计时
│   ├── ControlButtonsView.swift # 暂停/跳过/重置按钮
│   ├── StatsView.swift          # 今日统计
│   ├── FloatingReminderView.swift   # 浮窗提醒 UI
│   ├── FullScreenOverlayView.swift  # 全屏覆盖 UI
│   └── SettingsView.swift       # 设置页
└── Windows/
    ├── FloatingWindowController.swift  # 浮窗窗口管理
    └── OverlayWindowController.swift   # 全屏覆盖窗口管理
```

## License

MIT

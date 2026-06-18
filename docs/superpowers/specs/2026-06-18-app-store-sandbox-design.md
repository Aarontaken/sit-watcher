# App Store 更新与 Sandbox 迁移设计

## 目标

将 SitWatcher 收敛为单一的 Mac App Store 分发版本。应用不再包含 Sparkle 或任何自更新路径，必须启用 App Sandbox，并且在提交 App Store 之前，可以在本地工作区完成自验证。

## 决策

- 从唯一的 app target 中移除 Sparkle，不再维护 App Store 和直接下载两套发行变体。
- 将“检查更新”替换为“打开 App Store”。
- 将 App Store app ID 放在一个集中的配置点。因为当前还没有创建 App Store Connect app 记录，首次实现使用空值，并提供确定性的 fallback URL。
- 启用 `com.apple.security.app-sandbox`。
- 不预先添加额外 sandbox entitlement；只有验证证明现有功能确实需要时，才做有针对性的补充。

## 更新入口流程

footer 里的更新按钮改为 App Store 入口：

1. 如果配置了数字 App Store app ID，打开 `macappstore://apps.apple.com/app/id<APP_ID>`。
2. 如果打开失败，fallback 到 `https://apps.apple.com/app/id<APP_ID>`。
3. 如果没有配置 app ID，打开 `https://apps.apple.com/search?term=SitWatcher`。

这个流程不会下载、安装或执行任何应用代码，只会把用户带到 Apple 控制的 App Store 页面。

## 代码结构

- `project.yml`
  - 删除 Sparkle package 声明。
  - 删除 `SitWatcher` target 对 Sparkle 的依赖。
- `SitWatcher/Info.plist`
  - 删除 `SUEnableAutomaticChecks`。
  - 删除 `SUFeedURL`。
  - 删除 `SUPublicEDKey`。
- `SitWatcher/SitWatcherApp.swift`
  - 删除 `import Sparkle`。
  - 删除 `SPUStandardUpdaterController`。
  - 删除 `UpdateAvailabilityObserver`。
  - 保持菜单栏 app 的整体结构不变。
  - 将新的 App Store 打开动作传给面板。
- 新增更新打开单元
  - 提供一个小类型，例如 `AppStoreUpdateOpener`。
  - 将 app ID 空值占位集中放在唯一常量里。
  - 暴露一个只构造待尝试 URL 的方法，让单元测试无需真正打开 App Store 就能验证行为。
  - 暴露一个通过注入闭包打开 URL 的方法，让测试可以模拟成功和失败。
- `SitWatcher/Views/UnifiedPanelPrototype.swift`
  - 保留 footer 按钮的位置和图标风格。
  - 将 action 概念从“检查更新”改为“打开 App Store”。
  - 移除这个按钮上的可用更新红点，因为应用不再检查 appcast 元数据。
- 本地化字符串
  - 将更新 footer 的 label/help 文案从“检查更新”改为“打开 App Store”。
  - 保留 `SitWatcher/Localizable.xcstrings` 中无关的已有本地改动。
- `SitWatcher/SitWatcher.entitlements`
  - 将 `com.apple.security.app-sandbox` 设置为 `true`。

## Sandbox 影响

预计可以继续工作：

- 菜单栏额外项 UI。
- AppKit/SwiftUI 窗口和覆盖层。
- `UserDefaults` 设置。
- 用户通知。
- 从用户选择的文件导入自定义角色，并将处理后的资源存储到 Application Support。
- 通过 `SMAppService.mainApp` 设置登录启动。

需要明确验证：

- 通过 `NSEvent.mouseLocation` 做的空闲检测。
- 通过 `CGEventSource.secondsSinceLastEventType` 做的键盘空闲时间判断。
- sandbox 下跨屏全屏覆盖层的展示。
- 从图片、动图、视频源导入自定义角色。

实现时不应预先添加宽泛的文件、自动化、输入监听或辅助功能 entitlement。如果验证失败定位到具体 entitlement 或用户权限需求，再作为针对性后续处理。

## 错误处理

- 打开 App Store URL 不能阻塞或崩溃提醒主流程。
- 如果 `macappstore://` 打开失败，尝试 HTTPS。
- 如果所有打开尝试都失败，用 `print` 输出简短诊断。
- 缺少 App ID 在 App Store 记录创建前不是错误；此时按设计打开搜索 fallback。

## 验证要求

只有当本地可以完成验证，并且不依赖人工提交 App Store，才算实现完成。

自动化/静态验证：

- `rg "Sparkle|SPU|SUFeedURL|SUPublicEDKey|SUEnableAutomaticChecks" SitWatcher project.yml` 不返回生产代码引用。
- 生成后的 Xcode project 不包含 Sparkle package 依赖。
- `SitWatcher/SitWatcher.entitlements` 中 `com.apple.security.app-sandbox` 为 `true`。
- 单元测试覆盖：
  - 配置 App Store ID 时的 URL 顺序。
  - App Store ID 为空时的搜索 fallback URL。
  - `macappstore://` 失败后继续尝试 HTTPS 并成功。
- 现有单元测试继续通过 `xcodebuild test`。

运行时验证：

- 使用 `xcodegen generate` 生成 Xcode project。
- 使用项目现有的本地 `xcodebuild test` 流程构建并测试。
- 启动 debug app。
- 确认菜单栏面板可以打开。
- 触发 footer 的 App Store 动作，并在 App ID 为空时验证 opener 到达预期 fallback URL。
- 确认触发动作后 app 仍保持运行。
- 做一次短 sandbox smoke check：观察鼠标/键盘活动仍能重置 idle accumulator，不活动状态仍能朝 idle 推进。

## 不在范围内

- 创建 App Store Connect app 记录。
- 选择定价或订阅机制。
- App Store 截图、元数据和审核备注。
- 重做提醒 UX。
- 同时支持 Sparkle 和 App Store 两套构建。

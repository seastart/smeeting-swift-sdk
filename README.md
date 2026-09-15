# SMeeting Swift SDK

多人会议 SDK，支持 iOS 16+ 与 macOS 14+。提供主持人、举手、静音全场、等候室、
子会议等会控能力；底层音视频由 SRTC 提供。

本仓库只包含分发清单，SDK 以预编译 XCFramework 形式提供。

只要音视频通道、不需要会控，用 [SRTC](https://github.com/seastart/srtc-swift-sdk) 就够了。

## 集成

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/seastart/smeeting-swift-sdk.git", from: "1.3.5"),
]
```

在 target 中引用：

```swift
.product(name: "SMeeting", package: "smeeting-swift-sdk")
```

Xcode 图形界面：**File → Add Package Dependencies…**，填入本仓库地址。

SRTC 与 WebRTC 依赖会自动解析，无需另行声明。
（例外：iOS 全屏屏幕共享的扩展 target 需要单独声明 `srtc-swift-sdk`，见下方「屏幕共享」。）

## 快速开始

```swift
import SMeeting

let meeting = SMeetingEngine(logLevel: .debug)

// token 由你的业务后端签发，客户端不参与签名
try await meeting.login(token: token)
```

渲染视图与 Track 类型来自 SRTC，用到时一并 `import SRTC`。

完整文档见 [docs.stmlink.com](https://docs.stmlink.com)。

## 屏幕共享

### macOS

`requestShare()` 默认采主显示器；要让用户挑显示器/窗口就先枚举源（macOS 12.3+）：

```swift
let displays = try await ScreenCaptureSources.availableDisplays()
try await meeting.requestShare(source: displays[0])
```

### iOS

| 路径 | API | 能采到什么 |
| --- | --- | --- |
| 应用内采集 | `requestShare()` | **只有本 App 的画面** |
| 全屏采集 | `prepareBroadcastShare(appGroup:)` + `publishBroadcastShare()` | 整个系统屏幕 |

全屏采集需要额外集成一个 Broadcast Upload Extension：

1. 新建 Broadcast Upload Extension target，**只链接 `SRTCBroadcastKit`**，
   principal class 继承 `SRTCBroadcastSampleHandler`：

   ```swift
   import SRTCBroadcastKit

   class SampleHandler: SRTCBroadcastSampleHandler {}
   ```

   `SRTCBroadcastKit` 是 `srtc-swift-sdk` 的产物，而 SwiftPM 不允许使用传递依赖的产品，
   所以要在你的 `Package.swift`（或 Xcode 的 Package Dependencies）里**再加一条**：

   ```swift
   .package(url: "https://github.com/seastart/srtc-swift-sdk.git", exact: "1.4.4"),
   ```

   ⚠️ 只把 `SRTCBroadcastKit` 加到扩展 target 上：加到 App target 会让一个进程里出现
   两份同名类型（App 侧的 SRTC 已静态含有同一份代码）；反过来让扩展去链 SRTC/SMeeting
   会把 WebRTC 拉进只有 50MB 内存上限的扩展进程，很容易被系统杀掉。

2. App 与扩展配同一个 App Group，并在**扩展的 Info.plist** 写 `SRTCAppGroupIdentifier`
   （App entitlement、扩展 entitlement、扩展 Info.plist 三处必须一致）。
   App Group 还要在开发者后台注册，两份描述文件都得带上该 capability，
   否则签名阶段就报 `Provisioning profile doesn't include the App Groups capability`。

3. 入会后挂上监听，共享按钮直接用 `SRTCBroadcastPicker`
   （全屏采集只能由用户从系统 UI 发起，把它 `title: ""` 透明盖在自己画的按钮上）：

   ```swift
   // 入会后：只挂监听，不通知会议后端 —— 此刻共享还没开始
   try await meeting.prepareBroadcastShare(appGroup: "group.your.app")

   // 共享按钮：点一下直接进系统弹窗，App 侧不做任何事
   myShareButton.overlay {
       SRTCBroadcastPicker(preferredExtension: "com.your.app.broadcast", title: "")
   }

   // 用户点了"开始直播"，扩展开始出帧 —— 这时才对会议宣布共享
   func meeting(_ meeting: SMeetingEngine, shareBroadcastDidStart data: ShareBroadcastStartEventData) {
       Task { try? await meeting.publishBroadcastShare() }
   }
   ```

⚠️ **不要在点按钮时就 `requestShare`。** 用户在系统弹窗里点取消是没有回调的，
那样会议里会挂着一个永远没有画面的共享标记。一步到位的 `requestShare(broadcastAppGroup:)`
仍然保留，但只适合不关心中间态的简单集成。

| 状态 | 判断方式 |
| --- | --- |
| 已挂监听、用户还没开播 | `prepareBroadcastShare` 已成功，`isShareBroadcastActive == false` |
| 正在出帧 | 收到 `shareBroadcastDidStart` |
| 已结束 | 收到 `shareBroadcastDidFinish(reason:)` |

用户从系统胶囊停止广播时 SDK 会自动收尾（退发布 + 通知会议后端）并重新挂上监听，
业务侧不需要再调 `stopShare()`、也不用重新 prepare，只需刷新 UI。
不再需要共享能力时调 `stopBroadcastListening()`（`exitRoom()` 会自动拆）。

**模拟器跑不通全屏采集，必须真机。** 扩展进程的日志不在 Xcode 控制台，
用 Console.app 按 subsystem `com.srtc.broadcast` 过滤。

## 音频路由（iOS）

分持久与临时两层，**临时优先**：

```swift
meeting.defaultAudioRoute = .speaker        // 持久：入会前设定，长期有效
meeting.setAudioRoute(.earpiece)            // 临时：入会后临时切
meeting.clearAudioRouteOverride()           // 撤销临时覆盖，回落到持久默认
```

只读状态：`currentAudioRoute`（系统实际路由，含蓝牙/有线）、`effectiveAudioRouteTarget`、
`isExternalAudioRouteActive`、`availableAudioRoutes()`、`audioCallState`。
路由变化回调 `meeting(_:audioRouteDidChange:)`，来电中断恢复后回调
`meetingAudioRouteDidRecoverFromInterruption`。

- 可控目标只有**听筒 / 外放**两态：iOS 上没有可靠手段指定具体外设，
  要让用户选蓝牙/AirPlay 请用 `AVRoutePickerView`。外设在用时切外放会被忽略
  （该操作在 iOS 上本就无效）。
- 入会即建立通话音频通道并常驻到离会，因此**入会就会申请麦克风权限、状态栏亮橙色指示点**。
  这是路由可控的前提（会话不在通话模式时听筒切不过去），主流会议 App 同样如此。

## 版本

当前版本 **1.3.5**（依赖 SRTC **1.4.4**）。

| 平台 | 最低版本 |
| --- | --- |
| iOS | 16.0 |
| macOS | 14.0 |
| Xcode | 15.0 |

- macOS 指定显示器/窗口共享需要 macOS 12.3+
- iOS 全屏屏幕共享需要额外集成 Broadcast Upload Extension（见上）

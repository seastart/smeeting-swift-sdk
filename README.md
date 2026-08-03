# SMeeting Swift SDK

多人会议 SDK，支持 iOS 13+ 与 macOS 10.15+。提供主持人、举手、静音全场、等候室、
子会议等会控能力；底层音视频由 SRTC 提供。

本仓库只包含分发清单，SDK 以预编译 XCFramework 形式提供。

只要音视频通道、不需要会控，用 [SRTC](https://github.com/seastart/srtc-swift-sdk) 就够了。

## 集成

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/seastart/smeeting-swift-sdk.git", from: "1.0.0"),
]
```

在 target 中引用：

```swift
.product(name: "SMeeting", package: "smeeting-swift-sdk")
```

Xcode 图形界面：**File → Add Package Dependencies…**，填入本仓库地址。

SRTC 与 WebRTC 依赖会自动解析，无需另行声明。

## 快速开始

```swift
import SMeeting

let meeting = SMeetingEngine(logLevel: .debug)

// token 由你的业务后端签发，客户端不参与签名
try await meeting.login(token: token)
```

渲染视图与 Track 类型来自 SRTC，用到时一并 `import SRTC`。

完整文档见 [docs.stmlink.com](https://docs.stmlink.com)。

## 版本

当前版本 **1.0.0**。

| 平台 | 最低版本 |
| --- | --- |
| iOS | 13.0 |
| macOS | 10.15 |
| Xcode | 15.0 |

屏幕共享需要 macOS 12.3+。

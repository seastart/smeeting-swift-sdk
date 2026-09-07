// swift-tools-version: 5.9
//
// SMeeting Swift SDK —— 二进制分发清单
//
// 本文件由构建脚本自动生成，请勿手工编辑版本号与 checksum。

import PackageDescription

let package = Package(
    name: "smeeting-swift-sdk",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "SMeeting",
            targets: ["SMeetingSDK"]
        ),
    ],
    dependencies: [
        // SRTC。SMeeting 是会议业务层，渲染视图、Track 等类型都来自 SRTC 并出现在
        // public API 上，所以这个依赖必须暴露给使用方。
        //
        // ⚠️ iOS 全屏屏幕共享的扩展侧要链 `SRTCBroadcastKit`（srtc-swift-sdk 的第二个产物，
        // 不依赖 WebRTC）。SwiftPM 不允许使用传递依赖的产品，所以接入方需要在自己的
        // Package.swift / Xcode 工程里**再声明一条 srtc-swift-sdk 依赖**，版本与这里 pin 的
        // 1.3.2 保持一致，并且只把 SRTCBroadcastKit 加到 Broadcast Upload Extension
        // 的 target 上——加到 App target 会让一个进程里出现两份同名类型（App 侧的 SRTC
        // 里已静态含有同一份代码），反过来让扩展去链 SRTC/SMeeting 则会把 WebRTC 拉进
        // 只有 50MB 内存上限的扩展进程。
        .package(url: "https://github.com/seastart/srtc-swift-sdk.git", exact: "1.3.2"),
    ],
    targets: [
        // 预编译的 SDK 本体。`import SMeeting` 导入的就是它。
        .binaryTarget(
            name: "SMeeting",
            url: "https://repo.open.seastart.cn/repository/vcs-releases/meeting-swift-sdk-1.2.1.zip",
            checksum: "6fff3b4820d8bf5b479cec31413107bbc0923251ab401fbc50a8c9059ebf08e5"
        ),
        // 中转 target。binaryTarget 自己不能声明 dependencies，所以套一层普通 target
        // 把 SRTC 依赖（及其带过来的 WebRTC）传递给使用方。
        .target(
            name: "SMeetingSDK",
            dependencies: [
                "SMeeting",
                .product(name: "SRTC", package: "srtc-swift-sdk"),
            ],
            path: "Sources/SMeetingSDK"
        ),
    ]
)

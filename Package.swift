// swift-tools-version: 5.9
//
// SMeeting Swift SDK —— 二进制分发清单
//
// 本文件由构建脚本自动生成，请勿手工编辑版本号与 checksum。

import PackageDescription

let package = Package(
    name: "smeeting-swift-sdk",
    platforms: [
        // 下限跟随 SRTC：它自 1.4.0 把虚拟背景（onnxruntime）并进产物，下限抬到
        // iOS 16 / macOS 14。SwiftPM 的 platforms 是包级的，依赖方只能等于或高于
        // 被依赖方 —— 这里不同步抬，客户侧直接依赖解析失败。
        // SMeeting 1.2.x 及更早是 iOS 13 / macOS 10.15
        .iOS(.v16),
        .macOS(.v14),
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
        // 1.4.4 保持一致，并且只把 SRTCBroadcastKit 加到 Broadcast Upload Extension
        // 的 target 上——加到 App target 会让一个进程里出现两份同名类型（App 侧的 SRTC
        // 里已静态含有同一份代码），反过来让扩展去链 SRTC/SMeeting 则会把 WebRTC 拉进
        // 只有 50MB 内存上限的扩展进程。
        .package(url: "https://github.com/seastart/srtc-swift-sdk.git", exact: "1.4.4"),
    ],
    targets: [
        // 预编译的 SDK 本体。`import SMeeting` 导入的就是它。
        .binaryTarget(
            name: "SMeeting",
            url: "https://repo.open.seastart.cn/repository/vcs-releases/meeting-swift-sdk-1.3.6.zip",
            checksum: "e9b352262c212ac7792a3449ff921f48daf639f225a2afa5b22ab8b81e20b0b4"
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

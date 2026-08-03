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
        .package(url: "https://github.com/seastart/srtc-swift-sdk.git", exact: "1.0.0"),
    ],
    targets: [
        // 预编译的 SDK 本体。`import SMeeting` 导入的就是它。
        .binaryTarget(
            name: "SMeeting",
            url: "https://repo.open.seastart.cn/repository/vcs-releases/meeting-swift-sdk-1.0.0.zip",
            checksum: "bb0f227074c61b97de4e6df578d67edd0db8e3ed0626733877fb0730a59798d4"
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

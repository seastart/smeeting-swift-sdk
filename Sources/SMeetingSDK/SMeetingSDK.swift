// 这是一个中转 target，本身不含实现。
//
// 它存在的唯一理由：SPM 的 binaryTarget 不能声明 dependencies，而 SMeeting 需要 SRTC。
// 套这一层之后，接入方只要依赖 SMeeting 产品就会自动拿到 SRTC 和 WebRTC。
//
// 业务代码请 `import SMeeting`（会议层）与 `import SRTC`（渲染视图、Track 等类型），
// 不需要 import 本模块。

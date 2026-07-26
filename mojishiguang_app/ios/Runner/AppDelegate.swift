// -----------------------------------------------------------------------------
// AppDelegate - iOS 端平台通道处理
// 为「墨迹时光」Flutter 应用提供：
//   - AI 推理通道（CoreML / ANE）
//   - 设备信息通道（GPU / Neural Engine / 内存等能力检测）
// -----------------------------------------------------------------------------

import UIKit
import Flutter
import CoreML

@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController

        // ============================================================
        // 1. AI 推理通道（CoreML）
        // ============================================================
        let inferenceChannel = FlutterMethodChannel(
            name: "com.qianchang.mojishiguang/inference",
            binaryMessenger: controller.binaryMessenger
        )

        inferenceChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            switch call.method {
            case "runInference":
                guard let args = call.arguments as? [String: Any] else {
                    result(FlutterError(code: "INVALID_ARGS",
                                        message: "参数格式错误",
                                        details: nil))
                    return
                }

                let inputBytes = args["inputBytes"] as? FlutterStandardTypedData
                let width = args["width"] as? Int ?? 0
                let height = args["height"] as? Int ?? 0
                let modelName = args["modelName"] as? String ?? ""

                // TODO: 实际的 CoreML 推理实现
                // 1. 加载 .mlmodelc 编译模型
                // 2. 创建 MLModelProvider
                // 3. 将输入数据转为 CVPixelBuffer
                // 4. 执行 predict 并返回结果

                // 返回空数据（占位）
                result(FlutterStandardTypedData(bytes: Data()))

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // ============================================================
        // 2. 设备信息通道
        // ============================================================
        let deviceChannel = FlutterMethodChannel(
            name: "com.qianchang.mojishiguang/device",
            binaryMessenger: controller.binaryMessenger
        )

        deviceChannel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "getCapabilities":
                // 检测是否支持 Neural Engine（ANE）
                let hasANE: Bool = {
                    if #available(iOS 14.0, *) {
                        // 检查是否有 Apple Neural Engine
                        // A12+ 芯片均包含 ANE
                        return true
                    }
                    return false
                }()

                let physicalMemory = ProcessInfo.processInfo.physicalMemory
                let totalMemoryGB = Double(physicalMemory) / 1_000_000_000.0

                let capabilities: [String: Any] = [
                    "hasGPU": true,
                    "hasNPU": hasANE,
                    "gpuVendor": "apple",
                    "npuType": hasANE ? "neuralEngine" : "none",
                    "maxThreads": ProcessInfo.processInfo.processorCount,
                    "totalMemoryGB": totalMemoryGB,
                    "osType": "ios"
                ]
                result(capabilities)

            case "isHarmonyOS":
                result(false)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

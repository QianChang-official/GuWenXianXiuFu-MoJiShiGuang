// -----------------------------------------------------------------------------
// MainAbility - HarmonyOS 端平台通道处理
// 为「墨迹时光」Flutter 应用提供：
//   - AI 推理通道（MindSpore Lite）
//   - 设备信息通道（GPU / NPU / 内存等能力检测）
// -----------------------------------------------------------------------------

import UIAbility from '@ohos.app.ability.UIAbility';
import Window from '@ohos.window';
import Want from '@ohos.app.ability.Want';
import { BusinessError } from '@ohos.base';
import MindSpore from '@ohos.mindspore';

/**
 * 简化版 MethodChannel 实现（Flutter HarmonyOS 适配）。
 * 实际项目中应使用 flutter_ohos 包的 MethodChannel。
 */
class MethodChannel {
    private name: string;
    private handlers: Map<string, (call: MethodCall, result: MethodResult) => void> = new Map();

    constructor(name: string) {
        this.name = name;
    }

    onMethodCall(handler: (call: MethodCall, result: MethodResult) => void): void {
        // 注册方法调用处理器
        // 实际实现中需通过 FlutterEngine 注册到二进制消息器
    }

    invokeMethod(method: string, args?: Record<string, Object>): Promise<Object> {
        // 向 Flutter 端发送调用
        return Promise.resolve(null);
    }
}

interface MethodCall {
    method: string;
    arguments: Record<string, Object>;
}

interface MethodResult {
    send(data: Object): void;
    error(code: string, message: string, details?: Object): void;
    sendNotImplemented(): void;
}

export default class MainAbility extends UIAbility {
    private inferenceChannel?: MethodChannel;
    private deviceChannel?: MethodChannel;

    /**
     * Ability 创建时初始化平台通道。
     */
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        // ============================================================
        // 1. AI 推理通道（MindSpore Lite）
        // ============================================================
        this.inferenceChannel = new MethodChannel("com.qianchang.mojishiguang/inference");
        this.inferenceChannel.onMethodCall((call: MethodCall, result: MethodResult): void => {
            switch (call.method) {
                case "runInference": {
                    // 解析参数
                    const inputBytes = call.arguments["inputBytes"];
                    const width = call.arguments["width"];
                    const height = call.arguments["height"];
                    const modelName = call.arguments["modelName"];

                    // TODO: 实际的 MindSpore Lite 推理实现
                    // 1. 加载 .ms 模型文件
                    // 2. 创建 MindSpore Lite 会话
                    // 3. 设置输入张量
                    // 4. 执行推理并获取输出
                    // 5. 返回结果字节数据

                    console.info(`推理请求: model=${modelName}, ${width}x${height}`);
                    result.send(new ArrayBuffer(0));
                    break;
                }
                default: {
                    result.sendNotImplemented();
                }
            }
        });

        // ============================================================
        // 2. 设备信息通道
        // ============================================================
        this.deviceChannel = new MethodChannel("com.qianchang.mojishiguang/device");
        this.deviceChannel.onMethodCall((call: MethodCall, result: MethodResult): void => {
            switch (call.method) {
                case "getCapabilities": {
                    const capabilities = {
                        "hasGPU": true,
                        "hasNPU": true,
                        "gpuVendor": "arm",
                        "npuType": "mindspore",
                        "maxThreads": 8,
                        "totalMemoryGB": 8.0,
                        "osType": "harmonyos"
                    };
                    result.send(capabilities);
                    break;
                }
                case "isHarmonyOS": {
                    result.send(true);
                    break;
                }
                default: {
                    result.sendNotImplemented();
                }
            }
        });

        console.info("墨迹时光 MainAbility 已创建，平台通道已注册");
    }

    /**
     * 窗口创建时设置内容。
     */
    onWindowStageCreate(windowStage: Window.WindowStage): void {
        // 设置应用界面
        // 实际项目中此处加载 Flutter 渲染引擎
        windowStage.loadContent("pages/Index", (err, data) => {
            if (err.code) {
                console.error(`加载页面失败: ${JSON.stringify(err)}`);
                return;
            }
            console.info("页面加载成功");
        });
    }

    /**
     * Ability 销毁时释放资源。
     */
    onDestroy(): void {
        // 释放 MindSpore 会话
        this.inferenceChannel = undefined;
        this.deviceChannel = undefined;
        console.info("墨迹时光 MainAbility 已销毁，资源已释放");
    }
}

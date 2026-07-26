// -----------------------------------------------------------------------------
// MainActivity - Android 端平台通道处理
// 为「墨迹时光」Flutter 应用提供：
//   - AI 推理通道（NNAPI / TFLite）
//   - 设备信息通道（GPU/NPU/内存等能力检测）
// -----------------------------------------------------------------------------

package io.github.qianchang.mojishiguang

import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "Mojishiguang"

        // 平台通道名称（需与 Dart 端一致）
        private const val INFERENCE_CHANNEL = "com.qianchang.mojishiguang/inference"
        private const val DEVICE_CHANNEL = "com.qianchang.mojishiguang/device"
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ============================================================
        // 1. AI 推理通道
        // ============================================================
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INFERENCE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "runInference" -> {
                    Log.d(TAG, "收到推理请求: runInference")
                    try {
                        // 解析参数
                        val inputBytes = call.argument<ByteArray>("inputBytes")
                        val width = call.argument<Int>("width") ?: 0
                        val height = call.argument<Int>("height") ?: 0
                        val modelName = call.argument<String>("modelName") ?: ""

                        // TODO: 实际的 NNAPI / TFLite 推理实现
                        // 1. 加载 TFLite 模型
                        // 2. 创建 Interpreter 并配置 NNAPI Delegate
                        // 3. 执行推理
                        // 4. 返回结果

                        Log.d(TAG, "推理参数: model=$modelName, ${width}x$height")

                        // 返回空结果（占位）
                        result.success(byteArrayOf())
                    } catch (e: Exception) {
                        Log.e(TAG, "推理失败", e)
                        result.error("INFERENCE_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // ============================================================
        // 2. 设备信息通道
        // ============================================================
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCapabilities" -> {
                    Log.d(TAG, "查询设备能力")
                    try {
                        val maxMemoryGB = Runtime.getRuntime().maxMemory() / 1_000_000_000.0
                        val cap = mapOf(
                            "hasGPU" to true,
                            "hasNPU" to (Build.VERSION.SDK_INT >= 29),
                            "gpuVendor" to detectGpuVendor(),
                            "npuType" to "nnapi",
                            "maxThreads" to Runtime.getRuntime().availableProcessors(),
                            "totalMemoryGB" to maxMemoryGB,
                            "osType" to "android"
                        )
                        result.success(cap)
                    } catch (e: Exception) {
                        Log.e(TAG, "查询设备能力失败", e)
                        result.error("DEVICE_INFO_ERROR", e.message, null)
                    }
                }
                "isHarmonyOS" -> {
                    // Android 平台始终返回 false
                    result.success(false)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * 检测 GPU 厂商。
     * 通过读取系统属性中的 GPU 渲染信息判断。
     */
    private fun detectGpuVendor(): String {
        return try {
            val renderer = android.opengl.GLES20.glGetString(android.opengl.GLES20.GL_RENDERER)
            when {
                renderer?.contains("Mali") == true -> "mali"
                renderer?.contains("Adreno") == true -> "adreno"
                renderer?.contains("PowerVR") == true -> "powervr"
                else -> "unknown"
            }
        } catch (e: Exception) {
            "unknown"
        }
    }
}

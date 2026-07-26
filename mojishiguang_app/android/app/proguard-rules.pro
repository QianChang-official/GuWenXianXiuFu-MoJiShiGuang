# -----------------------------------------------------------------------------
# ProGuard 规则文件
# 保留「墨迹时光」核心类及 TensorFlow Lite 相关类。
# -----------------------------------------------------------------------------

# 保留应用核心类
-keep class io.github.qianchang.mojishiguang.** { *; }

# 保留 TFLite 模型类
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# 保留 NNAPI Runtime 类
-keep class androidx.neuralnetwork.** { *; }
-dontwarn androidx.neuralnetwork.**

# 保留 ML Kit 类
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Flutter 引擎相关
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

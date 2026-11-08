package com.visioiridis.visioiridis

import android.content.Intent
import android.os.Build
import android.widget.Toast
import com.pravera.flutter_foreground_task.service.ForegroundServiceManager
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private lateinit var overlay: CaptionOverlay

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val overlayChannel = MethodChannel(messenger, CHANNEL)
        // 浮动窗口上的操作交给 Dart 处理（先停止识别，再关闭）。
        overlay = CaptionOverlay(
            applicationContext,
            onSelectSystemAudio = { systemAudio ->
                overlayChannel.invokeMethod(
                    "selectAudioInput",
                    if (systemAudio) "systemAudio" else "microphone"
                )
            },
            onExit = { overlayChannel.invokeMethod("requestExit", null) },
        )
        overlayChannel.setMethodCallHandler(::onCall)
        MethodChannel(messenger, SYSTEM_AUDIO_CHANNEL)
            .setMethodCallHandler(::onSystemAudioCall)
        MethodChannel(messenger, BUNDLED_MODELS_CHANNEL)
            .setMethodCallHandler(::onBundledModelsCall)
        EventChannel(messenger, SYSTEM_AUDIO_PCM_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    SystemAudioBus.onPcm = { events.success(it) }
                    SystemAudioBus.onStopped = { events.endOfStream() }
                }

                override fun onCancel(arguments: Any?) {
                    SystemAudioBus.onPcm = null
                    SystemAudioBus.onStopped = null
                }
            })
    }

    /** 系统音频捕获（PRD 4.8）。 */
    private fun onSystemAudioCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" ->
                result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
            // 弹出系统录制确认框；授权后捕获服务立即启动，返回是否成功。
            "start" -> {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    result.success(false)
                    return
                }
                call.argument<String>("channel")?.let { SystemAudioCaptureService.channelName = it }
                call.argument<String>("title")?.let { SystemAudioCaptureService.notificationTitle = it }
                call.argument<String>("text")?.let { SystemAudioCaptureService.notificationText = it }
                SystemAudioBus.onPermissionResult = { result.success(it) }
                startActivity(
                    Intent(this, ProjectionRequestActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
            }
            "stop" -> {
                stopService(Intent(this, SystemAudioCaptureService::class.java))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDestroy() {
        // Flutter 引擎随 Activity 销毁，识别随之结束：移除浮动窗口，并停止麦克风
        // 前台服务（标记为正常停止，避免插件在任务被划掉后自动重启服务）。
        if (::overlay.isInitialized) overlay.hide()
        stopService(Intent(this, SystemAudioCaptureService::class.java))
        try {
            ForegroundServiceManager().stop(this)
        } catch (_: Exception) {
            // 服务未在运行。
        }
        super.onDestroy()
    }

    /**
     * 内置模型（随 APK 打包的 Flutter asset）以流的方式复制到 [dest]。
     * 模型文件有数百 MB，不能经 rootBundle 读入 Dart 内存。
     */
    private fun onBundledModelsCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "copyAsset") {
            result.notImplemented()
            return
        }
        val asset = call.argument<String>("asset")!!
        val dest = File(call.argument<String>("dest")!!)
        val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
        Thread {
            try {
                dest.parentFile?.mkdirs()
                assets.open(key).use { input ->
                    dest.outputStream().use { output -> input.copyTo(output, 1 shl 20) }
                }
                runOnUiThread { result.success(null) }
            } catch (e: Exception) {
                dest.delete()
                runOnUiThread { result.error("COPY_FAILED", e.message, null) }
            }
        }.start()
    }

    private fun onCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "show" -> {
                overlay.show(
                    CaptionOverlay.Style(
                        heightFraction = call.argument<Double>("heightFraction")!!,
                        background = call.argument<Number>("background")!!.toInt(),
                        focusColor = call.argument<Number>("focusColor")!!.toInt(),
                        historyColor = call.argument<Number>("historyColor")!!.toInt(),
                        focusSize = call.argument<Double>("focusSize")!!.toFloat(),
                        historySize = call.argument<Double>("historySize")!!.toFloat(),
                        historyBold = call.argument<Boolean>("historyBold") ?: false,
                    ),
                    CaptionOverlay.Labels(
                        microphone = call.argument<String>("microphone")!!,
                        speaker = call.argument<String>("speaker")!!,
                        back = call.argument<String>("back")!!,
                        exit = call.argument<String>("exit")!!,
                        confirmExit = call.argument<String>("confirmExit")!!,
                        cancel = call.argument<String>("cancel")!!,
                    ),
                )
                result.success(null)
            }
            "update" -> {
                overlay.update(
                    call.argument<String>("current")!!,
                    call.argument<Boolean>("partial")!!,
                    call.argument<List<String>>("history")!!,
                    call.argument<Boolean>("systemAudio") ?: false,
                )
                result.success(null)
            }
            "hide" -> {
                overlay.hide()
                result.success(null)
            }
            // 关闭 App：结束 Activity 并从最近任务中移除；onDestroy 中清理服务与浮动窗口。
            "exitApp" -> {
                result.success(null)
                finishAndRemoveTask()
            }
            // App 在后台时 SnackBar 不可见，改用系统 Toast 提示。
            "toast" -> {
                Toast.makeText(
                    applicationContext,
                    call.argument<String>("message"),
                    Toast.LENGTH_LONG
                ).show()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        private const val CHANNEL = "visio_iridis/overlay"
        private const val SYSTEM_AUDIO_CHANNEL = "visio_iridis/system_audio"
        private const val SYSTEM_AUDIO_PCM_CHANNEL = "visio_iridis/system_audio/pcm"
        private const val BUNDLED_MODELS_CHANNEL = "visio_iridis/bundled_models"
    }
}

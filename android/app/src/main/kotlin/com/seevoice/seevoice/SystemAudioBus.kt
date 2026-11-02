package com.seevoice.seevoice

import android.os.Handler
import android.os.Looper

/**
 * 系统音频捕获各组件之间的中转：授权结果回传给发起请求的一方，
 * 捕获到的 PCM 数据转发给 Flutter 的 EventChannel（均切回主线程）。
 */
object SystemAudioBus {
    private val main = Handler(Looper.getMainLooper())

    /** 授权完成回调：true 表示已授权且捕获服务已启动。 */
    var onPermissionResult: ((Boolean) -> Unit)? = null

    /** 16kHz / 16bit / 单声道 PCM 数据接收方。 */
    var onPcm: ((ByteArray) -> Unit)? = null

    /** 捕获被系统或用户结束（如在通知栏停止投屏）。 */
    var onStopped: (() -> Unit)? = null

    fun permissionResult(granted: Boolean) = main.post {
        onPermissionResult?.invoke(granted)
        onPermissionResult = null
    }

    fun pcm(bytes: ByteArray) = main.post { onPcm?.invoke(bytes) }

    fun stopped() = main.post { onStopped?.invoke() }
}

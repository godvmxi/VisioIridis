package com.visioiridis.visioiridis

import android.os.Build
import androidx.annotation.RequiresApi
import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle

/**
 * 透明 Activity：弹出系统“开始录制/投屏”确认框，授权后立即启动系统音频捕获服务。
 * 在这里（App 处于前台时）启动 mediaProjection 类型的前台服务，满足 Android 14+ 的要求，
 * 且不会把主界面拉到前台。
 */
@RequiresApi(Build.VERSION_CODES.Q)
class ProjectionRequestActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState != null) return
        val manager = getSystemService(MediaProjectionManager::class.java)
        @Suppress("DEPRECATION")
        startActivityForResult(manager.createScreenCaptureIntent(), REQUEST_CODE)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_CODE) return
        val granted = resultCode == RESULT_OK && data != null
        if (granted) {
            startForegroundService(
                Intent(this, SystemAudioCaptureService::class.java)
                    .putExtra(SystemAudioCaptureService.EXTRA_RESULT_CODE, resultCode)
                    .putExtra(SystemAudioCaptureService.EXTRA_DATA, data)
            )
        }
        SystemAudioBus.permissionResult(granted)
        finish()
        overridePendingTransition(0, 0)
    }

    private companion object {
        const val REQUEST_CODE = 2001
    }
}

package com.seevoice.seevoice

import android.os.Build
import androidx.annotation.RequiresApi
import android.Manifest
import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log

/**
 * 捕获系统播放的声音（PRD 4.8）：MediaProjection + AudioPlaybackCapture，
 * 输出 16kHz / 16bit / 单声道 PCM 到 [SystemAudioBus]。
 *
 * 系统限制：只能捕获用途为媒体、游戏或未知的声音，且对方 App 允许被捕获；
 * 电话与网络通话（VOICE_COMMUNICATION）的声音无法捕获。
 */
@RequiresApi(Build.VERSION_CODES.Q)
class SystemAudioCaptureService : Service() {
    private var projection: MediaProjection? = null
    private var record: AudioRecord? = null
    private var reader: Thread? = null
    @Volatile private var running = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(
            NOTIFICATION_ID,
            buildNotification(),
            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
        )
        val resultCode = intent?.getIntExtra(EXTRA_RESULT_CODE, 0) ?: 0
        @Suppress("DEPRECATION")
        val data: Intent? = intent?.getParcelableExtra(EXTRA_DATA)
        if (data == null || projection != null) return START_NOT_STICKY

        try {
            startCapture(resultCode, data)
        } catch (e: Exception) {
            Log.e(TAG, "system audio capture failed", e)
            stopSelf()
        }
        return START_NOT_STICKY
    }

    @SuppressLint("MissingPermission")
    private fun startCapture(resultCode: Int, data: Intent) {
        check(checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED) { "缺少录音权限" }

        val manager = getSystemService(MediaProjectionManager::class.java)
        val mp = manager.getMediaProjection(resultCode, data)
            ?: error("无法获取录制授权")
        // Android 14+ 要求在使用前注册回调；用户在通知栏或系统界面结束投屏时停止捕获。
        mp.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                stopSelf()
            }
        }, Handler(Looper.getMainLooper()))
        projection = mp

        val config = AudioPlaybackCaptureConfiguration.Builder(mp)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .addMatchingUsage(AudioAttributes.USAGE_GAME)
            .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
            .build()
        val format = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(SAMPLE_RATE)
            .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
            .build()
        val minBuffer = AudioRecord.getMinBufferSize(
            SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
        )
        val ar = AudioRecord.Builder()
            .setAudioFormat(format)
            .setBufferSizeInBytes(maxOf(minBuffer, CHUNK_BYTES * 4))
            .setAudioPlaybackCaptureConfig(config)
            .build()
        record = ar
        ar.startRecording()

        running = true
        reader = Thread({
            val buffer = ByteArray(CHUNK_BYTES)
            while (running) {
                val n = ar.read(buffer, 0, buffer.size)
                if (n > 0) SystemAudioBus.pcm(buffer.copyOf(n))
            }
        }, "system-audio-capture").apply { start() }
    }

    override fun onDestroy() {
        running = false
        reader?.join(500)
        record?.run {
            try { stop() } catch (_: Exception) {}
            release()
        }
        record = null
        projection?.stop()
        projection = null
        SystemAudioBus.stopped()
        super.onDestroy()
    }

    private fun buildNotification(): Notification {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "系统声音字幕", NotificationManager.IMPORTANCE_LOW)
        )
        val open = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT),
            PendingIntent.FLAG_IMMUTABLE
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("正在识别系统播放的声音")
            .setContentText("点击返回 App")
            .setContentIntent(open)
            .setOngoing(true)
            .build()
    }

    companion object {
        const val EXTRA_RESULT_CODE = "resultCode"
        const val EXTRA_DATA = "data"
        private const val TAG = "SystemAudioCapture"
        private const val CHANNEL_ID = "system_audio"
        private const val NOTIFICATION_ID = 2002
        private const val SAMPLE_RATE = 16000

        /** 100ms 一块：16000 采样/秒 × 2 字节 × 0.1 秒。 */
        private const val CHUNK_BYTES = 3200
    }
}

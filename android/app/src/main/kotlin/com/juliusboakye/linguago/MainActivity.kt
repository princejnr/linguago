package com.juliusboakye.linguago

import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.juliusboakye.linguago/voip_detector_methods"
    private val EVENT_CHANNEL = "com.juliusboakye.linguago/voip_detector_events"

    private var eventSink: EventChannel.EventSink? = null
    private var lastMode: Int = AudioManager.MODE_NORMAL
    private val handler = Handler(Looper.getMainLooper())
    private var isPolling = false

    private val pollRunnable = object : Runnable {
        override fun run() {
            checkAudioMode()
            if (isPolling) {
                handler.postDelayed(this, 1500)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isVoipActive" -> {
                    val mode = audioManager.mode
                    result.success(mode == AudioManager.MODE_IN_COMMUNICATION)
                }
                "getAudioMode" -> {
                    result.success(audioManager.mode)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    lastMode = audioManager.mode

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            audioManager.addOnModeChangedListener(mainExecutor) { mode ->
                                notifyModeChange(mode)
                            }
                        } catch (e: Exception) {
                            // Fallback to polling if listener registration fails
                        }
                    }

                    // Periodic polling to catch transitions across all Android versions
                    isPolling = true
                    handler.post(pollRunnable)
                }

                override fun onCancel(arguments: Any?) {
                    isPolling = false
                    handler.removeCallbacks(pollRunnable)
                    eventSink = null
                }
            }
        )
    }

    private fun checkAudioMode() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val currentMode = audioManager.mode
        if (currentMode != lastMode) {
            notifyModeChange(currentMode)
        }
    }

    private fun notifyModeChange(mode: Int) {
        lastMode = mode
        val isVoip = (mode == AudioManager.MODE_IN_COMMUNICATION)
        val payload = mapOf(
            "isVoip" to isVoip,
            "mode" to mode,
            "timestamp" to System.currentTimeMillis()
        )
        runOnUiThread {
            eventSink?.success(payload)
        }
    }
}

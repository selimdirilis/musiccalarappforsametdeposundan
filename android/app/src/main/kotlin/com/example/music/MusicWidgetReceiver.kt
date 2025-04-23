package com.example.music

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MusicWidgetReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d("MY_WIDGET", "👉 onReceive tetiklendi, gelen action: $action")
        if (action == null) {
            Log.w("MusicWidgetReceiver", "Alınan intent'in action'u null.")
            return
        }

        when (action) {
            "PLAY" -> {
                sendToFlutter("play")
            }
            "NEXT" -> {
                sendToFlutter("next")
            }
            else -> {
                Log.w("MusicWidgetReceiver", "Bilinmeyen action: $action")
            }
        }
    }

    private fun sendToFlutter(action: String) {
        val engine = FlutterEngineCache.getInstance().get("my_engine_id")
        if (engine == null) {
            Log.e("MY_WIDGET", "❌ FlutterEngine NULL, mesaj iletilemedi.")
            return
        }

        Log.d("MY_WIDGET", "✅ FlutterEngine bulundu, $action gönderiliyor.")
        MethodChannel(engine.dartExecutor.binaryMessenger, "music_widget_channel")
            .invokeMethod(action, null)
    }

}

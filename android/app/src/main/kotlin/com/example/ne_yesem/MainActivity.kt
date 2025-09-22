package com.example.ne_yesem

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ne_yesem/assistant"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "handleGoogleAssistantIntent" -> {
                    handleGoogleAssistantIntent(call.arguments as? Map<String, Any>, result)
                }
                "setupAppShortcuts" -> {
                    setupAppShortcuts(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle app shortcuts
        handleShortcutIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleShortcutIntent(intent)
    }

    private fun handleShortcutIntent(intent: Intent?) {
        intent?.let {
            val shortcutId = it.getStringExtra("shortcut_id")
            shortcutId?.let { id ->
                val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                val args = mapOf(
                    "shortcutId" to id,
                    "action" to it.action
                )
                channel.invokeMethod("handleAppShortcut", args)
            }
        }
    }

    private fun handleGoogleAssistantIntent(arguments: Map<String, Any>?, result: MethodChannel.Result) {
        val action = arguments?.get("action") as? String ?: ""
        val parameters = arguments?.get("parameters") as? Map<String, Any> ?: emptyMap()
        
        val response = mapOf(
            "type" to "success",
            "message" to "Google Assistant intent handled: $action",
            "data" to parameters
        )
        
        result.success(response)
    }

    private fun setupAppShortcuts(result: MethodChannel.Result) {
        // Android app shortcuts are typically defined in XML
        // This would integrate with ShortcutManager for dynamic shortcuts
        result.success(true)
    }
}
package com.astuto.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /// The widget whose tap opened the app, until Dart asks for it.
    private var widgetOpen: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        noteWidget(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        noteWidget(intent)
    }

    private fun noteWidget(intent: Intent?) {
        val from = intent?.getStringExtra(AstutWidget.EXTRA_FROM) ?: return
        widgetOpen = from
        // Said once: a recreated activity must not report the same tap again.
        intent.removeExtra(AstutWidget.EXTRA_FROM)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The home-screen widgets cannot run Dart, so the app hands them what
        // they will need — today's question and the question for each of the
        // next fourteen mornings, the streak and the week, today's five and
        // tomorrow's — and asks them all to redraw. It also asks which
        // widgets are placed, and which one opened the app, for measurement.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "astut/widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        val data = call.arguments as? Map<*, *>
                        if (data == null) {
                            result.error("bad_args", "expected a map", null)
                        } else {
                            AstutWidget.store(this, data)
                            AstutWidget.refreshAll(this)
                            result.success(null)
                        }
                    }
                    "installed" -> result.success(AstutWidget.installed(this))
                    "takeOpenedFrom" -> {
                        result.success(widgetOpen)
                        widgetOpen = null
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

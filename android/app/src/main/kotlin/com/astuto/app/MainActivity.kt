package com.astuto.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The home-screen widgets cannot run Dart, so the app hands them what
        // they will need — today's question and the question for each of the
        // next fourteen mornings, the streak and the week, today's five and
        // tomorrow's — and asks them all to redraw.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "astut/widget")
            .setMethodCallHandler { call, result ->
                if (call.method != "update") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val data = call.arguments as? Map<*, *>
                if (data == null) {
                    result.error("bad_args", "expected a map", null)
                    return@setMethodCallHandler
                }
                AstutWidget.store(this, data)
                AstutWidget.refreshAll(this)
                result.success(null)
            }
    }
}

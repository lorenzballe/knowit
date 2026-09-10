package com.astuto.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The home-screen widget cannot run Dart, so the app hands it what
        // it will need — today's question, the streak, and the question for
        // each of the next fourteen mornings — and asks it to redraw.
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
                val manager = AppWidgetManager.getInstance(this)
                val ids = manager.getAppWidgetIds(ComponentName(this, AstutWidget::class.java))
                AstutWidget.render(this, manager, ids)
                result.success(null)
            }
    }
}

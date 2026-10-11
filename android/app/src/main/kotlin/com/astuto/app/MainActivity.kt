package com.astuto.app

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /// The widget whose tap opened the app, and the card it named, until
    /// Dart asks for it: "from", and for a card "card" and "in".
    private var widgetOpen: Map<String, String>? = null

    /// The channel the app listens on, to be told a tap has come in.
    private var widgetChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        noteWidget(intent)
    }

    /// A tap on a widget while the app is running: the activity is
    /// single-top, so the tap arrives here rather than as a second app.
    /// Dart is told at once, as well as asking on coming back to the
    /// foreground; whichever asks first takes it.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (noteWidget(intent)) widgetChannel?.invokeMethod("opened", null)
    }

    private fun noteWidget(intent: Intent?): Boolean {
        val from = intent?.getStringExtra(AstutWidget.EXTRA_FROM) ?: return false
        val open = mutableMapOf("from" to from)
        intent.getStringExtra(AstutWidget.EXTRA_CARD)?.let { open["card"] = it }
        intent.getStringExtra(AstutWidget.EXTRA_IN)?.let { open["in"] = it }
        widgetOpen = open
        // Said once: a recreated activity must not report the same tap again.
        intent.removeExtra(AstutWidget.EXTRA_FROM)
        intent.removeExtra(AstutWidget.EXTRA_CARD)
        intent.removeExtra(AstutWidget.EXTRA_IN)
        return true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The home-screen widgets cannot run Dart, so the app hands them what
        // they will need — today's cards and today's shelf, and the same for
        // each of the next fourteen mornings, the streak and the week — and
        // asks them all to redraw. It also asks which widgets are placed, and
        // which one opened the app and on which card, so it can open it.
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "astut/widget")
        channel.setMethodCallHandler { call, result ->
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
        widgetChannel = channel

        // Where this install came from, for measurement (lib/measure/
        // install.dart): which app installed it — Google Play, or something
        // else — and whether the phone is one of Firebase Test Lab's, which
        // is where Google Play's pre-launch robots run. The same channel an
        // iPhone answers TestFlight on.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "astut/install")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installSource" -> result.success(
                        mapOf("installer" to installer(), "testLab" to inTestLab())
                    )
                    else -> result.notImplemented()
                }
            }
    }

    /// The package that installed the app: com.android.vending for Google
    /// Play, another store's, or null for an install by hand.
    private fun installer(): String? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            packageManager.getInstallSourceInfo(packageName).installingPackageName
        } else {
            installerBeforeR()
        }
    } catch (e: Exception) {
        null
    }

    /// The same, asked the only way a phone older than Android 11 knows.
    @Suppress("DEPRECATION")
    private fun installerBeforeR(): String? =
        packageManager.getInstallerPackageName(packageName)

    /// Firebase Test Lab marks its phones with this setting, and the Play
    /// pre-launch report's robots run there.
    private fun inTestLab(): Boolean = try {
        Settings.System.getString(contentResolver, "firebase.test.lab") == "true"
    } catch (e: Exception) {
        false
    }
}

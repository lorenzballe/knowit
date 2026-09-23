package com.astuto.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Locale

/// Today's five on the home screen, in their colours and in the order
/// they are read: a card read is solid with a tick, a card still to read
/// is its colour, faint, with a ring. Above them, how far the day has got.
///
/// At midnight it turns to the new day's five, all still to read — dealt
/// by the app the night before and written down with today's.
class AstutFiveWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    companion object {
        private class Card(val topic: String, val color: Int, val ink: Int, val read: Boolean)

        private const val CREAM = 0xFFF2F1EC.toInt()
        private const val TITLE = 0x9EF2F1EC.toInt()
        private const val LINE = 0xC7F2F1EC.toInt()
        private const val LABEL_OPEN = 0xE0F2F1EC.toInt()

        private val FILLS = intArrayOf(R.id.five_fill_0, R.id.five_fill_1, R.id.five_fill_2, R.id.five_fill_3, R.id.five_fill_4)
        private val RINGS = intArrayOf(R.id.five_ring_0, R.id.five_ring_1, R.id.five_ring_2, R.id.five_ring_3, R.id.five_ring_4)
        private val CHECKS = intArrayOf(R.id.five_check_0, R.id.five_check_1, R.id.five_check_2, R.id.five_check_3, R.id.five_check_4)
        private val LABELS = intArrayOf(R.id.five_label_0, R.id.five_label_1, R.id.five_label_2, R.id.five_label_3, R.id.five_label_4)

        fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val prefs = context.getSharedPreferences(AstutWidget.PREFS, Context.MODE_PRIVATE)
            val stored = prefs.getString("date", "") ?: ""
            fun text(key: String) = prefs.getString(key, "") ?: ""

            val gap = AstutWidget.daysBetween(stored, AstutWidget.todayKey())
            val cards: List<Card>
            val line: String
            when {
                stored.isEmpty() || !prefs.contains("fiveJson") -> {
                    cards = emptyList()
                    line = context.getString(R.string.widget_five_open)
                }
                gap <= 0 -> {
                    cards = parseCards(text("fiveJson"))
                    val read = cards.count { it.read }
                    line = if (read == cards.size && read > 0) text("fiveDone") else text("fiveReadText")
                }
                gap == 1 -> {
                    cards = parseCards(text("fiveTomorrowJson"))
                    line = text("fiveWaiting")
                }
                else -> {
                    cards = emptyList()
                    line = text("fiveWaiting")
                }
            }
            val title = if (stored.isEmpty()) "ASTUTE" else text("fiveTitle").ifEmpty { "ASTUTE" }
            val count = if (cards.isEmpty()) "" else "${cards.count { it.read }}/${cards.size}"

            val pending = AstutWidget.openApp(context)
            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.astut_five_widget)
                views.setTextViewText(R.id.five_title, title)
                views.setTextColor(R.id.five_title, TITLE)
                views.setTextViewText(R.id.five_count, count)
                views.setTextColor(R.id.five_count, CREAM)
                views.setTextViewText(R.id.five_line, line)
                views.setTextColor(R.id.five_line, LINE)
                views.setViewVisibility(R.id.five_row, if (cards.isEmpty()) View.INVISIBLE else View.VISIBLE)
                for (i in 0 until 5) {
                    val card = cards.getOrNull(i)
                    val shown = if (card == null) View.GONE else View.VISIBLE
                    views.setViewVisibility(FILLS[i], shown)
                    views.setViewVisibility(LABELS[i], shown)
                    if (card == null) {
                        views.setViewVisibility(RINGS[i], View.GONE)
                        views.setViewVisibility(CHECKS[i], View.GONE)
                        continue
                    }
                    views.setInt(FILLS[i], "setColorFilter", card.color)
                    views.setInt(FILLS[i], "setImageAlpha", if (card.read) 255 else 51)
                    views.setViewVisibility(RINGS[i], if (card.read) View.GONE else View.VISIBLE)
                    views.setInt(RINGS[i], "setColorFilter", card.color)
                    views.setInt(RINGS[i], "setImageAlpha", 191)
                    views.setViewVisibility(CHECKS[i], if (card.read) View.VISIBLE else View.GONE)
                    views.setTextColor(CHECKS[i], card.ink)
                    views.setTextViewText(LABELS[i], card.topic.uppercase(Locale.getDefault()))
                    views.setTextColor(
                        LABELS[i],
                        if (card.read) (card.ink and 0x00FFFFFF) or (0xD9 shl 24) else LABEL_OPEN,
                    )
                }
                views.setOnClickPendingIntent(R.id.five_root, pending)
                manager.updateAppWidget(id, views)
            }
        }

        /// The five as the app writes them: a JSON list of
        /// {topic, color, ink, read}.
        private fun parseCards(json: String): List<Card> = try {
            val list = JSONArray(json)
            List(list.length()) {
                val card = list.getJSONObject(it)
                Card(
                    topic = card.optString("topic", ""),
                    color = AstutWidget.parse(card.optString("color", ""), CREAM),
                    ink = AstutWidget.parse(card.optString("ink", ""), Color.BLACK),
                    read = card.optBoolean("read", false),
                )
            }.take(5)
        } catch (e: Exception) {
            emptyList()
        }
    }
}

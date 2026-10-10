package com.astuto.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import java.util.Locale

/// Today's shelf on the home screen: two cards from the top of Explore,
/// the same for everybody and only today, each on its subject's colour
/// with its question, and each opening itself in Explore. The shelf turns
/// to its next two every third hour, so it is not the same pair all day.
///
/// Everything it shows was written down by the app the last time it ran,
/// today's shelf and the next fortnight's, so it turns over at midnight
/// whether or not the app is opened.
class AstutShelfWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    companion object {
        private const val TITLE = 0x9EF2F1EC.toInt()

        private val CARDS = intArrayOf(R.id.shelf_card_0, R.id.shelf_card_1)
        private val GROUNDS = intArrayOf(R.id.shelf_ground_0, R.id.shelf_ground_1)
        private val TOPICS = intArrayOf(R.id.shelf_topic_0, R.id.shelf_topic_1)
        private val QUESTIONS = intArrayOf(R.id.shelf_question_0, R.id.shelf_question_1)

        fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val prefs = context.getSharedPreferences(AstutWidget.PREFS, Context.MODE_PRIVATE)
            val shelf = AstutWidget.shelfOn(prefs, AstutWidget.todayKey())
            val shown = window(shelf, AstutWidget.turnOfDay(), CARDS.size)
            val title = (prefs.getString("shelfTitle", "") ?: "").ifEmpty {
                context.getString(R.string.widget_shelf_label).uppercase(Locale.getDefault())
            }

            // Between the cards, Explore, where the shelf is.
            val pending = AstutWidget.openApp(
                context, AstutWidget.CODE_SHELF + CARDS.size, "shelf.home",
                null, AstutWidget.PLACE_SHELF,
            )
            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.astut_shelf_widget)
                views.setTextViewText(R.id.shelf_title, title)
                views.setTextColor(R.id.shelf_title, TITLE)
                views.setViewVisibility(R.id.shelf_row, if (shown.isEmpty()) View.GONE else View.VISIBLE)
                views.setViewVisibility(R.id.shelf_empty, if (shown.isEmpty()) View.VISIBLE else View.GONE)
                views.setTextViewText(R.id.shelf_empty, context.getString(R.string.widget_shelf_open))
                for (i in CARDS.indices) {
                    val card = shown.getOrNull(i)
                    if (card == null) {
                        views.setViewVisibility(CARDS[i], View.INVISIBLE)
                        continue
                    }
                    views.setViewVisibility(CARDS[i], View.VISIBLE)
                    views.setInt(GROUNDS[i], "setColorFilter", card.color)
                    views.setTextViewText(TOPICS[i], card.topic.uppercase(Locale.getDefault()))
                    views.setTextColor(TOPICS[i], (card.ink and 0x00FFFFFF) or (0xB8 shl 24))
                    views.setTextViewText(QUESTIONS[i], card.question)
                    views.setTextColor(QUESTIONS[i], card.ink)
                    views.setOnClickPendingIntent(
                        CARDS[i],
                        AstutWidget.openApp(
                            context, AstutWidget.CODE_SHELF + i, "shelf.home",
                            card.id, AstutWidget.PLACE_SHELF,
                        ),
                    )
                }
                views.setOnClickPendingIntent(R.id.shelf_root, pending)
                manager.updateAppWidget(id, views)
            }
        }

        /// [count] cards of [shelf] for the [turn]th turn of the day,
        /// wrapping round the shelf.
        private fun window(shelf: List<WidgetCard>, turn: Int, count: Int): List<WidgetCard> {
            if (shelf.isEmpty() || count <= 0) return emptyList()
            val n = minOf(count, shelf.size)
            val start = (turn * n) % shelf.size
            return List(n) { shelf[(start + it) % shelf.size] }
        }
    }
}

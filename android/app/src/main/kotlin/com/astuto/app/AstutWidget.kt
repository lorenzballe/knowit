package com.astuto.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

/// The next card to read today, on the home screen — drawn the way the app
/// draws a card: the subject's colour for a ground, the subject as an
/// eyebrow, the question set large, and a foot with the streak. Once the
/// five are read, a card of today's shelf, turning over every third hour,
/// and the foot says where it is from.
///
/// Everything it shows was written down by the app the last time it ran:
/// the widget reads it back and picks the card for today's date, so it
/// turns over at midnight whether or not the app is opened. Tapping it
/// opens that very card in the app.
class AstutWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        render(context, manager, ids)
    }

    companion object {
        internal const val PREFS = "astut_widget"
        private const val PAPER = 0xFF141416.toInt()

        /// Keeps what the app handed over, all of it, for all four widgets:
        /// words and numbers as they come, and each day of a calendar map
        /// under its own key.
        fun store(context: Context, data: Map<*, *>) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            prefs.clear()
            for ((key, value) in data) {
                if (key !is String) continue
                when (value) {
                    is String -> prefs.putString(key, value)
                    is Boolean -> prefs.putBoolean(key, value)
                    is Number -> prefs.putInt(key, value.toInt())
                    is Map<*, *> -> value.forEach { (day, line) ->
                        if (day is String && line is String) prefs.putString("${key}_$day", line)
                    }
                }
            }
            prefs.apply()
        }

        /// Redraws every widget of Astute on the home screen.
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            fun ids(provider: Class<*>) = manager.getAppWidgetIds(ComponentName(context, provider))
            render(context, manager, ids(AstutWidget::class.java))
            AstutStreakWidget.render(context, manager, ids(AstutStreakWidget::class.java))
            AstutFiveWidget.render(context, manager, ids(AstutFiveWidget::class.java))
            AstutShelfWidget.render(context, manager, ids(AstutShelfWidget::class.java))
        }

        /// Draws every instance of the widget from what is stored.
        fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
            if (ids.isEmpty()) return
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val today = todayKey()
            val stored = prefs.getString("date", "") ?: ""
            val sameDay = stored == today
            fun text(key: String) = prefs.getString(key, "") ?: ""
            fun today(key: String, aheadMap: String): String {
                val own = text(key)
                // Today's own line while the app has seen today; otherwise
                // the calendar's line for this date, handed over in advance.
                return if (sameDay) own else prefs.getString("${aheadMap}_$today", null) ?: own
            }
            val edition = prefs.getInt("edition", 0) + daysBetween(stored, today)
            val streak = prefs.getInt("streak", 0)
            val done = sameDay && prefs.getBoolean("done", false)
            // The five read, the widget turns to today's shelf.
            val shelf = if (done) shelfOn(prefs, today) else emptyList()

            val topic: String
            val question: String
            val color: Int
            val ink: Int
            val card: String
            val place: String
            val foot: String
            if (shelf.isNotEmpty()) {
                val on = shelf[turnOfDay() % shelf.size]
                topic = on.topic
                question = on.question
                color = on.color
                ink = on.ink
                card = on.id
                place = PLACE_SHELF
                foot = "◎ " + text("shelfFrom")
            } else {
                topic = today("topic", "aheadTopic")
                question = today("question", "ahead")
                color = parse(today("color", "aheadColor"), PAPER)
                ink = parse(today("ink", "aheadInk"), Color.WHITE)
                card = today("cardId", "aheadId")
                place = PLACE_TODAY
                // The streak is only known for the day the app last saw; a
                // later morning says what the day is, not what it did.
                foot = when {
                    !sameDay -> text("footPlain")
                    done -> "✓ " + text("footDone")
                    streak > 0 -> "● " + text("footStreak")
                    else -> text("footPlain")
                }
            }
            val eyebrow = if (topic.isEmpty()) "ASTUTE" else "✦ " + topic.uppercase(Locale.getDefault())
            val dim = (ink and 0x00FFFFFF) or (0xB8 shl 24)
            val faint = (ink and 0x00FFFFFF) or (0xC7 shl 24)

            val pending = openApp(context, CODE_CARD, "card.home", card, place)
            val empty = context.getString(R.string.widget_card_empty)
            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.astut_widget)
                views.setInt(R.id.widget_bg, "setColorFilter", color)
                views.setTextViewText(R.id.widget_eyebrow, eyebrow)
                views.setTextColor(R.id.widget_eyebrow, dim)
                views.setTextViewText(R.id.widget_edition, if (edition > 0) "#$edition" else "")
                views.setTextColor(R.id.widget_edition, dim)
                views.setTextViewText(R.id.widget_question, question.ifEmpty { empty })
                views.setTextColor(R.id.widget_question, ink)
                views.setTextViewText(R.id.widget_foot, foot)
                views.setTextColor(R.id.widget_foot, faint)
                views.setOnClickPendingIntent(R.id.widget_root, pending)
                manager.updateAppWidget(id, views)
            }
        }

        /// The extras that name the widget a tap came from, the card it
        /// landed on, and where that card lives: [PLACE_TODAY] or
        /// [PLACE_SHELF].
        internal const val EXTRA_FROM = "astut_widget_from"
        internal const val EXTRA_CARD = "astut_widget_card"
        internal const val EXTRA_IN = "astut_widget_in"

        /// One of today's five, opened on Today.
        internal const val PLACE_TODAY = "today"

        /// A card of today's shelf, opened in Explore.
        internal const val PLACE_SHELF = "shelf"

        /// A request code for every place on a widget that can be tapped.
        /// Two pending intents for the same activity with the same code are
        /// one intent, and the last one made would carry its card into all
        /// of them.
        internal const val CODE_CARD = 100
        internal const val CODE_FIVE = 200
        internal const val CODE_SHELF = 300
        internal const val CODE_STREAK = 400

        /// Tapping a widget opens the app, saying which widget it was and,
        /// on a card, which card and where it lives, so the app opens it.
        internal fun openApp(
            context: Context,
            code: Int,
            from: String,
            card: String? = null,
            place: String? = null,
        ): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).putExtra(EXTRA_FROM, from)
            if (!card.isNullOrEmpty()) intent.putExtra(EXTRA_CARD, card)
            if (!place.isNullOrEmpty()) intent.putExtra(EXTRA_IN, place)
            return PendingIntent.getActivity(
                context,
                code,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        /// The widgets placed on the home screen, as "kind.home", one entry
        /// per widget.
        fun installed(context: Context): List<String> {
            val manager = AppWidgetManager.getInstance(context)
            fun count(provider: Class<*>) =
                manager.getAppWidgetIds(ComponentName(context, provider)).size
            return List(count(AstutWidget::class.java)) { "card.home" } +
                List(count(AstutStreakWidget::class.java)) { "streak.home" } +
                List(count(AstutFiveWidget::class.java)) { "five.home" } +
                List(count(AstutShelfWidget::class.java)) { "shelf.home" }
        }

        /// Today's shelf on [day], as the app handed it over: the cards at
        /// the top of Explore the reader has not read.
        internal fun shelfOn(prefs: SharedPreferences, day: String): List<WidgetCard> =
            WidgetCard.list(prefs.getString("shelf_$day", "") ?: "", PAPER, Color.WHITE)

        /// Which third of a day's eight it is: the shelf turns to its next
        /// card every third hour, so a widget showing it is not the same
        /// card all day.
        internal fun turnOfDay(): Int = Calendar.getInstance().get(Calendar.HOUR_OF_DAY) / 3

        internal fun todayKey(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

        /// "#RRGGBB" as the app writes it, or the fallback when it did not.
        internal fun parse(hex: String, fallback: Int): Int {
            val s = hex.trim()
            if (s.length != 7 || !s.startsWith("#")) return fallback
            return try {
                Color.parseColor(s)
            } catch (e: IllegalArgumentException) {
                fallback
            }
        }

        /// Whole days from one date to another. Rounded, not cut: the day the
        /// clocks go forward is 23 hours long, and still a day.
        internal fun daysBetween(from: String, to: String): Int {
            if (from.isEmpty()) return 0
            return try {
                val format = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                val a = format.parse(from)?.time ?: return 0
                val b = format.parse(to)?.time ?: return 0
                ((b - a) / 86_400_000.0).roundToInt()
            } catch (e: Exception) {
                0
            }
        }
    }
}

/// A card as the app hands it over: its id, subject, colours and question,
/// and whether it has been read.
internal class WidgetCard(
    val id: String,
    val topic: String,
    val color: Int,
    val ink: Int,
    val question: String,
    val read: Boolean,
) {
    companion object {
        /// A JSON list of cards, as the app writes them, with the colours to
        /// fall back on where one is missing.
        fun list(json: String, color: Int, ink: Int): List<WidgetCard> = try {
            val list = JSONArray(json)
            List(list.length()) {
                val card = list.getJSONObject(it)
                WidgetCard(
                    id = card.optString("id", ""),
                    topic = card.optString("topic", ""),
                    color = AstutWidget.parse(card.optString("color", ""), color),
                    ink = AstutWidget.parse(card.optString("ink", ""), ink),
                    question = card.optString("question", ""),
                    read = card.optBoolean("read", false),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
}

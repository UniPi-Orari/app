package it.unipiorario.app.glance

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import HomeWidgetGlanceWidgetReceiver
import android.content.Context
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import it.unipiorario.app.MainActivity
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.WorkManager

class HomeWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*>
        get() = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            ContentWrapper(currentState())
        }
    }

    @Composable
    fun ContentWrapper(currentState: HomeWidgetGlanceState) {
        val prefs = currentState.preferences
        val data = prefs.getString("lessonWidget", "{}") as String

        val parsedData = parseSchedule(data)
        Log.d("HomeWidget", "Parsed data: $parsedData")

        parsedData.takeIf { it.isEmpty() }?.let {
            EmptyView()
        } ?: LessonsView(parsedData)
    }

    @Composable
    fun EmptyView() {
        GlanceTheme {
            Column(
                modifier = GlanceModifier
                    .background(GlanceTheme.colors.widgetBackground)
                    .cornerRadius(8.dp)
                    .fillMaxSize(),

                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically

            ) {
                Text(
                    text = "(◎-◎；)?",
                    style = TextStyle(
                        color = GlanceTheme.colors.primary,
                        fontSize = 40.sp,
                        fontWeight = FontWeight.Medium

                    )
                )
                Text(
                    text = "Nessuna lezione",
                    style = TextStyle(
                        color = GlanceTheme.colors.primary,
                        fontSize = 19.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
            }
            Box(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .clickable(actionStartActivity<MainActivity>()),

                contentAlignment = Alignment.BottomCenter
            ) {
                Text(
                    text = "Clicca per aprire l'app",
                    modifier = GlanceModifier.padding(bottom = 8.dp),
                    style = TextStyle(
                        color = GlanceTheme.colors.secondary,
                        fontSize = 13.sp
                    )
                )
            }
        }
    }

    @Composable
    fun LessonsView(lessons: List<DaySchedule>) {
        GlanceTheme{
            Column(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(GlanceTheme.colors.widgetBackground)
                    .padding(8.dp)
                    .cornerRadius(8.dp)
            ) {
                LazyColumn{
                    items(lessons) { day ->
                        DaySection(day)
                    }
                }
            }
        }
    }

    private fun getDayString(day: String): String {
        val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
        val date = LocalDate.parse(day, formatter)
        val pattern = "EEEE, d".let {
            if (date.dayOfMonth != 1) it else it.plus(" MMM")
        }

        return date.format(DateTimeFormatter.ofPattern(pattern, Locale.ITALIAN))
            .replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }
    }

    @Composable
    fun DaySection(daySchedule: DaySchedule) {
        Column(
            modifier = GlanceModifier.padding(vertical = 4.dp)
        ) {
            Text(
                text = getDayString(daySchedule.date),
                style = TextStyle(
                    fontWeight = FontWeight.Bold,
                    color = GlanceTheme.colors.primary,
                    fontSize = 19.sp
                ),
                modifier = GlanceModifier.padding(bottom = 4.dp)
            )
            daySchedule.lessons.forEach { lesson ->
                LessonRow(lesson)
                Spacer(modifier = GlanceModifier.height(4.dp))
            }
        }
    }

    @Composable
    fun LessonRow(lesson: Lesson) {
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(GlanceTheme.colors.secondaryContainer)
                .cornerRadius(8.dp)
                .clickable(actionStartActivity<MainActivity>())
                .padding(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = GlanceModifier
                    .size(35.dp)
                    .background(GlanceTheme.colors.primary)
                    .cornerRadius(360.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = lesson.roomName.replace("Fib ", ""),
                    modifier = GlanceModifier,
                    style = TextStyle(
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = GlanceTheme.colors.onPrimary
                    )
                )
            }

            Spacer(modifier = GlanceModifier.width(9.dp))

            Column {
                Text(
                    text = lesson.startDateTime.format(
                        DateTimeFormatter.ofPattern("HH:mm")
                    ),
                    style = TextStyle(
                        color = GlanceTheme.colors.secondary,
                        fontSize = 13.sp
                    )
                )
                Text(
                    text = lesson.endDateTime.format(
                        DateTimeFormatter.ofPattern("HH:mm")
                    ),
                    style = TextStyle(
                        color = GlanceTheme.colors.secondary,
                        fontSize = 13.sp
                    )
                )
            }

            Spacer(modifier = GlanceModifier.width(8.dp))

            Column {
                Text(
                    text = lesson.name,
                    maxLines = 1,
                    style = TextStyle(
                        color = GlanceTheme.colors.primary,
                        fontWeight = FontWeight.Bold,
                    )
                )
                Text(
                    text = lesson.courseName.takeUnless { it == "null" } ?: "Nessun corso",
                    maxLines = 1,
                    style = TextStyle(
                        color = GlanceTheme.colors.secondary,
                    )
                )
            }

            Spacer(
                modifier = GlanceModifier.defaultWeight()
            )

        }
    }
}


class HomeWidgetReceiver : HomeWidgetGlanceWidgetReceiver<HomeWidget>() {
    override val glanceAppWidget = HomeWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        // Schedule periodic updates when the widget is first added
        schedulePeriodicUpdates(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: android.appwidget.AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        // Ensure periodic updates are scheduled on every update
        schedulePeriodicUpdates(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Cancel periodic updates when the last widget is removed
        cancelPeriodicUpdates(context)
    }

    private fun schedulePeriodicUpdates(context: Context) {
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WidgetUpdateWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            WidgetUpdateWorker.createWorkRequest()
        )
        Log.d("HomeWidgetReceiver", "Scheduled periodic widget updates")
    }

    private fun cancelPeriodicUpdates(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(WidgetUpdateWorker.WORK_NAME)
        Log.d("HomeWidgetReceiver", "Cancelled periodic widget updates")
    }
}
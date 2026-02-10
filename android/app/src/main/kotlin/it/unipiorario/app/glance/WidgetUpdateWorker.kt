package it.unipiorario.app.glance

import android.content.Context
import android.util.Log
import androidx.glance.appwidget.updateAll
import androidx.work.CoroutineWorker
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * Worker that periodically updates the home widget.
 * This ensures the widget data stays fresh by triggering updates every hour.
 */
class WidgetUpdateWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            Log.d(TAG, "Updating widget...")
            
            // Trigger widget update - this will cause the widget to re-read
            // the shared preferences and call parseSchedule with fresh data
            HomeWidget().updateAll(context)
            
            Log.d(TAG, "Widget update completed successfully")
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error updating widget", e)
            Result.failure()
        }
    }

    companion object {
        private const val TAG = "WidgetUpdateWorker"
        const val WORK_NAME = "widget_periodic_update"
        
        // Update interval - 1 hour
        private const val UPDATE_INTERVAL_HOURS = 1L

        /**
         * Creates a periodic work request for updating the widget.
         * The widget will be updated every hour.
         */
        fun createWorkRequest() = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
            15,
            TimeUnit.MINUTES
        ).build()
    }
}

package it.unipiorario.app.glance

import org.json.JSONObject
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter


data class Lesson(
    val name: String,
    val startDateTime: LocalDateTime,
    val endDateTime: LocalDateTime,
    val courseName: String,
    val roomName: String
)

data class DaySchedule(
    val date: String,
    val lessons: List<Lesson>
)

fun parseSchedule(jsonString: String): List<DaySchedule> {
    val scheduleMap = mutableListOf<DaySchedule>()
    val jsonObject = JSONObject(jsonString)
    val dateFormat = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS")

    for (date in jsonObject.keys()) {
        val lessonsJsonArray = jsonObject.getJSONArray(date)
        val lessonsList = mutableListOf<Lesson>()

        for (i in 0 until lessonsJsonArray.length()) {
            val lessonJson = lessonsJsonArray.getJSONObject(i)
            val lesson = Lesson(
                name = lessonJson.getString("name"),
                startDateTime = LocalDateTime.parse(lessonJson.getString("startDateTime").replace("T", " "), dateFormat),
                endDateTime = LocalDateTime.parse(lessonJson.getString("endDateTime").replace("T", " "), dateFormat),
                courseName = lessonJson.getString("courseName"),
                roomName = lessonJson.getString("roomName")
            )
            lessonsList.add(lesson)
        }
        scheduleMap.add(DaySchedule(date, lessonsList))
    }

    return scheduleMap
}

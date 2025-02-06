import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Data Models

struct Lesson: Identifiable, Codable {
    var id = UUID()
    let name: String
    let startDateTime: Date
    let endDateTime: Date
    let courseName: String
    let roomName: String
}

struct DaySchedule: Codable {
    let date: Date
    let lessons: [Lesson]
}

extension DaySchedule: Comparable {
    static func < (lhs: DaySchedule, rhs: DaySchedule) -> Bool {
        return lhs.date < rhs.date
    }
    
    static func == (lhs: DaySchedule, rhs: DaySchedule) -> Bool {
        lhs.date == rhs.date
    }
    
    static func > (lhs: DaySchedule, rhs: DaySchedule) -> Bool {
        return lhs.date > rhs.date
    }
}

// MARK: - App Intent

struct ChangeDayIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Change Day"
    static var description = IntentDescription("Changes the displayed day in the widget.")

    @Parameter(title: "Direction", default: "next")
    var direction: String // "prev" or "next"

    init() {}

    init(direction: String) {
        self.direction = direction
    }

    func perform() async throws -> some IntentResult {
        let cachedResponse = UserDefaults.standard.string(forKey: "cachedResponse") ?? "[]"
        let schedules = parseScheduleJSON(jsonString: cachedResponse)

        let selectedDay = UserDefaults.standard.string(forKey: "selectedDay") ?? ""
        var selectedDayIndex = schedules.firstIndex(where: { $0.date.formatted(date: .complete, time: .omitted) == selectedDay }) ?? 0

        if direction == "prev" {
            selectedDayIndex = max(0, selectedDayIndex - 1)
        } else if direction == "next" {
            selectedDayIndex = min(schedules.count - 1, selectedDayIndex + 1)
        }

        if !schedules.isEmpty {
            UserDefaults.standard.set(selectedDayIndex, forKey: "selectedDayIndex")
            UserDefaults.standard.set(schedules[selectedDayIndex].date.formatted(date: .complete, time: .omitted), forKey: "selectedDay")
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
        return .result()
    }
}

// MARK: - Widget Timeline Provider

struct ScheduleProvider: AppIntentTimelineProvider {
    private let cacheKey = "cachedResponse"
    private let urlString = "http://127.0.0.1:11341"
    typealias Intent = ChangeDayIntent
    
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(date: Date(), selectedDayIndex: 0, schedules: [], isCached: false)
    }
    
    func snapshot(for configuration: ChangeDayIntent, in context: Context) async -> ScheduleEntry {
        let selectedDayIndex = UserDefaults.standard.integer(forKey: "selectedDayIndex")
        let cachedResponse = UserDefaults.standard.string(forKey: cacheKey) ?? "[]"
        let schedules = parseScheduleJSON(jsonString: cachedResponse)
        
        return ScheduleEntry(date: Date(), selectedDayIndex: selectedDayIndex, schedules: schedules, isCached: true)
    }
    
    func timeline(for configuration: ChangeDayIntent, in context: Context) async -> Timeline<ScheduleEntry> {
        return await withCheckedContinuation { continuation in
            fetchData { response, isCached in
                let selectedDayIndex = UserDefaults.standard.integer(forKey: "selectedDayIndex")
                let schedules = parseScheduleJSON(jsonString: response ?? "[]")
                let entry = ScheduleEntry(date: Date(), selectedDayIndex: selectedDayIndex, schedules: schedules, isCached: isCached)
                let timeline = Timeline(entries: [entry], policy: .never)
                continuation.resume(returning: timeline)
            }
        }
    }
    
    private func fetchData(completion: @escaping (String?, Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil, false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print(responseString)
                UserDefaults.standard.set(responseString, forKey: cacheKey)
                completion(responseString, false)
            } else if let cachedResponse = UserDefaults.standard.string(forKey: cacheKey) {
                // Use cached response if the request fails
                completion(cachedResponse, true)
            } else {
                completion("[]", false)
            }
        }
        task.resume()
    }
}

// MARK: - Timeline Entry

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let selectedDayIndex: Int
    let schedules: [DaySchedule]
    let isCached: Bool
}

// MARK: - Widget View

struct ScheduleWidgetView: View {
    @AppStorage("selectedDayIndex") var selectedDayIndex = 0
    @SwiftUI.Environment(\.widgetFamily) var family
    var entry: ScheduleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let schedules: [DaySchedule] = entry.schedules
            
            if schedules.isEmpty {
                VStack(
                    alignment: .center
                ) {
                    Text("(◎-◎；)?")
                        .font(
                            family == .systemSmall ? .title2 : .largeTitle
                        )
                        .foregroundColor(.primary)
                    
                    Text("Nessuna lezione")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
                
            } else {
                let currentIndex = min(max(entry.selectedDayIndex, 0), schedules.count - 1)
                let currentSchedule = schedules[currentIndex]
                
                HStack(alignment: .center) {
                    Text(formatTime(currentSchedule.date))
                        .font(.headline)
                        .foregroundColor(Color.primary)
                    
                    Spacer()
                    
                    Button(intent: ChangeDayIntent(direction: "prev")) {
                        Label("", systemImage: "arrow.left")
                    }
                    .buttonStyle(.plain)
                    .disabled(!(currentIndex > 0))
                    
                    Button(intent: ChangeDayIntent(direction: "next")) {
                        Label("", systemImage: "arrow.right")
                    }
                    .buttonStyle(.plain)
                    .disabled(!(currentIndex < schedules.count - 1))
                }
                
                
                ForEach(currentSchedule.lessons.prefix(family == .systemLarge ? 6 : 2)) { lesson in
                    LessonView(lesson: lesson)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .containerBackground(Color(.systemBackground), for: .widget)
        .frame(
            maxHeight: .infinity,
            alignment: .top
        )
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d"
        formatter.locale = Locale(identifier: "it_IT")
        
        return formatter.string(from: date).capitalized(with: Locale(identifier: "it_IT"))
    }
}


// MARK: - Lesson Row

struct LessonView: View {
    var lesson: Lesson
    @SwiftUI.Environment(\.widgetFamily) var family
    
    var body: some View {
        HStack(alignment: .center) {
            if (family != .systemSmall) {
                Text(
                    lesson.roomName.replacingOccurrences(of: "Fib ", with: "")
                )
                .font(.body)
                .padding(6)
                .background(Color.accentColor.opacity(0.4))
                .cornerRadius(360)
            }
            
            VStack(alignment: .leading) {
                Text(formatTime(lesson.startDateTime))
                    .font(.caption)
                    .bold()
                    .foregroundColor(.secondary)
                
                Text(formatTime(lesson.endDateTime))
                    .font(.caption)
                    .bold()
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading) {
                Text(lesson.name)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(lesson.courseName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(5)
        .background(Color.accentColor.opacity(0.4))
        .cornerRadius(10)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Sample Data

let sampleSchedules = [
    DaySchedule(date: Date(), lessons: [
        Lesson(name: "PROGRAMMAZIONE E ALGORITMICA", startDateTime: Date(), endDateTime: Date(), courseName: "CORSO B", roomName: "D2"),
        Lesson(name: "ALGEBRA LINEARE", startDateTime: Date(), endDateTime: Date(), courseName: "CORSO B", roomName: "D2"),
        Lesson(name: "ALGEBRA LINEARE", startDateTime: Date(), endDateTime: Date(), courseName: "CORSO B", roomName: "D2")
    ]),
    DaySchedule(date: Date(), lessons: [
        Lesson(name: "LABORATORIO I", startDateTime: Date(), endDateTime: Date(), courseName: "CORSO B", roomName: "D2"),
        Lesson(name: "ANALISI MATEMATICA", startDateTime: Date(), endDateTime: Date(), courseName: "CORSO B", roomName: "D2")
    ])
]


func parseScheduleJSON(jsonString: String) -> [DaySchedule] {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    dateFormatter.locale = Locale(identifier: "it_IT")

    
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "yyyy-MM-dd"
    
    guard let jsonData = jsonString.data(using: .utf8) else { return [] }
    
    do {
        let rawDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: [[String: Any]]]
        
        var schedules: [DaySchedule] = []
        
        rawDictionary?.forEach { date, lessonsArray in
            let lessons: [Lesson] = lessonsArray.compactMap { lessonDict in
                guard let name = lessonDict["name"] as? String,
                      let startDateTimeString = lessonDict["startDateTime"] as? String,
                      let endDateTimeString = lessonDict["endDateTime"] as? String,
                      let roomName = lessonDict["roomName"] as? String,
                      let startDateTime = dateFormatter.date(from: startDateTimeString),
                      let endDateTime = dateFormatter.date(from: endDateTimeString) else {
                    print("Skipping invalid lesson data: \(lessonDict)")
                    return nil
                }
                let courseName = lessonDict["courseName"] as? String ?? name
                return Lesson(name: name, startDateTime: startDateTime, endDateTime: endDateTime, courseName: courseName, roomName: roomName)
            }
            schedules.append(DaySchedule(date: dayFormatter.date(from: date)!, lessons: lessons))
        }
        
        return schedules.sorted()
    } catch {
        print("Error parsing JSON: \(error)")
        return []
    }
}
// MARK: - Widget Definition

struct HomeWidget: Widget {
    let kind: String = "HomeWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ChangeDayIntent.self, provider: ScheduleProvider()) { entry in
            ScheduleWidgetView(entry: entry)
        }
        .configurationDisplayName("Orario lezioni")
        .description("Un widget per vedere l'orario delle lezioni")
    }
}

// MARK: - Preview

struct ScheduleWidget_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleWidgetView(entry: ScheduleEntry(date: Date(), selectedDayIndex: 1, schedules: sampleSchedules, isCached: false))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

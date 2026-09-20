#if DEBUG
import Foundation

enum StoreScreenshotConfiguration {
    static let launchArgument = "-store-screenshot"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static var selectedTab: Int {
        guard let argumentIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "-store-screenshot-tab"),
              ProcessInfo.processInfo.arguments.indices.contains(argumentIndex + 1),
              let tab = Int(ProcessInfo.processInfo.arguments[argumentIndex + 1]) else {
            return 0
        }
        return min(max(tab, 0), 2)
    }

    static func tasks(now: Date = Date(), calendar: Calendar = .current) -> [Task] {
        let today = calendar.startOfDay(for: now)

        return [
            task("英単語200語", dueInDays: -2, completionCount: 1, from: today, calendar: calendar),
            task("基本情報技術者 午後問題", dueInDays: 0, completionCount: 0, from: today, calendar: calendar),
            task("簿記2級 仕訳", dueInDays: 0, completionCount: 2, from: today, calendar: calendar),
            task("TOEIC Part 5", dueInDays: 3, completionCount: 1, from: today, calendar: calendar),
            task("統計学 第3章", dueInDays: 7, completionCount: 0, from: today, calendar: calendar),
            task("面接の想定質問", dueInDays: 12, completionCount: 2, from: today, calendar: calendar),
            task("SwiftUI レイアウト", dueInDays: 18, completionCount: 1, from: today, calendar: calendar)
        ]
    }

    private static func task(
        _ title: String,
        dueInDays days: Int,
        completionCount: Int,
        from today: Date,
        calendar: Calendar
    ) -> Task {
        let scheduledDay = calendar.date(byAdding: .day, value: days, to: today) ?? today
        let scheduledDate = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: scheduledDay) ?? scheduledDay
        let createdAt = calendar.date(byAdding: .day, value: -max(completionCount + 1, 1), to: today) ?? today

        let stage: TaskStage
        switch completionCount {
        case 0:
            stage = .oneHourLater
        case 1:
            stage = .oneDayLater
        case 2:
            stage = .oneWeekLater
        default:
            stage = .oneMonthLater
        }

        return Task(
            id: UUID(),
            title: title,
            stage: stage,
            createdAt: createdAt,
            scheduledDate: scheduledDate,
            completionCount: completionCount
        )
    }
}
#endif

import SwiftUI
import WidgetKit

private enum SharedWidgetData {
    static let appGroupIdentifier = "group.-7imuzi.EbbinghausReminder"
    static let tasksKey = "widgetTasks"
    static let isSubscribedKey = "widgetIsSubscribed"
    static let entitlementCheckedAtKey = "widgetEntitlementCheckedAt"
    static let widgetKind = "EbbinghausTodayWidget"
}

private struct WidgetTaskSnapshot: Codable, Identifiable {
    let id: UUID
    let title: String
    let scheduledDate: Date
    let completionCount: Int
}

private struct TodayWidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTaskSnapshot]
    let isSubscribed: Bool
    let hasCheckedEntitlement: Bool
}

private struct TodayWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayWidgetEntry {
        TodayWidgetEntry(
            date: Date(),
            tasks: Self.sampleTasks,
            isSubscribed: true,
            hasCheckedEntitlement: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayWidgetEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let calendar = Calendar.current
        let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: entry.date))
            ?? entry.date.addingTimeInterval(60 * 60 * 24)
        completion(Timeline(entries: [entry], policy: .after(nextDay)))
    }

    private func loadEntry() -> TodayWidgetEntry {
        guard let defaults = UserDefaults(suiteName: SharedWidgetData.appGroupIdentifier) else {
            return TodayWidgetEntry(
                date: Date(),
                tasks: [],
                isSubscribed: false,
                hasCheckedEntitlement: false
            )
        }

        let tasks: [WidgetTaskSnapshot]
        if let data = defaults.data(forKey: SharedWidgetData.tasksKey),
           let decoded = try? JSONDecoder().decode([WidgetTaskSnapshot].self, from: data) {
            tasks = decoded
        } else {
            tasks = []
        }

        return TodayWidgetEntry(
            date: Date(),
            tasks: tasks,
            isSubscribed: defaults.bool(forKey: SharedWidgetData.isSubscribedKey),
            hasCheckedEntitlement: defaults.object(forKey: SharedWidgetData.entitlementCheckedAtKey) != nil
        )
    }

    private static var sampleTasks: [WidgetTaskSnapshot] {
        [
            WidgetTaskSnapshot(
                id: UUID(),
                title: "英単語 Lesson 3",
                scheduledDate: Date(),
                completionCount: 1
            ),
            WidgetTaskSnapshot(
                id: UUID(),
                title: "日本史 江戸時代",
                scheduledDate: Date(),
                completionCount: 2
            )
        ]
    }
}

private struct EbbinghausTodayWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    let entry: TodayWidgetEntry

    private let primaryColor = Color(red: 0, green: 122 / 255, blue: 1)

    var body: some View {
        VStack(alignment: .leading, spacing: widgetFamily == .systemSmall ? 8 : 10) {
            header

            Group {
                if !entry.hasCheckedEntitlement {
                    unavailableView(
                        icon: "arrow.clockwise.circle",
                        title: "アプリを開いて更新",
                        message: "購読状態を確認するとタスクが表示されます"
                    )
                } else if !entry.isSubscribed {
                    unavailableView(
                        icon: "crown.fill",
                        title: "サポーター限定",
                        message: "購読すると今日の復習をホーム画面で確認できます"
                    )
                } else {
                    taskList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .containerBackground(for: .widget) {
            Color(uiColor: .secondarySystemBackground)
        }
        .widgetURL(URL(string: "ebbinghausreminder://today"))
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "checklist")
                .foregroundStyle(primaryColor)
            Text("今日の復習")
                .font(.headline)
                .foregroundStyle(primaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 4)

            if entry.hasCheckedEntitlement && entry.isSubscribed {
                Text("\(dueTasks.count)件")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: entry.hasCheckedEntitlement ? "crown.fill" : "arrow.clockwise")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var taskList: some View {
        Group {
            if dueTasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text("今日の復習はありません")
                        .font(widgetFamily == .systemSmall ? .caption.weight(.medium) : .subheadline.weight(.medium))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: widgetFamily == .systemSmall ? 6 : 8) {
                    ForEach(Array(visibleTasks.enumerated()), id: \.element.id) { index, task in
                        taskRow(task)
                        if widgetFamily != .systemSmall && index < visibleTasks.count - 1 {
                            Divider()
                        }
                    }

                    if dueTasks.count > taskLimit {
                        Text("ほか \(dueTasks.count - taskLimit)件")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private func taskRow(_ task: WidgetTaskSnapshot) -> some View {
        HStack(spacing: 9) {
            Image(systemName: "circle")
                .font(.body.weight(.semibold))
                .foregroundStyle(isOverdue(task) ? .red : primaryColor)

            VStack(alignment: .leading, spacing: 1) {
                Text(task.title)
                    .font(widgetFamily == .systemSmall ? .caption.weight(.medium) : .subheadline.weight(.medium))
                    .lineLimit(1)
                if isOverdue(task) && widgetFamily != .systemSmall {
                    Text("期限切れ")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
            }

            Spacer(minLength: 4)

            if widgetFamily != .systemSmall {
                Text("\(task.completionCount + 1)回目")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func unavailableView(icon: String, title: String, message: String) -> some View {
        if widgetFamily == .systemSmall {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.title2.bold())
                    .foregroundStyle(primaryColor)
                Text(title)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(primaryColor)
                    .frame(width: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private var taskLimit: Int {
        switch widgetFamily {
        case .systemSmall:
            return 2
        case .systemLarge:
            return 8
        default:
            return 3
        }
    }

    private var visibleTasks: [WidgetTaskSnapshot] {
        Array(dueTasks.prefix(taskLimit))
    }

    private var dueTasks: [WidgetTaskSnapshot] {
        let endOfToday = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: entry.date)
        ) ?? entry.date

        return entry.tasks
            .filter { $0.scheduledDate < endOfToday }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }

    private func isOverdue(_ task: WidgetTaskSnapshot) -> Bool {
        task.scheduledDate < Calendar.current.startOfDay(for: entry.date)
    }
}

@main
struct EbbinghausReminderWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: SharedWidgetData.widgetKind,
            provider: TodayWidgetProvider()
        ) { entry in
            EbbinghausTodayWidgetView(entry: entry)
        }
        .configurationDisplayName("今日の復習")
        .description("期限切れと今日の復習タスクを確認できます。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

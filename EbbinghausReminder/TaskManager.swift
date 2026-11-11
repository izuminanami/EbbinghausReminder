import Foundation
import UserNotifications

final class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var completedTasks: [Task] = []
    @Published private(set) var notificationHour: Int
    @Published private(set) var notificationMinute: Int

    private let tasksKey = "tasks"
    private let completedTasksKey = "completedTasks"
    private let notificationHourKey = "notificationHour"
    private let notificationMinuteKey = "notificationMinute"

    init() {
        let defaults = UserDefaults.standard
        notificationHour = defaults.object(forKey: notificationHourKey) as? Int ?? 20
        notificationMinute = defaults.object(forKey: notificationMinuteKey) as? Int ?? 0

        #if DEBUG
        if StoreScreenshotConfiguration.isEnabled {
            tasks = StoreScreenshotConfiguration.tasks()
            return
        }
        #endif

        loadTasks()
        updateAnalyticsProperties()
    }

    var preferredNotificationTime: Date {
        Calendar.current.date(
            bySettingHour: notificationHour,
            minute: notificationMinute,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    func addTask(title: String, date: Date, source: String = "unknown") {
        let task = Task(
            id: UUID(),
            title: title,
            stage: .oneHourLater,
            createdAt: Date(),
            scheduledDate: applyingPreferredTime(to: date),
            completionCount: 0
        )
        tasks.append(task)
        saveTasks()
        AnalyticsService.shared.log("task_created", parameters: [
            "source": source,
            "scheduled_day_bucket": AnalyticsService.dayOffsetBucket(
                AnalyticsService.dayOffset(from: task.scheduledDate)
            ),
            "active_task_count": tasks.count
        ])
        requestNotificationPermissionIfNeeded { [weak self] isAuthorized in
            guard isAuthorized else { return }
            self?.scheduleNotification(for: task)
        }
    }

    func updateTask(_ task: Task, title: String, date: Date, source: String = "unknown") {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        let titleChanged = tasks[index].title != title
        let oldDay = Calendar.current.startOfDay(for: tasks[index].scheduledDate)
        let newDay = Calendar.current.startOfDay(for: date)

        tasks[index].title = title
        tasks[index].scheduledDate = applyingPreferredTime(to: date)
        let updatedTask = tasks[index]
        saveTasks()

        AnalyticsService.shared.log("task_updated", parameters: [
            "source": source,
            "title_changed": titleChanged,
            "date_changed": oldDay != newDay,
            "review_number": task.completionCount + 1,
            "scheduled_day_bucket": AnalyticsService.dayOffsetBucket(
                AnalyticsService.dayOffset(from: updatedTask.scheduledDate)
            )
        ])

        removeNotification(for: task)
        scheduleNotificationIfAuthorized(for: updatedTask)
    }

    func updateNotificationTime(to date: Date, source: String = "unknown") {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        notificationHour = components.hour ?? 20
        notificationMinute = components.minute ?? 0

        let defaults = UserDefaults.standard
        defaults.set(notificationHour, forKey: notificationHourKey)
        defaults.set(notificationMinute, forKey: notificationMinuteKey)

        for index in tasks.indices {
            tasks[index].scheduledDate = applyingPreferredTime(to: tasks[index].scheduledDate)
        }
        saveTasks()

        AnalyticsService.shared.log("notification_time_changed", parameters: [
            "source": source,
            "hour": notificationHour,
            "minute_bucket": notificationMinute < 30 ? "00_to_29" : "30_to_59",
            "rescheduled_task_count": tasks.count
        ])

        let identifiers = tasks.map { $0.id.uuidString }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        requestNotificationPermissionIfNeeded { [weak self] isAuthorized in
            guard isAuthorized else { return }
            DispatchQueue.main.async {
                guard let self else { return }
                self.tasks.forEach { self.scheduleNotification(for: $0) }
            }
        }
    }

    func requestNotificationPermission(source: String = "unknown") {
        requestNotificationPermissionIfNeeded(source: source) { _ in }
    }

    func completeTask(_ task: Task, source: String = "unknown") {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        let wasOverdue = tasks[index].scheduledDate < Calendar.current.startOfDay(for: Date())
        removeNotification(for: task)
        let nextCompletionCount = tasks[index].completionCount + 1
        let fullyCompleted = nextCompletionCount >= 4

        if nextCompletionCount >= 4 {
            var completedTask = tasks[index]
            completedTask.stage = .completed
            completedTask.completionCount = nextCompletionCount
            completedTasks.append(completedTask)
            tasks.remove(at: index)
        } else {
            tasks[index].completionCount = nextCompletionCount
            let nextIntervalInDays: Int

            switch nextCompletionCount {
            case 1:
                tasks[index].stage = .oneDayLater
                nextIntervalInDays = 1
            case 2:
                tasks[index].stage = .oneWeekLater
                nextIntervalInDays = 7
            default:
                tasks[index].stage = .oneMonthLater
                nextIntervalInDays = 30
            }

            let nextDate = Calendar.current.date(
                byAdding: .day,
                value: nextIntervalInDays,
                to: Date()
            ) ?? Date()
            tasks[index].scheduledDate = applyingPreferredTime(to: nextDate)
            scheduleNotificationIfAuthorized(for: tasks[index])
        }

        saveTasks()
        AnalyticsService.shared.log("task_completed", parameters: [
            "source": source,
            "review_number": nextCompletionCount,
            "fully_completed": fullyCompleted,
            "was_overdue": wasOverdue,
            "days_late_bucket": AnalyticsService.dayOffsetBucket(
                AnalyticsService.dayOffset(from: task.scheduledDate)
            ),
            "active_task_count": tasks.count,
            "completed_task_count": completedTasks.count
        ])
    }

    func deleteTask(_ task: Task, source: String = "unknown") {
        let list = tasks.contains(where: { $0.id == task.id }) ? "active" : "completed"
        removeNotification(for: task)
        tasks.removeAll { $0.id == task.id }
        completedTasks.removeAll { $0.id == task.id }
        saveTasks()
        AnalyticsService.shared.log("task_deleted", parameters: [
            "source": source,
            "list": list,
            "review_number": task.completionCount + 1
        ])
    }

    private func applyingPreferredTime(to date: Date) -> Date {
        Calendar.current.date(
            bySettingHour: notificationHour,
            minute: notificationMinute,
            second: 0,
            of: date
        ) ?? date
    }

    private func requestNotificationPermissionIfNeeded(
        source: String = "task_action",
        completion: @escaping (Bool) -> Void
    ) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                AnalyticsService.shared.setUserProperty("authorized", forName: "notification_status")
                completion(true)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error {
                        AnalyticsService.shared.record(error, context: "notification_permission")
                    }
                    AnalyticsService.shared.log("notification_permission_result", parameters: [
                        "source": source,
                        "granted": granted
                    ])
                    AnalyticsService.shared.setUserProperty(
                        granted ? "authorized" : "denied",
                        forName: "notification_status"
                    )
                    completion(granted)
                }
            case .denied:
                AnalyticsService.shared.setUserProperty("denied", forName: "notification_status")
                completion(false)
            @unknown default:
                AnalyticsService.shared.setUserProperty("unknown", forName: "notification_status")
                completion(false)
            }
        }
    }

    private func scheduleNotificationIfAuthorized(for task: Task) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else {
                return
            }
            self?.scheduleNotification(for: task)
        }
    }

    private func scheduleNotification(for task: Task) {
        guard task.scheduledDate > Date() else {
            AnalyticsService.shared.log("notification_schedule_skipped", parameters: [
                "reason": "past_date",
                "review_number": task.completionCount + 1
            ])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "復習の時間です"
        content.body = task.title
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: task.scheduledDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                AnalyticsService.shared.record(error, context: "notification_schedule", extra: [
                    "review_number": task.completionCount + 1
                ])
                AnalyticsService.shared.log("notification_schedule_failed", parameters: [
                    "review_number": task.completionCount + 1
                ])
            } else {
                AnalyticsService.shared.log("notification_scheduled", parameters: [
                    "review_number": task.completionCount + 1,
                    "scheduled_day_bucket": AnalyticsService.dayOffsetBucket(
                        AnalyticsService.dayOffset(from: task.scheduledDate)
                    )
                ])
            }
        }
    }

    private func removeNotification(for task: Task) {
        let identifiers = [task.id.uuidString]
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private func saveTasks() {
        let encoder = JSONEncoder()
        do {
            let tasksData = try encoder.encode(tasks)
            UserDefaults.standard.set(tasksData, forKey: tasksKey)
        } catch {
            AnalyticsService.shared.record(error, context: "encode_active_tasks")
        }
        do {
            let completedTasksData = try encoder.encode(completedTasks)
            UserDefaults.standard.set(completedTasksData, forKey: completedTasksKey)
        } catch {
            AnalyticsService.shared.record(error, context: "encode_completed_tasks")
        }
        WidgetSnapshotStore.saveTasks(tasks)
        updateAnalyticsProperties()
    }

    private func loadTasks() {
        let decoder = JSONDecoder()
        if let tasksData = UserDefaults.standard.data(forKey: tasksKey) {
            do {
                tasks = try decoder.decode([Task].self, from: tasksData)
            } catch {
                AnalyticsService.shared.record(error, context: "decode_active_tasks")
            }
        }
        if let completedTasksData = UserDefaults.standard.data(forKey: completedTasksKey) {
            do {
                completedTasks = try decoder.decode([Task].self, from: completedTasksData)
            } catch {
                AnalyticsService.shared.record(error, context: "decode_completed_tasks")
            }
        }
        WidgetSnapshotStore.saveTasks(tasks)
        AnalyticsService.shared.log("tasks_loaded", parameters: [
            "active_count": tasks.count,
            "completed_count": completedTasks.count,
            "overdue_count": tasks.filter { $0.scheduledDate < Calendar.current.startOfDay(for: Date()) }.count
        ])
    }

    private func updateAnalyticsProperties() {
        AnalyticsService.shared.setTaskCounts(active: tasks.count, completed: completedTasks.count)
    }
}

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
        loadTasks()
    }

    var preferredNotificationTime: Date {
        Calendar.current.date(
            bySettingHour: notificationHour,
            minute: notificationMinute,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    func addTask(title: String, date: Date) {
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
        requestNotificationPermissionIfNeeded { [weak self] isAuthorized in
            guard isAuthorized else { return }
            self?.scheduleNotification(for: task)
        }
    }

    func updateTask(_ task: Task, title: String, date: Date) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        tasks[index].title = title
        tasks[index].scheduledDate = applyingPreferredTime(to: date)
        let updatedTask = tasks[index]
        saveTasks()

        removeNotification(for: task)
        scheduleNotificationIfAuthorized(for: updatedTask)
    }

    func updateNotificationTime(to date: Date) {
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

    func requestNotificationPermission() {
        requestNotificationPermissionIfNeeded { _ in }
    }

    func completeTask(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        removeNotification(for: task)
        let nextCompletionCount = tasks[index].completionCount + 1

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
    }

    func deleteTask(_ task: Task) {
        removeNotification(for: task)
        tasks.removeAll { $0.id == task.id }
        completedTasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    private func applyingPreferredTime(to date: Date) -> Date {
        Calendar.current.date(
            bySettingHour: notificationHour,
            minute: notificationMinute,
            second: 0,
            of: date
        ) ?? date
    }

    private func requestNotificationPermissionIfNeeded(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion(granted)
                }
            case .denied:
                completion(false)
            @unknown default:
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
        guard task.scheduledDate > Date() else { return }

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

        UNUserNotificationCenter.current().add(request)
    }

    private func removeNotification(for task: Task) {
        let identifiers = [task.id.uuidString]
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private func saveTasks() {
        let encoder = JSONEncoder()
        if let tasksData = try? encoder.encode(tasks) {
            UserDefaults.standard.set(tasksData, forKey: tasksKey)
        }
        if let completedTasksData = try? encoder.encode(completedTasks) {
            UserDefaults.standard.set(completedTasksData, forKey: completedTasksKey)
        }
    }

    private func loadTasks() {
        let decoder = JSONDecoder()
        if let tasksData = UserDefaults.standard.data(forKey: tasksKey),
           let savedTasks = try? decoder.decode([Task].self, from: tasksData) {
            tasks = savedTasks
        }
        if let completedTasksData = UserDefaults.standard.data(forKey: completedTasksKey),
           let savedCompletedTasks = try? decoder.decode([Task].self, from: completedTasksData) {
            completedTasks = savedCompletedTasks
        }
    }
}

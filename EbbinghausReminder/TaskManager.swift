//
//  TaskManager.swift
//  EbbinghausReminder
//
//  Created by 泉七海 on 2025/02/05.
//

import Foundation
import UserNotifications
import WidgetKit

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var completedTasks: [Task] = [] // 実行済用リスト

    init() {
        loadTasks()
        requestNotificationPermission()
    }

    func addTask(title: String, date: Date = Date()) {
        let scheduledDate = date
        let newTask = Task(id: UUID(), title: title, stage: .oneHourLater, createdAt: Date(), scheduledDate: scheduledDate, completionCount: 0)
        tasks.append(newTask)
        saveTasks()
        scheduleNotification(for: newTask)
    }

    func completeTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            let completionCount = tasks[index].completionCount + 1

            if completionCount >= 4 {
                // 4回目の完了 → 実行済に移動
                removeNotification(for: task)
                var archivedTask = tasks[index]
                archivedTask.stage = .completed // 完了ステータス
                completedTasks.append(archivedTask) // 実行済リストに追加
                tasks.remove(at: index)
            } else {
                // 1回目の完了 → 1日後
                // 2回目の完了 → 1週間後
                // 3回目の完了 → 1ヶ月後
                // 4回目 → 実行済に移動
                let nextInterval: Int
                switch completionCount {
                case 1: nextInterval = 1  // 1日後
                case 2: nextInterval = 7  // 1週間後
                case 3: nextInterval = 30 // 1ヶ月後
                default: nextInterval = 0 // これが呼ばれることはない
                }

                let nextDate = Calendar.current.date(byAdding: .day, value: nextInterval, to: Date()) ?? Date()
                tasks[index].scheduledDate = nextDate
                tasks[index].completionCount = completionCount

                removeNotification(for: task)
                scheduleNotification(for: tasks[index])
            }

            saveTasks()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func updateTaskStages() {
        let now = Date()

        for i in tasks.indices {
            let task = tasks[i]
            switch task.stage {
            case .oneHourLater where now.timeIntervalSince(task.createdAt) > 3600:
                tasks[i].stage = .oneDayLater
            case .oneDayLater where now.timeIntervalSince(task.createdAt) > 86400:
                tasks[i].stage = .oneWeekLater
            case .oneWeekLater where now.timeIntervalSince(task.createdAt) > 604800:
                tasks[i].stage = .oneMonthLater
            default:
                break
            }
        }
        saveTasks()
    }

    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("通知の許可エラー: \(error.localizedDescription)")
            }
        }
    }

    private func scheduleNotification(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "復習タスクがあります！"
        content.body = task.title
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知スケジュールエラー: \(error.localizedDescription)")
            }
        }
    }

    private func removeNotification(for task: Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }

    func saveTasks() {
        if let encodedTasks = try? JSONEncoder().encode(tasks),
           let encodedCompletedTasks = try? JSONEncoder().encode(completedTasks) {
            UserDefaults.standard.set(encodedTasks, forKey: "tasks")
            UserDefaults.standard.set(encodedCompletedTasks, forKey: "completedTasks") // 実行済も保存
        }
    }

    func loadTasks() {
        if let savedTasks = UserDefaults.standard.data(forKey: "tasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: savedTasks) {
            tasks = decodedTasks
        }
        if let savedCompletedTasks = UserDefaults.standard.data(forKey: "completedTasks"),
           let decodedCompletedTasks = try? JSONDecoder().decode([Task].self, from: savedCompletedTasks) {
            completedTasks = decodedCompletedTasks
        }
    }
    
    func deleteTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
        } else if let index = completedTasks.firstIndex(where: { $0.id == task.id }) {
            completedTasks.remove(at: index)
        }
        saveTasks()
    }
}

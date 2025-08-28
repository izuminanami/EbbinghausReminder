//
//  TaskCalendarView.swift
//  EbbinghausReminder
//
//  Created by 泉七海 on 2025/02/05.
//

import SwiftUI

struct TaskCalendarView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var selectedDate = Date()
    @State private var isAddingTask = false
    @State private var completedTasks: Set<UUID> = [] // タスクごとの完了状態を管理

    var body: some View {
        VStack {
            Spacer()
                .frame(height: 10)
            HStack {
                Text("カレンダーで確認")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color("PrimaryColor"))
                    .padding()
                Spacer()
                Button(action: { withAnimation { isAddingTask = true } }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(Color("PrimaryColor"))
                        .onChange(of: selectedDate) { _ in
                            completedTasks.removeAll() // 別の日を選択したらチェック状態をリセット
                        }
                }
            }
            .padding()
            
            DatePicker("日付を選択", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .foregroundColor(Color("TextColor"))

            if !filteredTasks.isEmpty {
                List {
                    ForEach(filteredTasks) { task in
                        HStack {
                            Text(task.title)
                                .foregroundColor(Color("TextColor"))
                            Spacer()
                            Text("\(task.completionCount + 1)回目")
                                .foregroundColor(Color("GrayTextColor"))

                            // 押したら即チェックマークがつくボタン
                            Button(action: {
                                    completedTasks.insert(task.id) // 即座にチェックマークをつける
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 1秒後に処理
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        taskManager.completeTask(task) // 1秒後にタスク完了処理
                                    }
                                }
                            }) {
                                Image(systemName: completedTasks.contains(task.id) ? "checkmark.circle.fill" : "circle") // チェックを即反映
                                    .font(.title2)
                                    .foregroundColor(completedTasks.contains(task.id) ? Color.green : Color("PrimaryColor"))
                                    .transition(.scale) // スムーズな変化
                            }
                        }
                        .padding()
                        .background(Color("CardBackground"))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .transition(.move(edge: .trailing).combined(with: .opacity)) // スライド＆フェードアウト
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { taskManager.deleteTask(task) } label: {
                                Label("削除", systemImage: "trash")
                            }
                            .tint(Color("DeleteColor"))
                        }
                    }
                    .listRowBackground(Color("BackgroundColor")) // 各行の背景を統一
                }

                .scrollContentBackground(.hidden) // List のデフォルト背景を削除
                .background(Color("BackgroundColor")) // List の背景も統一
            }
            else {
                Spacer()
            }
        }
        .background(Color("BackgroundColor").edgesIgnoringSafeArea(.all))
        .onTapGesture(count: 2) { selectedDate = Date() }
        .onTapGesture { hideKeyboard() }
        .overlay(
            Group {
                if isAddingTask {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture { withAnimation { isAddingTask = false } }
                    
                    TaskAddPopupView(isShowing: $isAddingTask)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        )
    }

    private var filteredTasks: [Task] {
        return taskManager.tasks.filter { Calendar.current.isDate($0.scheduledDate, inSameDayAs: selectedDate) }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// プレビュー
struct TaskCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        let taskManager = TaskManager()
        
        taskManager.tasks = [
            Task(id: UUID(), title: "数学の復習", stage: .oneHourLater, createdAt: Date(), scheduledDate: Date(), completionCount: 1),
            Task(id: UUID(), title: "英単語テスト", stage: .oneHourLater, createdAt: Date(), scheduledDate: Date(), completionCount: 2),
            Task(id: UUID(), title: "読書", stage: .oneHourLater, createdAt: Date(), scheduledDate: Date(), completionCount: 3)
        ]
        
        return TaskCalendarView()
            .environmentObject(taskManager)
            .previewLayout(.sizeThatFits)
    }
}

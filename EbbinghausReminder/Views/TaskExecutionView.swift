//
//  TaskExecutionView.swift
//  EbbinghausReminder
//
//  Created by 泉七海 on 2025/02/05.
//

import SwiftUI

struct TaskExecutionView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var isShowingCompleted = false
    @State private var isAddingTask = false

    var body: some View {
        ZStack {
            VStack {
                Spacer()
                    .frame(height: 10)
                HStack {
                    // テキストをタップすると実行済・実行中が切り替わる
                    Text(isShowingCompleted ? "実行済のタスク" : "実行中のタスク")
                        .font(.title)
                        .bold()
                        .foregroundColor(Color("PrimaryColor"))
                        .padding()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingCompleted.toggle() // クリックで切り替え
                            }
                        }
                    Image(systemName: isShowingCompleted ? "chevron.up" : "chevron.down") // アイコンで切り替えを表現
                        .foregroundColor(Color("PrimaryColor"))
                        .font(.title2)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingCompleted.toggle()
                            }
                        }
                    Spacer()
                    Button(action: { withAnimation { isAddingTask = true } }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
                .padding()
                
                if displayedTasks.isEmpty {
                    // タスクがないときのメッセージを表示
                    Spacer()
                    Text(isShowingCompleted ? "実行済のタスクはありません" : "実行中のタスクはありません")
                        .foregroundColor(Color("GrayTextColor"))
                        .padding()
                    Spacer()
                        .frame(height: UIScreen.main.bounds.size.height/3)
                } else {
                    List {
                        ForEach(displayedTasks) { task in
                            HStack {
                                Text(task.title)
                                    .foregroundColor(Color("TextColor"))
                                Spacer()
                                Text(formattedDate(task.scheduledDate))
                                    .foregroundColor(Color("GrayTextColor"))
                                Spacer()
                                    .frame(width: 10)
                                Text("\(task.completionCount + 1)回目")
                                    .foregroundColor(Color("GrayTextColor"))
                            }
                            .padding()
                            .background(Color("CardBackground"))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteTask(task)
                                } label: {
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
            }
            .onTapGesture { hideKeyboard() }
            .background(Color("BackgroundColor").edgesIgnoringSafeArea(.all))
            
            if isAddingTask {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { withAnimation { isAddingTask = false } }

                TaskAddPopupView(isShowing: $isAddingTask)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }

    private var displayedTasks: [Task] {
        return isShowingCompleted ? taskManager.completedTasks : taskManager.tasks
    }

    private func deleteTask(_ task: Task) {
        if isShowingCompleted {
            if let index = taskManager.completedTasks.firstIndex(where: { $0.id == task.id }) {
                taskManager.completedTasks.remove(at: index)
            }
        } else {
            if let index = taskManager.tasks.firstIndex(where: { $0.id == task.id }) {
                taskManager.tasks.remove(at: index)
            }
        }
        taskManager.saveTasks()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

// プレビュー
struct TaskExecutionView_Previews: PreviewProvider {
    static var previews: some View {
        let taskManager = TaskManager()
        
        taskManager.tasks = [
            Task(id: UUID(), title: "プログラミングの復習", stage: .oneHourLater, createdAt: Date(), scheduledDate: Date(), completionCount: 1),
            Task(id: UUID(), title: "アプリデザインの改善", stage: .oneHourLater, createdAt: Date(), scheduledDate: Date(), completionCount: 2)
        ]
        
        return TaskExecutionView()
            .environmentObject(taskManager)
            .previewLayout(.sizeThatFits)
            .background(Color("BackgroundColor"))
    }
}

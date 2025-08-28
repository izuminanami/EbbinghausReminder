//
//  TodayTaskView.swift
//  EbbinghausReminder
//
//  Created by 泉七海 on 2025/02/05.
//

import SwiftUI

struct TodayTaskView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var isAddingTask = false
    @State private var isShowingInfo = false // InfoView のポップアップ管理
    @State private var completedTasks: Set<UUID> = [] // タスクごとの完了状態を管理

    var body: some View {
        ZStack {
            VStack {
                Spacer().frame(height: 10)
                HStack {
                    Text("今日のタスク")
                        .font(.title)
                        .bold()
                        .foregroundColor(Color("PrimaryColor"))
                        .padding()
                    Spacer()
                    Button(action: { withAnimation { isShowingInfo = true } }) {
                        Image(systemName: "info.circle")
                            .font(.title)
                            .foregroundColor(Color("PrimaryColor"))
                    }
                    Button(action: { withAnimation { isAddingTask = true } }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(Color("PrimaryColor"))
                    }
                }
                .padding()

                if todayTasks.isEmpty {
                    Spacer()
                    Text("今日のタスクはありません")
                        .foregroundColor(Color("GrayTextColor"))
                        .padding()
                    Spacer()
                        .frame(height: UIScreen.main.bounds.size.height/3)
                } else {
                    List {
                        ForEach(todayTasks) { task in
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
            }
            .background(Color("BackgroundColor").edgesIgnoringSafeArea(.all))

            // ポップアップの背景（フェード表示）
            if isAddingTask || isShowingInfo {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isAddingTask = false
                            isShowingInfo = false
                        }
                    }
            }
            // 「タスク追加」ポップアップ
            if isAddingTask {
                TaskAddPopupView(isShowing: $isAddingTask)
                    .transition(.opacity)
                    .zIndex(1)
            }
            // 「インフォメーション」ポップアップ
            if isShowingInfo {
                InfoView(isShowing: $isShowingInfo)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }

    // 前日以前の未完了タスクも表示
    private var todayTasks: [Task] {
        let today = Calendar.current.startOfDay(for: Date())
        return taskManager.tasks.filter { task in
            let taskDate = Calendar.current.startOfDay(for: task.scheduledDate)
            return taskDate <= today
        }
    }
}

// プレビュー
struct TodayTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let taskManager = TaskManager()
        
        taskManager.tasks = [
            Task(id: UUID(), title: "数学の復習", stage: .oneHourLater, createdAt: Date(), scheduledDate: Date(), completionCount: 1),
            Task(id: UUID(), title: "英単語テスト", stage: .oneHourLater, createdAt: Date(), scheduledDate: Date(), completionCount: 2)
        ]
        
        return TodayTaskView()
            .environmentObject(taskManager)
            .previewLayout(.sizeThatFits)
    }
}

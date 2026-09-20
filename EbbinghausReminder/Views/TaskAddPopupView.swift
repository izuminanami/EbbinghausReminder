//
//  TaskAddPopupView.swift
//  EbbinghausReminder
//
//  Created by 泉七海 on 2025/02/05.
//

import SwiftUI

struct TaskAddPopupView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Binding var isShowing: Bool
    @State private var taskTitle = ""
    @State private var taskDate: Date

    init(isShowing: Binding<Bool>, initialDate: Date = Date()) {
        _isShowing = isShowing
        _taskDate = State(initialValue: initialDate)
    }

    var body: some View {
        VStack {
            Text("タスクを追加")
                .font(.title)
                .bold()
                .foregroundColor(Color("PrimaryColor"))
                .padding(.top, 10)

            // モダンなテキストフィールドデザイン
            TextField("タスク名を入力...", text: $taskTitle)
                .padding()
                .background(Color("BackgroundColor").opacity(0.9))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("PrimaryColor"), lineWidth: 2)
                )
                .foregroundColor(Color("TextColor"))
                .padding(.horizontal, 20)
                .onSubmit { addTask() } // エンターキーでタスク追加可能に

            VStack(alignment: .leading, spacing: 8) {
                Label("最初に復習する日", systemImage: "calendar")
                    .font(.headline)
                    .foregroundColor(Color("TextColor"))

                DatePicker("最初に復習する日", selection: $taskDate, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .background(Color("CardBackground"))
                    .cornerRadius(8)

                Text("通知は設定した時刻に届きます")
                    .font(.caption)
                    .foregroundColor(Color("GrayTextColor"))
            }
            .padding(.horizontal, 20)

            HStack {
                Button("キャンセル") {
                    withAnimation { isShowing = false }
                }
                .foregroundColor(Color("DeleteColor"))
                .padding()
                
                Button("追加") {
                    addTask()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("PrimaryColor"))
                .padding()
                .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .frame(width: 320)
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .shadow(radius: 10)
        .onTapGesture { hideKeyboard() }
        .transition(.opacity) // フェードイン・フェードアウト
    }

    private func addTask() {
        let trimmedTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        taskManager.addTask(title: trimmedTitle, date: taskDate)
        withAnimation { isShowing = false }
        taskTitle = "" // フォームをリセット
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct TaskAddPopupView_Previews: PreviewProvider {
    static var previews: some View {
        let taskManager = TaskManager()
        
        TaskAddPopupView(isShowing: .constant(true))
            .environmentObject(taskManager)
            .previewLayout(.sizeThatFits)
            .background(Color("BackgroundColor")) // 背景色を適用
    }
}

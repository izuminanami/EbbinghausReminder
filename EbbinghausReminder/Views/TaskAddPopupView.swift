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
    @State private var taskDate = Date() // 選択された日付を格納

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
                .background(Color("TextFieldBackground").opacity(0.9))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("PrimaryColor"), lineWidth: 2)
                )
                .foregroundColor(Color("TextColor"))
                .padding(.horizontal, 20)
                .onSubmit { addTask() } // エンターキーでタスク追加可能に

            VStack {
                DatePicker("", selection: $taskDate, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .background(Color("CardBackground"))
                    .cornerRadius(8)
            }
            .padding()

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
                .disabled(taskTitle.isEmpty) // タスク名が空ならボタンを無効化
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
        guard !taskTitle.isEmpty else { return }
        taskManager.addTask(title: taskTitle, date: taskDate) // 選択した日付を反映
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

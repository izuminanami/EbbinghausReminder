import SwiftUI

struct TaskEditPopupView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @Binding var isShowing: Bool
    let task: Task

    @State private var taskTitle: String
    @State private var taskDate: Date

    init(task: Task, isShowing: Binding<Bool>) {
        self.task = task
        _isShowing = isShowing
        _taskTitle = State(initialValue: task.title)
        _taskDate = State(initialValue: task.scheduledDate)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("タスクを編集")
                .font(.title2.bold())
                .foregroundColor(Color("PrimaryColor"))

            TextField("タスク名", text: $taskTitle)
                .padding()
                .background(Color("BackgroundColor").opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("PrimaryColor"), lineWidth: 2)
                }

            VStack(alignment: .leading, spacing: 8) {
                DatePicker("次の復習日", selection: $taskDate, displayedComponents: .date)
                    .datePickerStyle(.compact)

                Text("通知は設定した時刻に届きます")
                    .font(.caption)
                    .foregroundColor(Color("GrayTextColor"))
            }

            HStack {
                Button("キャンセル") {
                    withAnimation { isShowing = false }
                }
                .foregroundColor(Color("DeleteColor"))

                Spacer()

                Button("保存") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("PrimaryColor"))
                .disabled(trimmedTitle.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 330)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
    }

    private var trimmedTitle: String {
        taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        guard !trimmedTitle.isEmpty else { return }
        taskManager.updateTask(task, title: trimmedTitle, date: taskDate)
        withAnimation { isShowing = false }
    }
}

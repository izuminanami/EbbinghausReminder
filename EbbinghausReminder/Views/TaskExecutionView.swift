import SwiftUI

struct TaskExecutionView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @AppStorage("taskSortOption") private var sortOptionRawValue = TaskSortOption.scheduledDate.rawValue

    @State private var isShowingCompleted = false
    @State private var isAddingTask = false
    @State private var editingTask: Task?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                sortPicker

                if displayedTasks.isEmpty {
                    Spacer()
                    Text(isShowingCompleted ? "実行済のタスクはありません" : "実行中のタスクはありません")
                        .foregroundColor(Color("GrayTextColor"))
                    Spacer()
                } else {
                    taskList
                }
            }
            .background(Color("BackgroundColor").ignoresSafeArea())

            if isAddingTask || editingTask != nil {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isAddingTask = false
                            editingTask = nil
                        }
                    }
            }

            if isAddingTask {
                TaskAddPopupView(isShowing: $isAddingTask)
                    .transition(.opacity)
                    .zIndex(1)
            }

            if let task = editingTask {
                TaskEditPopupView(task: task, isShowing: editingTaskBinding)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Menu {
                Button {
                    withAnimation { isShowingCompleted = false }
                } label: {
                    Label("実行中", systemImage: "list.bullet")
                }
                Button {
                    withAnimation { isShowingCompleted = true }
                } label: {
                    Label("実行済", systemImage: "checkmark.circle")
                }
            } label: {
                HStack(spacing: 6) {
                    Text(isShowingCompleted ? "実行済のタスク" : "実行中のタスク")
                        .font(.title2.bold())
                    Image(systemName: "chevron.down")
                        .font(.subheadline.bold())
                }
                .foregroundColor(Color("PrimaryColor"))
            }

            Spacer()

            Button { withAnimation { isAddingTask = true } } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color("PrimaryColor"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var sortPicker: some View {
        HStack {
            Text("\(displayedTasks.count)件")
                .font(.subheadline)
                .foregroundColor(Color("GrayTextColor"))
            Spacer()
            Menu {
                Picker("並び順", selection: $sortOptionRawValue) {
                    ForEach(TaskSortOption.allCases) { option in
                        Text(option.displayName).tag(option.rawValue)
                    }
                }
            } label: {
                Label(sortOption.displayName, systemImage: "arrow.up.arrow.down")
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var taskList: some View {
        List {
            ForEach(displayedTasks) { task in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .foregroundColor(Color("TextColor"))
                        Text(task.scheduledDate, format: .dateTime.year().month().day())
                            .font(.caption)
                            .foregroundColor(Color("GrayTextColor"))
                    }
                    Spacer()
                    Text(isShowingCompleted ? "完了" : "\(task.completionCount + 1)回目")
                        .font(.subheadline)
                        .foregroundColor(Color("GrayTextColor"))
                }
                .padding(.vertical, 8)
                .listRowBackground(Color("CardBackground"))
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    if !isShowingCompleted {
                        Button {
                            editingTask = task
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                        .tint(Color("PrimaryColor"))
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        taskManager.deleteTask(task)
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                    .tint(Color("DeleteColor"))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("BackgroundColor"))
        .listStyle(.insetGrouped)
    }

    private var displayedTasks: [Task] {
        sortOption.sorted(isShowingCompleted ? taskManager.completedTasks : taskManager.tasks)
    }

    private var sortOption: TaskSortOption {
        TaskSortOption(rawValue: sortOptionRawValue) ?? .scheduledDate
    }

    private var editingTaskBinding: Binding<Bool> {
        Binding(
            get: { editingTask != nil },
            set: { if !$0 { editingTask = nil } }
        )
    }
}

#Preview {
    TaskExecutionView()
        .environmentObject(TaskManager())
}

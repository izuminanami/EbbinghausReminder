import SwiftUI

struct TodayTaskView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @AppStorage("taskSortOption") private var sortOptionRawValue = TaskSortOption.scheduledDate.rawValue

    @State private var isAddingTask = false
    @State private var isShowingInfo = false
    @State private var isShowingSettings = false
    @State private var editingTask: Task?
    @State private var completingTaskIDs: Set<UUID> = []

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                sortPicker

                if overdueTasks.isEmpty && todayTasks.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 44))
                            .foregroundColor(Color("PrimaryColor"))
                        Text("今日の復習はありません")
                            .foregroundColor(Color("GrayTextColor"))
                    }
                    Spacer()
                } else {
                    taskList
                }
            }
            .background(Color("BackgroundColor").ignoresSafeArea())

            if isPresentingPopup {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { closePopups() }
            }

            if isAddingTask {
                TaskAddPopupView(isShowing: $isAddingTask)
                    .transition(.opacity)
                    .zIndex(1)
            }

            if isShowingInfo {
                InfoView(isShowing: $isShowingInfo)
                    .transition(.opacity)
                    .zIndex(1)
            }

            if isShowingSettings {
                SettingsView(isShowing: $isShowingSettings)
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
        HStack(spacing: 16) {
            Text("今日のタスク")
                .font(.title2.bold())
                .foregroundColor(Color("PrimaryColor"))
            Spacer()
            Button { withAnimation { isShowingInfo = true } } label: {
                Image(systemName: "info.circle")
            }
            Button { withAnimation { isShowingSettings = true } } label: {
                Image(systemName: "gearshape")
            }
            Button { withAnimation { isAddingTask = true } } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
        .font(.title2)
        .foregroundColor(Color("PrimaryColor"))
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var sortPicker: some View {
        HStack {
            if !overdueTasks.isEmpty {
                Label("期限切れ \(overdueTasks.count)件", systemImage: "exclamationmark.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(Color("DeleteColor"))
            }
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
            if !overdueTasks.isEmpty {
                Section("期限切れ") {
                    ForEach(overdueTasks) { task in
                        taskRow(task, isOverdue: true)
                    }
                }
            }

            if !todayTasks.isEmpty {
                Section("今日") {
                    ForEach(todayTasks) { task in
                        taskRow(task, isOverdue: false)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("BackgroundColor"))
        .listStyle(.insetGrouped)
    }

    private func taskRow(_ task: Task, isOverdue: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .foregroundColor(Color("TextColor"))
                if isOverdue {
                    Text(task.scheduledDate, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundColor(Color("DeleteColor"))
                }
            }
            Spacer()
            Text("\(task.completionCount + 1)回目")
                .font(.subheadline)
                .foregroundColor(Color("GrayTextColor"))

            Button {
                complete(task)
            } label: {
                Image(systemName: completingTaskIDs.contains(task.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(
                        completingTaskIDs.contains(task.id) ? .green : Color("PrimaryColor")
                    )
            }
            .buttonStyle(.borderless)
            .disabled(completingTaskIDs.contains(task.id))
        }
        .padding(.vertical, 8)
        .listRowBackground(Color("CardBackground"))
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                editingTask = task
            } label: {
                Label("編集", systemImage: "pencil")
            }
            .tint(Color("PrimaryColor"))
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

    private var overdueTasks: [Task] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return sortOption.sorted(taskManager.tasks.filter {
            $0.scheduledDate < startOfToday
        })
    }

    private var todayTasks: [Task] {
        sortOption.sorted(taskManager.tasks.filter {
            Calendar.current.isDateInToday($0.scheduledDate)
        })
    }

    private var sortOption: TaskSortOption {
        TaskSortOption(rawValue: sortOptionRawValue) ?? .scheduledDate
    }

    private var isPresentingPopup: Bool {
        isAddingTask || isShowingInfo || isShowingSettings || editingTask != nil
    }

    private var editingTaskBinding: Binding<Bool> {
        Binding(
            get: { editingTask != nil },
            set: { if !$0 { editingTask = nil } }
        )
    }

    private func complete(_ task: Task) {
        guard !completingTaskIDs.contains(task.id) else { return }
        completingTaskIDs.insert(task.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeInOut(duration: 0.25)) {
                taskManager.completeTask(task)
                completingTaskIDs.remove(task.id)
            }
        }
    }

    private func closePopups() {
        withAnimation {
            isAddingTask = false
            isShowingInfo = false
            isShowingSettings = false
            editingTask = nil
        }
    }
}

#Preview {
    TodayTaskView()
        .environmentObject(TaskManager())
}

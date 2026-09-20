import SwiftUI

struct TaskCalendarView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var isAddingTask = false
    @State private var editingTask: Task?
    @State private var completingTaskIDs: Set<UUID> = []

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                monthCalendar
                selectedDayHeader

                if selectedDayTasks.isEmpty {
                    Spacer()
                    Text("この日の復習はありません")
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
                TaskAddPopupView(isShowing: $isAddingTask, initialDate: selectedDate)
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
        HStack {
            Text("カレンダー")
                .font(.title2.bold())
                .foregroundColor(Color("PrimaryColor"))
            Spacer()
            Button {
                goToToday()
            } label: {
                Text("今日")
                    .font(.subheadline.bold())
            }
            Button { withAnimation { isAddingTask = true } } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
        }
        .foregroundColor(Color("PrimaryColor"))
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var monthCalendar: some View {
        VStack(spacing: 10) {
            HStack {
                Button { moveMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(displayedMonth, format: .dateTime.year().month(.wide))
                    .font(.headline)
                    .foregroundColor(Color("TextColor"))
                Spacer()
                Button { moveMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundColor(Color("PrimaryColor"))

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.bold())
                        .foregroundColor(Color("GrayTextColor"))
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        calendarDay(date)
                    } else {
                        Color.clear
                            .frame(height: 38)
                    }
                }
            }
        }
        .padding(14)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private func calendarDay(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let hasTasks = taskManager.tasks.contains {
            calendar.isDate($0.scheduledDate, inSameDayAs: date)
        }

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = date
                completingTaskIDs.removeAll()
            }
        } label: {
            ZStack(alignment: .bottom) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white : Color("TextColor"))
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .background {
                        Circle()
                            .fill(isSelected ? Color("PrimaryColor") : .clear)
                    }

                if hasTasks {
                    Circle()
                        .fill(isSelected ? Color.white : Color("PrimaryColor"))
                        .frame(width: 5, height: 5)
                        .padding(.bottom, 2)
                }
            }
            .frame(height: 38)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: date, hasTasks: hasTasks))
    }

    private var selectedDayHeader: some View {
        HStack {
            Text(selectedDate, format: .dateTime.month(.wide).day().weekday(.wide))
                .font(.headline)
                .foregroundColor(Color("TextColor"))
            Spacer()
            if !selectedDayTasks.isEmpty {
                Text("\(selectedDayTasks.count)件")
                    .font(.subheadline)
                    .foregroundColor(Color("GrayTextColor"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 6)
    }

    private var taskList: some View {
        List {
            ForEach(selectedDayTasks) { task in
                HStack(spacing: 12) {
                    Text(task.title)
                        .foregroundColor(Color("TextColor"))
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
        }
        .scrollContentBackground(.hidden)
        .background(Color("BackgroundColor"))
        .listStyle(.insetGrouped)
    }

    private var selectedDayTasks: [Task] {
        taskManager.tasks
            .filter { calendar.isDate($0.scheduledDate, inSameDayAs: selectedDate) }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }

    private var monthDays: [Date?] {
        guard let firstDay = calendar.date(
            from: calendar.dateComponents([.year, .month], from: displayedMonth)
        ), let dayRange = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingEmptyDays = (weekday - calendar.firstWeekday + 7) % 7
        let emptyDays = Array<Date?>(repeating: nil, count: leadingEmptyDays)
        let dates = dayRange.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
        return emptyDays + dates.map(Optional.some)
    }

    private var orderedWeekdaySymbols: [String] {
        let symbols = DateFormatter().veryShortStandaloneWeekdaySymbols ?? ["日", "月", "火", "水", "木", "金", "土"]
        let startIndex = max(calendar.firstWeekday - 1, 0)
        return Array(symbols[startIndex...] + symbols[..<startIndex])
    }

    private var editingTaskBinding: Binding<Bool> {
        Binding(
            get: { editingTask != nil },
            set: { if !$0 { editingTask = nil } }
        )
    }

    private func moveMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: newMonth)) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = newMonth
            selectedDate = firstDay
            completingTaskIDs.removeAll()
        }
    }

    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDate = Date()
            displayedMonth = Date()
            completingTaskIDs.removeAll()
        }
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

    private func accessibilityLabel(for date: Date, hasTasks: Bool) -> String {
        let dateText = date.formatted(.dateTime.year().month().day())
        return hasTasks ? "\(dateText)、復習予定あり" : dateText
    }
}

#Preview {
    TaskCalendarView()
        .environmentObject(TaskManager())
}

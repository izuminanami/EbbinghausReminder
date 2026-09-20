import Foundation

enum TaskSortOption: String, CaseIterable, Identifiable {
    case scheduledDate
    case createdDate
    case title

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .scheduledDate:
            return "復習日順"
        case .createdDate:
            return "登録日順"
        case .title:
            return "名前順"
        }
    }

    func sorted(_ tasks: [Task]) -> [Task] {
        switch self {
        case .scheduledDate:
            return tasks.sorted { $0.scheduledDate < $1.scheduledDate }
        case .createdDate:
            return tasks.sorted { $0.createdAt < $1.createdAt }
        case .title:
            return tasks.sorted {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        }
    }
}

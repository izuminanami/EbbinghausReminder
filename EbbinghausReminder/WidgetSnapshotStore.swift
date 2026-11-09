import Foundation
import WidgetKit

struct WidgetTaskSnapshot: Codable {
    let id: UUID
    let title: String
    let scheduledDate: Date
    let completionCount: Int
}

enum WidgetSnapshotStore {
    static let appGroupIdentifier = "group.-7imuzi.EbbinghausReminder"
    static let tasksKey = "widgetTasks"
    static let isSubscribedKey = "widgetIsSubscribed"
    static let entitlementCheckedAtKey = "widgetEntitlementCheckedAt"
    static let widgetKind = "EbbinghausTodayWidget"

    static func saveTasks(_ tasks: [Task]) {
        let snapshots = tasks.map {
            WidgetTaskSnapshot(
                id: $0.id,
                title: $0.title,
                scheduledDate: $0.scheduledDate,
                completionCount: $0.completionCount
            )
        }

        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = try? JSONEncoder().encode(snapshots) else {
            return
        }

        defaults.set(data, forKey: tasksKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func saveSubscriptionStatus(isSubscribed: Bool) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        defaults.set(isSubscribed, forKey: isSubscribedKey)
        defaults.set(Date(), forKey: entitlementCheckedAtKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}

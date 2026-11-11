import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import Foundation
import OSLog

/// Firebase and unified logging entry point. Never send task titles or other user-entered text.
final class AnalyticsService {
    static let shared = AnalyticsService()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "EbbinghausReminder",
        category: "Analytics"
    )

    private init() {}

    var isConfigured: Bool {
        FirebaseApp.app() != nil
    }

    func log(_ name: String, parameters: [String: Any] = [:]) {
        let sanitized = sanitize(parameters)
        logger.info("event=\(name, privacy: .public) parameters=\(String(describing: sanitized), privacy: .private(mask: .hash))")
        guard isConfigured else { return }
        Analytics.logEvent(name, parameters: sanitized)
    }

    func screen(_ name: String, className: String? = nil) {
        log(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: name,
            AnalyticsParameterScreenClass: className ?? name
        ])
    }

    func setUserProperty(_ value: String?, forName name: String) {
        logger.info("user_property=\(name, privacy: .public)")
        guard isConfigured else { return }
        Analytics.setUserProperty(value, forName: name)
    }

    func setTaskCounts(active: Int, completed: Int) {
        setUserProperty(Self.countBucket(active), forName: "active_task_bucket")
        setUserProperty(Self.countBucket(completed), forName: "completed_task_bucket")
    }

    func breadcrumb(_ message: String) {
        logger.debug("\(message, privacy: .public)")
        guard isConfigured else { return }
        Crashlytics.crashlytics().log(message)
    }

    func record(_ error: Error, context: String, extra: [String: Any] = [:]) {
        logger.error("error_context=\(context, privacy: .public) error=\(String(describing: error), privacy: .private(mask: .hash))")
        guard isConfigured else { return }

        let crashlytics = Crashlytics.crashlytics()
        crashlytics.setCustomValue(context, forKey: "error_context")
        sanitize(extra).forEach { crashlytics.setCustomValue($0.value, forKey: $0.key) }
        crashlytics.record(error: error)
    }

    static func dayOffset(from date: Date, to reference: Date = Date()) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: reference),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
    }

    static func dayOffsetBucket(_ value: Int) -> String {
        switch value {
        case ..<(-30): return "lt_minus_30"
        case -30 ... -8: return "minus_30_to_8"
        case -7 ... -2: return "minus_7_to_2"
        case -1: return "minus_1"
        case 0: return "today"
        case 1: return "plus_1"
        case 2 ... 7: return "plus_2_to_7"
        case 8 ... 30: return "plus_8_to_30"
        default: return "gt_30"
        }
    }

    static func countBucket(_ count: Int) -> String {
        switch count {
        case 0: return "0"
        case 1: return "1"
        case 2 ... 5: return "2_to_5"
        case 6 ... 10: return "6_to_10"
        case 11 ... 25: return "11_to_25"
        default: return "26_plus"
        }
    }

    private func sanitize(_ parameters: [String: Any]) -> [String: Any] {
        parameters.reduce(into: [:]) { result, entry in
            switch entry.value {
            case let value as String:
                result[entry.key] = String(value.prefix(100))
            case let value as Int:
                result[entry.key] = value
            case let value as Int64:
                result[entry.key] = value
            case let value as Double:
                result[entry.key] = value
            case let value as Float:
                result[entry.key] = value
            case let value as Bool:
                result[entry.key] = value ? 1 : 0
            default:
                result[entry.key] = String(describing: entry.value).prefix(100).description
            }
        }
    }
}

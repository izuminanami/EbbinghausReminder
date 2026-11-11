import AppTrackingTransparency
import Combine
import FirebaseCore
import GoogleMobileAds

@MainActor
final class TrackingAuthorizationManager: ObservableObject {
    static let shared = TrackingAuthorizationManager()

    @Published private(set) var areSDKsReady = false

    private var isPreparing = false
    private var launchSource = "standard"

    private init() {}

    func recordLaunchSource(_ source: String) {
        launchSource = source
    }

    func prepareSDKs() async {
        guard !areSDKsReady, !isPreparing else { return }
        isPreparing = true
        defer { isPreparing = false }

        let status = await requestAuthorizationIfNeeded()

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            MobileAds.shared.start { _ in
                continuation.resume()
            }
        }

        AnalyticsService.shared.log("app_launched", parameters: [
            "launch_source": launchSource
        ])
        AnalyticsService.shared.log("tracking_authorization_resolved", parameters: [
            "status": Self.analyticsName(for: status)
        ])
        areSDKsReady = true
    }

    private func requestAuthorizationIfNeeded() async -> ATTrackingManager.AuthorizationStatus {
        let currentStatus = ATTrackingManager.trackingAuthorizationStatus
        guard currentStatus == .notDetermined else { return currentStatus }
        return await ATTrackingManager.requestTrackingAuthorization()
    }

    private static func analyticsName(for status: ATTrackingManager.AuthorizationStatus) -> String {
        switch status {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "not_determined"
        @unknown default: return "unknown"
        }
    }
}

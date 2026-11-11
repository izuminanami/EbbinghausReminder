//
//  EbbinghausReminderApp.swift
//  EbbinghausReminder
//
//  Created by 泉七海 on 2025/02/05.
//

import SwiftUI
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        TrackingAuthorizationManager.shared.recordLaunchSource(
            launchOptions == nil ? "standard" : "system"
        )
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        AnalyticsService.shared.log("notification_received", parameters: ["app_state": "foreground"])
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        AnalyticsService.shared.log("notification_opened", parameters: [
            "action": response.actionIdentifier == UNNotificationDefaultActionIdentifier ? "default" : "other"
        ])
        completionHandler()
    }
}

@main
struct EbbinghausReminderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var taskManager = TaskManager()
    @StateObject private var subscriptionStore = SupportSubscriptionStore()

    init() {
        // タブバーのデザインを変更
        UITabBar.appearance().backgroundColor = UIColor(named: "BackgroundColor")
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: "GrayTextColor")
        UITabBar.appearance().tintColor = UIColor(named: "PrimaryColor")
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(taskManager)
                .environmentObject(subscriptionStore)
        }
    }
}

private struct AppRootView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var subscriptionStore: SupportSubscriptionStore
    @StateObject private var trackingAuthorization = TrackingAuthorizationManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isShowingOnboarding = false
    @State private var didEvaluateOnboarding = false
    @State private var selectedTab = Self.initialTab
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    TodayTaskView()
                        .tag(0)
                        .tabItem {
                            Label("今日のタスク", systemImage: "calendar")
                        }
                    TaskExecutionView()
                        .tag(1)
                        .tabItem {
                            Label("実行中", systemImage: "list.bullet")
                        }
                    TaskCalendarView()
                        .tag(2)
                        .tabItem {
                            Label("カレンダー", systemImage: "calendar.circle")
                        }
                }

                if didEvaluateOnboarding
                    && !isShowingOnboarding
                    && !Self.isStoreScreenshotMode
                    && trackingAuthorization.areSDKsReady
                    && subscriptionStore.hasCheckedEntitlement
                    && !subscriptionStore.isSubscribed {
                    Divider()
                    AdMobBannerView(width: geometry.size.width)
                        .padding(.top, 4)
                }
            }
        }
        .background(Color("BackgroundColor").ignoresSafeArea())
        .fullScreenCover(isPresented: $isShowingOnboarding) {
            OnboardingView {
                hasCompletedOnboarding = true
                isShowingOnboarding = false
            }
            .environmentObject(taskManager)
            .interactiveDismissDisabled()
        }
        .onAppear(perform: evaluateOnboarding)
        .onChange(of: selectedTab) { _, newValue in
            let screen = Self.screenName(for: newValue)
            AnalyticsService.shared.log("tab_selected", parameters: ["tab": screen])
            AnalyticsService.shared.screen(screen)
        }
        .onChange(of: scenePhase) { _, newPhase in
            AnalyticsService.shared.log("app_lifecycle_changed", parameters: [
                "phase": Self.scenePhaseName(newPhase)
            ])
        }
        .onOpenURL { url in
            guard url.scheme == "ebbinghausreminder" else { return }
            AnalyticsService.shared.log("deep_link_opened", parameters: [
                "destination": url.host ?? "unknown"
            ])
            selectedTab = 0
        }
        .task {
            await subscriptionStore.prepare()
        }
        .task(id: shouldPrepareTrackingSDKs) {
            guard shouldPrepareTrackingSDKs else { return }
            await trackingAuthorization.prepareSDKs()
        }
    }

    private func evaluateOnboarding() {
        guard !didEvaluateOnboarding else { return }
        didEvaluateOnboarding = true
        AnalyticsService.shared.screen(Self.screenName(for: selectedTab))

        if Self.isStoreScreenshotMode {
            isShowingOnboarding = false
            return
        }

        let defaults = UserDefaults.standard
        let onboardingWasEvaluated = defaults.object(forKey: "hasCompletedOnboarding") != nil
        let hasExistingData = defaults.data(forKey: "tasks") != nil
            || defaults.data(forKey: "completedTasks") != nil

        if !onboardingWasEvaluated && hasExistingData {
            hasCompletedOnboarding = true
            AnalyticsService.shared.log("onboarding_migrated_existing_user")
        } else {
            isShowingOnboarding = !hasCompletedOnboarding
        }
        AnalyticsService.shared.setUserProperty(
            hasCompletedOnboarding ? "completed" : "not_completed",
            forName: "onboarding_status"
        )
        if isShowingOnboarding {
            AnalyticsService.shared.log("onboarding_started")
        }
    }

    private static func screenName(for tab: Int) -> String {
        switch tab {
        case 1: return "task_list"
        case 2: return "calendar"
        default: return "today"
        }
    }

    private static func scenePhaseName(_ phase: ScenePhase) -> String {
        switch phase {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }

    private var shouldPrepareTrackingSDKs: Bool {
        didEvaluateOnboarding && !isShowingOnboarding && !Self.isStoreScreenshotMode
    }

    private static var isStoreScreenshotMode: Bool {
        #if DEBUG
        StoreScreenshotConfiguration.isEnabled
        #else
        false
        #endif
    }

    private static var initialTab: Int {
        #if DEBUG
        StoreScreenshotConfiguration.selectedTab
        #else
        0
        #endif
    }
}

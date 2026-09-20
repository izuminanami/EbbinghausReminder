//
//  EbbinghausReminderApp.swift
//  EbbinghausReminder
//
//  Created by 泉七海 on 2025/02/05.
//

import SwiftUI
import GoogleMobileAds

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MobileAds.shared.start(completionHandler: nil)
        return true
    }
}

@main
struct EbbinghausReminderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var taskManager = TaskManager()

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
        }
    }
}

private struct AppRootView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isShowingOnboarding = false
    @State private var didEvaluateOnboarding = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TabView {
                    TodayTaskView()
                        .tabItem {
                            Label("今日のタスク", systemImage: "calendar")
                        }
                    TaskExecutionView()
                        .tabItem {
                            Label("実行中", systemImage: "list.bullet")
                        }
                    TaskCalendarView()
                        .tabItem {
                            Label("カレンダー", systemImage: "calendar.circle")
                        }
                }

                if didEvaluateOnboarding && !isShowingOnboarding {
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
    }

    private func evaluateOnboarding() {
        guard !didEvaluateOnboarding else { return }
        didEvaluateOnboarding = true

        let defaults = UserDefaults.standard
        let onboardingWasEvaluated = defaults.object(forKey: "hasCompletedOnboarding") != nil
        let hasExistingData = defaults.data(forKey: "tasks") != nil
            || defaults.data(forKey: "completedTasks") != nil

        if !onboardingWasEvaluated && hasExistingData {
            hasCompletedOnboarding = true
        } else {
            isShowingOnboarding = !hasCompletedOnboarding
        }
    }
}

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

        // AdMob (12.2.0)で動作
        MobileAds.shared.start(completionHandler: nil)
        // GADMobileAds.sharedInstance().start(completionHandler: nil)
        return true
    }
    
}

@main
struct EbbinghausReminderApp: App {
    @StateObject var taskManager = TaskManager()

    init() {
        // タブバーのデザインを変更
        UITabBar.appearance().backgroundColor = UIColor(named: "BackgroundColor")
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: "GrayTextColor")
        UITabBar.appearance().tintColor = UIColor(named: "PrimaryColor")
    }

    var body: some Scene {
        WindowGroup {
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
            .background(Color("BackgroundColor").edgesIgnoringSafeArea(.all))
            .environmentObject(taskManager)
            AdMobBannerView()
            .frame(width: 320, height: 50)
        }
    }
}

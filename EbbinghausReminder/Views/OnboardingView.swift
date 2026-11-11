import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @State private var page = 0
    @State private var notificationTime = Date()

    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                if page < 2 {
                    Button("あとで") {
                        AnalyticsService.shared.log("onboarding_skipped", parameters: ["page": page])
                        onFinish()
                    }
                    .foregroundColor(Color("GrayTextColor"))
                }
            }
            .frame(height: 24)

            TabView(selection: $page) {
                OnboardingPage(
                    icon: "brain.head.profile",
                    title: "復習日は、おまかせ",
                    message: "覚えたい内容を登録するだけ。忘れやすいタイミングに合わせて、次の復習日を自動で組み立てます。"
                )
                .tag(0)

                OnboardingPage(
                    icon: "arrow.triangle.2.circlepath",
                    title: "4回の復習で定着",
                    message: "今日、1日後、1週間後、1か月後。終わったタスクはチェックするだけで次の復習へ進みます。"
                )
                .tag(1)

                notificationPage
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            if page < 2 {
                Button("次へ") {
                    AnalyticsService.shared.log("onboarding_next_tapped", parameters: ["from_page": page])
                    withAnimation { page += 1 }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("PrimaryColor"))
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    Button("通知を設定して始める") {
                        taskManager.updateNotificationTime(to: notificationTime, source: "onboarding")
                        AnalyticsService.shared.log("onboarding_completed", parameters: [
                            "notification_choice": "enabled"
                        ])
                        AnalyticsService.shared.setUserProperty("completed", forName: "onboarding_status")
                        onFinish()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("PrimaryColor"))
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                    Button("通知なしで始める") {
                        AnalyticsService.shared.log("onboarding_completed", parameters: [
                            "notification_choice": "disabled"
                        ])
                        AnalyticsService.shared.setUserProperty("completed", forName: "onboarding_status")
                        onFinish()
                    }
                    .foregroundColor(Color("GrayTextColor"))
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .background(Color("BackgroundColor").ignoresSafeArea())
        .onAppear {
            notificationTime = taskManager.preferredNotificationTime
            AnalyticsService.shared.screen("onboarding_1")
        }
        .onChange(of: page) { _, newPage in
            AnalyticsService.shared.log("onboarding_page_viewed", parameters: ["page": newPage + 1])
            AnalyticsService.shared.screen("onboarding_\(newPage + 1)")
        }
    }

    private var notificationPage: some View {
        VStack(spacing: 22) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 68))
                .foregroundStyle(Color("PrimaryColor"))

            Text("忘れない時刻を選ぶ")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(Color("TextColor"))

            Text("復習しやすい時刻に、まとめてお知らせします。時刻はあとから歯車ボタンで変更できます。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("GrayTextColor"))

            DatePicker(
                "通知時刻",
                selection: $notificationTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
        }
        .padding(.bottom, 24)
    }
}

private struct OnboardingPage: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(Color("PrimaryColor"))

            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(Color("TextColor"))

            Text(message)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("GrayTextColor"))
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 24)
    }
}

#Preview {
    OnboardingView(onFinish: {})
        .environmentObject(TaskManager())
}

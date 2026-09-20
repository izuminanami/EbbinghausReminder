import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @Environment(\.scenePhase) private var scenePhase
    @Binding var isShowing: Bool
    @State private var notificationTime = Date()
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("通知設定")
                    .font(.title2.bold())
                    .foregroundColor(Color("PrimaryColor"))
                Spacer()
                Button {
                    withAnimation { isShowing = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                }
                .foregroundColor(Color("PrimaryColor"))
            }

            Text("復習通知の時刻")
                .font(.headline)
                .foregroundColor(Color("TextColor"))

            HStack(spacing: 8) {
                Image(systemName: notificationStatusIcon)
                    .foregroundColor(notificationStatusColor)
                Text(notificationStatusText)
                    .font(.subheadline)
                    .foregroundColor(Color("TextColor"))
                Spacer()
                if notificationStatus == .denied {
                    Button("設定を開く") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                    .font(.subheadline.bold())
                }
            }
            .padding(12)
            .background(Color("BackgroundColor"))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            DatePicker(
                "通知時刻",
                selection: $notificationTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)

            Text("保存すると、実行中タスクの通知が選択した時刻に更新されます。通知はタスクを初めて登録したときにも確認されます。")
                .font(.footnote)
                .foregroundColor(Color("GrayTextColor"))

            Button("時刻を保存") {
                taskManager.updateNotificationTime(to: notificationTime)
                withAnimation { isShowing = false }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("PrimaryColor"))
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .frame(width: 340)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .onAppear {
            notificationTime = taskManager.preferredNotificationTime
            refreshNotificationStatus()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                refreshNotificationStatus()
            }
        }
    }

    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return "通知は有効です"
        case .denied:
            return "通知がオフです"
        case .notDetermined:
            return "保存時に通知を確認します"
        @unknown default:
            return "通知状態を確認できません"
        }
    }

    private var notificationStatusIcon: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return "checkmark.circle.fill"
        case .denied:
            return "exclamationmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .denied:
            return Color("DeleteColor")
        case .notDetermined:
            return Color("PrimaryColor")
        @unknown default:
            return Color("GrayTextColor")
        }
    }

    private func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }
}

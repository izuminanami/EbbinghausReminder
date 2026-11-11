import StoreKit
import SwiftUI

struct SupportDeveloperView: View {
    private static let privacyPolicyURL = URL(string: "https://izumi73.hp.peraichi.com/")!
    private static let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionStore: SupportSubscriptionStore
    let source: String

    init(source: String = "unknown") {
        self.source = source
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: subscriptionStore.isSubscribed ? "crown.fill" : "crown")
                        .font(.system(size: 54))
                        .foregroundColor(Color("PrimaryColor"))
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text("開発者を支援")
                            .font(.title.bold())
                            .foregroundColor(Color("TextColor"))
                        Text("広告を削除して、今日の復習ウィジェットを利用できます。")
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color("GrayTextColor"))
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        benefitRow(icon: "rectangle.slash", text: "アプリ内のバナー広告を削除")
                        benefitRow(icon: "checklist", text: "ホーム画面で今日の復習を確認")
                        benefitRow(icon: "heart.fill", text: "新機能の開発と継続的な改善を支援")
                        benefitRow(icon: "arrow.triangle.2.circlepath", text: "いつでもキャンセル可能")
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("CardBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    purchaseSection

                    Text("お支払いはApple IDに請求され、期間終了の24時間前までにキャンセルしない限り自動更新されます。サブスクリプションはApp Storeのアカウント設定から管理できます。")
                        .font(.caption)
                        .foregroundColor(Color("GrayTextColor"))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 20) {
                        Link("プライバシーポリシー", destination: Self.privacyPolicyURL)
                        Link("利用規約", destination: Self.termsOfUseURL)
                    }
                    .font(.footnote)
                }
                .padding(20)
            }
            .background(Color("BackgroundColor").ignoresSafeArea())
            .navigationTitle("サポーター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .task {
            AnalyticsService.shared.screen("support_paywall")
            AnalyticsService.shared.log("support_paywall_viewed", parameters: [
                "source": source,
                "is_subscribed": subscriptionStore.isSubscribed
            ])
            if subscriptionStore.loadState == .idle {
                await subscriptionStore.prepare()
            }
        }
    }

    @ViewBuilder
    private var purchaseSection: some View {
        if subscriptionStore.isSubscribed {
            Label("ご支援ありがとうございます", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundColor(Color("PrimaryColor"))
                .frame(maxWidth: .infinity)
                .padding()
        } else {
            switch subscriptionStore.loadState {
            case .idle, .loading:
                ProgressView("購入情報を読み込み中…")
                    .frame(maxWidth: .infinity)
                    .padding()
            case .loaded:
                if let product = subscriptionStore.product {
                    VStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Text(product.displayName)
                                .font(.headline)
                                .foregroundColor(Color("TextColor"))
                            Text("1か月ごとの自動更新 • \(product.displayPrice)")
                                .font(.subheadline)
                                .foregroundColor(Color("GrayTextColor"))
                        }

                        Button {
                            _Concurrency.Task { await subscriptionStore.purchase() }
                        } label: {
                            HStack {
                                if subscriptionStore.isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text(subscriptionStore.isPurchasing ? "処理中…" : "月額 \(product.displayPrice)で支援する")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color("PrimaryColor"))
                        .disabled(subscriptionStore.isPurchasing)

                        restoreButton
                    }
                }
            case .failed:
                VStack(spacing: 12) {
                    Button("もう一度読み込む") {
                        _Concurrency.Task { await subscriptionStore.loadProduct() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("PrimaryColor"))

                    restoreButton
                }
            }

            if let errorMessage = subscriptionStore.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(Color("DeleteColor"))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var restoreButton: some View {
        Button("購入を復元") {
            _Concurrency.Task { await subscriptionStore.restorePurchases() }
        }
        .font(.subheadline)
    }

    private func benefitRow(icon: String, text: String) -> some View {
        Label {
            Text(text)
                .foregroundColor(Color("TextColor"))
        } icon: {
            Image(systemName: icon)
                .foregroundColor(Color("PrimaryColor"))
                .frame(width: 24)
        }
    }
}

struct SupportSubscriptionButton: View {
    @EnvironmentObject private var subscriptionStore: SupportSubscriptionStore
    @Binding var isPresented: Bool
    let source: String

    var body: some View {
        if !subscriptionStore.isSubscribed {
            Button {
                AnalyticsService.shared.log("support_button_tapped", parameters: ["source": source])
                isPresented = true
            } label: {
                Image(systemName: "crown")
                    .accessibilityLabel("広告を削除して開発者を支援")
            }
        }
    }
}

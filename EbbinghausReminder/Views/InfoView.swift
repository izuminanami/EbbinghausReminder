//
//  InfoView.swift
//  EbbinghausReminder
//
//  Created by 泉七海 on 2025/02/05.
//

import SwiftUI

struct InfoView: View {
    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            HStack {
                Spacer()
            Button(action: {
                
                    withAnimation {
                        isShowing = false // 閉じるボタンでポップアップを閉じる
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(Color("PrimaryColor"))
                }
                .padding()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    SectionHeader(title: "🚀  アプリの概要")
                    Text("このアプリはエビングハウスの忘却曲線に基づき、効率的に記憶を定着させるための復習リマインダーです。")
                        .padding(.horizontal)
                        .foregroundColor(Color("TextColor"))
                    
                    SectionHeader(title: "📝  アプリの使い方")
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(icon: "plus.circle", text: "タスクを追加して学習を記録")
                        InfoRow(icon: "checkmark.circle", text: "タスクをこなし定着率を向上")
                        InfoRow(icon: "arrow.clockwise", text: "1回目 → 1日後に再表示")
                        InfoRow(icon: "arrow.clockwise", text: "2回目 → 1週間後に再表示")
                        InfoRow(icon: "arrow.clockwise", text: "3回目 → 1ヶ月後に再表示")
                        InfoRow(icon: "trophy", text: "4回目 → 完了済へ")
                    }
                    .padding(.horizontal)
                    
                    SectionHeader(title: "⚙️  便利な機能")
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(icon: "hand.tap", text: "左スワイプで削除、右スワイプで編集")
                        InfoRow(icon: "arrow.up.arrow.down", text: "復習日・登録日・名前で並べ替え")
                        InfoRow(icon: "calendar", text: "予定マーク付きカレンダーで日程を確認")
                        InfoRow(icon: "bell", text: "歯車ボタンから通知時刻を変更")
                        InfoRow(icon: "paintbrush", text: "ダークモード対応")
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
        .frame(width: 330, height: 600)
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .shadow(radius: 10)
        .transition(.opacity) // フェードイン・フェードアウトのアニメーション
        .zIndex(1) // 他のビューより前面に表示
    }
}

// セクションヘッダー
struct SectionHeader: View {
    var title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .bold()
            .foregroundColor(Color("PrimaryColor"))
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("CardBackground"))
            .cornerRadius(8)
            .padding(.horizontal)
    }
}

// アイコン付きリスト項目
struct InfoRow: View {
    var icon: String
    var text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("PrimaryColor"))
            Text(text)
                .foregroundColor(Color("TextColor"))
            Spacer()
        }
        .padding(4)
    }
}

//　プレビュー
struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView(isShowing: .constant(true))
            .previewLayout(.sizeThatFits)
            .background(Color("BackgroundColor"))
    }
}

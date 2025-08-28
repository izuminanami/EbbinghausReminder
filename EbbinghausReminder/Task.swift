//
//  Task.swift
//  EbbinghausReminder
//
//  Created by 泉七海 on 2025/02/05.
//

import Foundation

enum TaskStage: String, Codable {
    case oneHourLater = "1時間後"
    case oneDayLater = "1日後"
    case oneWeekLater = "1週間後"
    case oneMonthLater = "1ヶ月後"
    case completed = "完了"
}

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var stage: TaskStage
    var createdAt: Date
    var scheduledDate: Date
    var completionCount: Int
}

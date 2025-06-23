//
//  ReviewEntry.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import Foundation

// MARK: - 复盘记录数据模型
struct ReviewEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let userName: String
    
    // 基础信息
    let weather: WeatherType
    let moodBase: String // 心情底色
    
    // 8个复盘维度
    let energySource: String // ❤️ 今日能量源泉
    let timeObservation: String // ⏳ 时间之河观察
    let emotionExploration: String // 🌦️ 情绪晴雨探险
    let cognitiveBreakthroughGood: String // 💡 认知突破时刻 - 成长
    let cognitiveBreakthroughBad: String // 💡 认知突破时刻 - 旧模式
    let tomorrowPlanAvoid: String // 🗺️ 明日微调地图 - 想绕开的陷阱
    let tomorrowPlanSeed: String // 🗺️ 明日微调地图 - 想播种的种子
    let freeWriting: String // 🌌 心灵后花园
    let dailyMetaphor: String // 🔮 隐喻今日
    
    // 元数据
    let createdAt: Date
    let updatedAt: Date
    
    // AI分析结果（可选）
    let aiAnalysis: String?
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        userName: String = "",
        weather: WeatherType = .sunny,
        moodBase: String = "",
        energySource: String = "",
        timeObservation: String = "",
        emotionExploration: String = "",
        cognitiveBreakthroughGood: String = "",
        cognitiveBreakthroughBad: String = "",
        tomorrowPlanAvoid: String = "",
        tomorrowPlanSeed: String = "",
        freeWriting: String = "",
        dailyMetaphor: String = "",
        aiAnalysis: String? = nil
    ) {
        self.id = id
        self.date = date
        self.userName = userName
        self.weather = weather
        self.moodBase = moodBase
        self.energySource = energySource
        self.timeObservation = timeObservation
        self.emotionExploration = emotionExploration
        self.cognitiveBreakthroughGood = cognitiveBreakthroughGood
        self.cognitiveBreakthroughBad = cognitiveBreakthroughBad
        self.tomorrowPlanAvoid = tomorrowPlanAvoid
        self.tomorrowPlanSeed = tomorrowPlanSeed
        self.freeWriting = freeWriting
        self.dailyMetaphor = dailyMetaphor
        self.createdAt = Date()
        self.updatedAt = Date()
        self.aiAnalysis = aiAnalysis
    }
}

// MARK: - 天气类型枚举
enum WeatherType: String, CaseIterable, Codable {
    case sunny = "☀️"
    case cloudy = "☁️"
    case rainy = "🌧️"
    case snowy = "❄️"
    case windy = "💨"
    case foggy = "🌫️"
    
    var description: String {
        switch self {
        case .sunny: return "晴天"
        case .cloudy: return "多云"
        case .rainy: return "雨天"
        case .snowy: return "雪天"
        case .windy: return "大风"
        case .foggy: return "雾天"
        }
    }
}

// MARK: - 扩展方法
extension ReviewEntry {
    
    /// 格式化日期显示
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    /// 检查是否为今日复盘
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// 获取复盘完成度（百分比）
    var completionPercentage: Double {
        let fields = [
            energySource, timeObservation, emotionExploration,
            cognitiveBreakthroughGood, cognitiveBreakthroughBad,
            tomorrowPlanAvoid, tomorrowPlanSeed, freeWriting, dailyMetaphor
        ]
        
        let completedFields = fields.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return Double(completedFields.count) / Double(fields.count)
    }
    
    /// 获取复盘状态
    var status: ReviewStatus {
        let percentage = completionPercentage
        if percentage == 0 {
            return .notStarted
        } else if percentage < 1.0 {
            return .inProgress
        } else {
            return .completed
        }
    }
}

// MARK: - 复盘状态枚举
enum ReviewStatus {
    case notStarted
    case inProgress
    case completed
    
    var description: String {
        switch self {
        case .notStarted: return "未开始"
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        }
    }
    
    var color: String {
        switch self {
        case .notStarted: return "gray"
        case .inProgress: return "orange"
        case .completed: return "green"
        }
    }
}

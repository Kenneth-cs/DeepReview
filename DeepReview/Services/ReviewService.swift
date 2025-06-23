//
//  ReviewService.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import Foundation
import Combine

// MARK: - 复盘数据管理服务
class ReviewService: ObservableObject {
    
    // MARK: - 发布属性
    @Published var reviews: [ReviewEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - 私有属性
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let reviewsFileName = "reviews.json"
    
    // MARK: - 初始化
    init() {
        // 获取Documents目录
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // 加载已保存的复盘记录
        loadReviews()
    }
    
    // MARK: - 计算属性 - 统计数据
    
    /// 连续复盘天数
    var streakDays: Int {
        guard !reviews.isEmpty else { return 0 }
        
        let sortedReviews = reviews.sorted { $0.date > $1.date }
        var streak = 0
        let calendar = Calendar.current
        var currentDate = Date()
        
        for review in sortedReviews {
            if calendar.isDate(review.date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    /// 本月复盘数量
    var monthlyReviews: Int {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        return reviews.filter { review in
            let reviewMonth = calendar.component(.month, from: review.date)
            let reviewYear = calendar.component(.year, from: review.date)
            return reviewMonth == currentMonth && reviewYear == currentYear
        }.count
    }
    
    /// 总复盘数量
    var totalReviews: Int {
        reviews.count
    }
    
    /// 今日是否已复盘
    var hasTodayReview: Bool {
        reviews.contains { Calendar.current.isDateInToday($0.date) }
    }
    
    /// 获取今日复盘记录
    var todayReview: ReviewEntry? {
        reviews.first { Calendar.current.isDateInToday($0.date) }
    }
    
    // MARK: - 公共方法
    
    /// 保存复盘记录
    func saveReview(_ review: ReviewEntry) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // 检查是否已存在今日复盘，如果存在则更新，否则添加
        if let existingIndex = reviews.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
            reviews[existingIndex] = review
        } else {
            reviews.append(review)
        }
        
        saveToFile()
        
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    /// 删除复盘记录
    func deleteReview(_ review: ReviewEntry) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        reviews.removeAll { $0.id == review.id }
        saveToFile()
        
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    /// 获取指定日期的复盘记录
    func getReview(for date: Date) -> ReviewEntry? {
        return reviews.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    /// 获取最近的复盘记录
    func getRecentReviews(limit: Int = 10) -> [ReviewEntry] {
        return Array(reviews.sorted { $0.date > $1.date }.prefix(limit))
    }
    
    /// 搜索复盘记录
    func searchReviews(keyword: String) -> [ReviewEntry] {
        guard !keyword.isEmpty else { return reviews }
        
        return reviews.filter { review in
            review.energySource.localizedCaseInsensitiveContains(keyword) ||
            review.timeObservation.localizedCaseInsensitiveContains(keyword) ||
            review.emotionExploration.localizedCaseInsensitiveContains(keyword) ||
            review.freeWriting.localizedCaseInsensitiveContains(keyword) ||
            review.dailyMetaphor.localizedCaseInsensitiveContains(keyword)
        }
    }
    
    // MARK: - 私有方法
    
    /// 从文件加载复盘记录
    private func loadReviews() {
        let fileURL = documentsDirectory.appendingPathComponent(reviewsFileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("复盘记录文件不存在，创建空列表")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let loadedReviews = try JSONDecoder().decode([ReviewEntry].self, from: data)
            
            DispatchQueue.main.async {
                self.reviews = loadedReviews
                print("成功加载 \(loadedReviews.count) 条复盘记录")
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "加载复盘记录失败: \(error.localizedDescription)"
                print("加载复盘记录失败: \(error)")
            }
        }
    }
    
    /// 保存复盘记录到文件
    private func saveToFile() {
        let fileURL = documentsDirectory.appendingPathComponent(reviewsFileName)
        
        do {
            let data = try JSONEncoder().encode(reviews)
            try data.write(to: fileURL)
            print("成功保存 \(reviews.count) 条复盘记录")
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "保存复盘记录失败: \(error.localizedDescription)"
                print("保存复盘记录失败: \(error)")
            }
        }
    }
    
    /// 清空所有数据（用于测试）
    func clearAllData() {
        reviews.removeAll()
        saveToFile()
    }
}

// MARK: - 扩展：导出功能
extension ReviewService {
    
    /// 导出复盘记录为JSON字符串
    func exportReviewsAsJSON() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(reviews)
            return String(data: data, encoding: .utf8)
        } catch {
            errorMessage = "导出失败: \(error.localizedDescription)"
            return nil
        }
    }
    
    /// 导出复盘记录为CSV格式
    func exportReviewsAsCSV() -> String {
        var csvContent = "日期,天气,心情底色,能量源泉,时间观察,情绪探险,认知突破(成长),认知突破(旧模式),明日计划(避免),明日计划(播种),自由书写,隐喻今日\n"
        
        for review in reviews.sorted(by: { $0.date > $1.date }) {
            let row = [
                review.formattedDate,
                review.weather.description,
                review.moodBase,
                review.energySource,
                review.timeObservation,
                review.emotionExploration,
                review.cognitiveBreakthroughGood,
                review.cognitiveBreakthroughBad,
                review.tomorrowPlanAvoid,
                review.tomorrowPlanSeed,
                review.freeWriting,
                review.dailyMetaphor
            ].map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }.joined(separator: ",")
            
            csvContent += row + "\n"
        }
        
        return csvContent
    }
}

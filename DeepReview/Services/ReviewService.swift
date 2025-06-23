//
//  ReviewService.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import Foundation
import Combine

// MARK: - 数据完整性状态
enum DataIntegrityStatus: String, Codable, CaseIterable {
    case healthy = "健康"
    case degraded = "轻微损坏"
    case corrupted = "严重损坏"
    case unknown = "未知"
}

// MARK: - 复盘数据管理服务
class ReviewService: ObservableObject {
    
    // MARK: - 单例模式
    static let shared = ReviewService()
    
    // MARK: - 发布属性
    @Published var reviews: [ReviewEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var dataIntegrityStatus: DataIntegrityStatus = .unknown
    @Published var lastBackupDate: Date?
    
    // MARK: - 私有属性
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let reviewsFileName = "reviews.json"
    private let backupFileName = "reviews_backup.json"
    
    // MARK: - 初始化
    private init() {
        // 获取文档目录
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // 加载现有数据
        loadReviews()
        
        // 检查数据完整性
        Task {
            await performDataIntegrityCheck()
        }
    }
    
    // MARK: - 数据加载
    func loadReviews() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            do {
                let fileURL = self.documentsDirectory.appendingPathComponent(self.reviewsFileName)
                
                if !self.fileManager.fileExists(atPath: fileURL.path) {
                    // 文件不存在，创建空数组
                    DispatchQueue.main.async {
                        self.reviews = []
                        self.isLoading = false
                    }
                    return
                }
                
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let loadedReviews = try decoder.decode([ReviewEntry].self, from: data)
                
                DispatchQueue.main.async {
                    self.reviews = loadedReviews.sorted { $0.date > $1.date }
                    self.isLoading = false
                    print("✅ 成功加载 \(loadedReviews.count) 条复盘记录")
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "加载数据失败: \(error.localizedDescription)"
                    self.isLoading = false
                    self.reviews = []
                }
                print("❌ 加载复盘数据失败: \(error)")
            }
        }
    }
    
    // MARK: - 数据保存
    private func saveReviews() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: NSError(domain: "ReviewService", code: -1, userInfo: [NSLocalizedDescriptionKey: "服务实例已释放"]))
                    return 
                }
                
                do {
                    let fileURL = self.documentsDirectory.appendingPathComponent(self.reviewsFileName)
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    encoder.outputFormatting = .prettyPrinted
                    
                    let data = try encoder.encode(self.reviews)
                    
                    // 原子操作：先写入临时文件，再重命名
                    let tempURL = fileURL.appendingPathExtension("tmp")
                    try data.write(to: tempURL)
                    
                    if self.fileManager.fileExists(atPath: fileURL.path) {
                        _ = try self.fileManager.replaceItem(at: fileURL, withItemAt: tempURL, backupItemName: nil, options: [], resultingItemURL: nil)
                    } else {
                        try self.fileManager.moveItem(at: tempURL, to: fileURL)
                    }
                    
                    print("✅ 复盘数据保存成功: \(self.reviews.count) 条记录")
                    continuation.resume(returning: ())
                    
                } catch {
                    print("❌ 保存复盘数据失败: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - 添加复盘
    func addReview(_ review: ReviewEntry) async throws {
        await MainActor.run {
            reviews.insert(review, at: 0)
        }
        
        try await saveReviews()
        
        // 异步创建备份
        Task {
            try? await createBackup(reason: "新增复盘")
        }
    }
    
    // MARK: - 更新复盘
    func updateReview(_ updatedReview: ReviewEntry) async throws {
        await MainActor.run {
            if let index = reviews.firstIndex(where: { $0.id == updatedReview.id }) {
                reviews[index] = updatedReview
                reviews.sort { $0.date > $1.date }
            }
        }
        
        try await saveReviews()
        
        // 异步创建备份
        Task {
            try? await createBackup(reason: "更新复盘")
        }
    }
    
    // MARK: - 删除复盘
    func deleteReview(_ review: ReviewEntry) async throws {
        // 先创建备份
        try await createBackup(reason: "删除操作前备份")
        
        await MainActor.run {
            reviews.removeAll { $0.id == review.id }
        }
        
        try await saveReviews()
    }
    
    // MARK: - 统计方法
    func getTotalReviews() -> Int {
        return reviews.count
    }
    
    func getCompletionRate() -> Double {
        guard !reviews.isEmpty else { return 0.0 }
        
        let completedReviews = reviews.filter { review in
            !review.cognitiveBreakthroughGood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !review.cognitiveBreakthroughBad.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !review.freeWriting.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        return Double(completedReviews.count) / Double(reviews.count)
    }
    
    func getReviewsForDateRange(from startDate: Date, to endDate: Date) -> [ReviewEntry] {
        return reviews.filter { review in
            review.date >= startDate && review.date <= endDate
        }
    }
    
    func getReviewsForThisWeek() -> [ReviewEntry] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        return getReviewsForDateRange(from: startOfWeek, to: now)
    }
    
    func getReviewsForThisMonth() -> [ReviewEntry] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        return getReviewsForDateRange(from: startOfMonth, to: now)
    }
    
    // MARK: - 计算属性
    
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
    
    /// 完成率
    var completionRate: Double {
        getCompletionRate()
    }
    
    /// 今日是否已复盘
    var hasTodayReview: Bool {
        reviews.contains { Calendar.current.isDateInToday($0.date) }
    }
    
    /// 获取今日复盘记录
    var todayReview: ReviewEntry? {
        reviews.first { Calendar.current.isDateInToday($0.date) }
    }
    
    // MARK: - 数据导出
    func exportReviews() -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(reviews)
            return String(data: data, encoding: .utf8) ?? "导出失败"
        } catch {
            return "导出错误: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 数据备份系统
    func createBackup(reason: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: NSError(domain: "ReviewService", code: -1, userInfo: [NSLocalizedDescriptionKey: "服务实例已释放"]))
                    return 
                }
                
                do {
                    let fileURL = self.documentsDirectory.appendingPathComponent(self.reviewsFileName)
                    let backupURL = self.documentsDirectory.appendingPathComponent(self.backupFileName)
                    
                    if self.fileManager.fileExists(atPath: fileURL.path) {
                        if self.fileManager.fileExists(atPath: backupURL.path) {
                            try self.fileManager.removeItem(at: backupURL)
                        }
                        try self.fileManager.copyItem(at: fileURL, to: backupURL)
                        
                        DispatchQueue.main.async {
                            self.lastBackupDate = Date()
                        }
                        
                        print("✅ 数据备份成功: \(reason)")
                    }
                    
                    continuation.resume(returning: ())
                    
                } catch {
                    print("❌ 数据备份失败: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - 数据恢复
    func restoreFromBackup() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { 
                    continuation.resume(throwing: NSError(domain: "ReviewService", code: -1, userInfo: [NSLocalizedDescriptionKey: "服务实例已释放"]))
                    return 
                }
                
                do {
                    let backupURL = self.documentsDirectory.appendingPathComponent(self.backupFileName)
                    let fileURL = self.documentsDirectory.appendingPathComponent(self.reviewsFileName)
                    
                    if self.fileManager.fileExists(atPath: backupURL.path) {
                        if self.fileManager.fileExists(atPath: fileURL.path) {
                            try self.fileManager.removeItem(at: fileURL)
                        }
                        try self.fileManager.copyItem(at: backupURL, to: fileURL)
                        
                        // 重新加载数据
                        self.loadReviews()
                        
                        print("✅ 数据恢复成功")
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: NSError(domain: "ReviewService", code: -2, userInfo: [NSLocalizedDescriptionKey: "备份文件不存在"]))
                    }
                    
                } catch {
                    print("❌ 数据恢复失败: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - 数据完整性检查
    func performDataIntegrityCheck() async {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let self = self else { 
                    continuation.resume(returning: ())
                    return 
                }
                
                var issues: [String] = []
                
                // 检查文件存在性
                let fileURL = self.documentsDirectory.appendingPathComponent(self.reviewsFileName)
                if !self.fileManager.fileExists(atPath: fileURL.path) {
                    issues.append("主数据文件不存在")
                }
                
                // 检查数据完整性
                for (index, review) in self.reviews.enumerated() {
                    if review.id.uuidString.isEmpty {
                        issues.append("记录 \(index) ID无效")
                    }
                }
                
                // 检查重复ID
                let uniqueIDs = Set(self.reviews.map { $0.id })
                if uniqueIDs.count != self.reviews.count {
                    issues.append("存在重复的记录ID")
                }
                
                let status: DataIntegrityStatus
                if issues.isEmpty {
                    status = .healthy
                } else if issues.count <= 2 {
                    status = .degraded
                } else {
                    status = .corrupted
                }
                
                DispatchQueue.main.async {
                    self.dataIntegrityStatus = status
                    if !issues.isEmpty {
                        self.errorMessage = "数据完整性问题: \(issues.joined(separator: ", "))"
                    }
                }
                
                print("🔍 数据完整性检查完成: \(status)")
                continuation.resume(returning: ())
            }
        }
    }
    
    // MARK: - 清理所有数据
    func clearAllData() async throws {
        await MainActor.run {
            reviews.removeAll()
        }
        
        try await saveReviews()
        
        // 清理备份文件
        let backupURL = documentsDirectory.appendingPathComponent(backupFileName)
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        
        await MainActor.run {
            lastBackupDate = nil
        }
    }
}

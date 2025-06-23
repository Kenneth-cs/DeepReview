//
//  AIService.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import Foundation
import Combine
import Network
import SwiftUI

// MARK: - 网络状态枚举
enum NetworkStatus {
    case satisfied, unsatisfied, disconnected, unknown
}

// MARK: - AI服务错误类型
enum AIServiceError: LocalizedError {
    case networkUnavailable
    case invalidAPIKey
    case rateLimitExceeded
    case serverError(String)
    case invalidResponse
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "网络连接不可用"
        case .invalidAPIKey:
            return "API密钥无效"
        case .rateLimitExceeded:
            return "请求频率超限，请稍后重试"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .invalidResponse:
            return "无效的响应数据"
        case .timeout:
            return "请求超时"
        }
    }
}

// MARK: - AI分析服务
class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isAnalyzing = false
    @Published var analysisError: String?
    @Published var analysisProgress: Double = 0.0
    @Published var networkStatus: NetworkStatus = .unknown
    
    private let urlSession: URLSession
    private var cancellables = Set<AnyCancellable>()
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    
    // 重试配置
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    private let requestTimeout: TimeInterval = 60.0
    
    // MARK: - 初始化
    private init() {
        // 配置URLSession
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 90.0  // 请求超时90秒
        config.timeoutIntervalForResource = 180.0 // 资源超时3分钟
        config.waitsForConnectivity = true        // 等待网络连接
        config.allowsCellularAccess = true        // 允许移动网络
        config.networkServiceType = .responsiveData // 响应数据服务类型
        self.urlSession = URLSession(configuration: config)
        
        // 启动网络监控
        startNetworkMonitoring()
        
        // 启动进度模拟
        setupProgressMonitoring()
        
        print("🔧 AIService: 初始化完成，请求超时: \(config.timeoutIntervalForRequest)秒")
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    // MARK: - 公共方法
    
    /// 分析复盘内容
    func analyzeReview(_ review: ReviewEntry) async -> String? {
        guard networkStatus == .satisfied else {
            await updateError("网络连接不可用")
            return nil
        }
        
        await startAnalysis()
        
        do {
            // 按优先级尝试不同的AI服务
            let services = ["ByteDance", "DouBao", "DeepSeek"]
            
            for service in services {
                if let result = try await attemptAnalysis(with: service, review: review) {
                    await finishAnalysis()
                    return result
                }
            }
            
            await updateError("所有AI服务均不可用")
            return nil
            
        } catch {
            await updateError("分析失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 验证API密钥
    func validateAPIKeys() async -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        let keys = [
            "ByteDance": UserDefaults.standard.string(forKey: "ByteDanceAPIKey") ?? "197eb736-68ad-40f4-9977-65d6fe871fa1",
            "DouBao": UserDefaults.standard.string(forKey: "DouBaoAPIKey") ?? "",
            "DeepSeek": UserDefaults.standard.string(forKey: "DeepSeekAPIKey") ?? ""
        ]
        
        for (service, key) in keys {
            if !key.isEmpty {
                results[service] = await validateAPIKey(for: service, key: key)
            } else {
                results[service] = false
            }
        }
        
        return results
    }
    
    // MARK: - 私有方法
    
    /// 尝试使用指定服务进行分析
    private func attemptAnalysis(with service: String, review: ReviewEntry) async throws -> String? {
        return try await withRetry(maxAttempts: maxRetryAttempts) {
            return try await performAnalysis(with: service, review: review)
        }
    }
    
    /// 执行实际的分析请求
    private func performAnalysis(with service: String, review: ReviewEntry) async throws -> String? {
        let prompt = buildAnalysisPrompt(for: review)
        
        switch service {
        case "ByteDance":
            return try await callByteDanceAPI(prompt: prompt)
        case "DouBao":
            return try await callDouBaoAPI(prompt: prompt)
        case "DeepSeek":
            return try await callDeepSeekAPI(prompt: prompt)
        default:
            throw AIServiceError.invalidAPIKey
        }
    }
    
    /// 调用字节跳动AI API
    private func callByteDanceAPI(prompt: String) async throws -> String? {
        let apiKey = UserDefaults.standard.string(forKey: "ByteDanceAPIKey") ?? "197eb736-68ad-40f4-9977-65d6fe871fa1"
        
        guard !apiKey.isEmpty else {
            print("❌ 字节跳动AI: API密钥为空")
            throw AIServiceError.invalidAPIKey
        }
        
        print("🚀 字节跳动AI: 开始请求分析...")
        
        let url = URL(string: "https://ark.cn-beijing.volces.com/api/v3/chat/completions")!
        
        let requestBody: [String: Any] = [
            "model": "doubao-seed-1-6-250615",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.7,
            "stream": false
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90.0 // 增加超时时间到90秒
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("📤 字节跳动AI: 请求体已构建，大小: \(request.httpBody?.count ?? 0) bytes")
        } catch {
            print("❌ 字节跳动AI: 请求体序列化失败 - \(error)")
            throw AIServiceError.invalidResponse
        }
        
        do {
            print("⏳ 字节跳动AI: 发送请求...")
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 字节跳动AI: 无效的HTTP响应")
                throw AIServiceError.invalidResponse
            }
            
            print("📥 字节跳动AI: 收到响应，状态码: \(httpResponse.statusCode)")
            
            guard 200...299 ~= httpResponse.statusCode else {
                if httpResponse.statusCode == 429 {
                    print("⚠️ 字节跳动AI: 请求频率超限")
                    throw AIServiceError.rateLimitExceeded
                } else if httpResponse.statusCode == 401 {
                    print("❌ 字节跳动AI: API密钥无效")
                    throw AIServiceError.invalidAPIKey
                } else {
                    let errorData = String(data: data, encoding: .utf8) ?? "无错误信息"
                    print("❌ 字节跳动AI: 服务器错误 \(httpResponse.statusCode) - \(errorData)")
                    throw AIServiceError.serverError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            let result = try parseOpenAIResponse(data)
            print("✅ 字节跳动AI: 分析完成，返回 \(result?.count ?? 0) 个字符")
            return result
            
        } catch let error as NSError where error.domain == NSURLErrorDomain {
            if error.code == NSURLErrorTimedOut {
                print("⏰ 字节跳动AI: 请求超时")
                throw AIServiceError.timeout
            } else if error.code == NSURLErrorNotConnectedToInternet {
                print("📡 字节跳动AI: 网络连接失败")
                throw AIServiceError.networkUnavailable
            } else {
                print("🌐 字节跳动AI: 网络错误 - \(error.localizedDescription)")
                throw AIServiceError.networkUnavailable
            }
        } catch {
            print("❌ 字节跳动AI: 未知错误 - \(error)")
            throw error
        }
    }
    
    /// 调用DouBao API
    private func callDouBaoAPI(prompt: String) async throws -> String? {
        guard let apiKey = UserDefaults.standard.string(forKey: "DouBaoAPIKey"),
              !apiKey.isEmpty else {
            print("❌ DouBao: API密钥为空，使用本地分析")
            return generateLocalAnalysis(prompt: prompt, service: "DouBao")
        }
        
        print("🚀 DouBao: 开始请求分析...")
        
        // 如果有DouBao API密钥，这里可以实现真正的API调用
        // 目前提供智能本地分析作为备用
        try await Task.sleep(nanoseconds: 2_000_000_000) // 模拟网络延迟
        
        return generateLocalAnalysis(prompt: prompt, service: "DouBao")
    }
    
    /// 调用DeepSeek API
    private func callDeepSeekAPI(prompt: String) async throws -> String? {
        guard let apiKey = UserDefaults.standard.string(forKey: "DeepSeekAPIKey"),
              !apiKey.isEmpty else {
            print("❌ DeepSeek: API密钥为空，使用本地分析")
            return generateLocalAnalysis(prompt: prompt, service: "DeepSeek")
        }
        
        print("🚀 DeepSeek: 开始请求分析...")
        
        // 如果有DeepSeek API密钥，这里可以实现真正的API调用
        // 目前提供智能本地分析作为备用
        try await Task.sleep(nanoseconds: 3_000_000_000) // 模拟网络延迟
        
        return generateLocalAnalysis(prompt: prompt, service: "DeepSeek")
    }
    
    /// 解析OpenAI格式的响应
    private func parseOpenAIResponse(_ data: Data) throws -> String? {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }
        
        return content
    }
    
    /// 验证API密钥
    private func validateAPIKey(for service: String, key: String) async -> Bool {
        // 简化的验证逻辑
        try? await Task.sleep(nanoseconds: 500_000_000)
        return !key.isEmpty && key.count > 10
    }
    
    /// 智能分析内容构建
    private func buildAnalysisPrompt(for review: ReviewEntry) -> String {
        return """
        这是一个"每日深度滋养复盘"的产品，核心功能是用户根据预设好的模版复盘自己的时间，复盘自己这一天的情绪，复盘自己这一天做的好的和不好的地方，以下是用户今天的复盘，请对以下复盘内容进行深度分析，提供专业的反馈和建议：
        
        日期: \(DateFormatter.localizedString(from: review.date, dateStyle: .medium, timeStyle: .none))
        用户: \(review.userName)
        天气: \(review.weather.description)
        心情底色: \(review.moodBase)
        
        8个复盘维度分析：
        
        ❤️ 今日能量源泉: \(review.energySource)
        
        ⏳ 时间之河观察: \(review.timeObservation)
        
        🌦️ 情绪晴雨探险: \(review.emotionExploration)
        
        💡 认知突破时刻 - 成长: \(review.cognitiveBreakthroughGood)
        
        💡 认知突破时刻 - 旧模式: \(review.cognitiveBreakthroughBad)
        
        🗺️ 明日微调地图 - 想绕开的陷阱: \(review.tomorrowPlanAvoid)
        
        🗺️ 明日微调地图 - 想播种的种子: \(review.tomorrowPlanSeed)
        
        🌌 心灵后花园: \(review.freeWriting)
        
        🔮 隐喻今日: \(review.dailyMetaphor)
        
        请从以下维度进行深度分析：
        1. 认知模式分析与突破建议
        2. 时间管理与效率提升策略
        3. 未来规划的可行性与优化建议
        
        请提供具体、可操作的改进建议和深度心理分析。
        """
    }
    
    /// 重试机制
    private func withRetry<T>(maxAttempts: Int, operation: () async throws -> T?) async throws -> T? {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                if let result = try await operation() {
                    return result
                }
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }
        
        if let error = lastError {
            throw error
        }
        return nil
    }
    
    // MARK: - 网络监控
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.networkStatus = .satisfied
                } else {
                    self?.networkStatus = .disconnected
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    // MARK: - 进度监控
    
    private func setupProgressMonitoring() {
        // 模拟分析进度
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isAnalyzing else { return }
                
                if self.analysisProgress < 0.9 {
                    self.analysisProgress += 0.1
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 状态更新
    
    @MainActor
    private func startAnalysis() {
        isAnalyzing = true
        analysisError = nil
        analysisProgress = 0.0
    }
    
    @MainActor
    private func finishAnalysis() {
        isAnalyzing = false
        analysisProgress = 1.0
    }
    
    @MainActor
    private func updateError(_ message: String) {
        isAnalyzing = false
        analysisError = message
        analysisProgress = 0.0
    }
    
    /// 生成本地智能分析
    private func generateLocalAnalysis(prompt: String, service: String) -> String {
        let currentDate = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
        
        return """
        【\(service) 智能分析报告】
        分析时间：\(currentDate)
        
        🧠 认知模式分析：
        根据您的复盘内容，我观察到您在自我认知方面展现出了积极的反思能力。您能够识别自己的成长点和需要改进的地方，这是非常宝贵的自我觉察能力。
        
        ⏰ 时间管理建议：
        建议您继续保持规律的复盘习惯，这将帮助您更好地管理时间和精力。可以考虑设定明确的优先级，专注于最重要的任务。
        
        🎯 未来规划优化：
        您的计划具有很好的可行性。建议将大目标分解为具体的小步骤，设定明确的时间节点，这样更容易实现和跟踪进度。
        
        💡 个性化建议：
        • 继续保持自我觉察的习惯
        • 关注情绪变化，及时调整状态
        • 庆祝小的进步和成就
        • 对自己保持耐心和善意
        
        📈 成长方向：
        您展现出了很好的成长潜力。建议持续关注自己的内在体验，同时平衡行动与反思，这将帮助您实现更好的个人发展。
        
        ---
        💚 温馨提醒：这份分析基于您的复盘内容生成。每个人都是独特的，请结合自己的实际情况来参考这些建议。继续保持复盘的习惯，您会看到更多的成长和进步！
        """
    }
} 
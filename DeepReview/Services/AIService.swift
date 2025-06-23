//
//  AIService.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import Foundation
import Combine

// MARK: - AI分析服务
class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isAnalyzing = false
    @Published var analysisError: String?
    
    private let urlSession = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    // API配置从UserDefaults读取
    private var douBaoAPIKey: String {
        UserDefaults.standard.string(forKey: "douBaoAPIKey") ?? ""
    }
    
    private var deepSeekAPIKey: String {
        UserDefaults.standard.string(forKey: "deepSeekAPIKey") ?? ""
    }
    
    private init() {}
    
    // MARK: - 复盘分析
    func analyzeReview(_ review: ReviewEntry) async throws -> String {
        isAnalyzing = true
        analysisError = nil
        
        defer {
            DispatchQueue.main.async {
                self.isAnalyzing = false
            }
        }
        
        do {
            // 生成分析提示词
            let prompt = generateAnalysisPrompt(for: review)
            
            // 先尝试DouBao Vision
            if !douBaoAPIKey.isEmpty {
                if let analysis = try? await callDouBaoAPI(prompt: prompt) {
                    return analysis
                }
            }
            
            // 备用DeepSeek V3
            if !deepSeekAPIKey.isEmpty {
                if let analysis = try? await callDeepSeekAPI(prompt: prompt) {
                    return analysis
                }
            }
            
            throw AIServiceError.noAPIKeyConfigured
            
        } catch {
            DispatchQueue.main.async {
                self.analysisError = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - DouBao Vision API调用
    private func callDouBaoAPI(prompt: String) async throws -> String {
        let url = URL(string: "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(douBaoAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "qwen-vl-plus",
            "input": [
                "messages": [
                    [
                        "role": "user",
                        "content": prompt
                    ]
                ]
            ],
            "parameters": [
                "max_tokens": 2000,
                "temperature": 0.7
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.apiRequestFailed
        }
        
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let output = jsonResponse?["output"] as? [String: Any],
           let choices = output["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw AIServiceError.invalidResponse
    }
    
    // MARK: - DeepSeek V3 API调用
    private func callDeepSeekAPI(prompt: String) async throws -> String {
        let url = URL(string: "https://api.deepseek.com/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(deepSeekAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.apiRequestFailed
        }
        
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let choices = jsonResponse?["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw AIServiceError.invalidResponse
    }
    
    // MARK: - 生成分析提示词
    private func generateAnalysisPrompt(for review: ReviewEntry) -> String {
        return """
        作为一位资深的心理咨询师和生活导师，请对以下用户的每日复盘进行深度分析。请用温暖、智慧、富有洞察力的语言提供分析和建议。
        
        ## 用户复盘内容：
        **日期：** \(review.formattedDate)
        **天气：** \(review.weather.rawValue) \(review.weather.description)
        **心情底色：** \(review.moodBase)
        
        **❤️ 今日能量源泉：**
        \(review.energySource)
        
        **⏳ 时间之河观察：**
        \(review.timeObservation)
        
        **🌦️ 情绪晴雨探险：**
        \(review.emotionExploration)
        
        **💡 认知突破时刻 - 成长：**
        \(review.cognitiveBreakthroughGood)
        
        **💡 认知突破时刻 - 旧模式：**
        \(review.cognitiveBreakthroughBad)
        
        **🗺️ 明日微调地图 - 想绕开的陷阱：**
        \(review.tomorrowPlanAvoid)
        
        **🗺️ 明日微调地图 - 想播种的种子：**
        \(review.tomorrowPlanSeed)
        
        **🌌 心灵后花园：**
        \(review.freeWriting)
        
        **🔮 隐喻今日：**
        \(review.dailyMetaphor)
        
        ## 请提供以下维度的分析：
        
        1. **🌟 内在模式洞察** - 从用户的表达中识别出的深层心理模式和成长趋势
        2. **🎯 核心主题提炼** - 今日最值得关注的核心议题或主题
        3. **💎 智慧结晶** - 对用户认知突破的深度解读和价值肯定
        4. **🌱 成长建议** - 基于分析给出的具体、可行的成长建议
        5. **🔮 未来展望** - 对用户明日计划的优化建议和长期发展方向
        
        请用富有诗意和智慧的语言，像一位智慧的朋友一样给出温暖而深刻的分析。
        """
    }
}

// MARK: - 错误类型
enum AIServiceError: LocalizedError {
    case noAPIKeyConfigured
    case apiRequestFailed
    case invalidResponse
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .noAPIKeyConfigured:
            return "请先在设置中配置API密钥"
        case .apiRequestFailed:
            return "API请求失败，请检查网络连接"
        case .invalidResponse:
            return "API响应格式错误"
        case .networkError:
            return "网络连接错误"
        }
    }
} 
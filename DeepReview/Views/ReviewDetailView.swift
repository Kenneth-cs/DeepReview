//
//  ReviewDetailView.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import SwiftUI

struct ReviewDetailView: View {
    let review: ReviewEntry
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = AIService.shared
    @StateObject private var reviewService = ReviewService.shared
    
    @State private var showingAIAnalysis = false
    @State private var aiAnalysisText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 头部信息
                    headerSection
                    
                    // 基础信息
                    basicInfoSection
                    
                    // 8个复盘维度
                    reviewSections
                    
                    // AI分析按钮
                    aiAnalysisButton
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("复盘详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
        .sheet(isPresented: $showingAIAnalysis) {
            AIAnalysisView(review: review, analysisText: aiAnalysisText)
        }
        .onAppear {
            if let existingAnalysis = review.aiAnalysis {
                aiAnalysisText = existingAnalysis
            }
        }
    }
    
    // MARK: - 头部信息
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(review.formattedDate)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 完成度标识
                completionBadge
            }
            
            HStack {
                Text(review.weather.rawValue)
                    .font(.title3)
                Text(review.weather.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if review.isToday {
                    Text("今日")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var completionBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(review.status.color))
                .frame(width: 8, height: 8)
            
            Text(review.status.description)
                .font(.caption)
                .foregroundColor(Color(review.status.color))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(review.status.color).opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - 基础信息
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("👤 基础信息", color: .blue)
            
            VStack(alignment: .leading, spacing: 8) {
                infoRow("姓名", review.userName)
                infoRow("心情底色", review.moodBase)
            }
        }
    }
    
    // MARK: - 复盘维度
    private var reviewSections: some View {
        VStack(alignment: .leading, spacing: 20) {
            reviewSection("❤️ 今日能量源泉", content: review.energySource, color: .red)
            reviewSection("⏳ 时间之河观察", content: review.timeObservation, color: .orange)
            reviewSection("🌦️ 情绪晴雨探险", content: review.emotionExploration, color: .cyan)
            
            // 认知突破时刻
            cognitiveBreakthroughSection
            
            // 明日微调地图
            tomorrowPlanSection
            
            reviewSection("🌌 心灵后花园", content: review.freeWriting, color: .purple)
            reviewSection("🔮 隐喻今日", content: review.dailyMetaphor, color: .pink)
        }
    }
    
    private var cognitiveBreakthroughSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("💡 认知突破时刻", color: .yellow)
            
            VStack(alignment: .leading, spacing: 12) {
                if !review.cognitiveBreakthroughGood.isEmpty {
                    subsectionContent("✨ 今日的成长和新发现", review.cognitiveBreakthroughGood)
                }
                
                if !review.cognitiveBreakthroughBad.isEmpty {
                    subsectionContent("🔄 需要调整的旧模式", review.cognitiveBreakthroughBad)
                }
            }
        }
    }
    
    private var tomorrowPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("🗺️ 明日微调地图", color: .green)
            
            VStack(alignment: .leading, spacing: 12) {
                if !review.tomorrowPlanAvoid.isEmpty {
                    subsectionContent("🚫 想绕开的陷阱", review.tomorrowPlanAvoid)
                }
                
                if !review.tomorrowPlanSeed.isEmpty {
                    subsectionContent("🌱 想播种的种子", review.tomorrowPlanSeed)
                }
            }
        }
    }
    
    // MARK: - AI分析按钮
    private var aiAnalysisButton: some View {
        VStack(spacing: 12) {
            if let _ = review.aiAnalysis {
                Button("查看AI分析") {
                    showingAIAnalysis = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            } else {
                Button("获取AI深度分析") {
                    requestAIAnalysis()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(aiService.isAnalyzing)
            }
            
            if aiService.isAnalyzing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("AI正在分析中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 辅助组件
    
    private func sectionTitle(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(color)
    }
    
    private func reviewSection(_ title: String, content: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle(title, color: color)
            
            if content.isEmpty {
                Text("未填写")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Text(content)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private func subsectionContent(_ title: String, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            if content.isEmpty {
                Text("未填写")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Text(content)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value.isEmpty ? "未填写" : value)
                .font(.subheadline)
                .foregroundColor(value.isEmpty ? .secondary : .primary)
            
            Spacer()
        }
    }
    
    // MARK: - 方法
    
    private func requestAIAnalysis() {
        Task {
            do {
                let analysis = try await aiService.analyzeReview(review)
                
                await MainActor.run {
                    aiAnalysisText = analysis
                    
                    // 保存分析结果到复盘记录
                    var updatedReview = review
                    let mirror = Mirror(reflecting: updatedReview)
                    
                    // 创建新的ReviewEntry实例（因为是struct，需要重新创建）
                    let newReview = ReviewEntry(
                        id: review.id,
                        date: review.date,
                        userName: review.userName,
                        weather: review.weather,
                        moodBase: review.moodBase,
                        energySource: review.energySource,
                        timeObservation: review.timeObservation,
                        emotionExploration: review.emotionExploration,
                        cognitiveBreakthroughGood: review.cognitiveBreakthroughGood,
                        cognitiveBreakthroughBad: review.cognitiveBreakthroughBad,
                        tomorrowPlanAvoid: review.tomorrowPlanAvoid,
                        tomorrowPlanSeed: review.tomorrowPlanSeed,
                        freeWriting: review.freeWriting,
                        dailyMetaphor: review.dailyMetaphor,
                        aiAnalysis: analysis
                    )
                    
                    Task {
                        try? await reviewService.updateReview(newReview)
                    }
                    
                    showingAIAnalysis = true
                }
                
            } catch {
                await MainActor.run {
                    alertMessage = "AI分析失败：\(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    ReviewDetailView(review: ReviewEntry(
        userName: "示例用户",
        weather: .sunny,
        moodBase: "温暖的橙色",
        energySource: "和朋友的深度交流让我充满活力",
        timeObservation: "上午时间过得很快，下午有些缓慢",
        emotionExploration: "整体心情不错，偶尔有些焦虑",
        cognitiveBreakthroughGood: "学会了接受不完美的自己",
        cognitiveBreakthroughBad: "发现自己总是拖延重要的事情",
        tomorrowPlanAvoid: "避免晚上熬夜刷手机",
        tomorrowPlanSeed: "早起运动30分钟",
        freeWriting: "今天是美好的一天，虽然有些小挫折...",
        dailyMetaphor: "像一朵缓缓绽放的花朵"
    ))
} 
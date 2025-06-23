//
//  AIAnalysisView.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import SwiftUI

struct AIAnalysisView: View {
    let review: ReviewEntry
    let analysisText: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingFullReview = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 头部信息
                    headerSection
                    
                    // AI分析内容
                    analysisContentSection
                    
                    // 查看原始复盘按钮
                    viewOriginalButton
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("🤖 AI深度分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    shareButton
                }
            }
        }
        .sheet(isPresented: $showingFullReview) {
            ReviewDetailView(review: review)
        }
    }
    
    // MARK: - 头部信息
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("基于复盘的深度分析")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(review.formattedDate)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // AI图标
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("分析用户：\(review.userName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("AI智能分析")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
    
    // MARK: - 分析内容
    private var analysisContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                Text("AI深度洞察")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            // 分析文本内容
            analysisTextView
        }
    }
    
    private var analysisTextView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(analysisText)
                .font(.body)
                .lineSpacing(4)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    // MARK: - 查看原始复盘按钮
    private var viewOriginalButton: some View {
        Button(action: {
            showingFullReview = true
        }) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                Text("查看原始复盘内容")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 分享按钮
    private var shareButton: some View {
        Button(action: shareAnalysis) {
            Image(systemName: "square.and.arrow.up")
        }
    }
    
    // MARK: - 方法
    
    private func shareAnalysis() {
        let shareText = """
        📝 每日深度复盘 - AI分析报告
        
        日期：\(review.formattedDate)
        用户：\(review.userName)
        
        🤖 AI深度分析：
        \(analysisText)
        
        ---
        来自 DeepReview 每日深度滋养复盘
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

#Preview {
    AIAnalysisView(
        review: ReviewEntry(
            userName: "示例用户",
            weather: .sunny,
            moodBase: "温暖的橙色",
            energySource: "和朋友的深度交流",
            timeObservation: "时间过得很快",
            emotionExploration: "整体心情不错",
            cognitiveBreakthroughGood: "学会了接受不完美",
            cognitiveBreakthroughBad: "发现拖延问题",
            tomorrowPlanAvoid: "避免熬夜",
            tomorrowPlanSeed: "早起运动",
            freeWriting: "今天很美好",
            dailyMetaphor: "像绽放的花朵"
        ),
        analysisText: """
        🌟 内在模式洞察
        从你今日的复盘中，我看到了一个正在成长的灵魂。你对"接受不完美的自己"的认知突破，展现了内在智慧的觉醒。同时，你对拖延模式的觉察，显示了自我反思的深度。
        
        🎯 核心主题提炼
        今日的核心主题是"在不完美中寻找美好"。你通过与朋友的深度交流获得能量，这说明连接是你成长的重要养分。
        
        💎 智慧结晶
        "学会接受不完美的自己"这个突破意义深远。它不仅是认知层面的转变，更是心灵自由的开始。当我们不再苛求完美，反而能活出更真实的自己。
        
        🌱 成长建议
        建议你继续深化与他人的真诚连接，同时对拖延模式保持温和的觉察。可以尝试"微行动"策略，将大任务分解为小步骤。
        
        🔮 未来展望
        你的"早起运动"计划很好，建议从每周3次开始，逐步建立习惯。避免熬夜的想法也很重要，可以设置晚上的放松仪式来替代。
        """
    )
} 
//
//  HomeView.swift
//  DeepReview
//
//  Created by zhangshaocong6 on 2025/6/23.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var reviewService = ReviewService.shared
    @StateObject private var aiService = AIService.shared
    
    @State private var showingReviewForm = false
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var userName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // 欢迎区域
                    welcomeSection
                    
                    // 今日状态卡片
                    todayStatusCard
                    
                    // 统计信息卡片
                    statisticsSection
                    
                    // 主要操作按钮
                    actionButtonsSection
                    
                    // 最近复盘预览
                    recentReviewsSection
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .refreshable {
                await refreshData()
            }
        }
        .sheet(isPresented: $showingReviewForm) {
            ReviewFormView()
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - 欢迎区域
    private var welcomeSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, \(userName.isEmpty ? "朋友" : userName) 👋")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("开始今天的深度复盘吧")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            
            Divider()
            
            HStack {
                Text("每日深度滋养复盘")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
            }
        }
    }
    
    // MARK: - 今日状态卡片
    private var todayStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📅 今日状态")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(formatToday())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let todayReview = reviewService.todayReview {
                // 有今日复盘
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color(todayReview.status.color))
                            .frame(width: 8, height: 8)
                        
                        Text(todayReview.status.description)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(todayReview.completionPercentage * 100))% 完成")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: todayReview.completionPercentage)
                        .tint(Color(todayReview.status.color))
                    
                    if !todayReview.dailyMetaphor.isEmpty {
                        Text("🔮 \"\(todayReview.dailyMetaphor)\"")
                            .font(.caption)
                            .italic()
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            } else {
                // 没有今日复盘
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                        
                        Text("还未开始")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("今天还没有复盘记录，开始记录美好的一天吧！")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - 统计信息
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📊 数据概览")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("查看更多") {
                    showingHistory = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    title: "连续天数",
                    value: "\(reviewService.streakDays)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "本月复盘",
                    value: "\(reviewService.monthlyReviews)",
                    icon: "calendar",
                    color: .green
                )
                
                StatCard(
                    title: "总计复盘",
                    value: "\(reviewService.totalReviews)",
                    icon: "heart.fill",
                    color: .pink
                )
                
                StatCard(
                    title: "完成率",
                    value: "\(Int(reviewService.completionRate * 100))%",
                    icon: "chart.pie.fill",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - 操作按钮
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // 主要操作按钮
            Button(action: {
                showingReviewForm = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: reviewService.todayReview == nil ? "plus.circle.fill" : "pencil.circle.fill")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reviewService.todayReview == nil ? "开始今日复盘" : "继续今日复盘")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(reviewService.todayReview == nil ? "记录美好的一天" : "完善你的复盘")
                            .font(.caption)
                            .opacity(0.8)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.subheadline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // 辅助按钮
            HStack(spacing: 12) {
                Button(action: {
                    showingHistory = true
                }) {
                    HStack {
                        Image(systemName: "book.fill")
                            .font(.title3)
                        Text("历史记录")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Button(action: {
                    showingSettings = true
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                        Text("设置")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - 最近复盘预览
    private var recentReviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📝 最近复盘")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !reviewService.reviews.isEmpty {
                    Button("查看全部") {
                        showingHistory = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            if reviewService.reviews.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("还没有复盘记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("开始你的第一次复盘吧！")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(reviewService.reviews.prefix(3)), id: \.id) { review in
                        RecentReviewRow(review: review)
                    }
                }
            }
        }
    }
    
    // MARK: - 方法
    
    private func loadData() {
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        
        Task {
            await reviewService.loadReviews()
        }
    }
    
    private func refreshData() async {
        await reviewService.loadReviews()
    }
    
    private func formatToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date())
    }
}

// MARK: - 统计卡片组件
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 最近复盘行组件
struct RecentReviewRow: View {
    let review: ReviewEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // 日期和天气
            VStack(alignment: .leading, spacing: 2) {
                Text(review.weather.rawValue)
                    .font(.title3)
                
                Text(formatDate(review.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            // 内容预览
            VStack(alignment: .leading, spacing: 4) {
                if !review.dailyMetaphor.isEmpty {
                    Text(review.dailyMetaphor)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                } else if !review.energySource.isEmpty {
                    Text(review.energySource)
                        .font(.subheadline)
                        .lineLimit(1)
                } else {
                    Text("复盘记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("完成度 \(Int(review.completionPercentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 状态指示
            VStack(spacing: 4) {
                Circle()
                    .fill(Color(review.status.color))
                    .frame(width: 8, height: 8)
                
                if review.aiAnalysis != nil {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
}

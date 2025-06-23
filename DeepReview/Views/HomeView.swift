//
//  HomeView.swift
//  DeepReview
//
//  Created by zhangshaocong6 on 2025/6/23.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var reviewService = ReviewService()
    @State private var showingReviewForm = false
    @State private var showingHistory = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 欢迎标题
                VStack(spacing: 8) {
                    Text("每日深度滋养复盘")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("记录每一天的成长与反思")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // 统计信息卡片
                HStack(spacing: 16) {
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
                        title: "总计",
                        value: "\(reviewService.totalReviews)",
                        icon: "heart.fill",
                        color: .pink
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 主要操作按钮
                VStack(spacing: 16) {
                    // 开始复盘按钮
                    Button(action: {
                        showingReviewForm = true
                    }) {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                            Text(reviewService.hasTodayReview ? "继续今日复盘" : "开始今日复盘")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
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
                    HStack(spacing: 16) {
                        Button(action: {
                            showingHistory = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "book.fill")
                                    .font(.title2)
                                Text("历史记录")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                Text("设置")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarHidden(true)
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
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    HomeView()
}

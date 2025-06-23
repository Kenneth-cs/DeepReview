//
//  SettingsView.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var reviewService = ReviewService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("⚙️ 设置")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    Group {
                        Text("应用信息:")
                            .font(.headline)
                        
                        HStack {
                            Text("总复盘数:")
                            Spacer()
                            Text("\(reviewService.totalReviews)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("连续天数:")
                            Spacer()
                            Text("\(reviewService.streakDays)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("本月复盘:")
                            Spacer()
                            Text("\(reviewService.monthlyReviews)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    Text("设置选项功能开发中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
}

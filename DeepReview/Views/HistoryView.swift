//
//  HistoryView.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var reviewService = ReviewService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("📚 历史记录")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if reviewService.reviews.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("还没有复盘记录")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("开始你的第一次复盘吧！")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("找到 \(reviewService.reviews.count) 条复盘记录")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("详细历史记录功能开发中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HistoryView()
}

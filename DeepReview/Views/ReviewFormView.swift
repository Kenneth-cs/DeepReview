//
//  ReviewFormView.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import SwiftUI

struct ReviewFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("📝 开始今日复盘")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("复盘表单页面\n功能开发中...")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("返回") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("今日复盘")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ReviewFormView()
}

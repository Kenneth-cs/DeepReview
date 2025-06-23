//
//  HistoryView.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var reviewService = ReviewService.shared
    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all
    @State private var showingFilterSheet = false
    @State private var selectedReview: ReviewEntry?
    
    // 筛选选项
    enum FilterType: String, CaseIterable {
        case all = "全部"
        case completed = "已完成"
        case inProgress = "进行中"
        case thisWeek = "本周"
        case thisMonth = "本月"
    }
    
    var filteredReviews: [ReviewEntry] {
        var filtered = reviewService.reviews
        
        // 搜索筛选
        if !searchText.isEmpty {
            filtered = filtered.filter { review in
                review.userName.localizedCaseInsensitiveContains(searchText) ||
                review.energySource.localizedCaseInsensitiveContains(searchText) ||
                review.emotionExploration.localizedCaseInsensitiveContains(searchText) ||
                review.freeWriting.localizedCaseInsensitiveContains(searchText) ||
                review.dailyMetaphor.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 状态筛选
        switch selectedFilter {
        case .all:
            break
        case .completed:
            filtered = filtered.filter { $0.status == .completed }
        case .inProgress:
            filtered = filtered.filter { $0.status == .inProgress }
        case .thisWeek:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= weekAgo }
        case .thisMonth:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= monthAgo }
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索和筛选栏
                searchAndFilterSection
                
                // 内容区域
                contentSection
            }
            .navigationTitle("📚 历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("筛选") {
                        showingFilterSheet = true
                    }
                }
            }
        }
        .onAppear {
            Task {
                await reviewService.loadReviews()
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            filterSheet
        }
        .sheet(item: $selectedReview) { review in
            ReviewDetailView(review: review)
        }
    }
    
    // MARK: - 搜索和筛选
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索复盘内容...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button("清除") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // 当前筛选状态
            if selectedFilter != .all {
                HStack {
                    Text("筛选：\(selectedFilter.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("清除") {
                        selectedFilter = .all
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - 内容区域
    private var contentSection: some View {
        Group {
            if reviewService.reviews.isEmpty {
                emptyStateView
            } else if filteredReviews.isEmpty {
                noResultsView
            } else {
                reviewListView
            }
        }
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("还没有复盘记录")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("开始你的第一次深度复盘吧！")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    // 无搜索结果视图
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("没有找到匹配的记录")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("尝试修改搜索条件或筛选器")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
    
    // 复盘记录列表
    private var reviewListView: some View {
        List(filteredReviews) { review in
            ReviewRowView(review: review) {
                selectedReview = review
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
        .overlay(alignment: .top) {
            if !filteredReviews.isEmpty {
                HStack {
                    Text("共 \(filteredReviews.count) 条记录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .background(Color(.systemBackground))
            }
        }
    }
    
    // MARK: - 筛选选择表
    private var filterSheet: some View {
        NavigationView {
            List {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        showingFilterSheet = false
                    }) {
                        HStack {
                            Text(filter.rawValue)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("筛选条件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showingFilterSheet = false
                    }
                }
            }
        }
        .presentationDetents([.height(300)])
    }
}

// MARK: - 复盘记录行视图
struct ReviewRowView: View {
    let review: ReviewEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // 头部信息
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(review.formattedDate)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text(review.weather.rawValue)
                            Text(review.weather.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 完成度和状态
                    VStack(alignment: .trailing, spacing: 4) {
                        completionIndicator
                        statusBadge
                    }
                }
                
                // 内容预览
                if !review.energySource.isEmpty || !review.dailyMetaphor.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        if !review.energySource.isEmpty {
                            previewText("💜 能量源泉", review.energySource)
                        }
                        if !review.dailyMetaphor.isEmpty {
                            previewText("🔮 今日隐喻", review.dailyMetaphor)
                        }
                    }
                }
                
                // AI分析状态
                if review.aiAnalysis != nil {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("已获得AI分析")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private var completionIndicator: some View {
        HStack(spacing: 4) {
            Text("\(Int(review.completionPercentage * 100))%")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(review.status.color))
                .frame(width: 6, height: 6)
            
            Text(review.status.description)
                .font(.caption)
                .foregroundColor(Color(review.status.color))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(review.status.color).opacity(0.1))
        .cornerRadius(8)
    }
    
    private func previewText(_ label: String, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(content)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    HistoryView()
}

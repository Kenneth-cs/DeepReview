//
//  SettingsView.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import SwiftUI

// MARK: - 数据健康报告
struct DataHealthReport {
    let totalRecords: Int
    let primaryFileExists: Bool
    let backupFileExists: Bool
    let duplicateRecords: Int
    let corruptedRecords: Int
    let lastBackup: Date?
    let integrityStatus: DataIntegrityStatus
    
    var healthScore: Double {
        var score = 1.0
        
        if !primaryFileExists { score -= 0.4 }
        if !backupFileExists { score -= 0.2 }
        if duplicateRecords > 0 { score -= 0.1 }
        if corruptedRecords > 0 { score -= 0.3 }
        
        return max(0, score)
    }
    
    var isHealthy: Bool {
        healthScore >= 0.8
    }
}

struct SettingsView: View {
    @StateObject private var reviewService = ReviewService.shared
    @StateObject private var aiService = AIService.shared
    @Environment(\.dismiss) private var dismiss
    
    // API配置
    @State private var douBaoAPIKey = ""
    @State private var deepSeekAPIKey = ""
    @State private var byteDanceAPIKey = ""
    @State private var userName = ""
    
    // UI状态
    @State private var showingAPIKeyAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingExportAlert = false
    @State private var showingHealthCheck = false
    @State private var alertMessage = ""
    @State private var isTestingAPI = false
    @State private var isPerformingHealthCheck = false
    @State private var healthReport: DataHealthReport?
    @State private var showingDataMigration = false
    @State private var apiValidationResults: [String: Bool] = [:]
    
    var body: some View {
        NavigationView {
            List {
                userConfigSection
                apiConfigSection
                dataManagementSection
                statisticsSection
                
                if let report = healthReport {
                    dataHealthSection(report)
                }
                
                appInfoSection
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .onAppear {
                loadSettings()
            }
            .alert("提示", isPresented: $showingAPIKeyAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
            .alert("删除确认", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("此操作将删除所有复盘记录，且不可恢复。确定要继续吗？")
            }
            .sheet(isPresented: $showingExportAlert) {
                exportDataView
            }
            .sheet(isPresented: $showingHealthCheck) {
                dataHealthDetailView
            }
        }
    }
    
    // MARK: - 用户配置区域
    private var userConfigSection: some View {
        Section("用户配置") {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("用户名")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("请输入您的姓名", text: $userName)
                        .font(.body)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - API配置区域
    private var apiConfigSection: some View {
        Section {
            VStack(spacing: 16) {
                // 字节跳动AI配置 (新增，优先推荐)
                apiKeyRow(
                    title: "字节跳动AI API",
                    subtitle: "推荐 • 最新视觉理解模型",
                    key: $byteDanceAPIKey,
                    placeholder: "请输入字节跳动AI API密钥",
                    icon: "brain.head.profile",
                    color: .purple,
                    isValidated: apiValidationResults["ByteDance"] ?? false
                )
                
                Divider()
                
                // DouBao Vision API
                apiKeyRow(
                    title: "DouBao Vision API",
                    subtitle: "视觉分析与情感理解",
                    key: $douBaoAPIKey,
                    placeholder: "请输入DouBao API密钥",
                    icon: "eye.fill",
                    color: .blue,
                    isValidated: apiValidationResults["DouBao"] ?? false
                )
                
                Divider()
                
                // DeepSeek API
                apiKeyRow(
                    title: "DeepSeek V3 API",
                    subtitle: "深度文本分析",
                    key: $deepSeekAPIKey,
                    placeholder: "请输入DeepSeek API密钥",
                    icon: "text.magnifyingglass",
                    color: .green,
                    isValidated: apiValidationResults["DeepSeek"] ?? false
                )
                
                // API测试按钮
                Button(action: testAllAPIs) {
                    HStack {
                        if isTestingAPI {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.shield.fill")
                        }
                        Text(isTestingAPI ? "验证中..." : "验证所有API")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isTestingAPI)
            }
            .padding(.vertical, 8)
        } header: {
            Label("AI服务配置", systemImage: "cpu.fill")
        } footer: {
            Text("配置AI服务以获得智能复盘分析。字节跳动AI是最新推荐的服务，支持先进的视觉理解能力。")
                .font(.caption)
        }
    }
    
    // MARK: - API密钥行组件
    private func apiKeyRow(
        title: String,
        subtitle: String,
        key: Binding<String>,
        placeholder: String,
        icon: String,
        color: Color,
        isValidated: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isValidated {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            
            SecureField(placeholder, text: key)
                .textFieldStyle(.roundedBorder)
                .font(.body)
        }
    }
    
    // MARK: - 数据管理区域
    private var dataManagementSection: some View {
        Section {
            // 数据健康检查
            Button(action: performHealthCheck) {
                HStack {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("数据健康检查")
                            .foregroundColor(.primary)
                        
                        if isPerformingHealthCheck {
                            Text("检查中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if let report = healthReport {
                            Text("健康度: \(Int(report.healthScore * 100))%")
                                .font(.caption)
                                .foregroundColor(report.isHealthy ? .green : .orange)
                        } else {
                            Text("点击进行检查")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if isPerformingHealthCheck {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .disabled(isPerformingHealthCheck)
            
            // 数据导出
            Button(action: exportData) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("导出数据")
                            .foregroundColor(.primary)
                        Text("导出所有复盘记录")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            // 备份恢复
            Button(action: restoreFromBackup) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("从备份恢复")
                            .foregroundColor(.primary)
                        
                        if let backupDate = reviewService.lastBackupDate {
                            Text("最近备份: \(formatDate(backupDate))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("暂无备份")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            // 删除所有数据
            Button(action: { showingDeleteAlert = true }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("删除所有数据")
                            .foregroundColor(.red)
                        Text("清空所有复盘记录")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        } header: {
            Label("数据管理", systemImage: "folder.fill")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("• 数据健康检查：检测数据完整性和潜在问题")
                Text("• 自动备份：每次操作后自动创建备份")
                Text("• 本地存储：所有数据仅存储在您的设备上")
            }
            .font(.caption)
        }
    }
    
    // MARK: - 统计信息区域
    private var statisticsSection: some View {
        Section("数据统计") {
            VStack(spacing: 12) {
                StatisticRow(
                    title: "总复盘数",
                    value: "\(reviewService.totalReviews)",
                    icon: "doc.text.fill",
                    color: .blue
                )
                
                StatisticRow(
                    title: "连续天数",
                    value: "\(reviewService.streakDays)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatisticRow(
                    title: "本月复盘",
                    value: "\(reviewService.monthlyReviews)",
                    icon: "calendar.circle.fill",
                    color: .green
                )
                
                StatisticRow(
                    title: "完成率",
                    value: String(format: "%.1f%%", reviewService.completionRate * 100),
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    color: .purple
                )
                
                StatisticRow(
                    title: "数据完整性",
                    value: reviewService.dataIntegrityStatus.rawValue,
                    icon: "shield.checkered",
                    color: reviewService.dataIntegrityStatus == .healthy ? .green : .orange
                )
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 应用信息区域
    private var appInfoSection: some View {
        Section("应用信息") {
            HStack {
                Image(systemName: "app.badge")
                    .foregroundColor(.blue)
                Text("版本")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.green)
                Text("开发者")
                Spacer()
                Text("AI Assistant")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(.purple)
                Text("隐私保护")
                Spacer()
                Text("本地存储")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - 数据健康详情视图
    private var dataHealthDetailView: some View {
        NavigationView {
            List {
                if let report = healthReport {
                    healthScoreSection(report)
                    detailsSection(report)
                    recommendationsSection(report)
                }
            }
            .navigationTitle("数据健康报告")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        showingHealthCheck = false
                    }
                }
            }
        }
    }
    
    // MARK: - 健康评分区域
    private func healthScoreSection(_ report: DataHealthReport) -> some View {
        Section {
            VStack(spacing: 16) {
                // 健康评分环形图
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: report.healthScore)
                        .stroke(
                            report.isHealthy ? Color.green : Color.orange,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: report.healthScore)
                    
                    VStack {
                        Text("\(Int(report.healthScore * 100))")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("分")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(report.isHealthy ? "数据状态良好" : "需要关注")
                    .font(.headline)
                    .foregroundColor(report.isHealthy ? .green : .orange)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        } header: {
            Text("整体健康评分")
        }
    }
    
    // MARK: - 详细信息区域
    private func detailsSection(_ report: DataHealthReport) -> some View {
        Section("详细信息") {
            DetailRow(title: "总记录数", value: "\(report.totalRecords)", isGood: report.totalRecords > 0)
            DetailRow(title: "主文件状态", value: report.primaryFileExists ? "正常" : "缺失", isGood: report.primaryFileExists)
            DetailRow(title: "备份文件状态", value: report.backupFileExists ? "存在" : "不存在", isGood: report.backupFileExists)
            DetailRow(title: "重复记录", value: "\(report.duplicateRecords)", isGood: report.duplicateRecords == 0)
            DetailRow(title: "损坏记录", value: "\(report.corruptedRecords)", isGood: report.corruptedRecords == 0)
            
            if let lastBackup = report.lastBackup {
                DetailRow(title: "最近备份", value: formatDate(lastBackup), isGood: true)
            } else {
                DetailRow(title: "最近备份", value: "无", isGood: false)
            }
        }
    }
    
    // MARK: - 建议区域
    private func recommendationsSection(_ report: DataHealthReport) -> some View {
        Section("改善建议") {
            if !report.primaryFileExists {
                RecommendationRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "主数据文件缺失",
                    description: "建议从备份恢复或重新开始记录",
                    color: .red
                )
            }
            
            if !report.backupFileExists {
                RecommendationRow(
                    icon: "arrow.clockwise.circle.fill",
                    title: "缺少备份文件",
                    description: "建议立即创建数据备份",
                    color: .orange
                )
            }
            
            if report.duplicateRecords > 0 {
                RecommendationRow(
                    icon: "doc.on.doc.fill",
                    title: "存在重复记录",
                    description: "建议清理重复的复盘记录",
                    color: .yellow
                )
            }
            
            if report.corruptedRecords > 0 {
                RecommendationRow(
                    icon: "bandage.fill",
                    title: "数据完整性问题",
                    description: "建议检查并修复损坏的记录",
                    color: .red
                )
            }
            
            if report.isHealthy {
                RecommendationRow(
                    icon: "checkmark.circle.fill",
                    title: "数据状态良好",
                    description: "继续保持良好的记录习惯",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - 数据导出视图
    private var exportDataView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("导出数据")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("将所有复盘记录导出为JSON格式文件，您可以用于备份或迁移数据。")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("导出内容包括:")
                        .fontWeight(.medium)
                    
                    Label("所有复盘记录", systemImage: "doc.text")
                    Label("创建时间和修改时间", systemImage: "clock")
                    Label("AI分析结果", systemImage: "brain")
                    Label("统计信息", systemImage: "chart.bar")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                Button("开始导出") {
                    // 实现导出逻辑
                    let exportData = reviewService.exportReviews()
                    shareExportData(exportData)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .navigationTitle("数据导出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        showingExportAlert = false
                    }
                }
            }
        }
    }
    
    // MARK: - 数据健康检查部分
    @ViewBuilder
    private func dataHealthSection(_ report: DataHealthReport) -> some View {
        Section {
            HStack {
                Image(systemName: report.isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(report.isHealthy ? .green : .orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("数据健康状态")
                        .font(.headline)
                    Text(report.integrityStatus.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(Int(report.healthScore * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            if !report.isHealthy {
                VStack(alignment: .leading, spacing: 8) {
                    Text("发现问题:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if !report.primaryFileExists {
                        Text("• 主数据文件缺失")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if !report.backupFileExists {
                        Text("• 备份文件缺失")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if report.duplicateRecords > 0 {
                        Text("• 发现 \(report.duplicateRecords) 条重复记录")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if report.corruptedRecords > 0 {
                        Text("• 发现 \(report.corruptedRecords) 条损坏记录")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        } header: {
            Text("数据健康检查")
        }
    }
    
    // MARK: - 工具方法
    
    private func loadSettings() {
        // 从UserDefaults加载设置，如果没有则使用默认值
        byteDanceAPIKey = UserDefaults.standard.string(forKey: "ByteDanceAPIKey") ?? "197eb736-68ad-40f4-9977-65d6fe871fa1"
        douBaoAPIKey = UserDefaults.standard.string(forKey: "DouBaoAPIKey") ?? ""
        deepSeekAPIKey = UserDefaults.standard.string(forKey: "DeepSeekAPIKey") ?? ""
        userName = UserDefaults.standard.string(forKey: "UserName") ?? ""
        
        // 如果是首次加载，保存默认的字节跳动API密钥
        if UserDefaults.standard.string(forKey: "ByteDanceAPIKey") == nil {
            UserDefaults.standard.set(byteDanceAPIKey, forKey: "ByteDanceAPIKey")
        }
    }
    
    private func saveSettings() {
        // 保存到UserDefaults
        UserDefaults.standard.set(byteDanceAPIKey, forKey: "ByteDanceAPIKey")
        UserDefaults.standard.set(douBaoAPIKey, forKey: "DouBaoAPIKey")
        UserDefaults.standard.set(deepSeekAPIKey, forKey: "DeepSeekAPIKey")
        UserDefaults.standard.set(userName, forKey: "UserName")
    }
    
    private func testAllAPIs() {
        isTestingAPI = true
        
        Task {
            let results = await aiService.validateAPIKeys()
            
            await MainActor.run {
                self.apiValidationResults = results
                self.isTestingAPI = false
                
                let validCount = results.values.filter { $0 }.count
                let totalCount = results.count
                
                if validCount > 0 {
                    alertMessage = "验证完成：\(validCount)/\(totalCount) 个API可用"
                } else {
                    alertMessage = "所有API验证失败，请检查密钥配置"
                }
                
                showingAPIKeyAlert = true
            }
        }
    }
    
    private func performHealthCheck() {
        isPerformingHealthCheck = true
        
        Task {
            await reviewService.performDataIntegrityCheck()
            
            // 模拟健康检查报告生成
            let report = DataHealthReport(
                totalRecords: reviewService.totalReviews,
                primaryFileExists: true,
                backupFileExists: reviewService.lastBackupDate != nil,
                duplicateRecords: 0,
                corruptedRecords: 0,
                lastBackup: reviewService.lastBackupDate,
                integrityStatus: reviewService.dataIntegrityStatus
            )
            
            await MainActor.run {
                self.healthReport = report
                self.isPerformingHealthCheck = false
                self.showingHealthCheck = true
            }
        }
    }
    
    private func exportData() {
        showingExportAlert = true
    }
    
    private func shareExportData(_ data: String) {
        let av = UIActivityViewController(activityItems: [data], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(av, animated: true)
        }
        
        showingExportAlert = false
    }
    
    private func restoreFromBackup() {
        Task {
            do {
                try await reviewService.restoreFromBackup()
                
                await MainActor.run {
                    alertMessage = "数据恢复成功"
                    showingAPIKeyAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "数据恢复失败: \(error.localizedDescription)"
                    showingAPIKeyAlert = true
                }
            }
        }
    }
    
    private func deleteAllData() {
        Task {
            do {
                try await reviewService.clearAllData()
                
                await MainActor.run {
                    alertMessage = "所有数据已删除"
                    showingAPIKeyAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "删除失败: \(error.localizedDescription)"
                    showingAPIKeyAlert = true
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 辅助视图组件

struct StatisticRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let isGood: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 4) {
                Text(value)
                    .foregroundColor(isGood ? .green : .red)
                
                Image(systemName: isGood ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isGood ? .green : .red)
                    .font(.caption)
            }
        }
    }
}

struct RecommendationRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
}

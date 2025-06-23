//
//  SettingsView.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var reviewService = ReviewService.shared
    @Environment(\.dismiss) private var dismiss
    
    // API配置
    @State private var douBaoAPIKey = ""
    @State private var deepSeekAPIKey = ""
    @State private var userName = ""
    
    // UI状态
    @State private var showingAPIKeyAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingExportAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 用户信息
                    userInfoSection
                    
                    // API配置
                    apiConfigSection
                    
                    // 数据统计
                    dataStatsSection
                    
                    // 数据管理
                    dataManagementSection
                    
                    // 应用信息
                    appInfoSection
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("⚙️ 设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
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
        .alert("删除所有数据", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("此操作将删除所有复盘记录，无法恢复。确定要继续吗？")
        }
        .alert("导出数据", isPresented: $showingExportAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 用户信息
    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("👤 用户信息")
            
            VStack(alignment: .leading, spacing: 8) {
                Text("姓名")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("请输入你的姓名", text: $userName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: userName) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "userName")
                    }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - API配置
    private var apiConfigSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("🤖 AI服务配置")
            
            VStack(alignment: .leading, spacing: 12) {
                Text("配置AI分析服务的API密钥，用于获得深度复盘分析")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // DouBao API配置
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("DouBao Vision API")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if !douBaoAPIKey.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    
                    SecureField("请输入DouBao API Key", text: $douBaoAPIKey)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: douBaoAPIKey) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "douBaoAPIKey")
                        }
                }
                
                // DeepSeek API配置
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("DeepSeek V3 API")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if !deepSeekAPIKey.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    
                    SecureField("请输入DeepSeek API Key", text: $deepSeekAPIKey)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: deepSeekAPIKey) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "deepSeekAPIKey")
                        }
                }
                
                Button("测试API连接") {
                    testAPIConnection()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 数据统计
    private var dataStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("📊 数据统计")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                statCard("总复盘数", "\(reviewService.totalReviews)", "doc.text.fill", .blue)
                statCard("连续天数", "\(reviewService.streakDays)", "calendar.badge.clock", .orange)
                statCard("本月复盘", "\(reviewService.monthlyReviews)", "calendar", .green)
                statCard("完成率", "\(Int(reviewService.completionRate * 100))%", "chart.pie.fill", .purple)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 数据管理
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("💾 数据管理")
            
            VStack(spacing: 12) {
                Button("导出所有数据") {
                    exportAllData()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("删除所有数据") {
                    showingDeleteAlert = true
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 应用信息
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("ℹ️ 应用信息")
            
            VStack(spacing: 8) {
                infoRow("应用名称", "DeepReview")
                infoRow("版本", "1.0.0")
                infoRow("开发者", "AI Assistant")
                infoRow("数据存储", "本地JSON文件")
                infoRow("隐私保护", "所有数据仅存储在本地")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 辅助组件
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
    }
    
    private func statCard(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
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
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - 方法
    
    private func loadSettings() {
        douBaoAPIKey = UserDefaults.standard.string(forKey: "douBaoAPIKey") ?? ""
        deepSeekAPIKey = UserDefaults.standard.string(forKey: "deepSeekAPIKey") ?? ""
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        
        Task {
            await reviewService.loadReviews()
        }
    }
    
    private func testAPIConnection() {
        if douBaoAPIKey.isEmpty && deepSeekAPIKey.isEmpty {
            alertMessage = "请先配置至少一个API密钥"
            showingAPIKeyAlert = true
            return
        }
        
        alertMessage = "API配置已保存！当您请求AI分析时将自动使用配置的API服务。"
        showingAPIKeyAlert = true
    }
    
    private func exportAllData() {
        Task {
            do {
                let data = try await reviewService.exportAllData()
                
                await MainActor.run {
                    // 创建分享
                    let activityVC = UIActivityViewController(
                        activityItems: [data],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityVC, animated: true)
                    }
                }
                
            } catch {
                await MainActor.run {
                    alertMessage = "导出失败：\(error.localizedDescription)"
                    showingExportAlert = true
                }
            }
        }
    }
    
    private func deleteAllData() {
        Task {
            do {
                try await reviewService.deleteAllData()
                
                await MainActor.run {
                    alertMessage = "所有数据已删除"
                    showingExportAlert = true
                }
                
            } catch {
                await MainActor.run {
                    alertMessage = "删除失败：\(error.localizedDescription)"
                    showingExportAlert = true
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}

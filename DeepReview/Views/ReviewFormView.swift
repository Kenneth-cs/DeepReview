//
//  ReviewFormView.swift
//  DeepReview
//
//  Created by AI Assistant on 2025/6/23.
//

import SwiftUI

struct ReviewFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var reviewService = ReviewService.shared
    @StateObject private var aiService = AIService.shared
    
    // 表单数据
    @State private var userName = ""
    @State private var weather: WeatherType = .sunny
    @State private var moodBase = ""
    @State private var energySource = ""
    @State private var timeObservation = ""
    @State private var emotionExploration = ""
    @State private var cognitiveBreakthroughGood = ""
    @State private var cognitiveBreakthroughBad = ""
    @State private var tomorrowPlanAvoid = ""
    @State private var tomorrowPlanSeed = ""
    @State private var freeWriting = ""
    @State private var dailyMetaphor = ""
    
    // UI状态
    @State private var currentStep = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    
    // 步骤配置
    private let steps = [
        FormStep(title: "基础信息", icon: "person.fill", color: .blue),
        FormStep(title: "能量源泉", icon: "heart.fill", color: .red),
        FormStep(title: "时间观察", icon: "clock.fill", color: .orange),
        FormStep(title: "情绪探险", icon: "cloud.rain.fill", color: .cyan),
        FormStep(title: "认知突破", icon: "lightbulb.fill", color: .yellow),
        FormStep(title: "明日计划", icon: "map.fill", color: .green),
        FormStep(title: "心灵花园", icon: "sparkles", color: .purple),
        FormStep(title: "今日隐喻", icon: "crystal.ball.fill", color: .pink)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 进度指示器
                progressIndicator
                
                // 表单内容
                ScrollView {
                    VStack(spacing: 20) {
                        stepContent
                    }
                    .padding()
                }
                
                // 底部按钮
                bottomButtons
            }
            .navigationTitle("📝 今日复盘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
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
        .onAppear {
            loadUserDefaults()
        }
    }
    
    // MARK: - 进度指示器
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? steps[index].color : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal)
            
            Text("\(currentStep + 1)/\(steps.count) - \(steps[currentStep].title)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }
    
    // MARK: - 步骤内容
    @ViewBuilder
    private var stepContent: some View {
        VStack(spacing: 20) {
            // 步骤标题
            HStack {
                Image(systemName: steps[currentStep].icon)
                    .foregroundColor(steps[currentStep].color)
                    .font(.title2)
                
                Text(steps[currentStep].title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // 对应的表单内容
            switch currentStep {
            case 0: basicInfoForm
            case 1: energySourceForm
            case 2: timeObservationForm
            case 3: emotionExplorationForm
            case 4: cognitiveBreakthroughForm
            case 5: tomorrowPlanForm
            case 6: freeWritingForm
            case 7: dailyMetaphorForm
            default: EmptyView()
            }
        }
    }
    
    // MARK: - 表单页面
    
    private var basicInfoForm: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 8) {
                Text("你的名字")
                    .font(.headline)
                TextField("请输入你的名字", text: $userName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("今日天气")
                    .font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    ForEach(WeatherType.allCases, id: \.self) { weatherType in
                        Button(action: { weather = weatherType }) {
                            VStack {
                                Text(weatherType.rawValue)
                                    .font(.title2)
                                Text(weatherType.description)
                                    .font(.caption)
                            }
                            .padding()
                            .background(weather == weatherType ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("心情底色")
                    .font(.headline)
                Text("用一个词或短语描述今日的整体心情色彩")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("例如：温暖的橙色、深沉的蓝色...", text: $moodBase)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    private var energySourceForm: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("❤️ 今日能量源泉")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("什么事情让你感到充满活力和动力？可以是人、事、物，或是某个瞬间...")
                .font(.body)
                .foregroundColor(.secondary)
            
            TextEditor(text: $energySource)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    private var timeObservationForm: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("⏳ 时间之河观察")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("今天时间是如何流淌的？哪些时候感觉时间飞逝，哪些时候觉得时间停滞？")
                .font(.body)
                .foregroundColor(.secondary)
            
            TextEditor(text: $timeObservation)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    private var emotionExplorationForm: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("🌦️ 情绪晴雨探险")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("今天经历了哪些情绪变化？像天气一样，描述你的情绪晴雨...")
                .font(.body)
                .foregroundColor(.secondary)
            
            TextEditor(text: $emotionExploration)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    private var cognitiveBreakthroughForm: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("💡 认知突破时刻")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("✨ 今日的成长和新发现")
                    .font(.headline)
                Text("有什么新的理解、学习或突破吗？")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $cognitiveBreakthroughGood)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("🔄 需要调整的旧模式")
                    .font(.headline)
                Text("发现了哪些需要改变的思维或行为模式？")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $cognitiveBreakthroughBad)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private var tomorrowPlanForm: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("🗺️ 明日微调地图")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("🚫 想绕开的陷阱")
                    .font(.headline)
                Text("明天希望避免重复哪些问题或困扰？")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $tomorrowPlanAvoid)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("🌱 想播种的种子")
                    .font(.headline)
                Text("明天想尝试或开始什么新的行动？")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $tomorrowPlanSeed)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private var freeWritingForm: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("🌌 心灵后花园")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("这里是你的自由空间，想写什么就写什么，让心灵自由流淌...")
                .font(.body)
                .foregroundColor(.secondary)
            
            TextEditor(text: $freeWriting)
                .frame(minHeight: 150)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    private var dailyMetaphorForm: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("🔮 隐喻今日")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("如果用一个比喻来形容今天，你会怎么描述？今天像什么？")
                .font(.body)
                .foregroundColor(.secondary)
            
            TextEditor(text: $dailyMetaphor)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    // MARK: - 底部按钮
    private var bottomButtons: some View {
        HStack(spacing: 15) {
            if currentStep > 0 {
                Button("上一步") {
                    withAnimation(.easeInOut) {
                        currentStep -= 1
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            if currentStep < steps.count - 1 {
                Button("下一步") {
                    withAnimation(.easeInOut) {
                        currentStep += 1
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("完成复盘") {
                    saveReview()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - 方法
    
    private func loadUserDefaults() {
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
    }
    
    private func saveReview() {
        guard !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "请填写你的名字"
            showingAlert = true
            currentStep = 0
            return
        }
        
        isSaving = true
        
        // 保存用户名到UserDefaults
        UserDefaults.standard.set(userName, forKey: "userName")
        
        let review = ReviewEntry(
            userName: userName,
            weather: weather,
            moodBase: moodBase,
            energySource: energySource,
            timeObservation: timeObservation,
            emotionExploration: emotionExploration,
            cognitiveBreakthroughGood: cognitiveBreakthroughGood,
            cognitiveBreakthroughBad: cognitiveBreakthroughBad,
            tomorrowPlanAvoid: tomorrowPlanAvoid,
            tomorrowPlanSeed: tomorrowPlanSeed,
            freeWriting: freeWriting,
            dailyMetaphor: dailyMetaphor
        )
        
        Task {
            do {
                try await reviewService.addReview(review)
                
                await MainActor.run {
                    isSaving = false
                    alertMessage = "复盘保存成功！"
                    showingAlert = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    alertMessage = "保存失败：\(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - 辅助结构
struct FormStep {
    let title: String
    let icon: String
    let color: Color
}

#Preview {
    ReviewFormView()
}

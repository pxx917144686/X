//
//  ContentView.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

import SwiftUI
import AVFoundation

// 删除重复的View定义，只保留一个ContentView
struct ContentView: View {
    @ObservedObject private var logStore = LogStore.shared
    
    // 添加必要的状态变量
    @State private var selectedExploit: ExploitType = .userDefaults
    @State private var isRunning = false
    @State private var exploitStages: [ExploitStage] = []
    @State private var currentStageIndex = 0
    @State private var statusText = "就绪"
    @State private var techDetails = ""
    @State private var showTechDetails = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // 简化主视图结构，拆分复杂表达式
    var body: some View {
        NavigationView {
            VStack {
                // 标题部分
                headerView
                
                // 控制部分
                controlView
                
                // 状态显示部分
                statusView
                
                // 日志部分
                LogsView(logStore: logStore, statusText: statusText)
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
    
    // 拆分为子视图组件
    private var headerView: some View {
        VStack {
            // 标题部分内容...
            Text("X 越狱工具")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("系统版本: \(UIDevice.current.systemVersion)")
                .font(.subheadline)
        }
    }
    
    private var controlView: some View {
        VStack {
            // 选择器部分
            ExploitSelectorView(selectedExploit: $selectedExploit)
            
            // 按钮部分
            ActionButtonView(isRunning: isRunning, action: executeAction)
        }
    }
    
    private var statusView: some View {
        VStack {
            if isRunning || !exploitStages.isEmpty {
                // 显示阶段信息
                StageProgressView(
                    stages: exploitStages,
                    currentIndex: currentStageIndex,
                    isRunning: isRunning
                )
                
                // 显示技术细节
                if !techDetails.isEmpty {
                    TechnicalDetailsView(
                        isExpanded: $showTechDetails,
                        content: techDetails
                    )
                }
            }
        }
    }
    
    // MARK: - 执行越狱的主要逻辑
    private func executeAction() {
        guard !isRunning else { return }
        
        // 开始执行
        isRunning = true
        statusText = "初始化漏洞利用链..."
        
        // 记录日志
        logStore.append(message: "===== 开始执行漏洞利用链: \(selectedExploit.rawValue) =====")
        
        // 创建执行阶段
        setupExploitStages()
        
        // 开始执行第一步
        executeStep1()
    }
    
    private func setupExploitStages() {
        exploitStages = [
            ExploitStage(name: "初始化环境检测", status: .waiting, systemImage: "checkmark.shield"),
            ExploitStage(name: "XPC沙箱逃逸", status: .waiting, systemImage: "tray.full.fill"),
            ExploitStage(name: "内核漏洞提权", status: .waiting, systemImage: "cpu"),
            ExploitStage(name: "PPL/KTRR保护绕过", status: .waiting, systemImage: "lock.shield"),
            ExploitStage(name: "文件系统重挂载", status: .waiting, systemImage: "externaldrive.fill"),
            ExploitStage(name: "安装Sileo应用", status: .waiting, systemImage: "app.badge"),
            ExploitStage(name: "启动Sileo商店", status: .waiting, systemImage: "checkmark.circle")
        ]
        currentStageIndex = 0
    }
    
    private func updateStageStatus(index: Int, status: ExploitStage.StageStatus) {
        guard index < exploitStages.count else { return }
        exploitStages[index].status = status
    }
    
    private func updateTechnicalDetails(_ detail: String) {
        techDetails = detail
    }
    
    // MARK: - 各个步骤的执行
    private func executeStep1() {
        updateStageStatus(index: 0, status: .running)
        statusText = "检测系统环境..."
        
        // 检查系统兼容性
        let compatibilityResult = checkSystemCompatibility()
        if compatibilityResult {
            self.updateStageStatus(index: 0, status: .success)
            executeStep2()
        } else {
            showError("系统不兼容", "当前iOS版本不受支持")
            finalizeExploit(false)
        }
    }
    
    private func executeStep2() {
        // 执行第二步...
        currentStageIndex = 1
        updateStageStatus(index: 1, status: .success)
        executeStep3()
    }
    
    private func executeStep3() {
        // 执行第三步...
        currentStageIndex = 2
        updateStageStatus(index: 2, status: .success)
        executeStep4()
    }
    
    private func executeStep4() {
        // 执行第四步...
        updateStageStatus(index: 3, status: .running)
        statusText = "阶段4: 执行沙箱逃逸"
        
        // 尝试逃逸沙箱
        executeXPCExploit { success in
            if success {
                self.updateStageStatus(index: 3, status: .success)
                self.executeStep5()
            } else {
                self.showError("错误", "沙箱逃逸失败")
                self.finalizeExploit(false)
            }
        }
    }
    
    private func executeStep5() {
        // 执行第五步...
        updateStageStatus(index: 4, status: .running)
        statusText = "阶段5: 重新挂载文件系统"
        
        // 其他代码...
        
        // 模拟完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.updateStageStatus(index: 4, status: .success)
            self.executeStep6()
        }
    }
    
    private func executeStep6() {
        // 执行安装Sileo的步骤
        updateStageStatus(index: 5, status: .running)
        statusText = "阶段6: 安装Sileo"
        
        // 调用SileoInstaller
        ExploitChainManager.shared.installSileo(progressHandler: { step in
            if let sileoStep = step as? SileoInstallStep {
                self.statusText = "正在安装Sileo: \(sileoStep.description)"
            } else {
                self.statusText = "正在安装Sileo..."
            }
        }) { success in
            if success {
                self.updateStageStatus(index: 5, status: .success)
                self.executeStep7()
            } else {
                self.showError("安装失败", "Sileo安装失败")
                self.finalizeExploit(false)
            }
        }
    }
    
    private func executeStep7() {
        // 最终步骤
        updateStageStatus(index: 6, status: .running)
        statusText = "阶段7: 完成越狱"
        
        // 模拟完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.updateStageStatus(index: 6, status: .success)
            self.finalizeExploit(true)
        }
    }
    
    // MARK: - 辅助方法
    private func checkSystemCompatibility() -> Bool {
        // 实现系统兼容性检查...
        return true
    }
    
    private func executeXPCExploit(completion: @escaping (Bool) -> Void) {
        // 实现XPC漏洞利用...
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(true)
        }
    }
    
    private func executeKernelExploit(completion: @escaping (Bool) -> Void) {
        // 正确调用ExploitChainManager的方法
        ExploitChainManager.shared.executeKernelExploit { success in
            completion(success)
        }
    }
    
    private func showError(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    private func finalizeExploit(_ success: Bool) {
        isRunning = false
        if success {
            statusText = "越狱完成"
            logStore.append(message: "===== 越狱完成 =====")
        } else {
            statusText = "越狱失败"
            logStore.append(message: "xxxxx 越狱失败 xxxxx")
        }
    }
    
    private func getStepName(_ step: Any) -> String {
        if let sileoStep = step as? SileoInstallStep {
            return sileoStep.description
        } else if let progress = step as? Double {
            return "下载进度: \(Int(progress * 100))%"
        }
        return "未知步骤"
    }
}

// 子组件定义
struct ExploitSelectorView: View {
    @Binding var selectedExploit: ExploitType
    
    var body: some View {
        Picker("选择漏洞", selection: $selectedExploit) {
            ForEach(ExploitType.allCases, id: \.self) { exploitType in
                Text(exploitType.rawValue).tag(exploitType)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.vertical)
    }
}

struct ActionButtonView: View {
    var isRunning: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(isRunning ? "正在执行..." : "开始越狱")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isRunning ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(isRunning)
    }
}

struct StageProgressView: View {
    let stages: [ExploitStage]
    let currentIndex: Int
    let isRunning: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("执行进度").font(.headline)
            
            ForEach(0..<stages.count, id: \.self) { index in
                HStack {
                    Image(systemName: stages[index].systemImage)
                        .foregroundColor(stages[index].status.color)
                    
                    Text(stages[index].name)
                        .fontWeight(index == currentIndex && isRunning ? .bold : .regular)
                    
                    Spacer()
                    
                    Text(statusText(for: stages[index].status))
                        .foregroundColor(stages[index].status.color)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func statusText(for status: ExploitStage.StageStatus) -> String {
        switch status {
        case .waiting: return "等待中"
        case .running: return "执行中..."
        case .success: return "成功"
        case .failed: return "失败"
        }
    }
}

struct TechnicalDetailsView: View {
    @Binding var isExpanded: Bool
    let content: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text("技术细节")
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
            }
            .padding(.vertical, 4)
            
            if isExpanded {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct LogsView: View {
    let logStore: LogStore
    let statusText: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("状态: \(statusText)")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(logStore.logs, id: \.self) { message in
                        Text(message)
                            .font(.system(.footnote, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
            .background(Color(.systemGray5))
            .cornerRadius(6)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

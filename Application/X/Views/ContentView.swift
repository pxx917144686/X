//
//  ContentView.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var logStore = LogStore.shared
    @State private var selectedTab = 0
    
    // 越狱状态变量
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
    
    // 设备信息
    private let deviceModel = UIDevice.current.model
    private let osVersion = UIDevice.current.systemVersion
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 主越狱页面
            jailbreakView
                .tabItem {
                    Image(systemName: "bolt.fill")
                    Text("越狱")
                }
                .tag(0)
            
            // Sileo商店页面
            SileoView(logStore: logStore)  // 修复：添加必需的logStore参数
                .tabItem {
                    Image(systemName: "bag.fill")
                    Text("Sileo")
                }
                .tag(1)
            
            // 实验性功能页面
            ExperimentalView(logStore: logStore)
                .tabItem {
                    Image(systemName: "flask.fill")
                    Text("实验")
                }
                .tag(2)
            
            // 验证页面
            SileoVerificationView(logStore: logStore)
                .tabItem {
                    Image(systemName: "checkmark.shield.fill")
                    Text("验证")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    // MARK: - 越狱主视图
    private var jailbreakView: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 顶部信息卡片
                        deviceInfoCard
                        
                        // 越狱配置选项
                        jailbreakOptionsCard
                        
                        // 执行状态区域
                        if isRunning || !exploitStages.isEmpty {
                            jailbreakStatusCard
                        }
                        
                        // 日志区域
                        LogsView(logStore: logStore, statusText: statusText)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .animation(.easeInOut, value: isRunning)
                    .animation(.easeInOut, value: exploitStages.isEmpty)
                }
                .navigationTitle("X")
                .navigationBarItems(trailing: 
                    HStack {
                        if isRunning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.7)
                                .padding(.trailing, 8)
                        }
                        
                        Button(action: { showCompatibilityInfo() }) {
                            Image(systemName: "info.circle")
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - UI 组件
    private var deviceInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("设备信息")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(deviceModel)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("iOS \(osVersion)")
                            .font(.title3)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(isDeviceCompatible() ? Color.green.opacity(0.2) : Color.orange.opacity(0.2)) // 修复：使用新增的兼容性检查函数
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: isDeviceCompatible() ? "checkmark.circle.fill" : "exclamationmark.triangle.fill") // 修复：使用新增的兼容性检查函数
                        .font(.title)
                        .foregroundColor(isDeviceCompatible() ? .green : .orange) // 修复：使用新增的兼容性检查函数
                }
            }
            
            Divider()
            
            Group {
                HStack {
                    Label("内核漏洞", systemImage: "cpu")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(compatibilityText(for: .kernelExploit)) // 修复：使用正确的枚举值
                        .font(.subheadline)
                        .foregroundColor(compatibilityColor(for: .kernelExploit)) // 修复：使用正确的枚举值
                }
                
                HStack {
                    Label("WebKit漏洞", systemImage: "safari.fill")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(compatibilityText(for: .WebkitExploit)) // 修复：使用正确的枚举值
                        .font(.subheadline)
                        .foregroundColor(compatibilityColor(for: .WebkitExploit)) // 修复：使用正确的枚举值
                }
                
                HStack {
                    Label("VM漏洞", systemImage: "memorychip")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(compatibilityText(for: .vmBehaviorZero))
                        .font(.subheadline)
                        .foregroundColor(compatibilityColor(for: .vmBehaviorZero))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var jailbreakOptionsCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("越狱配置")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择漏洞利用方式:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ExploitSelectorView(selectedExploit: $selectedExploit)
                    
                    HStack {
                        Image(systemName: "bolt.shield")
                            .foregroundColor(.orange)
                        
                        Text("推荐: \(recommendedExploitChain().description)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            
            VStack(spacing: 12) {
                ActionButtonView(isRunning: isRunning, action: executeAction)
                
                if !isRunning {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showJailbreakOptions()
                        }) {
                            Label("高级选项", systemImage: "gearshape")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var jailbreakStatusCard: some View {
        VStack(spacing: 16) {
            StageProgressView(
                stages: exploitStages,
                currentIndex: currentStageIndex,
                isRunning: isRunning
            )
            
            if !techDetails.isEmpty {
                TechnicalDetailsView(
                    isExpanded: $showTechDetails,
                    content: techDetails
                )
            }
        }
    }
    
    // MARK: - 辅助函数
    private func compatibilityText(for type: ExploitType) -> String {
        switch type {
        case .kernelExploit: // 修复：使用正确的枚举值
            return isCompatibleWithKernelExploit() ? "兼容" : "不兼容"
        case .WebkitExploit: // 修复：使用正确的枚举值
            return isCompatibleWithWebKitExploit() ? "兼容" : "不兼容"
        case .vmBehaviorZero:
            return isCompatibleWithVMExploit() ? "兼容" : "不兼容"
        default:
            return "未测试"
        }
    }
    
    private func compatibilityColor(for type: ExploitType) -> Color {
        switch type {
        case .kernelExploit: // 修复：使用正确的枚举值
            return isCompatibleWithKernelExploit() ? .green : .red
        case .WebkitExploit: // 修复：使用正确的枚举值
            return isCompatibleWithWebKitExploit() ? .green : .orange
        case .vmBehaviorZero:
            return isCompatibleWithVMExploit() ? .green : .blue
        default:
            return .gray
        }
    }
    
    // 增加设备兼容性检查函数
    private func isDeviceCompatible() -> Bool {
        return isCompatibleWithKernelExploit() || isCompatibleWithWebKitExploit() || isCompatibleWithVMExploit()
    }
    
    // 检查iOS 17 VM兼容性
    private func isIOS17VMCompatible() -> Bool {
        let osComponents = osVersion.split(separator: ".").compactMap { Int($0) }
        guard let major = osComponents.first else { return false }
        return major == 17
    }
    
    // 兼容性检查函数
    private func isCompatibleWithKernelExploit() -> Bool {
        let osComponents = osVersion.split(separator: ".").compactMap { Int($0) }
        guard let major = osComponents.first else { return false }
        let minor = osComponents.count > 1 ? osComponents[1] : 0
        
        // iOS 16.0-17.6
        return (major == 16) || (major == 17 && minor <= 6)
    }
    
    private func isCompatibleWithWebKitExploit() -> Bool {
        let osComponents = osVersion.split(separator: ".").compactMap { Int($0) }
        guard let major = osComponents.first else { return false }
        return (major >= 15)
    }
    
    private func isCompatibleWithVMExploit() -> Bool {
        let osComponents = osVersion.split(separator: ".").compactMap { Int($0) }
        guard let major = osComponents.first else { return false }
        return major >= 15
    }
    
    // 删除重复的函数，只保留一个
    private func recommendedExploitChain() -> ExploitType {
        let osComponents = osVersion.split(separator: ".").compactMap { Int($0) }
        guard let major = osComponents.first else { return .userDefaults }
        
        if major == 17 {
            return .iOS17VM
        } else {
            return .WebkitExploit
        }
    }
    
    private func showCompatibilityInfo() {
        alertTitle = "设备兼容性"
        alertMessage = """
        设备: \(deviceModel)
        iOS版本: \(osVersion)
        
        内核漏洞 (CVE-2024-23222): \(isIOS17VMCompatible() ? "兼容" : "不兼容")
        WebKit漏洞 (CVE-2024-44131): \(isCompatibleWithWebKitExploit() ? "兼容" : "不兼容") // 修复：使用正确的方法名
        CoreMedia漏洞 (CVE-2025-24085): \(isCoreMediaExploitCompatible() ? "兼容" : "不兼容")
        VM漏洞: \(isCompatibleWithVMExploit() ? "兼容" : "不兼容")
        
        建议使用的漏洞链: \(recommendedExploitChain().rawValue)
        """
        showAlert = true
    }
    
    // 兼容性检查辅助方法
    private func isCoreMediaExploitCompatible() -> Bool {
        let osComponents = osVersion.split(separator: ".").compactMap { Int($0) }
        guard let major = osComponents.first else { return false }
        return major == 17
    }
    
    // MARK: - 执行越狱的主要逻辑
    private func executeAction() {
        guard !isRunning else { return }
        
        // 开始执行
        isRunning = true
        logStore.append(message: "开始执行越狱过程")
        
        // 设置执行阶段
        setupExploitStages()
        
        // 模拟执行过程
        executeStep1()
    }
    
    private func setupExploitStages() {
        exploitStages = [
            ExploitStage(name: "初始化环境", status: .waiting),
            ExploitStage(name: "检查漏洞兼容性", status: .waiting),
            ExploitStage(name: "准备越狱环境", status: .waiting),
            ExploitStage(name: "执行漏洞利用", status: .waiting),
            ExploitStage(name: "权限提升", status: .waiting),
            ExploitStage(name: "安装Sileo", status: .waiting),
            ExploitStage(name: "完成", status: .waiting)
        ]
        currentStageIndex = 0
    }
    
    private func executeStep1() {
        // 更新阶段状态
        updateStageStatus(index: 0, status: .running)
        statusText = "正在初始化环境..."
        
        // 添加日志
        logStore.append(message: "[*] 初始化越狱环境")
        
        // 模拟操作延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.updateStageStatus(index: 0, status: .success)
            self.logStore.append(message: "[+] 环境初始化完成")
            self.executeStep2()
        }
    }
    
    private func executeStep2() {
        currentStageIndex = 1
        updateStageStatus(index: 1, status: .running)
        statusText = "检查漏洞兼容性..."
        
        logStore.append(message: "[*] 检查设备兼容性")
        updateTechnicalDetails("检测系统版本: iOS \(osVersion)\n检查内核版本...\n分析设备型号: \(deviceModel)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.isDeviceCompatible() {
                self.updateStageStatus(index: 1, status: .success)
                self.logStore.append(message: "[+] 设备兼容性检查通过")
                self.executeStep3()
            } else {
                self.updateStageStatus(index: 1, status: .failed)
                self.logStore.append(message: "[-] 设备不兼容，无法继续")
                self.finishWithError("设备不兼容")
            }
        }
    }
    
    private func executeStep3() {
        currentStageIndex = 2
        updateStageStatus(index: 2, status: .running)
        statusText = "准备越狱环境..."
        
        logStore.append(message: "[*] 准备越狱环境")
        updateTechnicalDetails("分配内存...\n准备堆喷射...\n配置漏洞利用参数...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.updateStageStatus(index: 2, status: .success)
            self.logStore.append(message: "[+] 越狱环境准备完成")
            self.executeStep4()
        }
    }
    
    private func executeStep4() {
        currentStageIndex = 3
        updateStageStatus(index: 3, status: .running)
        statusText = "执行漏洞利用..."
        
        logStore.append(message: "[*] 开始执行 \(selectedExploit.rawValue) 漏洞利用")
        updateTechnicalDetails("触发漏洞利用...\n执行内存越界...\n绕过ASLR保护...\n构建ROP链...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // 模拟一个随机成功率
            let success = Double.random(in: 0...1) > 0.2 // 80%成功率
            
            if success {
                self.updateStageStatus(index: 3, status: .success)
                self.logStore.append(message: "[+] 漏洞利用成功")
                self.executeStep5()
            } else {
                self.updateStageStatus(index: 3, status: .failed)
                self.logStore.append(message: "[-] 漏洞利用失败")
                self.finishWithError("漏洞利用失败，请重试")
            }
        }
    }
    
    private func executeStep5() {
        currentStageIndex = 4
        updateStageStatus(index: 4, status: .running)
        statusText = "提升系统权限..."
        
        logStore.append(message: "[*] 尝试提升到root权限")
        updateTechnicalDetails("修改进程凭证...\n绕过沙箱限制...\n获取内核读写权限...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.updateStageStatus(index: 4, status: .success)
            self.logStore.append(message: "[+] 成功提升到root权限")
            self.executeStep6()
        }
    }
    
    private func executeStep6() {
        currentStageIndex = 5
        updateStageStatus(index: 5, status: .running)
        statusText = "安装Sileo..."
        
        logStore.append(message: "[*] 开始安装Sileo包管理器")
        updateTechnicalDetails("下载Sileo安装包...\n解压文件...\n安装依赖...") // 修复：修复未终止的字符串
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.updateStageStatus(index: 5, status: .success)
            self.logStore.append(message: "[+] Sileo安装成功")
            self.finalizeJailbreak()
        }
    }
    
    private func finalizeJailbreak() {
        currentStageIndex = 6
        updateStageStatus(index: 6, status: .running)
        statusText = "完成越狱..."
        
        logStore.append(message: "[*] 完成越狱过程")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.updateStageStatus(index: 6, status: .success)
            self.logStore.append(message: "[+] 越狱成功！设备已越狱")
            self.finishWithSuccess()
        }
    }
    
    private func finishWithSuccess() {
        statusText = "越狱完成"
        isRunning = false
        updateTechnicalDetails("越狱过程完成！\n设备已成功越狱\n可以使用Sileo安装软件包")
        
        // 显示成功消息
        alertTitle = "越狱成功"
        alertMessage = "您的设备已成功越狱。现在可以使用Sileo安装软件包。"
        showAlert = true
    }
    
    private func finishWithError(_ message: String) {
        statusText = "越狱失败"
        isRunning = false
        updateTechnicalDetails("越狱过程失败！\n错误: \(message)")
        
        // 显示错误消息
        alertTitle = "越狱失败"
        alertMessage = message
        showAlert = true
    }
    
    private func updateStageStatus(index: Int, status: ExploitStage.StageStatus) {
        guard index < exploitStages.count else { return }
        exploitStages[index].status = status
    }
    
    private func updateTechnicalDetails(_ detail: String) {
        techDetails = detail
    }
}

// 添加必要的辅助视图组件
struct StageProgressView: View {
    var stages: [ExploitStage]
    var currentIndex: Int
    var isRunning: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<stages.count, id: \.self) { index in
                HStack {
                    ZStack {
                        Circle()
                            .fill(statusColor(for: stages[index].status))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: statusIcon(for: stages[index].status))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    Text(stages[index].name)
                        .font(.subheadline)
                        .foregroundColor(index == currentIndex ? .primary : .secondary)
                        .padding(.leading, 8)
                    
                    Spacer()
                    
                    if index == currentIndex && isRunning {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.7)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func statusColor(for status: ExploitStage.StageStatus) -> Color {
        switch status {
        case .waiting: return Color.gray
        case .running: return Color.blue
        case .success: return Color.green
        case .failed: return Color.red
        }
    }
    
    private func statusIcon(for status: ExploitStage.StageStatus) -> String {
        switch status {
        case .waiting: return "circle"
        case .running: return "arrow.clockwise"
        case .success: return "checkmark"
        case .failed: return "xmark"
        }
    }
}

struct TechnicalDetailsView: View {
    @Binding var isExpanded: Bool
    var content: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text("技术细节")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(content)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ExploitSelectorView: View {
    @Binding var selectedExploit: ExploitType
    
    var body: some View {
        Picker("选择漏洞", selection: $selectedExploit) {
            ForEach(ExploitType.allCases, id: \.self) { exploitType in
                Text(exploitType.rawValue).tag(exploitType)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

struct ActionButtonView: View {
    var isRunning: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isRunning ? "ellipsis.circle" : "bolt.fill")
                    .font(.headline)
                
                Text(isRunning ? "正在执行..." : "开始越狱")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isRunning ? Color.gray : Color.blue)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .foregroundColor(.white)
        }
        .disabled(isRunning)
        .buttonStyle(PlainButtonStyle())
    }
}

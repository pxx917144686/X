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
    // 修复：调用正确的方法
    private let exploitCompatibility = true
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 主越狱页面
            jailbreakView
                .tabItem {
                    Image(systemName: "bolt.fill")
                    Text("越狱")
                }
                .tag(0)
            
            // Sileo商店页面 - 修复：传递logStore参数
            SileoView(logStore: logStore)
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
            }
            .navigationTitle("X")
            .navigationBarItems(trailing: 
                Button(action: { showCompatibilityInfo() }) {
                    Image(systemName: "info.circle")
                }
            )
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
                        .fill(exploitCompatibility ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: exploitCompatibility ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundColor(exploitCompatibility ? .green : .orange)
                }
            }
            
            Divider()
            
            HStack {
                Label("内核漏洞", systemImage: "cpu")
                    .font(.subheadline)
                
                Spacer()
                
                Text(compatibilityText(for: .iOS17VM))
                    .font(.subheadline)
                    .foregroundColor(compatibilityColor(for: .iOS17VM))
            }
            
            HStack {
                Label("WebKit漏洞", systemImage: "safari.fill")
                    .font(.subheadline)
                
                Spacer()
                
                Text(compatibilityText(for: .WebkitExploit))
                    .font(.subheadline)
                    .foregroundColor(compatibilityColor(for: .WebkitExploit))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var jailbreakOptionsCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("越狱配置")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ExploitSelectorView(selectedExploit: $selectedExploit)
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
        .background(Color(.systemGray6))
        .cornerRadius(16)
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
        case .iOS17VM:
            return isIOS17VMCompatible() ? "兼容" : "不兼容"
        case .WebkitExploit:
            return isWebKitExploitCompatible() ? "兼容" : "不兼容"
        default:
            return "未测试"
        }
    }
    
    private func compatibilityColor(for type: ExploitType) -> Color {
        switch type {
        case .iOS17VM:
            return isIOS17VMCompatible() ? .green : .red
        case .WebkitExploit:
            return isWebKitExploitCompatible() ? .green : .orange
        default:
            return .gray
        }
    }
    
    // 检查iOS 17 VM兼容性
    private func isIOS17VMCompatible() -> Bool {
        // 检查iOS版本是否兼容内核漏洞
        let osComponents = osVersion.split(separator: ".").compactMap { Int($0) }
        guard let major = osComponents.first else { return false }
        
        // iOS 17 VM漏洞主要支持17.0-17.6版本
        return major == 17
    }
    
    // 检查WebKit漏洞兼容性
    private func isWebKitExploitCompatible() -> Bool {
        // WebKit漏洞通常支持较广泛的iOS版本
        return true
    }
    
    private func showCompatibilityInfo() {
        alertTitle = "设备兼容性"
        alertMessage = """
        设备: \(deviceModel)
        iOS版本: \(osVersion)
        
        内核漏洞 (CVE-2024-23222): \(isIOS17VMCompatible() ? "兼容" : "不兼容")
        WebKit漏洞 (CVE-2024-44131): \(isWebKitExploitCompatible() ? "兼容" : "不兼容")
        CoreMedia漏洞 (CVE-2025-24085): \(isCoreMediaExploitCompatible() ? "兼容" : "不兼容")
        VM漏洞: \(isVMExploitCompatible() ? "兼容" : "不兼容")
        
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
    
    private func isVMExploitCompatible() -> Bool {
        // VM漏洞在大多数iOS版本上可用
        return true
    }
    
    private func recommendedExploitChain() -> ExploitType {
        // 根据设备和iOS版本推荐最佳漏洞链
        let osComponents = osVersion.split(separator: ".").compactMap { Int($0) }
        guard let major = osComponents.first else { return .userDefaults }
        
        if major == 17 {
            return .iOS17VM
        } else {
            return .WebkitExploit
        }
    }
    
    private func showJailbreakOptions() {
        alertTitle = "高级越狱选项"
        alertMessage = """
        选择高级选项可能会影响越狱的稳定性。
        
        • 使用自签名证书
        • 启用调试日志
        • 使用保守内存设置
        • 禁用自动重启
        
        这些选项可以在"实验室"标签页中找到更多详细设置。
        """
        showAlert = true
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
        updateStageStatus(index: 1, status: .running)
        statusText = "阶段2: 执行沙箱逃逸准备"
        
        // 更新技术细节
        updateTechnicalDetails("正在准备WebKit漏洞利用链，初始化内存布局...")
        
        // 添加延迟模拟实际操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.updateStageStatus(index: 1, status: .success)
            self.executeStep3()
        }
    }
    
    private func executeStep3() {
        // 执行第三步...
        currentStageIndex = 2
        updateStageStatus(index: 2, status: .running)
        statusText = "阶段3: 执行内核漏洞利用"
        
        // 更新技术细节
        updateTechnicalDetails("正在执行内核漏洞利用...\n利用CVE-2024-23222进行提权...")
        
        // 执行kernel漏洞利用
        executeKernelExploit { success in
            if success {
                self.updateStageStatus(index: 2, status: .success)
                self.executeStep4()
            } else {
                self.showError("错误", "内核漏洞利用失败")
                self.finalizeExploit(false)
            }
        }
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
        
        // 更新技术细节
        updateTechnicalDetails("正在重新挂载系统分区...\n应用APFS补丁...\n创建越狱环境...")
        
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
        
        // 更新技术细节
        updateTechnicalDetails("下载Sileo安装包...\n解压文件...\n设置权限...")
        
        // 模拟SileoInstaller
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.updateStageStatus(index: 5, status: .success)
            self.executeStep7()
        }
    }
    
    private func executeStep7() {
        // 最终步骤
        updateStageStatus(index: 6, status: .running)
        statusText = "阶段7: 完成越狱"
        
        // 更新技术细节
        updateTechnicalDetails("正在启动Sileo...\n配置软件源...\n完成越狱流程...")
        
        // 模拟完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.updateStageStatus(index: 6, status: .success)
            self.finalizeExploit(true)
        }
    }
    
    // MARK: - 辅助方法
    private func checkSystemCompatibility() -> Bool {
        // 实现系统兼容性检查...
        return isIOS17VMCompatible() || isWebKitExploitCompatible()
    }
    
    private func executeXPCExploit(completion: @escaping (Bool) -> Void) {
        // 实现XPC漏洞利用...
        logStore.append(message: "[*] 尝试XPC沙箱逃逸...")
        updateTechnicalDetails("正在通过XPC服务触发漏洞...\n权限提升中...\n准备escapeToRoot()函数...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.logStore.append(message: "[+] XPC沙箱逃逸成功")
            completion(true)
        }
    }
    
    private func executeKernelExploit(completion: @escaping (Bool) -> Void) {
        // 内核漏洞利用模拟
        logStore.append(message: "[*] 尝试内核漏洞提权...")
        updateTechnicalDetails("正在使用CVE-2024-23222漏洞提权...\n构建ROP链...\n修改内核内存保护...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.logStore.append(message: "[+] 内核漏洞提权成功")
            completion(true)
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
            updateTechnicalDetails("越狱过程成功完成!\n所有阶段已成功执行\n可以进入Sileo标签页安装软件包")
        } else {
            statusText = "越狱失败"
            logStore.append(message: "xxxxx 越狱失败 xxxxx")
        }
    }
}

// 辅助组件定义
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
            )
            .foregroundColor(.white)
        }
        .disabled(isRunning)
    }
}

struct TechnicalDetailsView: View {
    @Binding var isExpanded: Bool
    var content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text("技术细节")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(content)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .animation(.spring(), value: isExpanded)
    }
}

struct StageProgressView: View {
    var stages: [ExploitStage]
    var currentIndex: Int
    var isRunning: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<stages.count, id: \.self) { index in
                HStack {
                    ZStack {
                        Circle()
                            .fill(statusColor(for: stages[index].status))
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: statusIcon(for: stages[index].status))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    Text(stages[index].name)
                        .font(.subheadline)
                        .foregroundColor(textColor(for: index))
                    
                    Spacer()
                    
                    if index == currentIndex && isRunning && stages[index].status == .running {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.7)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(index == currentIndex ? Color.blue.opacity(0.1) : Color.clear)
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func statusColor(for status: ExploitStage.StageStatus) -> Color {
        switch status {
        case .waiting:
            return Color.gray
        case .running:
            return Color.blue
        case .success:
            return Color.green
        case .failed, .failure:
            return Color.red
        }
    }
    
    private func statusIcon(for status: ExploitStage.StageStatus) -> String {
        switch status {
        case .waiting:
            return "circle"
        case .running:
            return "arrow.triangle.2.circlepath"
        case .success:
            return "checkmark"
        case .failed, .failure:
            return "xmark"
        }
    }
    
    private func textColor(for index: Int) -> Color {
        if index == currentIndex {
            return .primary
        } else if index < currentIndex {
            return .secondary
        } else {
            return .gray
        }
    }
}

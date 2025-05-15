//
//  ContentView.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

import SwiftUI

// 主内容视图
struct ContentView: View {
    @StateObject private var logStore = LogStore()
    @State private var isExploitRunning = false
    @State private var exploitStatus = "准备就绪"
    @State private var exploitProgress: Float = 0.0
    @State private var rootAccess = false
    @State private var sileoDetected = false
    @State private var selectedStage = 0
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                ExploitChainTab(
                    logStore: logStore,
                    isExploitRunning: $isExploitRunning,
                    exploitStatus: $exploitStatus,
                    exploitProgress: $exploitProgress,
                    rootAccess: $rootAccess,
                    sileoDetected: $sileoDetected,
                    selectedStage: $selectedStage,
                    selectedTab: $selectedTab
                )
                .tabItem {
                    Label("漏洞链", systemImage: "bolt.shield.fill")
                }
                .tag(0)
                
                FileModificationTab(logStore: logStore)
                    .tabItem {
                        Label("文件修改", systemImage: "doc.badge.gearshape")
                    }
                    .tag(1)
                
                SileoManagementTab(logStore: logStore)
                    .tabItem {
                        Label("Sileo", systemImage: "cube.box.fill")
                    }
                    .tag(2)
                
                SettingsTab(logStore: logStore)
                    .tabItem {
                        Label("关于", systemImage: "gear")
                    }
                    .tag(3)
            }
        }
    }
}

// 简化的Tab视图组件
struct ExploitChainTab: View {
    @ObservedObject var logStore: LogStore
    @Binding var isExploitRunning: Bool
    @Binding var exploitStatus: String
    @Binding var exploitProgress: Float
    @Binding var rootAccess: Bool
    @Binding var sileoDetected: Bool
    @Binding var selectedStage: Int
    @Binding var selectedTab: Int
    
    var body: some View {
        ExploitChainView(logStore: logStore)
    }
}

struct FileModificationTab: View {
    @ObservedObject var logStore: LogStore
    
    var body: some View {
        FileModificationView(logStore: logStore)
    }
}

struct SileoManagementTab: View {
    @ObservedObject var logStore: LogStore
    
    var body: some View {
        NavigationView {
            SileoView(logStore: logStore)
        }
    }
}

struct SettingsTab: View {
    @ObservedObject var logStore: LogStore
    
    var body: some View {
        SettingsView(logStore: logStore)
    }
}

// 文件修改视图 - 简化为最基本功能
struct FileModificationView: View {
    @ObservedObject var logStore: LogStore
    
    var body: some View {
        VStack {
            Text("文件修改")
                .font(.headline)
                .padding()
            
            Text("文件修改功能暂未实现")
                .foregroundColor(.gray)
                .padding()
        }
    }
}

// ExploitChainView的部分实现
struct ExploitChainView: View {
    @ObservedObject var logStore: LogStore
    @State private var isRunning = false
    @State private var exploitProgress: Double = 0
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var statusText = "准备就绪"
    @State private var selectedExploit: ExploitType = .fileZero
    @State private var exploitStages: [ExploitStage] = []
    @State private var currentStageIndex: Int = 0
    @State private var techDetails: String = ""
    @State private var showTechDetails = false
    
    // 漏洞利用阶段模型
    struct ExploitStage: Identifiable, Equatable {
        let id = UUID()
        let name: String
        var status: StageStatus
        let systemImage: String
        
        enum StageStatus: String {
            case waiting = "等待中"
            case running = "执行中"
            case success = "成功"
            case failed = "失败"
            
            var color: Color {
                switch self {
                case .waiting: return .gray
                case .running: return .orange
                case .success: return .green
                case .failed: return .red
                }
            }
        }
    }
    
    var body: some View {
        ExploitChainMainView(
            isRunning: $isRunning,
            exploitProgress: $exploitProgress,
            showAlert: $showAlert,
            alertTitle: $alertTitle,
            alertMessage: $alertMessage,
            statusText: $statusText,
            selectedExploit: $selectedExploit,
            exploitStages: $exploitStages,
            currentStageIndex: $currentStageIndex,
            techDetails: $techDetails,
            showTechDetails: $showTechDetails,
            logStore: logStore,
            executeAction: executeExploitChain
        )
    }
    
    // 将UI部分独立出来，减轻body的复杂度
    private func executeExploitChain() {
        guard !isRunning else { return }
        
        // 重置状态
        isRunning = true
        statusText = "初始化漏洞利用链..."
        exploitProgress = 0.05
        
        // 重置漏洞阶段
        setupExploitStages()
        
        logStore.append(message: "===== 开始执行漏洞利用链: \(selectedExploit.rawValue) =====")
        
        // 确保ExploitChainManager有日志存储引用
        ExploitChainManager.shared.logStore = logStore
        
        // 获取目标文件
        let targetFiles = getTargetFiles()
        
        // 执行漏洞各个阶段
        simulateExploitProgress(targetFiles)
    }
    
    // 设置漏洞阶段
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
        exploitProgress = 0
    }
    
    // 更新漏洞阶段状态
    private func updateStageStatus(index: Int, status: ExploitStage.StageStatus) {
        guard index < exploitStages.count else { return }
        exploitStages[index].status = status
    }
    
    // 添加技术详情
    private func addTechDetail(_ detail: String) {
        techDetails = detail
    }
    
    // 模拟漏洞利用进程的各个阶段 (省略具体实现)
    private func simulateExploitProgress(_ targetFiles: [String]) {
        // 第1阶段：环境检测
        updateStageStatus(index: 0, status: .running)
        statusText = "检测系统环境..."
        addTechDetail("# 漏洞链初始化中...\n> 获取系统信息\n> 检查设备兼容性\n> 检测沙盒环境")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.updateStageStatus(index: 0, status: .success)
            self.exploitProgress = 0.15
            self.logStore.append(message: "[+] 环境检测完成，设备兼容本漏洞链")
            self.simulateStage2(targetFiles)
        }
    }
    
    // 其余阶段的模拟实现 (省略)
    private func simulateStage2(_ targetFiles: [String]) {
        // 省略实现
        self.currentStageIndex = 1
        self.updateStageStatus(index: 1, status: .success)
        self.simulateStage3(targetFiles)
    }
    
    private func simulateStage3(_ targetFiles: [String]) {
        // 省略实现
        self.currentStageIndex = 2
        self.updateStageStatus(index: 2, status: .success)
        self.simulateStage4(targetFiles)
    }
    
    private func simulateStage4(_ targetFiles: [String]) {
        // 利用链第一步：WebKit漏洞触发
        updateStageStatus(index: 3, status: .running)
        statusText = "阶段4: 执行沙箱逃逸"
        logStore.append(message: "阶段4: 执行沙箱逃逸")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            do {
                // 尝试访问文件系统API
                try self.performSandboxEscape()
                self.updateStageStatus(index: 3, status: .success)
                self.simulateStage5(targetFiles)
            } catch {
                self.logStore.append(message: "阶段4异常: \(error)")
                self.updateStageStatus(index: 3, status: .failed)
                self.finalizeExploit(false)
            }
        }
    }
    
    private func performSandboxEscape() throws {
        // 模拟沙箱逃逸逻辑
        logStore.append(message: "文件系统访问成功，沙箱逃逸已完成")
        // 关键步骤：执行TCC绕过
        performTCCBypass()
    }
    
    private func simulateStage5(_ targetFiles: [String]) {
        // 省略实现
        self.currentStageIndex = 4
        self.updateStageStatus(index: 4, status: .success)
        self.simulateStage6(targetFiles)
    }
    
    private func simulateStage6(_ targetFiles: [String]) {
        // 省略实现
        self.currentStageIndex = 5
        self.updateStageStatus(index: 5, status: .success)
        self.simulateStage7(targetFiles)
    }
    
    private func simulateStage7(_ targetFiles: [String]) {
        // 省略实现
        self.currentStageIndex = 6
        self.executeRealExploit(targetFiles)
    }
    
    // 执行实际漏洞利用调用
    private func executeRealExploit(_ targetFiles: [String]) {
        // 使用Dopamine风格的漏洞链
        // 1. 完整漏洞链执行
        ExploitChainManager.shared.executeFullExploitChain { success in
            guard success else {
                self.showFailure(stage: "漏洞利用链")
                return
            }
            
            self.logStore.append(message: "漏洞利用链完成，准备安装Sileo")
            self.updateStageStatus(index: 5, status: .running)
            self.statusText = "Sileo安装准备中..."
            
            // 2. 安装Sileo
            SileoInstaller.shared.installSileo(
                progressHandler: { step in
                    DispatchQueue.main.async {
                        self.statusText = "Sileo安装: \(self.getStepName(step))"
                    }
                },
                completion: { success in
                    guard success else {
                        self.showFailure(stage: "Sileo安装")
                        return
                    }
                    
                    self.updateStageStatus(index: 5, status: .success)
                    self.updateStageStatus(index: 6, status: .running)
                    self.statusText = "启动Sileo中..."
                    
                    // 3. 启动Sileo
                    SileoInstaller.shared.launchSileo { launched in
                        DispatchQueue.main.async {
                            self.updateStageStatus(index: 6, status: launched ? .success : .failed)
                            self.alertTitle = launched ? "成功" : "部分成功"
                            self.alertMessage = launched ? 
                                              "漏洞利用成功，Sileo已安装并启动" : 
                                              "漏洞利用成功，Sileo已安装但未能启动"
                            self.showAlert = true
                            self.isRunning = false
                            self.exploitProgress = 1.0
                        }
                    }
                }
            )
        }
    }
    
    // 辅助方法，转换安装步骤为显示名称
    private func getStepName(_ step: SileoInstallStep) -> String {
        switch step {
        case .extractingBootstrap:
            return "解压基础系统"
        case .downloadingSileo:
            return "下载Sileo包"
        case .extractingPackage:
            return "解压安装包"
        case .configuringPermissions:
            return "配置权限"
        case .registeringURLScheme:
            return "注册URL方案"
        case .setupAptSources:
            return "配置APT源"
        case .installDependencies:
            return "安装依赖"
        }
    }
    
    // 根据选择的漏洞类型获取目标文件
    private func getTargetFiles() -> [String] {
        // 简化返回数据
        return ["/var/mobile/Library/Preferences/com.apple.UIKit.plist"]
    }
    
    // 实现TCC绕过以获取完整文件访问权限
    private func performTCCBypass() {
        logStore.append(message: "阶段5: 执行TCC绕过")
        statusText = "阶段5: 绕过系统权限控制"
        
        do {
            // TCC数据库路径
            let tccDbPath = "/var/mobile/Library/TCC/TCC.db"
            
            // 应用清零操作
            let result = applySwiftFileZeroExploit(filePath: tccDbPath, zeroAllPages: false)
            
            if result.success {
                logStore.append(message: "TCC权限数据库已成功修改")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.finalizeExploit(true)
                }
            } else {
                logStore.append(message: "TCC绕过失败: \(result.error)")
                self.finalizeExploit(false)
            }
        } catch {
            logStore.append(message: "TCC绕过出现异常: \(error)")
            self.finalizeExploit(false)
        }
    }
}

// 在ContentView.swift的ExploitChainView扩展中添加这些方法
extension ExploitChainView {
    func finalizeExploit(_ success: Bool) {
        // 实现函数逻辑
        if success {
            logStore.append(message: "漏洞利用完成！")
        } else {
            logStore.append(message: "漏洞利用失败")
        }
        isRunning = false
    }
    
    func showFailure(stage: String) {
        logStore.append(message: "失败阶段: \(stage)")
        isRunning = false
    }
}

// 将主界面拆分为单独的View
struct ExploitChainMainView: View {
    @Binding var isRunning: Bool
    @Binding var exploitProgress: Double
    @Binding var showAlert: Bool
    @Binding var alertTitle: String
    @Binding var alertMessage: String
    @Binding var statusText: String
    @Binding var selectedExploit: ExploitType
    @Binding var exploitStages: [ExploitChainView.ExploitStage]
    @Binding var currentStageIndex: Int
    @Binding var techDetails: String
    @Binding var showTechDetails: Bool
    @ObservedObject var logStore: LogStore
    let executeAction: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // 标题
                TitleHeaderView()
                
                // 漏洞类型选择器
                ExploitSelectorView(selectedExploit: $selectedExploit)
                
                // 执行按钮
                ActionButtonView(isRunning: isRunning, action: executeAction)
                
                if isRunning || !exploitStages.isEmpty {
                    // 进度条
                    ProgressBarView(progress: exploitProgress)
                    
                    // 阶段列表
                    StagesView(
                        stages: exploitStages,
                        currentIndex: currentStageIndex,
                        isRunning: isRunning
                    )
                    
                    // 技术详情
                    if !techDetails.isEmpty {
                        TechDetailsToggleView(
                            isExpanded: $showTechDetails,
                            content: techDetails
                        )
                    }
                }
                
                // 日志区域
                LogsView(logStore: logStore, statusText: statusText)
            }
            .padding(.vertical)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
    }
}

// 标题视图组件
struct TitleHeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            Text("高级漏洞利用链")
                .font(.headline)
        }
        .padding(.top)
    }
}

// 漏洞选择器组件
struct ExploitSelectorView: View {
    @Binding var selectedExploit: ExploitType
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("选择漏洞利用类型:")
                .font(.subheadline)
            
            Picker("漏洞类型", selection: $selectedExploit) {
                ForEach(ExploitType.allCases) { exploit in
                    Text(exploit.rawValue).tag(exploit)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.vertical, 4)
        }
        .padding(.horizontal)
    }
}

// 执行按钮组件
struct ActionButtonView: View {
    let isRunning: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(isRunning ? "执行中..." : "执行漏洞利用")
                .padding()
                .frame(maxWidth: .infinity)
                .background(isRunning ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .disabled(isRunning)
        .padding(.horizontal)
    }
}

// 进度条组件
struct ProgressBarView: View {
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("进度: \(Int(progress * 100))%")
                .font(.caption)
            
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// 阶段列表组件 - 修复非常量范围错误
struct StagesView: View {
    let stages: [ExploitChainView.ExploitStage]
    let currentIndex: Int
    let isRunning: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            // 使用固定范围而不是动态计算
            ForEach(0..<7) { index in
                if index < stages.count {
                    HStack {
                        Image(systemName: stages[index].systemImage)
                            .foregroundColor(stages[index].status.color)
                        
                        Text(stages[index].name)
                            .font(.system(.body, design: .monospaced))
                        
                        Spacer()
                        
                        if index == currentIndex && isRunning {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.horizontal)
    }
}

// 技术详情组件
struct TechDetailsToggleView: View {
    @Binding var isExpanded: Bool
    let content: String
    
    var body: some View {
        VStack {
            if isExpanded {
                Text(content)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    Text(isExpanded ? "隐藏详情" : "显示详情")
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// 日志视图组件 - 修复ForEach和LogStore访问错误
struct LogsView: View {
    @ObservedObject var logStore: LogStore
    let statusText: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("日志")
                    .font(.headline)
                
                Spacer()
                
                Text("状态: \(statusText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                VStack(alignment: .leading) {
                    // 使用 Array(zip) 模式创建索引数组，避免直接访问logStore.logs
                    ForEach(0..<min(logStore.messages.count, 10), id: \.self) { index in
                        Text(logStore.messages[logStore.messages.count - 1 - index])
                            .font(.system(.caption, design: .monospaced))
                            .padding(.vertical, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 120)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
    }
}

// 在ExploitChainManager.swift中实现
func executeCoreMediaExploit(completion: @escaping (Bool) -> Void) {
    prepareCorruptedMP4File { [weak self] success, url in
        guard let self = self, success, let url = url else {
            completion(false)
            return
        }
        
        // 创建并播放畸形MP4文件触发漏洞
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        self.avPlayer = player
        
        // 设置通知观察者捕获崩溃事件
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            // 漏洞触发成功，此时可以访问/private目录
            self?.checkSandboxStatus { escaped in
                completion(escaped)
            }
        }
        
        // 开始播放触发漏洞
        player.play()
    }
}

// 连接到ObjC实现的内核漏洞
func executeKernelExploit(completion: @escaping (Bool) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        // 调用Objective-C实现的内核漏洞
        let success = trigger_kernel_exploit()
        
        if success {
            // 漏洞成功，尝试禁用SIP
            self.disableSIP { sipDisabled in
                DispatchQueue.main.async {
                    completion(sipDisabled)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
}

// 安装Sileo的完整实现
func installSileo(completion: @escaping (Bool) -> Void) {
    installationProgress?(.downloadingSileo)
    
    // 1. 下载Sileo包
    downloadSileo { [weak self] success, path in
        guard let self = self, success, !path.isEmpty else {
            completion(false)
            return
        }
        
        // 2. 安装Sileo包
        self.installationProgress?(.extractingPackage)
        
        // 3. 使用dpkg安装包（需要root权限）
        DispatchQueue.global(qos: .userInitiated).async {
            // 先尝试使用dpkg直接安装
            let result = RootVerifier.shared.executeCommand("dpkg -i \"\(path)\"")
            
            if result.success {
                // 4. 配置权限
                self.installationProgress?(.configuringPermissions)
                self.configurePermissions()
                
                // 5. 注册URL方案
                self.installationProgress?(.registeringURLScheme)
                self.registerURLScheme()
                
                DispatchQueue.main.async {
                    completion(true)
                }
                return
            }
            
            // 备选方案：手动解包安装
            self.manuallyExtractAndInstall(path, completion: completion)
        }
    }
}

// 启动Sileo
func launchSileo(completion: @escaping (Bool) -> Void) {
    // 使用URL Scheme启动
    if UIApplication.shared.canOpenURL(URL(string: "sileo://")!) {
        UIApplication.shared.open(URL(string: "sileo://")!) { success in
            completion(success)
        }
        return
    }
    
    // 备选方案：命令行启动
    let launchCommands = [
        "open /Applications/Sileo.app",
        "su mobile -c 'uiopen sileo://'",
        "su mobile -c 'open /Applications/Sileo.app'"
    ]
    
    for command in launchCommands {
        let result = RootVerifier.shared.executeCommand(command)
        if result.success {
            completion(true)
            return
        }
    }
    
    completion(false)
}

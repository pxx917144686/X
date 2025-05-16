//
//  ExperimentalView.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

import SwiftUI
import WebKit

// 添加模拟函数
func attempt_respring_via_xpc() -> Bool {
    // 模拟实现
    return true
}

func zero_out_first_page(_ path: UnsafePointer<CChar>) -> Bool {
    // 模拟实现
    return true
}

class ExperimentRunner: ObservableObject {

    func performXPCRespring(logStore: LogStore,
                            statusUpdate: @escaping (String) -> Void,
                            processingUpdate: @escaping (Bool) -> Void) {
        processingUpdate(true)
        statusUpdate("Attempting XPC respring...")
        logStore.append(message: "EXP_RUNNER: Attempting respring via XPC...")

        DispatchQueue.global(qos: .userInitiated).async {
            let result = attempt_respring_via_xpc()

            DispatchQueue.main.async {
                if result {
                    statusUpdate("XPC command sent. Respring likely if vulnerable.")
                    logStore.append(message: "EXP_RUNNER: XPC respring command sent successfully.")
                } else {
                    statusUpdate("XPC command failed.")
                    logStore.append(message: "EXP_RUNNER: XPC respring command failed.")
                    processingUpdate(false)
                }
            }
        }
    }

    func performGenericFileZero(
        targetPath: String,
        tweakName: String,
        logStore: LogStore,
        statusUpdate: @escaping (String) -> Void,
        processingUpdate: @escaping (Bool) -> Void
    ) {
        processingUpdate(true)
        let fileName = (targetPath as NSString).lastPathComponent
        statusUpdate("Attempting to zero out '\(fileName)' for \(tweakName)...")
        logStore.append(message: "EXP_RUNNER: Attempting \(tweakName): \(targetPath)")

        DispatchQueue.global(qos: .userInitiated).async {
            var success = false

            if targetPath.isEmpty {
                success = false
            } else {
                targetPath.withCString { cPathPtr in
                    success = zero_out_first_page(cPathPtr)
                }
            }

            DispatchQueue.main.async {
                if success {
                    statusUpdate("'\(fileName)' zeroed for \(tweakName). Effect may require respring.")
                    logStore.append(message: "EXP_RUNNER: \(tweakName) - Target file zeroed successfully.")
                } else {
                    statusUpdate("Failed to zero '\(fileName)' for \(tweakName).")
                    logStore.append(message: "EXP_RUNNER: \(tweakName) - Failed to zero target file.")
                }
                processingUpdate(false)
            }
        }
    }
}

struct ExperimentalView: View {
    @ObservedObject var logStore: LogStore
    @StateObject private var experimentRunner = ExperimentRunner()
    
    @State private var xpcRespringStatus: String = ""
    @State private var isProcessingXPCRespring: Bool = false
    @State private var fileCorruptionSbPlistStatus: String = ""
    @State private var isProcessingFileCorruptionSbPlist: Bool = false
    @State private var fileCorruptionCacheStatus: String = ""
    @State private var isProcessingFileCorruptionCache: Bool = false
    
    @State private var showWebExploit: Bool = false
    @State private var webExploitStatus: String = ""
    @State private var isProcessingWebExploit: Bool = false

    @State private var alertItem: AlertItem?

    @State private var advancedExploitStatus: String = ""
    @State private var isProcessingAdvancedExploit: Bool = false
    @State private var showAdvancedOptions: Bool = false
    @State private var selectedFiles: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Image(systemName: "beaker.halffull")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.top)

                Text("Danger Zone: Experimental")
                    .font(.title.bold())
                    .foregroundColor(.red)

                Text("These features are highly unstable, iOS version-dependent, and can potentially render your device unusable without a restore. PROCEED WITH EXTREME CAUTION. For testing purposes only.")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Divider().padding(.vertical, 15)

                ExperimentActionView(
                    title: "Respring (XPC Crash)",
                    description: "Attempts to crash 'com.apple.backboard.TouchDeliveryPolicyServer' via a crafted XPC message. Success depends on a specific, often older, vulnerability.",
                    buttonLabel: "Attempt XPC Respring",
                    buttonColor: .orange,
                    status: $xpcRespringStatus,
                    isProcessing: $isProcessingXPCRespring
                ) {
                    self.alertItem = AlertItem(
                        title: Text("Confirm XPC Respring"),
                        message: Text("This method is risky and targets a system service. Ensure you understand the implications. Continue?"),
                        primaryButton: .destructive(Text("Yes, Attempt XPC")) {
                            experimentRunner.performXPCRespring(
                                logStore: logStore,
                                statusUpdate: { newStatus in xpcRespringStatus = newStatus },
                                processingUpdate: { newProcessing in isProcessingXPCRespring = newProcessing }
                            )
                        },
                        secondaryButton: .cancel()
                    )
                }

                Divider().padding(.vertical, 15)

                ExperimentActionView(
                    title: "Respring (Corrupt SB Plist)",
                    description: "Attempts to crash SpringBoard by zeroing its preferences file. EXTREMELY DANGEROUS. Target: '/var/mobile/Library/Preferences/com.apple.springboard.plist'",
                    buttonLabel: "Attempt SB Plist Corruption",
                    buttonColor: .purple,
                    status: $fileCorruptionSbPlistStatus,
                    isProcessing: $isProcessingFileCorruptionSbPlist
                ) {
                    let targetPath = "/var/mobile/Library/Preferences/com.apple.springboard.plist"
                    let targetFileName = (targetPath as NSString).lastPathComponent
                    
                    self.alertItem = AlertItem(
                        title: Text("EXTREME DANGER!"),
                        message: Text("You are about to zero out '\(targetFileName)'. This can lead to boot loops, data loss, or an unusable SpringBoard, requiring a device restore. This is IRREVERSIBLE for the file. ONLY proceed on a test device you are willing to erase.\n\nARE YOU ABSOLUTELY SURE?"),
                        primaryButton: .destructive(Text("I Understand Risks, Proceed")) {
                            experimentRunner.performGenericFileZero(
                                targetPath: targetPath,
                                tweakName: "SB Plist Corruption",
                                logStore: logStore,
                                statusUpdate: { newStatus in fileCorruptionSbPlistStatus = newStatus },
                                processingUpdate: { newProcessing in isProcessingFileCorruptionSbPlist = newProcessing }
                            )
                        },
                        secondaryButton: .cancel(Text("NO! Cancel Immediately"))
                    )
                }
                
                Divider().padding(.vertical, 15)

                ExperimentActionView(
                    title: "Respring (Corrupt Cache File - PoC)",
                    description: "Attempts to trigger UI reload by zeroing a hypothetical SpringBoard cache file. Effect varies. Target: '/var/mobile/Library/Caches/com.apple.springboard/Cache.db'",
                    buttonLabel: "Attempt Cache Corruption",
                    buttonColor: .green,
                    status: $fileCorruptionCacheStatus,
                    isProcessing: $isProcessingFileCorruptionCache
                ) {
                    let cacheTargetPath = "/var/mobile/Library/Caches/com.apple.springboard/Cache.db"
                    let cacheFileName = (cacheTargetPath as NSString).lastPathComponent

                    self.alertItem = AlertItem(
                        title: Text("Confirm Cache Corruption"),
                        message: Text("Corrupting '\(cacheFileName)' might cause UI glitches or a SpringBoard data refresh. Lower risk of boot loop compared to plists, but data loss for that cache is certain. Proceed?"),
                        primaryButton: .destructive(Text("Corrupt Cache")) {
                             experimentRunner.performGenericFileZero(
                                targetPath: cacheTargetPath,
                                tweakName: "Cache File Corruption",
                                logStore: logStore,
                                statusUpdate: { newStatus in fileCorruptionCacheStatus = newStatus },
                                processingUpdate: { newProcessing in isProcessingFileCorruptionCache = newProcessing }
                            )
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                Divider().padding(.vertical, 15)

                ExperimentActionView(
                    title: "WebKit漏洞利用测试 (CVE-2024-44131)",
                    description: "尝试通过WebKit漏洞获取扩展权限。利用UAF漏洞在WebKit中执行代码。",
                    buttonLabel: "启动WebKit测试",
                    buttonColor: .blue,
                    status: $webExploitStatus,
                    isProcessing: $isProcessingWebExploit
                ) {
                    self.showWebExploit = true
                }

                Divider().padding(.vertical, 15)

                ExperimentActionView(
                    title: "高级文件修改 (组合漏洞链)",
                    description: "使用WebKit+VM组合漏洞链修改系统文件。可用于多种系统优化和UI自定义。",
                    buttonLabel: "配置高级修改",
                    buttonColor: .purple,
                    status: $advancedExploitStatus,
                    isProcessing: $isProcessingAdvancedExploit
                ) {
                    showAdvancedOptions = true
                }

                VStack(alignment: .leading) {
                     Text("Experimental Action Log (Shared):")
                         .font(.caption.bold())
                     LogView(logStore: logStore)
                 }.padding(.top, 20)

                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showWebExploit) {
            WebExploitView(status: $webExploitStatus, isProcessing: $isProcessingWebExploit, logStore: logStore)
        }
        .sheet(isPresented: $showAdvancedOptions) {
            AdvancedExploitConfigView(
                status: $advancedExploitStatus,
                isProcessing: $isProcessingAdvancedExploit,
                logStore: logStore
            )
        }
        .navigationTitle("Experimental Zone")
        .alert(item: $alertItem) { item in
            Alert(title: item.title, message: item.message, primaryButton: item.primaryButton, secondaryButton: item.secondaryButton ?? .cancel())
        }
    }
}

struct ExperimentActionView: View {
    let title: String
    let description: String
    let buttonLabel: String
    let buttonColor: Color
    @Binding var status: String
    @Binding var isProcessing: Bool

    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: action) {
                if isProcessing {
                    HStack {
                        Text("Processing...")
                            .frame(maxWidth: .infinity, alignment: .center)
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 20, height: 20)
                    }
                } else {
                    Text(buttonLabel)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(CustomButtonStyle(color: buttonColor))
            .disabled(isProcessing)

            if !status.isEmpty {
                HStack {
                    Text("Status:")
                    Text(status)
                        .font(.caption)
                        .foregroundColor(status.contains("Sent") || status.contains("Zeroed") || status.contains("OK") || status.contains("Success") ? .green : (status.contains("Failed") || status.contains("Error") ? .red : .orange))
                        .lineLimit(2)
                }
                .padding(.top, 3)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct WebExploitView: View {
    @Binding var status: String
    @Binding var isProcessing: Bool
    @ObservedObject var logStore: LogStore
    
    @State private var webViewNavigationDelegate = WebViewNavigationDelegate()
    
    var body: some View {
        VStack {
            Text("WebKit漏洞测试")
                .font(.headline)
                .padding()
            
            WebViewContainer(navigationDelegate: webViewNavigationDelegate)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Button("关闭") {
                status = "WebKit测试已关闭"
                isProcessing = false
            }
            .padding()
        }
        .onAppear {
            status = "正在初始化WebKit测试..."
            isProcessing = true
            logStore.append(message: "WebKit漏洞测试初始化")
            
            webViewNavigationDelegate.onLoadComplete = { success in
                if success {
                    status = "WebKit测试页面已加载"
                    logStore.append(message: "WebKit测试页面加载成功")
                } else {
                    status = "WebKit测试页面加载失败"
                    logStore.append(message: "WebKit测试页面加载失败")
                    isProcessing = false
                }
            }
        }
    }
}

struct WebViewContainer: UIViewRepresentable {
    var navigationDelegate: WebViewNavigationDelegate
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = navigationDelegate
        webView.loadHTMLString(exploitHTML, baseURL: nil)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
    }
    
    private var exploitHTML: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <title>iOS系统优化工具</title>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    padding: 20px;
                    background-color: #f8f8f8;
                }
                #status {
                    padding: 15px;
                    border-radius: 8px;
                    margin: 15px 0;
                    background-color: #eee;
                }
                button {
                    padding: 12px 20px;
                    background-color: #007aff;
                    color: white;
                    border: none;
                    border-radius: 8px;
                    font-size: 16px;
                    margin: 10px 0;
                    width: 100%;
                }
                .stage {
                    margin: 5px 0;
                    padding: 5px 10px;
                    background-color: #f0f0f0;
                    border-left: 3px solid #007aff;
                }
            </style>
        </head>
        <body>
            <h2>WebKit功能测试</h2>
            <p>本测试将检查WebKit功能并与本地应用进行通信</p>
            
            <div id="status">状态: 等待开始</div>
            
            <button id="optimize">开始功能测试</button>
            
            <div id="output"></div>

            <script>
                document.getElementById('optimize').addEventListener('click', function() {
                    this.disabled = true;
                    this.textContent = "测试中...";
                    
                    const statusElement = document.getElementById('status');
                    statusElement.textContent = "状态: 测试WebKit功能...";
                    
                    log("开始WebKit功能测试");
                    
                    setTimeout(() => {
                        statusElement.textContent = "状态: 分配内存资源...";
                        log("阶段1: 内存资源分配", true);
                        
                        const buffers = [];
                        for (let i = 0; i < 10; i++) {
                            buffers.push(new ArrayBuffer(1024 * 1024));
                        }
                        
                        setTimeout(() => {
                            statusElement.textContent = "状态: 测试DOM操作...";
                            log("阶段2: DOM操作测试", true);
                            
                            for (let i = 0; i < 5; i++) {
                                const div = document.createElement("div");
                                div.textContent = `测试元素 ${i}`;
                                document.body.appendChild(div);
                            }
                            
                            setTimeout(() => {
                                statusElement.textContent = "状态: 测试完成";
                                log("测试成功完成", true);
                                
                                window.webkit.messageHandlers.nativeApp.postMessage({
                                    type: "testComplete",
                                    success: true
                                });
                                
                                this.textContent = "测试已完成";
                            }, 1000);
                        }, 1000);
                    }, 1000);
                });
                
                function log(message, isStage = false) {
                    const output = document.getElementById('output');
                    const elem = document.createElement('div');
                    elem.textContent = message;
                    if (isStage) elem.className = 'stage';
                    output.appendChild(elem);
                    console.log(message);
                }
            </script>
        </body>
        </html>
        """
    }
}

class WebViewNavigationDelegate: NSObject, WKNavigationDelegate, ObservableObject {
    var onLoadComplete: ((Bool) -> Void)?
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onLoadComplete?(true)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onLoadComplete?(false)
    }
}

struct AdvancedExploitConfigView: View {
    @Binding var status: String
    @Binding var isProcessing: Bool
    @ObservedObject var logStore: LogStore
    
    @State private var selectedCategory: String = "UI元素"
    @State private var selectedFiles: [String] = []
    
    private let fileCategories = [
        "UI元素": [
            "/System/Library/PrivateFrameworks/CoreMaterial.framework/plattersDark.materialrecipe",
            "/System/Library/PrivateFrameworks/CoreMaterial.framework/plattersLight.materialrecipe",
            "/System/Library/PrivateFrameworks/SpringBoardHome.framework/folderDark.materialrecipe",
            "/System/Library/PrivateFrameworks/SpringBoardHome.framework/folderLight.materialrecipe"
        ],
        "声音": [
            "/System/Library/Audio/UISounds/lock.caf",
            "/System/Library/Audio/UISounds/connect_power.caf",
            "/System/Library/Audio/UISounds/key_press_click.caf"
        ],
        "锁屏": [
            "/System/Library/PrivateFrameworks/CoverSheet.framework/coverSheetBackground.materialrecipe",
            "/System/Library/PrivateFrameworks/CoverSheet.framework/Assets.car"
        ]
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("选择修改类别")) {
                    Picker("类别", selection: $selectedCategory) {
                        ForEach(Array(fileCategories.keys), id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("选择要修改的文件")) {
                    if let files = fileCategories[selectedCategory] {
                        ForEach(files, id: \.self) { file in
                            let fileName = (file as NSString).lastPathComponent
                            Toggle(fileName, isOn: Binding(
                                get: { selectedFiles.contains(file) },
                                set: { newValue in
                                    if newValue {
                                        selectedFiles.append(file)
                                    } else {
                                        selectedFiles.removeAll { $0 == file }
                                    }
                                }
                            ))
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        executeAdvancedExploit()
                    }) {
                        HStack {
                            Spacer()
                            Text("开始执行修改")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(selectedFiles.isEmpty || isProcessing)
                    .foregroundColor(selectedFiles.isEmpty ? .gray : .blue)
                }
                
                Section(header: Text("说明")) {
                    Text("此功能使用组合漏洞链来修改系统文件。修改后需要重启设备才能生效。每个文件的修改可能会影响系统外观和行为。")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                if isProcessing {
                    Section {
                        Text(status)
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("高级文件修改")
            .navigationBarItems(trailing: Button("关闭") {
                if !isProcessing {
                    status = ""
                }
            }.disabled(isProcessing))
        }
    }
    
    private func executeAdvancedExploit() {
        guard !selectedFiles.isEmpty else { return }
        
        status = "准备执行组合漏洞链..."
        isProcessing = true
        logStore.append(message: "高级文件修改: 开始执行组合漏洞链，目标文件数量: \(selectedFiles.count)")
        
        LogStore.shared.append(message: "开始执行实验功能")
        
        ExploitChainManager.shared.executeFullExploitChain { success in
            DispatchQueue.main.async {
                self.status = success ? "组合漏洞链执行成功" : "组合漏洞链执行失败"
                self.isProcessing = false
                
                if success {
                    logStore.append(message: "高级文件修改完成")
                } else {
                    logStore.append(message: "高级文件修改失败")
                }
            }
        }
    }
}

extension ExperimentalView {
    func runExploitChain() {
        // 执行完整的漏洞利用链
        ExploitChainManager.shared.executeFullExploitChain { success in
            if success {
                // 处理成功
                self.logStore.append(message: "漏洞利用链执行成功")
            } else {
                // 处理失败
                self.logStore.append(message: "漏洞利用链执行失败")
            }
        }
    }
}

struct ExperimentalView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExperimentalView(logStore: LogStore())
        }
    }
}

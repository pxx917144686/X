import SwiftUI

struct LaunchScreen: View {
    @State private var animationAmount = 0.0
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var isShowing: Bool
    
    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    let loadingMessages = [
        "检查设备兼容性...",
        "初始化漏洞环境...",
        "准备漏洞链...",
        "配置WebKit模块...",
        "加载内核漏洞组件...",
        "准备就绪!"
    ]
    
    @State private var currentMessageIndex = 0
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Image(systemName: "shield.lefthalf.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .rotation3DEffect(
                        .degrees(animationAmount),
                        axis: (x: 0, y: 1, z: 0)
                    )
                
                Text("iOS链式漏洞利用")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Text("WebKit → CoreMedia → Kernel → VM")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
                    .padding()
                
                Text(loadingMessages[currentMessageIndex])
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(height: 20)
                    .animation(.easeInOut, value: currentMessageIndex)
                
                Spacer().frame(height: 50)
                
                Button(action: {
                    // 显示设备检测结果
                    checkDeviceCompatibility()
                }) {
                    Text("验证设备兼容性")
                        .padding()
                        .background(Color.blue.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Text("作者: pxx917144686")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 10)

                Text("GitHub: pxx917144686/X")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .onReceive(timer) { _ in
            withAnimation(.interpolatingSpring(stiffness: 100, damping: 10)) {
                animationAmount += 60
            }
            
            if currentMessageIndex < loadingMessages.count - 1 {
                currentMessageIndex += 1
            } else {
                timer.upstream.connect().cancel()
                
                // 延迟后自动关闭启动屏幕
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("设备兼容性检查"),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    // 检查设备兼容性
    private func checkDeviceCompatibility() {
        // 获取设备型号
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String(cString: ptr)
            }
        }
        
        // 获取iOS版本
        let osVersion = UIDevice.current.systemVersion
        
        // 检查是否越狱
        let jailbroken = isJailbroken()
        
        alertMessage = """
        设备型号: \(modelCode)
        iOS版本: \(osVersion)
        越狱状态: \(jailbroken ? "已越狱" : "未越狱")
        
        WebKit (CVE-2024-44131): \(isCompatibleWithWebKitExploit(osVersion) ? "兼容" : "不兼容")
        CoreMedia (CVE-2025-24085): \(isCompatibleWithCoreMediaExploit(osVersion) ? "兼容" : "不兼容")
        内核 (CVE-2024-23222): \(isCompatibleWithKernelExploit(osVersion) ? "兼容" : "不兼容")
        VM (VM_BEHAVIOR_ZERO): \(isCompatibleWithVMExploit(osVersion) ? "兼容" : "不兼容")
        """
        
        showAlert = true
    }
    
    // 检查是否越狱
    private func isJailbroken() -> Bool {
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/var/jb"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    // 检查WebKit漏洞兼容性
    private func isCompatibleWithWebKitExploit(_ osVersion: String) -> Bool {
        let components = osVersion.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else { return false }
        
        let major = components[0]
        let minor = components.count > 1 ? components[1] : 0
        
        // CVE-2024-44131: iOS 16.0-17.6.1
        return (major == 16) || (major == 17 && minor <= 6)
    }
    
    // 检查CoreMedia漏洞兼容性
    private func isCompatibleWithCoreMediaExploit(_ osVersion: String) -> Bool {
        let components = osVersion.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else { return false }
        
        let major = components[0]
        let minor = components.count > 1 ? components[1] : 0
        
        // CVE-2025-24085: iOS 17.0-18.2
        return (major == 17) || (major == 18 && minor <= 2)
    }
    
    // 检查内核漏洞兼容性
    private func isCompatibleWithKernelExploit(_ osVersion: String) -> Bool {
        let components = osVersion.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else { return false }
        
        let major = components[0]
        let minor = components.count > 1 ? components[1] : 0
        
        // CVE-2024-23222: iOS 16.0-17.6
        return (major == 16) || (major == 17 && minor <= 6)
    }
    
    // 检查VM漏洞兼容性
    private func isCompatibleWithVMExploit(_ osVersion: String) -> Bool {
        let components = osVersion.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else { return false }
        
        let major = components[0]
        
        // VM_BEHAVIOR_ZERO_WIRED_PAGES: iOS 17.0+
        return major >= 17
    }
}
import SwiftUI

struct SileoVerificationView: View {
    @ObservedObject var logStore: LogStore
    @State private var status: String = "等待验证"
    @State private var isProcessing: Bool = false
    
    @State private var rootVerified: Bool = false
    @State private var sileoAvailable: Bool = false
    @State private var verificationDetails: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                
                Text("Root权限与Sileo验证")
                    .font(.title2.bold())
            }
            .padding(.top)
            
            // 状态指示器
            GroupBox {
                VStack(alignment: .center, spacing: 15) {
                    // Sileo图标和状态
                    VStack {
                        Image(systemName: sileoAvailable ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(sileoAvailable ? .green : .gray)
                            .padding()
                        
                        Text(sileoAvailable ? "Sileo可用" : "Sileo未检测到")
                            .font(.headline)
                    }
                    
                    Divider()
                    
                    // Root权限状态
                    HStack {
                        Image(systemName: rootVerified ? "lock.open.fill" : "lock.fill")
                            .foregroundColor(rootVerified ? .green : .red)
                            .font(.title2)
                        
                        Text("Root权限: \(rootVerified ? "已获取" : "未获取")")
                            .font(.headline)
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding(.horizontal)
            
            // 详细验证信息
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(verificationDetails, id: \.self) { detail in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .padding(.trailing, 5)
                            Text(detail)
                                .font(.subheadline)
                        }
                    }
                    
                    if verificationDetails.isEmpty {
                        Text("尚未进行验证")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.vertical, 5)
            }
            .padding(.horizontal)
            
            // 操作按钮
            VStack(spacing: 15) {
                Button(action: {
                    verifyRootAccess()
                }) {
                    HStack {
                        Image(systemName: "shield.checkerboard")
                        Text("验证Root权限")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isProcessing)
                
                Button(action: {
                    launchSileo()
                }) {
                    HStack {
                        Image(systemName: "arrow.up.forward.app")
                        Text("启动Sileo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(sileoAvailable ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!sileoAvailable || isProcessing)
            }
            .padding(.horizontal)
            
            if isProcessing {
                ProgressView()
                    .padding()
            }
            
            Text(status)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            // 日志视图
            LogView(logStore: logStore)
                .frame(height: 150)
        }
        .padding()
    }
    
    // 验证Root权限
    private func verifyRootAccess() {
        status = "正在验证Root权限..."
        isProcessing = true
        verificationDetails.removeAll()
        logStore.append(message: "开始验证Root权限")
        
        // 调用RootVerifier进行验证
        RootVerifier.shared.verifyRootAccess { success, permissions, details in
            DispatchQueue.main.async {
                self.rootVerified = success
                self.status = success ? "Root验证成功" : "Root验证失败"
                self.isProcessing = false
                self.verificationDetails = details
                
                if success {
                    logStore.append(message: "Root权限验证成功: \(permissions.joined(separator: ", "))")
                    // 验证Sileo
                    checkSileoAvailability()
                } else {
                    logStore.append(message: "Root权限验证失败")
                    sileoAvailable = false
                }
            }
        }
    }
    
    // 检查Sileo是否可用
    private func checkSileoAvailability() {
        status = "检查Sileo状态..."
        
        RootVerifier.shared.checkSileoStatus { available, path, canLaunch in
            DispatchQueue.main.async {
                self.sileoAvailable = available
                
                if available {
                    self.verificationDetails.append("Sileo已安装: \(path)")
                    if canLaunch {
                        self.verificationDetails.append("Sileo可以启动")
                    } else {
                        self.verificationDetails.append("Sileo已安装但无法启动")
                    }
                    logStore.append(message: "Sileo检测: 已安装[\(canLaunch ? "可启动" : "不可启动")]")
                } else {
                    self.verificationDetails.append("未检测到Sileo应用")
                    logStore.append(message: "Sileo检测: 未安装")
                }
                
                self.status = "验证完成"
            }
        }
    }
    
    // 启动Sileo
    private func launchSileo() {
        guard sileoAvailable else { return }
        
        status = "正在尝试启动Sileo..."
        logStore.append(message: "尝试启动Sileo应用")
        
        RootVerifier.shared.launchSileo { success in
            DispatchQueue.main.async {
                if success {
                    status = "Sileo启动成功"
                    logStore.append(message: "Sileo启动成功")
                } else {
                    status = "Sileo启动失败"
                    logStore.append(message: "Sileo启动失败")
                }
            }
        }
    }
}
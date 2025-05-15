import SwiftUI

struct SileoView: View {
    @ObservedObject var logStore: LogStore
    @State private var sileoInstalled = false
    @State private var sileoPath = ""
    @State private var sileoVersion = ""
    @State private var isProcessing = false
    @State private var statusMessage = "检查Sileo状态..."
    
    @State private var customRepoURL = ""
    @State private var showAddRepoAlert = false
    @State private var showInstallAlert = false
    
    // 预设源列表
    let predefinedRepos = [
        "https://repo.chariz.com": "Chariz源 - 优质插件",
        "https://havoc.app": "Havoc源 - 综合插件",
        "https://repo.twickd.com": "Twickd源 - 主题和插件",
        "https://repo.dynastic.co": "Dynastic源 - 综合仓库"
    ]
    
    var body: some View {
        SileoMainView(
            logStore: logStore,
            sileoInstalled: $sileoInstalled,
            sileoPath: $sileoPath,
            sileoVersion: $sileoVersion,
            isProcessing: $isProcessing,
            statusMessage: $statusMessage,
            customRepoURL: $customRepoURL,
            showAddRepoAlert: $showAddRepoAlert,
            showInstallAlert: $showInstallAlert,
            predefinedRepos: predefinedRepos
        )
    }
}

struct SileoMainView: View {
    @ObservedObject var logStore: LogStore
    @Binding var sileoInstalled: Bool
    @Binding var sileoPath: String
    @Binding var sileoVersion: String
    @Binding var isProcessing: Bool
    @Binding var statusMessage: String
    @Binding var customRepoURL: String
    @Binding var showAddRepoAlert: Bool
    @Binding var showInstallAlert: Bool
    let predefinedRepos: [String: String]
    
    var body: some View {
        VStack(spacing: 20) {
            SileoStatusView(
                sileoInstalled: $sileoInstalled,
                sileoPath: $sileoPath,
                sileoVersion: $sileoVersion,
                isProcessing: $isProcessing,
                statusMessage: $statusMessage,
                showInstallAlert: $showInstallAlert,
                checkSileoStatus: checkSileoStatus,
                installSileo: installSileo,
                launchSileo: launchSileo
            )
            
            if sileoInstalled {
                SileoRepoManagementView(
                    predefinedRepos: predefinedRepos,
                    customRepoURL: $customRepoURL,
                    showAddRepoAlert: $showAddRepoAlert,
                    isProcessing: $isProcessing,
                    addSileoRepo: addSileoRepo
                )
            }
            
            if isProcessing {
                ProgressView()
            }
            
            Text(statusMessage)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            LogView(logStore: logStore)
                .frame(height: 150)
        }
        .padding(.vertical)
        .onAppear {
            checkSileoStatus()
        }
        .navigationTitle("Sileo管理")
    }
    
    private func checkSileoStatus() {
        statusMessage = "检查Sileo状态..."
        isProcessing = true
        
        SileoManager.shared.logStore = logStore
        SileoManager.shared.checkSileoInstallation { installed, path, version in
            self.sileoInstalled = installed
            self.sileoPath = path
            self.sileoVersion = version ?? "未知"
            
            if installed {
                self.statusMessage = "Sileo已安装"
                logStore.append(message: "发现Sileo: \(path)")
                if let version = version {
                    logStore.append(message: "Sileo版本: \(version)")
                }
            } else {
                self.statusMessage = "未安装Sileo"
                logStore.append(message: "未发现Sileo安装")
            }
            
            isProcessing = false
        }
    }
    
    private func installSileo() {
        statusMessage = "正在安装Sileo..."
        isProcessing = true
        
        RootVerifier.shared.verifyRootAccess { hasRoot, _, _ in
            if !hasRoot {
                statusMessage = "安装失败：需要root权限"
                logStore.append(message: "安装Sileo失败：没有root权限")
                isProcessing = false
                return
            }
            
            SileoManager.shared.installSileo { success, message in
                statusMessage = message
                logStore.append(message: "Sileo安装结果: \(message)")
                
                if success {
                    checkSileoStatus()
                } else {
                    isProcessing = false
                }
            }
        }
    }
    
    private func launchSileo() {
        statusMessage = "正在启动Sileo..."
        
        SileoManager.shared.launchSileo { success in
            if success {
                statusMessage = "Sileo已启动"
            } else {
                statusMessage = "无法启动Sileo"
            }
        }
    }
    
    private func addSileoRepo(url: String) {
        guard !url.isEmpty else { return }
        
        statusMessage = "正在添加源..."
        isProcessing = true
        
        SileoManager.shared.addSileoRepo(repoURL: url) { success, message in
            statusMessage = message
            logStore.append(message: "添加源结果: \(message)")
            isProcessing = false
            
            if success {
                customRepoURL = ""
            }
        }
    }
}

struct SileoStatusView: View {
    @Binding var sileoInstalled: Bool
    @Binding var sileoPath: String
    @Binding var sileoVersion: String
    @Binding var isProcessing: Bool
    @Binding var statusMessage: String
    @Binding var showInstallAlert: Bool
    let checkSileoStatus: () -> Void
    let installSileo: () -> Void
    let launchSileo: () -> Void
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: sileoInstalled ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .font(.title2)
                        .foregroundColor(sileoInstalled ? .green : .red)
                    
                    VStack(alignment: .leading) {
                        Text(sileoInstalled ? "Sileo已安装" : "Sileo未安装")
                            .font(.headline)
                        
                        if sileoInstalled && !sileoVersion.isEmpty {
                            Text("版本: \(sileoVersion)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if sileoInstalled && !sileoPath.isEmpty {
                            Text(sileoPath)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        checkSileoStatus()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isProcessing)
                }
                
                HStack(spacing: 15) {
                    if sileoInstalled {
                        Button(action: {
                            launchSileo()
                        }) {
                            Label("启动Sileo", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isProcessing)
                    } else {
                        Button(action: {
                            showInstallAlert = true
                        }) {
                            Label("安装Sileo", systemImage: "square.and.arrow.down.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isProcessing)
                        .alert(isPresented: $showInstallAlert) {
                            Alert(
                                title: Text("安装Sileo"),
                                message: Text("此操作需要root权限。确认要安装Sileo吗？"),
                                primaryButton: .default(Text("安装")) {
                                    installSileo()
                                },
                                secondaryButton: .cancel(Text("取消"))
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct SileoRepoManagementView: View {
    let predefinedRepos: [String: String]
    @Binding var customRepoURL: String
    @Binding var showAddRepoAlert: Bool
    @Binding var isProcessing: Bool
    let addSileoRepo: (String) -> Void
    
    var body: some View {
        GroupBox(label: Text("Sileo源管理").bold()) {
            VStack(alignment: .leading, spacing: 15) {
                Section(header: Text("添加预设源").font(.subheadline)) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(predefinedRepos.keys), id: \.self) { repoURL in
                                Button(action: {
                                    customRepoURL = repoURL
                                    showAddRepoAlert = true
                                }) {
                                    Text(predefinedRepos[repoURL] ?? repoURL)
                                        .lineLimit(1)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(15)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                Section(header: Text("添加自定义源").font(.subheadline)) {
                    HStack {
                        TextField("输入源URL (https://repo.example.com)", text: $customRepoURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            if !customRepoURL.isEmpty {
                                showAddRepoAlert = true
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(customRepoURL.isEmpty || isProcessing)
                    }
                }
                
                Button(action: {
                    let sileoURL = URL(string: "sileo://sources")!
                    UIApplication.shared.open(sileoURL)
                }) {
                    Label("打开Sileo源管理", systemImage: "list.bullet")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
            }
            .padding(10)
        }
        .padding(.horizontal)
        .alert(isPresented: $showAddRepoAlert) {
            Alert(
                title: Text("添加源"),
                message: Text("确认添加以下源到Sileo:\n\(customRepoURL)"),
                primaryButton: .default(Text("添加")) {
                    addSileoRepo(customRepoURL)
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }
}
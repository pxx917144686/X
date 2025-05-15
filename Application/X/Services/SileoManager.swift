import Foundation
import UIKit

// Sileo管理器
class SileoManager {
    static let shared = SileoManager()
    var logStore: LogStore?
    
    // Sileo相关路径
    private let sileoPackagePaths = [
        "/Applications/Sileo.app",
        "/var/jb/Applications/Sileo.app",
        "/var/containers/Bundle/Application/*/Sileo.app",
    ]
    
    // Sileo源URL
    private let defaultRepos = [
        "https://repo.chariz.com": "Chariz源",
        "https://repo.dynastic.co": "Dynastic源",
        "https://havoc.app": "Havoc源",
        "https://repo.twickd.com": "Twickd源",
    ]
    
    private init() {}
    
    private func log(_ message: String) {
        logStore?.append(message: message)
    }
    
    // 检查Sileo安装状态
    func checkSileoInstallation(completion: @escaping (Bool, String, String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 首先检查常规安装位置
            for path in self.sileoPackagePaths {
                if path.contains("*") {
                    // 处理通配符路径
                    let basePath = path.components(separatedBy: "*").first ?? ""
                    if let contents = try? FileManager.default.contentsOfDirectory(atPath: basePath) {
                        for item in contents {
                            let fullPath = "\(basePath)\(item)/Sileo.app"
                            if FileManager.default.fileExists(atPath: fullPath) {
                                self.log("在路径: \(fullPath) 发现Sileo")
                                let version = self.getSileoVersion(path: fullPath)
                                DispatchQueue.main.async {
                                    completion(true, fullPath, version)
                                }
                                return
                            }
                        }
                    }
                } else if FileManager.default.fileExists(atPath: path) {
                    self.log("在标准路径: \(path) 发现Sileo")
                    let version = self.getSileoVersion(path: path)
                    DispatchQueue.main.async {
                        completion(true, path, version)
                    }
                    return
                }
            }
            
            // 检查URL方案
            let canOpenSileoURL = UIApplication.shared.canOpenURL(URL(string: "sileo://")!)
            if canOpenSileoURL {
                self.log("发现Sileo URL方案，应用已安装但路径未知")
                DispatchQueue.main.async {
                    completion(true, "未知路径", nil)
                }
                return
            }
            
            self.log("未发现Sileo安装")
            DispatchQueue.main.async {
                completion(false, "", nil)
            }
        }
    }
    
    // 获取Sileo版本
    private func getSileoVersion(path: String) -> String? {
        let infoPath = "\(path)/Info.plist"
        guard let infoDict = NSDictionary(contentsOfFile: infoPath) else {
            return nil
        }
        
        return infoDict["CFBundleShortVersionString"] as? String
    }
    
    // 安装Sileo
    func installSileo(completion: @escaping (Bool, String) -> Void) {
        log("开始Sileo安装过程...")
        
        // 首先检查是否已安装
        checkSileoInstallation { installed, path, version in
            if installed {
                self.log("Sileo已安装，路径: \(path)")
                completion(true, "Sileo已安装，版本: \(version ?? "未知")")
                return
            }
            
            // 需要root权限才能安装
            RootVerifier.shared.verifyRootAccess { hasRoot, permissions, _ in
                if !hasRoot {
                    self.log("没有root权限，无法安装Sileo")
                    completion(false, "安装失败：没有root权限")
                    return
                }
                
                // 开始安装过程
                self.performSileoInstallation { success, message in
                    completion(success, message)
                }
            }
        }
    }
    
    // 执行Sileo安装
    private func performSileoInstallation(completion: @escaping (Bool, String) -> Void) {
        log("准备Sileo安装文件...")
        
        // 使用dpkg命令安装Sileo (基于公开实现)
        let sileoInstallCommands = [
            // 创建必要目录
            "mkdir -p /var/jb/var/lib/dpkg/",
            "mkdir -p /var/jb/etc/apt/sources.list.d/",
            
            // 安装Sileo的dpkg命令
            "dpkg -i /var/jb/sileo.deb",
            
            // 如果不存在dpkg，可以使用解包并复制
            "tar -xf /var/jb/sileo.tar -C /var/jb/Applications/",
            "chmod -R 755 /var/jb/Applications/Sileo.app",
            
            // 修复权限
            "chown -R mobile:mobile /var/jb/Applications/Sileo.app"
        ]
        
        // 创建一个虚拟的安装环境 - 实际安装需要真实的root权限和文件
        var success = false
        var errorMessage = ""
        
        // 执行命令
        for command in sileoInstallCommands {
            let result = RootVerifier.shared.executeCommand(command)
            if !result.success {
                errorMessage = "执行命令失败: \(command)\n错误: \(result.output)"
                self.log(errorMessage)
                break
            }
            success = true
        }
        
        // 验证安装
        if success {
            checkSileoInstallation { installed, path, version in
                if installed {
                    self.log("Sileo安装成功，路径: \(path)")
                    completion(true, "Sileo安装成功，版本: \(version ?? "未知")")
                } else {
                    self.log("安装命令成功但未检测到Sileo")
                    completion(false, "命令执行成功但未检测到Sileo安装")
                }
            }
        } else {
            completion(false, errorMessage)
        }
    }
    
    // 添加Sileo源
    func addSileoRepo(repoURL: String, completion: @escaping (Bool, String) -> Void) {
        log("尝试添加Sileo源: \(repoURL)")
        
        // 验证URL格式
        guard let _ = URL(string: repoURL) else {
            completion(false, "无效的URL格式")
            return
        }
        
        // 首先检查Sileo是否已安装
        checkSileoInstallation { installed, _, _ in
            if !installed {
                self.log("未安装Sileo，无法添加源")
                completion(false, "未安装Sileo，无法添加源")
                return
            }
            
            // 需要root权限
            RootVerifier.shared.verifyRootAccess { hasRoot, _, _ in
                if !hasRoot {
                    self.log("没有root权限，无法添加源")
                    completion(false, "没有root权限，无法添加源")
                    return
                }
                
                // 添加源到Sileo的源列表
                self.addRepoToSileoSources(repoURL: repoURL) { success, message in
                    completion(success, message)
                }
            }
        }
    }
    
    // 添加源到Sileo的源列表
    private func addRepoToSileoSources(repoURL: String, completion: @escaping (Bool, String) -> Void) {
        // 构造源配置
        let repoName = defaultRepos[repoURL] ?? "自定义源"
        let sourcesListEntry = "deb \(repoURL) ./\n"
        
        // 源列表文件路径
        let sourcesListPaths = [
            "/var/jb/etc/apt/sources.list.d/sileo.sources",
            "/etc/apt/sources.list.d/sileo.sources",
            "/private/etc/apt/sources.list.d/sileo.sources"
        ]
        
        // 尝试添加到源文件
        var success = false
        var sourcePath = ""
        
        for path in sourcesListPaths {
            // 检查源文件是否存在
            if FileManager.default.fileExists(atPath: path) {
                do {
                    // 读取现有内容
                    let existingContent = try String(contentsOfFile: path, encoding: .utf8)
                    
                    // 检查源是否已存在
                    if existingContent.contains(repoURL) {
                        self.log("源已经存在: \(repoURL)")
                        completion(true, "源已存在: \(repoName)")
                        return
                    }
                    
                    // 添加新源
                    let newContent = existingContent + sourcesListEntry
                    try newContent.write(toFile: path, atomically: true, encoding: .utf8)
                    
                    success = true
                    sourcePath = path
                    break
                } catch {
                    self.log("无法修改源文件: \(error.localizedDescription)")
                    continue
                }
            }
        }
        
        if success {
            self.log("成功添加源 \(repoName) 到 \(sourcePath)")
            
            // 刷新Sileo源
            self.refreshSileoSources { refreshSuccess in
                if refreshSuccess {
                    completion(true, "成功添加并刷新源: \(repoName)")
                } else {
                    completion(true, "添加源成功，但刷新失败: \(repoName)")
                }
            }
        } else {
            // 如果找不到现有文件，尝试创建新文件
            if let firstPath = sourcesListPaths.first {
                do {
                    // 确保目录存在
                    let directory = (firstPath as NSString).deletingLastPathComponent
                    try FileManager.default.createDirectory(
                        atPath: directory, 
                        withIntermediateDirectories: true
                    )
                    
                    // 创建源文件
                    try sourcesListEntry.write(toFile: firstPath, atomically: true, encoding: .utf8)
                    
                    self.log("创建了新的源文件: \(firstPath)")
                    
                    // 刷新Sileo源
                    self.refreshSileoSources { refreshSuccess in
                        if refreshSuccess {
                            completion(true, "创建源文件并添加源成功: \(repoName)")
                        } else {
                            completion(true, "创建源文件成功，但刷新失败: \(repoName)")
                        }
                    }
                    
                    return
                } catch {
                    self.log("创建源文件失败: \(error.localizedDescription)")
                }
            }
            
            completion(false, "无法修改或创建源文件")
        }
    }
    
    // 刷新Sileo源
    private func refreshSileoSources(completion: @escaping (Bool) -> Void) {
        self.log("尝试刷新Sileo源...")
        
        // 尝试通过URL Scheme刷新
        if UIApplication.shared.canOpenURL(URL(string: "sileo://sources")!) {
            UIApplication.shared.open(URL(string: "sileo://sources")!) { success in
                if success {
                    self.log("成功打开Sileo源页面")
                    completion(true)
                } else {
                    self.log("无法打开Sileo源页面")
                    completion(false)
                }
            }
            return
        }
        
        // 如果URL Scheme失败，尝试命令行方法
        let refreshCommands = [
            "su mobile -c /Applications/Sileo.app/Sileo sources refresh",
            "su mobile -c /var/jb/Applications/Sileo.app/Sileo sources refresh",
            "apt-get update"
        ]
        
        for command in refreshCommands {
            let result = RootVerifier.shared.executeCommand(command)
            if result.success {
                self.log("成功执行刷新命令: \(command)")
                completion(true)
                return
            }
        }
        
        self.log("所有刷新命令均失败")
        completion(false)
    }
    
    // 启动Sileo
    func launchSileo(completion: @escaping (Bool) -> Void) {
        self.log("尝试启动Sileo...")
        
        // 使用URL Scheme启动
        if UIApplication.shared.canOpenURL(URL(string: "sileo://")!) {
            UIApplication.shared.open(URL(string: "sileo://")!) { success in
                if success {
                    self.log("成功启动Sileo")
                    completion(true)
                } else {
                    self.log("无法通过URL Scheme启动Sileo")
                    completion(false)
                }
            }
            return
        }
        
        // 如果URL Scheme失败，尝试其他方法
        checkSileoInstallation { installed, path, _ in
            if !installed {
                self.log("未安装Sileo，无法启动")
                completion(false)
                return
            }
            
            // 尝试通过命令行启动
            let launchCommands = [
                "open \(path)",
                "su mobile -c 'uiopen sileo://'",
                "su mobile -c 'open \(path)'"
            ]
            
            for command in launchCommands {
                let result = RootVerifier.shared.executeCommand(command)
                if result.success {
                    self.log("成功通过命令启动Sileo: \(command)")
                    completion(true)
                    return
                }
            }
            
            self.log("所有启动方法均失败")
            completion(false)
        }
    }
}
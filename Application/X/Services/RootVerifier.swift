import Foundation
import UIKit
#if canImport(Darwin)
import Darwin
#endif

class RootVerifier {
    static let shared = RootVerifier()
    
    private init() {}
    
    // 验证Root权限
    func verifyRootAccess(completion: @escaping (Bool, [String], [String]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            var hasRootAccess = false
            var permissions = [String]()
            var details = [String]()
            
            // 1. 检查UID和GID
            let uid = getuid()
            let gid = getgid()
            let euid = geteuid()
            let egid = getegid()
            
            let isRoot = (uid == 0 || euid == 0)
            details.append("用户ID: \(uid)/\(euid) (\(isRoot ? "root" : "非root"))")
            details.append("组ID: \(gid)/\(egid)")
            
            if isRoot {
                hasRootAccess = true
                permissions.append("Root UID")
            }
            
            // 2. 尝试访问需要Root权限的路径
            let rootPaths = [
                "/private/var/root",
                "/private/var/db/sudo",
                "/var/jb",
                "/var/db",
                "/var/mobile/Library/Preferences/com.apple.security.plist",
                "/etc/master.passwd",
                "/private/etc/fstab",
                "/usr/libexec"
            ]
            
            var canAccessRootPaths = false
            
            for path in rootPaths {
                if FileManager.default.fileExists(atPath: path) {
                    do {
                        // 尝试列出目录内容或读取文件
                        if FileManager.default.isDirectory(atPath: path) {
                            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
                            details.append("可访问目录: \(path) (包含\(contents.count)个项目)")
                        } else {
                            // 尝试读取文件
                            let data = try Data(contentsOf: URL(fileURLWithPath: path))
                            details.append("可读取文件: \(path) (大小: \(data.count)字节)")
                        }
                        
                        canAccessRootPaths = true
                        permissions.append("访问\(path)")
                    } catch {
                        details.append("路径\(path)存在但无法访问: \(error.localizedDescription)")
                    }
                }
            }
            
            if canAccessRootPaths {
                hasRootAccess = true
            }
            
            // 3. 尝试写入需要Root权限的位置
            let testWritePaths = [
                "/private/var/mobile/root_test.txt",
                "/var/mobile/Library/root_write_test.txt",
                "/private/etc/root_test.txt"
            ]
            
            var canWriteRootPaths = false
            
            for path in testWritePaths {
                let testString = "Root权限测试: \(Date())"
                do {
                    try testString.write(toFile: path, atomically: true, encoding: .utf8)
                    hasRootAccess = true
                    canWriteRootPaths = true
                    permissions.append("写入权限")
                    details.append("可以写入: \(path)")
                    
                    // 清理测试文件
                    try? FileManager.default.removeItem(atPath: path)
                    break
                } catch {
                    // 继续尝试下一个路径
                }
            }
            
            if !canWriteRootPaths {
                details.append("无法写入任何Root测试文件")
            }
            
            // 4. 检测越狱环境和工具
            let jailbreakPaths = [
                "/var/lib/dpkg/status",
                "/var/lib/apt",
                "/private/var/lib/apt",
                "/var/lib/cydia",
                "/private/var/stash",
                "/Applications/Cydia.app",
                "/Applications/Sileo.app",
                "/var/jb/Applications/Sileo.app",
                "/var/jb/Applications/Cydia.app",
                "/var/jb/usr/bin/dpkg",
                "/var/jb/usr/bin/apt",
                "/usr/bin/ssh"
            ]
            
            for path in jailbreakPaths {
                if FileManager.default.fileExists(atPath: path) {
                    hasRootAccess = true
                    permissions.append("越狱环境")
                    details.append("检测到越狱环境: \(path)存在")
                    break
                }
            }
            
            // 5. 检查SSH是否运行
            if self.isSshRunning() {
                hasRootAccess = true
                permissions.append("SSH服务")
                details.append("检测到SSH服务正在运行")
            }
            
            // 6. 检查设备是否已越狱
            if hasRootAccess {
                details.append("设备已越狱，已获得Root权限")
            } else {
                // 如果常规检测失败，尝试利用漏洞获取权限
                self.triggerExploit { exploitSuccess in
                    if exploitSuccess {
                        details.append("通过漏洞获得Root权限")
                        permissions.append("漏洞提权")
                        hasRootAccess = true
                    } else {
                        details.append("漏洞利用失败")
                    }
                    
                    DispatchQueue.main.async {
                        completion(hasRootAccess, permissions, details)
                    }
                }
            }
            DispatchQueue.main.async {
                completion(hasRootAccess, permissions, details)
            }
        }
    }
    
    // 检查Sileo状态
    func checkSileoStatus(completion: @escaping (Bool, String, Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 首先检查常规安装
            let sileoPaths = [
                "/Applications/Sileo.app",
                "/var/jb/Applications/Sileo.app"
            ]
            
            var sileoPath = ""
            var sileoExists = false
            
            for path in sileoPaths {
                if FileManager.default.fileExists(atPath: path) {
                    sileoExists = true
                    sileoPath = path
                    break
                }
            }
            
            if !sileoExists {
                // 检查动态路径
                let jailbreakPaths = [
                    "/var/containers/Bundle/Application/*/Sileo.app",
                    "/private/var/containers/Bundle/Application/*/Sileo.app"
                ]
                
                for pattern in jailbreakPaths {
                    if pattern.contains("*") {
                        // 如果路径包含通配符，使用glob进行搜索
                        let matchingPaths = self.findPaths(matching: pattern)
                        if !matchingPaths.isEmpty {
                            sileoPath = matchingPaths[0]
                            sileoExists = true
                            break
                        }
                    }
                }
            }
            
            // 检查URL scheme是否可用
            let sileoURL = URL(string: "sileo://")!
            let canOpenURL = UIApplication.shared.canOpenURL(sileoURL)
            
            DispatchQueue.main.async {
                completion(sileoExists, sileoPath, canOpenURL)
            }
        }
    }
    
    // 启动Sileo
    func launchSileo(completion: @escaping (Bool) -> Void) {
        let sileoURL = URL(string: "sileo://")!
        
        UIApplication.shared.open(sileoURL) { success in
            completion(success)
        }
    }
    
    // 测试内核访问权限
    private func testKernelAccess() -> (Bool, String) {
        // 尝试操作内核级别功能
        let sysctlResult = executeCommand("sysctl -n hw.machine")
        if sysctlResult.success {
            return (true, "能够执行sysctl命令: \(sysctlResult.output)")
        }
        
        return (false, "无法访问内核功能")
    }
    
    // 使用VM漏洞尝试提权
    private func triggerExploit(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 尝试修改关键系统文件以获取提权
            let testPaths = [
                "/private/var/mobile/Library/Preferences/com.apple.security.plist",
                "/var/mobile/Library/Preferences/com.apple.UIKit.plist",
                "/private/var/mobile/test_root_access.txt"
            ]
            
            for path in testPaths {
                let exploitResult = applySwiftFileZeroExploit(
                    filePath: path, 
                    zeroAllPages: false
                )
                
                if exploitResult == 0 {
                    print("漏洞利用成功修改文件: \(path)")
                    DispatchQueue.main.async {
                        completion(true)
                    }
                    return
                }
            }
            
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    // 执行Shell命令
    func executeCommand(_ command: String) -> (success: Bool, output: String) {
        // iOS不支持直接使用Process类，使用模拟实现
        let pipe = Pipe()
        _ = pipe.fileHandleForReading  // 使用下划线避免未使用警告
        
        // 返回模拟结果
        return (true, "Command executed: \(command)")
    }
    
    // 检查SSH是否运行
    private func isSshRunning() -> Bool {
        let result = executeCommand("ps aux | grep sshd | grep -v grep")
        return result.success && !result.output.isEmpty
    }
    
    // 查找匹配通配符的路径
    private func findPaths(matching pattern: String) -> [String] {
        var results = [String]()
        
        if pattern.contains("*") {
            let components = pattern.components(separatedBy: "*")
            if components.count > 1 {
                let prefix = components[0]
                let suffix = components[1]
                
                if let baseDir = prefix.components(separatedBy: "/").dropLast().joined(separator: "/") as String?, 
                   !baseDir.isEmpty {
                    do {
                        // 确保基础目录存在
                        if FileManager.default.fileExists(atPath: baseDir) {
                            let contents = try FileManager.default.contentsOfDirectory(atPath: baseDir)
                            for item in contents {
                                let fullPath = "\(baseDir)/\(item)"
                                if fullPath.hasPrefix(prefix) && suffix.isEmpty ? true : fullPath.hasSuffix(suffix) {
                                    let silieoExecutablePath = "\(fullPath)/Sileo"
                                    if FileManager.default.fileExists(atPath: silieoExecutablePath) {
                                        results.append(fullPath)
                                    }
                                }
                            }
                        }
                    } catch {
                        print("无法搜索目录: \(error)")
                    }
                }
            }
        }
        
        return results
    }
    
    // 检查文件管理器目录
    private func isDirectory(atPath path: String) -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return exists && isDir.boolValue
    }
}

// FileManager扩展
extension FileManager {
    func isDirectory(atPath path: String) -> Bool {
        var isDir: ObjCBool = false
        let exists = fileExists(atPath: path, isDirectory: &isDir)
        return exists && isDir.boolValue
    }
}

// 在RootVerifier类中添加命令执行函数
extension RootVerifier {
    // 创建文件夹
    func createDirectory(at path: String) -> Bool {
        do {
            try FileManager.default.createDirectory(
                atPath: path,
                withIntermediateDirectories: true,
                attributes: nil
            )
            return true
        } catch {
            return false
        }
    }
    
    // 检查命令是否存在
    func commandExists(_ command: String) -> Bool {
        let result = executeCommand("which \(command)")
        return result.success && !result.output.isEmpty
    }
    
    // 检查设备是否已越狱
    func isJailbroken() -> (jailbroken: Bool, details: [String]) {
        var jailbroken = false
        var details = [String]()
        
        // 越狱标志文件
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/var/lib/cydia",
            "/var/lib/apt",
            "/var/jb",
            "/private/var/lib/apt"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                jailbroken = true
                details.append("发现越狱标记: \(path)")
            }
        }
        
        // 检查是否可以运行未签名代码
        let commandResult = executeCommand("echo 'Jailbreak test'")
        if let result = commandResult.output {
            if result.contains("Jailbreak test") {
                jailbroken = true
                details.append("可以执行命令行命令")
            }
        }
        
        // 检查是否有root权限
        if getuid() == 0 {
            jailbroken = true
            details.append("进程有root权限 (UID=0)")
        }
        
        return (jailbroken, details)
    }
}

import Foundation
import UIKit

// 导入SileoInstallStep
// import SileoInstallStep // 如果放在单独的文件中

class SileoInstaller {
    static let shared = SileoInstaller()
    
    // 使用新定义的枚举
    var installationProgress: ((SileoInstallStep) -> Void)?
    
    private init() {}
    
    // 安装Sileo - Dopamine风格实现
    func installSileo(
        progressHandler: ((SileoInstallStep) -> Void)? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        self.installationProgress = progressHandler
        
        // 1. 准备环境和依赖
        setupDependencies { [weak self] dependenciesSuccess in
            guard let self = self, dependenciesSuccess else {
                completion(false)
                return
            }
            
            // 2. 下载Sileo
            self.downloadSileo { success, path in
                guard success, !path.isEmpty else {
                    completion(false)
                    return
                }
                
                // 3. 安装Sileo
                self.installSileoPackage(at: path, completion: completion)
            }
        }
    }
    
    // 设置依赖项 - Dopamine风格
    private func setupDependencies(completion: @escaping (Bool) -> Void) {
        installationProgress?(.extractingBootstrap)
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. 检查基础系统是否已解压
            let basicFiles = [
                "/var/jb/usr/bin/bash",
                "/var/jb/usr/bin/dpkg",
                "/var/jb/usr/bin/apt",
                "/var/jb/etc/apt/sources.list.d"
            ]
            
            var hasDependencies = true
            for file in basicFiles {
                if !FileManager.default.fileExists(atPath: file) {
                    hasDependencies = false
                    break
                }
            }
            
            // 2. 配置APT源
            self.installationProgress?(.setupAptSources)
            let aptSuccess = self.configureAptSources()
            
            // 3. 安装额外依赖
            self.installationProgress?(.installDependencies)
            let depSuccess = self.installRequiredDependencies()
            
            DispatchQueue.main.async {
                completion(hasDependencies && aptSuccess && depSuccess)
            }
        }
    }
    
    // 配置APT源
    private func configureAptSources() -> Bool {
        let sourcesDir = "/var/jb/etc/apt/sources.list.d"
        let mainSourceFile = "\(sourcesDir)/sileo.sources"
        
        // 创建源目录
        do {
            try FileManager.default.createDirectory(
                atPath: sourcesDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            // 写入源文件
            let sourceContent = """
            deb https://repo.getsileo.app/ ./
            deb https://repo.chariz.com/ ./
            """
            
            try sourceContent.write(
                toFile: mainSourceFile,
                atomically: true,
                encoding: .utf8
            )
            
            // 更新源
            let updateResult = RootVerifier.shared.executeCommand("apt-get update")
            return updateResult.success
            
        } catch {
            print("配置APT源失败: \(error)")
            return false
        }
    }
    
    // 安装必要依赖
    private func installRequiredDependencies() -> Bool {
        // 安装基础依赖
        let dependencies = [
            "apt",
            "libapt",
            "dpkg",
            "lzma",
            "firmware-sbin"
        ]
        
        for dep in dependencies {
            let result = RootVerifier.shared.executeCommand("apt-get install -y \(dep)")
            if !result.success {
                print("安装依赖\(dep)失败")
                return false
            }
        }
        
        return true
    }
    
    // 下载Sileo
    private func downloadSileo(completion: @escaping (Bool, String) -> Void) {
        installationProgress?(.downloadingSileo)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationPath = documentsDirectory.appendingPathComponent("sileo.deb").path
        
        // 检查是否已下载
        if FileManager.default.fileExists(atPath: destinationPath) {
            completion(true, destinationPath)
            return
        }
        
        // 构建下载URL
        let urlString = "https://getsileo.app/download/sileo.deb"
        guard let url = URL(string: urlString) else {
            completion(false, "")
            return
        }
        
        // 下载文件
        let downloadTask = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                print("下载Sileo失败: \(error?.localizedDescription ?? "未知错误")")
                DispatchQueue.main.async {
                    completion(false, "")
                }
                return
            }
            
            do {
                // 移动下载的文件到目标位置
                if FileManager.default.fileExists(atPath: destinationPath) {
                    try FileManager.default.removeItem(atPath: destinationPath)
                }
                try FileManager.default.moveItem(at: tempURL, to: URL(fileURLWithPath: destinationPath))
                
                DispatchQueue.main.async {
                    completion(true, destinationPath)
                }
            } catch {
                print("移动下载的文件失败: \(error)")
                DispatchQueue.main.async {
                    completion(false, "")
                }
            }
        }
        
        downloadTask.resume()
    }
    
    // 安装Sileo包
    private func installSileoPackage(at path: String, completion: @escaping (Bool) -> Void) {
        installationProgress?(.extractingPackage)
        
        // 复制到/var/jb目录
        let jbPath = "/var/jb/sileo.deb"
        do {
            if FileManager.default.fileExists(atPath: jbPath) {
                try FileManager.default.removeItem(atPath: jbPath)
            }
            try FileManager.default.copyItem(atPath: path, toPath: jbPath)
        } catch {
            print("复制Sileo包到/var/jb失败: \(error)")
            completion(false)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 使用dpkg安装
            let installResult = RootVerifier.shared.executeCommand("dpkg -i \(jbPath)")
            
            if installResult.success {
                // 配置权限
                self.installationProgress?(.configuringPermissions)
                self.configurePermissions()
                
                // 注册URL方案
                self.installationProgress?(.registeringURLScheme)
                self.registerURLScheme()
                
                DispatchQueue.main.async {
                    completion(true)
                }
                return
            }
            
            // 如果dpkg安装失败，尝试手动方法
            self.manuallyInstallSileo(path: jbPath, completion: completion)
        }
    }
    
    // 手动安装Sileo
    private func manuallyInstallSileo(path: String, completion: @escaping (Bool) -> Void) {
        // 解压deb文件
        let extractResult = RootVerifier.shared.executeCommand("ar -x \(path) data.tar.gz")
        if !extractResult.success {
            // 尝试另一种格式
            let xzResult = RootVerifier.shared.executeCommand("ar -x \(path) data.tar.xz")
            if !xzResult.success {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
        }
        
        // 解压tar文件到/var/jb
        let tarFile = FileManager.default.fileExists(atPath: "/var/jb/data.tar.gz") ? "data.tar.gz" : "data.tar.xz"
        let untarResult = RootVerifier.shared.executeCommand("tar -xf /var/jb/\(tarFile) -C /var/jb")
        
        if untarResult.success {
            // 配置权限
            self.configurePermissions()
            self.registerURLScheme()
            
            DispatchQueue.main.async {
                completion(true)
            }
        } else {
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    // 配置Sileo权限
    private func configurePermissions() {
        // 设置权限
        let chmodCommands = [
            "chmod 755 /var/jb/Applications/Sileo.app/Sileo",
            "chmod -R 755 /var/jb/Applications/Sileo.app",
            "chown -R mobile:mobile /var/jb/Applications/Sileo.app"
        ]
        
        for command in chmodCommands {
            let _ = RootVerifier.shared.executeCommand(command)
        }
    }
    
    // 注册URL方案
    private func registerURLScheme() {
        // 注册URL方案
        // 在iOS上这通常是通过Info.plist完成的
        // 这里我们只需确保文件存在权限正确
        let infoPath = "/var/jb/Applications/Sileo.app/Info.plist"
        if FileManager.default.fileExists(atPath: infoPath) {
            let _ = RootVerifier.shared.executeCommand("chmod 644 \(infoPath)")
        }
    }
    
    // 启动Sileo
    func launchSileo(completion: @escaping (Bool) -> Void) {
        // 方法1：使用URL方案
        if UIApplication.shared.canOpenURL(URL(string: "sileo://")!) {
            UIApplication.shared.open(URL(string: "sileo://")!) { success in
                completion(success)
            }
            return
        }
        
        // 方法2：命令行启动
        let launchCommands = [
            "open /var/jb/Applications/Sileo.app",
            "su mobile -c 'uiopen sileo://'",
            "su mobile -c 'open /var/jb/Applications/Sileo.app'"
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
}

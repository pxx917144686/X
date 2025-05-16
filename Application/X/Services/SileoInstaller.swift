import Foundation
import UIKit

// 确保导入SileoInstallStep模型
// import SileoInstallStep // 如果放在单独的模块中需要导入

class SileoInstaller {
    var installationProgress: ((SileoInstallStep) -> Void)?
    
    func installSileo(
        progressHandler: ((SileoInstallStep) -> Void)? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        self.installationProgress = progressHandler
        
        // 修复各种枚举引用
        installationProgress?(.extractingBootstrap)
        
        // 下面是其他代码...
        
        self.installationProgress?(.setupAptSources)
        
        // 下面是其他代码...
        
        installationProgress?(.downloadingSileo)
        
        // 下面是其他代码...
        
        installationProgress?(.extractingPackage)
        
        // 下面是其他代码...
        
        self.installationProgress?(.configuringPermissions)
        
        // 重启SpringBoard确保图标显示
        DispatchQueue.global(qos: .userInitiated).async {
            let sbResult = system("killall -9 SpringBoard")
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    // 验证Sileo是否真正安装成功
    private func verifySileoInstallation() -> Bool {
        let siloePaths = [
            "/var/jb/Applications/Sileo.app/Sileo", 
            "/Applications/Sileo.app/Sileo"
        ]
        
        for path in siloePaths {
            if FileManager.default.fileExists(atPath: path) {
                let result = RootVerifier.shared.executeCommand("ls -la \(path)")
                return true
            }
        }
        return false
    }
    
}

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
            _ = executeCommand("/usr/bin/killall", withArguments: ["-9", "SpringBoard"])
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    func launchSileo(completion: @escaping (Bool) -> Void) {
        if let url = URL(string: "sileo://") {
            UIApplication.shared.open(url) { success in
                if success {
                    completion(true)
                    return
                }
                
                // 如果URL Scheme失败，尝试直接启动
                DispatchQueue.global(qos: .userInitiated).async {
                    // 尝试多种方法重启SpringBoard，确保图标显示
                    _ = self.executeCommand("/usr/bin/killall", withArguments: ["-9", "SpringBoard"])
                    
                    // 等待一段时间确保SpringBoard重启
                    Thread.sleep(forTimeInterval: 2.0)
                    
                    DispatchQueue.main.async {
                        completion(true)
                    }
                }
            }
        } else {
            completion(false)
        }
    }
    
    private func executeCommand(_ command: String, withArguments arguments: [String]) -> Int32 {
        var pid: pid_t = 0
        var fileActions: posix_spawn_file_actions_t?
        
        posix_spawn_file_actions_init(&fileActions)
        
        let argv: [UnsafeMutablePointer<CChar>?] = [strdup(command)] + arguments.map { strdup($0) } + [nil]
        
        let status = posix_spawn(&pid, command, &fileActions, nil, argv, nil)
        
        // 释放内存
        for arg in argv where arg != nil {
            free(arg)
        }
        
        posix_spawn_file_actions_destroy(&fileActions)
        
        if status == 0 {
            // 等待进程完成
            var exitStatus: Int32 = 0
            waitpid(pid, &exitStatus, 0)
            return exitStatus
        } else {
            return -1
        }
    }
}

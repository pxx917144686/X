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
#import "exploit_poc.h"
#import "BootstrapExtractor.h"

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
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/tar"];
    [task setArguments:@[@"-xf", bootstrapPath, @"-C", jbPath]];
    [task launch];
    [task waitUntilExit];
    
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
    system("chmod 755 /var/jb/usr/bin/*");
    system("chmod 755 /var/jb/bin/*");
    system("chmod 755 /var/jb/basebin/*");
    
    NSLog(@"[+] 基础系统解压完成");
    return true;
}

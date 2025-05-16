#import <Foundation/Foundation.h>
#include <sys/mount.h>

// 重新挂载根文件系统为可读写
bool remount_rootfs_as_rw(void) {
    NSLog(@"[*] 尝试将根文件系统重新挂载为可读写");
    
    // 使用 mount 系统调用重新挂载根文件系统
    int result = mount("apfs", "/", MNT_UPDATE | MNT_RELOAD, NULL);
    if (result != 0) {
        NSLog(@"[-] 重新挂载失败: %d (%s)", errno, strerror(errno));
        return false;
    }
    
    // 验证文件系统是否可写
    NSString *testPath = @"/test_write_access";
    NSError *error = nil;
    
    [@"test" writeToFile:testPath atomically:YES 
                encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"[-] 文件系统写入测试失败: %@", error);
        return false;
    }
    
    // 清理测试文件
    [[NSFileManager defaultManager] removeItemAtPath:testPath error:nil];
    
    NSLog(@"[+] 成功将根文件系统重新挂载为可读写");
    return true;
}

// 为 Swift 提供 C 函数接口
bool remount_rootfs_as_rw_wrapper(void) {
    return remount_rootfs_as_rw();
}

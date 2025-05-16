#ifndef FilesystemUtils_h
#define FilesystemUtils_h

#import <Foundation/Foundation.h>

// 重新挂载根文件系统为可读写
bool remount_rootfs_as_rw(void);

// Swift 包装函数
bool remount_rootfs_as_rw_wrapper(void);

#endif /* FilesystemUtils_h */

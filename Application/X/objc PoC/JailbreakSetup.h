#ifndef JailbreakSetup_h
#define JailbreakSetup_h

#import <Foundation/Foundation.h>

// 完整越狱函数
bool jailbreak_device(void);

// 设置持久化越狱环境
bool setup_persistent_jailbreak(void);

// 安装越狱组件
bool install_jailbreak_components(void);

// 修补系统
bool patch_system_files(void);

// 挂载分区为可写
bool remount_rootfs(void);

#endif /* JailbreakSetup_h */

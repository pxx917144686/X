#ifndef BootstrapExtractor_h
#define BootstrapExtractor_h

#import <Foundation/Foundation.h>

// 声明需要在Swift中调用的函数
bool extract_bootstrap_to_jb(void);
bool exploit_iokit_cve_2023_42824(void);
bool trigger_kernel_exploit(void);

#endif /* BootstrapExtractor_h */

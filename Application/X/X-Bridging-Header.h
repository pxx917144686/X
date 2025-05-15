//
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

#ifndef X_Bridging_Header_h
#define X_Bridging_Header_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach/mach.h>

// 核心漏洞函数
bool extract_bootstrap_to_jb(void);
bool exploit_iokit_cve_2023_42824(void);
bool trigger_kernel_exploit(void);
bool exploit_method_ion_port_race(void);
bool exploit_method_macho_parser(void);
bool exploit_method_type_confusion(void);
bool bypass_ppl_via_pac(void);
bool bypass_kpp_protection(void);
bool bypass_ppl_via_hardware_method(void);
bool remount_rootfs_as_rw(void);
bool connect_xpc_service(const char* serviceName);

// VM相关常量和函数
#define VM_BEHAVIOR_ZERO_WIRED 7
extern vm_size_t vm_page_size;

// 文件操作权限相关
#define PROT_READ  0x01
#define PROT_WRITE 0x02
#define MAP_SHARED 0x0001
#define O_RDWR     0x0002
#define MS_SYNC    0x0010

#endif /* X_Bridging_Header_h */

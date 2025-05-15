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
#import <mach/vm_map.h>

// 用于越狱操作的声明
extern vm_size_t vm_page_size;
extern mach_port_t mach_task_self_;

// VM相关常量
#define VM_BEHAVIOR_DEFAULT 0
#define VM_BEHAVIOR_ZERO_WIRED 7

// 声明mach_vm_behavior_set函数
kern_return_t mach_vm_behavior_set(
    mach_port_t target_task,
    mach_vm_address_t address,
    mach_vm_size_t size,
    vm_behavior_t new_behavior
);

// 声明ObjC函数实现
bool extract_bootstrap_to_jb(void);
bool trigger_kernel_exploit(void);
bool remount_rootfs_as_rw(void);
bool connect_xpc_service(const char* serviceName);
bool bypass_ppl_via_pac(void);
bool bypass_kpp_protection(void);
bool bypass_ppl_via_hardware_method(void);
bool exploit_iokit_cve_2023_42824(void);

// 声明文件操作相关常量
#define PROT_READ  0x01
#define PROT_WRITE 0x02
#define MAP_SHARED 0x0001
#define O_RDWR     0x0002
#define MS_SYNC    0x0010

#endif /* X_Bridging_Header_h */

//
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

#ifndef X_Bridging_Header_h
#define X_Bridging_Header_h

#import <Foundation/Foundation.h>
#include "exploit_poc.h"
#import "RespringHelper.h"
#import "objc PoC/BootstrapExtractor.h"

// 漏洞利用链接口
bool trigger_kernel_exploit(void);
bool escalate_to_root(void);
bool bypass_ppl_via_pac(void);
bool bypass_kpp_protection(void);
bool bypass_ppl_via_hardware_method(void);
bool remount_rootfs_as_rw(void);
bool extract_bootstrap_to_jb(void);
bool connect_xpc_service(const char* serviceName);
bool kernel_elevate_file_permissions(const char* path);
bool bypass_code_signing(void);

// 其他新增函数
bool exploit_iokit_cve_2023_42824(void);
bool exploit_iomfb_memory_leak(void);
bool exploit_iosurface_memory_corruption(void);
bool exploit_avevideo_encoder(void);
bool exploit_blastdoor_escape(void);
bool exploit_coreml_type_confusion(void);
bool exploit_memorystatus_control(void);
bool exploit_webcontent_ipc(void);

#endif

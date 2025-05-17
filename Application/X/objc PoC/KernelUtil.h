#ifndef KernelUtil_h
#define KernelUtil_h

#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import "KernelExploitBase.h"

// 内核特殊地址查找
uint64_t find_kernel_base_address(void);
uint64_t find_kernel_task(void);
uint64_t find_kernel_proc(void);
uint64_t find_amfi_trust_cache(void);
uint64_t find_kernel_pmap(void);
uint64_t find_amfi_validate_func(void);
uint64_t find_code_signature_validation_func(void);
uint64_t find_sip_config_addr(void);
uint64_t find_amfi_flags_addr(void);
uint64_t get_rootfs_vnode_mount(void);

// 内核功能封装
bool disable_system_integrity_protection(void);
bool disable_amfi(void);
bool disable_sandbox(void);
bool disable_pac_checks(uint64_t kernel_trust);

// 内核内存工具
uint64_t kernel_allocate(size_t size);
bool kernel_free(uint64_t kaddr, size_t size);
bool is_kernel_memory_readable(uint64_t kaddr);
bool is_kernel_memory_writeable(uint64_t kaddr);
bool flush_kernel_memory_cache(uint64_t kaddr, size_t size);

// 进程和权限管理
bool set_process_as_platform(uint64_t proc);
bool create_root_shell(void);
bool execute_as_root(const char *path);
bool add_to_trustcache_temporarily(const char* path);

// 内核调用和ROP链
uint64_t create_kernel_rop_chain(uint64_t *gadgets, size_t gadget_count);
bool execute_kernel_rop_chain(uint64_t chain_addr);
uint64_t setup_kcall_primitives(void);
uint64_t kcall(uint64_t port, uint64_t func, uint64_t arg1, uint64_t arg2, uint64_t arg3, uint64_t arg4, uint64_t arg5, uint64_t arg6);

// 端口和地址转换
uint64_t find_port_address(mach_port_t port);
mach_port_t port_for_kernel_task(void);
bool setup_tfp0_primitive(void);
bool setup_persistent_kernel_access(void);

// 文件系统操作
bool kernel_remount_rootfs_as_rw(void);
bool modify_boot_partition(void);

// 内存管理工具
int memorystatus_control(uint32_t command, int32_t pid, uint32_t flags, void *buffer, size_t buffersize);

#endif /* KernelUtil_h */

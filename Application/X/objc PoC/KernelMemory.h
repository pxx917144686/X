// KernelMemory.h
#ifndef KernelMemory_h
#define KernelMemory_h

#import <Foundation/Foundation.h>
#import "KernelExploitBase.h"

// 内核内存读写函数
bool kernel_read(uint64_t kaddr, void* uaddr, size_t size);
bool kernel_write(uint64_t kaddr, const void* uaddr, size_t size);

// 基础读写原语
bool read_kernel_byte(uint64_t kaddr, uint8_t* uaddr);
bool write_kernel_byte(uint64_t kaddr, uint8_t value);

// 不同方法的内核读写
bool iosurface_kernel_read(uint64_t kaddr, void* uaddr, size_t size);
bool iosurface_kernel_write(uint64_t kaddr, const void* uaddr, size_t size);
bool physical_kernel_read(uint64_t kaddr, void* uaddr, size_t size);
bool physical_kernel_write(uint64_t kaddr, const void* uaddr, size_t size);

// 设置内核读写原语
bool setup_kernel_rw_primitive(void);

#endif /* KernelMemory_h */

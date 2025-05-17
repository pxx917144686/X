// HeapSpray.h
#ifndef HeapSpray_h
#define HeapSpray_h

#import <Foundation/Foundation.h>

// 基本堆喷射
bool heap_spray(size_t size, size_t count, uint64_t pattern);

// 目标结构堆喷射
bool heap_spray_target_structures(size_t target_size, size_t count);

// 使用不同方式的堆喷射
bool spray_iosurface_objects(size_t size, size_t count);
bool spray_mach_messages(size_t size, size_t count);

#endif /* HeapSpray_h */

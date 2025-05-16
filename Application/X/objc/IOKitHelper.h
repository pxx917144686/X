#ifndef IOKitHelper_h
#define IOKitHelper_h

#include <mach/mach.h>
#include <Foundation/Foundation.h>

// IOKit 类型定义
typedef mach_port_t io_object_t;
typedef io_object_t io_connect_t;
typedef io_object_t io_service_t;
typedef io_object_t io_iterator_t;
typedef io_object_t io_registry_entry_t;

// 函数声明
bool IOKitHelperInit(void);
mach_port_t IOKitGetMasterPort(void);
io_service_t IOServiceGetMatchingService(mach_port_t masterPort, CFDictionaryRef matching);
CFMutableDictionaryRef IOServiceMatching(const char *name);
kern_return_t IOServiceOpen(io_service_t service, task_port_t owningTask, uint32_t type, io_connect_t *connect);
kern_return_t IOServiceClose(io_connect_t connect);
kern_return_t IOObjectRelease(io_object_t object);
kern_return_t IOConnectCallMethod(
    io_connect_t connection,
    uint32_t selector,
    const uint64_t *input,
    uint32_t inputCnt,
    const void *inputStruct,
    size_t inputStructCnt,
    uint64_t *output,
    uint32_t *outputCnt,
    void *outputStruct,
    size_t *outputStructCntP);

#endif /* IOKitHelper_h */

#include "IOKitHelper.h"
#include <dlfcn.h>

// 函数指针
static mach_port_t (*_IOKitGetMasterPort)(void) = NULL;
static io_service_t (*_IOServiceGetMatchingService)(mach_port_t, CFDictionaryRef) = NULL;
static CFMutableDictionaryRef (*_IOServiceMatching)(const char *) = NULL;
static kern_return_t (*_IOServiceOpen)(io_service_t, task_port_t, uint32_t, io_connect_t *) = NULL;
static kern_return_t (*_IOServiceClose)(io_connect_t) = NULL;
static kern_return_t (*_IOObjectRelease)(io_object_t) = NULL;
static kern_return_t (*_IOConnectCallMethod)(io_connect_t, uint32_t, const uint64_t *, uint32_t, 
    const void *, size_t, uint64_t *, uint32_t *, void *, size_t *) = NULL;

// IOKit 符号初始化
bool IOKitHelperInit(void) {
    static bool initialized = false;
    if (initialized) return true;
    
    void *handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
    if (!handle) {
        NSLog(@"[-] 无法加载 IOKit 框架: %s", dlerror());
        return false;
    }
    
    // 加载 IOKit 函数
    _IOServiceGetMatchingService = dlsym(handle, "IOServiceGetMatchingService");
    _IOServiceMatching = dlsym(handle, "IOServiceMatching");
    _IOServiceOpen = dlsym(handle, "IOServiceOpen");
    _IOServiceClose = dlsym(handle, "IOServiceClose");
    _IOObjectRelease = dlsym(handle, "IOObjectRelease");
    _IOConnectCallMethod = dlsym(handle, "IOConnectCallMethod");
    
    // 检查必要的函数是否已加载
    if (!_IOServiceGetMatchingService || !_IOServiceMatching || 
        !_IOServiceOpen || !_IOServiceClose || 
        !_IOObjectRelease || !_IOConnectCallMethod) {
        NSLog(@"[-] 无法加载部分 IOKit 函数");
        return false;
    }
    
    initialized = true;
    return true;
}

// 获取 IOKit 主端口
mach_port_t IOKitGetMasterPort(void) {
    // iOS 中使用 MACH_PORT_NULL 代替主端口
    return MACH_PORT_NULL;
}

// IOKit 函数包装器
io_service_t IOServiceGetMatchingService(mach_port_t masterPort, CFDictionaryRef matching) {
    if (!IOKitHelperInit() || !_IOServiceGetMatchingService) return 0;
    return _IOServiceGetMatchingService(masterPort, matching);
}

CFMutableDictionaryRef IOServiceMatching(const char *name) {
    if (!IOKitHelperInit() || !_IOServiceMatching) return NULL;
    return _IOServiceMatching(name);
}

kern_return_t IOServiceOpen(io_service_t service, task_port_t owningTask, uint32_t type, io_connect_t *connect) {
    if (!IOKitHelperInit() || !_IOServiceOpen) return KERN_FAILURE;
    return _IOServiceOpen(service, owningTask, type, connect);
}

kern_return_t IOServiceClose(io_connect_t connect) {
    if (!IOKitHelperInit() || !_IOServiceClose) return KERN_FAILURE;
    return _IOServiceClose(connect);
}

kern_return_t IOObjectRelease(io_object_t object) {
    if (!IOKitHelperInit() || !_IOObjectRelease) return KERN_FAILURE;
    return _IOObjectRelease(object);
}

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
    size_t *outputStructCntP) {
    if (!IOKitHelperInit() || !_IOConnectCallMethod) return KERN_FAILURE;
    return _IOConnectCallMethod(connection, selector, input, inputCnt, 
                              inputStruct, inputStructCnt, 
                              output, outputCnt, 
                              outputStruct, outputStructCntP);
}

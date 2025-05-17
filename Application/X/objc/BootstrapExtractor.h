#ifndef BootstrapExtractor_h
#define BootstrapExtractor_h

#import <Foundation/Foundation.h>

@interface BootstrapExtractor : NSObject

+ (BOOL)extractBootstrap:(NSString *)bootstrapPath toJBPath:(NSString *)jbPath;
+ (BOOL)setPermissionsForDirectory:(NSString *)dirPath mode:(int)mode;
+ (BOOL)kernelHack;

@end

// C函数
bool extract_bootstrap_to_jb(void);
bool trigger_kernel_exploit(void);

#endif /* BootstrapExtractor_h */

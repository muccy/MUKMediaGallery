#import "MUKMediaGalleryUtils.h"

static NSString *const kResourcesBundleName = @"MUKMediaGalleryResources";

@implementation MUKMediaGalleryUtils

+ (NSBundle *)resourcesBundle {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *url = [[NSBundle mainBundle] URLForResource:kResourcesBundleName withExtension:@"bundle"];
        bundle = [NSBundle bundleWithURL:url];
    });
    
    return bundle;
}

+ (UIImage *)imageNamed:(NSString *)name {
    return [UIImage imageNamed:[kResourcesBundleName stringByAppendingFormat:@".bundle/%@", name]];
}

@end

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MUKMediaGalleryUIParadigm) {
    MUKMediaGalleryUIParadigmLayered = 0,
    MUKMediaGalleryUIParadigmGlossy
};

@interface MUKMediaGalleryUtils : NSObject

+ (NSBundle *)resourcesBundle;
+ (UIImage *)imageNamed:(NSString *)name;

+ (MUKMediaGalleryUIParadigm)defaultUIParadigm;

@end
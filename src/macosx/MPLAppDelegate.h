#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPLAppDelegate : NSObject <NSApplicationDelegate>

- (instancetype) initWithImageDictionary: (NSDictionary *) imageDictionary;

@property (nonatomic, readonly) NSDictionary *imageDictionary;

@end

NS_ASSUME_NONNULL_END

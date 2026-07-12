#import <AppKit/AppKit.h>
#import <Python.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPLTimer : NSObject

- (void) start;
- (void) stop;

- (void) updateIntervalInMsecs:(int)intervalInMsecs;
- (void) updateSingleShot:(BOOL)singleShot;

@property (atomic, assign, nullable) PyObject *pyObject;

@end

NS_ASSUME_NONNULL_END

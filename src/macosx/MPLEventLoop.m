#import "MPLEventLoop.h"
#import "MPLFigureManager.h"
#import "MPLUtils.h"


@implementation MPLEventLoop {
    // Keeps track of all active loops (both -spin... and -run...)
    // Needed so we can post enough events to cancel all loops
    NSInteger _loopCount;

    // Each -spin... loop checks this to see if it should stop.
    // We can't use -[NSApplication isRunning] as spin loops can be used
    // while not in a running state (flush_events())
    BOOL _shouldStop;

    // Makes sure that [NSApp run] was called at least once for proper initialization
    BOOL _wasRunCalledAtLeastOnce;

    // Internal state for dealing with -runUntilNoFigureManagers
    BOOL (^_stopCondition)(void);
}


#pragma mark - Lifecycle

+ (instancetype) sharedInstance
{
    static MPLEventLoop *sharedInstance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MPLEventLoop alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype) init
{
    if ((self = [super init])) {
        _wasRunCalledAtLeastOnce = [NSApp isRunning];
    }
    
    return self;
}


#pragma mark - Private Methods

- (void) _postInternalEvent
{
    // There exists a very small possibility that we are running as a framework
    // inside of another app which is using NSEventTypeApplicationDefined events.
    // Hence, set subtype to a value unlikely to conflict.
    NSEvent *event = [NSEvent otherEventWithType: NSEventTypeApplicationDefined
                                        location: NSZeroPoint
                                   modifierFlags: 0
                                       timestamp: 0
                                    windowNumber: 0
                                         context: nil
                                         subtype: INT16_MAX
                                           data1: 0
                                           data2: 0];

    // +[NSEvent otherEventWithType:...] is declared nullable but will not return
    // nil for these constant, valid arguments; guard defensively anyway.
    if (event) {
        [NSApp postEvent: event atStart: YES];
    }
}

- (void) _ensureRunWasCalledAtLeastOnce
{
    if (!_wasRunCalledAtLeastOnce) {
        dispatch_async(dispatch_get_main_queue(), ^{ [NSApp stop:self]; });
        [NSApp run];
        _wasRunCalledAtLeastOnce = YES;
    }
}


#pragma mark - Public Methods

- (void) spinUntilStandardInputActivity
{
    [self _ensureRunWasCalledAtLeastOnce];

    __block int inputDidOccur = 0;
    __weak id weakSelf = self;

    dispatch_source_t source = dispatch_source_create(
        DISPATCH_SOURCE_TYPE_READ, STDIN_FILENO, 0,
        dispatch_get_main_queue()
    );

    dispatch_source_set_event_handler(source, ^{
        inputDidOccur = 1;
        dispatch_source_cancel(source);
        [weakSelf _postInternalEvent];
    });

    dispatch_resume(source);

    _loopCount++;

    while (!inputDidOccur) {
        @autoreleasepool {
            NSEvent *event = [NSApp nextEventMatchingMask: NSEventMaskAny
                                                untilDate: [NSDate distantFuture]
                                                   inMode: NSDefaultRunLoopMode
                                                  dequeue: YES];

            [NSApp sendEvent:event];
        }
    }

    _loopCount--;
    if (_loopCount == 0) _shouldStop = NO;
}

- (void) spinUntilNoEvents
{
    [self _ensureRunWasCalledAtLeastOnce];

    _loopCount++;

    while (!_shouldStop) {
        @autoreleasepool {
            NSEvent *event = [NSApp nextEventMatchingMask: NSEventMaskAny
                                                untilDate: [NSDate distantPast]
                                                   inMode: NSDefaultRunLoopMode
                                                  dequeue: YES];

            if (!event) break;

            [NSApp sendEvent:event];
        }
    }

    _loopCount--;
    if (_loopCount == 0) _shouldStop = NO;
}

- (void) runUntilTimeout:(double)timeout
{
    if ([NSApp isRunning]) {
        PyErr_SetString(PyExc_RuntimeError, "An event loop is already running");
        return;
    }
    
    _loopCount++;

    if (timeout > 0.0) {
        [self performSelector:@selector(stop) withObject:nil afterDelay:timeout];
    }

    _wasRunCalledAtLeastOnce = YES;
    [NSApp run];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stop) object:nil];
    
    _loopCount--;
    if (!_loopCount) _shouldStop = NO;
}

- (void) runUntilStopCondition:(BOOL (^)(void))stopCondition
{
    if ([NSApp isRunning]) {
        PyErr_SetString(PyExc_RuntimeError, "An event loop is already running");
        return;
    }

    _loopCount++;

    _stopCondition = stopCondition;
    _wasRunCalledAtLeastOnce = YES;
    [NSApp run];
    _stopCondition = nil;

    _loopCount--;
    if (!_loopCount) _shouldStop = NO;
}

- (void) checkStopCondition
{
    if (_stopCondition && _stopCondition()) {
        [self stop];
    }
}

- (void) stop
{
    _shouldStop = YES;
    
    [NSApp stop:self];
    
    // Post X events, where X is the number of active loops
    for (NSInteger i = 0; i < _loopCount; i++) {
        [self _postInternalEvent];
    }
}


@end


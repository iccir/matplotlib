/*
    MPLTimer Thread-safety Notes

    Historically, the macOS backend utilitized a single-shot timer as a mechanism
    to forward draw_idle() requests to the main thread (#25553/#27527). This had
    the side-effect of allowing external clients to use the timer API to do the same.
    
    This class has been written to be thread safe in order to err on the side
    of caution. This may change in the future as the discussion of worker-thread
    usage is ongoing (#31968).
    
    To implement thread-safety, we do the following:
    
    1) Properties and ivars (except _storage) are only modified on the main thread.

    2) We store our PyObject inside a special MPLTimerStorage class that also
       acts as a mutex via the @synchronized directive.

       This storage object is strongly-retained by a block copy and automatically
       released at the end of the block dispatch. Hence, it's impossible for the
       MPLTimerStorage instance to be dealloc'd during the timer callback.

    3) When calling the "on_timer" callback:
       - Acquire the GIL.
       - Acquire the _storage mutex.
       - Extract the pyObject and increment the reference count.
       - Release the _storage mutex.
       - Call "_on_timer" on the pyObject.
       - Decrement the pyObject reference count.
       - Release the GIL.
*/

#import "MPLTimer.h"
#import "MPLUtils.h"


@interface MPLTimerStorage : NSObject
@property (nonatomic, assign, nullable) PyObject *pyObject;
@end

@implementation MPLTimerStorage
@end

@interface MPLTimer ()
@property (nonatomic, getter=isSingleShot) BOOL singleShot;
@end

@implementation MPLTimer {
    dispatch_source_t _source;
    uint64_t _intervalInNsecs;
    MPLTimerStorage *_storage;
}

#pragma mark - Lifecycle

- (instancetype) init
{
    if ((self = [super init])) {
        MPLLog("[Lifecycle] MPLTimer<%p> init", self);
        _storage = [[MPLTimerStorage alloc] init];
    }

    return self;
}

- (void) dealloc
{
    @synchronized (_storage) {
        [_storage setPyObject:NULL];
    }

    // We always call -stop prior to dealloc, which will clear and cancel
    // our _source. As a failsafe, the source's callback will cancel itself
    // if it sees a NULL pyObject.

    MPLLog("[Lifecycle] MPLTimer<%p> dealloc", self);
}


#pragma mark - Private Methods

- (void) _clearSource
{
    _source = nil;
}

- (void) _cancelAndClearSource
{
    dispatch_source_t source = _source;
    _source = nil;
    if (source) dispatch_source_cancel(source);
}

- (void) _restartTimer
{
    dispatch_source_t source = dispatch_source_create(
        DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue()
    );

    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, _intervalInNsecs);
    dispatch_source_set_timer(source, start, _intervalInNsecs, 0);

    __weak MPLTimer *weakSelf = self;
    __weak dispatch_source_t weakSource = source;

    // 'storage' will be strongly retained by the block and also act as our mutex.
    MPLTimerStorage *storage = _storage;
    dispatch_source_set_event_handler(source, ^{
        PyGILState_STATE gstate = PyGILState_Ensure();

        PyObject *pyObject = NULL;

        @synchronized (storage) {
            pyObject = [storage pyObject];
            Py_XINCREF(pyObject);
        }

        if (pyObject) {
            MPLCallMethod(pyObject, "_on_timer", "");
            Py_DECREF(pyObject);
        }
        
        __strong MPLTimer *strongSelf = weakSelf;
        if ([strongSelf isSingleShot]) {
            [strongSelf _cancelAndClearSource];

        // If this callback has fired after -[MPLTimer dealloc],
        // be absolutely certain that the source has been cancelled.
        // This should be not needed, but it's better to err on the
        // side of caution
        } else if (!pyObject || !strongSelf) {
            dispatch_source_cancel(weakSource);
        }

        PyGILState_Release(gstate);
    });

    dispatch_source_set_cancel_handler(source, ^{
        [weakSelf _clearSource];
    });

    [self _cancelAndClearSource];
    _source = source;
    dispatch_activate(source);
}


#pragma mark - Public Methods

- (void) start
{
    if ([NSThread isMainThread]) {
        [self _restartTimer];

    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self start];
        });
    }
}

- (void) stop
{
    if ([NSThread isMainThread]) {
        [self _cancelAndClearSource];

    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stop];
        });
    }
}

- (void) updateIntervalInMsecs:(int)intervalInMsecs
{
    if ([NSThread isMainThread]) {
        _intervalInNsecs = intervalInMsecs * NSEC_PER_MSEC;
        if (_source) [self _restartTimer];

    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateIntervalInMsecs:intervalInMsecs];
        });
    }
}

- (void) updateSingleShot:(BOOL)singleShot
{
    if ([NSThread isMainThread]) {
        [self setSingleShot:singleShot];

    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateSingleShot:singleShot];
        });
    }
}


#pragma mark - Accessors

- (void) setPyObject:(PyObject *)pyObject
{
    @synchronized (_storage) {
        [_storage setPyObject:pyObject];
    }
}

- (PyObject *) pyObject
{
    @synchronized (_storage) {
        return [_storage pyObject];
    }
}


@end

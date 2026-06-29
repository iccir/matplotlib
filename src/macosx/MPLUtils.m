#import "MPLUtils.h"


void _MPLUnavailable(const char *s)
{
    [NSException raise: NSInvalidArgumentException
                format: @"'%s' called but marked with __attribute__((unavailable))", s];

    __builtin_unreachable();
}


#pragma mark - Python Utility Functions

void MPLCallMethod(PyObject *pyObject, const char *name, char const *format, ...)
{
    PyGILState_STATE gilState = PyGILState_Ensure();

    PyObject *result = NULL;

    // Null or empty string, simply use PyObject_CallMethod()
    if (!format || !format[0]) {
        result = PyObject_CallMethod(pyObject, name, NULL);

    } else {
        va_list va;
        va_start(va, format);

        PyObject *args = Py_VaBuildValue(format, va);
        PyObject *method = PyObject_GetAttrString(pyObject, name);

        // "Py_BuildValue() does not always build a tuple."
        if (args && !PyTuple_Check(args)) {
            PyObject *tuple = PyTuple_Pack(1, args);
            Py_DECREF(args);
            args = tuple;
        }

        if (method && args) {
            result = PyObject_Call(method, args, NULL);
        }

        Py_XDECREF(method);
        Py_XDECREF(args);

        va_end(va);
    }

    if (result) {
        Py_DECREF(result);
    } else {
        PyErr_Print();
    }

    PyGILState_Release(gilState);
}


NSString *MPLGetStringWithPyString(PyObject *pyString)
{
    if (!pyString || !PyUnicode_Check(pyString)) return nil;

    const char *cString = PyUnicode_AsUTF8(pyString);
    if (!cString) return nil;

    return [NSString stringWithUTF8String:cString];
}


extern NSArray<NSString *> *MPLGetStringArrayWithPySequence(PyObject *pySequence)
{
    if (!PySequence_Check(pySequence)) {
        return nil;
    }

    Py_ssize_t size = PySequence_Size(pySequence);
    if (size < 0) {
        return nil;
    }

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:(NSUInteger)size];

    for (Py_ssize_t i = 0; i < size; i++) {
        PyObject *pyItem = PySequence_GetItem(pySequence, i);  // New reference
        NSString *string = MPLGetStringWithPyString(pyItem);
        Py_DECREF(pyItem);

        if (string) {
            [result addObject:string];
        } else {
            return nil;
        }
    }

    return [result copy];
}


extern NSString *MPLGetStringWithPySequence(PyObject *pySequence)
{
    NSArray *array = MPLGetStringArrayWithPySequence(pySequence);
    return [array count] == 1 ? [array lastObject] : nil;
}


NSDictionary *MPLGetStringDictionaryWithPyDict(PyObject *dict)
{
    if (!dict || !PyDict_Check(dict)) {
        return nil;
    }

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    PyObject *pyKey = NULL;
    PyObject *pyValue = NULL;
    Py_ssize_t position = 0;

    while (PyDict_Next(dict, &position, &pyKey, &pyValue)) {
        NSString *key = MPLGetStringWithPyString(pyKey);
        NSString *value = MPLGetStringWithPyString(pyValue);
        if (!key || !value) return nil;

        [result setObject:value forKey:key];
    }

    return [result copy];
}


#pragma mark - Graphics Utility Functions

CGRect MPLGetCenteredRect(CGRect bounds, CGSize size)
{
    return CGRectMake(
        bounds.origin.x + ((bounds.size.width  - size.width)  / 2.0),
        bounds.origin.y + ((bounds.size.height - size.height) / 2.0),
        size.width,
        size.height
    );
}


NSColor *MPLGetRGBColor(int rgb, CGFloat alpha)
{
    float r = (((rgb & 0xFF0000) >> 16) / 255.0);
    float g = (((rgb & 0x00FF00) >>  8) / 255.0);
    float b = (((rgb & 0x0000FF) >>  0) / 255.0);

    return [NSColor colorWithSRGBRed:r green:g blue:b alpha:alpha];
}


CGImageRef sCreateImage(
    CGSize size, CGFloat scale, BOOL flipped,
    CFStringRef colorSpaceName, size_t componentCount, CGBitmapInfo bitmapInfo,
    void (^callback)(CGContextRef)
) {
    if (size.width <= 0 || size.height <= 0) return NULL;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(colorSpaceName);
    if (!colorSpace) return NULL;

    size_t pixelsWide = size.width  * scale;
    size_t pixelsHigh = size.height * scale;

    CGContextRef context = CGBitmapContextCreate(
        NULL, pixelsWide, pixelsHigh,
        8, pixelsWide * componentCount, colorSpace,
        bitmapInfo
    );

    CGImageRef result = NULL;

    if (context) {
        if (flipped) {
            CGContextTranslateCTM(context, 0, pixelsHigh);
            CGContextScaleCTM(context, scale, -scale);
        }

        NSGraphicsContext *savedContext = [NSGraphicsContext currentContext];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithCGContext:context flipped:flipped]];

        callback(context);
        
        [NSGraphicsContext setCurrentContext:savedContext];

        result = CGBitmapContextCreateImage(context);
        CFRelease(context);
    }

    CGColorSpaceRelease(colorSpace);

    return result;
}


CGImageRef MPLCreateImage(CGSize size, CGFloat scale, void (^callback)(CGContextRef))
{
    CGBitmapInfo bitmapInfo = 0 | kCGImageAlphaPremultipliedFirst | kCGImageByteOrder32Little;
    return sCreateImage(size, scale, YES, kCGColorSpaceSRGB, 4, bitmapInfo, callback);
}


CGImageRef MPLCopyGrayscaleNonAlphaImage(CGImageRef inImage)
{
    CGSize size = CGSizeMake(CGImageGetWidth(inImage), CGImageGetHeight(inImage));
    CFStringRef colorSpaceName = kCGColorSpaceGenericGrayGamma2_2;
    CGBitmapInfo bitmapInfo = 0 | kCGImageAlphaNone;

    return sCreateImage(size, 1, NO, colorSpaceName, 1, bitmapInfo, ^(CGContextRef context) {
        CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), inImage);
    });
}

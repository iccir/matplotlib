#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Python.h>

// When a method or function is NS_UNAVAILABLE, call MPLUnavailable()
// in the implementation to throw a runtime error.
extern void _MPLUnavailable(const char *prettyFunction) __attribute__((__noreturn__));
#define MPLUnavailable() _MPLUnavailable(__PRETTY_FUNCTION__)

// Acquire the GIL, call a method with the specified arguments,
// discard the result, print any exception.
extern void MPLCallMethod(PyObject *pyObject, const char *name, char const *format, ...);

// Converts the passed Python str to an NSString
extern NSString *MPLGetStringWithPyString(PyObject *string);

// Input: a Python sequence of str objects.
// Output: An NSArray of NSString objects.
// Returns nil if 'sequence' is not a sequence or contained any non-str object
extern NSArray<NSString *> *MPLGetStringArrayWithPySequence(PyObject *pySequence);

// Input: a Python sequence of exactly one str object.
// Output: An NSString or nil
extern NSString *MPLGetStringWithPySequence(PyObject *pySequence);

// Input: a Python dict of str keys and values.
// Output: An NSDictionary of NSString keys and values.
// Returns nil if 'dict' is not a dict or any key/value was not a str.
extern NSDictionary<NSString *, NSString *> *MPLGetStringDictionaryWithPyDict(PyObject *dict);

// Returns a rectangle of size 'size' centered in 'bounds'.
// For example: { 60, 40 } centered in { 20, 20, 80, 80 } is { 30, 40, 60, 40 }
extern CGRect MPLGetCenteredRect(CGRect bounds, CGSize size);

// Returns an NSColor in the sRGB color space.
// For example: 'MPLGetRGBColor(0xFF0000, 1.0)' is opaque red.
extern NSColor *MPLGetRGBColor(int rgb, CGFloat alpha);

// Create a a sRGB+alpha image of the specified width, height, and scale factor.
// (0, 0) corresponds to the upper-left corner.
extern CGImageRef MPLCreateImage(CGSize size, CGFloat scale, void (^callback)(CGContextRef));

// Copy a grayscale non-alpha version of inImage to use with CGContextClipToMask()
extern CGImageRef MPLCopyGrayscaleNonAlphaImage(CGImageRef inImage);

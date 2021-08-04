#ifndef coregraphics_h
#define coregraphics_h

#import <AppKit/NSImage.h>

// taken from qcoregraphics.mm (Qt 5.15.4) and ported for older Qt 5 versions
@interface NSImage (QtExtras)
+ (instancetype)imageFromQImage:(const QT_PREPEND_NAMESPACE(QImage) &)image;
+ (instancetype)imageFromQIcon:(const QT_PREPEND_NAMESPACE(QIcon) &)icon;
+ (instancetype)imageFromQIcon:(const QT_PREPEND_NAMESPACE(QIcon) &)icon withSize:(int)size;
@end

#endif // coregraphics_h

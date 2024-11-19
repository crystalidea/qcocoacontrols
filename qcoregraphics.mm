#include "pch.h"
#include "qcoregraphics.h"

#if (QT_VERSION < QT_VERSION_CHECK(5, 7, 0))

    // this adds const to non-const objects (like std::as_const)
    template <typename T>
    Q_DECL_CONSTEXPR typename std::add_const<T>::type &qAsConst(T &t) noexcept { return t; }
    // prevent rvalue arguments:
    template <typename T>
    void qAsConst(const T &&) = delete;

    // like std::exchange
    template <typename T, typename U = T>
    Q_DECL_RELAXED_CONSTEXPR T qExchange(T &t, U &&newValue)
    {
        T old = std::move(t);
        t = std::forward<U>(newValue);
        return old;
    }
#endif

template <typename T, typename U, U (*RetainFunction)(U), void (*ReleaseFunction)(U)>
class QAppleRefCounted
{
public:
    QAppleRefCounted() : value() {}
    QAppleRefCounted(const T &t) : value(t) {}
    QAppleRefCounted(T &&t) noexcept(std::is_nothrow_move_constructible<T>::value)
        : value(std::move(t)) {}
    QAppleRefCounted(QAppleRefCounted &&other)
            noexcept(std::is_nothrow_move_assignable<T>::value &&
                     std::is_nothrow_move_constructible<T>::value)
        : value(qExchange(other.value, T())) {}
    QAppleRefCounted(const QAppleRefCounted &other) : value(other.value) { if (value) RetainFunction(value); }
    ~QAppleRefCounted() { if (value) ReleaseFunction(value); }
    operator T() const { return value; }
    void swap(QAppleRefCounted &other) noexcept(noexcept(qSwap(value, other.value)))
    { qSwap(value, other.value); }
    QAppleRefCounted &operator=(const QAppleRefCounted &other)
    { QAppleRefCounted copy(other); swap(copy); return *this; }
    QAppleRefCounted &operator=(QAppleRefCounted &&other)
        noexcept(std::is_nothrow_move_assignable<T>::value &&
                 std::is_nothrow_move_constructible<T>::value)
    { QAppleRefCounted moved(std::move(other)); swap(moved); return *this; }
    T *operator&() { return &value; }
protected:
    T value;
};

/*
    Helper class that automates refernce counting for CFtypes.
    After constructing the QCFType object, it can be copied like a
    value-based type.

    Note that you must own the object you are wrapping.
    This is typically the case if you get the object from a Core
    Foundation function with the word "Create" or "Copy" in it. If
    you got the object from a "Get" function, either retain it or use
    constructFromGet(). One exception to this rule is the
    HIThemeGet*Shape functions, which in reality are "Copy" functions.
*/
template <typename T>
class QCFType : public QAppleRefCounted<T, CFTypeRef, CFRetain, CFRelease>
{
    using Base = QAppleRefCounted<T, CFTypeRef, CFRetain, CFRelease>;
public:
    using Base::Base;
    explicit QCFType(CFTypeRef r) : Base(static_cast<T>(r)) {}
    template <typename X> X as() const { return reinterpret_cast<X>(this->value); }
    static QCFType constructFromGet(const T &t)
    {
        if (t)
            CFRetain(t);
        return QCFType<T>(t);
    }
};

#if (QT_VERSION >= QT_VERSION_CHECK(5, 8, 0))
    #define QImage2CGImageRef(img) img.toCGImage()
    #define QSize2CGSize(sz) sz.toCGSize()
#else
    #define QImage2CGImageRef(img) toCGImage(img)
    #define QSize2CGSize(sz) CGSizeMake(sz.width(), sz.height())

    CGBitmapInfo qt_mac_bitmapInfoForImage(const QImage &image)
    {
        CGBitmapInfo bitmapInfo = kCGImageAlphaNone;
        switch (image.format()) {
        case QImage::Format_ARGB32:
            bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrder32Host;
            break;
        case QImage::Format_RGB32:
            bitmapInfo = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host;
            break;
        case QImage::Format_RGBA8888_Premultiplied:
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
            break;
        case QImage::Format_RGBA8888:
            bitmapInfo = kCGImageAlphaLast | kCGBitmapByteOrder32Big;
            break;
        case QImage::Format_RGBX8888:
            bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big;
            break;
        case QImage::Format_ARGB32_Premultiplied:
            bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
            break;
        default: break;
        }
        return bitmapInfo;
    }

    CGImageRef toCGImage(const QImage &img)
    {
        if (img.isNull())
            return nil;
        CGBitmapInfo bitmapInfo = qt_mac_bitmapInfoForImage(img);
        // Format not supported: return nil CGImageRef
        if (bitmapInfo == kCGImageAlphaNone)
            return nil;
        // Create a data provider that owns a copy of the QImage and references the image data.
        auto deleter = [](void *image, const void *, size_t)
                       { delete static_cast<QImage *>(image); };
        QCFType<CGDataProviderRef> dataProvider =
            CGDataProviderCreateWithData(new QImage(img), img.bits(), img.byteCount(), deleter);
        QCFType<CGColorSpaceRef> colorSpace =  CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        const size_t bitsPerComponent = 8;
        const size_t bitsPerPixel = 32;
        const CGFloat *decode = nullptr;
        const bool shouldInterpolate = false;
        return CGImageCreate(img.width(), img.height(), bitsPerComponent, bitsPerPixel,
                             img.bytesPerLine(), colorSpace, bitmapInfo, dataProvider,
                             decode, shouldInterpolate, kCGRenderingIntentDefault);
    }
#endif

@implementation NSImage (QtExtras)
+ (instancetype)imageFromQImage:(const QImage &)image
{
    if (image.isNull())
        return nil;

    QCFType<CGImageRef> cgImage = QImage2CGImageRef(image);
    if (!cgImage)
        return nil;

    // We set up the NSImage using an explicit NSBitmapImageRep, instead of
    // [NSImage initWithCGImage:size:], as the former allows us to correctly
    // set the size of the representation to account for the device pixel
    // ratio of the original image, which in turn will be reflected by the
    // NSImage.
    auto nsImage = [[NSImage alloc] initWithSize:NSZeroSize];
    auto *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    imageRep.size = QSize2CGSize((image.size() / image.devicePixelRatioF()));
    [nsImage addRepresentation:[imageRep autorelease]];
    Q_ASSERT(CGSizeEqualToSize(nsImage.size, imageRep.size));

    return [nsImage autorelease];
}

+ (instancetype)imageFromQIcon:(const QIcon &)icon
{
    return [NSImage imageFromQIcon:icon withSize:0];
}

+ (instancetype)imageFromQIcon:(const QIcon &)icon withSize:(int)size
{
    if (icon.isNull())
        return nil;

    auto availableSizes = icon.availableSizes();
    if (availableSizes.isEmpty() && size > 0)
        availableSizes << QSize(size, size);

    auto nsImage = [[[NSImage alloc] initWithSize:NSZeroSize] autorelease];

    for (QSize size : qAsConst(availableSizes)) {
        QImage image = icon.pixmap(size).toImage();
        if (image.isNull())
            continue;

        QCFType<CGImageRef> cgImage = QImage2CGImageRef(image);
        if (!cgImage)
            continue;

        auto *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
        imageRep.size = QSize2CGSize((image.size() / image.devicePixelRatioF()));
        [nsImage addRepresentation:[imageRep autorelease]];
    }

    if (!nsImage.representations.count)
        return nil;

    [nsImage setTemplate:icon.isMask()];

    if (size)
        nsImage.size = CGSizeMake(size, size);

    return nsImage;
}
@end

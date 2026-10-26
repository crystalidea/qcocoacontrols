#include "pch.h"
#include "qcoregraphics.h"

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
        : value(std::exchange(other.value, T())) {}
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

@implementation NSImage (QtExtras)
+ (instancetype)imageFromQImage:(const QImage &)image
{
    if (image.isNull())
        return nil;

    QCFType<CGImageRef> cgImage = image.toCGImage();
    if (!cgImage)
        return nil;

    // We set up the NSImage using an explicit NSBitmapImageRep, instead of
    // [NSImage initWithCGImage:size:], as the former allows us to correctly
    // set the size of the representation to account for the device pixel
    // ratio of the original image, which in turn will be reflected by the
    // NSImage.
    auto nsImage = [[NSImage alloc] initWithSize:NSZeroSize];
    auto *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    imageRep.size = (image.size() / image.devicePixelRatioF()).toCGSize();
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

    for (QSize size : std::as_const(availableSizes))
    {
        QImage image = icon.pixmap(size).toImage();
        if (image.isNull())
            continue;

        QCFType<CGImageRef> cgImage = image.toCGImage();
        if (!cgImage)
            continue;

        auto *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
        imageRep.size = (image.size() / image.devicePixelRatioF()).toCGSize();
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

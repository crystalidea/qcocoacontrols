#include "pch.h"
#include "qcocoaicon.h"
#include "qcoregraphics.h"

NSImage * QCocoaIcon::standardIcon(StandardIcon type)
{
    NSString *nsImageName = nil;
    NSImage *nsImage = nil;

    if (type == StandardIcon::UserAccounts)
        nsImageName = NSImageNameUserAccounts;
    else if (type == StandardIcon::PreferencesGeneral)
        nsImageName = NSImageNamePreferencesGeneral;
    else if (type == StandardIcon::Advanced)
        nsImageName = NSImageNameAdvanced;
    else if (type == StandardIcon::Computer)
        nsImageName = NSImageNameComputer;
    else if (type == StandardIcon::ColorPanel)
        nsImageName = NSImageNameColorPanel;
    else if (type == StandardIcon::FontPanel)
        nsImageName = NSImageNameFontPanel;
    else if (type == StandardIcon::ListViewTemplate)
        nsImageName = NSImageNameListViewTemplate;
    else if (type == StandardIcon::Add)
        nsImageName = NSImageNameAddTemplate;
    else if (type == StandardIcon::Remove)
        nsImageName = NSImageNameRemoveTemplate;
    else if (type == StandardIcon::Info)
        nsImageName = NSImageNameInfo;
    else if (type == StandardIcon::Action)
        nsImageName = NSImageNameActionTemplate;

    if (nsImageName)
        nsImage = [NSImage imageNamed: nsImageName];

    return nsImage;
}

NSImage *QCocoaIcon::imageFromQIcon(const QIcon& icon)
{
    return [NSImage imageFromQIcon: icon];
}

NSImage *QCocoaIcon::imageFromQImage(const QImage &img)
{
    return [NSImage imageFromQImage: img];
}

QPixmap QCocoaIcon::standardIcon(StandardIcon type, int nSize)
{
    QMacAutoReleasePool pool;

    QPixmap pix;

    NSImage *nsImage = QCocoaIcon::standardIcon(type);

    if (nsImage)
    {
        NSRect rect = NSMakeRect(0, 0, nSize, nSize);
        CGImageRef imageRef = [nsImage CGImageForProposedRect: &rect context:nil hints:nil];

        if (imageRef)
        {
            QImage img = CGImageToQImage(imageRef);

            if (!img.isNull())
                pix = QPixmap::fromImage(img);

            // The CGImageRef returned is guaranteed to live as long as the current autorelease pool.
            // The caller should not release the CGImage. This is the standard Cocoa convention, but people may not realize that it applies to CFTypes.
            //CFRelease(imageRef);
        }
    }

    return pix;
}

// https://stackoverflow.com/questions/74747658/how-to-convert-a-cgimageref-to-a-qpixmap-in-qt-6

CGBitmapInfo CGBitmapInfoForQImage(const QImage &image)
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
    default:
        break;
    }

    return bitmapInfo;
}

QImage CGImageToQImage(CGImageRef cgImage)
{
    const size_t width = CGImageGetWidth(cgImage);
    const size_t height = CGImageGetHeight(cgImage);
    QImage image(width, height, QImage::Format_ARGB32_Premultiplied);
    image.fill(Qt::transparent);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef context = CGBitmapContextCreate((void *)image.bits(), image.width(), image.height(), 8,
                                                 image.bytesPerLine(), colorSpace, CGBitmapInfoForQImage(image));

    // Scale the context so that painting happens in device-independent pixels
    const qreal devicePixelRatio = image.devicePixelRatio();
    CGContextScaleCTM(context, devicePixelRatio, devicePixelRatio);

    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(context, rect, cgImage);

    CFRelease(colorSpace);
    CFRelease(context);

    return image;
}


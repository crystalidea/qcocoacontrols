#include "stdafx.h"
#include "qcocoaicon.h"

#include <QtMacExtras>

#import <AppKit/NSImage.h>

NSImage * QCocoaIcon::iconToNSImage(StandardIcon type)
{
    QString str;

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

NSImage *QCocoaIcon::iconToNSImage(const QIcon& icon, const QWidget *widget)
{
    if (icon.isNull())
        return 0;

    NSImage *image = nil;
    image = [[NSImage alloc] init];

    int nScreenNumber = QApplication::desktop()->screenNumber(widget);

    if (nScreenNumber != -1)
    {
        QScreen *screen = QApplication::screens().at(nScreenNumber);

        if (screen)
        {
            qreal pixelRatio = screen->devicePixelRatio();

            for (QSize sz : icon.availableSizes())
            {
                QPixmap pixmap = icon.pixmap(sz);

                CGImageRef cgimage = QtMac::toCGImageRef(pixmap);
                NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgimage];
                // https://stackoverflow.com/questions/24945615/how-to-show-in-memory-nsimage-as-retina-2x
                [bitmapRep setSize: NSMakeSize(pixmap.width() / pixelRatio, pixmap.height() / pixelRatio ) ];
                [image addRepresentation:bitmapRep];
                [bitmapRep release];
                CFRelease(cgimage);
            }
        }
    }

    return image;
}

QPixmap QCocoaIcon::standardIcon(StandardIcon type, int nSize)
{
    QMacAutoReleasePool pool;

    QPixmap pix;

    NSImage *nsImage = QCocoaIcon::iconToNSImage(type);

    if (nsImage)
    {
        NSRect rect = NSMakeRect(0, 0, nSize, nSize);
        CGImageRef imageRef = [nsImage CGImageForProposedRect: &rect context:nil hints:nil];

        if (imageRef)
        {
            pix = QtMac::fromCGImageRef(imageRef);

            //CFRelease(imageRef); // not needed with autorelease pool
        }
    }

    return pix;
}

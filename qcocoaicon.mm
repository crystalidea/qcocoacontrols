#include "stdafx.h"
#include "qcocoaicon.h"
#include "qcoregraphics.h"

#include <QtMacExtras>

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
            pix = QtMac::fromCGImageRef(imageRef);

            // The CGImageRef returned is guaranteed to live as long as the current autorelease pool.
            // The caller should not release the CGImage. This is the standard Cocoa convention, but people may not realize that it applies to CFTypes.
            //CFRelease(imageRef);
        }
    }

    return pix;
}


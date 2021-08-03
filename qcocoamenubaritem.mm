#include "stdafx.h"
#include "qcocoamenubaritem.h"

#import <AppKit/AppKit.h>

class QCocoaMenubarItemPrivate
{
public:

    QCocoaMenubarItemPrivate()
    {
        // TODO
    }

    QCocoaMenubarItemPrivate(NSStatusItem* item)
        : statusItem(item)
    {
        Q_ASSERT( [item isKindOfClass:[NSStatusItem class]] );

        // [NSStatusItem button] was added in 10.10, but before that there was a private _button selector
        if ((floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9))
            statusItemButton = statusItem.button;
        else
        {
            typedef NSButton * (*buttonSelector)(id, SEL);

            SEL selector = NSSelectorFromString(@"_button");

            if ([statusItem respondsToSelector:selector]) {
                IMP imp = [statusItem methodForSelector:selector];
                buttonSelector func = reinterpret_cast<buttonSelector>(imp);
                statusItemButton = func(statusItem, selector);
            }
        }

        Q_ASSERT(statusItemButton);
    }

    ~QCocoaMenubarItemPrivate()
    {

    }

    NSStatusItem* getStatusItem() {
        return statusItem;
    }

    NSButton* getStatusItemButton() {
        return statusItemButton;
    }

private:

    NSStatusItem* statusItem = nullptr;
    NSButton *statusItemButton = nullptr;
};

QCocoaMenubarItem::QCocoaMenubarItem(QObject *parent)
    : QObject(parent), pimpl(new QCocoaMenubarItemPrivate())
{

}

QCocoaMenubarItem::QCocoaMenubarItem(QObject *parent, WId existingStatusItem)
    : QObject(parent), pimpl(new QCocoaMenubarItemPrivate(reinterpret_cast<NSStatusItem *>(existingStatusItem)))
{

}

QCocoaMenubarItem::~QCocoaMenubarItem()
{

}

WId QCocoaMenubarItem::getStatusItemButton() const
{
    return reinterpret_cast<WId>(pimpl->getStatusItemButton());
}

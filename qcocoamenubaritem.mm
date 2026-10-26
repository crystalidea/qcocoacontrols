#include "pch.h"
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

        statusItemButton = statusItem.button;

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

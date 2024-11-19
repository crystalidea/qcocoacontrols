#include "pch.h"
#include "qcocoapreferencesdialog.h"

#include <QtMacExtras>

#import <AppKit/NSToolbar.h>
#import <AppKit/NSToolbarItem.h>

#include "bigsurtoolbar.h"

class QCocoaPreferencesPrivate
{
public:

    NSToolbar *nativeToolbar() const { return _macToolbar->nativeToolbar(); }

    QMacToolBarBigSur *_macToolbar;
    QCocoaPreferencesDialog *_dialog;
};

QCocoaToolbarImpl::QCocoaToolbarImpl(QCocoaPreferencesDialog *parent)
    : QObject(parent)
{
    _private = new QCocoaPreferencesPrivate();

    _private->_macToolbar = new QMacToolBarBigSur(this);
    _private->_dialog = parent;

    NSToolbar *nativeToolbar = _private->nativeToolbar();
    nativeToolbar.allowsUserCustomization = NO;
}

void QCocoaToolbarImpl::setButtonTitle(int nButton, const QString &title)
{
    Q_ASSERT(nButton < _private->_macToolbar->items().size());

    if (nButton < _private->_macToolbar->items().size())
        _private->_macToolbar->items().at(nButton)->setText(title);
}

QCocoaToolbarImpl::~QCocoaToolbarImpl()
{
    delete _private;
}

void QCocoaToolbarImpl::addButton(QPreferencesPage *page, bool bLast)
{
    QMacAutoReleasePool pool;

    QMacToolBarItem *toolBarItem = _private->_macToolbar->addItem(page->getIcon(), page->getTitle());
    toolBarItem->setSelectable(true);

    QObject::connect(toolBarItem, &QMacToolBarItem::activated,
                     std::bind( &QCocoaToolbarImpl::buttonActivated, this, _private->_macToolbar->items().size() - 1 ) );

    if (bLast)
    {
        _private->_dialog->window()->winId(); // create window->windowhandle()
        _private->_macToolbar->attachToWindowWithStyle(_private->_dialog->window()->windowHandle(), QMacToolBarBigSur::StylePreference);

        setSelectedButton(0); // now make the first item selected
    }
}

void QCocoaToolbarImpl::setSelectedButton(int nButton)
{
    Q_ASSERT(nButton < _private->_macToolbar->items().size());

    if (nButton < _private->_macToolbar->items().size())
    {
        QMacToolBarItem *toolBarItemFirst = _private->_macToolbar->items()[nButton];
        NSToolbarItem *nativeToolBarItem = toolBarItemFirst->nativeToolBarItem();

        NSToolbar *nativeToolbar = _private->nativeToolbar();
        [nativeToolbar setSelectedItemIdentifier:nativeToolBarItem.itemIdentifier];
    }
}

int QCocoaToolbarImpl::getHeight() const
{
    return 0;
}

int QCocoaToolbarImpl::getContentPaddingY() const
{
    return 20;
}

int QCocoaToolbarImpl::getMinimumWidth() const
{
    return 300;
}

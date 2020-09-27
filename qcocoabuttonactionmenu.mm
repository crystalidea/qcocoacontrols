#include "stdafx.h"
#include "qcocoabuttonactionmenu.h"
#include "qcocoabutton_p.h"

#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSPopUpButtonCell.h>

class CocoaButtonPrivateActionMenu : public CocoaButtonPrivate
{
public:

    CocoaButtonPrivateActionMenu(QCocoaButton *qButton)
        : CocoaButtonPrivate(qButton, [[NSPopUpButton alloc] initWithFrame: NSMakeRect(0, 0, 0, 0) pullsDown: YES])
    {

    }

    void setImage(NSImage *img) override
    {
        NSPopUpButton *btn = static_cast<NSPopUpButton *>(getNSButton());

        NSMenu *menu = [btn menu];

        Q_ASSERT(menu && [menu numberOfItems]);

        if (menu && [menu numberOfItems])
        {
            NSMenuItem *pMenuItem = [menu itemAtIndex:0];

            [pMenuItem setImage: (NSImage *)img];
        }
    }

    void updateSize() override
    {
        QCocoaButtonActionMenu *btnCocoa = static_cast<QCocoaButtonActionMenu *>(getButton());

        NSRect frame = [_nsButton frame];

        [_nsButton setFrame:frame];

        if ([_nsButton imagePosition] == NSImageOnly)
            _cocoaButton->setFixedSize(44, NSHeight(frame));
        else
        {
            if (btnCocoa->fixedWidth())
                _cocoaButton->setFixedSize(btnCocoa->fixedWidth(), NSHeight(frame));
            else
            {
                [_nsButton sizeToFit];
                _cocoaButton->setFixedSize(NSWidth(frame), NSHeight(frame));
            }
        }
    }

    NSMenuItem * insertOrGetTitleMenuItem()
    {
        QMacAutoReleasePool pool;

        NSMenuItem *dummyItem = nullptr;
        NSPopUpButton *btn = static_cast<NSPopUpButton *>(getNSButton());
        QCocoaButtonActionMenu *btnCocoa = static_cast<QCocoaButtonActionMenu *>(getButton());

        // insert dummy first item that will be visible as always displayed
        // https://stackoverflow.com/questions/2669242/a-popup-button-with-a-static-image-cocoa-osx
        // http://www.thecodedself.com/macOS-action-button-swift/

        NSMenu *menu = btn.menu;

        if (menu)
        {
            const static NSInteger dummyTag = 12345;

            if ([menu numberOfItems])
                dummyItem = [menu itemAtIndex:0];

            if (!dummyItem || [dummyItem tag] != dummyTag) // check if dummy doesn't exist or is already there
            {
                // создадим меню с dummy элементом даже пока нет меню, чтобы на кнопке виден был текст (это title dummy элемента)

                dummyItem = [[NSMenuItem alloc] init];
                [dummyItem setTag: dummyTag];
                [menu insertItem: dummyItem atIndex: 0];
                [dummyItem setTitle: btnCocoa->text().toNSString()];
            }
        }

        return dummyItem;
    }
};

QCocoaButtonActionMenu::QCocoaButtonActionMenu(QWidget *parent)
    : QCocoaButton(parent, new CocoaButtonPrivateActionMenu(this) )
{
    setBezelStyle(QCocoaButton::TexturedRounded);

    NSPopUpButton *btn = static_cast<NSPopUpButton *>(pimpl->getNSButton());
    NSPopUpButtonCell *buttonCell = btn.cell;
    [buttonCell setUsesItemFromMenu: YES];
}

void QCocoaButtonActionMenu::setMenu(QMenu *pMenu)
{
    CocoaButtonPrivateActionMenu *pimplMenu = static_cast<CocoaButtonPrivateActionMenu *>(pimpl.get());

    NSPopUpButton *btn = static_cast<NSPopUpButton *>(pimpl->getNSButton());

    [btn setMenu: pMenu->toNSMenu()];

    pimplMenu->insertOrGetTitleMenuItem();

    pimpl->updateSize();
}

void QCocoaButtonActionMenu::setText(const QString &text)
{
    if (_text != text)
    {
        QMacAutoReleasePool pool;

        _text = text;

        CocoaButtonPrivateActionMenu *pimplMenu = static_cast<CocoaButtonPrivateActionMenu *>(pimpl.get());

        NSMenuItem *dummyItem = pimplMenu->insertOrGetTitleMenuItem();

        if (dummyItem)
        {
            [dummyItem setTitle: _text.toNSString()];
        }

        pimpl->updateSize();
    }
}

void QCocoaButtonActionMenu::setFixedWidth(int w)
{
    _fixedWidth = w;

    pimpl->updateSize();
}

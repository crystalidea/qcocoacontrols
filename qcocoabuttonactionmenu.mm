#include "stdafx.h"
#include "qcocoabuttonactionmenu.h"
#include "qcocoabutton_p.h"

#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSPopUpButtonCell.h>

const int FIXED_WIDTH_ICON_ONLY = 44;
const int FIXED_HEIGHT = 28;

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
        NSRect frame = [_nsButton frame];

        if ([_nsButton imagePosition] == NSImageOnly)
            _cocoaButton->setFixedSize(FIXED_WIDTH_ICON_ONLY, FIXED_HEIGHT);
        else
        {
            [_nsButton sizeToFit];
            _cocoaButton->setFixedSize(NSWidth(frame), FIXED_HEIGHT);
        }
    }

    NSMenuItem * insertOrGetTitleMenuItem()
    {
        NSMenuItem *dummyItem = nullptr;
        NSPopUpButton *btn = static_cast<NSPopUpButton *>(getNSButton());

        // insert dummy first item that will be visible as always displayed
        // https://stackoverflow.com/questions/2669242/a-popup-button-with-a-static-image-cocoa-osx
        // http://www.thecodedself.com/macOS-action-button-swift/

        NSMenu *menu = btn.menu;

        Q_ASSERT(menu);

        if (menu)
        {
            const static NSInteger dummyTag = 12345;

            if ([menu numberOfItems])
                dummyItem = [menu itemAtIndex:0];

            if (!dummyItem || [dummyItem tag] != dummyTag) // check if dummy doesn't exist or is already there
            {
                // create a dummy item if without a menu in order to have some text on a button (dummy button title)

                dummyItem = [[[NSMenuItem alloc] init] autorelease];
                [dummyItem setTag: dummyTag];
                [menu insertItem: dummyItem atIndex: 0];
            }
        }

        return dummyItem;
    }
};

QCocoaButtonActionMenu::QCocoaButtonActionMenu(QWidget *parent)
    : QCocoaButton(parent, new CocoaButtonPrivateActionMenu(this) )
{
    _bezelStyle = QCocoaButton::TexturedRounded;

    NSPopUpButton *btn = static_cast<NSPopUpButton *>(pimpl->getNSButton());
    NSPopUpButtonCell *buttonCell = btn.cell;
    [buttonCell setUsesItemFromMenu: YES];
}

void QCocoaButtonActionMenu::setMenu(QMenu *pMenu)
{
    QMacAutoReleasePool pool;

    NSPopUpButton *btn = static_cast<NSPopUpButton *>(pimpl->getNSButton());

    [btn setMenu: pMenu->toNSMenu()];

    setText(text()); // create dummy item, update its text
}

void QCocoaButtonActionMenu::setText(const QString &text)
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

#include "qcocoabutton.h"
#include "qcocoabutton_p.h"

#import <AppKit/NSButton.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSApplication.h>

QCocoaButton::QCocoaButton(QWidget *parent)
    : QCocoaWidget(parent)
{
    pimpl.reset(new CocoaButtonPrivate(this));

    setupLayout(pimpl->getNSButton());

    // calling a virtual function updateSize from a constructor is a bad idea, it's now done in the showEvent method
}

QCocoaButton::QCocoaButton(QWidget *parent, CocoaButtonPrivate *customPrivate)
    : QCocoaWidget(parent)
{
    pimpl.reset(customPrivate);

    setupLayout(pimpl->getNSButton());
}

void QCocoaButton::showEvent(QShowEvent *event)
{
    Q_UNUSED(event);

    setBezelStyle(_bezelStyle); // init default bezel style, will call updateSize
}

QCocoaButton::~QCocoaButton()
{

}

void QCocoaButton::setBezelStyle(BezelStyle bezelStyle)
{
    _bezelStyle = bezelStyle;

    switch(bezelStyle) {
        case QCocoaButton::Disclosure:
        case QCocoaButton::Circular:
        case QCocoaButton::Inline:
        case QCocoaButton::RoundedDisclosure:
        case QCocoaButton::HelpButton:
            [pimpl->getNSButton() setTitle:@""];
        default:
            break;
    }

    NSFont* font = 0;
    switch(bezelStyle) {
        case QCocoaButton::RoundRect:
            font = [NSFont fontWithName:@"Lucida Grande" size:12];
            break;

        case QCocoaButton::Recessed:
            font = [NSFont fontWithName:@"Lucida Grande Bold" size:12];
            break;

        case QCocoaButton::Inline:
            font = [NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]];
            break;

        default:
            font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeRegular]];
            break;
    }

    [pimpl->getNSButton() setFont:font];

    switch(bezelStyle) {
        case QCocoaButton::Recessed:
            [pimpl->getNSButton() setButtonType:NSPushOnPushOffButton];
        case QCocoaButton::Disclosure:
            [pimpl->getNSButton() setButtonType:NSOnOffButton];
        default:
            [pimpl->getNSButton() setButtonType:NSMomentaryPushInButton];
    }

    [pimpl->getNSButton() setBezelStyle:(NSBezelStyle)bezelStyle];

    pimpl->updateSize();
}

void QCocoaButton::setText(const QString &text)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    if (pimpl->isSpecialButton())
        return;

    QMacAutoReleasePool pool;

    [pimpl->getNSButton() setTitle: text.toNSString()];
    //[pimpl->nsButton setAlternateTitle:fromQString(text)]; // Set it for accessibility reasons as alternative title

    pimpl->updateSize();
}

void QCocoaButton::setIcon(const QIcon &image)
{
    QMacAutoReleasePool pool;

    if (pimpl->isSpecialButton())
        return;

    NSImage *img = QCocoaIcon::iconToNSImage(image);

    if (img)
        pimpl->setImage(img);

    pimpl->updateSize();
}

void QCocoaButton::setIcon(QCocoaIcon::StandardIcon icon)
{
    QMacAutoReleasePool pool;

    NSImage *img = QCocoaIcon::iconToNSImage(icon);

    if (img)
        pimpl->setImage(img);

    pimpl->updateSize();
}

void QCocoaButton::setIconPosition(IconPosition pos)
{
    NSCellImagePosition nsPos = NSNoImage;

    if (pos == IconOnly)
        nsPos = NSImageOnly;
    else if (pos == IconLeft)
        nsPos = NSImageLeft;
    else if (pos == IconRight)
        nsPos = NSImageRight;
    else if (pos == IconBelow)
        nsPos = NSImageBelow;
    else if (pos == IconAbove)
        nsPos = NSImageAbove;
    else if (pos == IconOverlaps)
        nsPos = NSImageOverlaps;

    [pimpl->getNSButton() setImagePosition:nsPos];

    pimpl->updateSize();
}

void QCocoaButton::setChecked(bool checked)
{
    [pimpl->getNSButton() setState:checked];
}

void QCocoaButton::setCheckable(bool checkable)
{
    const NSInteger cellMask = checkable ? NSChangeBackgroundCellMask : NSNoCellMask;

    [[pimpl->getNSButton() cell] setShowsStateBy:cellMask];
}

void QCocoaButton::setToolTip(const QString& strTip)
{
    QMacAutoReleasePool pool;

    [pimpl->getNSButton() setToolTip: strTip.toNSString()];
}

void QCocoaButton::setMenu(QMenu *menu)
{
    NSMenu *m = menu->toNSMenu();
    NSEvent *event = [[NSApplication sharedApplication] currentEvent];

    [NSMenu popUpContextMenu:m withEvent:event forView:(NSButton *)pimpl->getNSButton()];
}

bool QCocoaButton::isChecked()
{
    return [pimpl->getNSButton() state];
}

QSize QCocoaButton::sizeHint() const
{
    NSRect frame = [pimpl->getNSButton() frame];

    return QSize(frame.size.width, frame.size.height);
}

QAbstractButton *QCocoaButton::abstractButton()
{
    return reinterpret_cast<QAbstractButton *>(this);
}

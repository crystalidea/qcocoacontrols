#include "pch.h"
#include "qcocoacombobox.h"
#include "qcoregraphics.h"

#import <AppKit/AppKit.h>

#include <functional>

@interface QCocoaComboBoxMenuTarget : NSObject
{
@public
    std::function<void(int)> chosen;
}
- (void)itemChosen:(NSMenuItem *)item;
@end

@implementation QCocoaComboBoxMenuTarget
- (void)itemChosen:(NSMenuItem *)item
{
    // A receiver of the signals may delete the combo box, whose destructor resets and releases this target, the
    // function included. The call runs on a copy that lives until it returns, and nothing here touches the target
    // after the call
    const std::function<void(int)> call = chosen;

    if (call)
        call(int(item.tag));
}
@end

// The menu and the target of its items outlive showPopup(), like the native menu QComboBox keeps for its own native
// list: they are released on the next popup or with the combo box, so the action of the chosen item never reaches a
// released object, whenever AppKit sends it
class QCocoaComboBoxPrivate
{
public:

    ~QCocoaComboBoxPrivate()
    {
        reset();
    }

    void reset()
    {
        if (menu)
        {
            // The combo box may be deleted while its menu is open: the menu closes, and its items let go of the
            // target released below, however long AppKit keeps the menu around
            for (NSMenuItem *item in menu.itemArray)
                item.target = nil;

            [menu cancelTracking];
            [menu release];
            menu = nil;
        }

        if (target)
        {
            target->chosen = nullptr;
            [target release];
            target = nil;
        }
    }

    NSMenu *menu = nil;
    QCocoaComboBoxMenuTarget *target = nil;
};

QCocoaComboBox::QCocoaComboBox(QWidget *parent)
    : QComboBox(parent), _popup(new QCocoaComboBoxPrivate)
{

}

QCocoaComboBox::~QCocoaComboBox()
{

}

void QCocoaComboBox::showPopup()
{
    if (isEditable() || !count())
    {
        QComboBox::showPopup();
        return;
    }

    QMacAutoReleasePool pool;

    _popup->reset();

    _popup->target = [[QCocoaComboBoxMenuTarget alloc] init];

    QPointer<QCocoaComboBox> guard(this);

    // The same signals as when an item is chosen in the list Qt draws, with the text taken before activated as Qt
    // does. A receiver of activated may delete the combo box, so the guard is checked after every signal. A receiver
    // of currentIndexChanged may not: QComboBox itself goes on with the deleted object after that signal
    _popup->target->chosen = [guard](int index) {

        if (!guard)
            return;

        guard->setCurrentIndex(index);

        if (!guard)
            return;

        const QString text = guard->itemText(index);

        emit guard->activated(index);

        if (!guard)
            return;

        emit guard->textActivated(text);
    };

    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    menu.autoenablesItems = NO;
    _popup->menu = menu;

    const int current = currentIndex();
    NSMenuItem *currentItem = nil;

    for (int i = 0; i < count(); ++i)
    {
        const QModelIndex index = model()->index(i, modelColumn(), rootModelIndex());

        // QComboBox::insertSeparator() marks its items so
        if (index.data(Qt::AccessibleDescriptionRole).toString() == QLatin1String("separator"))
        {
            [menu addItem:[NSMenuItem separatorItem]];
            continue;
        }

        NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:itemText(i).toNSString() action:@selector(itemChosen:)
                                                keyEquivalent:@""] autorelease];
        item.target = _popup->target;
        item.tag = i;
        // as in the list Qt draws, an item has to be selectable as well to be chosen: an enabled heading of a group
        // is not
        const Qt::ItemFlags flags = model()->flags(index);
        item.enabled = (flags & Qt::ItemIsEnabled) && (flags & Qt::ItemIsSelectable) ? YES : NO;
        item.state = i == current ? NSControlStateValueOn : NSControlStateValueOff;

        const QIcon icon = itemIcon(i);

        if (!icon.isNull())
            item.image = [NSImage imageFromQIcon:icon withSize:iconSize().width()];

        [menu addItem:item];

        if (!currentItem || i == current)
            currentItem = item;
    }

    menu.minimumWidth = width();

    // a font set on the combo box goes to the menu too, as in the native list of Qt
    if (font().resolveMask())
        menu.font = [NSFont fontWithName:font().family().toNSString() size:font().pointSize()];

    // The position and the way to open the menu are those of QComboBoxPrivate::showNativePopup() and
    // QCocoaMenu::showPopup(). An invisible NSPopUpButtonCell places the current item over the text of the combo box;
    // -[NSMenu popUpMenuPositioningItem:atLocation:inView:] would do that too, but in a modal window it shows the items
    // disabled
    QPoint offset(0, 7);

    if (testAttribute(Qt::WA_MacSmallSize))
        offset = QPoint(-1, 7);
    else if (testAttribute(Qt::WA_MacMiniSize))
        offset = QPoint(-2, 6);

    QWidget *top = window();
    NSView *view = reinterpret_cast<NSView *>(top->winId());
    QPoint pos = mapTo(top, offset);

    // Near the bottom of the screen the menu is lifted by the part of it below the current item that doesn't fit. Its
    // final position is AppKit's, so the part is estimated from the share of the items below the current one
    if (QScreen *screen = top->screen())
    {
        const int bottom = screen->availableGeometry().bottom() + 1;
        const int globalY = mapToGlobal(offset).y();
        const CGFloat menuHeight = menu.size.height;

        if (globalY + menuHeight > bottom)
        {
            const CGFloat share = ([menu indexOfItem:currentItem] + 1.0) / menu.numberOfItems;
            const CGFloat heightBelow = (1.0 - share) * menuHeight;

            if (globalY + heightBelow > bottom)
                pos.setY(qRound(pos.y() - globalY + bottom - heightBelow));
        }
    }

    NSPopUpButtonCell *cell = [[[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:NO] autorelease];
    cell.altersStateOfSelectedItem = NO;
    cell.transparent = YES;
    cell.menu = menu;
    [cell selectItem:currentItem];

    [cell performClickWithFrame:NSMakeRect(pos.x(), pos.y(), menu.minimumWidth, 10) inView:view];

    // The menu takes the mouse release, and without one the combo box stays pressed. The combo box may be gone by
    // now if its window was closed while the menu was open
    if (guard)
    {
        QMouseEvent released(QEvent::MouseButtonRelease, QPointF(), mapToGlobal(QPointF()), Qt::LeftButton,
                             Qt::MouseButtons(Qt::LeftButton), Qt::NoModifier);

        QCoreApplication::sendEvent(this, &released);
    }
}

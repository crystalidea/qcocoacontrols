#include "pch.h"
#include "qcocoapreferencesdialog.h"
#include "qcoregraphics.h"

#import <AppKit/AppKit.h>

// The page buttons are a native NSToolbar in the preference style: an icon with
// a label under it and the current page highlighted, the way macOS lays out a
// settings window. Qt 6 has no public API for NSToolbar, so the delegate below
// hands the items to AppKit and passes the clicks back.

@interface QCocoaPreferencesToolbarDelegate : NSObject <NSToolbarDelegate>
{
@public
    QCocoaToolbarImpl *owner;
    NSMutableArray<NSToolbarItem *> *items;
}
- (void)itemActivated:(NSToolbarItem *)sender;
@end

@implementation QCocoaPreferencesToolbarDelegate

- (instancetype)init
{
    if (self = [super init])
        items = [[NSMutableArray alloc] init];

    return self;
}

- (void)dealloc
{
    [items release];
    [super dealloc];
}

- (NSArray<NSToolbarItemIdentifier> *)itemIdentifiers
{
    NSMutableArray<NSToolbarItemIdentifier> *identifiers = [NSMutableArray arrayWithCapacity:items.count];

    for (NSToolbarItem *item in items)
        [identifiers addObject:item.itemIdentifier];

    return identifiers;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    Q_UNUSED(toolbar);
    Q_UNUSED(flag);

    for (NSToolbarItem *item in items)
    {
        if ([item.itemIdentifier isEqualToString:itemIdentifier])
            return item;
    }

    return nil;
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    Q_UNUSED(toolbar);

    return [self itemIdentifiers];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    Q_UNUSED(toolbar);

    return [self itemIdentifiers];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    Q_UNUSED(toolbar);

    return [self itemIdentifiers];
}

- (void)itemActivated:(NSToolbarItem *)sender
{
    const NSUInteger index = [items indexOfObject:sender];

    if (owner && index != NSNotFound)
        emit owner->buttonActivated(int(index));
}

@end

class QCocoaPreferencesPrivate : public QObject
{
public:

    explicit QCocoaPreferencesPrivate(QCocoaPreferencesDialog *dialog)
        : _dialog(dialog)
    {
        _delegate = [[QCocoaPreferencesToolbarDelegate alloc] init];

        _toolbar = [[NSToolbar alloc] initWithIdentifier:@"QCocoaPreferencesToolbar"];
        _toolbar.delegate = _delegate;
        _toolbar.allowsUserCustomization = NO;
        _toolbar.autosavesConfiguration = NO;
        _toolbar.displayMode = NSToolbarDisplayModeIconAndLabel;

        // Qt replaces the NSWindow of a widget when its type or modality changes
        // after the window was created -- QDialog::setModal() right before show()
        // is enough. The toolbar belongs to the NSWindow, so it is attached again
        // every time the dialog is shown.

        dialog->installEventFilter(this);
    }

    ~QCocoaPreferencesPrivate() override
    {
        // The NSWindow keeps its toolbar and may outlive this object, while
        // NSToolbar.delegate and NSToolbarItem.target are not retained: cut
        // every way back here before the delegate goes away.

        for (NSToolbarItem *item in _delegate->items)
            item.target = nil;

        _delegate->owner = nullptr;
        _toolbar.delegate = nil;

        [_toolbar release];
        [_delegate release];
    }

    void attachToWindow()
    {
        NSView *view = reinterpret_cast<NSView *>(_dialog->window()->winId()); // creates the native window if there is none yet
        NSWindow *window = view.window;

        if (!window)
            return;

        if (window.toolbar != _toolbar)
            window.toolbar = _toolbar;

        window.toolbarStyle = NSWindowToolbarStylePreference;
    }

    bool eventFilter(QObject *watched, QEvent *event) override
    {
        if (watched == _dialog && event->type() == QEvent::Show && _delegate->items.count)
            attachToWindow();

        return QObject::eventFilter(watched, event);
    }

    QCocoaPreferencesDialog *_dialog;
    QCocoaPreferencesToolbarDelegate *_delegate;
    NSToolbar *_toolbar;
};

QCocoaToolbarImpl::QCocoaToolbarImpl(QCocoaPreferencesDialog *parent)
    : QObject(parent)
{
    _private = new QCocoaPreferencesPrivate(parent);
    _private->_delegate->owner = this;
}

void QCocoaToolbarImpl::setButtonTitle(int nButton, const QString &title)
{
    NSMutableArray<NSToolbarItem *> *items = _private->_delegate->items;

    Q_ASSERT(nButton < int(items.count));

    if (nButton >= 0 && nButton < int(items.count))
        items[nButton].label = title.toNSString();
}

QCocoaToolbarImpl::~QCocoaToolbarImpl()
{
    delete _private;
}

void QCocoaToolbarImpl::addButton(QPreferencesPage *page, bool bLast)
{
    QMacAutoReleasePool pool;

    NSMutableArray<NSToolbarItem *> *items = _private->_delegate->items;

    NSString *identifier = [NSString stringWithFormat:@"QCocoaPreferencesPage%lu", static_cast<unsigned long>(items.count)];

    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:identifier];
    item.label = page->getTitle().toNSString();
    item.image = [NSImage imageFromQIcon:page->getIcon() withSize:32];
    item.target = _private->_delegate;
    item.action = @selector(itemActivated:);

    [items addObject:item];
    [item release];

    if (bLast)
    {
        _private->attachToWindow();

        setSelectedButton(0); // now make the first item selected
    }
}

void QCocoaToolbarImpl::setSelectedButton(int nButton)
{
    NSMutableArray<NSToolbarItem *> *items = _private->_delegate->items;

    Q_ASSERT(nButton < int(items.count));

    if (nButton >= 0 && nButton < int(items.count))
        _private->_toolbar.selectedItemIdentifier = items[nButton].itemIdentifier;
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

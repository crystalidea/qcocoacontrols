#include "pch.h"
#include "qcocoapopover.h"
#include "qcocoaappearance.h"
#include "qcocoamenubaritem.h"

#import <AppKit/AppKit.h>

static int EventPopoverClosed = QEvent::User + 1;

@interface NSViewControllerQt : NSViewController {
    // AppKit tells the controller that the popover closed once its animation ends, by when the contents may be gone
    QPointer<QWidget> _contents;
}
-(id)initWithContents:(QWidget *)w;
@end

@implementation NSViewControllerQt

-(id)initWithContents:(QWidget *)w
{
    self = [super init];

    _contents = w;

    return self;
}

-(void)loadView {

    NSView *nativeWidgetView = reinterpret_cast<NSView *>(_contents->winId());

    // this NSWindow hack basically detaches NSView from QWidget
    // and doesn't let top level QWidget to be displayed as a window

    NSWindow *window = [[NSWindow alloc] init];
    NSView *contentView = [window contentView];

    [contentView addSubview:nativeWidgetView];

    [window release];

    _contents->show();

    // The Qt view goes into a plain container instead of becoming the controller's view. The controller's view becomes
    // the content view of the popover window, and Qt then treats that window as its own and pushes the widget's size
    // constraints onto it. The popover window forwards resizeIncrements to its NSPopoverFrame, which doesn't implement
    // it, so the app would crash as soon as the minimum or maximum size of the contents changed. Inside the container
    // the Qt view stays a child view and Qt leaves the popover window alone. The popover gets its size when it is
    // shown: contents that grow later are clipped
    NSView *container = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(nativeWidgetView.frame),
                                                                  NSHeight(nativeWidgetView.frame))] autorelease];
    nativeWidgetView.frame = container.bounds;
    nativeWidgetView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [container addSubview:nativeWidgetView];

    [self setView:container];
}

- (void) receivePopoverClosedNotification:(NSNotification *) notification {

    Q_UNUSED(notification);

    [[NSNotificationCenter defaultCenter] removeObserver: self];

    if (_contents)
    {
        QEvent ev( (QEvent::Type)EventPopoverClosed);
        QCoreApplication::sendEvent(_contents, &ev);
    }
}
@end

// The appearance of a popover is set explicitly, so it doesn't follow the app by itself: while the popover is shown,
// a change of the appearance of the app goes to the popover, and its frame and native controls match the contents Qt
// repaints
@interface QCocoaPopoverAppearanceObserver : NSObject
{
@public
    NSPopover *popover; // not retained: QCocoaPopoverPrivate owns the popover and stops this observer first
}
@end

@implementation QCocoaPopoverAppearanceObserver
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context
{
    Q_UNUSED(keyPath);
    Q_UNUSED(object);
    Q_UNUSED(change);
    Q_UNUSED(context);

    if (popover.shown)
        popover.appearance = NSApp.effectiveAppearance;
}
@end

class QCocoaPopoverPrivate : public QObject
{

public:

    QCocoaPopoverPrivate(QCocoaPopover *parent)
        : QObject(nullptr), _parent (parent)
    {
        _popup = [[NSPopover alloc] init];

        // defaults

        _popup.behavior = NSPopoverBehaviorTransient;
        _popup.animates = YES;
    }

    ~QCocoaPopoverPrivate()
    {
        removeEscapeMonitor();
        stopFollowingAppearance();
        [_popup release];
    }

    void show(NSView * relativeToView, int msec)
    {
        _popup.contentViewController = [[[NSViewControllerQt alloc] initWithContents: _parent->_contents] autorelease];

        // Without an explicit appearance NSPopover gives its frame VibrantLight even when the app is dark: the native
        // controls inside (QCocoaButton) are then drawn light, with black text on the contents Qt draws dark
        _popup.appearance = NSApp.effectiveAppearance;

        if (!_appearanceObserver)
        {
            _appearanceObserver = [[QCocoaPopoverAppearanceObserver alloc] init];
            _appearanceObserver->popover = _popup;

            [NSApp addObserver:_appearanceObserver forKeyPath:@"effectiveAppearance" options:0 context:nullptr];
        }

        [_popup showRelativeToRect:relativeToView.bounds ofView:relativeToView preferredEdge:NSRectEdgeMinY];

        // for some reason NSPopoverDelegate is working only for popoverWillShow notification,
        // that's why we use the notification center

        [[NSNotificationCenter defaultCenter] addObserver:_popup.contentViewController
                                                     selector:@selector(receivePopoverClosedNotification:)
                                                         name:@"NSPopoverDidCloseNotification"
                                                       object:_popup];

        // Escape goes to the key window, which stays the window of Qt while the popover is open, so AppKit doesn't
        // close a transient or semitransient popover on it: the key is taken here before it reaches that window
        if (!_escapeMonitor)
        {
            NSPopover *popup = _popup;

            _escapeMonitor = [[NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown
                                                                    handler:^NSEvent *(NSEvent *event) {
                if (event.keyCode == 53 && popup.shown && popup.behavior != NSPopoverBehaviorApplicationDefined)
                {
                    [popup performClose:nil];
                    return nil;
                }

                return event;
            }] retain];
        }

        if (msec)
        {
            _timer = new QTimer(this);
            _timer->setSingleShot(true);

            QObject::connect(_timer, &QTimer::timeout, _timer, [this]{
                close();
            } );

            _timer->start(msec);
        }
    }

    void closeNSPopover()
    {
        [_popup close];
    }

    // The popover is gone before this returns, and AppKit tells about it right away rather than after an animation
    void closeWithoutAnimation()
    {
        if (_popup.shown)
        {
            _popup.animates = NO;
            [_popup close];
        }
    }

    void removeEscapeMonitor()
    {
        if (_escapeMonitor)
        {
            [NSEvent removeMonitor:_escapeMonitor];
            [_escapeMonitor release];
            _escapeMonitor = nil;
        }
    }

    void stopFollowingAppearance()
    {
        if (_appearanceObserver)
        {
            [NSApp removeObserver:_appearanceObserver forKeyPath:@"effectiveAppearance"];
            [_appearanceObserver release];
            _appearanceObserver = nil;
        }
    }

    void close()
    {
        if (_popup.shown)
        {
            [_popup close];
        }
    }

    void stopTimer()
    {
        if (_timer)
            _timer->stop();
    }

    void setPopoverBehavior(QCocoaPopover::PopoverBehavior b)
    {
        _popup.behavior = (NSPopoverBehavior)(b);
    }

    void setAnimate(bool bAnimate)
    {
        _popup.animates = bAnimate ? YES : NO;
    }

private:

    NSPopover *_popup = nullptr;
    QCocoaPopover *_parent = nullptr;
    QTimer *_timer = nullptr;
    id _escapeMonitor = nil;
    QCocoaPopoverAppearanceObserver *_appearanceObserver = nil;
};

static const char *PROP_IS_POPOVER = "QCocoaPopover";

QCocoaPopover::QCocoaPopover(QObject *parent, QWidget *contents)
    : QObject(parent), _contents(contents), p(new QCocoaPopoverPrivate(this))
{
    _contents->setProperty(PROP_IS_POPOVER, true);

    // Under Liquid Glass a popover is a piece of glass: the contents leave out the background of a window, as the
    // controls of a native popover do, and the glass shows through around them
    if (QCocoaAppearance::isLiquidGlass())
        _contents->setAttribute(Qt::WA_TranslucentBackground);

    // this is required to handle custom event (EventPopoverClosed)
    _contents->installEventFilter(this);
}

QCocoaPopover::~QCocoaPopover()
{
    _contents->removeEventFilter(this);

    // Without its animation the popover is gone, and AppKit has told so, while the contents still exist
    p->closeWithoutAnimation();

    _contents->deleteLater();
}

bool QCocoaPopover::eventFilter(QObject *obj, QEvent *event)
{
    if (obj == _contents && event->type() == EventPopoverClosed) // cocoa closed the popover
    {
        // no need to close the popup and the widget because they are already closed by cocoa
        // only need to emit the signal

        p->removeEscapeMonitor();
        p->stopFollowingAppearance();

        emit closed();

        return true;
    }
    else if (event->type() == QEvent::Close) // if user closed QWidget need to make sure that popup is closed as well
    {
        p->close();
    }
    else if (event->type() == QEvent::Enter)
    {
        p->stopTimer();
    }

    return false;
}

void QCocoaPopover::setPopoverBehavior(PopoverBehavior b)
{
    p->setPopoverBehavior(b);
}

void QCocoaPopover::setAnimate(bool bAnimate)
{
    p->setAnimate(bAnimate);
}

void QCocoaPopover::show(QWidget *forWidget)
{
    NSView *v = reinterpret_cast<NSView *>(forWidget->winId());
    p->show(v, _timeout);
}

void QCocoaPopover::show(QCocoaMenubarItem *forMenuIcon)
{
    NSView *v = reinterpret_cast<NSView *>(forMenuIcon->getStatusItemButton());
    p->show(v, _timeout);
}

void QCocoaPopover::close()
{
    p->close();
}

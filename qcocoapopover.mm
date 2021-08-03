#include "stdafx.h"
#include "qcocoapopover.h"
#include "qcocoamenubaritem.h"

#import <AppKit/AppKit.h>

static int EventPopoverClosed = QEvent::User + 1;

@interface NSViewControllerQt : NSViewController {
    QWidget * _contents;
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

    // this NSWindow hack basically detaches NSView from QWidget
    // and doesn't let top level QWidget to be displayed as a window

    NSView *nativeWidgetView = reinterpret_cast<NSView *>(_contents->winId());
    NSWindow *window = [[NSWindow alloc] init];
    NSView *contentView = [window contentView];

    [contentView addSubview:nativeWidgetView];

    [window release];

    _contents->show(); // only in the end!

    [self setView:nativeWidgetView];
}

- (void) receivePopoverClosedNotification:(NSNotification *) notification {

    [[NSNotificationCenter defaultCenter] removeObserver: self];

    //NSLog(@"--> receivePopoverClosedNotification");

    QEvent ev( (QEvent::Type)EventPopoverClosed);
    QCoreApplication::sendEvent(_contents, &ev);
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
        [_popup release];
    }

    void show(NSView * relativeToView, int msec)
    {
        _popup.contentViewController = [[[NSViewControllerQt alloc] initWithContents: _parent->_contents] autorelease];

        [_popup showRelativeToRect:relativeToView.bounds ofView:relativeToView preferredEdge:NSRectEdgeMinY];

        // for some reason NSPopoverDelegate is working only for popoverWillShow notification,
        // that's why we use the notification center

        [[NSNotificationCenter defaultCenter] addObserver:_popup.contentViewController
                                                     selector:@selector(receivePopoverClosedNotification:)
                                                         name:@"NSPopoverDidCloseNotification"
                                                       object:_popup];

        if (msec)
        {
            QTimer::singleShot(msec, this, [this]{
                close();
            } );
        }
    }

    void close()
    {
        if (_popup.shown)
        {
            [_popup close];
        }

        if (_parent->_contents->isVisible()) // why do we need to check this?
            _parent->_contents->close();
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
    QCocoaPopover *_parent;
};

QCocoaPopover::QCocoaPopover(QObject *parent, QWidget *contents)
    : QObject(parent), _contents(contents), p(new QCocoaPopoverPrivate(this))
{
    // this is required for propert handling of Cmd+Q while popover is displayed
    QGuiApplication::instance()->installEventFilter(this);

    // this is required to handle custom event (EventPopoverClosed)
    _contents->installEventFilter(this);
}

QCocoaPopover::~QCocoaPopover()
{
    QGuiApplication::instance()->removeEventFilter(this);

    _contents->removeEventFilter(this);

    //NSLog(@"--> QCocoaPopover destroy");

    p->close();

    delete _contents;
}

bool QCocoaPopover::eventFilter(QObject *obj, QEvent *event)
{
    if (obj == _contents && event->type() == EventPopoverClosed) // cocoa closed the popover
    {
        //NSLog(@"--> EventPopoverClosed");

        // no need to close the popup and the widget because they are already closed by cocoa
        // only need to emit the signal

        emit closed();

        return true;
    }
    else if (event->type() == QEvent::Quit) // disable quit from the app by pressing Cmd+Q
    {
        //if (_contents->isActiveWindow()) // no check for active widget !
        {
            close();

            //qDebug("--> Popover close in quit event");

            //event->ignore();
            //return true;
        }
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

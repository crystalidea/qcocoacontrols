#include "qcocoasegmentedbutton.h"

#include <QIcon>
#include <QMenu>

#import <AppKit/NSSegmentedControl.h>
#import <AppKit/NSSegmentedCell.h>
#import <AppKit/NSFont.h>

// QCocoaSegmentedButtonTarget

@interface QCocoaSegmentedButtonTarget: NSObject
{
    QCocoaSegmentedButton *mRealTarget;
}
-(id)initWithObject1:(QCocoaSegmentedButton*)object;
-(IBAction)segControlClicked:(id)sender;
@end

@implementation QCocoaSegmentedButtonTarget
-(id)initWithObject1:(QCocoaSegmentedButton*)object
{
    self = [super init];

    mRealTarget = object;

    return self;
}

-(IBAction)segControlClicked:(id)sender
{
    emit mRealTarget->clicked([sender selectedSegment], false);
}
@end

// QCocoaSegmentedButtonPrivate

class QCocoaSegmentedButtonPrivate : public QObject
{
protected:

    QPointer<QCocoaSegmentedButton> parent;
    NSSegmentedControl *control;

public:
    QCocoaSegmentedButtonPrivate(NSSegmentedControl *pControl, QCocoaSegmentedButton *pParent)
        : QObject(pParent), parent(pParent), control(pControl)
    {

    }

    ~QCocoaSegmentedButtonPrivate()
    {
        [control release];
    }

    void updateSize()
    {
        [control sizeToFit];

        NSRect frame = [control frame];

        [control setFrame:frame];

        parent->setFixedSize(NSWidth(frame), NSHeight(frame));
    }

    friend class QCocoaSegmentedButton;
};

// see: http://stackoverflow.com/questions/1203698/show-nssegmentedcontrol-menu-when-segment-clicked-despite-having-set-action

@interface SegmentedCellWithoutMenuDelay : NSSegmentedCell
{

}
- (SEL)action;
@end

@implementation SegmentedCellWithoutMenuDelay
- (SEL)action
{
    //this allows connected menu to popup instantly (because no action is returned for menu button)
    NSMenu *m = [self menuForSegment: [self selectedSegment]];

    return (m ? nil : [super action]);
}
@end

QCocoaSegmentedButton::QCocoaSegmentedButton(QWidget *pParent /*= 0*/)
  : QCocoaWidget(pParent)
{
    QMacAutoReleasePool pool;

    NSSegmentedControl *segControl = [[NSSegmentedControl alloc] init];

    d_ptr.reset(new QCocoaSegmentedButtonPrivate(segControl, this));

    [segControl setFont: [NSFont controlContentFontOfSize:[NSFont systemFontSizeForControlSize: NSControlSizeSmall]]];

    [segControl sizeToFit];

    setCustomCellWithoutMenuDelay();

    QCocoaSegmentedButtonTarget *bt = [[QCocoaSegmentedButtonTarget alloc] initWithObject1:this];
    [segControl setTarget:bt];
    [segControl setAction:@selector(segControlClicked:)];

    setupLayout(segControl);

    NSRect initFrame = [segControl frame];

    setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
    setFixedSize(NSWidth(initFrame), NSHeight(initFrame));
}

void QCocoaSegmentedButton::setCustomCellWithoutMenuDelay()
{
    NSFont *font = [d_ptr->control font]; // remember font

    [d_ptr->control setCell: [[SegmentedCellWithoutMenuDelay alloc] init]];

    [d_ptr->control setFont:font]; // restore
}

QCocoaSegmentedButton::~QCocoaSegmentedButton()
{
}

QSize QCocoaSegmentedButton::sizeHint() const
{
    Q_ASSERT(d_ptr);
    if (!d_ptr)
        return QSize();

    NSRect frame = [d_ptr->control frame];
    return QSize(frame.size.width, frame.size.height);
}

void QCocoaSegmentedButton::setSegmentCount(int count)
{
    [d_ptr->control setSegmentCount:count];
}

void QCocoaSegmentedButton::setSegmentStyle(SegmentStyle style)
{
    [d_ptr->control setSegmentStyle:(NSSegmentStyle)style];
}

void QCocoaSegmentedButton::setSegmentTitle(int iSegment, const QString &strTitle)
{
    Q_ASSERT(d_ptr);
    if (!d_ptr)
        return;

    QMacAutoReleasePool pool;

    QString s(strTitle);
    [d_ptr->control setLabel: s.remove('&').toNSString() forSegment: iSegment];

    d_ptr->updateSize();
}

void QCocoaSegmentedButton::setSegmentToolTip(int iSegment, const QString &strTip)
{
    Q_ASSERT(d_ptr);
    if (!d_ptr)
        return;

    QMacAutoReleasePool pool;

    [[d_ptr->control cell] setToolTip: strTip.toNSString() forSegment: iSegment];
}

void QCocoaSegmentedButton::setSegmentIcon(int iSegment, const QIcon& icon)
{
    Q_ASSERT(d_ptr);
    if (!d_ptr)
        return;

    NSImage *nsImage = QCocoaIcon::imageFromQIcon(icon);

    if (nsImage)
    {
        [d_ptr->control setImage: nsImage forSegment: iSegment];

        [nsImage release];
    }

    d_ptr->updateSize();
}

void QCocoaSegmentedButton::setSegmentIcon(int iSegment, QCocoaIcon::StandardIcon icon)
{
    NSImage *nsImage = QCocoaIcon::standardIcon(icon);

    if (nsImage)
        [d_ptr->control setImage: nsImage forSegment: iSegment];

    d_ptr->updateSize();
}

void QCocoaSegmentedButton::setSegmentMenu(int iSegment, QMenu *menu)
{
    Q_ASSERT(d_ptr);
    if (!d_ptr)
        return;

    if (menu && d_ptr->control)
        [d_ptr->control setMenu:menu->toNSMenu() forSegment:iSegment];
}

void QCocoaSegmentedButton::setSegmentEnabled(int iSegment, bool fEnabled)
{
    Q_ASSERT(d_ptr);
    if (!d_ptr)
        return;

    [[d_ptr->control cell] setEnabled: fEnabled forSegment: iSegment];
}

void QCocoaSegmentedButton::segmentAnimateClick(int iSegment)
{
    Q_ASSERT(d_ptr);
    if (!d_ptr)
        return;

    [d_ptr->control setSelectedSegment: iSegment];
    [[d_ptr->control cell] performClick: d_ptr->control];
}

void QCocoaSegmentedButton::setSegmentChecked(int nIndex, bool bChecked)
{
    Q_ASSERT(d_ptr);
    if (!d_ptr)
        return;

    if (bChecked)
        [d_ptr->control setSelectedSegment:nIndex];
}

bool QCocoaSegmentedButton::isSegmentChecked(int nIndex) const
{
    Q_ASSERT(d_ptr);
    if (!d_ptr)
        return false;

    return [d_ptr->control selectedSegment] == nIndex;
}

void QCocoaSegmentedButton::setSegmentFixedWidth(int nSegment, int nWidth)
{
    Q_ASSERT(d_ptr);
    if (!d_ptr)
        return;

    [d_ptr->control setWidth:nWidth forSegment:nSegment];
}

int QCocoaSegmentedButton::segmentWidth(int nSegment) const
{
    return [d_ptr->control widthForSegment:nSegment];
}

int QCocoaSegmentedButton::segmentCount() const
{
    return [d_ptr->control segmentCount];
}

void QCocoaSegmentedButton::setTrackingMode(SegmentSwitchTracking mode)
{
    Q_ASSERT(d_ptr);
    if (!d_ptr)
        return;

    [[d_ptr->control cell] setTrackingMode: (NSSegmentSwitchTracking)mode];
}

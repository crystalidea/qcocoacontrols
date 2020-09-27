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
    mRealTarget->onClicked([sender selectedSegment]);
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

    pimpl = new QCocoaSegmentedButtonPrivate(segControl, this);

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
    NSFont *font = [pimpl->control font]; // remember font

    [pimpl->control setCell: [[SegmentedCellWithoutMenuDelay alloc] init]];

    [pimpl->control setFont:font]; // restore
}

QCocoaSegmentedButton::~QCocoaSegmentedButton()
{
}

QSize QCocoaSegmentedButton::sizeHint() const
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return QSize();

    NSRect frame = [pimpl->control frame];
    return QSize(frame.size.width, frame.size.height);
}

void QCocoaSegmentedButton::setSegmentCount(int count)
{
    [pimpl->control setSegmentCount:count];
}

void QCocoaSegmentedButton::setSegmentStyle(SegmentStyle style)
{
    [pimpl->control setSegmentStyle:(NSSegmentStyle)style];
}

void QCocoaSegmentedButton::setTitle(int iSegment, const QString &strTitle)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    QMacAutoReleasePool pool;

    QString s(strTitle);
    [pimpl->control setLabel: s.remove('&').toNSString() forSegment: iSegment];

    pimpl->updateSize();
}

void QCocoaSegmentedButton::setToolTip(int iSegment, const QString &strTip)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    QMacAutoReleasePool pool;

    [[pimpl->control cell] setToolTip: strTip.toNSString() forSegment: iSegment];
}

void QCocoaSegmentedButton::setSegmentIcon(int iSegment, const QIcon& icon)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    NSImage *nsImage = QCocoaIcon::iconToNSImage(icon, this);

    if (nsImage)
    {
        [pimpl->control setImage: nsImage forSegment: iSegment];

        [nsImage release];
    }

    pimpl->updateSize();
}

void QCocoaSegmentedButton::setSegmentIcon(int iSegment, QCocoaIcon::StandardIcon icon)
{
    NSImage *nsImage = QCocoaIcon::iconToNSImage(icon);

    if (nsImage)
    {
        [pimpl->control setImage: nsImage forSegment: iSegment];

        [nsImage release];
    }

    pimpl->updateSize();
}

void QCocoaSegmentedButton::setSegmentMenu(int iSegment, QMenu *menu)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    if (menu && pimpl->control)
        [pimpl->control setMenu:menu->toNSMenu() forSegment:iSegment];
}

void QCocoaSegmentedButton::setEnabled(int iSegment, bool fEnabled)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    [[pimpl->control cell] setEnabled: fEnabled forSegment: iSegment];
}

void QCocoaSegmentedButton::animateClick(int iSegment)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    [pimpl->control setSelectedSegment: iSegment];
    [[pimpl->control cell] performClick: pimpl->control];
}

void QCocoaSegmentedButton::onClicked(int iSegment)
{
    emit clicked(iSegment, false);
}

void QCocoaSegmentedButton::setChecked(int nIndex, bool bChecked)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    if (bChecked)
        [pimpl->control setSelectedSegment:nIndex];
}

bool QCocoaSegmentedButton::isChecked(int nIndex) const
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return false;

    return [pimpl->control selectedSegment] == nIndex;
}

void QCocoaSegmentedButton::setFixedWidth(int nSegment, int nWidth)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    [pimpl->control setWidth:nWidth forSegment:nSegment];
}

int QCocoaSegmentedButton::segmentWidth(int nSegment) const
{
    return [pimpl->control widthForSegment:nSegment];
}

int QCocoaSegmentedButton::segmentCount() const
{
    return [pimpl->control segmentCount];
}

void QCocoaSegmentedButton::setTrackingMode(SegmentSwitchTracking mode)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    [[pimpl->control cell] setTrackingMode: (NSSegmentSwitchTracking)mode];
}

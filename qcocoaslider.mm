#include "pch.h" // QMacAutoReleasePool
#include "qcocoaslider.h"

#import <AppKit/NSSlider.h>
#import <AppKit/NSSliderCell.h>

class QCocoaSliderPrivate : public QObject
{
protected:

    QPointer<QCocoaSlider> parent;
    NSSlider *nsSlider;

public:
    QCocoaSliderPrivate(NSSlider *pControl, QCocoaSlider *pParent)
        : QObject(pParent), parent(pParent), nsSlider(pControl)
    {

    }

    ~QCocoaSliderPrivate()
    {

    }

    void valueChanged()
    {
        emit parent->valueChanged([nsSlider intValue]);
    }

    friend class QCocoaSlider;
};

@interface QCocoaButtonSliderTarget : NSObject
{
@public
    QPointer<QCocoaSliderPrivate> pimpl;
}
-(IBAction)sliderDidMove:(id)sender;
@end

@implementation QCocoaButtonSliderTarget
-(IBAction)sliderDidMove:(id)sender
{
    Q_UNUSED(sender);
    Q_ASSERT(pimpl);
    if (pimpl)
        pimpl->valueChanged();
}
@end

QCocoaSlider::QCocoaSlider(QWidget * parent /*= 0*/) : QCocoaWidget(parent)
{
    QMacAutoReleasePool pool;

    NSSlider *slider = [[NSSlider alloc] init];
    pimpl = new QCocoaSliderPrivate(slider, this);

    QCocoaButtonSliderTarget *target = [[QCocoaButtonSliderTarget alloc] init];
    target->pimpl = pimpl;
    [slider setTarget:target];
    [slider setAction:@selector(sliderDidMove:)];

    setupLayout(slider);

    [slider release];
}

// An explicitly set vertical property overrides the frame aspect ratio heuristic
// NSSlider otherwise uses for the orientation, so it is kept in sync in BOTH
// directions.

static void setNSSliderVertical(NSSlider *slider, BOOL vertical)
{
    slider.vertical = vertical;
}

void QCocoaSlider::setSliderType(SliderType type /*= LinearHorizontal*/)
{
    switch (type)
    {
        case QCocoaSlider::LinearHorizontal:
            [ [pimpl->nsSlider cell] setSliderType:NSSliderTypeLinear];
            setNSSliderVertical(pimpl->nsSlider, NO);

            setOrientation(Qt::Horizontal);
            break;
        case QCocoaSlider::LinearVertical:
            [ [pimpl->nsSlider cell] setSliderType:NSSliderTypeLinear];
            setNSSliderVertical(pimpl->nsSlider, YES);

            setOrientation(Qt::Vertical);
            break;
        case QCocoaSlider::CircularSlider:
            [ [pimpl->nsSlider cell] setSliderType:NSSliderTypeCircular];
            setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
            break;
    }
}

QSize QCocoaSlider::sizeHint() const
{
    NSRect frame = [pimpl->nsSlider frame];
    return QSize(frame.size.width, frame.size.height);
}

void QCocoaSlider::setOrientation(Qt::Orientation orientation)
{
    // A slider is defined as vertical if its height is greater than its width.

    if (orientation == Qt::Vertical)
    {
        setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Expanding);

        setMaximumWidth(100);
    }
    else
    {
        setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);

    }
}

void QCocoaSlider::setRange(int min, int max)
{
    setMinimum(min);
    setMaximum(max);
}

int QCocoaSlider::maximum() const
{
    return [pimpl->nsSlider maxValue];
}

int QCocoaSlider::minimum() const
{
    return [pimpl->nsSlider minValue];
}

void QCocoaSlider::setMaximum(int maxValue)
{
    [pimpl->nsSlider setMaxValue:maxValue];
}

void QCocoaSlider::setMinimum(int minValue)
{
    [pimpl->nsSlider setMinValue:minValue];
}

int QCocoaSlider::value() const
{
    return [pimpl->nsSlider intValue];
}

void QCocoaSlider::setValue(int value)
{
    [pimpl->nsSlider setIntValue:value];

    pimpl->valueChanged();
}

void QCocoaSlider::setAltIncrementValue(int increment)
{
    [pimpl->nsSlider setAltIncrementValue:increment];
}

void QCocoaSlider::setTickInterval(int ti)
{
    // NSSlider wants a tick count, not an interval. Qt treats a zero interval as "no ticks";
    // dividing by it here would be undefined behaviour (SIGFPE on Intel).

    if (ti <= 0)
    {
        [pimpl->nsSlider setNumberOfTickMarks: 0];
        return;
    }

    // Widen before subtracting: maximum() and minimum() are int, so a full-width
    // range overflows in the subtraction itself. Round up with integer arithmetic
    // rather than a double round-trip, and keep the result in NSInteger, which is
    // what setNumberOfTickMarks: takes. An inverted range is clamped to a single tick.

    const qint64 range = qMax<qint64>(0, qint64(maximum()) - qint64(minimum()));
    const NSInteger ticks = NSInteger((range + ti - 1) / ti) + 1;

    [pimpl->nsSlider setNumberOfTickMarks: ticks];
}

void QCocoaSlider::setTickPosition(QSlider::TickPosition position)
{
    switch (position)
    {
        case QSlider::NoTicks:
            [pimpl->nsSlider setNumberOfTickMarks:0]; break;
        case QSlider::TicksAbove:
            [pimpl->nsSlider setTickMarkPosition:NSTickMarkPositionAbove]; break;
        case QSlider::TicksBelow:
            [pimpl->nsSlider setTickMarkPosition:NSTickMarkPositionBelow]; break;
        case QSlider::TicksBothSides: // not supported in NSSlider
            break;

    }
}

void QCocoaSlider::setAllowsTickMarkValuesOnly(bool bValuesTicks)
{
    [pimpl->nsSlider setAllowsTickMarkValuesOnly: (bValuesTicks ? YES : NO) ];
}

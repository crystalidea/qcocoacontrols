#include "qcocoaslider.h"

#import <Foundation/NSAutoreleasePool.h>

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
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSSlider *slider = [[NSSlider alloc] init];
    pimpl = new QCocoaSliderPrivate(slider, this);

    QCocoaButtonSliderTarget *target = [[QCocoaButtonSliderTarget alloc] init];
    target->pimpl = pimpl;
    [slider setTarget:target];
    [slider setAction:@selector(sliderDidMove:)];

    setupLayout(slider);

    [slider release];

    [pool drain];
}

void QCocoaSlider::setSliderType(SliderType type /*= LinearHorizontal*/)
{
    switch (type)
    {
        case QCocoaSlider::LinearHorizontal:
            [ [pimpl->nsSlider cell] setSliderType:NSSliderTypeLinear];
            setOrientation(Qt::Horizontal);
            break;
        case QCocoaSlider::LinearVertical:
            [ [pimpl->nsSlider cell] setSliderType:NSSliderTypeLinear];
            pimpl->nsSlider.vertical = YES;

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
    int ticks = ceil((maximum() - minimum()) / ti) + 1;

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

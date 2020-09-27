#include "stdafx.h"
#include "qcocoagradientbutton.h"

QCocoaGradientButton::QCocoaGradientButton(QWidget *parent)
    : QCocoaSegmentedButton(parent), widgetToAttachedTo(0)
{
    setSegmentStyle(QCocoaSegmentedButton::SegmentStyleSmallSquare);
    setTrackingMode(QCocoaSegmentedButton::NSSegmentSwitchTrackingMomentary);

    //pimpl = new QCocoaGradientButtonPrivate(this);
}

QCocoaGradientButton::~QCocoaGradientButton()
{

}

bool QCocoaGradientButton::eventFilter(QObject *o, QEvent *ev)
{
    return QWidget::eventFilter(o, ev);
}

QSize QCocoaGradientButton::sizeHint() const
{
    return QCocoaSegmentedButton::sizeHint();
}

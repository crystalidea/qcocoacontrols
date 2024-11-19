#include "pch.h"
#include "qcocoaslider.h"

#include <QSlider>

class QCocoaSliderPrivate : public QObject
{
public:
    QCocoaSliderPrivate(QCocoaSlider *slider, QSlider *sliderReal)
        : QObject(slider), realSlider(sliderReal) {}

    QPointer<QSlider> realSlider;
};

QCocoaSlider::QCocoaSlider(QWidget * parent /*= 0*/) : QCocoaWidget(parent)
{
    QSlider *slider = new QSlider(this);

    connect(slider, SIGNAL(valueChanged(int)), this, SIGNAL(valueChanged(int)));

    pimpl = new QCocoaSliderPrivate(this, slider);

    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(slider);
}

QSize QCocoaSlider::sizeHint() const
{
    return pimpl->realSlider->sizeHint();
}

void QCocoaSlider::setSliderType(SliderType type /*= LinearSlider*/)
{

}

void QCocoaSlider::setRange(int min, int max)
{
    pimpl->realSlider->setRange(min, max);
}

void QCocoaSlider::setOrientation(Qt::Orientation orientation)
{
    pimpl->realSlider->setOrientation(orientation);
}

void QCocoaSlider::setValue(int value)
{
    pimpl->realSlider->setValue(value);
}

void QCocoaSlider::setMaximum(int maxValue)
{
    pimpl->realSlider->setMaximum(maxValue);

}

void QCocoaSlider::setMinimum(int minValue)
{
    pimpl->realSlider->setMinimum(minValue);
}
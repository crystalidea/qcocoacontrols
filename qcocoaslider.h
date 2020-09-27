#ifndef qcocoaslider_h__
#define qcocoaslider_h__

#include <QPointer>
#include <QSlider>
#include "qcocoawidget.h"

class QCocoaSliderPrivate;

class QCocoaSlider : public QCocoaWidget
{
    Q_OBJECT

public:

    enum SliderType
    {
        LinearHorizontal = 0,
        LinearVertical = 1,
        CircularSlider = 2
    };

    QCocoaSlider(QWidget * parent = 0);

    virtual QSize sizeHint() const;

    int maximum() const;
    int minimum() const;

    void setMaximum(int maxValue);
    void setMinimum(int minValue);

    int value() const;

    void setAltIncrementValue(int increment);

    void setTickInterval(int ti);
    void setTickPosition(QSlider::TickPosition position);
    void setAllowsTickMarkValuesOnly(bool bValuesTicks);

public slots:

    void setOrientation(Qt::Orientation orientation);
    void setSliderType(SliderType type = LinearHorizontal);
    void setRange(int min, int max);
    void setValue(int value);

signals:

    void valueChanged(int value);

private:

    friend class QCocoaSliderPrivate;
    QPointer<QCocoaSliderPrivate> pimpl;
};

#endif // qcocoaslider_h__

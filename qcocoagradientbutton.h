#ifndef qcocoagradientbutton_h__
#define qcocoagradientbutton_h__

#include "qcocoawidget.h"
#include "qcocoabutton.h"
#include "qcocoasegmentedbutton.h"
#include <QPointer>

class QCocoaGradientButtonPrivate;

// A gradient button performs an instantaneous action related to a view, such as a source list
// https://developer.apple.com/library/mac/documentation/UserExperience/Conceptual/OSXHIGuidelines/ControlsButtons.html#//apple_ref/doc/uid/20000957-CH48-SW1

class QCocoaGradientButton: public QCocoaSegmentedButton
{
    Q_OBJECT

public:

    QCocoaGradientButton(QWidget *pParent = 0);
    ~QCocoaGradientButton();

    virtual QSize sizeHint() const;

    void attachToWidget(QWidget *w);

protected:

    bool eventFilter(QObject *, QEvent *);

private:

    friend class QCocoaGradientButtonPrivate;
    QPointer<QCocoaGradientButtonPrivate> pimpl;
    QWidget *widgetToAttachedTo;
};

#endif // qcocoagradientbutton_h__

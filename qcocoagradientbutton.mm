#include "qcocoagradientbutton.h"
#include "qcocoabutton.h"

#include <QEvent>

class QCocoaGradientButtonPrivate : public QObject
{
protected:

    QPointer<QCocoaGradientButton> parent;
    int m_nWidthWithoutLastSegment;

public:
    QCocoaGradientButtonPrivate(QCocoaGradientButton *pParent)
        : QObject(pParent), parent(pParent), m_nWidthWithoutLastSegment(0)
    {

    }

    ~QCocoaGradientButtonPrivate()
    {

    }

    friend class QCocoaGradientButton;
};

QCocoaGradientButton::QCocoaGradientButton(QWidget *parent)
    : QCocoaSegmentedButton(parent), widgetToAttachedTo(0)
{
    setSegmentStyle(QCocoaSegmentedButton::SegmentStyleSmallSquare);
    setTrackingMode(QCocoaSegmentedButton::NSSegmentSwitchTrackingMomentary);

    pimpl = new QCocoaGradientButtonPrivate(this);
}

QCocoaGradientButton::~QCocoaGradientButton()
{

}

bool QCocoaGradientButton::eventFilter(QObject *, QEvent *ev)
{
    if (ev->type() == QEvent::Resize)
    {
        setFixedSize(QWIDGETSIZE_MAX, QWIDGETSIZE_MAX); // remove constraints

        updateGeometry();
    }

    return false;
}

QSize QCocoaGradientButton::sizeHint() const
{
    QSize sz = QCocoaSegmentedButton::sizeHint();

    if (widgetToAttachedTo)
    {
        QCocoaGradientButton *p = const_cast<QCocoaGradientButton *>(this);

        int parentWidth = widgetToAttachedTo->width();

        sz.setWidth(parentWidth);

        p->setSegmentFixedWidth(segmentCount() - 1, parentWidth - pimpl->m_nWidthWithoutLastSegment);
    }

    return sz;
}

// the idea is taken from
// http://stackoverflow.com/questions/22586313/nstableview-with-buttons-like-in-system-preferences-using-only-interface-bui/22586314#22586314

void QCocoaGradientButton::attachToWidget(QWidget *w)
{
    Q_ASSERT(segmentCount() != 0);

    pimpl->m_nWidthWithoutLastSegment = sizeHint().width() + 1; // plus border (?)
    setSegmentCount(segmentCount() + 1);
    setSegmentEnabled(segmentCount() - 1, false);

    widgetToAttachedTo = w;

    w->installEventFilter(this);

    updateGeometry();
}

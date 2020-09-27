#include "qcocoabox.h"

#import <AppKit/NSBox.h>
#import <AppKit/NSSlider.h>

#import <Foundation/NSAutoreleasePool.h>

class QCocoaBoxPrivate : public QObject
{
protected:

    QPointer<QCocoaBox> parent;
    NSBox *nsBox;

public:
    QCocoaBoxPrivate(NSBox *pControl, QCocoaBox *pParent)
        : QObject(pParent), parent(pParent), nsBox(pControl)
    {

    }

    ~QCocoaBoxPrivate() { }

    friend class QCocoaBox;
};

QCocoaBox::QCocoaBox(QWidget * parent /*= 0*/) : QCocoaWidget(parent), contents(nullptr)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSBox *box = [[NSBox alloc] init];
    [box setBoxType:(NSBoxType)NSBoxPrimary];
    pimpl = new QCocoaBoxPrivate(box, this);

    setupLayout(box);

    setMinimumHeight(1); // for NSBoxSeparator

    [box release];

    [pool drain];
}

#define LEFT_RIGHT_MARGIN   10
#define TOP_MARGIN          20
#define BOTTOM_MARGIN       10

void QCocoaBox::setContentWidget(QWidget *widget)
{
    if (widget)
    {
        QMacCocoaViewContainer *p = container();

        if (p)
        {
            QHBoxLayout *layout = new QHBoxLayout(p);
            layout->setContentsMargins(QMargins(LEFT_RIGHT_MARGIN, TOP_MARGIN, LEFT_RIGHT_MARGIN, BOTTOM_MARGIN));
            layout->addWidget(widget);

            widget->adjustSize();

            QSize minSize = widget->size();
            minSize.setWidth(minSize.width() + LEFT_RIGHT_MARGIN*2);
            minSize.setHeight(minSize.height() + TOP_MARGIN + BOTTOM_MARGIN);

            setMinimumSize(minSize);

            widget->setPalette(Qt::transparent); // make sure it's transparent

            if (widget->layout())
                widget->layout()->setContentsMargins(QMargins(0,0,0,0)); // make sure to have no margins
        }
    }
}

QSize QCocoaBox::sizeHint() const
{
    QSize sz;

    NSRect frame = [pimpl->nsBox frame];
    sz = QSize(frame.size.width, ([pimpl->nsBox boxType] == (NSBoxType)NSBoxSeparator) ? 1 : frame.size.height);

    if (contents)
        sz = QSize(contents->width(), contents->height());

    return sz;
}

void QCocoaBox::setTitle(const QString &title)
{
    QMacAutoReleasePool pool;
    [pimpl->nsBox setTitle: title.toNSString()];
}

void QCocoaBox::setBoxType(BoxType type)
{
    [pimpl->nsBox setBoxType:(NSBoxType)type];
}

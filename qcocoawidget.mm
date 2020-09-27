#include "qcocoawidget.h"

#import "Foundation/Foundation.h"
#import "AppKit/NSView.h"
#import <AppKit/NSImage.h>

QCocoaWidget::QCocoaWidget(QWidget *parent) :
    QWidget(parent), view(0), m_bPlannedToBeInvisible(false)
{
    setProperty("setVisibleCustom", true); // for QWidgetHider
}

void QCocoaWidget::setupLayout(NSView *cocoaView)
{
    view = cocoaView;

    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setContentsMargins(0, 0, 0, 0);

    QMacCocoaViewContainer *pContainer = new QMacCocoaViewContainer(cocoaView, this);

    layout->addWidget(pContainer);
}

QMacCocoaViewContainer *QCocoaWidget::container() const
{
    QVBoxLayout *v = static_cast<QVBoxLayout *>(layout());

    return static_cast<QMacCocoaViewContainer *>(v->itemAt(0) ? v->itemAt(0)->widget() : nullptr);
}

void QCocoaWidget::setVisibleCustom(bool visible)
{
    if (view)
        [view setHidden: visible ? NO : YES];

    m_bPlannedToBeInvisible = !visible;
}

void QCocoaWidget::showEvent(QShowEvent *event)
{
    // при старте, если мы хотим, чтобы view было невидимым, необходим следущий код
    if (m_bPlannedToBeInvisible)
        setVisibleCustom(false);

    QWidget::showEvent(event);
}

void QCocoaWidget::changeEvent(QEvent *event)
{
    QWidget::changeEvent(event);

    [view setEnabled: isEnabled() ? YES: NO];
}

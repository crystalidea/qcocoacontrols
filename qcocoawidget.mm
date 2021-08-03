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

    QWidget *nativeWidget = QWidget::createWindowContainer(QWindow::fromWinId((WId)cocoaView), this);
    nativeWidget->setAttribute(Qt::WA_NativeWindow, true);

    layout->addWidget(nativeWidget);
}

QWidget *QCocoaWidget::nativeWidget() const
{
    QVBoxLayout *v = static_cast<QVBoxLayout *>(layout());

    return static_cast<QWidget *>(v->itemAt(0) ? v->itemAt(0)->widget() : nullptr);
}

void QCocoaWidget::setVisibleCustom(bool visible)
{
    if (view)
        [view setHidden: visible ? NO : YES];

    m_bPlannedToBeInvisible = !visible;
}

void QCocoaWidget::showEvent(QShowEvent *event)
{
    // upon startup if we'd want the widget to be displayed invisible
    if (m_bPlannedToBeInvisible)
        setVisibleCustom(false);

    QWidget::showEvent(event);
}

void QCocoaWidget::changeEvent(QEvent *event)
{
    QWidget::changeEvent(event);

    if ([view respondsToSelector:@selector(setEnabled:)])
        [view setEnabled: isEnabled() ? YES: NO];
}

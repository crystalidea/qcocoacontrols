#include "qcocoawidget.h"

#import "Foundation/Foundation.h"
#import "AppKit/NSView.h"
#import "AppKit/NSControl.h"

QCocoaWidget::QCocoaWidget(QWidget *parent) :
    QWidget(parent), view(0)
{

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

void QCocoaWidget::changeEvent(QEvent *event)
{
    if ([view isKindOfClass:[NSControl class]])
        [(NSControl *)view setEnabled: isEnabled() ? YES: NO];
    else
    {
        // TODO ?
    }

    QWidget::changeEvent(event);
}

#ifndef qcocoawidget_h__
#define qcocoawidget_h__

#include <QWidget>

#ifdef Q_OS_MAC

#include <QVBoxLayout>

Q_FORWARD_DECLARE_OBJC_CLASS(NSView);

class QCocoaWidget : public QWidget
{
    Q_OBJECT

public:

    explicit QCocoaWidget(QWidget *parent);
    ~QCocoaWidget() {}

    void setupLayout(NSView *cocoaView);

    QWidget *nativeWidget() const;

protected slots:



protected:

    void changeEvent(QEvent *event) override;

private:

    NSView *view;
};

#else

typedef QWidget QCocoaWidget;

#endif

#endif // qcocoawidget_h__

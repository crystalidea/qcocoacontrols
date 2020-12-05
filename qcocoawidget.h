#ifndef qcocoawidget_h__
#define qcocoawidget_h__

#include <QWidget>

#ifdef Q_OS_MAC

#include <QVBoxLayout>
#include <QMacCocoaViewContainer>

Q_FORWARD_DECLARE_OBJC_CLASS(NSImage);

class QCocoaWidget : public QWidget
{
    Q_OBJECT

public:

    explicit QCocoaWidget(QWidget *parent);
    ~QCocoaWidget() {}

    void setupLayout(NSView *cocoaView);

    QMacCocoaViewContainer *container() const;

protected slots:

    void setVisibleCustom(bool visible);

protected:

    virtual void showEvent(QShowEvent *event) override;
    virtual void changeEvent(QEvent *event) override;

private:

    NSView *view;

    bool m_bPlannedToBeInvisible; // скорее всего, Qt принудительно показывает виджет при старте
};

#else

typedef QWidget QCocoaWidget;

#endif

#endif // qcocoawidget_h__

#ifndef QCOCOABUTTONACTIONMENU_H
#define QCOCOABUTTONACTIONMENU_H

#include "qcocoabutton.h"

class QCocoaButtonActionMenu : public QCocoaButton
{
    Q_OBJECT

public:

#ifdef Q_OS_MAC

    explicit QCocoaButtonActionMenu(QWidget *parent);

    void setMenu(QMenu *menu) override;
    void setText(const QString &text) override;

    QString text() const { return _text;}

private:

    QString _text;

#else

    QCocoaButtonActionMenu(QWidget *parent) : QCocoaButton(parent) {}

#endif
};

#endif // QCOCOABUTTONACTIONMENU_H

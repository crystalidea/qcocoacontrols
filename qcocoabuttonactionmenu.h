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

    void setFixedWidth(int w); // если мы не хотим, чтобы кнопка себя растягивала при смене текста не ней
    int fixedWidth() const { return _fixedWidth; }

    QString	text() const { return _text;}

private:

    QString _text;
    int _fixedWidth = 0;

#else

    QCocoaButtonActionMenu(QWidget *parent) : QCocoaButton(parent) {}

#endif
};

#endif // QCOCOABUTTONACTIONMENU_H

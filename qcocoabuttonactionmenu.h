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

    // Width the button needs to show text in full, for giving it one width for all the titles it switches between.
    // The arrow and the margins take about 48 pt under Liquid Glass and less in the classic design, so a width made of
    // the text width and a fixed allowance cuts the title in one of them
    int widthForText(const QString &text) const;

private:

    QString _text;

#else

    QCocoaButtonActionMenu(QWidget *parent) : QCocoaButton(parent) {}

#endif
};

#endif // QCOCOABUTTONACTIONMENU_H

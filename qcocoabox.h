#ifndef qcocoabox_h__
#define qcocoabox_h__

#include <QPointer>
#include "qcocoawidget.h"

class QCocoaBoxPrivate;

class QCocoaBox : public QCocoaWidget
{
    Q_OBJECT

public:

    enum BoxType {
       NSBoxPrimary   = 0, // Specifies the primary box appearance. This is the default box type.
       NSBoxSecondary = 1, // Specifies the secondary box appearance.
       NSBoxSeparator = 2, // Specifies that the box is a separator.
       NSBoxOldStyle  = 3  // Specifies that the box is an OS X v10.2–style box.
    };

    QCocoaBox(QWidget * parent = 0);

    virtual QSize sizeHint() const;

public:

    void setTitle(const QString &title);
    void setBoxType(BoxType type);

    void setContentWidget(QWidget *widget);

signals:

private:

    friend class QCocoaBoxPrivate;
    QPointer<QCocoaBoxPrivate> pimpl;
    QWidget *contents;
};

#endif // qcocoabox_h__

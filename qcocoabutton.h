#ifndef qcocoabutton_h__
#define qcocoabutton_h__

#include "qcocoawidget.h"
#include "qcocoaicon.h"

#include <QPointer>
#include <QPushButton>

class CocoaButtonPrivate;

class QCocoaButton : public QCocoaWidget
{
    Q_OBJECT

public:

    enum BezelStyle { // matches NSBezelStyle
        Rounded           = 1,
        RegularSquare     = 2, /* RegularSquare (Bevel buttons) are not recommended for use in apps that run in OS X v10.7 and later.
                                  You should consider alternatives, such as gradient buttons and segmented controls */
        Disclosure        = 5,
        ShadowlessSquare  = 6,
        Circular          = 7, /* Round buttons are not recommended for use in apps that run in OS X v10.7 and later.
                                  You should consider an alternative, such as a gradient button */
        TexturedSquare    = 8,
        HelpButton        = 9,
        SmallSquare       = 10,
        TexturedRounded   = 11,
        RoundRect         = 12,
        Recessed          = 13,
        RoundedDisclosure = 14,
        Inline            = 15
    };

    enum IconPosition { // matches NSCellImagePosition)
        NoIcon = 0,
        IconOnly = 1,
        IconLeft = 2,
        IconRight  = 3,
        IconBelow  = 4,
        IconAbove  = 5,
        IconOverlaps   = 6
        //NSImageLeading  API_AVAILABLE(macosx(10.12)) = 7,
        //NSImageTrailing API_AVAILABLE(macosx(10.12)) = 8
    };

    explicit QCocoaButton(QWidget *parent);
    ~QCocoaButton();

protected:

    QCocoaButton(QWidget *parent, CocoaButtonPrivate *customPrivate);

public slots:

    virtual void setText(const QString &text);
    void setIcon(const QIcon &image);

#ifdef Q_OS_MAC
    void setIcon(QCocoaIcon::StandardIcon icon);
#endif

    void setIconPosition(IconPosition pos);

    void setChecked(bool checked);

    void setToolTip(const QString& strTip);

public:

    virtual void setMenu(QMenu *menu);

    void setBezelStyle(BezelStyle bezelStyle = Rounded);

    void setCheckable(bool checkable);
    bool isChecked();

    void initFrom(QPushButton * /* pOther */) {}

    QSize sizeHint() const override;

    QAbstractButton *abstractButton(); // helper method when you need to insert QCocoaButton into QDialogButtonBox

signals:
    void clicked(bool checked = false);

protected:

    friend class CocoaButtonPrivate;
    std::unique_ptr<CocoaButtonPrivate> pimpl;
    BezelStyle style;
};

#endif // qcocoabutton_h__

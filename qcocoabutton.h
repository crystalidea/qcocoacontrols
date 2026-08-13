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

    void showEvent(QShowEvent *event) override;

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

    // Helper for inserting a QCocoaButton into a QDialogButtonBox, which accepts nothing but
    // QAbstractButton *. READ THIS BEFORE USING IT:
    //
    // On macOS the returned pointer is a lie. QCocoaButton derives from QWidget, not from
    // QAbstractButton, so abstractButton() just reinterpret_casts 'this'. It happens to work
    // because the QWidget subobject sits at offset 0, which makes the pointer value correct for
    // everything QDialogButtonBox actually does with it: setParent(), layout()->addWidget() and
    // the connect() to QObject::destroyed.
    //
    // What you must NOT do on macOS is call any QAbstractButton method on the result -- setText(),
    // isChecked(), setShortcut(), setCheckable() and friends all start with Q_D(QAbstractButton),
    // which would run over a QWidgetPrivate and read/write past the end of it.
    //
    // Also note that QDialogButtonBox's own connect to QAbstractButton::clicked is silently dead
    // here: the signal index it computes belongs to QAbstractButton, while this class emits its
    // own clicked() at a different index. So accepted()/rejected()/helpRequested() will never fire
    // for such a button -- connect to QCocoaButton::clicked directly instead. In other words, the
    // button box can lay this button out, but it cannot manage it.
    //
    // On other platforms the returned pointer is a real QPushButton owned by this widget, so none
    // of the above applies -- but QDialogButtonBox::addButton() will reparent it out of the
    // QCocoaButton, leaving the wrapper empty.
    QAbstractButton *abstractButton();

signals:
    void clicked(bool checked = false);

protected:

    friend class CocoaButtonPrivate;
    std::unique_ptr<CocoaButtonPrivate> pimpl;
    BezelStyle _bezelStyle = BezelStyle::Rounded;
};

#endif // qcocoabutton_h__

#ifndef QCocoaMessageBox_h__
#define QCocoaMessageBox_h__

#include <QtWidgets/QMessageBox>

// On macOS the message is shown through NSAlert rather than a dialog built from Qt widgets.
// Qt can put up a native alert on its own (QCocoaMessageDialog, since 6.5), but that is no
// replacement for this class:
//
// 1. Qt switches its native path off for subclasses. On QEvent::Polish QMessageBox gives
//    itself Option::DontUseNativeDialog when metaObject() differs from
//    QMessageBox::staticMetaObject and no option has been set explicitly - which is what
//    setOption() and setOptions() record. So any subclass - QCocoaMessageBox itself, and
//    whatever derives from it - gets the plain widget dialog out of Qt unless it calls one
//    of those two setters before the box is polished.
//
// 2. A sheet on the parent window, the panel that slides out from under its title bar.
//    QDialog::exec() makes the dialog modal for the whole application unless the caller set
//    Qt::WindowModal on it beforehand, while QCocoaMessageDialog puts up a sheet only for
//    Qt::WindowModal, so by default the message comes up through Qt as a separate window in
//    the middle of the screen. Here it is attached to the parent window, as long as that
//    window is visible and not minimized.
//
// 3. The sheet works on macOS 26 (Tahoe) too. Qt 6.12 puts up no sheet there at all: the
//    buttons of its window modal alert stop responding to the mouse, so for Qt::WindowModal
//    QCocoaMessageDialog::show() gives up and lets the widget dialog take over. The
//    difference is who drives the sheet - Qt runs a Qt event loop of its own, while here the
//    alert window goes through AppKit's modal loop, where the buttons keep working.
//
// 4. The application is brought to the front: [NSApp activateIgnoringOtherApps:YES]. For a
//    program that lives in the menu bar the message would otherwise easily end up behind
//    other windows. Qt does nothing of the sort.
//
// 5. Mnemonics are stripped from standard buttons only. Qt cleans '&' out of every title,
//    while custom titles come from the localization and from the license server, where an
//    ampersand can be a literal character of the text.
//
// 6. The "don't ask again" checkbox is drawn in the small system font, the way macOS draws
//    it in its own messages; with the QCheckBox text left empty, macOS supplies the title.
//
// Everything else deliberately follows Qt's native path: the role-based button layout taken
// from QPlatformDialogHelper::buttonLayout, the choice of the default button, click() on the
// pressed button, and the fallback to the widget dialog where NSAlert plainly cannot cope
// (rich text, a non-empty detailedText()). The escape button is picked the same way, with one
// deliberate exception: among NoRole buttons only the standard No gets Escape here, while Qt
// gives it to a lone NoRole button of any kind - see resolveEscapeButton().
class QCocoaMessageBox : public QMessageBox
{
    Q_OBJECT

public:

    using QMessageBox::QMessageBox;

    bool isCheckBoxChecked() const {
        return checkBox() && checkBox()->isChecked();
    }

#ifdef Q_OS_MAC
    int exec() override;

    static QMessageBox::StandardButton critical(QWidget *parent, const QString &title, const QString &text, QMessageBox::StandardButtons buttons = QMessageBox::Ok, QMessageBox::StandardButton defaultButton = NoButton);
    static QMessageBox::StandardButton information(QWidget *parent, const QString &title, const QString &text, QMessageBox::StandardButtons buttons = QMessageBox::Ok, QMessageBox::StandardButton defaultButton = NoButton);
    static QMessageBox::StandardButton question(QWidget *parent, const QString &title, const QString &text, QMessageBox::StandardButtons buttons = QMessageBox::StandardButtons(QMessageBox::Yes | QMessageBox::No), QMessageBox::StandardButton defaultButton = QMessageBox::NoButton);
    static QMessageBox::StandardButton warning(QWidget *parent, const QString &title, const QString &text, QMessageBox::StandardButtons buttons = QMessageBox::Ok, QMessageBox::StandardButton defaultButton = NoButton);

#endif

private:

};

#endif // QCocoaMessageBox_h__

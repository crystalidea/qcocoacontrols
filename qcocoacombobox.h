#ifndef qcocoacombobox_h__
#define qcocoacombobox_h__

#include <QComboBox>

#ifdef Q_OS_MAC

#include <memory>

class QCocoaComboBoxPrivate;

// A QComboBox whose list opens as a native NSMenu, the way the menu of NSPopUpButton does: the current item is placed
// over the text of the combo box, and under Liquid Glass the menu gets the glass of the system menus. The menu carries
// the item texts, icons, disabled items, a check mark at the current item and the separators of
// QComboBox::insertSeparator(), and is at least as wide as the combo box.
//
// Qt 6.8 can show a native list itself, but only for every combo box of the app at once, through the style hint
// SH_ComboBox_UseNativePopup, and it turns separators into empty items. An editable combo box keeps the list Qt draws,
// as it goes together with the completer of the line edit.

class QCocoaComboBox : public QComboBox
{
    Q_OBJECT

public:

    explicit QCocoaComboBox(QWidget *parent = nullptr);
    ~QCocoaComboBox() override;

    void showPopup() override;

private:

    std::unique_ptr<QCocoaComboBoxPrivate> _popup;
};

#else

typedef QComboBox QCocoaComboBox;

#endif

#endif // qcocoacombobox_h__

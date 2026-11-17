#include "pch.h"
#include "qcocoamessagebox.h"
#include "qcocoaicon.h"

#include <QtGui/qtextdocument.h> // Qt::mightBeRichText

#import <AppKit/AppKit.h>

namespace {

// Mnemonic stripping mirrors QPlatformTheme::removeMnemonics: that function is declared in a
// private QPA header, and this library pulls in no private Qt headers (the same reason it
// carries its own QMacAutoReleasePool). The rules: a lone '&' is dropped, "&&" collapses
// to a single '&', and a "(&X)" group is removed along with the whitespace before it
QString removeMnemonics(const QString &original)
{
    const auto mnemonicInParentheses = [](QStringView text)
    {
        // Fullwidth parentheses count as regular ones: that is how mnemonics are written
        // in Chinese, Japanese and Korean translations
        constexpr char16_t wideOpen = 0xFF08;
        constexpr char16_t wideClose = 0xFF09;

        Q_ASSERT(text.size() == 4);

        if (!text.startsWith(u'(') && !text.startsWith(QChar(wideOpen)))
            return false;

        if (text[1] != u'&' || text[2] == u'&')
            return false;

        return text.endsWith(u')') || text.endsWith(QChar(wideClose));
    };

    QString returnText(original.size(), u'\0');
    int finalDest = 0;
    QStringView text(original);

    while (!text.isEmpty())
    {
        if (text.startsWith(u'&'))
        {
            text = text.sliced(1);

            if (text.isEmpty())
                break;
        }
        else if (text.size() >= 4 && mnemonicInParentheses(text.first(4)))
        {
            text = text.sliced(4);

            while (finalDest > 0 && returnText.at(finalDest - 1).isSpace())
                --finalDest;

            continue;
        }

        returnText[finalDest] = text.front();
        text = text.sliced(1);
        ++finalDest;
    }

    returnText.truncate(finalDest);

    return returnText;
}

// In the macOS layout the second and every further AcceptRole button sits to the left of
// the primary one. QMessageBox::ButtonRole has no value for that, so take the first free one
constexpr int kAlternateRole = QMessageBox::NRoles;

struct RoleSlot
{
    int role;

    // Set for exactly the roles that the MacLayout row of QPlatformDialogHelper::buttonLayout
    // marks with Reverse: such a role is walked backwards, so that after the whole list is
    // added to the alert right to left, the first of its buttons ends up rightmost
    bool reverse;
};

// Button order in a macOS alert, left to right: the MacLayout row of the
// QPlatformDialogHelper::buttonLayout table, minus its Stretch separator - placement inside
// the alert is AppKit's business, only the relative order is ours. Help, Reset, Apply and
// Action come first; counting from the other end, Yes is rightmost, then No, then Accept
const RoleSlot kMacRoleOrder[] = {
    { QMessageBox::HelpRole,        false },
    { QMessageBox::ResetRole,       false },
    { QMessageBox::ApplyRole,       false },
    { QMessageBox::ActionRole,      false },
    { QMessageBox::DestructiveRole, true  },
    { kAlternateRole,               true  },
    { QMessageBox::RejectRole,      true  },
    { QMessageBox::AcceptRole,      true  },
    { QMessageBox::NoRole,          true  },
    { QMessageBox::YesRole,         true  },
};

struct ButtonEntry
{
    QAbstractButton *button;
    int role;
};

// The dialog buttons with their roles. QMessageBox::buttons() hands them out grouped by
// role, and within one role in the order they were added
QList<ButtonEntry> collectButtons(const QMessageBox *pMsgBox)
{
    QList<ButtonEntry> entries;
    bool bSeenAccept = false;

    const QList<QAbstractButton *> myButtons = pMsgBox->buttons();

    for (QAbstractButton *btn : myButtons)
    {
        int role = pMsgBox->buttonRole(btn);

        if (role == QMessageBox::AcceptRole)
        {
            if (bSeenAccept)
                role = kAlternateRole;
            else
                bSeenAccept = true;
        }

        entries.append({ btn, role });
    }

    return entries;
}

// The same list, laid out left to right by the macOS rules
QList<ButtonEntry> orderedForMacLayout(const QList<ButtonEntry> &entries)
{
    QList<ButtonEntry> ordered;
    ordered.reserve(entries.size());

    for (const RoleSlot &slot : kMacRoleOrder)
    {
        if (slot.reverse)
        {
            for (auto it = entries.crbegin(); it != entries.crend(); ++it)
            {
                if (it->role == slot.role)
                    ordered.append(*it);
            }
        }
        else
        {
            for (const ButtonEntry &entry : entries)
            {
                if (entry.role == slot.role)
                    ordered.append(entry);
            }
        }
    }

    // A role missing from the layout should not happen: QMessageBox rejects a button with
    // InvalidRole. Still, losing a button is worse than placing it wrong
    if (ordered.size() != entries.size())
    {
        for (const ButtonEntry &entry : entries)
        {
            bool bPlaced = false;

            for (const ButtonEntry &placed : ordered)
            {
                if (placed.button == entry.button)
                {
                    bPlaced = true;
                    break;
                }
            }

            if (!bPlaced)
                ordered.append(entry);
        }
    }

    return ordered;
}

// The button that Return activates. A null result means "let AppKit decide", which makes the
// first added button - the rightmost one - the default
QAbstractButton *resolveDefaultButton(const QMessageBox *pMsgBox, const QList<ButtonEntry> &entries)
{
    if (QAbstractButton *btn = pMsgBox->defaultButton())
        return btn;

    // The first AcceptRole button; after the role reassignment there is at most one of them,
    // and a box with just Yes and No has none
    for (const ButtonEntry &entry : entries)
    {
        if (entry.role == QMessageBox::AcceptRole)
            return entry.button;
    }

    return nullptr;
}

// The button that Escape activates. The checks follow QMessageBoxPrivate::detectEscapeButton,
// which Qt runs from setVisible() before it decides on a native dialog, so the button it picks
// reaches the NSAlert as well. Here it never runs: this path puts up the alert without ever
// making the QMessageBox visible. The last check is the fallback rule of Qt's native alert -
// with several RejectRole buttons, Escape goes to the first one. The details button step is
// not needed - a non-empty detailedText() never gets this far
QAbstractButton *resolveEscapeButton(const QMessageBox *pMsgBox, const QList<ButtonEntry> &entries)
{
    if (QAbstractButton *btn = pMsgBox->escapeButton())
        return btn;

    if (QAbstractButton *btn = pMsgBox->button(QMessageBox::Cancel))
        return btn;

    if (entries.size() == 1)
        return entries.first().button;

    QAbstractButton *pFirstReject = nullptr;
    bool bSeveralRejects = false;

    for (const ButtonEntry &entry : entries)
    {
        if (entry.role != QMessageBox::RejectRole)
            continue;

        if (pFirstReject)
        {
            bSeveralRejects = true;
            break;
        }

        pFirstReject = entry.button;
    }

    if (pFirstReject && !bSeveralRejects)
        return pFirstReject;

    // The standard No button gets Escape: it really does mean refusal. A custom button with the
    // same role does not: on custom buttons NoRole usually means nothing more than "not Accept",
    // and Escape must not fire an action. At this step Qt gives Escape to a NoRole button of any
    // kind, but only when exactly one such button exists
    if (QAbstractButton *btn = pMsgBox->button(QMessageBox::No))
        return btn;

    // Qt's native alert gives Escape to the first RejectRole button it adds, and adding reverses
    // the order of a role a second time, so its pick is the first RejectRole button in entries -
    // the same one as here, unless the role holds both standard and custom buttons, since Qt's
    // own list puts all the standard ones first. Null when no RejectRole button exists at all
    return pFirstReject;
}

int processMessageBoxResult(NSAlert *alert, NSInteger retCode, QMessageBox *pMsgBox, const QList<QAbstractButton *> &addedButtons)
{
    QCheckBox *checkBtn = pMsgBox->checkBox();

    if (checkBtn) // mirror unconditionally, the user may have unchecked a pre-checked box
        checkBtn->setChecked([[alert suppressionButton] state] == NSControlStateValueOn);

    // We set the button tags ourselves, so the response is a button's index in the order they
    // were added. Anything outside that range (the system NSModalResponse* values, a sheet
    // closed by someone else's code) is not a button
    const int nButtonIndex = static_cast<int>(retCode - NSAlertFirstButtonReturn);

    if (nButtonIndex < 0 || nButtonIndex >= addedButtons.size())
        return QMessageBox::NoButton;

    QAbstractButton *btn = addedButtons.at(nButtonIndex);

    // The code of a standard button is read before the click: a receiver of clicked may delete
    // the box, and with it the button, so neither is touched after the click
    const int nStandardButton = pMsgBox->standardButton(btn);

    // The click is not optional: it is what sets clickedButton() and emits the clicked signal
    // that callers rely on, and QMessageBox closes the dialog itself on that same signal
    btn->click();

    return nStandardButton;
}

} // namespace

int QCocoaMessageBox::exec()
{
    QMacAutoReleasePool pool;

    // Make us the active application
    [NSApp activateIgnoringOtherApps:YES];

    // NSAlert has neither a separate details section nor rich text: hand such a message over
    // to the ordinary Qt dialog, which draws both
    bool bFallbackToWidgetDialog = Qt::mightBeRichText(text()) || Qt::mightBeRichText(informativeText());

#if QT_CONFIG(textedit)
    bFallbackToWidgetDialog = bFallbackToWidgetDialog || !detailedText().isEmpty();
#endif

    if (bFallbackToWidgetDialog)
        return QMessageBox::exec();

    NSAlert *alert = [[[NSAlert alloc] init] autorelease];

    QString txt = text();
    QString infoText = informativeText();

    if (txt.size())
        [alert setMessageText: txt.toNSString()];

    if (infoText.size())
        [alert setInformativeText: infoText.toNSString()];

    // Only the critical style changes the picture: AppKit badges the application icon with a
    // caution sign. Warning and informational look the same
    if (icon() == QMessageBox::Critical)
        alert.alertStyle = NSAlertStyleCritical;
    else if (icon() == QMessageBox::Warning)
        alert.alertStyle = NSAlertStyleWarning;
    else
        alert.alertStyle = NSAlertStyleInformational;

    // A picture of our own only when it was set explicitly: setIcon() fills iconPixmap() too,
    // but with an image from the Qt style, which looks foreign in a native alert. An explicit
    // setIconPixmap() resets icon() to NoIcon, which is how the two are told apart
    if (icon() == QMessageBox::NoIcon && !iconPixmap().isNull())
        alert.icon = QCocoaIcon::imageFromQIcon(iconPixmap());

    QCheckBox *checkBtn = checkBox();

    if (checkBtn)
    {
        [alert setShowsSuppressionButton:YES];

        // use small checkbox, it's prettier
        NSCell *cell = [[alert suppressionButton] cell];
        [cell setControlSize:NSControlSizeSmall];
        [cell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];

        if (checkBtn->isChecked())
            [cell setState: NSControlStateValueOn];

        // if we don't supply QCheckBox text, there will be a default one from macOS

        if (checkBtn->text().size())
            [cell setTitle: checkBtn->text().toNSString()];
    }

    const QList<ButtonEntry> entries = collectButtons(this);

    QAbstractButton *pDefaultButton = resolveDefaultButton(this, entries);
    QAbstractButton *pEscapeButton = resolveEscapeButton(this, entries);

    QList<QAbstractButton *> addedButtons;
    addedButtons.reserve(entries.size());

    // addButtonWithTitle: places buttons right to left, so the list laid out left to right is
    // added starting from its end
    const QList<ButtonEntry> ordered = orderedForMacLayout(entries);

    for (auto it = ordered.crbegin(); it != ordered.crend(); ++it)
    {
        QAbstractButton *btn = it->button;

        // Mnemonics are stripped from standard buttons only: their titles come from the Qt theme
        // with the ampersands in them ("&Yes"). In titles of our own - and those come from the
        // localization and from the license server - an ampersand can be a literal character
        const bool bStandardButton = standardButton(btn) != QMessageBox::NoButton;
        const QString title = bStandardButton ? removeMnemonics(btn->text()) : btn->text();

        NSButton *addedButton = [alert addButtonWithTitle: title.toNSString()];

        // We define the alert's response ourselves: let it be the button's index in the order they
        // were added. Reading the response as an index into buttons() would be wrong - that list
        // is not kept in this order
        addedButton.tag = NSAlertFirstButtonReturn + addedButtons.size();
        addedButtons.append(btn);

        if (it->role == QMessageBox::DestructiveRole)
            addedButton.hasDestructiveAction = YES;

        // By default AppKit gives Return to the first added button and Escape to any button
        // titled "Cancel", so the key equivalents have to be cleared as well as set
        if (btn == pDefaultButton)
            addedButton.keyEquivalent = @"\r";
        else if ([addedButton.keyEquivalent isEqualToString:@"\r"])
            addedButton.keyEquivalent = @"";

        // Escape does not override Return, which is how AppKit behaves too. Escape is spelled as an
        // octal code because \e is a GNU extension, not a standard escape sequence
        if (btn == pEscapeButton && ![addedButton.keyEquivalent isEqualToString:@"\r"])
            addedButton.keyEquivalent = @"\033";
        else if ([addedButton.keyEquivalent isEqualToString:@"\033"])
            addedButton.keyEquivalent = @"";
    }

    // No default button was set and no role picked one: restore the AppKit rule, where the
    // first added - that is, the rightmost - button becomes the default
    if (!pDefaultButton)
        alert.buttons.firstObject.keyEquivalent = @"\r";

    // Qt's event dispatcher keeps running inside the AppKit modal loop, which means deferred
    // deletions get delivered: the dialog may have been destroyed along with its parent while
    // the message stood on screen. There is then nothing left to read the response from
    QPointer<QMessageBox> guard(this);

    NSInteger retCode = NSModalResponseCancel;

    QWidget *pParent = qobject_cast<QWidget *>(parent());

    // A sheet is shown only for a window that is visible and not minimized: winId() forces the
    // window into existence, and a sheet slides out from under the parent's title bar - for a
    // hidden or minimized parent it would stay invisible, with the program stuck in a modal loop
    if (pParent && pParent->window()->isVisible() && !pParent->window()->isMinimized())
    {
        NSView *view = reinterpret_cast<NSView *>(pParent->window()->winId());
        NSWindow *wnd = [view window];

        [alert beginSheetModalForWindow:wnd
                      completionHandler:^(NSInteger code) {
                          [NSApp stopModalWithCode:code];
                      }];

        retCode = [NSApp runModalForWindow:[alert window]]; // uses AppKit, event loop not Qt
    }
    else
    {
        // runModal is not supposed to return NSModalResponseContinue, but per QTBUG-114546 it
        // sometimes does: it means "the modal session is still running"
        do
        {
            retCode = [alert runModal];
        }
        while (retCode == NSModalResponseContinue);
    }

    if (!guard)
        return QMessageBox::NoButton;

    return processMessageBoxResult(alert, retCode, this, addedButtons);
}

QMessageBox::StandardButton QCocoaMessageBox::critical(QWidget *parent, const QString &title, const QString &text, QMessageBox::StandardButtons buttons, QMessageBox::StandardButton defaultButton)
{
    QCocoaMessageBox msgBox(parent);

    msgBox.setIcon(QMessageBox::Critical);
    msgBox.setWindowTitle(title);
    msgBox.setText(text);
    msgBox.setStandardButtons(buttons);
    msgBox.setDefaultButton(defaultButton);

    return (QMessageBox::StandardButton)msgBox.exec();
}

QMessageBox::StandardButton QCocoaMessageBox::information(QWidget *parent, const QString &title, const QString &text, QMessageBox::StandardButtons buttons, QMessageBox::StandardButton defaultButton)
{
    QCocoaMessageBox msgBox(parent);

    msgBox.setIcon(QMessageBox::Information);
    msgBox.setWindowTitle(title);
    msgBox.setText(text);
    msgBox.setStandardButtons(buttons);
    msgBox.setDefaultButton(defaultButton);

    return (QMessageBox::StandardButton)msgBox.exec();
}

QMessageBox::StandardButton QCocoaMessageBox::question(QWidget *parent, const QString &title, const QString &text, QMessageBox::StandardButtons buttons, QMessageBox::StandardButton defaultButton)
{
    QCocoaMessageBox msgBox(parent);

    msgBox.setIcon(QMessageBox::Question);
    msgBox.setWindowTitle(title);
    msgBox.setText(text);
    msgBox.setStandardButtons(buttons);
    msgBox.setDefaultButton(defaultButton);

    return (QMessageBox::StandardButton)msgBox.exec();
}

QMessageBox::StandardButton QCocoaMessageBox::warning(QWidget *parent, const QString &title, const QString &text, QMessageBox::StandardButtons buttons, QMessageBox::StandardButton defaultButton)
{
    QCocoaMessageBox msgBox(parent);

    msgBox.setIcon(QMessageBox::Warning);
    msgBox.setWindowTitle(title);
    msgBox.setText(text);
    msgBox.setStandardButtons(buttons);
    msgBox.setDefaultButton(defaultButton);

    return (QMessageBox::StandardButton)msgBox.exec();
}

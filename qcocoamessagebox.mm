#include "pch.h"
#include "qcocoamessagebox.h"
#include "qcocoaicon.h"

#include <QtGui/qtextdocument.h> // Qt::mightBeRichText

#import <AppKit/AppKit.h>

namespace {

// Снятие мнемоник повторяет QPlatformTheme::removeMnemonics: та объявлена в приватном
// заголовке QPA, а приватные заголовки Qt библиотека не подключает (ради этого же здесь
// живёт свой QMacAutoReleasePool). Правила: одиночный '&' выбрасывается, из "&&" остаётся
// один '&', группа вида "(&X)" удаляется вместе с пробелами перед ней
QString removeMnemonics(const QString &original)
{
    const auto mnemonicInParentheses = [](QStringView text)
    {
        // полноширинные скобки считаются равнозначными обычным: так мнемоники пишут
        // в переводах для китайского, японского и корейского
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

// Вторая и каждая следующая кнопка с AcceptRole в раскладке macOS стоит левее основной.
// Своего значения в QMessageBox::ButtonRole для этого нет, поэтому берём первое свободное
constexpr int kAlternateRole = QMessageBox::NRoles;

struct RoleSlot
{
    int role;

    // кнопки одной роли перебираются с конца: их взаимный порядок должен сохраниться
    // после того, как весь список развернётся при добавлении в алерт
    bool reverse;
};

// Порядок кнопок в алерте macOS, слева направо: повторяет строку MacLayout таблицы
// QPlatformDialogHelper::buttonLayout. Help, Reset, Apply и Action уходят в левую группу,
// остальные - в правую, где самая правая роль Yes, перед ней No, перед ней Accept
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

// Кнопки диалога с ролями. QMessageBox::buttons() отдаёт их сгруппированными по роли,
// а внутри одной роли - в порядке добавления
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

// Тот же список, разложенный по правилам macOS слева направо
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

    // роли, которой нет в раскладке, быть не должно: QMessageBox не принимает кнопку
    // с InvalidRole. Но потерять кнопку хуже, чем поставить её не на место
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

// Кнопка, которую закрывает Return. Пустой результат значит "решает AppKit", то есть
// основной станет первая добавленная, она же самая правая
QAbstractButton *resolveDefaultButton(const QMessageBox *pMsgBox, const QList<ButtonEntry> &entries)
{
    if (QAbstractButton *btn = pMsgBox->defaultButton())
        return btn;

    // первая кнопка с AcceptRole; после переназначения роли такая в списке ровно одна
    for (const ButtonEntry &entry : entries)
    {
        if (entry.role == QMessageBox::AcceptRole)
            return entry.button;
    }

    return nullptr;
}

// Кнопка, которую нажимает Escape. Порядок проверок - как в QMessageBoxPrivate::detectEscapeButton
// (она вызывается только при показе через QDialog, то есть на этом пути не работает), а последним
// идёт запасное правило нативного алерта Qt: при нескольких кнопках с RejectRole Escape достаётся
// первой из них. Шаг про кнопку подробностей не нужен - при непустом detailedText() сюда не доходит
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

    // Стандартной кнопке No Escape полагается: она и значит отказ. Своей кнопке с этой же
    // ролью - нет, роль NoRole у таких кнопок обычно стоит просто как "не Accept", и Escape
    // не должен запускать действие. Qt тут отдаёт Escape любой единственной кнопке с NoRole
    if (QAbstractButton *btn = pMsgBox->button(QMessageBox::No))
        return btn;

    // В порядке добавления в алерт первая кнопка роли с флагом reverse идёт там же, где и в
    // entries, так что это та же кнопка, которую выбрал бы Qt
    return pFirstReject;
}

int processMessageBoxResult(NSAlert *alert, NSInteger retCode, QMessageBox *pMsgBox, const QList<QAbstractButton *> &addedButtons)
{
    QCheckBox *checkBtn = pMsgBox->checkBox();

    if (checkBtn) // mirror unconditionally, the user may have unchecked a pre-checked box
        checkBtn->setChecked([[alert suppressionButton] state] == NSControlStateValueOn);

    // tag кнопки мы задавали сами, поэтому ответ - это её номер в порядке добавления.
    // Всё, что в этот диапазон не попало (системные NSModalResponse*, лист, закрытый
    // чужим кодом), кнопкой не является
    const int nButtonIndex = static_cast<int>(retCode - NSAlertFirstButtonReturn);

    if (nButtonIndex < 0 || nButtonIndex >= addedButtons.size())
        return QMessageBox::NoButton;

    QAbstractButton *btn = addedButtons.at(nButtonIndex);

    // Нажать кнопку обязательно: на этом держатся и clickedButton(), и сигнал clicked,
    // которым пользуются вызывающие. По этому же сигналу QMessageBox закрывает диалог сам.
    // Для стандартной кнопки дополнительно возвращаем её код
    btn->click();

    return pMsgBox->standardButton(btn);
}

} // namespace

int QCocoaMessageBox::exec()
{
    QMacAutoReleasePool pool;

    // Make us the active application
    [NSApp activateIgnoringOtherApps:YES];

    // NSAlert не умеет ни отдельного блока подробностей, ни разметки в тексте: такое
    // сообщение отдаём обычному диалогу Qt, он рисует и то, и другое
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

    // Картинку меняет только стиль critical: AppKit вешает на иконку программы
    // предупреждающий значок. Warning и informational выглядят одинаково
    if (icon() == QMessageBox::Critical)
        alert.alertStyle = NSAlertStyleCritical;
    else if (icon() == QMessageBox::Warning)
        alert.alertStyle = NSAlertStyleWarning;
    else
        alert.alertStyle = NSAlertStyleInformational;

    // Своя картинка - только если её задали явно: setIcon() тоже заполняет iconPixmap(),
    // но картинкой из стиля Qt, а она в нативном алерте выглядит чужой. Явный
    // setIconPixmap() сбрасывает icon() в NoIcon, по этому их и отличаем
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

    // addButtonWithTitle: кладёт кнопки справа налево, поэтому разложенный слева направо
    // список добавляем с конца
    const QList<ButtonEntry> ordered = orderedForMacLayout(entries);

    for (auto it = ordered.crbegin(); it != ordered.crend(); ++it)
    {
        QAbstractButton *btn = it->button;

        // Мнемоники снимаем только у стандартных кнопок: их подписи приходят из темы Qt
        // вместе с амперсандами ("&Yes"). В своих подписях - а они приходят из локализации
        // и от сервера лицензий - амперсанд может быть настоящим символом текста
        const bool bStandardButton = standardButton(btn) != QMessageBox::NoButton;
        const QString title = bStandardButton ? removeMnemonics(btn->text()) : btn->text();

        NSButton *addedButton = [alert addButtonWithTitle: title.toNSString()];

        // Ответ алерта задаём сами: пусть это будет номер кнопки в порядке добавления.
        // Разбирать ответ как номер в buttons() нельзя - тот список в этом порядке не лежит
        addedButton.tag = NSAlertFirstButtonReturn + addedButtons.size();
        addedButtons.append(btn);

        if (it->role == QMessageBox::DestructiveRole)
            addedButton.hasDestructiveAction = YES;

        // AppKit сам отдаёт Return первой добавленной кнопке, а Escape - кнопке с подписью
        // "Cancel", поэтому назначения надо не только ставить, но и снимать
        if (btn == pDefaultButton)
            addedButton.keyEquivalent = @"\r";
        else if ([addedButton.keyEquivalent isEqualToString:@"\r"])
            addedButton.keyEquivalent = @"";

        // Escape не перебивает Return: так же ведёт себя и AppKit. Escape записан восьмеричным
        // кодом, потому что \e - это расширение GNU, а не стандартная последовательность
        if (btn == pEscapeButton && ![addedButton.keyEquivalent isEqualToString:@"\r"])
            addedButton.keyEquivalent = @"\033";
        else if ([addedButton.keyEquivalent isEqualToString:@"\033"])
            addedButton.keyEquivalent = @"";
    }

    // Основную кнопку не задали и роли её не выбрали - возвращаем правило AppKit:
    // основной становится первая добавленная, то есть самая правая
    if (!pDefaultButton)
        alert.buttons.firstObject.keyEquivalent = @"\r";

    // Внутри модального цикла AppKit продолжает работать и обработчик событий Qt, а значит
    // доставляются отложенные удаления: диалог могли снести вместе с его родителем, пока
    // сообщение стояло на экране. Тогда разбирать ответ уже не на чем
    QPointer<QMessageBox> guard(this);

    NSInteger retCode = NSModalResponseCancel;

    QWidget *pParent = qobject_cast<QWidget *>(parent());

    // Лист показываем только у видимого и развёрнутого окна: winId() создаёт окно
    // принудительно, а лист крепится под заголовком родителя - у невидимого или свёрнутого
    // окна он остался бы невидимым, а программа встала бы в модальном цикле
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
        // runModal не должен возвращать NSModalResponseContinue, но по QTBUG-114546
        // бывает, что возвращает: это значит "модальный цикл продолжается"
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

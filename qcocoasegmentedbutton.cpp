#include "pch.h"
#include "qcocoasegmentedbutton.h"

#include <QToolButton>
#include <QHBoxLayout>

class QCocoaSegmentedButtonPrivate : public QObject
{
    //Q_OBJECT

public:
    explicit QCocoaSegmentedButtonPrivate(QCocoaSegmentedButton* parentWidget)
        : QObject(parentWidget),
        parent(parentWidget),
        trackingMode(QCocoaSegmentedButton::NSSegmentSwitchTrackingSelectOne),
        style(QCocoaSegmentedButton::SegmentStyleRounded)
    {
        signalMapper = new QSignalMapper(this);
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
        connect(signalMapper, &QSignalMapper::mappedInt, parentWidget,
            [this](int index) {
            bool isChecked = false;
            if (index >= 0 && index < buttons.size()) {
                isChecked = buttons[index]->isChecked();
            }
            emit parent->clicked(index, isChecked);
        });
#else
        connect(signalMapper, SIGNAL(mapped(int)), parentWidget, SLOT(onSegmentClicked(int)));
#endif
        layout = new QHBoxLayout(parentWidget);
        layout->setContentsMargins(0, 0, 0, 0);
        layout->setSpacing(0);
    }

    ~QCocoaSegmentedButtonPrivate()
    {
        // QSignalMapper will be deleted automatically.
        qDeleteAll(buttons); // Also removes them from the layout
        buttons.clear();
    }

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
private slots:
    void onSegmentClicked(int index)
    {
        if (index >= 0 && index < buttons.size()) {
            bool isChecked = buttons[index]->isChecked();
            emit parent->clicked(index, isChecked);
        }
    }
#endif

public:
    // Rebuild buttons to match `count`
    void setSegmentCount(int count)
    {
        if (count < 0)
            count = 0;

        // If we have more buttons than needed, remove the extras
        while (buttons.size() > count) {
            QToolButton* btn = buttons.takeLast();
            layout->removeWidget(btn);
            delete btn;
        }

        // If we have fewer buttons, create new ones
        while (buttons.size() < count) {
            QToolButton* button = new QToolButton(parent);
            button->setAutoRaise(true);
            button->setFocusPolicy(Qt::TabFocus);
            // The actual style (text/icon arrangement) will be set in updateButtonStyles()
            connect(button, &QToolButton::clicked, signalMapper,
                static_cast<void(QSignalMapper::*)()>(&QSignalMapper::map));
            buttons.append(button);
            layout->addWidget(button);
            signalMapper->setMapping(button, buttons.size() - 1);
        }

        updateButtonStyles();
        updateTrackingMode();
    }

    void updateButtonStyles()
    {
        Qt::ToolButtonStyle tbStyle = Qt::ToolButtonTextBesideIcon;
        if (style == QCocoaSegmentedButton::SegmentStyleSmallSquare) {
            tbStyle = Qt::ToolButtonIconOnly;
        }
        // You can add logic here for other styles if needed
        for (auto* btn : buttons) {
            btn->setToolButtonStyle(tbStyle);
        }
    }

    void updateTrackingMode()
    {
        bool autoExclusive = false;
        bool checkable = true;
        switch (trackingMode) {
        case QCocoaSegmentedButton::NSSegmentSwitchTrackingSelectOne:
            autoExclusive = true;
            break;
        case QCocoaSegmentedButton::NSSegmentSwitchTrackingSelectAny:
            autoExclusive = false;
            break;
        case QCocoaSegmentedButton::NSSegmentSwitchTrackingMomentary:
            checkable = false;
            break;
        }

        for (auto* btn : buttons) {
            btn->setAutoExclusive(autoExclusive);
            btn->setCheckable(checkable);
        }
    }

    QPointer<QCocoaSegmentedButton> parent;
    QHBoxLayout* layout = nullptr;
    QList<QToolButton*> buttons;
    QSignalMapper* signalMapper = nullptr;
    QCocoaSegmentedButton::SegmentSwitchTracking trackingMode;
    QCocoaSegmentedButton::SegmentStyle style;
};

QCocoaSegmentedButton::QCocoaSegmentedButton(QWidget* parent)
    : QCocoaWidget(parent), d_ptr(new QCocoaSegmentedButtonPrivate(this))
{
    // Default setups
    setTrackingMode(NSSegmentSwitchTrackingSelectOne);  // default
    setSegmentStyle(SegmentStyleRounded);               // default
}

QCocoaSegmentedButton::~QCocoaSegmentedButton()
{
    int a = 1;
}

void QCocoaSegmentedButton::setSegmentCount(int count)
{
    if (!d_ptr) return;
    d_ptr->setSegmentCount(count);
}

int QCocoaSegmentedButton::segmentCount() const
{
    if (!d_ptr) return 0;
    return d_ptr->buttons.size();
}

void QCocoaSegmentedButton::setSegmentToolTip(int index, const QString& tip)
{
    if (!d_ptr) return;
    if (index < 0 || index >= d_ptr->buttons.size()) {
        qWarning() << "Invalid segment index:" << index;
        return;
    }
    d_ptr->buttons[index]->setToolTip(tip);
}

void QCocoaSegmentedButton::setSegmentIcon(int index, const QIcon& icon)
{
    if (!d_ptr) return;
    if (index < 0 || index >= d_ptr->buttons.size()) {
        qWarning() << "Invalid segment index:" << index;
        return;
    }
    d_ptr->buttons[index]->setIcon(icon);
}

#ifdef Q_OS_MAC
void QCocoaSegmentedButton::setSegmentIcon(int index, QCocoaIcon::StandardIcon icon)
{
    // TODO: Provide Mac-specific standard icon logic
    Q_UNUSED(index);
    Q_UNUSED(icon);
}
#endif

void QCocoaSegmentedButton::setSegmentMenu(int index, QMenu* menu)
{
    if (!d_ptr) return;
    if (index < 0 || index >= d_ptr->buttons.size()) {
        qWarning() << "Invalid segment index:" << index;
        return;
    }
    d_ptr->buttons[index]->setMenu(menu);
    // Typically you'd also call:
    // d_ptr->buttons[index]->setPopupMode(QToolButton::InstantPopup);
    // or a suitable popup mode for your use-case
}

void QCocoaSegmentedButton::setSegmentEnabled(int index, bool enabled)
{
    if (!d_ptr) return;
    if (index < 0 || index >= d_ptr->buttons.size()) {
        qWarning() << "Invalid segment index:" << index;
        return;
    }
    d_ptr->buttons[index]->setEnabled(enabled);
}

void QCocoaSegmentedButton::segmentAnimateClick(int index)
{
    if (!d_ptr) return;
    if (index < 0 || index >= d_ptr->buttons.size()) {
        qWarning() << "Invalid segment index:" << index;
        return;
    }
    d_ptr->buttons[index]->animateClick();
}

QSize QCocoaSegmentedButton::sizeHint() const
{
    // A simple approach is to sum the preferred widths/heights of our sub-buttons
    // plus the layout spacing and margins.
    if (!d_ptr) return QSize(100, 30); // fallback

    int totalWidth = 0;
    int maxHeight = 0;
    for (auto* btn : d_ptr->buttons) {
        QSize s = btn->sizeHint();
        totalWidth += s.width();
        maxHeight = qMax(maxHeight, s.height());
    }
    // plus spacing
    int spacing = d_ptr->layout->spacing() * (d_ptr->buttons.size() - 1);
    totalWidth += spacing;

    QMargins margins = d_ptr->layout->contentsMargins();
    totalWidth += margins.left() + margins.right();
    maxHeight += margins.top() + margins.bottom();

    return QSize(totalWidth, maxHeight);
}

void QCocoaSegmentedButton::setSegmentChecked(int index, bool checked)
{
    if (!d_ptr) return;
    if (index < 0 || index >= d_ptr->buttons.size()) {
        qWarning() << "Invalid segment index:" << index;
        return;
    }

    // If we are in SelectOne mode, checking this button may uncheck the others automatically
    d_ptr->buttons[index]->setChecked(checked);
}

bool QCocoaSegmentedButton::isSegmentChecked(int index) const
{
    if (!d_ptr) return false;
    if (index < 0 || index >= d_ptr->buttons.size()) {
        qWarning() << "Invalid segment index:" << index;
        return false;
    }
    return d_ptr->buttons[index]->isChecked();
}

void QCocoaSegmentedButton::setSegmentTitle(int index, const QString& title)
{
    if (!d_ptr) return;
    if (index < 0 || index >= d_ptr->buttons.size()) {
        qWarning() << "Invalid segment index:" << index;
        return;
    }
    QToolButton* btn = d_ptr->buttons[index];

    // Use elidedText to avoid manual substring / "..." issues.
    QFontMetrics fm(btn->font());
    QString elided = fm.elidedText(title, Qt::ElideRight, btn->width());
    btn->setText(elided);
}

void QCocoaSegmentedButton::setSegmentFixedWidth(int index, int width)
{
    if (!d_ptr) return;
    if (index < 0 || index >= d_ptr->buttons.size()) {
        qWarning() << "Invalid segment index:" << index;
        return;
    }
    d_ptr->buttons[index]->setFixedWidth(width);
}

int QCocoaSegmentedButton::segmentWidth(int index) const
{
    if (!d_ptr) return -1;
    if (index < 0 || index >= d_ptr->buttons.size()) {
        qWarning() << "Invalid segment index:" << index;
        return -1;
    }
    return d_ptr->buttons[index]->width();
}

void QCocoaSegmentedButton::setSegmentFixedHeight(int index, int height)
{
    if (!d_ptr) return;
    if (index < 0 || index >= d_ptr->buttons.size()) {
        qWarning() << "Invalid segment index:" << index;
        return;
    }
    d_ptr->buttons[index]->setFixedHeight(height);
}

void QCocoaSegmentedButton::setTrackingMode(SegmentSwitchTracking mode)
{
    if (!d_ptr) return;
    d_ptr->trackingMode = mode;
    d_ptr->updateTrackingMode();
}

QCocoaSegmentedButton::SegmentSwitchTracking QCocoaSegmentedButton::trackingMode() const
{
    if (!d_ptr) return NSSegmentSwitchTrackingSelectOne;
    return d_ptr->trackingMode;
}

void QCocoaSegmentedButton::setSegmentStyle(SegmentStyle style)
{
    if (!d_ptr) return;
    d_ptr->style = style;
    d_ptr->updateButtonStyles();
}

QCocoaSegmentedButton::SegmentStyle QCocoaSegmentedButton::segmentStyle() const
{
    if (!d_ptr) return SegmentStyleRounded;
    return d_ptr->style;
}


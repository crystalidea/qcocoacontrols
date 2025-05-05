#include "pch.h"
#include "qcocoapopover.h"
#include "qcocoapopover_generic_dialog.h"

class QCocoaPopoverPrivate
{
public:
    QCocoaPopoverPrivate(QCocoaPopover* q)
        : q_ptr(q)
    {
    }

    void createPopoverIfNeeded();

    QCocoaPopover* q_ptr;      // back-pointer
    QPointer<QPopoverDialog>        popoverDialog;
    QCocoaPopover::PopoverBehavior  popoverBehavior = QCocoaPopover::PopoverBehavior::BehaviorTransient;
    bool                            animate = false;
    bool                            isShowing = false;

    // For anchor logic:
    QWidget* anchorWidget = nullptr;

    // Timer for timeouts
    QTimer                          closeTimer;
};

// Creates the dialog if it doesn't exist yet.
void QCocoaPopoverPrivate::createPopoverIfNeeded()
{
    if (popoverDialog.isNull()) {
        popoverDialog = new QPopoverDialog(q_ptr->_contents);

        // Install an event filter on the dialog so we can intercept close events, etc.
        popoverDialog->installEventFilter(q_ptr);

        // Also handle if the user clicks outside (Qt::Popup typically does it automatically,
        // but let's be safe).
    }
}

QCocoaPopover::QCocoaPopover(QObject* parent, QWidget* contents)
    : QObject(parent),
    _contents(contents),
    p(new QCocoaPopoverPrivate(this))
{
    // Default behavior is transient
    setPopoverBehavior(PopoverBehavior::BehaviorTransient);
}

QCocoaPopover::~QCocoaPopover()
{
    close();  // ensure it's closed
    // p is a QScopedPointer, it will delete itself.
}

void QCocoaPopover::show()
{
    // We need valid popover contents or there's nothing to show
    if (!_contents)
        return;

    p->createPopoverIfNeeded();
    if (p->popoverDialog.isNull())
        return;

    QWidget* dialog = p->popoverDialog;
    dialog->adjustSize();
    const QSize popSize = dialog->sizeHint();

    int x = 0;
    int y = 0;

    // Show the arrow tip exactly at the cursor
    QPoint cursorPos = QCursor::pos();
    // Because the arrow is at the bottom center, we align that to the cursor
    x = cursorPos.x() - popSize.width() / 2;
    y = cursorPos.y() - popSize.height();

    // Now clamp to screen:
#if QT_VERSION >= QT_VERSION_CHECK(5,10,0)
    QScreen* screen = QGuiApplication::screenAt(cursorPos);
    QRect screenGeom = screen ? screen->availableGeometry()
        : QGuiApplication::primaryScreen()->availableGeometry();
#else
    QRect screenGeom = QApplication::desktop()->availableGeometry(cursorPos);
#endif

    // Clamp horizontally
    if (x < screenGeom.left()) {
        x = screenGeom.left();
    }
    else if (x + popSize.width() > screenGeom.right()) {
        x = screenGeom.right() - popSize.width();
    }

    // Clamp vertically
    if (y < screenGeom.top()) {
        y = screenGeom.top();
    }
    else if (y + popSize.height() > screenGeom.bottom()) {
        y = screenGeom.bottom() - popSize.height();
    }

    // Final positioning
    dialog->move(x, y);
    dialog->show();
    dialog->raise();

    // Start close timer if needed
    if (_timeout > 0) {
        p->closeTimer.setSingleShot(true);
        QObject::connect(&p->closeTimer, &QTimer::timeout, [this]() {
            this->close();
        });
        p->closeTimer.start(_timeout);
    }

    p->isShowing = true;
}

void QCocoaPopover::show(QCocoaMenubarItem* /*forMenuIcon*/)
{
    // Placeholder for show relative to a menubar icon. 
    // You'd do something similar to show(QWidget*), 
    // computing geometry from the menubar item location, etc.
    qWarning() << "show(QCocoaMenubarItem *) not implemented on non-macOS fallback.";
}

void QCocoaPopover::close()
{
    if (!p->popoverDialog.isNull() && p->isShowing) {
        p->popoverDialog->close();
        p->isShowing = false;
        emit closed();
    }
}

void QCocoaPopover::setPopoverBehavior(QCocoaPopover::PopoverBehavior b)
{
    p->popoverBehavior = b;
}

void QCocoaPopover::setAnimate(bool bAnimate)
{
    p->animate = bAnimate;
    // For actual animations, you could use QPropertyAnimation, fade in/out, etc.
    // This is just a placeholder to store the flag.
}

bool QCocoaPopover::eventFilter(QObject* obj, QEvent* event)
{
    // If the user interacts with something else outside the popover,
    // Qt::Popup *should* auto-close. But let's handle extra logic 
    // for BehaviorTransient / BehaviorSemitransient.

    if (obj == p->popoverDialog) {
        // If the dialog is losing focus or user clicked outside:
        // - BehaviorTransient => close on click outside
        // - BehaviorSemitransient => might differ if the user interacts within the same window
        //   but for simplicity, we also close it if the user interacts outside.
        switch (event->type()) {
        case QEvent::FocusOut:
        case QEvent::WindowDeactivate:
            if (p->popoverBehavior == PopoverBehavior::BehaviorTransient ||
                p->popoverBehavior == PopoverBehavior::BehaviorSemitransient) {
                close();
            }
            break;
        default:
            break;
        }
    }
    return QObject::eventFilter(obj, event);
}

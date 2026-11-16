#ifndef qcocoatabwidget_h__
#define qcocoatabwidget_h__

#include <QTabWidget>

#ifdef Q_OS_MAC

#include <memory>

class QCocoaTabWidgetPrivate;

// A QTabWidget that looks and moves like NSTabView under Liquid Glass with macOS 27 and later. Its tabs are an
// NSSegmentedControl with the tabs role, the bar NSTabView itself shows there: the selected tab lies under a piece of
// glass that slides to the tab the user picks. QMacStyle could only paint a still picture of that bar, as SwiftUI
// draws the glass and its motion inside AppKit. The place of the bar, the bezel of the pane and the margins around the
// pages come from an NSTabView of the same size kept out of sight, so the widget matches one next to it in both
// appearances and in the small and mini sizes (Qt::WA_MacSmallSize, Qt::WA_MacMiniSize on the tab widget).
//
// QTabBar still keeps the tabs: titles, icons, tool tips, the enabled, visible and current tab, so the QTabWidget API
// works as usual, and a QTabWidget promoted to this class in Qt Designer needs nothing else. What NSTabView doesn't
// show isn't shown: the tabs are always on top, and closable or movable tabs, the document mode and corner widgets are
// not supported. The keyboard focus doesn't stop at the bar; Ctrl+Tab switches the tabs as in QTabWidget.
//
// The bar of macOS 27.0 draws a disabled tab like an enabled one, though it ignores clicks on it.
//
// On macOS 26 and earlier, in the classic design and on other platforms it is a plain QTabWidget.

class QCocoaTabWidget : public QTabWidget
{
    Q_OBJECT

public:

    explicit QCocoaTabWidget(QWidget *parent = nullptr);
    ~QCocoaTabWidget() override;

    // Whether the tabs are the native bar: it depends only on the system and the design of the app
    bool hasNativeTabBar() const;

protected:

    void changeEvent(QEvent *event) override;

private:

    std::unique_ptr<QCocoaTabWidgetPrivate> _native;
};

#else

typedef QTabWidget QCocoaTabWidget;

#endif

#endif // qcocoatabwidget_h__

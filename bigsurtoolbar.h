#ifndef bigsurtoolbar_h
#define bigsurtoolbar_h

#include <QMacToolBar>

class QMacToolBarBigSur : public QMacToolBar
{
public:

    enum BigSurToolbarStyle { // macOS 11.0+ (Big Sur)
        StyleAutomatic, // The default value. The style will be determined by the window's given configuration
        StyleExpanded, // The toolbar will appear below the window title
        StylePreference, // The toolbar will appear below the window title and the items in the toolbar will attempt to have equal widths when possible
        StyleUnified, // The window title will appear inline with the toolbar when visible
        StyleUnifiedCompact // Same as NSWindowToolbarStyleUnified, but with reduced margins in the toolbar allowing more focus to be on the contents of the window
    };

    using QMacToolBar::QMacToolBar;

    void attachToWindowWithStyle(QWindow *window, BigSurToolbarStyle style);
};

#endif // bigsurtoolbar_h

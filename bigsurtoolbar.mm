#include "bigsurtoolbar.h"

#include <QGuiApplication>
#include <QWindow>

#import <AppKit/AppKit.h>

#include <Cocoa/Cocoa.h>

#if (QT_VERSION > QT_VERSION_CHECK(5, 6, 3)) // not legacy Qt
    /* Backport the toolbarStyle property to allow compilation with older SDKs*/
    #if !QT_MACOS_PLATFORM_SDK_EQUAL_OR_ABOVE(__MAC_10_16)
    typedef NS_ENUM(NSInteger, NSWindowToolbarStyle) {
        // The default value. The style will be determined by the window's given configuration
        NSWindowToolbarStyleAutomatic,
        // The toolbar will appear below the window title
        NSWindowToolbarStyleExpanded,
        // The toolbar will appear below the window title and the items in the toolbar will attempt to have equal widths when possible
        NSWindowToolbarStylePreference,
        // The window title will appear inline with the toolbar when visible
        NSWindowToolbarStyleUnified,
        // Same as NSWindowToolbarStyleUnified, but with reduced margins in the toolbar allowing more focus to be on the contents of the window
        NSWindowToolbarStyleUnifiedCompact
    } API_AVAILABLE(macos(11.0));

    @interface NSWindow (toolbarStyle)
    @property NSWindowToolbarStyle toolbarStyle API_AVAILABLE(macos(11.0));
    @end

    #endif // __MAC_10_16
#endif

void QMacToolBarBigSur::attachToWindowWithStyle(QWindow *window, BigSurToolbarStyle style)
{
    QMacToolBar::attachToWindow(window);

    // getting actual NSWindow should be done with
    // NSWindow *macWindow = static_cast<NSWindow*>(
    // QGuiApplication::platformNativeInterface()->nativeResourceForWindow("nswindow", d->targetWindow));
    // but it's not possible outside Qt source code, unfortunately

    NSView *view = reinterpret_cast<NSView*>(window->winId());
    NSWindow *macWindow = view.window;

    if (@available(macOS 11.0, *)) {
        macWindow.toolbarStyle = (NSWindowToolbarStyle)(style);
    }
}

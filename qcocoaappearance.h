#ifndef qcocoaappearance_h__
#define qcocoaappearance_h__

// The design AppKit gives the standard controls of this process, and the window contrast that the Liquid Glass
// design takes away from Qt widgets.
//
// AppKit decides on Liquid Glass per process: it is on with macOS 26 and later if the executable was built against
// the macOS 26 SDK or later, unless it was built against an SDK older than 27 and sets UIDesignRequiresCompatibility
// in its Info.plist. design() reads the SDK recorded in the executable, not the one this library was compiled with,
// and agrees with qt_apple_runningWithLiquidGlass() of a Qt 6.8.5 with qtbase-liquid-glass-opt-out-sdk.patch from
// crystalidea/qt-build-tools, by which QMacStyle picks its metrics. On other platforms the design is always Classic.

class QCocoaAppearance
{
public:

    enum class Design { Classic, LiquidGlass };

    static Design design();
    static bool isLiquidGlass() { return design() == Design::LiquidGlass; }

    // Under Liquid Glass NSColor.windowBackgroundColor is white in the light appearance, and the palette Qt builds
    // from the system colors paints windows, item views and their headers the same white. installWindowContrast()
    // gives every top-level QDialog and QMainWindow the Window and Button colors of secondarySystemFillColor laid over
    // windowBackgroundColor and recomputes them when the appearance changes. In the generic RGB values Qt uses for
    // its palette that is #EBEBEB light and #292929 dark, against #FFFFFF and #171717 of item views. Only these two
    // roles of the window itself are set: an application-wide palette would drop the palettes Qt keeps per widget
    // class, such as the alternating rows of item views.
    //
    // Call it once, after the QApplication is created. It does nothing in the classic design, where the window
    // background is gray anyway, and on other platforms.
    static void installWindowContrast();
};

#endif // qcocoaappearance_h__

#ifndef qcocoaappearance_h__
#define qcocoaappearance_h__

// The design AppKit gives the standard controls of this process, and the window contrast that the Liquid Glass
// design takes away from Qt widgets.
//
// AppKit decides on Liquid Glass per process: it is on with macOS 26 and later if the executable was built against
// the macOS 26 SDK or later. design() reads the SDK recorded in the executable, not the one this library was compiled
// with, and so agrees with AppKit and with qt_apple_runningWithLiquidGlass() of Qt, by which QMacStyle picks its
// metrics. On other platforms the design is always Classic.
//
// The opt out by UIDesignRequiresCompatibility is not supported: an app that uses this library must not set the key
// in its Info.plist. AppKit honors the key on macOS 26 whatever the SDK, and on macOS 27 in an app built against an
// SDK older than 27, while design() doesn't read it, so the controls of the library would follow Liquid Glass in an
// app that AppKit draws in the classic design.

class QCocoaAppearance
{
public:

    enum class Design { Classic, LiquidGlass };

    static Design design();
    static bool isLiquidGlass() { return design() == Design::LiquidGlass; }

    // Under Liquid Glass AppKit draws the title bar and the toolbar of a window in the dark appearance lighter than
    // NSColor.windowBackgroundColor, while the palette Qt builds from the system colors paints windows, item views and
    // their headers in windowBackgroundColor: the window comes out darker than its own title bar. In the dark
    // appearance installWindowContrast() gives every top-level QDialog and QMainWindow the Window and Button colors of
    // secondarySystemFillColor laid over windowBackgroundColor, #292929 in the generic RGB values Qt uses for its
    // palette, which comes out as light as the title bar, against #171717 of item views. In the light appearance the
    // title bar is as white as the window background, and the windows keep the colors of the Qt palette: a gray body
    // under a white title bar looks foreign there. The colors follow the appearance when it changes. Only these two
    // roles of the window itself are set: an application-wide palette would drop the palettes Qt keeps per widget
    // class, such as the alternating rows of item views.
    //
    // Call it once, after the QApplication is created. It does nothing in the classic design, where the window and
    // its title bar are of one color anyway, and on other platforms.
    static void installWindowContrast();
};

#endif // qcocoaappearance_h__

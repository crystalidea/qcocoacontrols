#include "pch.h"
#include "qcocoaappearance.h"

#import <AppKit/AppKit.h>

#include <mach-o/dyld.h>
#include <mach-o/loader.h>

namespace
{
    // Major version of the SDK recorded in the executable. AppKit picks the design by this field, so it is read at run
    // time: the library can be compiled with another SDK than the one the app is linked with
    int programSdkMajor()
    {
        for (uint32_t i = 0; i < _dyld_image_count(); ++i)
        {
            const mach_header *header = _dyld_get_image_header(i);

            if (header->filetype != MH_EXECUTE)
                continue;

            const bool is64Bit = header->magic == MH_MAGIC_64 || header->magic == MH_CIGAM_64;
            uintptr_t cursor = uintptr_t(header) + (is64Bit ? sizeof(mach_header_64) : sizeof(mach_header));

            for (uint32_t n = 0; n < header->ncmds; ++n)
            {
                const load_command *command = reinterpret_cast<const load_command *>(cursor);

                if (command->cmd == LC_BUILD_VERSION)
                    return reinterpret_cast<const build_version_command *>(command)->sdk >> 16;

                if (command->cmd == LC_VERSION_MIN_MACOSX)
                    return reinterpret_cast<const version_min_command *>(command)->sdk >> 16;

                cursor += command->cmdsize;
            }

            break;
        }

        return 0;
    }

    // secondarySystemFillColor laid over windowBackgroundColor in the current appearance of the app. The colors are
    // converted to generic RGB, the way Qt converts the system colors of its palette
    QColor contrastColor()
    {
        QColor color;

        if (@available(macOS 14.0, *)) // secondarySystemFillColor; Liquid Glass means macOS 26 anyway
        {
            QMacAutoReleasePool pool;

            QColor *result = &color;

            [NSApp.effectiveAppearance performAsCurrentDrawingAppearance:^{

                NSColor *background = [NSColor.windowBackgroundColor colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
                NSColor *fill = [NSColor.secondarySystemFillColor colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];

                if (!background || !fill)
                    return;

                const CGFloat alpha = fill.alphaComponent;

                result->setRgbF(float(fill.redComponent * alpha + background.redComponent * (1 - alpha)),
                                float(fill.greenComponent * alpha + background.greenComponent * (1 - alpha)),
                                float(fill.blueComponent * alpha + background.blueComponent * (1 - alpha)));
            }];
        }

        return color;
    }

    bool isDarkAppearance()
    {
        NSAppearanceName name = [NSApp.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua,
                                                                                               NSAppearanceNameDarkAqua]];

        return [name isEqualToString:NSAppearanceNameDarkAqua];
    }

    bool wantsContrast(const QWidget *widget)
    {
        return widget->isWindow() && (qobject_cast<const QDialog *>(widget) || qobject_cast<const QMainWindow *>(widget));
    }

    void applyContrast(QWidget *window)
    {
        // in the light appearance the colors of the Qt palette, the white of the title bar; they are set back
        // explicitly only on a window that was shown in the dark appearance before
        const QPalette qtPalette = QApplication::palette(window);
        const bool dark = isDarkAppearance();
        const QColor windowColor = dark ? contrastColor() : qtPalette.color(QPalette::Window);
        const QColor buttonColor = dark ? windowColor : qtPalette.color(QPalette::Button);

        if (!windowColor.isValid())
            return;

        QPalette palette = window->palette();

        // setPalette() sends PaletteChange to every child and repaints the window: only when the color is new
        if (palette.color(QPalette::Window) == windowColor && palette.color(QPalette::Button) == buttonColor)
            return;

        palette.setColor(QPalette::Window, windowColor);
        palette.setColor(QPalette::Button, buttonColor);

        window->setPalette(palette);
    }

    // Show comes before the window is put on screen, every time it is shown, so a window that was hidden while the
    // appearance changed gets the new color before its first paint. ThemeChange comes to the windows that exist when
    // the appearance or the accessibility display settings change
    class WindowContrastFilter : public QObject
    {
    public:

        using QObject::QObject;

    protected:

        bool eventFilter(QObject *object, QEvent *event) override
        {
            if ((event->type() == QEvent::Show || event->type() == QEvent::ThemeChange) && object->isWidgetType())
            {
                QWidget *widget = static_cast<QWidget *>(object);

                if (wantsContrast(widget))
                    applyContrast(widget);
            }

            return QObject::eventFilter(object, event);
        }
    };
}

QCocoaAppearance::Design QCocoaAppearance::design()
{
    static const Design design = []
    {
        const int sdk = programSdkMajor();

        if (sdk < 26 || NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 26)
            return Design::Classic;

        // the opt-out key works only for apps built against an SDK older than 27
        if (sdk < 27)
        {
            id optOut = [NSBundle.mainBundle objectForInfoDictionaryKey:@"UIDesignRequiresCompatibility"];

            if (optOut && [optOut boolValue])
                return Design::Classic;
        }

        return Design::LiquidGlass;
    }();

    return design;
}

void QCocoaAppearance::installWindowContrast()
{
    static bool installed = false;

    if (installed || !qApp || !isLiquidGlass())
        return;

    installed = true;

    qApp->installEventFilter(new WindowContrastFilter(qApp));

    const QWidgetList windows = QApplication::topLevelWidgets();

    for (QWidget *window : windows)
    {
        if (window->isVisible() && wantsContrast(window))
            applyContrast(window);
    }
}

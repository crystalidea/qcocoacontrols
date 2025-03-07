#ifndef QCOCOAICON_H
#define QCOCOAICON_H

Q_FORWARD_DECLARE_OBJC_CLASS (NSImage);

class QCocoaIcon
{
public:

    // ref: https://developer.apple.com/design/human-interface-guidelines/macos/icons-and-images/system-icons/
    // http://hetima.github.io/fucking_nsimage_syntax/
    enum StandardIcon
    {
        // Control Icons:
        Action, // Displays a menu containing app-wide or contextual commands.
        ListViewTemplate, // Displays content in a list-based layout.
        Add, // Creates a new item
        Remove, // Remove an item (from a list, for example).
        // Preferences Icons:
        UserAccounts, PreferencesGeneral, Advanced,
        // System Entity Icons:
        Computer, // Computer (represents the current computer)
        // Toolbar Icons:
        ColorPanel,
        FontPanel,
        Info, // Shows or hides an information window or view.
    };

    // all methods return an autorelease object
    static NSImage *imageFromQImage(const QImage &img);
    static NSImage * imageFromQIcon(const QIcon &icon);
    static NSImage * standardIcon(StandardIcon type);

    static QPixmap standardIcon(StandardIcon type, int nSize);
};

#ifdef Q_OS_MAC
QImage CGImageToQImage(CGImageRef cgImage); // for Qt6, however there's QImage::toCGImage
#endif

#endif // QCOCOAICON_H

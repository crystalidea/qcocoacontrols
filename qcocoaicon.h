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

    static NSImage * iconToNSImage(StandardIcon type);
    static NSImage * iconToNSImage(const QIcon &icon, const QWidget *widget = nullptr);

    static QPixmap standardIcon(StandardIcon type, int nSize);
};

#endif // QCOCOAICON_H

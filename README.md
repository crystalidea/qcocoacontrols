# qcocoacontrols

The library helps to make use of native macOS controls in a Qt app. On Windows (and others?) it's supposed to provide a decent fallback.

Requires Qt 6 (we build it with Qt 6.8) and macOS 12 or later.

Many of those controls are used in our [Macs Fan Control](https://crystalidea.com/macs-fan-control) and [AnyToISO](https://crystalidea.com/anytoiso) apps.

The code is far from being ideal so you're welcome to contribute.

To compile on macOS we use Qt Creator and Visual Studio 2022 Community on Windows

#### linking on macOS

Being a static library by default, qcocoacontrols requires the '-ObjC' flag to be passed to the linker when linking your target app. Otherwise it will crash with something like

``` +[NSImage imageFromQIcon:]: unrecognized selector sent to class 0x7fff8d90cbb0```

The reason for that are customizations for the existing **NSImage** class and bringing those to the target app is not enabled by default ([More info](https://stackoverflow.com/questions/2567498/objective-c-categories-in-static-library)). Adding linker flags can be done by appending them to LIBS in your .pro file:

``` LIBS += -Llib_path -lqcocoacontrols -ObjC```

## Some examples:

##### QCocoaPreferencesDialog:
![QCocoaPreferencesDialog](/images/QCocoaPreferencesDialog.png)

##### QCocoaButton with BezelStyle::HelpButton:

![QCocoaButton](/images/QCocoaButton_help.png)

##### QCocoaPopover displayed for the help button:

![QCocoaPopover.png](/images/QCocoaPopover.png)

##### QCocoaSegmentedButton:

![QCocoaSegmentedButton](/images/QCocoaSegmentedButton.png)

##### Two examples of QCocoaButtonActionMenu, the second with icon position set to QCocoaButton::IconOnly:

![QCocoaButtonActionMenu.png](/images/QCocoaButtonActionMenu.png)

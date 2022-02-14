# qcocoacontrols

The library helps to make use of native macOS controls in a Qt app. On Windows (and others?) it's supposed to provide a decent fallback.

Tested with Qt 5.6.x, Qt 5.15.x and Qt 6.2.x.

Many of those controls are used in our [Macs Fan Control](https://crystalidea.com/macs-fan-control) and [AnyToISO](https://crystalidea.com/anytoiso) apps.

The code is far from being ideal so you're welcome to contribute.

To compile on macOS we use Qt Creator and Visual Studio 2019 Community on Windows

#### linking on macOS

Being a static library by default, qcocoacontrols requires the '-ObjC' flag to be passed to the linker when linking your target app. Otherwise it will crash with something like

``` +[NSImage imageFromQIcon:]: unrecognized selector sent to class 0x7fff8d90cbb0```

The reason for that are customizations for the existing **NSImage** class and bringing those to the target app is not enabled by default ([More info](https://stackoverflow.com/questions/2567498/objective-c-categories-in-static-library)). Actually in our case it wasn't actually required when using Qt 5.15 but for Qt 5.6 - yes. Adding linker flags can be done by appending them to LIBS in your .pro file:

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
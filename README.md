# qcocoacontrols

The library helps to make use of native macOS controls in a Qt app. On Windows (and others?) it should provide a decent fallback.

Tested with Qt 5 (5.6.3 and Qt 5.15.2).

Many of those controls are used in our [Macs Fan Control](https://crystalidea.com/macs-fan-control) and [AnyToISO](https://crystalidea.com/anytoiso) apps.

The code is far from being ideal so you're welcome to contribute.

To compile on macOS we use Qt Creator and Visual Studio 2019 Community on Windows

## Some examples:

##### QCocoaPreferencesDialog:
![QCocoaPreferencesDialog](/images/QCocoaPreferencesDialog.png)

##### QCocoaButton with BezelStyle::HelpButton:

![QCocoaButton](/images/QCocoaButton_help.png)

##### QCocoaSegmentedButton:

![QCocoaSegmentedButton](/images/QCocoaSegmentedButton.png)

##### Two examples of QCocoaButtonActionMenu, the second with icon position set to QCocoaButton::IconOnly:

![QCocoaButtonActionMenu.png](/images/QCocoaButtonActionMenu.png)


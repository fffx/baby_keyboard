## TODO block power button
- https://github.com/lwouis/alt-tab-macos/blob/8a4aa7908fb5f4ff417bdaadce7cf70605095600/src/experimentations/README.md
- https://github.com/libusb/hidapi

- ~~show window on launch~~
- ~~hide docker icon, only need menu bar~~
- ~~https://developer.apple.com/documentation/uikit/creating-custom-symbol-images-for-your-app~~
- only block user selected keyboard
    - https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX11.3.sdk/System/Library/Frameworks/CoreGraphics.framework/Versions/A/Headers/CGEventTypes.h
- whitelist by keys
- blacklist by keys
- temporary lock by holding Fn



## swiftUI
https://developer.apple.com/design/human-interface-guidelines/layout-and-organization




## Test

* on first start should request for accessibility
    -  the toggle should be disabled
    - after permissions is granted, the text hinter should be hidden
    -  the toggle should be enabled
* When keyboard is blocked, after quitting, the lock should be released
* toggle lock should work properly


## translation prommpt
https://github.com/midday-ai/languine

I have these strings from an macos keyboard app
Please translate these strings to German, each string is separated by a blank line:
```
Please grant accessibility permissions to [%@] in:
[System Settings]
    > [Secuerity & Privacy]
        > [Accessibility] (scroll down)

Effect

Firework Window

Lock

Lock Keyboard

Lock keyboard on launch

Confetti

None

Speak a word

Speak the pressed key

Quit %@

You can use shortcut Ctrl + Option + U to toggle keyboard lock
```
# BabyKeyboard Lock

A macOS menu bar app that locks your keyboard to prevent unwanted inputs while entertaining your toddlers or kids with fun visual and audio effects.

**Official Website:** https://keyboardlock.app/

![BabyKeyboard Lock screenshot](screenshots/main.png)

## Features

- **Keyboard Lock**: Prevents unwanted inputs, including media keys and the Power button
- **Hot Corner Toggle**: Quickly lock/unlock by moving the mouse to the top-right corner of the screen
- **Fun Effects**: Configurable effects including confetti animations, spoken key names, and words starting with the pressed key
- **Non-Intrusive**: No visible window - continue watching videos or reading webpages normally
- **Menu Bar App**: Clean interface accessible from the menu bar with global shortcut toggle


## FAQ

### Malicious Software Warning

If you see "Apple can't check app for malicious software," this is because the app is not yet notarized with Apple. See the following guides to allow the app to run:

- [Latest macOS](https://support.apple.com/en-gb/guide/mac-help/mchleab3a043/mac)
- [macOS 15](https://support.apple.com/en-gb/guide/mac-help/mchleab3a043/15.0/mac/15.0)
- [macOS 14](https://support.apple.com/en-gb/guide/mac-help/mchleab3a043/14.0/mac/14.0)

For more details, see [issue #4](https://github.com/fffx/baby_keyboard/issues/4).

### Privacy

The app is released with GitHub CI for transparency. You can review the source code and compile it yourself if desired.



## TODO

- [x] Show window on launch
- [x] Hide dock icon (menu bar only)
- [x] Custom symbol images
- [ ] Additional effects
- [ ] Whitelist/blacklist by key codes
- [ ] Temporary lock by holding Fn key
- [ ] Accessibility improvements
- [ ] Notarization ([Apple docs](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution))
- [ ] Unit test coverage



## Credits

- Sound effects from [Freesound.org](https://freesound.org/)
- Inspired by [keylock](https://github.com/kfv/keylock/)


## Support

If you find this app useful, consider [buying me a coffee](https://paypal.me/fangxing204) ☕

## License

See [LICENSE](LICENSE) file for details.

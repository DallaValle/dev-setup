# Amphetamine

Amphetamine replaces KeepingYouAwake on macOS and can keep the Mac awake with its lid closed.

## Install

Install the latest [Amphetamine from the Mac App Store](https://apps.apple.com/app/amphetamine/id937984704), then open it and complete its welcome setup. This is a manual step; `scripts/packages.sh` does not install App Store apps.

On other Macs, quit and uninstall KeepingYouAwake if it is still installed. If Homebrew manages it, use `brew uninstall --cask keepingyouawake`.

### Power Protect on Apple silicon laptops

Install [Amphetamine Power Protect](https://x74353.github.io/Amphetamine-Power-Protect/) as part of final setup on Apple silicon Mac laptops. It fixes closed-display sessions being interrupted when connecting or disconnecting a charger or a display with power delivery. Amphetamine must be installed first.

Run these commands as your normal macOS user to download the current official installer and open its disk image:

```sh
curl --fail --location --output "$HOME/Downloads/Power Protect for Amphetamine.dmg" \
  'https://github.com/x74353/Amphetamine-Power-Protect/raw/main/DMG/Power%20Protect%20for%20Amphetamine.dmg' &&
  open "$HOME/Downloads/Power Protect for Amphetamine.dmg"
```

In the mounted image, double-click the Power Protect installer and authenticate with Touch ID or your administrator password. These commands prepare the official interactive installation; `packages.sh` and `install.sh` do not perform it.

Confirm that Amphetamine recognizes Power Protect. The installer creates both of these files:

```text
~/Library/Application Scripts/com.if.Amphetamine/powerProtect.scpt
/private/etc/sudoers.d/amphetamine_powerProtect
```

End any active closed-display session and start a new one after installation. Eject the disk image when finished.

## Keep working with the lid closed

Start an Amphetamine session from its menu bar icon. In the session options, turn off **Allow system sleep when display is closed** and complete any closed-display setup prompts before closing the lid. End the session when you want normal sleep behavior again.

Enable launch at login in Amphetamine preferences if wanted. Verify a session with your usual charger and display setup before relying on it for a long task. On Apple silicon laptops, also connect and disconnect external power during the session and confirm the Mac stays awake with the lid closed.

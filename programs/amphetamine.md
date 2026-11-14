# Amphetamine

Amphetamine replaces KeepingYouAwake on macOS and can keep the Mac awake with its lid closed.

## Install

Install the latest [Amphetamine from the Mac App Store](https://apps.apple.com/app/amphetamine/id937984704), then open it and complete its welcome setup. This is a manual step; `scripts/packages.sh` does not install App Store apps.

On other Macs, quit and uninstall KeepingYouAwake if it is still installed. If Homebrew manages it, use `brew uninstall --cask keepingyouawake`.

## Keep working with the lid closed

Start an Amphetamine session from its menu bar icon. In the session options, turn off **Allow system sleep when display is closed** and complete any closed-display setup prompts before closing the lid. End the session when you want normal sleep behavior again.

Enable launch at login in Amphetamine preferences if wanted. Verify a session with your usual charger and display setup before relying on it for a long task.

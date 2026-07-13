# Wave 2: macOS app registration and QA after Nix app migration

Worker: researcher `019f1922-f5f5-7623-85ce-a833f0a85b5b`

## Key findings
- Verify system apps in `/Applications/Nix Apps`; Home Manager user apps in `~/Applications/Home Manager Apps` depending on HM state/version.
- Verify copy vs symlink behavior; copy mode is more macOS-friendly but requires App Management permissions.
- Verify Spotlight via `mdfind 'kMDItemCFBundleIdentifier == "..."'` and metadata via `mdls`.
- Verify `launchctl managername` is `Aqua` for local GUI activation path, then `open` the app from its Nix-owned path.
- Grant App Management to the exact terminal used for switch if activation cannot update app bundles.
- Repin Dock items because Dock/sidebar items are aliases and can keep pointing at old cask paths.

## Sources
- https://support.apple.com/guide/mac-help/open-apps-in-spotlight-mh35840/mac
- https://support.apple.com/guide/mac-help/folders-that-come-with-your-mac-mchlp1143/mac
- https://support.apple.com/guide/mac-help/create-and-remove-aliases-on-mac-mchlp1046/mac
- https://support.apple.com/guide/mac-help/change-privacy-security-settings-on-mac-mchl211c911f/mac
- https://support.apple.com/en-us/102321
- https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/LaunchServicesConcepts/LSCConcepts/LSCConcepts.html
- https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html
- https://github.com/nix-community/home-manager/issues/8336
- https://github.com/nix-darwin/nix-darwin/issues/1079

## EXPAND
- LEAD: per-app compatibility matrix — WHY: remaining risk is app-specific path sensitivity — ANGLE: after implementation, test each moved app by bundle ID, open path, permissions, Dock repin.

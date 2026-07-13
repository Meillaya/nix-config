# Expansion Log

## Wave 0
- Created session and decomposed axes.
- Initial workers planned: repo surface, Darwin module semantics, package replacement coverage, uninstall risk, real-world examples, repo deep-dive.

## Wave 1 return: codebase repo Homebrew surface
- Journaled worker `019f1916-7646-7471-bc81-7b905dbb425e`.
- New leads: nix-homebrew flake wiring; cask inventory; `/opt/homebrew` path entanglement; Homebrew update workflow; historical removal trail.

## Wave 1 return: upstream nix-darwin/nixpkgs apps
- Journaled worker `019f1917-09d0-7e13-ade5-7f64b8487b3f`.
- New leads: activation ordering; option evolution; macOS app bundle packaging; MAS/cask cleanup semantics.

## Wave 1
- Official docs/source axis completed.
- Package availability axis completed via nix search/eval.
- GUI apps/LaunchServices axis completed via nix-darwin/HM/mac-app-util source.
- MAS limitations axis completed via nix-darwin and mas-cli docs.

## Expansion leads opened and status
- App symlink/Spotlight behavior — investigated; mac-app-util + nix-darwin/HM source indicate copy/trampoline paths are more robust than bare symlinks.
- Codesigning/quarantine — investigated; nixpkgs sources show app-specific binary/provenance/signing constraints and HM/nix-darwin App Management permission checks.
- Direct replacements for current repo casks — investigated from modules/darwin/casks.nix and nixpkgs availability.
- MAS unavoidable manual installs — investigated; mas cannot purchase paid apps and depends on App Store account/Spotlight state.

Convergence: no unchecked actionable leads remain for the requested research scope; unresolved items require user-specific installed MAS list or testing candidate apps on target macOS.

## Wave 1 returns: docs, real-world examples, uninstall risk
- Journaled workers `019f1916-916d-7d22-8455-426c7ef4c900`, `019f1916-ea77-7903-821b-fb089802bfcc`, and `019f1916-cb17-7ef0-8815-1b09cfb6419c`.
- New leads include cleanup semantics, MAS leftovers, dual-prefix cleanup, services, app placement/path caveats, and cask data preservation.

## Wave 2 expansion: strict no-Homebrew app gaps
- Local web expansion covered Helium, OmniWM, Stremio, Sublime Text, and Ghostty.
- New actionable leads: local binary derivation templates; runtime app QA.

## Wave 2 expansion: implementation shape
- Local codebase expansion mapped exact file edit surface.
- New leads: exact patch implementation; lockfile cleanup.

## Wave 2 returns: app gaps and app-registration QA
- Journaled workers `019f1922-9bf8-7322-bba3-003fa0bde9c6`, `019f1922-cc50-7fa0-9ce7-bc3fa95ad647`, and `019f1922-f5f5-7623-85ce-a833f0a85b5b`.
- Closed direct-replacement leads for Helium/OmniWM/Sublime/Stremio as no direct nixpkgs attrs; found Homebrew-free alternatives/local packaging paths.
- Remaining lead is implementation/runtime QA, not additional research.

## Convergence
- Two expansion waves completed.
- No unchecked research leads remain that change the migration recommendation.
- Open implementation leads are deferred to a code-change task: exact patch, lockfile cleanup, per-app runtime QA after switch.

# Wave 1: Homebrew uninstall and migration risk

Worker: researcher `019f1916-cb17-7ef0-8815-1b09cfb6419c`

## Key findings
- Safe sequence: inventory formula leaves/casks/services/MAS, snapshot Brewfile if desired, stop services, remove shell wiring, run official uninstall script for the correct prefix, verify leftovers.
- Apple Silicon default prefix is `/opt/homebrew`; Intel default is `/usr/local`; dual-prefix Macs require separate attention.
- Avoid cask `--zap` when preserving user app data because it can remove preferences/caches/shared resources.
- Cask uninstall/reinstall can cause macOS to lose Dock/Launchpad/permission metadata.
- Current services behavior lives in Homebrew/brew; old homebrew-services tap is archived/stale.

## Sources
- https://docs.brew.sh/FAQ
- https://docs.brew.sh/Manpage
- https://docs.brew.sh/Installation
- https://docs.brew.sh/Cask-Cookbook
- https://docs.brew.sh/Shell-Completion
- https://docs.brew.sh/Common-Issues
- https://docs.brew.sh/Brew-Bundle-and-Brewfile
- https://github.com/Homebrew/install/blob/main/README.md
- https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh
- https://docs.brew.sh/rubydoc/Homebrew/Services/Cli.html
- https://github.com/mas-cli/mas/blob/main/README.md

## EXPAND markers verbatim
- LEAD: Dual-prefix migration cleanup — WHY: confirm whether `/usr/local` still contains an Intel Homebrew tree after moving to Apple Silicon — ANGLE: Homebrew Common Issues + uninstall.sh `--path=/usr/local`
- LEAD: Service orphan detection — WHY: verify whether any launchd plists remain outside Homebrew’s managed service files — ANGLE: `brew services list/info/cleanup` + `launchctl` domains
- LEAD: Cask data preservation policy — WHY: identify which apps need manual backup before uninstalling Homebrew — ANGLE: Cask Cookbook `zap` semantics + app-specific `~/Library` locations
- LEAD: App Store inventory completeness — WHY: ensure `mas list` is not missing apps due to Spotlight indexing problems — ANGLE: mas-cli README Spotlight checks (`mdls`, `mdfind`)

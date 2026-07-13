# Wave 1: Real-world Homebrew-free nix-darwin examples

Worker: librarian `019f1916-ea77-7903-821b-fb089802bfcc`

## Key findings
- Public brew-free nix-darwin configs exist; one example explicitly states no `brew` is installed and packages come from Nix or language toolchains.
- Both nix-darwin and Home Manager have Homebrew-free app placement paths from Nix package sets.
- GUI app migration remains the hard part because some apps are path-sensitive or need macOS App Management permissions.
- Cask/Brewfile cleanup has known edge cases in nix-darwin issue discussions.

## Sources
- https://github.com/LnL7/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/system/applications.nix#L59-L112
- https://github.com/nix-community/home-manager/blob/5d72a29fc36ac21adae6ae35568fe5ee6700850f/modules/targets/darwin/linkapps.nix#L34-L43
- https://github.com/nix-community/home-manager/blob/5d72a29fc36ac21adae6ae35568fe5ee6700850f/modules/targets/darwin/copyapps.nix#L41-L145
- https://github.com/tommyknows/nixfiles/blob/3bd12ff6e0d39f531189ede427cdf8e69ff2f989/README.md#L10-L14
- https://github.com/oke-py/macos-configuration/blob/73e67ebb6353f00064d17908d1ea1fc7b646780b/README.md#L79-L107
- https://github.com/LnL7/nix-darwin/issues/57
- https://github.com/LnL7/nix-darwin/issues/1086
- https://github.com/nix-community/home-manager/issues/3557

## EXPAND markers verbatim
- LEAD: Brew-free public config — WHY: establishes a real-world Homebrew-free baseline — ANGLE: find additional fully brew-free nix-darwin repos with GUI apps in Nixpkgs
- LEAD: GUI app placement patterns — WHY: shows how apps work without casks — ANGLE: inspect nix-darwin `system.applications` and home-manager Darwin app-copy/link behavior
- LEAD: Migration caveats — WHY: explains why brew-free is hard in practice — ANGLE: Home Manager App Management and app-path-sensitive issues
- LEAD: Cask-limit threads — WHY: documents the failure modes that motivate brew-free setups — ANGLE: nix-darwin issues/discussions around casks, MAS, and Brewfile cleanup

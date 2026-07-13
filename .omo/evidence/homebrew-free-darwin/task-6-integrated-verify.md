# Task 6 integrated verification evidence

## git diff --stat before verification
 docs/service-notes/nix-homebrew.md |  22 -------
 flake.lock                         | 104 ---------------------------------
 flake.nix                          |  36 +-----------
 modules/darwin/README.md           |   3 +-
 modules/darwin/casks.nix           |  29 ----------
 modules/darwin/home-manager.nix    |  22 -------
 modules/darwin/packages.nix        |   8 +++
 modules/shared/home-manager.nix    |  13 +----
 modules/shared/packages.nix        | 115 +------------------------------------
 9 files changed, 15 insertions(+), 337 deletions(-)

## active product config Homebrew scan (flake/modules, excluding lock)

## documentation Homebrew references (migration note allowed)
docs/service-notes/homebrew-free-migration.md:1:# Homebrew-free Darwin migration
docs/service-notes/homebrew-free-migration.md:3:This repo is intended to manage the Darwin system with Nix, not Homebrew.
docs/service-notes/homebrew-free-migration.md:14:## Before removing the existing Homebrew installation
docs/service-notes/homebrew-free-migration.md:16:Only remove the physical Homebrew tree after the Nix config has built, switched,

## removed lock inputs scan

## former homebrew eval should fail or be absent
warning: Git tree '/Users/mei/nixos-config' is dirty
error (ignored): SQLite database '/Users/mei/.cache/nix/eval-cache-v6/50349a879e0555e3c94030ffd3495786eacbf6385b6eecf580c2b707b72e0be9.sqlite' is busy
false

## system drv path eval
/nix/store/8ickvlhy5c3709fq7dfhz19j4bajc4g4-darwin-system-26.05.06648f4.drv
## git diff --check

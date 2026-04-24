# Zen and Helium on standalone Linux

## Zen

This repo now integrates Zen declaratively via the community Nix flake:

- `github:0xc000022070/zen-browser-flake`

On standalone Linux, the package is added through:

- `inputs.zen-browser.packages.${pkgs.system}.default`

This gives you a declarative Zen install even though your locked nixpkgs input
itself did not contain a `zen-browser` package.

Source used:
- https://github.com/0xc000022070/zen-browser-flake
- https://github.com/zen-browser

## Helium

Helium is now declared through a local overlay package that wraps the official
Linux AppImage release from:

- `https://github.com/imputnet/helium-linux/releases`

The package is pinned to the official upstream release artifacts for:

- `x86_64-linux`
- `aarch64-linux`

Source used:
- https://github.com/imputnet/helium
- https://github.com/imputnet/helium-linux

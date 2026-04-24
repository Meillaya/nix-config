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

Helium is **not** yet declaratively packaged in this repo.

The official upstream repository documents Linux releases and Linux packaging,
but there was no nixpkgs package or existing flake/package already present in
this repo's locked inputs during migration.

So Helium remains host-managed for now until we either:

1. package it in an overlay, or
2. adopt a dedicated Helium Nix package source.

Source used:
- https://github.com/imputnet/helium

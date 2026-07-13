# Task 5 mcp-nixos replacement verification evidence

## mcp-nixos package path
/nix/store/iyn7sxjm20jy8a8qjc79k9h4pjnw3sr7-mcp-nixos-2.3.1

## mcp-nixos tool source
Called the packaged mcp_nixos.server nix tool against source=nixos, type=packages, channel=unstable.
Human package index reference: https://search.nixos.org/packages?channel=unstable

### mcp-nixos
Found 3 packages matching 'mcp-nixos':

* mcp-nixos (2.3.0)
  MCP server for NixOS

* python314Packages.mcpadapt (0.1.20)
  MCP servers tool

* haskellPackages.pty-mcp-server (0.1.5.0)
  pty-mcp-server

### ast-grep
Found 3 packages matching 'ast-grep':

* ast-grep (0.42.1)
  Fast and polyglot tool for code searching, linting, rewriting at large scale

* python314Packages.grep-ast (0.9.0)
  Python implementation of the ast-grep tool

* python313Packages.grep-ast (0.9.0)
  Python implementation of the ast-grep tool

### ghostty-bin
Found 3 packages matching 'ghostty-bin':

* ghostty-bin (1.3.1)
  Fast, native, feature-rich terminal emulator pushing modern features

* tree-sitter-grammars.tree-sitter-ghostty (1.2-unstable-2026-01-02)
  Tree-sitter grammar for ghostty

* python314Packages.tree-sitter-grammars.tree-sitter-ghostty (1.2+unstable20260102)
  Python bindings for tree-sitter-ghostty

### iterm2
Found 3 packages matching 'iterm2':

* iterm2 (3.6.6)
  Replacement for Terminal and the successor to iTerm

* python313Packages.iterm2 (2.13)
  Python interface to iTerm2's scripting API

* python314Packages.iterm2 (2.13)
  Python interface to iTerm2's scripting API

### postman
Found 3 packages matching 'postman':

* postman (11.88.3)
  API Development Environment

* newman (6.2.2)
  Command-line collection runner for Postman

* grpcui (1.5.1)
  Interactive web UI for gRPC, along the lines of postman

### raycast
Found 1 packages matching 'raycast':

* raycast (1.104.10)
  Control your tools with a few keystrokes

### obsidian
Found 3 packages matching 'obsidian':

* obsidian (1.12.7)
  Powerful knowledge base that works on top of a local folder of plain text Markdown files

* dwarf-fortress-packages.themes.obsidian (47.05)

* haskellPackages.commonmark-wikilink (0.2.0.0)
  Obsidian-friendly commonmark wikilink parser

### vesktop
Found 1 packages matching 'vesktop':

* vesktop (1.6.5)
  Alternate client for Discord with Vencord built-in

### zed-editor
Found 3 packages matching 'zed-editor':

* zed-editor (0.230.1)
  High-performance, multiplayer code editor from the creators of Atom and Tree-sitter

* zod (2011-09-06)
  Multiplayer remake of ZED

* zed-open-capture (0.5.0-unstable-2023-24-19)
  Platform-agnostic camera and sensor capture API for the ZED 2, ZED 2i, and ZED Mini stereo cameras


## Nix attr eval from current flake nixpkgs input
mcp-nixos        2.3.1
ast-grep         0.42.1
ghostty-bin      1.3.1
iterm2           3.6.6
postman          11.89.0
raycast          1.104.10
obsidian         1.12.7
vesktop          1.6.5
zed-editor       0.232.2
claude-code      2.1.112
codex            0.121.0

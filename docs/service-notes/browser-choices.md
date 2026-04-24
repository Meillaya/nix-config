# Declarative browser choices on standalone Linux

This repo now declares:

- `brave`

## Not yet declared from locked nixpkgs

The following requested browser packages were **not present** in the repo's
currently locked nixpkgs input during migration:

- `zen-browser`
- `helium`

That means they currently stay **host-managed** on this machine unless you later:

1. add an overlay/package expression for them, or
2. update/pin a nixpkgs input that contains them

## Why browser profiles are not committed

The live browser config directories contain secrets and state such as:

- cookies
- login/session databases
- browsing history
- bookmarks and sync state
- extension storage

Those profiles are not safe to commit wholesale into this repo. The current
declarative boundary is package choice, not full profile replication.

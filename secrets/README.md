Place local age-encrypted secret files in this directory when needed.

This directory is intentionally ignored by git (except for this file) so the
public flake can bootstrap on fresh Linux installs without fetching a private
GitHub secrets repository during evaluation.

Example files:

- `github-ssh-key.age`
- `github-signing-key.age`

The sample `modules/darwin/secrets.nix` and `modules/nixos/secrets.nix` files
already show how to reference files from this directory via the `secrets`
special argument.

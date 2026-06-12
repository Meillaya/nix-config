{ pkgs, config, lib, ... }:

let
  homeDirectory =
    let
      hmHome = lib.attrByPath [ "home" "homeDirectory" ] null config;
      primaryUser =
        lib.attrByPath [ "home" "username" ]
          (lib.attrByPath [ "system" "primaryUser" ] null config)
          config;
      managedUserHome =
        if primaryUser == null then
          null
        else
          lib.attrByPath [ "users" "users" primaryUser "home" ] null config;
    in
    if hmHome != null then hmHome else if managedUserHome != null then managedUserHome else "$HOME";
in
{
  ".npmrc" = {
    text = ''
      prefix=${homeDirectory}/.local
    '';
  };

  ".config/fastfetch" = {
    source = ../shared/config/fastfetch;
    recursive = true;
  };

  # ".ssh/id_github.pub" = {
  #   text = githubPublicKey;
  # };

  # Initializes Emacs with org-mode so we can tangle the main config
  ".emacs.d/init.el" = {
    text = builtins.readFile ../shared/config/emacs/init.el;
  };

  # IMPORTANT: The Emacs configuration expects a config.org file at ~/.config/emacs/config.org
  # You can either:
  # 1. Copy the provided config.org to ~/.config/emacs/config.org
  # 2. Set EMACS_CONFIG_ORG environment variable to point to your config.org location
  # 3. Uncomment below to have Nix manage the file:
  #
  # ".config/emacs/config.org" = {
  #   text = builtins.readFile ../shared/config/emacs/config.org;
  # };

}

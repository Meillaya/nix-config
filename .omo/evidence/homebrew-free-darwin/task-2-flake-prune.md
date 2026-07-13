# Task 2 flake prune evidence

## flake.nix Homebrew input scan after edit

## flake diff summary
diff --git a/flake.nix b/flake.nix
index 93de9bf..a6b3296 100644
--- a/flake.nix
+++ b/flake.nix
@@ -8,25 +8,6 @@
       url = "github:LnL7/nix-darwin/master";
       inputs.nixpkgs.follows = "nixpkgs";
     };
-    nix-homebrew = {
-      url = "github:zhaofengli-wip/nix-homebrew";
-    };
-    homebrew-bundle = {
-      url = "github:homebrew/homebrew-bundle";
-      flake = false;
-    };
-    homebrew-core = {
-      url = "github:homebrew/homebrew-core";
-      flake = false;
-    };
-    homebrew-cask = {
-      url = "github:homebrew/homebrew-cask";
-      flake = false;
-    };
-    barutsrb-homebrew-tap = {
-      url = "github:BarutSRB/homebrew-tap";
-      flake = false;
-    };
     disko = {
       url = "github:nix-community/disko";
       inputs.nixpkgs.follows = "nixpkgs";
@@ -41,7 +22,7 @@
       inputs.nixpkgs.follows = "nixpkgs";
     };
   };
-  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, barutsrb-homebrew-tap, home-manager, nixpkgs, disko, agenix, zen-browser, noctalia } @inputs:
+  outputs = { self, darwin, home-manager, nixpkgs, disko, agenix, zen-browser, noctalia } @inputs:
     let
       user = "mei";
       secrets = ./secrets;
@@ -398,21 +379,6 @@ EOF
           specialArgs = inputs;
           modules = [
             home-manager.darwinModules.home-manager
-            nix-homebrew.darwinModules.nix-homebrew
-            {
-              nix-homebrew = {
-                inherit user;
-                enable = true;
-                taps = {
-                  "homebrew/homebrew-core" = homebrew-core;
-                  "homebrew/homebrew-cask" = homebrew-cask;
-                  "homebrew/homebrew-bundle" = homebrew-bundle;
-                  "BarutSRB/homebrew-tap" = barutsrb-homebrew-tap;
-                };
-                mutableTaps = false;
-                autoMigrate = true;
-              };
-            }
             ./hosts/darwin
           ];
         }

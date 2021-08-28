{
  description = "(insert short project description here)";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixpkgs-unstable";

  # Upstream source tree(s).
  inputs.lemmy-ui-src = {
    url = "github:LemmyNet/lemmy-ui/6994a3a6913ff3eabe98f5f182343d58ffb6a3a0";
    flake = false;
  };

  outputs = { self, nixpkgs, lemmy-ui-src }:
    let
      # Generate a user-friendly version numer.
      userFriendlyVersion = src: builtins.substring 0 8 lemmy-ui-src.lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # A Nixpkgs overlay.
      overlay = final: prev: {
          inherit self lemmy-ui-src;
      };

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ overlay (import ./nix/overlay.nix) ]; });
    in
    {
      defaultPackage = forAllSystems (system: self.packages.${system}.lemmy-ui);
      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) lemmy-ui;
        });
    };
}

{
  description = "(insert short project description here)";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixpkgs-unstable";

  # Upstream source tree(s).
  inputs.lemmy-ui-src = { url = "github:LemmyNet/lemmy-ui"; flake = false; };

  outputs = { self, nixpkgs, lemmy-ui-src }:
    let
      # Generate a user-friendly version numer.
      userFriendlyVersion = src: builtins.substring 0 8 lemmy-ui-src.lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
    in
    {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        lemmy-ui = with final; mkYarnPackage rec {
          pname = "lemmy-ui";
          version = userFriendlyVersion src;
          src = ./.;
          yarnNix = ./yarn.nix;
          yarnLock = ./yarn.lock;
          buildInputs = [ pkgs.nodePackages.rimraf ];
          # installPhase = ''
          #   yarn --offline build
          #   cp -r deps/lemmy-ui/dist $out
          # '';
          installPhase = ''
            yarn install --pure-lockfile
          '';
          buildPhase = ''
            yarn build:prod --offline
          '';
          # don't generate the dist tarball
          # (`doDist = false` does not work in mkYarnPackage)
          distPhase = ''
            true
          '';
        };

      };

      defaultPackage.x86_64-linux = self.packages.x86_64-linux.lemmy-ui;
      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) lemmy-ui;
        });
    };
}

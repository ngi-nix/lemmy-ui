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
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
    in
    {

      # A Nixpkgs overlay.
      overlay = final: prev:
        let
          src_with_submodules = builtins.fetchGit {
            url = "https://github.com/LemmyNet/lemmy-ui";
            inherit (lemmy-ui-src) rev;
            ref = "main";
            submodules = true;
          };
          version = "0.11.3";
          patchedPackageJSON = final.runCommand "package.json" { } ''
            ${final.jq}/bin/jq '.version = "${version}"' ${src_with_submodules}/package.json > $out
          '';
        in
        {
          lemmy-ui = with final; mkYarnPackage rec {
            pname = "lemmy-ui";
            inherit version;
            src = src_with_submodules;
            extraBuildInputs = [ final.libsass ];
            yarnNix = ./yarn.nix;
            yarnLock = ./yarn.lock;
            packageJSON = patchedPackageJSON;
            yarnPreBuild = ''
              mkdir -p $HOME/.node-gyp/${nodejs.version}
              echo 9 > $HOME/.node-gyp/${nodejs.version}/installVersion
              ln -sfv ${nodejs}/include $HOME/.node-gyp/${nodejs.version}
              export npm_config_nodedir=${nodejs}
            '';
            pkgConfig = {
              node-sass = {
                buildInputs = with final;[ python libsass pkg-config ];
                postInstall = ''
                  LIBSASS_EXT=auto yarn --offline run build
                  rm build/config.gypi
                '';
              };
            };
            buildPhase = ''
              # Yarn writes cache directories etc to $HOME.
              export HOME=$PWD/yarn_home
              
              ln -sf $PWD/node_modules $PWD/deps/lemmy-ui/
              
              yarn --offline build:prod
            '';
            distPhase = "true";
          };
        };

      defaultPackage = forAllSystems (system: self.packages.${system}.lemmy-ui);
      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) lemmy-ui;
        });
    };
}

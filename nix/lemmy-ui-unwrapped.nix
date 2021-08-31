{ mkYarnPackage
, src_with_submodules
, libsass
, nodejs
, python3
, pkg-config
, self
, _rev ? self.rev or "dirty"
}:

let
  pkgConfig = {
    node-sass = {
      nativeBuildInputs = [ ];
      buildInputs = [ libsass pkg-config python3 ];
      postInstall = ''
        LIBSASS_EXT=auto yarn --offline run build
        rm build/config.gypi
      '';
    };
  };
in
mkYarnPackage rec {
  pname = "lemmy-ui";
  version = _rev;

  src = src_with_submodules;

  extraBuildInputs = [ libsass ];

  yarnNix = ./yarn.nix;
  yarnLock = ../yarn.lock;
  packageJSON = ../package.json;

  yarnPreBuild = ''
    mkdir -p $HOME/.node-gyp/${nodejs.version}
    echo 9 > $HOME/.node-gyp/${nodejs.version}/installVersion
    ln -sfv ${nodejs}/include $HOME/.node-gyp/${nodejs.version}

    export npm_config_nodedir=${nodejs}
  '';

  buildPhase = ''
    # Yarn writes cache directories etc to $HOME.
    export HOME=$PWD/yarn_home
    
    ln -sf $PWD/node_modules $PWD/deps/lemmy-ui/
    
    yarn --offline build:prod
  '';

  distPhase = "true";

  inherit pkgConfig;
}

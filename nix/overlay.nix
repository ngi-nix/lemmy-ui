final: prev: {
  lemmy-ui = prev.callPackage ./lemmy-ui.nix { };

  lemmy-ui-docker = final.callPackage ./lemmy-ui-docker.nix { };

  src_with_submodules = builtins.fetchGit {
    url = "https://github.com/LemmyNet/lemmy-ui";
    inherit (prev.lemmy-ui-src) rev;
    ref = "main";
    submodules = true;
  };
}

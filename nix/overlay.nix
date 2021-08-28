final: prev: {
  lemmy-unwrapped = prev.callPackage ./lemmy-ui-unwrapped.nix { };

  lemmy-ui = final.lemmy-unwrapped; #final.callPackage ./lemmy-ui-wrapped.nix { };

  src_with_submodules = builtins.fetchGit {
    url = "https://github.com/LemmyNet/lemmy-ui";
    inherit (prev.lemmy-ui-src) rev;
    ref = "main";
    submodules = true;
  };
}

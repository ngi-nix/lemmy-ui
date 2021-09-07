{ dockerTools
, lemmy-ui
}:

dockerTools.buildImage {
  name = "lemmy-ui";
  tag = lemmy-ui.unwrapped.version;

  contents = [
    lemmy-ui
  ];
}

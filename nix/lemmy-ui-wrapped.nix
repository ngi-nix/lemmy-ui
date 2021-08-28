{ nodejs
, lemmy-ui-unwrapped
, writeShellScriptBin
}:

writeShellScriptBin "lemmy-ui" ''
   ${nodejs}/bin/node ${lemmy-ui-unwrapped}/libexec/lemmy-ui/node_modules/lemmy-ui/dist/js/server.js
''

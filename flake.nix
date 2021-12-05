{
  description = "devshell";

  outputs = { self, nixpkgs }:
    let
      eachSystem = f:
        let
          op = attrs: system:
            let
              ret = f system;
              op2 = attrs: key:
                attrs // {
                  ${key} = (attrs.${key} or { }) // { ${system} = ret.${key}; };
                };
            in
            builtins.foldl' op2 attrs (builtins.attrNames ret);
        in
        builtins.foldl' op { } [
          "aarch64-darwin"
          "aarch64-linux"
          "i686-linux"
          "x86_64-darwin"
          "x86_64-linux"
        ];

      forSystem = system:
        let
          devshell = import ./. { inherit system; };
        in
        {
          defaultPackage = devshell.cli;
          legacyPackages = devshell;
          devShell = devshell.fromTOML ./devshell.toml;
        };
      fromTOML = path:  eachSystem (system:
        let pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import ./overlay.nix) ];
        };
        in {
          devShell = pkgs.devshell.fromTOML path;
        }
      );
    in
    {
      defaultTemplate.path = ./template;
      defaultTemplate.description = "nix flake new 'github:numtide/devshell'";
      # Import this overlay into your instance of nixpkgs
      overlay = import ./overlay.nix;
      lib = {
        inherit fromTOML;
        importTOML = import ./nix/importTOML.nix;
      };
    }
    //
    eachSystem forSystem;
}

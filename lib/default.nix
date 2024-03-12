{ lib }:
rec {
  filterDirectories = files: lib.attrsets.filterAttrs (name: type: type == "directory") files;
  getDirectories = d: (builtins.attrNames (filterDirectories (builtins.readDir d)));
  importModules =
    let
      createModule = name: {
        "${builtins.baseNameOf name}" = import name;
      };
      modules = d: map createModule (map (n: "${builtins.toString d}/${n}") (getDirectories d));
    in d: lib.attrsets.mergeAttrsList (modules d);
  importHosts = hostsDirectory: specialArgs:
    let
      hosts = getDirectories hostsDirectory;
      mkNixosConfiguration = host: {
        "${host}" = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ (hostsDirectory + /${host}/configuration.nix) ];
          specialArgs = specialArgs;
        };
      };
      nixosConfigurations = lib.attrsets.mergeAttrsList (builtins.map mkNixosConfiguration hosts);
    in nixosConfigurations;
}

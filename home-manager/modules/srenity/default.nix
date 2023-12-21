{ lib, ... }: {
  sops = {
    secrets = lib.attrsets.mapAttrs' (
      k: v: lib.attrsets.nameValuePair
      ("srenity/${k}")
      (v // { sopsFile = ./secrets.yaml; })
    ) {
      "OS_USERNAME" = {};
      "OS_PASSWORD" = {};
    };
  };
}

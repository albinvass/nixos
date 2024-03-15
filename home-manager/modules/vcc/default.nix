
{ lib, ... }: {
  sops = {
    secrets = lib.attrsets.mapAttrs' (
      k: v: lib.attrsets.nameValuePair
      "vcc/${k}"
      (v // { sopsFile = ./secrets.yaml; })
    ) {
      "CDSID" = {};
      "PASSWORD" = {};
      "POINTSHARP_PIN" = {};
    };
  };
}

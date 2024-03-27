
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
      "ARTIFACTORY_API_KEY" = {};
      "GERRIT_HTTP_USERNAME" = {};
      "GERRIT_HTTP_PASSWORD" = {};
    };
  };
}

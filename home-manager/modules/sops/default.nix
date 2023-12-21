{ config, ... }:
{
  sops.defaultSopsFile = ../../../secrets.yaml;
  sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
}

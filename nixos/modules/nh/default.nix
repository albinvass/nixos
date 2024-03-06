{ inputs, ...}:
{
  imports = [
    inputs.nh.nixosModules.default
  ];

  nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };
}

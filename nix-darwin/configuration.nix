{ pkgs, inputs, ... }:
{
  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # Apparently needed for some dumb reason:
  # https://www.reddit.com/r/NixOS/comments/1keumfe/comment/mqreihz/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
  programs.fish.enable = true;

  # The platform the configuration will be used on.
  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
    overlays = [ inputs.bacon-ls.overlay."aarch64-darwin" ];
  };
  users.users."albinvass".home = "/Users/albinvass";
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.albinvass = {
      imports = [ ./home.nix ];
    };
    extraSpecialArgs = {
      inherit inputs;
    };
  };
}

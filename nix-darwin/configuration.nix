{ inputs, ... }:
{
  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
  system.primaryUser = "albinvass";

  # Apparently needed for some dumb reason:
  # https://www.reddit.com/r/NixOS/comments/1keumfe/comment/mqreihz/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
  programs.fish.enable = true;

  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = "albinvass";
    autoMigrate = true;
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = true;
      cleanup = "zap";
    };
    # Must match the taps declared in `nix-homebrew.taps` above, otherwise
    # `brew bundle --cleanup` tries to untap them and fails because the tap
    # directories are read-only symlinks into the nix store.
    taps = [
      "homebrew/core"
      "homebrew/cask"
      "homebrew/bundle"
    ];
    brews = [ "qemu" ];
  };

  # The platform the configuration will be used on.
  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
    overlays = [
      inputs.bacon-ls.overlay."aarch64-darwin"
      inputs.git-toprepo.overlays.default
      inputs.nixneovimplugins.overlays.default
    ];
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

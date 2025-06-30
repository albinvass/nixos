{ pkgs, inputs }:
{
  git-toprepo = inputs.git-toprepo.packages.${pkgs.system}.git-toprepo;
  oils-for-unix = let
    pname = "oils-for-unix";
    version = "0.33.0";
  in pkgs.stdenv.mkDerivation {
      inherit pname version;
      src = builtins.fetchTarball {
        url = "https://oils.pub/download/oils-for-unix-${version}.tar.gz";
        sha256 = "sha256:0y4pg6sz5dzyvhvx490yhbxi7603dhjmsxjqrqram7iax8xvpvfa";
      };

      buildInputs = with pkgs; [
        readline
      ];

      buildPhase = ''
        _build/oils.sh
      '';

      installPhase = ''
        mkdir -p $out
        ./install
      '';
  };
}

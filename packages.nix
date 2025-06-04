{ pkgs, inputs }:
let
  rustPlatform =
    let
      toolchain = inputs.fenix.packages.${pkgs.system}.minimal.toolchain;
    in
    pkgs.makeRustPlatform {
      cargo = toolchain;
      rustc = toolchain;
    };
in
{
  git-toprepo = rustPlatform.buildRustPackage {
    pname = "git-toprepo";
    version = "0.1.0";
    src = inputs.git-toprepo;
    cargoLock.lockFile = "${inputs.git-toprepo}/Cargo.lock";
    doCheck = false;
  };
}

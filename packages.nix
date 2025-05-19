{ pkgs, inputs }: {
  git-toprepo = pkgs.rustPlatform.buildRustPackage {
          pname = "git-toprepo";
          version = "0.1.0";
          src = inputs.git-toprepo;
          cargoLock.lockFile = "${inputs.git-toprepo}/Cargo.lock";
          doCheck = false;
        };
}

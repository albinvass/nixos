{ pkgs, inputs }:
{
  git-toprepo = inputs.git-toprepo.packages.${pkgs.system}.git-toprepo;
}

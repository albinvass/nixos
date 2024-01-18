{ lib, buildGoModule, fetchFromGitHub }:
let 
  version = "1.1.0";
  owner = "kubernetes-sigs";
  repo = "hierarchical-namespaces";
in
buildGoModule {
  pname = "kubectl-hns";
  version = "${version}";

  src = fetchFromGitHub {
    owner = "${owner}";
    repo = "${repo}";
    rev = "v${version}";
    sha256 = "${lib.fakeSha256}";
  };

  vendorSha256 = "${lib.fakeSha256}";

  meta = with lib; {
    description = "Manage hierarchical namespaces (part of HNC)";
    homepage = "https://github.com/${owner}/${repo}";
    changelog = "https://github.com/${owner}/${repo}/releases/tag/v${version}";
    license = licenses.asl20;
  };
}

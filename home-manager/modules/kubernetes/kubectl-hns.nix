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
    sha256 = "sha256-Ko6Eb9eJttU1Sk+9PzYyTJjXe2joC0jvOQYjFAFAj/8=";
  };

  vendorSha256 = null;
  subPackages = [ "./cmd/kubectl" ];
  postInstall = ''
    mv $out/bin/kubectl $out/bin/kubectl-hns
  '';

  meta = with lib; {
    description = "Manage hierarchical namespaces (part of HNC)";
    homepage = "https://github.com/${owner}/${repo}";
    changelog = "https://github.com/${owner}/${repo}/releases/tag/v${version}";
    license = licenses.asl20;
  };
}

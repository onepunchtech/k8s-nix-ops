{ pkgs, nix-kube-generators, nixhelm }:

let
  kubelib = nix-kube-generators.lib { inherit pkgs; };

  external-dns = kubelib.fromHelm {
    name = "external-dns";
    chart = (nixhelm.charts { inherit pkgs; }).external-dns.external-dns;
    namespace = "infra";
  };

  cert-manager = kubelib.fromHelm {
    name = "cert-manager";
    chart = (nixhelm.charts { inherit pkgs; }).jetstack.cert-manager;
    namespace = "infra";
  };

  ingress-nginx = kubelib.fromHelm {
    name = "ingress-nginx";
    chart = (nixhelm.charts { inherit pkgs; }).kubernetes.ingress-nginx;
    namespace = "infra";
  };

  namespaces = map mkNamespace [ "infra" ];

  mkNamespace = name: {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = name;
  };

  charts = namespaces ++ cert-manager ++ external-dns ++ ingress-nginx;

  chartsManifest = kubelib.toYAMLStreamFile charts;

in chartsManifest

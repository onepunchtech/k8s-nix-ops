{config, lib, pkgs, charts, kubelib, ...}:
with lib; let
  externalDNS = {
    options = {

    };
  };

  yamls = kubelib.fromHelm {
    name = "crtmgr";
    chart = charts.jetstack.cert-manager;
    namespace = "default";
    includeCRDs = false;
    values = {crds.enabled = true;};
    #extraOpts = ["--set crds.enabled=true"];
  };

  certMgrCrds = builtins.filter (x: x.kind == "CustomResourceDefinition") yamls;

  certMgrInfra = builtins.filter (x: x.kind != "CustomResourceDefinition") yamls;

in {
  options = {
    features.certManager = {
      enabled = mkEnableOption "Cert Manager";
      issuerEmail = mkOption {
        description = "email used to register acme certs";
        type = types.str;
      };
    };
  };

  config = mkIf config.features.certManager.enabled {
    helmCharts = {
      crds.templates = { certManager = kubelib.toYAMLStreamFile certMgrCrds;};
      infra.templates = { certManager = kubelib.toYAMLStreamFile certMgrInfra;};
    };
  };
}
